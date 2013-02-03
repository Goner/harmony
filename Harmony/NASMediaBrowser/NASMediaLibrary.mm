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

#define INTERFACE_OK 1
#define FAKE_NASSERVER 1

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

- (NSString *) description {
    return [NSString stringWithFormat: @"MediaObject: %@, %@", title, id];
}
@end

@implementation MediaContainer
@synthesize childrenCount;

- (NSString *)description {
    return [[NSString stringWithFormat:@"MediaContainer: %d, ", childrenCount] stringByAppendingString: [super description]];
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
        @"http://img26.nipic.com/20110808/7485157_075051018000_1.png",@"Thumbnail",
        @"http://news.xinhuanet.com/yzyd/travel/20130130/145710538519106419931n.jpg",@"Resized",
        @"http://pic15.nipic.com/20110701/5198878_162433615197_2.jpg",@"MediaItems",nil];

    return [fakeURLs objectForKey:key];
#else
    for(Resource* resource in resouces) {
        NSRange rng = [resource.uri rangeOfString:type options:NSCaseInsensitiveSearch];
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
+ (BOOL) checkResultWithJSON:(NSDictionary *)JSONDict;
+ (NSString *) callCTransactProcWithParam:(NSString *)param;
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
        
        [array addObject:category];
    }
   
    return array;
}

+ (NSArray*) getCategories:(MediaCategory *) mediaCatogery {
#if FAKE_NASSERVER
    NSMutableArray* array = [[NSMutableArray alloc] init];
    for(int i = 0; i < 5; i++) {
        MediaCategory* category = [[MediaCategory alloc] init];
        category.title = [NSString  stringWithFormat:@"title%d",i ];
        category.id = [NSString  stringWithFormat:@"id%d",i];
        category.childrenCount = i+1;
        
        [array addObject:category];
    }
    return array;
#else
    if (!nasMediaBrowserPtr) {
        return nil;
    }
    PLT_MediaObjectListReference  pltMediaList(new PLT_MediaObjectList);
    char objID[1025] = {0};
    [mediaCatogery.id getCString: objID maxLength: 1024 encoding:NSUTF8StringEncoding];
    nasMediaBrowserPtr->Browser(objID, pltMediaList);
    
    NSMutableArray* array = [[NSMutableArray alloc] init];
    for (int i = 0; i < pltMediaList->GetItemCount(); i++) {
        PLT_MediaContainer* container = (PLT_MediaContainer*)(*pltMediaList->GetItem(i));
        
        MediaCategory* category = [[MediaCategory alloc] init];
        
        category.title = [NSString  stringWithCString:container->m_Title encoding:NSUTF8StringEncoding];
        category.id = [NSString  stringWithCString:container->m_ObjectID encoding:NSUTF8StringEncoding];
        category.childrenCount = container->m_ChildrenCount;
        
        [array addObject:category];
    }
    
    return array;
#endif
}

+ (NSArray *) getFirstMediaItems:(NSArray *)catogeries{
    NSMutableArray *firstMediaItems = [[NSMutableArray alloc] init];
    for(MediaCategory *category in catogeries) {
        NSArray *mediaItems = [self getMediaItems:category withMaxResults:1];
        if([mediaItems count] > 0) {
            [firstMediaItems addObject:[mediaItems objectAtIndex:0]];
        }
    }
    return firstMediaItems;
}

+ (NSArray*) getMediaItems:(MediaCategory *)catogery {
    return [self getMediaItems:catogery withMaxResults:0];
}

