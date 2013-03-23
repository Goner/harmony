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
#import "NetWorkStateMonitor.h"

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
    Reachability *reachability = [NetWorkStateMonitor getCurReachability];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkChange:) name:kReachabilityChangedNotification object:nil];
    if([reachability currentReachabilityStatus] == ReachableViaWiFi) {
        [self startBackupPhoto];
    }
}

+ (void) stopAutoBackupPhoto{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

+ (void) getCurrentContactsCountWithBlock:(void (^)(int nCount)) block{
    [self accessContactsWithBlock:^(ABAddressBookRef addressBook) {
        CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
        block(CFArrayGetCount(people));
        CFRelease(people);
    }];
}

static  dispatch_queue_t sync_queue = nil;


+ (dispatch_queue_t) getSyncDispatchQueue {
    if(!sync_queue){
        sync_queue = dispatch_queue_create("merry99_sync_data", NULL);
    }
    return sync_queue;
}

+ (void) handleNetworkChange:(NSNotificationCenter *)notice {
    NetworkStatus status = [[self getReachability] currentReachabilityStatus];
    if(status == ReachableViaWiFi) {
        [self startBackupPhoto];
    }
}

+ (NSString *)getCurrentTime{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy.mm.dd"];
    NSDate *now = [[NSDate alloc] init];
    return [dateFormat stringFromDate:now];
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
            //dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    //todo
                } else if (!granted) {
                    //todo
                } else {
                    // access granted
                    addressOperationBlock(addressBook);
                    CFRelease(addressBook);
                }
            //});
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
        int count = CFArrayGetCount(vCardPeople);
        for (CFIndex index = 0; index < count; index++)
        {
            ABRecordRef person = CFArrayGetValueAtIndex(vCardPeople, index);
            ABAddressBookAddRecord(addressBook, person, NULL);
        }
        CFRelease(vCardPeople);
        CFRelease(defaultSource);
        
        ABAddressBookSave(addressBook, nil);
        [self saveSyncContactsTimeAndCount:count];
    }];
    
}

+ (void) backupContacts{

    [self accessContactsWithBlock:^(ABAddressBookRef addressBook) {
        CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
        NSData *vCardsData = (__bridge_transfer NSData *)ABPersonCreateVCardRepresentationWithPeople(people);
        [NASMediaLibrary backupVCardData:vCardsData];
        [self saveSyncContactsTimeAndCount:CFArrayGetCount(people)];
        CFRelease(people);
    }];

}

+ (void) backupPhotos{
    NSMutableArray *backupedPhotos = [[NSMutableArray alloc] initWithArray:
                                        [[NSUserDefaults standardUserDefaults] objectForKey:@"Merry99BackupedPhotos"]];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library enumerateGroupsWithTypes:ALAssetsGroupAll
           usingBlock:^(ALAssetsGroup *group, BOOL *stop){
               [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
                   if (asset){
                       if([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]){
                           ALAssetRepresentation* assetRepresentation = [asset defaultRepresentation];
                           NSUInteger size = [assetRepresentation size];
                           uint8_t * buf =malloc(size);
                           NSError * err = nil;
                           NSUInteger gotByteCount = [assetRepresentation getBytes:buf fromOffset:0 length:size error:&err];
                           if (gotByteCount)
                           {
                               if (err)
                               {
                                   free(buf);
                               }
                               else
                               {
                                   NSString *fileName = [assetRepresentation filename];
                                   //if(![backupedPhotos containsObject:fileName]){
                                       NSData * photoData= [NSData dataWithBytesNoCopy:buf length:size freeWhenDone:YES];
                                   if([NASMediaLibrary backupPhotoData:photoData withName:[NSString stringWithFormat:@"/%@", fileName]]) {
                                           [backupedPhotos addObject:fileName];
                                           [[NSUserDefaults standardUserDefaults] setObject:backupedPhotos forKey:@"Merry99BackupedPhotos"];
                                       }
                                   //}
                                   
                               }
                           } else {
                               free(buf);
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
