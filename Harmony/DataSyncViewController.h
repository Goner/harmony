//
//  DataSyncViewController.h
//  Harmony
//
//  Created by wang zhenbin on 2/27/13.
//  Copyright (c) 2013 久久相悦. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DataSyncViewController : UIViewController
@property(weak, nonatomic) IBOutlet UIView *view1;
@property(weak, nonatomic) IBOutlet UIView *view2;
@property(weak, nonatomic) IBOutlet UILabel *currentContactsCount;
@property(weak, nonatomic) IBOutlet UILabel *lastBackupedContactsCount;
@property(weak, nonatomic) IBOutlet UILabel *lastBAckupedTime;
-(IBAction)onSyncPhotoSlideChange:(id)sender;
-(IBAction)onSyncPhotoButtonPressed:(id)sender;
-(IBAction)onBackupContactsButtonPressed:(id)sender;
-(IBAction)onRestoreContactsButtonPressed:(id)sender;
@end
