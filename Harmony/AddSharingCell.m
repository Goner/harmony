//
//  AddSharingCell.m
//  Harmony
//
//  Created by hongyu on 13-2-27.
//  Copyright (c) 2013年 久久相悦. All rights reserved.
//

#import "AddSharingCell.h"

@implementation AddSharingCell

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

- (void) setIsShared:(BOOL)isShared
{
    _isShared = isShared;
    if (_isShared) {
        [self.shareButton setTitle: @"已共享" forState:UIControlStateNormal];
    } else {
        [self.shareButton setTitle: @"添加共享" forState:UIControlStateNormal];

    }
    
}



- (IBAction)toggleSharing:(id)sender
{
    [self.cellDelegate toggleSharing: self.row];
}

@end
