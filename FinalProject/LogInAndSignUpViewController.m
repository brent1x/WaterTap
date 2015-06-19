//
//  LogInAndSignUpViewController.m
//  FinalProject
//
//  Created by Brent Dady on 6/18/15.
//  Copyright (c) 2015 Brent Dady. All rights reserved.
//

#import "LogInAndSignUpViewController.h"

#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "RootViewController.h"
#import "User.h"

#import <ParseFacebookUtilsV4/PFFacebookUtils.h>

@interface LogInAndSignUpViewController ()
@property (weak, nonatomic) IBOutlet UITextField *fullNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *logInButton;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (weak, nonatomic) IBOutlet UIButton *logInWithFBButton;
@end

@implementation LogInAndSignUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.fullNameTextField.hidden = YES;

    // - (CGRect)borderRectForBounds:(CGRect)bounds
//    self.passwordTextField.frame = self.emailTextField.frame;
//    self.emailTextField.frame = self.fullNameTextField.frame;
    //  self.emailTextField.frame.origin = CGPo self.fullNameTextField.frame.origin;



}

- (IBAction)onLogInButtonTapped:(id)sender {

    [PFUser logInWithUsernameInBackground:self.emailTextField.text password:self.passwordTextField.text block:^(PFUser *user, NSError *error) {
        if (user) {
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            NSString *errorString = [error userInfo][@"Log In Error"];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid username or password or info not registered with an existing account" message:errorString delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            self.emailTextField.text = nil;
            self.passwordTextField.text = nil;
        }
    }];


}

- (IBAction)onSignUpButtonTapped:(id)sender {

    // - (CGRect)borderRectForBounds:(CGRect)bounds

//    self.emailTextField.frame = self.passwordTextField.frame;

//    self.passwordTextField.frame = CGRectMake(152, 303, 97, 30);


//    self.signUpButton.frame = self.logInButton.frame;

    if (!self.fullNameTextField.hidden) {
        User *newUser = [User new];
        newUser.username = self.emailTextField.text;
        newUser.password = self.passwordTextField.text;
        newUser.email = self.emailTextField.text;
        newUser.fullName = self.fullNameTextField.text;

        [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
            if(!error){
                [self dismissViewControllerAnimated:YES completion:nil];
            } else {
                NSString *errorString = [error userInfo][@"error"];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"There was an error!" message:errorString delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
                self.fullNameTextField.text = nil;
                self.passwordTextField.text = nil;
                self.emailTextField.text = nil;
            }
            
        }];
    }

    [UIView animateWithDuration:0.5 animations:^{
        self.fullNameTextField.hidden = NO;
        self.logInButton.hidden = YES;
    }];

}


- (IBAction)onLogInWithFBButtonTapped:(id)sender {

    //substitute nil with facebook permissions array of strings

    [PFFacebookUtils logInInBackgroundWithReadPermissions:nil block:^(PFUser *user, NSError *error) {
        if (!user) {
            NSLog(@"Uh oh. The user cancelled the Facebook login.");
        } else if (user.isNew) {
            NSLog(@"User signed up and logged in through Facebook!");
        } else {
             [self dismissViewControllerAnimated:YES completion:nil];
            NSLog(@"User logged in through Facebook!");
        }
    }];
}


@end
