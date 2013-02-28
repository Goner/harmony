//
//  MoreActionsController.m
//  Merry992
//
//  Created by hongyu on 13-1-25.
//  Copyright (c) 2013年 why. All rights reserved.
//

#import "MoreActionsController.h"
#import "MoreActionCell.h"
#import "SharingController.h"
#import "MessagesViewController.h"
#import "AboutViewController.h"
#import "DataSyncViewController.h"

@interface MoreActionsController ()

@end

@implementation MoreActionsController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSArray *array1 = [NSArray arrayWithObjects: @"好友共享", @"备份, 恢复", nil];
        NSArray *array2 = [NSArray arrayWithObjects: @"系统消息", nil];
        NSArray *array3 = [NSArray arrayWithObjects: @"关于久久相悦管家", nil];


        self.actions = [NSArray arrayWithObjects: array1, array2, array3, nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void) viewWillAppear:(BOOL)animated
{
    [self.rootController hideButtonBack: NO];
    [self.rootController hideBottomBar: YES];
    [self.rootController hideCategoryDroplist:YES];
    [MainController setTopBarTitle:@"更多"];
    [self.navigationController.view setFrame: [self.rootController rectWithoutBottomBar]];
    [self.view setFrame: [self.rootController rectWithoutBottomBar]];

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


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.actions.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *array = [self.actions objectAtIndex: section];
    return array.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MoreActionCell *cell = [tableView dequeueReusableCellWithIdentifier: @"MoreActionCell"];
    if (cell == nil ) {
        cell = [MoreActionCell cellFromNib];
    }
    
    NSArray *array = [self.actions objectAtIndex: indexPath.section];
    cell.title.text = [array objectAtIndex: indexPath.row];
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MoreActionCell *cell = (MoreActionCell *)[tableView cellForRowAtIndexPath: indexPath];
//    NSLog(@"Cell selected: %@", cell.title.text);
    
    NSString *function = cell.title.text;
    
    if ([function isEqualToString: @"好友共享"]) {
        [self showSharingView];
    } else if ([function isEqualToString: @"备份, 恢复"]) {
        [self showDataSyncView];
    } else if ([function isEqualToString: @"系统消息"]) {
        [self showMessagesView];
    } else if ([function isEqualToString: @"关于久久相悦管家"]) {
        [self showAboutView];
    }

    
}

- (void) showSharingView
{
    SharingController *sharingController = [[SharingController alloc] initWithNibName: @"SharingController" bundle:nil];
    
    [self.navigationController pushViewController:sharingController animated:YES];
}

- (void) showDataSyncView{
    DataSyncViewController *dataSyncViewController = [[DataSyncViewController alloc] initWithNibName:@"DataSyncViewController" bundle:nil];
    [self.navigationController pushViewController:dataSyncViewController animated:YES];
}

- (void) showMessagesView {
    MessagesViewController *messagesViewController = [[MessagesViewController alloc] init];
    [self.navigationController pushViewController:messagesViewController animated:YES];
}

- (void) showAboutView {
    AboutViewController *aboutViewController = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
    [self.navigationController pushViewController:aboutViewController animated:YES];
}

- (IBAction)onLogoutPressed:(id)sender {
    [self.rootController logout];
}

@end



