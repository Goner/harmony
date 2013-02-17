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

@interface LoginViewController()
-(UIActivityIndicatorView *)createActivityIndicator;
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
	// Do any additional setup after loading the view.


}
- (void) viewDidAppear:(BOOL)animated {
    NSDictionary *data = [SimpleKeychain load:@"merry99"];
    if(data == nil) {
        return;
    }
    NSString *user = [data objectForKey:@"userName"];
    NSString *passwd = [data objectForKey:@"password"];
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
    UIActivityIndicatorView *indicatorView = [self createActivityIndicator];
    [self.view addSubview:indicatorView];
    [self.view setUserInteractionEnabled:FALSE];
    [indicatorView startAnimating];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        BOOL bRet = [NASMediaLibrary initWithUser:userName.text password:password.text];
        if(update) {
            [SimpleKeychain save:@"merry99" data:[NSDictionary dictionaryWithObjectsAndKeys:
                                                  userName.text, @"userName",
                                                  password.text, @"password", nil]];
            
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [indicatorView stopAnimating];
            [indicatorView removeFromSuperview];
            [self.view setUserInteractionEnabled:TRUE];
            if (!bRet) {
                NSLog(@"Initialize failed.");
            }
            
            [self performSegueWithIdentifier:@"login" sender:self];
        });
    });
    dispatch_release(queue);
}

-(UIActivityIndicatorView *)createActivityIndicator{
    CGRect screenBounds = [UIScreen mainScreen].bounds;
     UIActivityIndicatorView *indicatorView  = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [indicatorView setCenter:CGPointMake(screenBounds.size.width/2 - 15, screenBounds.size.height/2 - 15)];
    [indicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    return indicatorView;
}
@end
