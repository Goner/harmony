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
#import "NASError.h"

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
        int ret = [NASMediaLibrary initWithUser:user password:pass];
        if(ret != SUCCESS) {
            [SimpleKeychain delete:@"merry99"];
        } else if(update) {
            [SimpleKeychain save:@"merry99" data:[NSDictionary dictionaryWithObjectsAndKeys:
                                                  userName.text, @"userName",
                                                  password.text, @"password", nil]];
            
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            if (ret != SUCCESS) {
                NSString *error = nil;
                switch (ret) {
                    case E_NETWORK_NOT_AVAILABLE:
                        error = @"网络连接不可用，请稍后重试";
                        break;
                    case E_WRONG_USER_OR_PASSWORD:
                        error = @"用户名密码不匹配";
                        break;
                    case E_BOX_NOT_ONLINE:
                        error = @"久久宝盒不在线";
                        break;
                    case E_SERVER_NOT_RESPONSE:
                        error = @"服务器无响应";
                        break;
                    case E_LOW_NETWORK_QUALITY:
                        error = @"当前网络情况无法建立连接";
                        break;
                    default:
                        error = @"网络连接不可用，请稍后重试";
                        break;
                }
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"登录失败" message:error delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
                [alertView show];
                return;
            }
            
            [self performSegueWithIdentifier:@"login" sender:self];
        });
    });
    dispatch_release(queue);
}
@end
