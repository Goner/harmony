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
#import "UIDevice+IdentifierAddition.h"

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
- (NSString *)getThumbnailURL {
    return nil;
}

- (NSString *)getResizedURL {
    return nil;
}

- (NSString *)getMediaURL {
    return nil;
}
@end

@implementation MediaCategory
@synthesize childrenCount;

- (NSString *)description {
    return [[NSString stringWithFormat:@"MediaContainer: %d, ", childrenCount] stringByAppendingString: [super description]];
}

- (NSString *)getThumbnailURL {
    NSString * sid = [[NASMediaLibrary getServerBaseURL] stringByAppendingFormat:@"%@", self.id];
    return [[NASMediaLibrary getServerBaseURL] stringByAppendingFormat:@"/Thumbnails/%@", self.id];
}

- (NSString *)getResizedURL {
    return [[NASMediaLibrary getServerBaseURL] stringByAppendingFormat:@"/Resized/%@", self.id];
}

- (NSString *)getMediaURL {
    return [[NASMediaLibrary getServerBaseURL] stringByAppendingFormat:@"/MediaItems/%@", self.id];
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
    return [[NSString stringWithFormat:@"MediaItem: %@, %@, %@,", creator, date, resources] stringByAppendingString: [super description]];
}

- (NSString *)getURLForKey:(NSString *)key{
#if FAKE_NASSERVER
    static NSDictionary* fakeURLs = [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"http://img3.cache.netease.com/photo/0008/2012-03-27/t_7TK32ME629A50008.jpg",@"Thumbnails",
                                     @"http://pic15.nipic.com/20110701/5198878_162433615197_2.jpg",@"Resized",
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
    return [self getURLForKey:@"Thumbnails"];
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

- (BOOL) isEqual:(id)object{
    if([object isKindOfClass:[User class]]){
        return [self hash] == [object hash];
    }
    return FALSE;
}

- (NSUInteger)hash{
    return [[self description] hash];
}

@end

@implementation Friend
@synthesize isOnline;
@synthesize isShield;

- (NSString *)description {
    return [[super description] stringByAppendingFormat:@", online: %d, shield: %d", isOnline, isShield];
}

- (BOOL) isEqual:(id)object{
    if([object isKindOfClass:[Friend class]]){
        return [self.name compare:((Friend *)object).name] == NSOrderedSame;
    }
    return FALSE;
}

- (NSUInteger)hash{
    return [self.name hash];
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
static NPT_String ipAddress;
static NSString * loginedUserName;

+ (BOOL) initWithUser:(NSString *)user password:(NSString *)passwd {
    nasMediaBrowserPtr = nullptr;
    bRemoteAccess = FALSE;
    const char* userName = [user UTF8String];
    const char* password = [passwd UTF8String];
#if FAKE_NASSERVER
    loginedUserName = user;
    ipAddress = "127.0.0.1";
    return TRUE;
#else
    nasMediaBrowserPtr = std::make_shared<NASLocalMediaBrowser>();
    if(NPT_SUCCEEDED(nasMediaBrowserPtr->Connect())){
        ipAddress = nasMediaBrowserPtr->GetIpAddress();
        if(local_access_auth(ipAddress, userName, password) != 0){
            return FALSE;
        }
        bRemoteAccess = FALSE;
    } else {    
        nasMediaBrowserPtr = std::make_shared<NASRemoteMediaBrowser>(userName,  password, "license");
        if(NPT_FAILED(nasMediaBrowserPtr->Connect())){
            return FALSE;
        }
        ipAddress = nasMediaBrowserPtr->GetIpAddress();
        bRemoteAccess = TRUE;
    }
    loginedUserName = user;
    return TRUE;
#endif
}

+ (NSString *)getServerBaseURL{
    return [NSString stringWithFormat:@"http://%s:8200",ipAddress.GetChars()];
}

+ (BOOL)isRemoteAccess{
    return bRemoteAccess;
}

+ (NSString *)getLoginedUserName{
    return loginedUserName;
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
        {ImageFavorID, ImageFavorTitle},
        {ImagePersonID,IMagePersonTitle},
        {ImageDateID, ImageDateTitle}
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

+ (NSArray *) getMediaObjects:(MediaCategory *)category withMaxResults:(int)maxResults{
#if FAKE_NASSERVER
    NSMutableArray* array = [[NSMutableArray alloc] init];
//    for(int i = 0; i < 5; i++) {
//        MediaCategory* categoryChild = [[MediaCategory alloc] init];
//        categoryChild.title = [NSString  stringWithFormat:@"title%d",i ];
//        categoryChild.id = [NSString  stringWithFormat:@"id%d",i];
//        categoryChild.childrenCount = i+1;
//        categoryChild.parentCategory = category;
//        [array addObject:categoryChild];
//    }
    for(int i = 0; i < 16; i++) {
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
    nasMediaBrowserPtr->Browser([category.id UTF8String], pltMediaList, 0, maxResults);
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    if(pltMediaList.IsNull()){
        return array;
    }

    for (int i = 0; i < pltMediaList->GetItemCount(); i++) {
        MediaObject *object = [self convToMediaObjct:*pltMediaList->GetItem(i)];
        object.parentCategory = category;
        [array addObject: object];
    }
    return array;
#endif
}

+ (NSDictionary *) callCTransactProcWithParam:(NSDictionary *)paramDict{
    NSString* parameter  = [[[SBJsonWriter alloc] init] stringWithObject:paramDict];
    const char* inParameter = [parameter UTF8String];
    const char* outParameter = transact_proc_call(inParameter);
    NSString* result = [NSString stringWithCString:outParameter encoding:NSUTF8StringEncoding];
    free((void*)outParameter);
    return [[[SBJsonParser alloc] init] objectWithString:result];
}

+ (BOOL) checkResultWithJSON:(NSDictionary *)JSONDict{
    return [[JSONDict objectForKey:@"RESULT"] isEqualToString:@"SUCCESS"];
}

+ (NSArray *) getFriendList {
    NSDictionary *paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"FRIEND", @"METHOD",
                               @"GETFRIENDLIST", @"TYPE", nil];
#if !FAKE_INTERFACE
    NSDictionary* resultDict = [self callCTransactProcWithParam: paramDict];
#else
     NSString* out =  @"{\"RESULT\":\"SUCCESS\", \"LIST\": [{\"NAME\":\"123\", \"SN\":\"22\", \"ONLINE\":true, \"SHIELD\":false},{\"NAME\":\"WWW\", \"SN\":\"333\", \"ONLINE\":false, \"SHIELD\":true}]}";
     NSDictionary* resultDict = [[[SBJsonParser alloc] init] objectWithString:out];
#endif
    if(![self checkResultWithJSON: resultDict])
        return nil;
    
    NSMutableArray* friends = [[NSMutableArray alloc] init];
    NSArray* array = [resultDict objectForKey:@"LIST"];
    for(NSDictionary* obj in array) {
        Friend* f = [[Friend alloc] init];
        f.name = [obj objectForKey:@"NAME"];
        f.sn = [obj objectForKey:@"SN"];
        f.isOnline = [[obj objectForKey:@"ONLINE"] boolValue];
        f.isShield = [[obj objectForKey:@"SHIELD"] boolValue];
        [friends addObject:f];
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

+ (BOOL) unshareFolder:(NSString *)folder withFriends:(NSArray *)friends{
    NSMutableArray* users = [[NSMutableArray alloc] init];
    for (User* user in friends) {
        [users addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                          user.name, @"NAME",user.sn,@"SN", nil]];
    }
    NSDictionary* paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"SHARE", @"METHOD",
                        @"REMOVE", @"TYPE",
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

+ (NSArray *) getAllShareFolders {
    NSDictionary* paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"SHARE", @"METHOD",
                               @"QUERYFOLDER", @"TYPE", nil];
#if !FAKE_INTERFACE
    NSDictionary* resultDict = [self callCTransactProcWithParam: paramDict];
#else
    NSString* out =  @"{\"RESULT\":\"SUCCESS\", \"LIST\":[{\"FOLDER\":\"FODLDER1\"},{\"FOLDER\":\"FODLDER2\"}]}";
    NSDictionary* resultDict = [[[SBJsonParser alloc] init] objectWithString:out];
#endif
    if (![self checkResultWithJSON: resultDict])
        return nil;
    NSArray* array = [resultDict objectForKey:@"LIST"];
    NSMutableArray* folders = [[NSMutableArray alloc] init];
    for(NSDictionary* obj in array) {
        NSString *folder = [obj objectForKey:@"FOLDER"];
        [folders addObject:folder];
    }
    return folders;
}

+ (NSArray *)getFriendsSharedWithFolder:(NSString *)folder {
    NSDictionary* paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"SHARE", @"METHOD",
                               @"QUERY", @"TYPE",
                               folder, @"FOLDER",nil];
#if !FAKE_INTERFACE
    NSDictionary* resultDict = [self callCTransactProcWithParam: paramDict];
#else
    NSString* out =  @"{\"RESULT\":\"SUCCESS\", \"LIST\": [{\"NAME\":\"123\", \"SN\":\"22\", \"ONLINE\":true, \"SHIELD\":false},{\"NAME\":\"WWW\", \"SN\":\"333\", \"ONLINE\":false, \"SHIELD\":true}]}";
    NSDictionary* resultDict = [[[SBJsonParser alloc] init] objectWithString:out];
#endif
    if(![self checkResultWithJSON: resultDict])
        return nil;
    
    NSMutableArray* friends = [[NSMutableArray alloc] init];
    NSArray* array = [resultDict objectForKey:@"LIST"];
    for(NSDictionary* obj in array) {
        Friend* f = [[Friend alloc] init];
        f.name = [obj objectForKey:@"NAME"];
        f.sn = [obj objectForKey:@"SN"];
        f.isOnline = [[obj objectForKey:@"ONLINE"] boolValue];
        f.isShield = [[obj objectForKey:@"SHIELD"] boolValue];
        [friends addObject:f];
    }
    
    return friends;
}

+ (NSArray *) getSubFolders:(NSString *)folder {
    NSDictionary* paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"SHARE", @"METHOD",
                               @"GETFOLDER", @"TYPE",
                               [folder stringByAppendingString:@"/"], @"FOLDER",nil];
#if !FAKE_INTERFACE
    NSDictionary* resultDict = [self callCTransactProcWithParam: paramDict];
#else
    NSString* out =  @"{\"RESULT\":\"SUCCESS\", \"FOLDERLIST\":[\"FODLDER1\", \"FODLDER2\"]}";
    NSDictionary* resultDict = [[[SBJsonParser alloc] init] objectWithString:out];
#endif
    if (![self checkResultWithJSON: resultDict])
        return nil;
    return [resultDict objectForKey:@"FOLDERLIST"];
}

//management interface
+ (BOOL) tagFavoriteObjects:(NSArray *)favors {
    NSDictionary* paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"FAVOR", @"METHOD",
                        @"ADD", @"TYPE",
                        favors, @"OBJECTIDLIST", nil];
#if !FAKE_INTERFACE
    NSDictionary* resultDict = [self callCTransactProcWithParam: paramDict];
#else
    NSString* out  = @"{\"RESULT\":\"SUCCESS\", \"STATE\":\"80\"}";
    NSDictionary* resultDict = [[[SBJsonParser alloc] init] objectWithString:out];
#endif
    return [self checkResultWithJSON: resultDict];
}

+ (BOOL) untagFavoriteObjects:(NSArray *)unFavors {
    NSDictionary* paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"FAVOR", @"METHOD",
                        @"DELETE", @"TYPE",
                        unFavors, @"OBJECTIDLIST", nil];
#if !FAKE_INTERFACE
    NSDictionary* resultDict = [self callCTransactProcWithParam:paramDict];
#else
    NSString* out  = @"{\"RESULT\":\"SUCCESS\", \"STATE\":\"80\"}";
    NSDictionary* resultDict = [[[SBJsonParser alloc] init] objectWithString:out];
#endif
    return [self checkResultWithJSON: resultDict];
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

+ (BOOL) commitPrinttaskForFiles:(NSArray *)files{
    NSMutableArray *printTask = [[NSMutableArray alloc] init];
    for (NSString *file in files) {
        NSDictionary *printItem = [NSDictionary dictionaryWithObjectsAndKeys:
                                   file, @"FILEPATH",
                                   @"A4", @"PAPER",
                                   @"16", @"SIZE",
                                    @"1", @"COUNT", nil];
       [printTask addObject:printItem];
    }
    NSDictionary* paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"SERVICE", @"METHOD",
                               @"COMMITPRINT", @"TYPE",
                               printTask, @"PRINTLIST", nil];
#if !FAKE_INTERFACE
    NSDictionary* resultDict = [self callCTransactProcWithParam:paramDict];
#else
    NSString* out  = @"{\"RESULT\":\"SUCCESS\"}";
    NSDictionary* resultDict = [[[SBJsonParser alloc] init] objectWithString:out];
#endif
    return [self checkResultWithJSON: resultDict];
}

+ (NSArray *) getNASMessages{
    NSDictionary* paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"SERVICE", @"METHOD",
                               @"GETSERVICESTATUS", @"TYPE", nil];
#if !FAKE_INTERFACE
    NSDictionary* resultDict = [self callCTransactProcWithParam:paramDict];
#else
    NSString* out  = @"{\"RESULT\":\"SUCCESS\",\"SERVICELOGLIST\":[{\"NOTIFY\":\"久久相册共享已经成功\"},{\"NOTIFY\":\"久久冲印小图已经上传，可以开始制作影集了！大图传送中….\"},{\"NOTIFY\":\"久久冲印大图已经上传成功，订单号码:xxx\"}]}";
    NSDictionary* resultDict = [[[SBJsonParser alloc] init] objectWithString:out];
#endif
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    if(![self checkResultWithJSON: resultDict]) {
        return messages;
    }
    
    NSArray *notifys = [resultDict objectForKey:@"SERVICELOGLIST"];
    for (NSDictionary *notify in notifys) {
        [messages addObject:[notify objectForKey:@"NOTIFY"]];
    }
    return messages;
}

//file data exchange interface
static NSString *uniqueID = [[UIDevice currentDevice] uniqueDeviceIdentifier];;
+ (NSData *) getVCardData{
    char *vcardData = NULL;
    int len = get_vcard_data([uniqueID UTF8String], &vcardData);
    if(len < 0) {
        return nil;
    }
    return [NSData dataWithBytesNoCopy:vcardData length:len freeWhenDone:YES];
}

+ (BOOL) backupVCardData:(NSData *)vCardData{
    int ret =transfer_vcard((const char*)[vCardData bytes], [vCardData length], [uniqueID UTF8String]);
    return ret == 0;
}

+ (BOOL) backupPhotoData:(NSData *)photoData withName:(NSString *)name{
    int ret =transfer_photo((const char*)[photoData bytes], [photoData length], [name UTF8String], [uniqueID UTF8String]);
    return ret == 0;
}
@end
