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
#import "MBProgressHUD.h"
#import "NetWorkStateMonitor.h"

@interface LoginViewController()
-(void)loginWithUser:(NSString *)user withPassword:(NSString *)pass updateLoginRecord:(BOOL)update;
@end

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
	// Do any additional setup after loading the view

}
- (void) viewDidAppear:(BOOL)animated {
    if(![NetWorkStateMonitor startLocalNetworkMonitor]) {
        return;
    }
    NSDictionary *data = [SimpleKeychain load:@"merry99"];
    if(data == nil) {
        return;
    }
    NSString *user = [data objectForKey:@"userName"];
    NSString *passwd = [data objectForKey:@"password"];
    self.userName.text = user;
    self.password.text = passwd;
    [self loginWithUser:user withPassword:passwd updateLoginRecord:FALSE];
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
    [self loginWithUser:userName.text withPassword:password.text updateLoginRecord:TRUE];
}

-(void)loginWithUser:(NSString *)user withPassword:(NSString *)pass updateLoginRecord:(BOOL)update {
    [self.view endEditing:YES];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"请稍候";
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        BOOL bRet = [NASMediaLibrary initWithUser:user password:pass];
        if(!bRet) {
            [SimpleKeychain delete:@"merry99"];
        } else if(update) {
            [SimpleKeychain save:@"merry99" data:[NSDictionary dictionaryWithObjectsAndKeys:
                                                  userName.text, @"userName",
                                                  password.text, @"password", nil]];
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if (!bRet) {
                return;
            }
            
            [self performSegueWithIdentifier:@"login" sender:self];
        });
    });
    dispatch_release(queue);
}
@end
