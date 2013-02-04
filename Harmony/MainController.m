//
//  MainController.m
//  Merry992
//
//  Created by hongyu on 13-1-20.
//  Copyright (c) 2013年 why. All rights reserved.
//

#import "MainController.h"
#import "GridViewController.h"
#import "MoreActionsController.h"
#import "PopoverController.h"
#import "CategoryController.h"
#import "NASMediaLibrary.h"
#import "SimpleKeychain.h"

#define CONTENT_MARGIN 4

@interface MainController ()
@property (nonatomic, strong) GridViewController *gridController;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) MoreActionsController *actionMoreController;

@end

@implementation MainController

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
    CGRect rect = self.view.bounds;
    
    //set contentView frame
    CGRect contentRect = rect;
    contentRect.origin.y += self.topBar.bounds.size.height - CONTENT_MARGIN;
    contentRect.size.height -= contentRect.origin.y;
    [self.contentView setFrame: contentRect];
    
    //init gridController and navigationController
    CGRect subViewRect = [self rectWithBottomBar];
    self.gridController = [[GridViewController alloc] initWithNibName:@"GridViewController" bundle:nil];
    [self.gridController setRootController: self];
    [self.gridController.view setFrame: subViewRect];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.gridController];
    [self.navigationController setNavigationBarHidden:YES];
    [self.navigationController.view setFrame: subViewRect];

    //add view controllers into self
    [self addChildViewController: self.navigationController];
    [self.contentView addSubview: self.navigationController.view];
    [self.navigationController didMoveToParentViewController: self];

//    self.categoryImages = [NSArray arrayWithObjects: @"recent", @"favor", @"people", @"date", @"video", nil];
    self.mediaCategories = [NASMediaLibrary getMediaCategories];
    
    [self setCategoryIndex: 0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewDidUnload {
    [self setContentView:nil];
    [self setButtonBack:nil];
    [self setBottomBar:nil];
    [self setTopBar:nil];
    [self setCateButton:nil];
    [super viewDidUnload];
}

- (void) setCategoryIndex:(int)index
{
    if(index >= [self.mediaCategories count]){
        return;
    }
    
    if([self.navigationController.viewControllers count] > 1) {
        [self.navigationController popViewControllerAnimated: YES];
        _categoryIndex = -1;
    }
    
    if (_categoryIndex != index) {
        _categoryIndex = index;
        NSString *title = [[self.mediaCategories objectAtIndex: index] title];
        NSString *str1 =  [title stringByAppendingString: @"b.png"];
        NSString *str2 = [title stringByAppendingString: @"a.png"];
        UIImage *img1 = [UIImage imageNamed: str1];
        UIImage *img2 = [UIImage imageNamed: str2];

        [self.cateButton setImage: img1 forState:UIControlStateNormal];
        [self.cateButton setImage: img2 forState:UIControlStateHighlighted];

        [self.gridController backToTopCatogery:[self.mediaCategories objectAtIndex:index]];
    }
    
}

- (CGRect) rectWithBottomBar
{
    CGRect ret = self.view.bounds;
    ret.size.height -= self.topBar.bounds.size.height + self.bottomBar.bounds.size.height - CONTENT_MARGIN;
    return ret;
}

- (CGRect) rectWithoutBottomBar
{
    CGRect ret = self.view.bounds;
    ret.size.height -= self.topBar.bounds.size.height - CONTENT_MARGIN;
    return ret;
}

- (void) hideButtonBack: (BOOL) hiden
{
    [self.buttonBack setHidden: hiden];
    
}

- (void) hideBottomBar: (BOOL) hiden
{
    if (hiden != self.bottomBar.isHidden) {
        [self.bottomBar setHidden: hiden];

    }

}

- (IBAction)onButtonActionMorePressed:(id)sender {
    if (self.actionMoreController == nil) {
        self.actionMoreController = [[MoreActionsController alloc] initWithNibName:@"MoreActionsController" bundle:nil];
        self.actionMoreController.rootController = self;
    }
    
    [self.navigationController pushViewController: self.actionMoreController animated:YES];
    [self hideBottomBar: YES];
}

- (IBAction)onButtonCategoryPressed:(id)sender {

    if (self.categoryController == nil) {
        self.categoryController = [[CategoryController alloc] initWithNibName: @"CategoryController" bundle:nil];
        self.categoryController.rootController = self;
        
        //add view controllers into self
        [self.categoryController.view setFrame: self.view.bounds];
        [self addChildViewController: self.categoryController];
        [self.view addSubview: self.categoryController.view];
        [self.categoryController didMoveToParentViewController: self];
        
    }
    [self.categoryController.view setHidden: NO];
  
}

- (IBAction)onBackButtonPressed:(id)sender {
    if([self.navigationController.viewControllers count] > 1) {
        [self.navigationController popViewControllerAnimated: YES];
    } else {
        [self.gridController backToParentCatogery];
    }
}

- (IBAction)onButtonDownloadPressed:(id)sender{
    [self.gridController downloadSelectedItems];
}

- (IBAction)onButtonTagFavorPressed:(id)sender{
    [self.gridController tagFavorSelectedItems];
}

- (IBAction)onButtonAlbumSharePressed:(id)sender{
    [self.gridController shareAlbumSelectedItems];
}

- (void) logout
{
    [SimpleKeychain delete:@"merry99"];
    [self dismissViewControllerAnimated: YES completion:nil];
}

@end
