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

@implementation DataSynchronizer
//- void makePhoneCall{
//    //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tel://99999"]];
//    UIWebView*callWebview =[[UIWebView alloc] init];
//    NSURL *telURL =[NSURL URLWithString:@"tel://10086"];// 貌似tel:// 或者 tel: 都行
//    [callWebview loadRequest:[NSURLRequest requestWithURL:telURL]];
//    [self.veiw addSubview:callWebview];
//}

/////////////////
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
        for (CFIndex index = 0; index < CFArrayGetCount(vCardPeople); index++)
        {
            ABRecordRef person = CFArrayGetValueAtIndex(vCardPeople, index);
            ABAddressBookAddRecord(addressBook, person, NULL);
        }
        CFRelease(vCardPeople);
        CFRelease(defaultSource);
        
        ABAddressBookSave(addressBook, nil);
    }];
}

+ (void) backupContacts{
    [self accessContactsWithBlock:^(ABAddressBookRef addressBook) {
        CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
        NSData *vCardsData = (__bridge_transfer NSData *)ABPersonCreateVCardRepresentationWithPeople(people);
        [NASMediaLibrary backupVCardData:vCardsData];
        CFRelease(people);
    }];
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

+ backupPhotos{
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
