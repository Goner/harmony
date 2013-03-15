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
static MainController *currentMainController;

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
    [self.bkgImage setFrame: contentRect];

    //add view controllers into self
    [self addChildViewController: self.navigationController];
    [self.contentView addSubview: self.navigationController.view];
    [self.navigationController didMoveToParentViewController: self];

    self.mediaCategories = [NASMediaLibrary getMediaCategories];
    
    _categoryIndex = -1;
    self.editingMode = NO;
    [self setCategoryIndex: 0];
    
    currentMainController = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewDidUnload {
    currentMainController = nil;
    [self setContentView:nil];
    [self setButtonBack:nil];
    [self setBottomBar:nil];
    [self setTopBar:nil];
    [self setCateButton:nil];
    [self setBkgImage:nil];
    [super viewDidUnload];
}

- (void) setCategoryIndex:(int)index
{
    if(index >= [self.mediaCategories count]){
        return;
    }
    
    if([self.navigationController.viewControllers count] > 1) {
        [self.navigationController popToRootViewControllerAnimated: YES];
        _categoryIndex = -1;
    }
    
    if (self.imageBrowserEditingMode) {
        [self enableImageBrowserEditing:NO];
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

        [self.gridController gotoTopCatogery:[self.mediaCategories objectAtIndex:index]];
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

- (CGRect) rectOfBottomBar
{
    CGRect ret = self.contentView.bounds;
    ret.origin.y = ret.size.height - self.bottomBar.bounds.size.height;
    ret.size.height = self.bottomBar.bounds.size.height;

    return ret;
}

- (void) hideButtonBack: (BOOL) hidden
{
    [self.buttonBack setHidden: hidden];
    
}

- (void) hideBottomBar: (BOOL) hidden
{
    if (hidden != self.bottomBar.isHidden) {
        [self.bottomBar setHidden: hidden];
    }
}

- (void) hideCategoryDroplist: (BOOL) hidden {
    [self.cateButton.superview setHidden:hidden];
}

- (void) enableButtonEditing: (BOOL)enable{
    [self.buttonEditing setEnabled:enable];
}

+ (void) setTopBarTitle:(NSString *)title {
    if(currentMainController){
        currentMainController.titleLable.text = title;
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

- (void)enableBottomBarEditingState:(BOOL)state{
    _buttonEditing.hidden = state;
    _buttonMoreAction.hidden = state;
    
    _buttonShareAlbum.hidden = !state;
    _buttonPhotoPrint.hidden = !state;
    _buttonDownload.hidden = !state;
    _buttonTagFavor.hidden = !state;
}

- (void) enableImageBrowserEditing: (BOOL)enable{
    [self enableBottomBarEditingState:enable];
    [self hideButtonBack:NO];
    self.imageBrowserEditingMode = YES;
}

- (IBAction)onBackButtonPressed:(id)sender {
    if (self.editingMode) {
        self.editingMode = NO;
        [self.gridController clearSelections];
        [self enableBottomBarEditingState:NO];
        [self hideCategoryDroplist:NO];
        [self hideButtonBack:self.gridController.currentCategory.parentCategory == nil];
        return;
    }
    if(self.imageBrowserEditingMode) {
        self.imageBrowserEditingMode = NO;
        [self enableBottomBarEditingState:NO];
        [self hideButtonBack:self.gridController.currentCategory.parentCategory == nil];
    }
    if([self.navigationController.viewControllers count] > 1) {
        [self.navigationController popViewControllerAnimated: YES];
    } else {
        [self.gridController backToParentCatogery];
    }
}

- (void)autoFadeAlter{
    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"操作完成" delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    [alert show];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
        [alert dismissWithClickedButtonIndex:0 animated:YES];
    });

}

- (void)willPresentAlertView:(UIAlertView *)alertView {
	[alertView setFrame:CGRectMake(10, 200, 280, 80)];
    alertView.alpha = 0.5;
}

- (IBAction)onButtonDownloadPressed:(id)sender{
    [self.gridController downloadSelectedItems];
    [self autoFadeAlter];
}

- (IBAction)onButtonTagFavorPressed:(id)sender{
    [self.gridController tagFavorSelectedItems];
    [self autoFadeAlter];
}

- (IBAction)onButtonAlbumSharePressed:(id)sender{
    [self.gridController shareAlbumSelectedItems];
    [self autoFadeAlter];
}

- (IBAction)onButtonPhotoPrintPressed:(id)sender{
    [self.gridController commitPrintSelectedItems];
    [self autoFadeAlter];
}

- (IBAction)onButtonEditingPressed:(id)sender{
    [self enableBottomBarEditingState:YES];
    self.editingMode = YES;
    [self hideCategoryDroplist:YES];
    [self hideButtonBack:NO];
}

- (void) logout
{
    [SimpleKeychain delete:@"merry99"];
    [self dismissViewControllerAnimated: YES completion:nil];
}

@end
