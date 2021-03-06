//
//  MainController.h
//  Merry992
//
//  Created by hongyu on 13-1-20.
//  Copyright (c) 2013年 why. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CategoryController.h"

@interface MainController : UIViewController

+ (void) setTopBarTitle:(NSString *)title;

@property (nonatomic, strong) CategoryController *categoryController;
@property (nonatomic, assign) int categoryIndex;
@property (nonatomic, strong) NSArray *mediaCategories;
@property (nonatomic) BOOL editingMode;
@property (nonatomic) BOOL imageBrowserEditingMode;

@property (weak, nonatomic) IBOutlet UIView *contentView;
- (IBAction)onBackButtonPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *buttonBack;
@property (weak, nonatomic) IBOutlet UIView *bottomBar;
@property (weak, nonatomic) IBOutlet UIView *topBar;
@property (weak, nonatomic) IBOutlet UIButton *cateButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLable;
@property (weak, nonatomic) IBOutlet UIImageView *bkgImage;
@property (weak, nonatomic) IBOutlet UIImageView *favorImage;

@property (weak, nonatomic) IBOutlet UIButton *buttonEditing;
@property (weak, nonatomic) IBOutlet UIButton *buttonMoreAction;
@property (weak, nonatomic) IBOutlet UIButton *buttonShareAlbum;
@property (weak, nonatomic) IBOutlet UIButton *buttonPhotoPrint;
@property (weak, nonatomic) IBOutlet UIButton *buttonDownload;
@property (weak, nonatomic) IBOutlet UIButton *buttonTagFavor;

- (void) hideButtonBack: (BOOL) hiden;
- (void) hideBottomBar: (BOOL) hiden;
- (void) hideCategoryDroplist: (BOOL) hiden;
- (void) enableButtonEditing: (BOOL)enable;
- (void) enableImageBrowserEditing: (BOOL)enable;

- (IBAction)onButtonActionMorePressed:(id)sender;
- (IBAction)onButtonCategoryPressed:(id)sender;
- (IBAction)onButtonDownloadPressed:(id)sender;
- (IBAction)onButtonTagFavorPressed:(id)sender;
- (IBAction)onButtonAlbumSharePressed:(id)sender;
- (IBAction)onButtonPhotoPrintPressed:(id)sender;
- (IBAction)onButtonEditingPressed:(id)sender;

- (CGRect) rectWithBottomBar;
- (CGRect) rectWithoutBottomBar;
- (CGRect) rectOfBottomBar;

- (void) logout;

@end
