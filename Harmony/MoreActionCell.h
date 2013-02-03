//
//  MoreActionCell.h
//  Merry992
//
//  Created by hongyu on 13-1-26.
//  Copyright (c) 2013年 why. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MoreActionCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UILabel *title;

+ (MoreActionCell *) cellFromNib;

@end
