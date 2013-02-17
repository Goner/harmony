//
//  PhotoLibrary.m
//  NASClient
//
//  Created by wang zhenbin on 1/12/13.
//  Copyright (c) 2013 merry99. All rights reserved.
//

#import "NASMediaLibrary.h"
#import "NASMediaBrowser.h"
#import "NptCommon.h"
#import "interfaceudt_client.h"
#import "SBJson.h"

#define FAKE_INTERFACE 0
#define FAKE_NASSERVER 0

@implementation ProtocolInfo
@synthesize protocol;
@synthesize contentType;

- (NSString *)description {
    return [NSString stringWithFormat: @"ProtocolInfo:%@, %@", protocol, contentType];
}
@end

@implementation Resource
@synthesize uri;
@synthesize protocolInfo;
@synthesize size;
@synthesize resolution;

- (NSString *)description {
    return [NSString stringWithFormat: @"Resource: %@, %@, %d, %@", uri, protocolInfo, size, resolution];
}
@end

@implementation MediaObject
@synthesize title;
@synthesize id;
@synthesize parentCategory;

- (NSString *) description {
    return [NSString stringWithFormat: @"MediaObject: %@, %@, %@", title, id, parentCategory];
}

- (id)getMediaItem {
    return self;
}
@end

@implementation MediaCategory
@synthesize childrenCount;

- (NSString *)description {
    return [[NSString stringWithFormat:@"MediaContainer: %d, ", childrenCount] stringByAppendingString: [super description]];
}
- (id)getMediaItem {
    MediaObject *obj = self;
    do {
        NSArray *array = [NASMediaLibrary getMediaObjects:(MediaCategory *)obj withMaxResults:1];
        if(array.count == 0) {
            obj = nil;
            break;
        }
        obj = [array objectAtIndex:0];
    }while([obj isKindOfClass:[MediaCategory class]]);
    return obj;
}
@end

@interface MediaItem()
- (NSString *)getURLForKey:(NSString *)key;
@end
@implementation MediaItem
@synthesize creator;
@synthesize date;
@synthesize resources;

- (NSString *)description {
    return [[NSString stringWithFormat:@"PhotoItem: %@, %@, %@,", creator, date, resources] stringByAppendingString: [super description]];
}

- (NSString *)getURLForKey:(NSString *)key{
#if FAKE_NASSERVER
    static NSDictionary* fakeURLs = [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"http://img3.cache.netease.com/photo/0008/2012-03-27/t_7TK32ME629A50008.jpg",@"Thumbnail",
                                     @"http://news.xinhuanet.com/yzyd/travel/20130130/145710538519106419931n.jpg",@"Resized",
                                     @"http://pic15.nipic.com/20110701/5198878_162433615197_2.jpg",@"MediaItems",nil];
    NSString *url = [fakeURLs objectForKey:key];
    return url;
#else
    for(Resource* resource in resources) {
        NSRange rng = [resource.uri rangeOfString:key options:NSCaseInsensitiveSearch];
        if(rng.location != NSNotFound)
            return resource.uri;
    }
    return nil;
#endif
}
- (NSString *)getThumbnailURL {
    return [self getURLForKey:@"Thumbnail"];
}

- (NSString *)getResizedURL {
    return [self getURLForKey:@"Resized"];
}

- (NSString *)getMediaURL {
    return [self getURLForKey:@"MediaItems"];
}
@end

@implementation User
@synthesize name;
@synthesize sn;

- (NSString *)description {
    return [NSString stringWithFormat:@"User: %@, SN: %@", name, sn];
}
@end

@implementation Friend
@synthesize isOnline;
@synthesize isShield;

- (NSString *)description {
    return [[super description] stringByAppendingFormat:@"online: %d, shield: %d", isOnline, isShield];
}
@end

@implementation FolderShareInfo
@synthesize folder;
@synthesize friends;

