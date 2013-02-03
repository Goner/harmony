//
//  MediaResourceFetcher.h
//  Harmony
//
//  Created by wang zhenbin on 2/2/13.
//  Copyright (c) 2013 久久相悦. All rights reserved.
//

#import <Foundation/Foundation.h>

enum NETWORK_MODE {
    LOCAL_NETWORK,
    REMOTE_NETWORK
};

@class ASINetworkQueue;
@interface MediaResourceFetcher : NSObject {
    ASINetworkQueue*    networkQueue;
    enum NETWORK_MODE   networkMode;
}

@property(retain) ASINetworkQueue* networkQueue;
- (void) initWithNetworkMode:(enum NETWORK_MODE)mode;
- (void) getDataFromURL:(NSString *)url completion:(void (^)(NSData *))processData;
- (void) cancelDownloads;
- (NSString *)getFileNameFromURL:(NSString *)url;
- (NSData *)getCacheDataForURL:(NSString *)url;
- (void)cacheData:(NSData *)data forURL:(NSString *)url;
- (NSString *)getCacheFilePathFromURL:(NSString *)url;
- (void)downloadURL:(NSString *)url;
@end
