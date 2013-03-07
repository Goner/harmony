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
@property (retain) NSMutableArray *sharedFriends;
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
    
    _friends = [NASMediaLibrary getFriendList];
    _sharedFriends = [NSMutableArray arrayWithArray:[NASMediaLibrary getFriendsSharedWithFolder:_curFolderPath]];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload
{
    if([_sharedFolders count] == 0){
       [_sharedFolders removeObject:_curFolderPath];
    }
    [NASMediaLibrary shareFolder:_curFolderPath withFriends:_sharedFriends];
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
    friendCell.checkStateImageView.hidden = ![_sharedFriends containsObject:friend];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FriendCell *cell = (FriendCell *)[tableView cellForRowAtIndexPath:indexPath];
    if(cell.checkStateImageView.hidden){
        [_sharedFriends addObject:[_friends objectAtIndex:indexPath.row]];
    } else {
        [_sharedFriends removeObject:[_friends objectAtIndex:indexPath.row]];
    }
    cell.checkStateImageView.hidden = !cell.checkStateImageView.hidden;
}	

@end
