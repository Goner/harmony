//
//  NetWorkStateMonitor.h
//  Harmony
//
//  Created by robin on 3/23/13.
//  Copyright (c) 2013 久久相悦. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"

@interface NetWorkStateMonitor : NSObject
+ (BOOL) startLocalNetworkMonitor;
+ (BOOL) startRemoteServerMonitor;
+ (BOOL) isNetworkAvailable;
+ (Reachability *)getCurReachability;
@end
