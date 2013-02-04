//
//  GridCellView.m
//  Merry992
//
//  Created by hongyu on 13-1-20.
//  Copyright (c) 2013年 why. All rights reserved.
//

#import "GridCellView.h"

@implementation GridCellView

+ (GridCellView *) cellViewFromNib
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"GridCellView" owner:nil options:nil];
    return [array objectAtIndex: 0];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(onTap:)];
        [self addGestureRecognizer: self.tapRecognizer];
    }
    
//    // needed?
//    self.clearsContextBeforeDrawing = NO;
    
    return  self;
}

- (void) setImage: (UIImage *) image
{
//    float w = image.size.width;
//    float h = image.size.height;
//    
//    float width = self.pictureView.bounds.size.width;
//    float height = self.pictureView.bounds.size.height;
//    float rate1 = w/h;
//    float rate2 = width/height;
//    float transformThredhold = 1.2;
//    if ((rate1/rate2) > transformThredhold || (rate1/rate2) < 1/transformThredhold) {
//        self.pictureView.contentMode = UIViewContentModeScaleAspectFit;
//    } else {
//        self.pictureView.contentMode = UIViewContentModeScaleToFill;
//    }
    self.favorImage.hidden = YES;
    self.pictureView.contentMode = UIViewContentModeScaleToFill;

    self.pictureView.image = image;
    
}

- (void) setSelected:(BOOL)selected
{
    _selected = selected;
    if (_selected) {
        self.backgroundImage.image = [UIImage imageNamed:@"cellb.png"];
    } else {
        self.backgroundImage.image = [UIImage imageNamed:@"cella.png"];
    }
}

-(void) onTap: (UIGestureRecognizer *) recognizer
{
    NSLog(@"%s", __func__);
    [self.delegate onTap: self];
}

- (void) tagFavor{
    self.favorImage.hidden = NO;
}
- (void) untagFavor{
    self.favorImage.hidden = YES;
}
@end
