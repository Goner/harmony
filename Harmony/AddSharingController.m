//
//  AddSharingController.m
//  Harmony
//
//  Created by hongyu on 13-2-27.
//  Copyright (c) 2013年 久久相悦. All rights reserved.
//

#import "AddSharingController.h"

@interface AddSharingController ()

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // TODO: modify here
    return  4;
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
    aCell.title.text = @"Title of the folder";
    aCell.pictureView.image = [UIImage imageNamed: @"2.jpg"];
    [aCell setIsShared: NO];
    aCell.row = indexPath.row;
    aCell.cellDelegate = self;
    
    return  cell;
}

- (IBAction)onAddSharing:(id)sender
{
    AddSharingController *addSharingController = [[AddSharingController alloc] initWithNibName: @"AddSharingController" bundle:nil];
    
    [self.navigationController pushViewController:addSharingController animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //TODO: 选中，进入下一层
    AddSharingController *addSharingController = [[AddSharingController alloc] initWithNibName: @"AddSharingController" bundle:nil];
    
    [self.navigationController pushViewController:addSharingController animated:YES];
    
}

- (void) toggleSharing: (int)row;
{
    //TODO: 切换选中/去选中

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow: row inSection:0];
    AddSharingCell *aCell = (AddSharingCell *)[self.tableView cellForRowAtIndexPath: indexPath];
    [aCell setIsShared: !aCell.isShared];
    
}

@end
