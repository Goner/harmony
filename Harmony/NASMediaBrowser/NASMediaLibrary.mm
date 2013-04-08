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
#import "NetWorkStateMonitor.h"
#import "NASError.h"

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
    for(Resource* resource in resources) {
        NSRange rng = [resource.uri rangeOfString:key options:NSCaseInsensitiveSearch];
        if(rng.location != NSNotFound) {
            NSString *url = resource.uri;
            if([NASMediaLibrary isRemoteAccess]) {
                url = [[NASMediaLibrary getServerBaseURL] stringByAppendingString:[[NSURL URLWithString:url] path]];
            }
            return url;
        }
    }
    return nil;
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
@synthesize isShared;

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
static NASMediaBrowserPtr nasMediaBrowserPtr = nullptr;
static bool bRemoteAccess;
static NPT_String ipAddress;
static NSString *loginedUserName;

+ (NSInteger) initWithUser:(NSString *)user password:(NSString *)passwd {
    bRemoteAccess = FALSE;
    const char* userName = [user UTF8String];
    const char* password = [passwd UTF8String];
    if(![NetWorkStateMonitor isNetworkAvailable]) {
        return E_NETWORK_NOT_AVAILABLE;
    }
    nasMediaBrowserPtr = std::make_shared<NASLocalMediaBrowser>(userName,  password);
    if(NPT_SUCCEEDED(nasMediaBrowserPtr->Connect())){
        bRemoteAccess = FALSE;
    } else {
        if(![NetWorkStateMonitor isNetworkAvailable]) {
            return E_NETWORK_NOT_AVAILABLE;
        }
        nasMediaBrowserPtr = std::make_shared<NASRemoteMediaBrowser>(userName,  password);
        int ret = nasMediaBrowserPtr->Connect();
        if(NPT_FAILED(ret)){
            return ret;
        }
        bRemoteAccess = TRUE;
    }
    ipAddress = nasMediaBrowserPtr->GetIpAddress();
    loginedUserName = user;
    return SUCCESS;
}

+ (BOOL) reconnect {
    if(!nasMediaBrowserPtr) {
        return NO;
    }
    if(NPT_SUCCEEDED(nasMediaBrowserPtr->Reconnect())){
        ipAddress = nasMediaBrowserPtr->GetIpAddress();
        return YES;
    }
    return NO;
}

+ (void) closeConnection {
    if(nasMediaBrowserPtr) {
        nasMediaBrowserPtr->Close();
    }
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
    if(![NetWorkStateMonitor isNetworkAvailable]){
        return nil;
    }
    
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
}

+ (NSDictionary *) callCTransactProcWithParam:(NSDictionary *)paramDict{
    if(![NetWorkStateMonitor isNetworkAvailable]) {
        return nil;
    }
    
    NSString* parameter  = [[[SBJsonWriter alloc] init] stringWithObject:paramDict];
    const char* inParameter = [parameter UTF8String];
    const char* outParameter = transact_proc_call(inParameter);
    if(!outParameter) {
        return nil;
    }
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
    NSDictionary* resultDict = [self callCTransactProcWithParam: paramDict];
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
    NSDictionary* resultDict = [self callCTransactProcWithParam:paramDict];
   
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
    NSDictionary* resultDict = [self callCTransactProcWithParam:paramDict];
    return [self checkResultWithJSON: resultDict];
}

+ (NSArray *) getAllShareFolders {
    NSDictionary* paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"SHARE", @"METHOD",
                               @"QUERYFOLDER", @"TYPE", nil];
    NSDictionary* resultDict = [self callCTransactProcWithParam: paramDict];
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
    NSDictionary* resultDict = [self callCTransactProcWithParam: paramDict];
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
        f.isShared = [[obj objectForKey:@"SHAREFLAG"] boolValue];
        [friends addObject:f];
    }
    
    return friends;
}

+ (NSArray *) getSubFolders:(NSString *)folder {
    NSDictionary* paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"SHARE", @"METHOD",
                               @"GETFOLDER", @"TYPE",
                               [folder stringByAppendingString:@"/"], @"FOLDER",nil];
    NSDictionary* resultDict = [self callCTransactProcWithParam: paramDict];
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
    NSDictionary* resultDict = [self callCTransactProcWithParam: paramDict];
    return [self checkResultWithJSON: resultDict];
}

+ (BOOL) untagFavoriteObjects:(NSArray *)unFavors {
    NSDictionary* paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"FAVOR", @"METHOD",
                        @"DELETE", @"TYPE",
                        unFavors, @"OBJECTIDLIST", nil];
    NSDictionary* resultDict = [self callCTransactProcWithParam:paramDict];
    return [self checkResultWithJSON: resultDict];
}

+ (NSString *)shareAlbumWithFiles:(NSArray *)files{
    NSDictionary* paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"ALBUMSHARE", @"METHOD",
                          @"ADD", @"TYPE",
                          files, @"FILELIST", nil];
    NSDictionary* resultDict = [self callCTransactProcWithParam:paramDict];
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
    NSDictionary* resultDict = [self callCTransactProcWithParam:paramDict];
    return [self checkResultWithJSON: resultDict];
}

+ (NSArray *) getNASMessages{
    NSDictionary* paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"SERVICE", @"METHOD",
                               @"GETSERVICESTATUS", @"TYPE", nil];

    NSDictionary* resultDict = [self callCTransactProcWithParam:paramDict];
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
    if(![NetWorkStateMonitor isNetworkAvailable]){
        return nil;
    }
    char *vcardData = NULL;
    int len = get_vcard_data([uniqueID UTF8String], &vcardData);
    if(len < 0) {
        return nil;
    }
    return [NSData dataWithBytesNoCopy:vcardData length:len freeWhenDone:YES];
}

+ (BOOL) backupVCardData:(NSData *)vCardData{
    if([NetWorkStateMonitor isNetworkAvailable]) {
        int ret =transfer_vcard((const char*)[vCardData bytes], [vCardData length], [uniqueID UTF8String]);
        return ret == 0;
    }
    return NO;
}

+ (BOOL) backupPhotoData:(NSData *)photoData withName:(NSString *)name{
    if ([NetWorkStateMonitor isNetworkAvailable]) {
        int ret =transfer_photo((const char*)[photoData bytes], [photoData length], [name UTF8String], [uniqueID UTF8String]);
        return ret == 0;
    }
    return NO;
}
@end