+ (NSArray *)getMediaItems:(MediaCategory *)catogery withMaxResults:(int)maxResults{
#if FAKE_NASSERVER
    NSMutableArray* array = [[NSMutableArray alloc] init];
    for(int i = 0; i < 6; i++) {
        MediaItem* item = [[MediaItem alloc] init]; 
        item.title = [NSString  stringWithFormat:@"item_title_%d", i];
        item.id = [NSString  stringWithFormat:@"item_id_%d", i];
        item.creator = [NSString  stringWithFormat:@"item_creator_%d", i];
        item.date = [NSString  stringWithFormat:@"item_date_%d", i];
        [array addObject:item];
    }
    return array;
#else
    if (!nasMediaBrowserPtr) {
        return nil;
    }
    PLT_MediaObjectListReference  pltMediaList(new PLT_MediaObjectList);
    char objID[1025] = {0};
    [catogery.id getCString: objID maxLength: 1024 encoding:NSUTF8StringEncoding];
    nasMediaBrowserPtr->Browser(objID, pltMediaList, 0, maxResults);
    
    NSMutableArray* array = [[NSMutableArray alloc] init];
    for (int i = 0; i < pltMediaList->GetItemCount(); i++) {
        PLT_MediaItem* mediaItem = (PLT_MediaItem*)(*pltMediaList->GetItem(i));
        
        MediaItem* item = [[MediaItem alloc] init];
        
        item.title = [NSString  stringWithCString:mediaItem->m_Title encoding:NSUTF8StringEncoding];
        item.id = [NSString  stringWithCString:mediaItem->m_ObjectID encoding:NSUTF8StringEncoding];
        item.creator = [NSString  stringWithCString:mediaItem->m_Creator encoding:NSUTF8StringEncoding];
        item.date = [NSString  stringWithCString:mediaItem->m_Date encoding:NSUTF8StringEncoding];
        
        NSMutableArray* resources = [[NSMutableArray alloc] init];
        
        for (int resourceIndex = 0;  resourceIndex < mediaItem->m_Resources.GetItemCount(); resourceIndex++) {
            PLT_MediaItemResource* pltResourcde = mediaItem->m_Resources.GetItem(resourceIndex);
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
        item.resouces = resources;
        
        [array addObject:item];
    }

    return array;
#endif
}

+ (NSString *) callCTransactProcWithParam:(NSString *)param{
    int len = 0;
    char* inParameter = (char*)[param UTF8String];
    transact_proc_call(inParameter, NULL, &len);
    char* outParameter = (char*)malloc(++len);
    transact_proc_call(inParameter, outParameter, &len);
    NSString* result = [NSString stringWithCString:outParameter encoding:NSUTF8StringEncoding];
    free(outParameter);
    
    return result;
}

+ (BOOL) checkResultWithJSON:(NSDictionary *)JSONDict{
    return [[JSONDict objectForKey:@"RESULT"] isEqualToString:@"SUCCESS"];
}

+ (NSArray *) getFriendList {
    NSString* parameter = @"{\"METHOD\":\"FRIEND\", \"TYPE\":\"GETFRIENDLIST\"}";
#if INTERFACE_OK
    NSString* out = [self callCTransactProcWithParam: parameter];
#else
     NSString* out =  @"{\"RESULT\":\"SUCCESS\", \"LIST\": [{\"NAME\":\"123\", \"SN”:\"22\", \"ONLINE\":true, \"SHIELD\":false},{\"NAME\":\"WWW\", \"SN\":\"333\", \"ONLINE\":false, \"SHIELD\":true}]}";
#endif
    SBJsonParser* parser = [[SBJsonParser alloc] init];
    NSDictionary* dict = [parser objectWithString:out];
    if([self checkResultWithJSON: dict])
        return nil;
    
    NSArray* friends = [[NSMutableArray alloc] init];
    NSArray* array = [dict objectForKey:@"LIST"];
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
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                  @"SHARE", @"METHOD",
                  @"ADD", @"TYPE",
                  folder, @"FOLDER",
                   users, @"FRIENDLIST", nil];
    NSString* parameter  = [[[SBJsonWriter alloc] init] stringWithObject:dict];
#if INTERFACE_OK
    NSString* out = [self callCTransactProcWithParam:parameter];
#else
    NSString* out  = @"{\"RESULT\":\"SUCCESS\"}";
#endif
    NSDictionary* resultDict = [[[SBJsonParser alloc] init] objectWithString:out];
    return [self checkResultWithJSON: resultDict];
}

