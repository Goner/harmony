//
//  CategoryController.m
//  Merry992
//
//  Created by hongyu on 13-1-26.
//  Copyright (c) 2013年 why. All rights reserved.
//

#import "CategoryController.h"
#import "MainController.h"

@interface CategoryController ()

@end

@implementation CategoryController

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
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    CGPoint touchPosition = [touch locationInView:self.view];
    
    CGPoint pnt = [self.view convertPoint:touchPosition toView:self.menuView];
    
    if ([self.menuView pointInside:pnt withEvent:event]) {
    } else {
        [self.view setHidden: YES];
    }
}

- (void)viewDidUnload {
    [self setMenuView:nil];
    [super viewDidUnload];
}

- (IBAction)onButton1Pressed:(id)sender {
    [self.rootController setCategoryIndex: 0];
    [self.view setHidden: YES];
    
}

- (IBAction)onButton2Pressed:(id)sender {
    [self.rootController setCategoryIndex: 1];
    [self.view setHidden: YES];
    
}

- (IBAction)onButton3Pressed:(id)sender {
    [self.rootController setCategoryIndex: 2];
    [self.view setHidden: YES];
    
}

- (IBAction)onButton4Pressed:(id)sender {
    [self.rootController setCategoryIndex: 3];
    [self.view setHidden: YES];
    
}

- (IBAction)onButton5Pressed:(id)sender {
    [self.rootController setCategoryIndex: 4];
    [self.view setHidden: YES];
    
}

@end