- (NSString *)description {
    return [NSString stringWithFormat:@"Folder: %@, Share: %@", folder, friends];
}
@end

@implementation FolderInfo
@synthesize folderPath;
@synthesize subFolders;

- (NSString *)description {
    return [NSString stringWithFormat:@"FolderPath: %@, SubFolders: %@", folderPath, subFolders];
}

@end

const char* RootCotainerID = "0";
const char* PhotoLibraryName = "Photos"; //or "Pictures";

//Image
const char* ImageID = "3";
const char* ImageAllID= "3$10";
const char* ImagePersonID = "3$11";
const char* IMagePersonTitle = "人物";
const char* ImageLocationID = "3$12";
const char* ImageLocationTitle = "位置";
const char* ImageDateID = "3$13";
const char* ImageDateTitle = "日期";
const char* ImageRecentID = "3$16";
const char* ImageRecentTitle = "最新";
const char* ImageFavorID = "3$18";
const char* ImageFavorTitle = "精选";
const char* ImageDirID = "3$19";
const char* ImageDirTitle = "目录";

//Music
const char* MusicID = "1";
const char* MusicTitle = "音乐";
const char* MusicAllID = "1$1";
const char* MusicArtistID = "1$2";
const char* MusicAlbumID = "1$3";
const char* MusicDirID = "1$6";

//Video
const char* VideoID = "2";
const char* VideoTitle = "视频";
const char* VedioAllID = "2$8";
const char* VedioDirID = "2$9";

struct  CategoryDesc{
    const char* id;
    const char* title;
};

typedef std::shared_ptr<NASMediaBrowser> NASMediaBrowserPtr;

@interface NASMediaLibrary()
+ (MediaObject *)convToMediaObjct:(PLT_MediaObject *)pltObject;
+ (BOOL) checkResultWithJSON:(NSDictionary *)JSONDict;
+ (NSDictionary *) callCTransactProcWithParam:(NSDictionary *)paramDict;
@end

@implementation NASMediaLibrary
static NASMediaBrowserPtr nasMediaBrowserPtr;
static bool bRemoteAccess;

+ (BOOL) initWithUser:(NSString *)user password:(NSString *)passwd {
    nasMediaBrowserPtr = nullptr;
    bRemoteAccess = FALSE;
    const char* userName = [user UTF8String];
    const char* password = [passwd UTF8String];
#if FAKE_NASSERVER
    return true;
#else
    std::shared_ptr<NASLocalMediaBrowser> localMediaBrowserPtr = std::make_shared<NASLocalMediaBrowser>();
    if(NPT_SUCCEEDED(localMediaBrowserPtr->Connect())){
        nasMediaBrowserPtr  = localMediaBrowserPtr;
        NPT_String ipAddress = localMediaBrowserPtr->GetIpAddress();
        
        if(local_access_auth((char*)ipAddress, (char*)[user UTF8String], (char*)[passwd UTF8String]) == 0){
            return TRUE;
        } else {
            return FALSE;
        }
    }
    
    std::shared_ptr<NASRemoteMediaBrowser> remoteMediaBrowserPtr = std::make_shared<NASRemoteMediaBrowser>(userName,  password, "license");
        if(NPT_SUCCEEDED(remoteMediaBrowserPtr->Connect())){
            nasMediaBrowserPtr = remoteMediaBrowserPtr;
            bRemoteAccess = TRUE;
            return TRUE;
    }
    return FALSE;
#endif
}

