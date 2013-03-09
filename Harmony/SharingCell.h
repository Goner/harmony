//
//  SharingCell.h
//  Harmony
//
//  Created by hongyu on 13-2-24.
//  Copyright (c) 2013年 久久相悦. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SharingCellDelegate <NSObject>

- (void)cancelSharedItem:(int)row;

@end

@interface SharingCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *pictureView;

@property (weak, nonatomic) IBOutlet UILabel *title;


@property (weak, nonatomic) IBOutlet UIButton *cancelSharingButton;

@property (weak, nonatomic) IBOutlet UIImageView *background;

@property  (weak, nonatomic) id<SharingCellDelegate> cellDelegate;

@property (assign, nonatomic) int row;
-(IBAction)cacelSharing:(id)sender;

@end
