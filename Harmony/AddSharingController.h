//
//  AddSharingController.h
//  Harmony
//
//  Created by hongyu on 13-2-27.
//  Copyright (c) 2013年 久久相悦. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddSharingCell.h"

@interface AddSharingController : UIViewController<UITableViewDataSource, UITableViewDelegate, AddSharingCellDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (retain) NSString *folderPath;
@property (weak, nonatomic) NSMutableArray *shareFolders;
@end
