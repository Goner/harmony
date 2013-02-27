//
//  DataSynchronizer.m
//  Harmony
//
//  Created by wang zhenbin on 2/26/13.
//  Copyright (c) 2013 久久相悦. All rights reserved.
//

#import "DataSynchronizer.h"
#import "AssetsLibrary/ALAsset.h"
#import "AssetsLibrary/ALAssetRepresentation.h"
#import "NASMediaLibrary.h"
#import "Reachability.h"

@interface DataSynchronizer()
+ (dispatch_queue_t) getSyncDispatchQueue;
+ (Reachability *) getReachability;
+ (void) handleNetworkChange:(NSNotificationCenter *)notice;
+ (NSString *)getCurrentTime;
+ (void) saveSyncContactsTimeAndCount:(NSInteger *)count;
+  (BOOL)isABAddressBookCreateWithOptionsAvailable;
+ (void)accessContactsWithBlock:(void(^)(ABAddressBookRef))addressOperationBlock ;
+ (void) restoreContacts;
+ (void) backupContacts;
+ (void)backupPhotos;
@end
@implementation DataSynchronizer
+ (void) startBackupPhoto {
    dispatch_async([self getSyncDispatchQueue], ^(){
        [self backupPhotos];
    });
}

+ (void) startAutoBackupPhoto{
    [[self getReachability] startNotifier];
    NetworkStatus status = [[self getReachability] currentReachabilityStatus];
    if(status == ReachableViaWiFi) {
        [self startBackupPhoto];
    }
}

+ (void) stopAutoBackupPhoto{
    [[self getReachability] stopNotifier];
}

+ (void) startBackupContacts {
    dispatch_async([self getSyncDispatchQueue], ^(){
        [self backupContacts];
    });
}

+ (void) startRestoreContacts {
    dispatch_async([self getSyncDispatchQueue], ^(){
        [self restoreContacts];
    });
}

+ (NSString *) getLastSyncContactsTime{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"syncContatTime"];
}

+ (NSInteger) getLastSyncContactsCount {
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"syncContactsCount"];
}

+ (NSInteger) getCurrentContactsCount {
    __block NSInteger count = 0;
    [self accessContactsWithBlock:^(ABAddressBookRef addressBook) {
        CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
        count = CFArrayGetCount(people);
        CFRelease(people);
    }];
    return count;
}
//- void makePhoneCall{
//    //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tel://99999"]];
//    UIWebView*callWebview =[[UIWebView alloc] init];
//    NSURL *telURL =[NSURL URLWithString:@"tel://10086"];// 貌似tel:// 或者 tel: 都行
//    [callWebview loadRequest:[NSURLRequest requestWithURL:telURL]];
//    [self.veiw addSubview:callWebview];
//}
static  dispatch_queue_t sync_queue = nil;
static  Reachability *reachability;

+ (dispatch_queue_t) getSyncDispatchQueue {
    if(!sync_queue){
        sync_queue = dispatch_queue_create("merry99_sync_data", NULL);
    }
    return sync_queue;
}

+ (Reachability *) getReachability{
    if(reachability)
        return reachability;
    reachability = [Reachability reachabilityForLocalWiFi];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkChange:) name:kReachabilityChangedNotification object:nil];
    return reachability;
}

+ (void) handleNetworkChange:(NSNotificationCenter *)notice {
    NetworkStatus status = [[self getReachability] currentReachabilityStatus];
    if(status == ReachableViaWiFi) {
        [self startBackupPhoto];
    }
}

+ (NSString *)getCurrentTime{
    NSDate *now = [[NSDate alloc] init];
    return [now description];
}

