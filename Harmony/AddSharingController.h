//
//  AddSharingController.h
//  Harmony
//
//  Created by hongyu on 13-2-27.
//  Copyright (c) 2013年 久久相悦. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddSharingController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
