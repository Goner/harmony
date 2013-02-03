//
//  GridViewController.h
//  Merry992
//
//  Created by hongyu on 13-1-20.
//  Copyright (c) 2013年 why. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScrollGridView.h"
#import "GridCellView.h"
#import "MWPhotoBrowser.h"
#import "MainController.h"
#import "NASMediaLibrary.h"

@class MediaResourceFetcher;

@interface GridViewController : UIViewController<ScrollGridViewDataSource, GridCellViewDelegate, MWPhotoBrowserDelegate>


@property (weak, nonatomic) IBOutlet ScrollGridView *gridView;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGes;
@property (nonatomic) BOOL multiSelectionMode;
@property (nonatomic) BOOL topGidView;
@property (nonatomic, weak) MainController *rootController;

@property (nonatomic, strong) NSArray *mediaObjects;
@property (nonatomic, strong) MediaResourceFetcher* fetcher;

- (void)loadTopCatogery:(MediaCategory *)topCategory;
@end
