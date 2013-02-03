//
//  SimpleKeychain.h
//  Harmony
//
//  Created by Anomie on 9/3/11 from StackOverflow
//  Copyright (c) 2011. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SimpleKeychain : NSObject
+ (void)save:(NSString *)service data:(id)data;
+ (id)load:(NSString *)service;
+ (void)delete:(NSString *)service;
@end
