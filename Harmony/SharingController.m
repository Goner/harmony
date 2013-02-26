//
//  SharingController.m
//  Harmony
//
//  Created by hongyu on 13-2-24.
//  Copyright (c) 2013年 久久相悦. All rights reserved.
//

#import "SharingController.h"
#import "SharingCell.h"

@interface SharingController ()

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
    // TODO: modify here
    return  5;
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
    
    // TODO: modify here
    sCell.title.text = @"Title of the folder";
    sCell.pictureView.image = [UIImage imageNamed: @"1.jpg"];
    
    return  cell;
}


@end
