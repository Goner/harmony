//
//  PhotoLibrary.h
//  NASClient
//
//  Created by wang zhenbin on 1/12/13.
//  Copyright (c) 2013 merry99. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProtocolInfo : NSObject {
    NSString* protocol;
    NSString* contentType;
}

@property (retain) NSString* protocol;
@property (retain) NSString* contentType;

- (NSString *)description;
@end

@interface Resource: NSObject {
    NSString*       uri;
    ProtocolInfo*   protocolInfo;
    NSInteger       size;
    NSString*       resolution;
}

@property (retain) NSString*       uri;
@property (retain) ProtocolInfo*   protocolInfo;
@property (assign) NSInteger        size;
@property (retain) NSString*       resolution;

- (NSString *)description;
@end

@class MediaCategory;
@interface MediaObject : NSObject {
    NSString* title;
    NSString* id;
    MediaCategory *parentCategory;
}

@property (retain) NSString* title;
@property (retain) NSString* id;
@property (retain) MediaCategory *parentCategory;

- (NSString *)description;
- (id)getMediaItem;
@end

@interface MediaCategory : MediaObject {
    NSInteger   childrenCount;
}

@property (assign) NSInteger childrenCount;

- (NSString *)description;
@end

@interface MediaItem : MediaObject {
    NSString* creator;
    NSString* date;
    NSArray* resources;
}

@property (retain) NSString* creator;
@property (retain) NSString* date;
@property (retain) NSArray* resources;

- (NSString *)description;
- (NSString *)getThumbnailURL;
- (NSString *)getResizedURL;
- (NSString *)getMediaURL;
@end

@interface User : NSObject {
    NSString* name;
    NSString* sn;
}

@property (retain) NSString* name;
@property (retain) NSString* sn;

- (NSString *)description;
@end

@interface Friend : User {
    BOOL   isOnline;
    BOOL   isShield;
}

@property (assign) BOOL isOnline;
@property (assign) BOOL isShield;

- (NSString *)description;
@end

@interface FolderShareInfo : NSObject {
    NSString*   folder;
    NSArray*    friends;
}

@property (retain) NSString* folder;
@property (retain) NSArray* friends;

- (NSString *)description;
@end

@interface FolderInfo : NSObject {
    NSString* folderPath;
    NSMutableArray*  subFolders;
}

@property (retain) NSString* folderPath;
@property (retain) NSMutableArray* subFolders;

- (NSString *)description;
@end


@interface NASMediaLibrary : NSObject
+ (BOOL)     initWithUser:(NSString*) user password:(NSString*) passwd;

//media interface
+ (NSArray *) getMediaCategories;
+ (NSArray *) getMediaObjects:(MediaCategory *)catogery;
+ (NSArray *) getMediaObjects:(MediaCategory *)catogery withMaxResults:(int)maxResults;

 //social interface
+ (NSArray *) getFriendList;
+ (BOOL) shareFolder:(NSString *)folder withFriends:(NSArray *)friends;
+ (BOOL) unshareFolder:(NSString *)folder;
+ (NSArray *) getAllShareInfos;
+ (int) getShareStateWithFriend:(NSString *)friendName andFolder:(NSString *)folder;
//management interface
+ (BOOL) tagFavoriteObj:(NSString *)objID;
+ (BOOL) untagFavoriteObj:(NSString *)objID;
+ (FolderInfo *) getFolderStructure:(NSString *)folderPath;

//Album share
+ (NSString *)shareAlbumWithFiles:(NSArray *)files;
+ (int)getAlbumShareState:(NSString *)albumShareID;
@end
