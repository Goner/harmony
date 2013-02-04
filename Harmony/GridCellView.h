//
//  GridCellView.h
//  Merry992
//
//  Created by hongyu on 13-1-20.
//  Copyright (c) 2013年 why. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GridCellViewDelegate <NSObject>

-(void) onTap: (UIView *) view;

@end

@interface GridCellView : UIView
@property (weak, nonatomic) IBOutlet UIImageView *pictureView;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UIImageView *favorImage;

@property (nonatomic) int contentIndex;
@property (nonatomic) BOOL selected;

@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;

@property (nonatomic, weak) id<GridCellViewDelegate> delegate;

+ (GridCellView *) cellViewFromNib;
- (void) setImage: (UIImage *) image;
- (void) tagFavor;
- (void) untagFavor;
@end
