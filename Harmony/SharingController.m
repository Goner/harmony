//
//  SharingController.m
//  Harmony
//
//  Created by hongyu on 13-2-24.
//  Copyright (c) 2013年 久久相悦. All rights reserved.
//

#import "SharingController.h"
#import "SharingCell.h"
#import "AddSharingController.h"
#import "FriendsListController.h"
#import "MainController.h"
#import "NASMediaLibrary.h"

@interface SharingController ()
@property (retain) NSMutableArray *shareFolders;
@end

@implementation SharingController

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
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    // Do any additional setup after loading the view from its nib.
    _shareFolders = [NSMutableArray arrayWithArray:[NASMediaLibrary getAllShareFolders]];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [MainController setTopBarTitle:@"好友共享"];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setTableView:nil];
    [super viewDidUnload];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return  [_shareFolders count];
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"SharingCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: identifier];
    if (cell == nil) {
        NSArray *array = [[NSBundle mainBundle] loadNibNamed: @"SharingCell" owner:nil options:nil];
        if (array.count > 0) {
            cell = [array objectAtIndex: 0];
        }
    }
    
    SharingCell *sCell = (SharingCell *)cell;
    
    sCell.title.text = [_shareFolders objectAtIndex:indexPath.row];
    return  cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FriendsListController *friendsListController = [[FriendsListController alloc] initWithNibName:@"FriendsListController" bundle:nil];
    
    friendsListController.sharedFolders = _shareFolders;
    friendsListController.curFolderPath = [_shareFolders objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:friendsListController animated:YES];
}

- (IBAction)onAddSharing:(id)sender
{
    AddSharingController *addSharingController = [[AddSharingController alloc] initWithNibName: @"AddSharingController" bundle:nil];
    
    addSharingController.shareFolders = _shareFolders;
    addSharingController.folderPath = @"/merry/storage";
    [self.navigationController pushViewController:addSharingController animated:YES];
}

@end
