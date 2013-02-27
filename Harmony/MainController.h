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

@property (nonatomic, strong) CategoryController *categoryController;
@property (nonatomic, assign) int categoryIndex;
//@property (nonatomic, strong) NSArray *categoryImages;
@property (nonatomic, strong) NSArray *mediaCategories;

@property (weak, nonatomic) IBOutlet UIView *contentView;
- (IBAction)onBackButtonPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *buttonBack;
@property (weak, nonatomic) IBOutlet UIView *bottomBar;
@property (weak, nonatomic) IBOutlet UIView *topBar;
@property (weak, nonatomic) IBOutlet UIButton *cateButton;

- (void) hideButtonBack: (BOOL) hiden;
- (void) hideBottomBar: (BOOL) hiden;

- (IBAction)onButtonActionMorePressed:(id)sender;
- (IBAction)onButtonCategoryPressed:(id)sender;
- (IBAction)onButtonDownloadPressed:(id)sender;
- (IBAction)onButtonTagFavorPressed:(id)sender;
- (IBAction)onButtonAlbumSharePressed:(id)sender;
- (IBAction)onButtonPhotoPrintPressed:(id)sender;

- (CGRect) rectWithBottomBar;
- (CGRect) rectWithoutBottomBar;

- (void) logout;

@end
