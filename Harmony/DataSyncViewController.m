//
//  DataSyncViewController.m
//  Harmony
//
//  Created by wang zhenbin on 2/27/13.
//  Copyright (c) 2013 久久相悦. All rights reserved.
//

#import "DataSyncViewController.h"
#import "DataSynchronizer.h"
#import "MainController.h"

@interface DataSyncViewController ()

@end

@implementation DataSyncViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [DataSynchronizer getCurrentContactsCountWithBlock:^(int nCount){
        dispatch_async(dispatch_get_main_queue(), ^(){
            _currentContactsCount.text = [NSString stringWithFormat:@"%d条", nCount];
        });
    }];
    
    _lastBackupedContactsCount.text = [NSString stringWithFormat:@"%d条", [DataSynchronizer getLastSyncContactsCount]];
    _lastBAckupedTime.text = [DataSynchronizer getLastSyncContactsTime];
}

- (void)viewWillAppear:(BOOL)animated{
    [MainController setTopBarTitle:@"备份 恢复"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)onSyncPhotoSlideChange:(id)sender{
    UISwitch *switcher = (UISwitch *)sender;
    if(switcher.selected) {
        [DataSynchronizer startAutoBackupPhoto];
    } else {
        [DataSynchronizer stopAutoBackupPhoto];
    }
}

-(IBAction)onSyncPhotoButtonPressed:(id)sender{
    [DataSynchronizer startBackupPhoto];
}

-(IBAction)onBackupContactsButtonPressed:(id)sender{
    [DataSynchronizer startBackupContacts];
}
-(IBAction)onRestoreContactsButtonPressed:(id)sender{
    [DataSynchronizer startRestoreContacts];
}

@end
