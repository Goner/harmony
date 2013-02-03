//
//  LoginViewController.h
//  Harmony
//
//  Created by wang zhenbin on 2/2/13.
//  Copyright (c) 2013 久久相悦. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField* userName;
@property (weak, nonatomic) IBOutlet UITextField* password;

- (IBAction)onLoginButtonPressed:(id)sender;
- (IBAction)onCancelButtonPressed:(id)sender;
@end
