//
//  ScrollGridView.m
//  Merry992
//
//  Created by hongyu on 13-1-20.
//  Copyright (c) 2013年 why. All rights reserved.
//

#import "ScrollGridView.h"
#import "GridCellView.h"

@implementation ScrollGridView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        self.cells = [[NSMutableArray alloc] initWithCapacity: 128];
    }
        
    return self;
}

- (void) reloadData
{
    int numberOfCells = [self.dataSource numberOfCellsInView:self];
    int numberOfRows = (numberOfCells + 2) / self.numberOfColumns;
    float width = self.bounds.size.width;
    float height = (self.cellHeight + self.cellVSpace) * numberOfRows + self.vMargin * 2;
    CGSize csize = CGSizeMake(width, height);
    [self setContentSize: csize];
    
    for (UIView *view in self.cells) {
        [view removeFromSuperview];
    }
    [self.cells removeAllObjects];
    
    for (int i = 0; i < numberOfCells; ++i) {
        UIView *cell = [self.dataSource viewAtIndex: i];
        cell.frame = [self rectAtIndex: i];
        
        [self addSubview: cell];
        [self.cells addObject: cell];
    }
    
}

- (void) clearAllSelected
{
    for (GridCellView *cell in self.cells) {
        cell.selected = NO;
    }
}

- (CGRect) rectAtIndex: (int) index
{

    float x = (self.cellWidth + self.cellHSpace) * (index % self.numberOfColumns) + self.hMargin;
    float y = (self.cellHeight + self.cellVSpace) * (index / self.numberOfColumns) + self.vMargin;
    float width = self.cellWidth;
    float height = self.cellHeight;
    
    CGRect ret = CGRectMake(x, y, width, height);
    
    return ret;
}



@end
