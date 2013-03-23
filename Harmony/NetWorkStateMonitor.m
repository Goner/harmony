//
//  NetWorkStateMonitor.m
//  Harmony
//
//  Created by robin on 3/23/13.
//  Copyright (c) 2013 久久相悦. All rights reserved.
//

#import "NetWorkStateMonitor.h"
#import "message.h"
#import "DataSynchronizer.h"
#include "NASMediaLibrary.h"


@implementation NetWorkStateMonitor
static Reachability *reachability = nil;
static Reachability *localReachability = nil;
static Reachability *remoteReachability = nil;

+ (void)showAlert{
    dispatch_async(dispatch_get_main_queue(), ^(){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"网络不可用" message:@"无法连接到久久宝盒，请连接到无线或者移动数据网络。" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
        [alertView show];
    });
}

+ (BOOL) startLocalNetworkMonitor{
    if(!localReachability){
        localReachability = [Reachability reachabilityForLocalWiFi];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkChange:) name:kReachabilityChangedNotification object:nil];
        [localReachability startNotifier];
    }
    reachability = localReachability;
    if([reachability currentReachabilityStatus] != NotReachable) {
        return YES;
    }
    [self showAlert];
    return NO;
}

+ (BOOL) startRemoteServerMonitor{
    if(!remoteReachability) {
        struct sockaddr_in serverAddress;
        bzero(&serverAddress, sizeof(serverAddress));
        serverAddress.sin_len = sizeof(serverAddress);
        serverAddress.sin_family = AF_INET;
        serverAddress.sin_addr.s_addr = inet_addr(SERVERIP);
        remoteReachability = [Reachability reachabilityWithAddress:&serverAddress];
        [remoteReachability startNotifier];
    }

    reachability = remoteReachability;
    if([reachability currentReachabilityStatus] != NotReachable) {
        return YES;
    }
    [self showAlert];
    return NO;
}

+ (void) handleNetworkChange:(NSNotificationCenter *)notice {
    if([localReachability currentReachabilityStatus] == NotReachable) {
        [self showAlert];
    }
    if([NASMediaLibrary isRemoteAccess] && [remoteReachability currentReachabilityStatus] ==NotReachable){
        [self showAlert];
    }
}

+ (BOOL) isNetworkAvailable{
    return [reachability currentReachabilityStatus] != NotReachable;
}

+ (Reachability *)getCurReachability{
    return reachability;
}
@end
