//
//  SharingCell.h
//  Harmony
//
//  Created by hongyu on 13-2-24.
//  Copyright (c) 2013年 久久相悦. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SharingCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *pictureView;

@property (weak, nonatomic) IBOutlet UILabel *title;


@property (weak, nonatomic) IBOutlet UIButton *cancelSharing;

@property (weak, nonatomic) IBOutlet UIImageView *background;

@end
