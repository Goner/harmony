//
//  MoreActionsController.m
//  Merry992
//
//  Created by hongyu on 13-1-25.
//  Copyright (c) 2013年 why. All rights reserved.
//

#import "MoreActionsController.h"
#import "MoreActionCell.h"

@interface MoreActionsController ()

@end

@implementation MoreActionsController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.actions = [NSArray arrayWithObjects: @"好友共享", @"备份 恢复", @"好友管理", @"系统消息", @"上传下载任务", @"帮助与反馈", @"关于久久相悦管家", nil];
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
    [self.navigationController.view setFrame: [self.rootController rectWithoutBottomBar]];
    [self.view setFrame: [self.rootController rectWithoutBottomBar]];

    
    //        [[UIApplication sharedApplication]setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.actions.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MoreActionCell *cell = [tableView dequeueReusableCellWithIdentifier: @"MoreActionCell"];
    if (cell == nil ) {
        cell = [MoreActionCell cellFromNib];
    }
    
    cell.title.text = [self.actions objectAtIndex: indexPath.row];
    return cell;
    
}


- (IBAction)onLogoutPressed:(id)sender {
    [self.rootController logout];
}

@end
