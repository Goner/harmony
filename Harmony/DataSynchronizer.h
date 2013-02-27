//
//  DataSynchronizer.h
//  Harmony
//
//  Created by wang zhenbin on 2/26/13.
//  Copyright (c) 2013 久久相悦. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AddressBook/AddressBook.h"
;

@interface DataSynchronizer : NSObject {
    
}
+ (void) startBackupPhoto;
+ (void) startAutoBackupPhoto;
+ (void) stopAutoBackupPhoto;
+ (void) startBackupContacts;
+ (void) startRestoreContacts;
+ (NSString *) getLastSyncContactsTime;
+ (NSInteger) getLastSyncContactsCount;
+ (NSInteger) getCurrentContactsCount;
@end
