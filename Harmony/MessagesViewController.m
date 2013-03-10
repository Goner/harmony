//
//  MessagesViewController.m
//  Harmony
//
//  Created by wang zhenbin on 2/27/13.
//  Copyright (c) 2013 久久相悦. All rights reserved.
//

#import "MessagesViewController.h"
#import "NASMediaLibrary.h"
#import "MainController.h"

@interface MessagesViewController ()

@end

@implementation MessagesViewController
@synthesize messages;

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
    messages = [NASMediaLibrary getNASMessages];
}

- (void)viewWillAppear:(BOOL)animated{
    [MainController setTopBarTitle:@"系统消息"];
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

    return messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.lineBreakMode = UILineBreakModeCharacterWrap;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0];
    [cell.textLabel setText:[messages objectAtIndex:indexPath.row]];
    
    return cell;
}
@end
