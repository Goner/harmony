//
//  FriendsListViewController.m
//  Harmony
//
//  Created by wang zhenbin on 2/28/13.
//  Copyright (c) 2013 久久相悦. All rights reserved.
//

#import "FriendsListController.h"
#import "FriendCell.h"
#import "NASMediaLibrary.h"

@interface FriendsListController ()
@property (retain) NSArray *friends;
@end

@implementation FriendsListController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    //_friends = [NASMediaLibrary getFriendList];
    _friends = [NSMutableArray arrayWithArray:[NASMediaLibrary getFriendsSharedWithFolder:_curFolderPath]];
    
}

- (void)viewDidDisappear:(BOOL)animated{
    NSMutableArray *sharedFriends = [[NSMutableArray alloc] init];
    NSMutableArray *unSharedFriends = [[NSMutableArray alloc] init];
    for (Friend * friend in self.friends) {
        if(friend.isShared) {
            [sharedFriends addObject:friend];
        } else {
            [unSharedFriends addObject:friend];
        }
    }
    if([sharedFriends count] == 0){
        [self.sharedFolders removeObject:self.curFolderPath];
    }
    if ([sharedFriends count] != 0) {
        [NASMediaLibrary shareFolder:_curFolderPath withFriends:sharedFriends];
    }
    
    if([unSharedFriends count] != 0){
        [NASMediaLibrary unshareFolder:_curFolderPath withFriends:unSharedFriends];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_friends count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FriendCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *array = [[NSBundle mainBundle] loadNibNamed: @"FriendCell" owner:nil options:nil];
        if (array.count > 0) {
            cell = [array objectAtIndex: 0];
        }
    }
    
    FriendCell *friendCell = (FriendCell *)cell;
    Friend *friend= [_friends objectAtIndex:indexPath.row];
    friendCell.friendNameLable.text = friend.name;
    friendCell.checkStateImageView.hidden = !friend.isShared;
    
    UIView *bgView = [[UIView alloc] init];
    [bgView setBackgroundColor:[UIColor colorWithRed:0.69 green:0.69 blue:0.588 alpha:1]];
    [cell setSelectedBackgroundView:bgView];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FriendCell *cell = (FriendCell *)[tableView cellForRowAtIndexPath:indexPath];
    Friend *friend = [_friends objectAtIndex:indexPath.row];
    friend.isShared = cell.checkStateImageView.hidden;
    cell.checkStateImageView.hidden = !cell.checkStateImageView.hidden;
}	
@end
