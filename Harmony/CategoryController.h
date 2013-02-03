//
//  CategoryController.h
//  Merry992
//
//  Created by hongyu on 13-1-26.
//  Copyright (c) 2013年 why. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MainController;

@interface CategoryController : UIViewController

@property (nonatomic, weak) MainController *rootController;

@property (weak, nonatomic) IBOutlet UIView *menuView;

- (IBAction)onButton1Pressed:(id)sender;
- (IBAction)onButton2Pressed:(id)sender;
- (IBAction)onButton3Pressed:(id)sender;
- (IBAction)onButton4Pressed:(id)sender;
- (IBAction)onButton5Pressed:(id)sender;

@end
