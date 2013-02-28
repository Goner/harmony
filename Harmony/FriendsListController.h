//
//  FriendsListViewController.h
//  Harmony
//
//  Created by wang zhenbin on 2/28/13.
//  Copyright (c) 2013 久久相悦. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FriendsListController : UITableViewController
@property (retain)NSString *curFolderPath;
@property (weak, nonatomic) NSMutableArray *sharedFolders;
@end
