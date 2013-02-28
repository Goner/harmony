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
