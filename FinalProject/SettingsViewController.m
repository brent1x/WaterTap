//
//  SettingsViewController.m
//  FinalProject
//
//  Created by Brent Dady on 6/18/15.
//  Copyright (c) 2015 Brent Dady. All rights reserved.
//

#import "SettingsViewController.h"
#import "RootViewController.h"
#import "HealthKitViewController.h"

#define kNSUserDailyGoalKey @"kNSUserDailyGoalKey"
#define kNSUserUnitTypeSelected @"kNSUserUnitTypeSelected"

@interface SettingsViewController () 

@property NSArray *notificationCheck;
@property (weak, nonatomic) IBOutlet UITextField *dailyGoalTextField;
@property (weak, nonatomic) IBOutlet UIButton *notificationButton;
@property (weak, nonatomic) IBOutlet UISwitch *notifSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedUnitSelector;
@property int dailyGoal;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationController.navigationBarHidden = NO;

    self.navigationItem.title = @"Settings";

    [self switchLogic];

    [self loadGoalFromUserDefaults];

    // if no daily goal has been entered, this will prompt user to set it to something; otherwise it defaults to 0
    if ([self.dailyGoalTextField.text isEqualToString:@""]) {
        self.dailyGoalTextField.placeholder = @"Set your daily goal here.";
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self switchLogic];
    [self loadGoalFromUserDefaults];


    // this section checks whether mL has been set as the default unit type; if so, it lights up the correct segment in the UISegCtrl
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *goalFromDefault = [userDefaults objectForKey:kNSUserUnitTypeSelected];
    NSLog(@"user defaults type: %@", goalFromDefault);
    if ([goalFromDefault isEqualToString:@"milliliter"]) {
        self.segmentedUnitSelector.selectedSegmentIndex = 1;
    }

}

- (IBAction)onDailyGoalDidChange:(UITextField *)sender {
    // this method checks whether or not the daily goal changed. if it did it lets its delegate (RootVC) know
    [self.delegate dailyGoalChanged:[self.dailyGoalTextField.text intValue]];
    [self saveGoalToUserDefaults];
}

- (IBAction)unwindFromSegue:(UIStoryboardSegue *)segue {
    if (self.recoTotal != nil) {
        // this method checks, upon the unwind from the recommendation (aka HealthKit) view controller, if we received a recoomendation
        // if it does have a recommendation, it loads it into the daily goal and calls the delegate method
        self.dailyGoalTextField.text = self.recoTotal;
        [self.delegate dailyGoalChanged:[self.dailyGoalTextField.text intValue]];
        [self saveGoalToUserDefaults];
    }
}

- (IBAction)onUnitTypeSelected:(UISegmentedControl *)sender {
    if (self.segmentedUnitSelector.selectedSegmentIndex == 1) {
        double convertOunceToML = [self.dailyGoalTextField.text doubleValue] * 29.5735;
        int convToInt = (int)(convertOunceToML + (convertOunceToML > 0 ? 0.5 : -0.5));
        self.dailyGoalTextField.text = [NSString stringWithFormat:@"%i", convToInt];
        [self.delegate dailyGoalChanged:[self.dailyGoalTextField.text intValue]];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:@"milliliter" forKey:kNSUserUnitTypeSelected];
        // [self.delegate unitTypeSelected:@"milliliter"];
    } else if (self.segmentedUnitSelector.selectedSegmentIndex == 0) {
        double convertMLToCounce = [self.dailyGoalTextField.text doubleValue] * 0.0338;
        int convToInt = (int)(convertMLToCounce + (convertMLToCounce > 0 ? 0.5 : -0.5));
        self.dailyGoalTextField.text = [NSString stringWithFormat:@"%i", convToInt];
        [self.delegate dailyGoalChanged:[self.dailyGoalTextField.text intValue]];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:@"ounce" forKey:kNSUserUnitTypeSelected];
        // [self.delegate unitTypeSelected:@"ounce"];
    }
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

- (void)saveGoalToUserDefaults {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.dailyGoalTextField.text forKey:kNSUserDailyGoalKey];
}

- (void)loadGoalFromUserDefaults {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *goalFromDefault = [userDefaults objectForKey:kNSUserDailyGoalKey];
    self.dailyGoalTextField.text = goalFromDefault;
}

@end
