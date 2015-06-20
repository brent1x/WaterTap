//
//  SettingsViewController.m
//  FinalProject
//
//  Created by Brent Dady on 6/18/15.
//  Copyright (c) 2015 Brent Dady. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@property NSArray *notificationCheck;

@property (weak, nonatomic) IBOutlet UIButton *notificationButton;
@property (weak, nonatomic) IBOutlet UISwitch *notifSwitch;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = NO;
    [self switchLogic];
}

- (void)viewWillAppear:(BOOL)animated {
    [self switchLogic];
}

- (IBAction)onSwitchTapped:(id)sender {
    if (self.notifSwitch.on == NO) {
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        self.notificationButton.enabled = NO;
    } else {
        [self performSegueWithIdentifier:@"reminderSegue" sender:self];
    }
}

- (void)switchLogic {
    if ([[[UIApplication sharedApplication] scheduledLocalNotifications] count] == 0) {
        [self.notifSwitch setOn:NO animated:YES];
        self.notificationButton.enabled = NO;
    } else {
        [self.notifSwitch setOn:YES animated:NO];
        self.notificationButton.enabled = YES;
    }
}

@end
