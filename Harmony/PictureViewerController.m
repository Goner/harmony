//
//  PictureViewerController.m
//  Merry992
//
//  Created by hongyu on 13-1-22.
//  Copyright (c) 2013年 why. All rights reserved.
//

#import "PictureViewerController.h"

@interface PictureViewerController ()

@end

@implementation PictureViewerController



- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (void) viewWillAppear:(BOOL)animated
{
    [self.rootController hideButtonBack: NO];
    [self.rootController hideBottomBar: NO];
    [MainController setTopBarTitle:@""];
    [self.navigationController.view setFrame: [self.rootController rectWithBottomBar]];
}

@end
