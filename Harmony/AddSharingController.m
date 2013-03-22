//
//  AddSharingController.m
//  Harmony
//
//  Created by hongyu on 13-2-27.
//  Copyright (c) 2013年 久久相悦. All rights reserved.
//

#import "AddSharingController.h"
#import "MainController.h"
#import "NASMediaLibrary.h"

@interface AddSharingController ()
@property NSArray *subFolders;
@end

@implementation AddSharingController

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
	// Do any additional setup after loading the view.
    _subFolders = [NASMediaLibrary getSubFolders:_folderPath];
}

- (void)viewWillAppear:(BOOL)animated{
    [MainController setTopBarTitle:@"添加共享"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return  [_subFolders count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"AddSharingCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: identifier];
    if (cell == nil) {
        NSArray *array = [[NSBundle mainBundle] loadNibNamed: @"AddSharingCell" owner:nil options:nil];
        if (array.count > 0) {
            cell = [array objectAtIndex: 0];
        }
    }
    
    AddSharingCell *aCell = (AddSharingCell *)cell;
    
    // TODO: modify here
    aCell.title.text = [_subFolders objectAtIndex:indexPath.row];
    [aCell setIsShared: [_shareFolders containsObject:[_folderPath stringByAppendingPathComponent:aCell.title.text]]];
    aCell.row = indexPath.row;
    aCell.cellDelegate = self;
    
    UIView *bgView = [[UIView alloc] init];
    [bgView setBackgroundColor:[UIColor colorWithRed:0.69 green:0.69 blue:0.588 alpha:1]];
    [cell setSelectedBackgroundView:bgView];
    
    return  cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AddSharingController *addSharingController = [[AddSharingController alloc] initWithNibName: @"AddSharingController" bundle:nil];
    addSharingController.folderPath = [_folderPath stringByAppendingPathComponent:[_subFolders objectAtIndex:indexPath.row]];
    addSharingController.shareFolders = self.shareFolders;
    [self.navigationController pushViewController:addSharingController animated:YES];
}

- (void) toggleSharing: (int)row;
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow: row inSection:0];
    AddSharingCell *aCell = (AddSharingCell *)[self.tableView cellForRowAtIndexPath: indexPath];
    if(!aCell.isShared){
        [aCell setIsShared: YES];
        [_shareFolders addObject:[_subFolders objectAtIndex:row]];
    }
    
}

@end