+ (BOOL) unshareFolder:(NSString *)folder {
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"SHARE", @"METHOD",
                        @"REMOVE", @"TYPE",
                        folder, @"FOLDER", nil];
    NSString* parameter  = [[[SBJsonWriter alloc] init] stringWithObject:dict];
#if INTERFACE_OK
    NSString* out = [self callCTransactProcWithParam:parameter];
#else
    NSString* out  = @"{\"RESULT\":\"SUCCESS\"}";
#endif
    NSDictionary* resultDict = [[[SBJsonParser alloc] init] objectWithString:out];
    return [self checkResultWithJSON: resultDict];
    
}

+ (NSArray *) getAllShareInfos {
    NSString* parameter = @"{\"METHOD\":\"SHARE\", \"TYPE\":\"QUERY\"}";
#if INTERFACE_OK
    NSString* out = [self callCTransactProcWithParam: parameter];
#else
    NSString* out =  @"{\"RESULT\":\"SUCCESS\", \"LIST\":[{\"FOLDER\":\"FODLDER1\", \"FRIENDLIST\": [{\"NAME\":\"123\", \"SN”:\"22\"}, {\"NAME\":\"WWW\", \"SN”:\"33\"}]},{\"FOLDER\":\"FODLDER2\", \"FRIENDLIST\": [{\"NAME\":\"WW\", \"SN”:\"33\"}, {\"NAME\":\"ZZ\", \"SN”:\"BB\"}]}]}";
#endif
    NSDictionary* resultDict = [[[SBJsonParser alloc] init] objectWithString:out];
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
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"SHARE", @"METHOD",
                        @"GETSHARESTATE", @"TYPE",
                        friendName, @"FRIENDNAME",
                        folder, @"FOLDER", nil];
    NSString* parameter  = [[[SBJsonWriter alloc] init] stringWithObject:dict];
#if INTERFACE_OK
    NSString* out = [self callCTransactProcWithParam:parameter];
#else
    NSString* out  = @"{\"RESULT\":\"SUCCESS\", \"STATE\":\"80\"}";
#endif
    NSDictionary* resultDict = [[[SBJsonParser alloc] init] objectWithString:out];
    
    return [self checkResultWithJSON: resultDict] ? [[resultDict objectForKey:@"STATE"] intValue] : 0;
}

//management interface
+ (BOOL) tagFavoriteObj:(NSString *)objID {
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"FAVOR", @"METHOD",
                        @"ADD", @"TYPE",
                        objID, @"OBJECTID", nil];
    NSString* parameter  = [[[SBJsonWriter alloc] init] stringWithObject:dict];
#if INTERFACE_OK
    NSString* out = [self callCTransactProcWithParam:parameter];
#else
    NSString* out  = @"{\"RESULT\":\"SUCCESS\", \"STATE\":\"80\"}";
#endif
    NSDictionary* resultDict = [[[SBJsonParser alloc] init] objectWithString:out];
    
    return [self checkResultWithJSON: resultDict];
}

+ (BOOL) untagFavoriteObj:(NSString *)objID {
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"FAVOR", @"METHOD",
                        @"DELETE", @"TYPE",
                        objID, @"OBJECTID", nil];
    NSString* parameter  = [[[SBJsonWriter alloc] init] stringWithObject:dict];
#if INTERFACE_OK
    NSString* out = [self callCTransactProcWithParam:parameter];
#else
    NSString* out  = @"{\"RESULT\":\"SUCCESS\", \"STATE\":\"80\"}";
#endif
    NSDictionary* resultDict = [[[SBJsonParser alloc] init] objectWithString:out];
    
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
@end


//test
//    {
//        NSArray* categories = [PhotoLibrary GetPhotoCategories];
//        NSLog(@"%@", categories);
//        NSArray* albums = [PhotoLibrary GetPhotoAlbums: [categories objectAtIndex: 0]];
//        NSLog(@"%@", albums);
//        NSArray* photoItems = [PhotoLibrary GetPhotoItems: [albums objectAtIndex:0]];
//        NSLog(@"%@", photoItems);
//    }