+ (MediaObject *)convToMediaObjct:(PLT_MediaObject *)pltObject{
    MediaObject *mediaObject = nil;
    if(pltObject->IsContainer()) {
        MediaCategory *category = [[MediaCategory alloc] init];
        category.childrenCount = ((PLT_MediaContainer *)pltObject)->m_ChildrenCount;
        mediaObject = category;
    } else {
        MediaItem *item = [[MediaItem alloc] init];
        item.creator = [NSString  stringWithCString:pltObject->m_Creator encoding:NSUTF8StringEncoding];
        item.date = [NSString  stringWithCString:pltObject->m_Date encoding:NSUTF8StringEncoding];
        
        NSMutableArray* resources = [[NSMutableArray alloc] init];
        
        for (int resourceIndex = 0;  resourceIndex < pltObject->m_Resources.GetItemCount(); resourceIndex++) {
            PLT_MediaItemResource* pltResourcde = pltObject->m_Resources.GetItem(resourceIndex);
            Resource* resource = [[Resource alloc] init];
            resource.uri = [NSString  stringWithCString:pltResourcde->m_Uri encoding:NSUTF8StringEncoding];
            ProtocolInfo* protocolInfo = [[ProtocolInfo alloc] init];
            protocolInfo.protocol = [NSString  stringWithCString:pltResourcde->m_ProtocolInfo.GetProtocol() encoding:NSUTF8StringEncoding];
            protocolInfo.contentType = [NSString  stringWithCString:pltResourcde->m_ProtocolInfo.GetContentType() encoding:NSUTF8StringEncoding];
            resource.protocolInfo = protocolInfo;
            resource.size = pltResourcde->m_Size;
            resource.resolution = [NSString  stringWithCString:pltResourcde->m_Resolution encoding:NSUTF8StringEncoding];
            [resources addObject: resource];
        }
        item.resources = resources;
        mediaObject = item;
    }
    
    mediaObject.title = [NSString  stringWithCString:pltObject->m_Title encoding:NSUTF8StringEncoding];
    mediaObject.id = [NSString  stringWithCString:pltObject->m_ObjectID encoding:NSUTF8StringEncoding];
    return mediaObject;
}

+ (NSArray*) getMediaCategories {
    NSMutableArray* array = [[NSMutableArray alloc] init];
    
   static CategoryDesc mediaCetegories[] = {
        {ImageRecentID,ImageRecentTitle},
        {ImagePersonID,IMagePersonTitle},
//      {ImageLocationID, ImageLocationTitle},
        {ImageDateID, ImageDateTitle},
        {ImageFavorID, ImageFavorTitle}
        //,{MusicID, MusicTitle}
        //,{VideoID, VideoTitle}
    };
    
    for (int i = 0; i < sizeof(mediaCetegories)/sizeof(CategoryDesc); i++) {
        MediaCategory* category = [[MediaCategory alloc] init];
 
        category.title = [NSString  stringWithCString:mediaCetegories[i].title encoding:NSUTF8StringEncoding];
        category.id = [NSString  stringWithCString:mediaCetegories[i].id encoding:NSUTF8StringEncoding];
        category.parentCategory = nil;
        [array addObject:category];
    }
   
    return array;
}

+ (NSArray *) getMediaObjects:(MediaCategory *)catogery{
    return [self getMediaObjects:catogery withMaxResults:0];
}

+ (NSArray *) getMediaObjects:(MediaCategory *)catogery withMaxResults:(int)maxResults{
#if FAKE_NASSERVER
    NSMutableArray* array = [[NSMutableArray alloc] init];
    for(int i = 0; i < 5; i++) {
        MediaCategory* categoryChild = [[MediaCategory alloc] init];
        categoryChild.title = [NSString  stringWithFormat:@"title%d",i ];
        categoryChild.id = [NSString  stringWithFormat:@"id%d",i];
        categoryChild.childrenCount = i+1;
        categoryChild.parentCategory = category;
        [array addObject:category];
    }
    for(int i = 5; i < 12; i++) {
        MediaItem* item = [[MediaItem alloc] init];
        item.title = [NSString  stringWithFormat:@"item_title_%d", i];
        item.id = [NSString  stringWithFormat:@"item_id_%d", i];
        item.creator = [NSString  stringWithFormat:@"item_creator_%d", i];
        item.date = [NSString  stringWithFormat:@"item_date_%d", i];
        item.parentCategory = category;
        [array addObject:item];
    }
    return array;
#else
    if (!nasMediaBrowserPtr) {
        return nil;
    }
    PLT_MediaObjectListReference  pltMediaList(new PLT_MediaObjectList);
    nasMediaBrowserPtr->Browser([catogery.id UTF8String], pltMediaList, 0, maxResults);
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    if(pltMediaList.IsNull()){
        return array;
    }

    for (int i = 0; i < pltMediaList->GetItemCount(); i++) {
        MediaObject *object = [self convToMediaObjct:*pltMediaList->GetItem(i)];
        object.parentCategory = catogery;
        [array addObject: object];
    }
    return array;
#endif
}