+ (void) saveSyncContactsTimeAndCount:(NSInteger *)count {
    [[NSUserDefaults standardUserDefaults] setInteger:count forKey:@"syncContactsCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[self getCurrentTime] forKey:@"syncContatTime"];
}


+ (BOOL)isABAddressBookCreateWithOptionsAvailable {
    return &ABAddressBookCreateWithOptions != NULL;
}

+ (void)accessContactsWithBlock:(void(^)(ABAddressBookRef)) addressOperationBlock {
    ABAddressBookRef addressBook;
    if ([self isABAddressBookCreateWithOptionsAvailable]) {
        CFErrorRef error = nil;
        addressBook = ABAddressBookCreateWithOptions(NULL,&error);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            // callback can occur in background, address book must be accessed on thread it was created on
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    //todo
                } else if (!granted) {
                    //todo
                } else {
                    // access granted
                    addressOperationBlock(addressBook);
                    CFRelease(addressBook);
                }
            });
        });
    } else {
        // iOS 4/5
        addressBook = ABAddressBookCreate();
        addressOperationBlock(addressBook);
        CFRelease(addressBook);
    }
}

+ (void) restoreContacts{
    NSData *vCardData = [NASMediaLibrary getVCardData];
    if(!vCardData) {
        return;
    }
    __block NSInteger count = 0;
    [self accessContactsWithBlock:^(ABAddressBookRef addressBook) {
        //empyt contacts
        CFArrayRef people=ABAddressBookCopyArrayOfAllPeople(addressBook);
        CFIndex contactsCount=ABAddressBookGetPersonCount(addressBook);
        for (int i=0; i < contactsCount; i++) {
            ABRecordRef person=CFArrayGetValueAtIndex(people, i);
            ABAddressBookRemoveRecord(addressBook, person, nil);
        }
        CFRelease(people);
        //update contacs
 
        ABRecordRef defaultSource = ABAddressBookCopyDefaultSource(addressBook);
        CFArrayRef vCardPeople = ABPersonCreatePeopleInSourceWithVCardRepresentation(defaultSource, (__bridge CFDataRef)(vCardData));
        count = CFArrayGetCount(vCardPeople);
        for (CFIndex index = 0; index < count; index++)
        {
            ABRecordRef person = CFArrayGetValueAtIndex(vCardPeople, index);
            ABAddressBookAddRecord(addressBook, person, NULL);
        }
        CFRelease(vCardPeople);
        CFRelease(defaultSource);
        
        ABAddressBookSave(addressBook, nil);
    }];
    [self saveSyncContactsTimeAndCount:count];
}

+ (void) backupContacts{
    __block NSInteger count = 0;
    [self accessContactsWithBlock:^(ABAddressBookRef addressBook) {
        CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
        count = CFArrayGetCount(people);
        NSData *vCardsData = (__bridge_transfer NSData *)ABPersonCreateVCardRepresentationWithPeople(people);
        [NASMediaLibrary backupVCardData:vCardsData];
        CFRelease(people);
    }];
    [self saveSyncContactsTimeAndCount:count];
}

+ (void) backupPhotos{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library enumerateGroupsWithTypes:ALAssetsGroupAll
                           usingBlock:^(ALAssetsGroup *group, BOOL *stop){
                               [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
                                   if (asset){
                                       if([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]){
                                           ALAssetRepresentation* assetRepresentation = [asset defaultRepresentation];
                                           NSUInteger size = [assetRepresentation size];
                                           uint8_t * buff =malloc(size);
                                           NSError * err = nil;
                                           NSUInteger gotByteCount = [assetRepresentation getBytes:buff fromOffset:0 length:size error:&err];
                                           if (gotByteCount)
                                           {
                                               if (err)
                                               {
                                                   NSLog(@"UploadFail error:ALAssetTypePhoto, Error reading asset:%@",[err localizedDescription]);
                                                   free(buff);
                                               }
                                               else
                                               {
                                                   NSData * photoData= [NSData dataWithBytesNoCopy:buff length:size freeWhenDone:YES];
                                                   [NASMediaLibrary backupPhotoData:photoData withName:[assetRepresentation filename]];
                                               }
                                           }
                                           
                                       }
                                   }
                                   //stop = [self isStopBackup];
                               }];
                               //stop = [self isStopBackup];
                            }
                         failureBlock:^(NSError *error){
                                                       // User did not allow access to library
                         }];
}

@end
