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
static int lastNetworkStatus = NotReachable;

+ (void)showAlert{
    dispatch_async(dispatch_get_main_queue(), ^(){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"网络不可用" message:@"无法连接到久久宝盒，请连接到无线或者移动数据网络。" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
        [alertView show];
    });
}

+ (BOOL) startNetworkMonitor{
    if(!reachability){
        reachability = [Reachability reachabilityForLocalWiFi];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkChange:) name:kReachabilityChangedNotification object:nil];
        [reachability startNotifier];
    }
    
    lastNetworkStatus = [reachability currentReachabilityStatus];
    if(lastNetworkStatus == NotReachable) {
        [self showAlert];
        return NO;
    }
    return YES;
}

+ (void) handleNetworkChange:(NSNotificationCenter *)notice {
    if([reachability currentReachabilityStatus] == NotReachable && lastNetworkStatus != NotReachable) {
            [self showAlert];
            lastNetworkStatus = NotReachable;
    }
    lastNetworkStatus = [reachability currentReachabilityStatus];
}

+ (BOOL) isNetworkAvailable{
    return [reachability currentReachabilityStatus] != NotReachable;
}

+ (Reachability *)getCurReachability{
    return reachability;
}
@end