+ (NSDictionary *) callCTransactProcWithParam:(NSDictionary *)paramDict{
    NSString* parameter  = [[[SBJsonWriter alloc] init] stringWithObject:paramDict];
    int len = 0;
    char* inParameter = (char*)[parameter UTF8String];
    transact_proc_call(inParameter, NULL, &len);
    char* outParameter = (char*)malloc(++len);
    transact_proc_call(inParameter, outParameter, &len);
    NSString* result = [NSString stringWithCString:outParameter encoding:NSUTF8StringEncoding];
    free(outParameter);
    return [[[SBJsonParser alloc] init] objectWithString:result];
}

+ (BOOL) checkResultWithJSON:(NSDictionary *)JSONDict{
    return [[JSONDict objectForKey:@"RESULT"] isEqualToString:@"SUCCESS"];
}

+ (NSArray *) getFriendList {
    NSDictionary *paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"FRIEND", @"METHOD",
                               @"GETFRIENDLIST", @"TYP", nil];
#if !FAKE_INTERFACE
    NSDictionary* resultDict = [self callCTransactProcWithParam: paramDict];
#else
     NSString* out =  @"{\"RESULT\":\"SUCCESS\", \"LIST\": [{\"NAME\":\"123\", \"SN”:\"22\", \"ONLINE\":true, \"SHIELD\":false},{\"NAME\":\"WWW\", \"SN\":\"333\", \"ONLINE\":false, \"SHIELD\":true}]}";
     NSDictionary* resultDict = [[[SBJsonParser alloc] init] objectWithString:out];
#endif
    if([self checkResultWithJSON: resultDict])
        return nil;
    
    NSArray* friends = [[NSMutableArray alloc] init];
    NSArray* array = [resultDict objectForKey:@"LIST"];
    for(NSDictionary* obj in array) {
        Friend* f = [[Friend alloc] init];
        f.name = [obj objectForKey:@"NAME"];
        f.sn = [obj objectForKey:@"SN"];
        f.isOnline = [[obj objectForKey:@"ONLINE"] boolValue];
        f.isShield = [[obj objectForKey:@"SHIELD"] boolValue];
    }

    return friends;
}

+ (BOOL) shareFolder:(NSString *)folder withFriends:(NSArray *)friends {
    NSMutableArray* users = [[NSMutableArray alloc] init];
    for (User* user in friends) {
        [users addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                          user.name, @"NAME",user.sn,@"SN", nil]];
    }
    NSDictionary* paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                  @"SHARE", @"METHOD",
                  @"ADD", @"TYPE",
                  folder, @"FOLDER",
                   users, @"FRIENDLIST", nil];
#if !FAKE_INTERFACE
    NSDictionary* resultDict = [self callCTransactProcWithParam:paramDict];
#else
    NSString* out  = @"{\"RESULT\":\"SUCCESS\"}";
     NSDictionary* resultDict = [[[SBJsonParser alloc] init] objectWithString:out];
#endif
   
    return [self checkResultWithJSON: resultDict];
}

+ (BOOL) unshareFolder:(NSString *)folder {
    NSDictionary* paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"SHARE", @"METHOD",
                        @"REMOVE", @"TYPE",
                        folder, @"FOLDER", nil];
