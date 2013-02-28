//
//  AboutViewController.m
//  Harmony
//
//  Created by wang zhenbin on 2/27/13.
//  Copyright (c) 2013 久久相悦. All rights reserved.
//

#import "AboutViewController.h"
#import "MainController.h"

@interface AboutViewController ()

@end

@implementation AboutViewController

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

- (void)viewWillAppear:(BOOL)animated{

    [MainController setTopBarTitle:@"关于久久管家"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onCallService:(id)sender{
    //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tel://99999"]];
    UIWebView*callWebview =[[UIWebView alloc] init];
    NSURL *telURL =[NSURL URLWithString:@"tel://4009901099"];
    [callWebview loadRequest:[NSURLRequest requestWithURL:telURL]];
    [self.view addSubview:callWebview];
}

@end
