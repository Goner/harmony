//
//  LoginViewController.m
//  Harmony
//
//  Created by wang zhenbin on 2/2/13.
//  Copyright (c) 2013 久久相悦. All rights reserved.
//

#import "LoginViewController.h"
#import "NASMediaLibrary.h"
#import "SimpleKeychain.h"

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
- (void) viewDidAppear:(BOOL)animated {
    NSDictionary *data = [SimpleKeychain load:@"merry99"];
    if(data == nil) {
        return;
    }
    NSString *user = [data objectForKey:@"userName"];
    NSString *passwd = [data objectForKey:@"password"];
    if(![NASMediaLibrary initWithUser:user password:passwd]) {
        return;
    }
    [self performSegueWithIdentifier:@"login" sender:self];
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
    [SimpleKeychain save:@"merry99" data:[NSDictionary dictionaryWithObjectsAndKeys:
                                          userName.text, @"userName",
                                          password.text, @"password", nil]];
    [self performSegueWithIdentifier:@"login" sender:self];
}

@end