#if !FAKE_INTERFACE
    NSDictionary* resultDict = [self callCTransactProcWithParam:paramDict];
#else
    NSString* out  = @"{\"RESULT\":\"SUCCESS\"}";
    NSDictionary* resultDict = [[[SBJsonParser alloc] init] objectWithString:out];
#endif
    return [self checkResultWithJSON: resultDict];
}

+ (NSArray *) getAllShareInfos {
    NSDictionary* paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"SHARE", @"METHOD",
                               @"QUERY", @"TYPE", nil];
#if !FAKE_INTERFACE
    NSDictionary* resultDict = [self callCTransactProcWithParam: paramDict];
#else
    NSString* out =  @"{\"RESULT\":\"SUCCESS\", \"LIST\":[{\"FOLDER\":\"FODLDER1\", \"FRIENDLIST\": [{\"NAME\":\"123\", \"SN”:\"22\"}, {\"NAME\":\"WWW\", \"SN”:\"33\"}]},{\"FOLDER\":\"FODLDER2\", \"FRIENDLIST\": [{\"NAME\":\"WW\", \"SN”:\"33\"}, {\"NAME\":\"ZZ\", \"SN”:\"BB\"}]}]}";
    NSDictionary* resultDict = [[[SBJsonParser alloc] init] objectWithString:out];
#endif
    if ([self checkResultWithJSON: resultDict])
        return nil;
    NSArray* array = [resultDict objectForKey:@"LIST"];
    NSMutableArray* infos = [[NSMutableArray alloc] init];
    for(NSDictionary* obj in array) {
        FolderShareInfo* info = [[FolderShareInfo alloc] init];
        info.folder = [obj objectForKey:@"FOLDER"];
        NSArray* friendList = [obj objectForKey:@"FRIEND"];
        NSMutableArray* sharedUsers = [[NSMutableArray alloc] init];
        for (NSDictionary* friendObj in friendList) {
            User* user = [[User alloc] init];
            user.name = [friendObj objectForKey:@"NAME"];
            user.sn = [friendObj objectForKey:@"SN"];
            [sharedUsers addObject: user];
        }
        info.friends = sharedUsers;
        [infos addObject:info];
    }
    return infos;
}

+ (int) getShareStateWithFriend:(NSString *)friendName andFolder:(NSString *)folder {
    NSDictionary* paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"SHARE", @"METHOD",
                        @"GETSHARESTATE", @"TYPE",
                        friendName, @"FRIENDNAME",
                        folder, @"FOLDER", nil];
#if !FAKE_INTERFACE
    NSDictionary* resultDict = [self callCTransactProcWithParam: paramDict];
#else
    NSString* out  = @"{\"RESULT\":\"SUCCESS\", \"STATE\":\"80\"}";
    NSDictionary* resultDict = [[[SBJsonParser alloc] init] objectWithString:out];
#endif
    return [self checkResultWithJSON: resultDict] ? [[resultDict objectForKey:@"STATE"] intValue] : 0;
}

//management interface
+ (BOOL) tagFavoriteObj:(NSString *)objID {
    NSDictionary* paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"FAVOR", @"METHOD",
                        @"ADD", @"TYPE",
                        objID, @"OBJECTID", nil];
#if !FAKE_INTERFACE
    NSDictionary* resultDict = [self callCTransactProcWithParam: paramDict];
#else
    NSString* out  = @"{\"RESULT\":\"SUCCESS\", \"STATE\":\"80\"}";
    NSDictionary* resultDict = [[[SBJsonParser alloc] init] objectWithString:out];
#endif
    return [self checkResultWithJSON: resultDict];
}

+ (BOOL) untagFavoriteObj:(NSString *)objID {
    NSDictionary* paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"FAVOR", @"METHOD",
                        @"DELETE", @"TYPE",
                        objID, @"OBJECTID", nil];
