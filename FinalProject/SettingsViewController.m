//
//  SettingsViewController.m
//  FinalProject
//
//  Created by Brent Dady on 6/18/15.
//  Copyright (c) 2015 Brent Dady. All rights reserved.
//

#import "SettingsViewController.h"
#import "RootViewController.h"

@interface SettingsViewController ()

@property NSArray *notificationCheck;
@property (weak, nonatomic) IBOutlet UITextField *dailyGoalTextField;
@property int dailyGoal;
@property (weak, nonatomic) IBOutlet UIButton *notificationButton;
@property (weak, nonatomic) IBOutlet UISwitch *notifSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedUnitSelector;


@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.title = @"Settings";
    [self switchLogic];
}

- (void)viewWillAppear:(BOOL)animated {
    [self switchLogic];

}


- (IBAction)onDailyGoalDidChange:(UITextField *)sender {
    [self.delegate dailyGoalChanged:[self.dailyGoalTextField.text intValue]];
}

- (IBAction)onUnitTypeSelected:(UISegmentedControl *)sender {
    if (self.segmentedUnitSelector.selectedSegmentIndex == 1) {
        double convertOunceToML = [self.dailyGoalTextField.text doubleValue] * 29.5735;
        int convToInt = (int)(convertOunceToML + (convertOunceToML > 0 ? 0.5 : -0.5));
        self.dailyGoalTextField.text = [NSString stringWithFormat:@"%i", convToInt];
        [self.delegate unitTypeSelected:@"milliliter"];
    } else if (self.segmentedUnitSelector.selectedSegmentIndex == 0) {
        double convertMLToCounce = [self.dailyGoalTextField.text doubleValue] * 0.0338;
        int convToInt = (int)(convertMLToCounce + (convertMLToCounce > 0 ? 0.5 : -0.5));
        self.dailyGoalTextField.text = [NSString stringWithFormat:@"%i", convToInt];
        [self.delegate unitTypeSelected:@"ounce"];
    }

    // TO BUILD LOGIC HERE THAT WILL MAKE METHOD CALLS TO CONSUMPTION EVENT, DAILY GOAL, PEROSONALIZED RECOMMENDATION, AND CUSTOM WATER CONTAINER TO CONVERT UNITS BETWEEN OUNCES AND MILLILETERS
}

- (IBAction)onSwitchTapped:(id)sender {
    if (self.notifSwitch.on == NO) {
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        self.notificationButton.hidden = YES;
    } else {
        [self performSegueWithIdentifier:@"reminderSegue" sender:self];
    }
}

- (void)switchLogic {
    if ([[[UIApplication sharedApplication] scheduledLocalNotifications] count] == 0) {
        [self.notifSwitch setOn:NO animated:YES];
        self.notificationButton.hidden = YES;
    } else {
        [self.notifSwitch setOn:YES animated:NO];
        self.notificationButton.hidden = NO;
    }
}

@end
