//
//  MediaResourceFetcher.m
//  Harmony
//
//  Created by wang zhenbin on 2/2/13.
//  Copyright (c) 2013 久久相悦. All rights reserved.
//

#import "MediaResourceFetcher.h"
#import "interfaceudt_client.h"
#import "ASINetworkQueue.h"
#import "ASIHTTPRequest.h"
#import "AssetsLibrary/ALAssetsLibrary.h"
#import "NASMediaLibrary.h"

@implementation MediaResourceFetcher
@synthesize networkQueue;

- (void) initWithNetworkMode:(enum NETWORK_MODE)mode {
    networkMode = mode;
    self.networkQueue = [[ASINetworkQueue alloc] init];
    [[self networkQueue] go];
}


- (void) getDataFromURL:(NSString *)url completion:(void (^)(NSData *))processData{
    NSData* data = [self getCacheDataForURL:url];
    if (data != nil){
        processData(data);
        return;
    }
    NSURL *mediaURL = [NSURL URLWithString:url];
    if (REMOTE_NETWORK == networkMode){
        mediaURL = [NSURL URLWithString:[[NASMediaLibrary getServerBaseURL] stringByAppendingString:[mediaURL path]]];
    }
    if (LOCAL_NETWORK == networkMode || REMOTE_NETWORK == networkMode) {
        ASIHTTPRequest * __block request = [ASIHTTPRequest requestWithURL:mediaURL];
        [request setCompletionBlock:^{
            NSData *responseData = [request responseData];
            dispatch_async(dispatch_get_main_queue(), ^{
                processData(responseData);
            });
            [self cacheData:responseData forURL:url];
            request = nil;
        }];
        [[self networkQueue] addOperation:request];
    } else {
        int offset = 0;
        NSString *tmpFile = @"tmpfile";
        //getphoto_to_file(imageName, tmpFile);
        NSData *data = [NSData dataWithContentsOfFile:tmpFile];
        processData(data);
    }
}
- (void) cancelDownloads{
    [[self networkQueue] cancelAllOperations];
}

- (NSString *)getFileNameFromURL:(NSString *)url{
    return [[[NSURL URLWithString:url] pathComponents] lastObject];
}

- (NSString *)getCacheFilePathFromURL:(NSString *)url{
    NSString *cacheKey = [[NASMediaLibrary getLoginedUserName] stringByAppendingString:[[[NSURL URLWithString:url] pathComponents] componentsJoinedByString:@"-"]];
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    return [cachesPath stringByAppendingPathComponent:cacheKey];
}

- (NSData *)getCacheDataForURL:(NSString *)url {
    NSString *cacheFile = [self getCacheFilePathFromURL:url];
    return [NSData dataWithContentsOfFile:cacheFile];
}

- (void)cacheData:(NSData *)data forURL:(NSString *)url{
    NSString *cacheFile = [self getCacheFilePathFromURL:url];
    [data writeToFile:cacheFile atomically:YES];
}

- (void)downloadURL :(NSString *)url{
    [self getDataFromURL:url completion:^(NSData *data){
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc]init];
        [library writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:nil];
    }];
}
@end
