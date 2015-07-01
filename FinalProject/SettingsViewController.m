//
//  SettingsViewController.m
//  FinalProject
//
//  Created by Brent Dady on 6/18/15.
//  Copyright (c) 2015 Brent Dady. All rights reserved.
//

#import "RootViewController.h"
#import "SettingsViewController.h"
#import "HealthKitViewController.h"
#import "QuartzCore/QuartzCore.h"
#import "ConsumptionEvent.h"

#define kNSUserDailyGoalKey @"kNSUserDailyGoalKey"
#define kNSUserUnitTypeSelected @"kNSUserUnitTypeSelected"
#define kNSUserReceivedRecommendation @"kNSUserReceivedRecommendation"
#define kNSUserDefaultsContainerOneSize @"kNSUserDefaultsContainerOneSize"
#define kNSUserDefaultsContainerTwoSize @"kNSUserDefaultsContainerTwoSize"

@interface SettingsViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedUnitSelector;
@property (weak, nonatomic) IBOutlet UITextField *dailyGoalTextField;
@property (weak, nonatomic) IBOutlet UISwitch *customContainerSwitch;
@property (weak, nonatomic) IBOutlet UIButton *customContainerButton;
@property (weak, nonatomic) IBOutlet UIButton *notificationButton;
@property (weak, nonatomic) IBOutlet UISwitch *notifSwitch;
@property (weak, nonatomic) IBOutlet UIButton *recoButton;
@property (weak, nonatomic) IBOutlet UISwitch *recoSwitch;
@property NSArray *notificationCheck;
@property bool recoReceived;
@property int dailyGoal;
@property double realGoal;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.title = @"Settings";

    UIColor *myBlueColor = [UIColor colorWithRed:27.0/255.0 green:152.0/255.0 blue:224.0/255.0 alpha:1];
    UIColor *myGrayColor = [UIColor colorWithRed:232.0/255.0 green:241.0/255.0 blue:242.0/255.0 alpha:1];
    self.view.backgroundColor = myGrayColor;

    self.dailyGoalTextField.layer.cornerRadius = 3.0f;
    self.dailyGoalTextField.layer.borderWidth = 1;
    self.dailyGoalTextField.layer.borderColor = myBlueColor.CGColor;

    [self switchLogic];
    [self recommendationSwitchLogic];
    [self loadGoalFromUserDefaults];

    // if no daily goal has been entered, this will prompt user to set it to something; otherwise it defaults to 0
    if ([self.dailyGoalTextField.text isEqualToString:@""]) {
        self.dailyGoalTextField.placeholder = @"Set a goal";
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {

    [self.navigationController setNavigationBarHidden:NO animated:YES];
    // this line checks to see if a user has set up custom reminders
    [self switchLogic];

    // this line will load the daily goal saved from the Recommendation (aka HealthKit) view controller
    [self loadGoalFromUserDefaults];

    // this section checks whether mL has been set as the default unit type; if so, it lights up the correct segment in the UISegCtrl
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *unitTypeSelected = [userDefaults objectForKey:kNSUserUnitTypeSelected];
    if ([unitTypeSelected isEqualToString:@"milliliter"]) {
        self.segmentedUnitSelector.selectedSegmentIndex = 1;
    }

    // this line checks to see if a user has previously received a recommendation
    self.recoReceived = [userDefaults boolForKey:kNSUserReceivedRecommendation];
    if (self.recoReceived == TRUE) {
        self.dailyGoalTextField.enabled = FALSE;
    }

    [self recommendationSwitchLogic];

    // this line check to see if a user has set up custom water containers
    [self customContainerSwitchLogic];
}

#pragma mark // Unwind from Segue

- (IBAction)unwindFromSegue:(UIStoryboardSegue *)segue {
    if (self.recoTotal != nil) {
        // this method checks, upon the unwind from the Recommendation (aka HealthKit) view controller, if we received a recoomendation if it does have a recommendation, it loads it into the daily goal and calls the delegate method

        self.dailyGoalTextField.text = self.recoTotal;
        [self.delegate dailyGoalChanged:[self.dailyGoalTextField.text intValue]];
        [self saveGoalToUserDefaults];
    }
}

#pragma mark // Business Logic

- (IBAction)onDailyGoalDidChange:(UITextField *)sender {
    // this method checks whether or not the daily goal changed. if it did, it lets its delegate (RootVC) know

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *unitTypeSelected = [userDefaults objectForKey:kNSUserUnitTypeSelected];

    int dailyGoal = [self.dailyGoalTextField.text intValue];

    if ([unitTypeSelected isEqualToString:@"milliliter"]) {
        dailyGoal = (int)((double)dailyGoal * 29.5735);
    }

    [self.delegate dailyGoalChanged:dailyGoal];
    NSLog(@"%@", self.delegate);
    [self saveGoalToUserDefaults];

    //Save latest goal to DB with 0 Added water
    ConsumptionEvent *myConsumptionEvent = [ConsumptionEvent new];
    myConsumptionEvent.volumeConsumed = 0;
    myConsumptionEvent.user = [PFUser currentUser];
    myConsumptionEvent.consumptionGoal = [self.dailyGoalTextField.text intValue];
    myConsumptionEvent.consumedAt = [NSDate date];
    [myConsumptionEvent pinInBackground];
}

- (IBAction)onUnitTypeSelected:(UISegmentedControl *)sender {
    // this piece of logic checks whether the user has selected imperial or metric unit types. if they choose metric, I convert from ounces (default) to milliliters and round the result to the nearest whole number, then I update the daily goal text field and call the delegate method that is listening for any changes to the daily goal finally, I save the selected unit type to NSUserDefaults so it persists across the app without having to query Parse

    if (self.segmentedUnitSelector.selectedSegmentIndex == 1) {
//        double goalInML = [self.dailyGoalTextField.text doubleValue] * 29.5735296875;
//        self.realGoal = goalInML;
//        self.dailyGoalTextField.text = [NSString stringWithFormat:@"%d", (int)goalInML];
//        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//        [userDefaults setObject:@"milliliter" forKey:kNSUserUnitTypeSelected];

        double convertOunceToML = [self.dailyGoalTextField.text doubleValue] * 29.5735296875;
        int convToInt = (int)(convertOunceToML + (convertOunceToML > 0 ? 0.5 : -0.5));
        self.dailyGoalTextField.text = [NSString stringWithFormat:@"%i", convToInt];
//        [self.delegate dailyGoalChanged:[self.dailyGoalTextField.text intValue]];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:@"milliliter" forKey:kNSUserUnitTypeSelected];

    } else if (self.segmentedUnitSelector.selectedSegmentIndex == 0) {
        double convertMLToCounce = [self.dailyGoalTextField.text doubleValue] * 0.03381402255892;
        int convToInt = (int)(convertMLToCounce + (convertMLToCounce > 0 ? 0.5 : -0.5));
        self.dailyGoalTextField.text = [NSString stringWithFormat:@"%i", convToInt];
//        [self.delegate dailyGoalChanged:[self.dailyGoalTextField.text intValue]];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:@"ounce" forKey:kNSUserUnitTypeSelected];
    }
}

#pragma mark // Reminder Switch Logic

- (IBAction)onSwitchTapped:(id)sender {
    // this method checks to see if the user flips the reminders switch. if it's *on* and the user flips it to *off*, then all of the reminders are cancelled. conversely, if the switch is *off* and the user flips it to *on", it segues to the reminders VC

    if (self.notifSwitch.on == NO) {
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        self.notificationButton.hidden = YES;
    } else {
        [self performSegueWithIdentifier:@"reminderSegue" sender:self];
    }
}

- (void)switchLogic {
    // this method checks to see if notifications have been set. if so, the switch is set *on* and the *edit* button appears,
    // which will segue the user to the reminders view controller where they can edit the reminders

    if ([[[UIApplication sharedApplication] scheduledLocalNotifications] count] == 0) {
        [self.notifSwitch setOn:NO animated:YES];
        self.notificationButton.hidden = YES;
    } else {
        [self.notifSwitch setOn:YES animated:NO];
        self.notificationButton.hidden = NO;
    }
}

#pragma mark // Recommendation Switch Logic

- (void)recommendationSwitchLogic {
    // this section checks whether a user has received a personalized recommendation. if they have, the UISwitch is set to *on* if they haven't, it remains off. if the switch is *on* and it flips, the recommendation is cleared. if the switch is *off* and it flips, I segue them to the Recommendation (aka HealthKit) view controller

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.recoReceived = [userDefaults boolForKey:kNSUserReceivedRecommendation];

    if (self.recoReceived == TRUE) {
        self.recoSwitch.on = TRUE;
        self.recoButton.hidden = FALSE;
    } else {
        self.recoSwitch.on = FALSE;
        [userDefaults setBool:FALSE forKey:kNSUserReceivedRecommendation];
        self.dailyGoalTextField.enabled = YES;
        self.recoButton.hidden = TRUE;
    }
}

- (IBAction)onRecommendationSwitchTapped:(id)sender {
    // this method checks to see if user flips the reminders switch. if it's *on* and it flips, then all of the reminders are cancelled. conversely, if the switch is *off* and it flips, we segue the user to the Recommendation (aka HealthKit) VC

    if (self.recoSwitch.on == TRUE) {
        [self performSegueWithIdentifier:@"recommendationSegue" sender:self];
    } else { // if (self.recoSwitch.on == FALSE) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setBool:FALSE forKey:kNSUserReceivedRecommendation];
        self.recoReceived = FALSE;
        self.dailyGoalTextField.text = @"";
        self.dailyGoalTextField.placeholder = @"Set a goal";
        [self recommendationSwitchLogic];
    }
}

#pragma mark // Custom Container Switch Logic

- (void)customContainerSwitchLogic {
    // this method checks whether a user has set up custom containers. if they have, the switch is *on*

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *containerOne = [userDefaults objectForKey:kNSUserDefaultsContainerOneSize];
    if ([containerOne intValue] > 0) {
        self.customContainerSwitch.on = TRUE;
        self.customContainerButton.hidden = FALSE;
    } else {
        self.customContainerSwitch.on = FALSE;
        self.customContainerButton.hidden = TRUE;
    }
}

- (IBAction)onCustomContainerSwitchTapped:(id)sender {
    // if the switch is *off* and it gets flipped, I segue them to the Custom Container VC. if the switch is *on* and it flips, I set the custom containers equal to nil

    if (self.customContainerSwitch.on == TRUE) {
        [self performSegueWithIdentifier:@"containerSegue" sender:self];
    } else if (self.customContainerSwitch.on == FALSE) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults removeObjectForKey:kNSUserDefaultsContainerOneSize];
        [self customContainerSwitchLogic];
    }
}

#pragma mark // Daily Goal NSUser Default Methods

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
