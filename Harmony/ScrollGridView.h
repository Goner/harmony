//
//  ScrollGridView.h
//  Merry992
//
//  Created by hongyu on 13-1-20.
//  Copyright (c) 2013年 why. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ScrollGridView;

@protocol ScrollGridViewDataSource <NSObject>

- (int) numberOfCellsInView: (ScrollGridView *) gridView;
- (UIView *) viewAtIndex: (int) index;

@end

@interface ScrollGridView : UIScrollView

@property (nonatomic) int numberOfColumns;
@property (nonatomic) int cellWidth;
@property (nonatomic) int cellHeight;
@property (nonatomic) int cellHSpace;
@property (nonatomic) int cellVSpace;
@property (nonatomic) int hMargin;
@property (nonatomic) int vMargin;

@property (nonatomic, strong) id<ScrollGridViewDataSource> dataSource;
@property (nonatomic, strong) NSMutableArray *cells;


- (void) reloadData;
- (void) clearAllSelected;


@end
