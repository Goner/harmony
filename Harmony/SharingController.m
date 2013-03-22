//
//  SharingController.m
//  Harmony
//
//  Created by hongyu on 13-2-24.
//  Copyright (c) 2013年 久久相悦. All rights reserved.
//

#import "SharingController.h"
#import "AddSharingController.h"
#import "FriendsListController.h"
#import "MainController.h"
#import "NASMediaLibrary.h"

@interface SharingController ()
@property (retain) NSMutableArray *shareFolders;
@property (weak, nonatomic)SharingCell *editingCell;
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
    
    UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleCellSwipe:)];
    [gesture setDirection:(UISwipeGestureRecognizerDirectionLeft | UISwipeGestureRecognizerDirectionRight)];
    [self.tableView addGestureRecognizer:gesture];
    _editingCell = nil;
}

- (void)viewWillAppear:(BOOL)animated{
    
    [self.rootController hideButtonBack: NO];
    [self.rootController hideBottomBar: YES];    
    [self.view setFrame: [self.rootController rectWithoutBottomBar]];
    [self.tableView setFrame: [self.rootController rectWithoutBottomBar]];
    
    [self.bottomBar setFrame: [self.rootController rectOfBottomBar]];

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
    [self setBottomBar:nil];
    [super viewDidUnload];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return  [_shareFolders count];
}

- (void)handleCellSwipe:(UISwipeGestureRecognizer *)recognizer{
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        CGPoint swipeLocation = [recognizer locationInView:_tableView];
        NSIndexPath *swipedIndexPath = [_tableView indexPathForRowAtPoint:swipeLocation];
        SharingCell *sCell = (SharingCell *)[_tableView cellForRowAtIndexPath:swipedIndexPath];
        // do what you want here
        sCell.cancelSharingButton.hidden = NO;
        _editingCell = sCell;
    }
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
    sCell.row = indexPath.row;
    
    sCell.title.text = [_shareFolders objectAtIndex:indexPath.row];
    sCell.cellDelegate = self;
    
    UIView *bgView = [[UIView alloc] init];
    [bgView setBackgroundColor:[UIColor colorWithRed:0.69 green:0.69 blue:0.588 alpha:1]];
    [cell setSelectedBackgroundView:bgView];
    
    return  cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(_editingCell){
        _editingCell.cancelSharingButton.hidden = YES;
        _editingCell = nil;
        return;
    }
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

- (void)cancelSharedItem:(int)row{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    [NASMediaLibrary unshareFolder:[_shareFolders objectAtIndex:row] withFriends:nil];
    [_shareFolders removeObjectAtIndex:row];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
}
@end
