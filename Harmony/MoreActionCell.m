//
//  MoreActionCell.m
//  Merry992
//
//  Created by hongyu on 13-1-26.
//  Copyright (c) 2013年 why. All rights reserved.
//

#import "MoreActionCell.h"

@implementation MoreActionCell

+ (MoreActionCell *) cellFromNib
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed: @"MoreActionCell" owner:nil options:nil];
    MoreActionCell *ret = [array objectAtIndex: 0];
    
    return ret;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
