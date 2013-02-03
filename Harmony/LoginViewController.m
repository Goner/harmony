//
//  LoginViewController.m
//  Harmony
//
//  Created by wang zhenbin on 2/2/13.
//  Copyright (c) 2013 久久相悦. All rights reserved.
//

#import "LoginViewController.h"
#import "NASMediaLibrary.h"

@implementation LoginViewController
@synthesize userName;
@synthesize password;

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
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onCancelButtonPressed:(id)sender{
    userName.text = @"";
    password.text = @"";
}

-(IBAction)onLoginButtonPressed:(id)sender{
    BOOL bRet = [NASMediaLibrary initWithUser:userName.text password:password.text];
    if (!bRet) {
        NSLog(@"Initialize failed.");
        return;
    }
    [self performSegueWithIdentifier:@"login" sender:self];
}

@end
