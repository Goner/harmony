//
//  PopoverController.m
//  Merry992
//
//  Created by hongyu on 13-1-26.
//  Copyright (c) 2013年 why. All rights reserved.
//

#import "PopoverController.h"

@interface PopoverController ()

@end

@implementation PopoverController

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
    NSLog(@"sss %@", self.view);
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
