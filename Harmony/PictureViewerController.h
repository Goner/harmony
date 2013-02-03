//
//  PictureViewerController.h
//  Merry992
//
//  Created by hongyu on 13-1-22.
//  Copyright (c) 2013年 why. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWPhotoBrowser.h"
#import "MainController.h"

@interface PictureViewerController : MWPhotoBrowser;

@property (nonatomic, weak) MainController *rootController;

//@property (nonatomic, weak) MWPhotoBrowser *pictureController;

//- (id) initWithDelegate: (id<MWPhotoBrowserDelegate>) delegate rootController: (MainController *) rootController;

@end
