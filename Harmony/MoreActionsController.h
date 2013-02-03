//
//  MoreActionsController.h
//  Merry992
//
//  Created by hongyu on 13-1-25.
//  Copyright (c) 2013年 why. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainController.h"

@interface MoreActionsController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) MainController *rootController;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray *actions;

- (IBAction)onLogoutPressed:(id)sender;
@end