#if !FAKE_INTERFACE
    NSDictionary* resultDict = [self callCTransactProcWithParam:paramDict];
#else
    NSString* out  = @"{\"RESULT\":\"SUCCESS\", \"STATE\":\"80\"}";
    NSDictionary* resultDict = [[[SBJsonParser alloc] init] objectWithString:out];
#endif
    return [self checkResultWithJSON: resultDict];
}

+ (FolderInfo *) getFolderStructure:(NSString *)folderPath {
    int len = 0;
    char* path = (char*)[folderPath UTF8String];
    if(get_folder_meta(path, NULL, &len/*, true, false*/) < 0) {
        return nil;
    }
    char* meta = (char*)malloc(++len);
    if(get_folder_meta(path, meta, &len/*, true, false*/) < 0) {
        return nil;
    }
    NSString* metJSON = [NSString stringWithCString:meta encoding:NSUTF8StringEncoding];
    free(meta);
    NSDictionary* dict = [[[SBJsonParser alloc] init] objectWithString:metJSON];
    
    NSArray* array = [dict objectForKey:@"meta"];
    NSMutableDictionary* folders = [[NSMutableDictionary alloc] init];
    
    FolderInfo* rootFolderInfo = nil;
    for (NSDictionary* folderObj in array){
        if([[folderObj objectForKey:@"STATE"] isEqualToString:@"0"])
            continue;
        NSString* cid = [folderObj objectForKey:@"CID"];
        NSString* pid = [folderObj objectForKey:@"PID"];
        FolderInfo* parent = [folders objectForKey:pid];
        
        if(nil == parent && ![pid isEqualToString:@"0"])
            continue;
        
        FolderInfo* info = [[FolderInfo alloc] init];
        info.subFolders = nil;
        [folders setObject:info forKey:cid];
        
        if ([pid isEqualToString:@"0"]) {
            info.folderPath = [folderObj objectForKey:@"NAME"];
            rootFolderInfo = info;
            continue;
        }
        info.folderPath = [parent.folderPath stringByAppendingFormat:@"/%@",
                           [[folderObj objectForKey:@"NAME"] stringByTrimmingCharactersInSet:
                                [NSCharacterSet characterSetWithCharactersInString:@"/"]]];
        if(nil == parent.subFolders) {
            parent.subFolders = [[NSMutableArray alloc] init];
        }
        [parent.subFolders addObject:info];
    }
    
    return rootFolderInfo;
}

+ (NSString *)shareAlbumWithFiles:(NSArray *)files{
    NSDictionary* paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"ALBUMSHARE", @"METHOD",
                          @"ADD", @"TYPE",
                          files, @"FILELIST", nil];
#if !FAKE_INTERFACE
    NSDictionary* resultDict = [self callCTransactProcWithParam:paramDict];
#else
    NSString* out  = @"{\"RESULT\":\"SUCCESS\", \"ID\":\"112\"}";
    NSDictionary* resultDict = [[[SBJsonParser alloc] init] objectWithString:out];
#endif
    if(![self checkResultWithJSON:resultDict])
        return @"";
    return [resultDict objectForKey:@"ID"];
}

+ (int)getAlbumShareState:(NSString *)albumShareID{
    NSDictionary* paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"ALBUMSHARE", @"METHOD",
                          @"GETSHARESTATE", @"TYPE",
                          albumShareID, @"OBJECTID", nil];
#if !FAKE_INTERFACE
    NSDictionary* resultDict = [self callCTransactProcWithParam:paramDict];
#else
    NSString* out  = @"{\"RESULT\":\"SUCCESS\", \"ID\":\"112\"}";
    NSDictionary* resultDict = [[[SBJsonParser alloc] init] objectWithString:out];
#endif

    if(![self checkResultWithJSON:resultDict])
        return -1;
    return [[resultDict objectForKey:@"STATE"] intValue];
}
@end
