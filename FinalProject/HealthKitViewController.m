//
//  HealthKitViewController.m
//  FinalProject
//
//  Created by Brent Dady on 6/18/15.
//  Copyright (c) 2015 Brent Dady. All rights reserved.
//

#import "HealthKitViewController.h"
#import "HKHealthStore+AAPLExtensions.h"
#import "SettingsViewController.h"

#define kNSUserUnitTypeSelected @"kNSUserUnitTypeSelected"
#define kNSUserReceivedRecommendation @"kNSUserReceivedRecommendation"

@interface HealthKitViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *heightTextField;
@property (weak, nonatomic) IBOutlet UITextField *weightTextField;
@property (weak, nonatomic) IBOutlet UITextField *strenousActivityTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *climateSelectedSegment;
@property (weak, nonatomic) IBOutlet UILabel *calculateTextField;
@property (weak, nonatomic) IBOutlet UIButton *goButton;
@property (weak, nonatomic) IBOutlet UILabel *suggestedGoalLabel;
@property (weak, nonatomic) IBOutlet UIView *suggestedGoalView;
@property double mlMultiplier;

@end

@implementation HealthKitViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.goButton.hidden = YES;
    self.suggestedGoalLabel.hidden = YES;
    self.suggestedGoalView.hidden = YES;
    [self styling];

    // this initializes the healthStore (db provided by HealthKit)
    self.healthStore = [[HKHealthStore alloc] init];

    // since HK isn't on iPad or older iOS versions, I check to see if it's available to the user
    if ([HKHealthStore isHealthDataAvailable]) {
        NSSet *writeDataTypes = [self dataTypesToWrite];
        NSSet *readDataTypes = [self dataTypesToRead];

        [self.healthStore requestAuthorizationToShareTypes:writeDataTypes readTypes:readDataTypes completion:^(BOOL success, NSError *error) {
            if (!success) {
                NSLog(@"Error: %@", error);
                return;
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                // if HK is available, I call the following methods, which will grab values from HK to use in the app
                // [self updateUsersAgeLabel];
                [self updateUsersHeightLabel];
                [self updateUsersWeightLabel];
            });
        }];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)styling {
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.title = @"Custom Goal";

    UIColor *myGrayColor = [UIColor colorWithRed:232.0/255.0 green:241.0/255.0 blue:242.0/255.0 alpha:1];
    UIColor *myBlueColor = [UIColor colorWithRed:27.0/255.0 green:152.0/255.0 blue:224.0/255.0 alpha:1];
    self.view.backgroundColor = myGrayColor;
    self.heightTextField.layer.cornerRadius = 3.0f;
    self.heightTextField.layer.borderWidth = 1;
    self.heightTextField.layer.borderColor = myBlueColor.CGColor;
    self.weightTextField.layer.cornerRadius = 3.0f;
    self.weightTextField.layer.borderWidth = 1;
    self.weightTextField.layer.borderColor = myBlueColor.CGColor;
    self.strenousActivityTextField.layer.cornerRadius = 3.0f;
    self.strenousActivityTextField.layer.borderWidth = 1;
    self.strenousActivityTextField.layer.borderColor = myBlueColor.CGColor;
}

#pragma mark // Write Data Permissions to HealthKit
- (NSSet *)dataTypesToWrite {

    // HKQuantityType *proteinType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryProtein];
    return [NSSet setWithObjects:nil];

    /* THESE TWO LINES WILL LET ME WRITE WATER QUANTITY TYPES TO HEALTHKIT UPON iOS9 RELEASE */
    // HKQuantityType *waterType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryWater];
    // return [NSSet setWithObjects:waterType, nil];
}

#pragma mark // Read Data Permissions from HealthKit
- (NSSet *)dataTypesToRead {
    HKQuantityType *heightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    HKQuantityType *weightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    // HKCharacteristicType *birthdayType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth];

    return [NSSet setWithObjects:heightType, weightType, nil];
}

#pragma mark // Update Labels With User's Data from HealthKit
//- (void)updateUsersAgeLabel {
//    NSError *error;
//    NSDate *dateOfBirth = [self.healthStore dateOfBirthWithError:&error];
//    if (!dateOfBirth) {
//        NSLog(@"Either an error occured fetching the user's age information or none has been stored yet.");
//        self.ageTextField.text = NSLocalizedString(@"Not available in HealthKit. Please enter your age.", nil);
//    }
//
//    else {
//        // This will compute the age of the user if age isn't provided
//        NSDate *now = [NSDate date];
//        NSDateComponents *ageComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:dateOfBirth toDate:now options:NSCalendarWrapComponents];
//        NSUInteger usersAge = [ageComponents year];
//        self.ageTextField.text = [NSNumberFormatter localizedStringFromNumber:@(usersAge) numberStyle:NSNumberFormatterNoStyle];
//    }
//}

- (void)updateUsersHeightLabel {
    // Fetch user's default height unit in inches.
    NSLengthFormatter *lengthFormatter = [[NSLengthFormatter alloc] init];
    lengthFormatter.unitStyle = NSFormattingUnitStyleLong;

    NSLengthFormatterUnit heightFormatterUnit = NSLengthFormatterUnitInch;
    NSString *heightUnitString = [lengthFormatter unitStringFromValue:10 unit:heightFormatterUnit];
    NSString *localizedHeightUnitDescriptionFormat = NSLocalizedString(@"Height (%@)", nil);

    self.heightTextField.text = [NSString stringWithFormat:localizedHeightUnitDescriptionFormat, heightUnitString];

    HKQuantityType *heightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];

    // Query to get the user's latest height, if it exists.
    [self.healthStore aapl_mostRecentQuantitySampleOfType:heightType predicate:nil completion:^(HKQuantity *mostRecentQuantity, NSError *error) {
        if (!mostRecentQuantity) {
            NSLog(@"Either an error occured fetching the user's height information or none has been stored yet.");

            dispatch_async(dispatch_get_main_queue(), ^{
                self.heightTextField.text = @"";
            });
        }

        else {
            // Determine the height in the required unit (inches).
            HKUnit *heightUnit = [HKUnit inchUnit];
            double usersHeight = [mostRecentQuantity doubleValueForUnit:heightUnit];

            // Update the user interface.
            dispatch_async(dispatch_get_main_queue(), ^{
                self.heightTextField.text = [NSNumberFormatter localizedStringFromNumber:@(usersHeight) numberStyle:NSNumberFormatterNoStyle];
            });
        }
    }];
}

- (void)updateUsersWeightLabel {
    // Fetch the user's default weight unit in the required unit (pounds).
    NSMassFormatter *massFormatter = [[NSMassFormatter alloc] init];
    massFormatter.unitStyle = NSFormattingUnitStyleLong;

    NSMassFormatterUnit weightFormatterUnit = NSMassFormatterUnitPound;
    NSString *weightUnitString = [massFormatter unitStringFromValue:10 unit:weightFormatterUnit];
    NSString *localizedWeightUnitDescriptionFormat = NSLocalizedString(@"Weight (%@)", nil);

    self.weightTextField.text = [NSString stringWithFormat:localizedWeightUnitDescriptionFormat, weightUnitString];

    // Query to get the user's latest weight, if it exists.
    HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];

    [self.healthStore aapl_mostRecentQuantitySampleOfType:weightType predicate:nil completion:^(HKQuantity *mostRecentQuantity, NSError *error) {
        if (!mostRecentQuantity) {
            NSLog(@"Either an error occured fetching the user's height information or none has been stored yet.");
            dispatch_async(dispatch_get_main_queue(), ^{
                self.weightTextField.text = @"";
            });
        }
        else {
            // Determine the weight in the required unit.
            HKUnit *weightUnit = [HKUnit poundUnit];
            double usersWeight = [mostRecentQuantity doubleValueForUnit:weightUnit];

            // Update the user interface.
            dispatch_async(dispatch_get_main_queue(), ^{
                self.weightTextField.text = [NSNumberFormatter localizedStringFromNumber:@(usersWeight) numberStyle:NSNumberFormatterNoStyle];
            });
        }
    }];
}

#pragma mark // Calculate Recommended Water Intake

- (IBAction)onCalculateTapped:(id)sender {
    // this method calculates the recommended amount of water the user should consume per day

    // normalizing for climate
    double climateMultiplier = 1;
    if (self.climateSelectedSegment.selectedSegmentIndex == 0) {
        climateMultiplier = 1.09;
    } else if (self.climateSelectedSegment.selectedSegmentIndex == 2) {
        climateMultiplier = 1.21;
    }

    // normalizing for weight
    double weightMultiplier;

    if ([self.weightTextField.text doubleValue] < 1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oh noes!" message:@"Please enter actual numbers to calculate your daily goal." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    } else if ([self.weightTextField.text doubleValue] <= 100) {
        weightMultiplier = 1.1;
    } else if ([self.weightTextField.text doubleValue] > 100 && [self.weightTextField.text doubleValue] <= 125) {
        weightMultiplier = 1.075;
    } else if ([self.weightTextField.text doubleValue] > 125 && [self.weightTextField.text doubleValue] <= 150) {
        weightMultiplier = 1.05;
    } else if ([self.weightTextField.text doubleValue] > 150 && [self.weightTextField.text doubleValue] <= 175) {
        weightMultiplier = 1.025;
    } else if ([self.weightTextField.text doubleValue] > 175 && [self.weightTextField.text doubleValue] <= 200) {
        weightMultiplier = 1;
    } else if ([self.weightTextField.text doubleValue] > 200 && [self.weightTextField.text doubleValue] <= 225) {
        weightMultiplier = .975;
    } else if ([self.weightTextField.text doubleValue] > 225 && [self.weightTextField.text doubleValue] <= 250) {
        weightMultiplier = 0.95;
    } else if ([self.weightTextField.text doubleValue] > 250 && [self.weightTextField.text doubleValue] <= 300) {
        weightMultiplier = 0.925;
    } else if ([self.weightTextField.text doubleValue] > 300) {
        weightMultiplier = 0.9;
    }

    // the following 2 checks are implemented to prevent jokers from trying to break the app with negative numbers
    if ([self.heightTextField.text doubleValue] < 0 || [self.strenousActivityTextField.text doubleValue] < 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oh noes!" message:@"Please enter actual numbers to calculate your daily goal." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }

    // this section checks whether they have mL set as the preferred unit type; if so I convert from ounces to mLs
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *goalFromDefault = [userDefaults objectForKey:kNSUserUnitTypeSelected];
    if ([goalFromDefault isEqualToString:@"milliliter"]) {
        self.mlMultiplier = 29.5735;
    } else {
        self.mlMultiplier = 1;
    }

    // this section is the patented algorithm, along with TRACKER, that makes this app a decacorn
    double strenous = ([self.strenousActivityTextField.text doubleValue] * .6);
    double goal = ((((([self.weightTextField.text doubleValue] * weightMultiplier) * .5333) + strenous) * climateMultiplier) * self.mlMultiplier);
    int myInt = (int)(goal + (goal > 0 ? 0.5 : -0.5));
    self.calculateTextField.text = [NSString stringWithFormat:@"%i", myInt];

    if ([goalFromDefault isEqualToString:@"milliliter"]) {
        self.suggestedGoalLabel.text = @"Suggested goal (mL):";
    } else {
        self.suggestedGoalLabel.text = @"Suggested goal (oz):";
    }

    self.suggestedGoalLabel.hidden = FALSE;
    self.suggestedGoalView.hidden = FALSE;
    self.goButton.hidden = FALSE;
}

#pragma mark // Prepare for Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // this is just passing the value I calculated in the above method back to the Settings VC when we segue back
    // also setting a bool to true, indicating a recommendation has been made – this was created to persist the
    // state of a switch on the Settings page

    SettingsViewController *destVC = segue.destinationViewController;
    destVC.recoTotal = self.calculateTextField.text;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:TRUE forKey:kNSUserReceivedRecommendation];
}

#pragma mark // To Be Used To Write Water Data To HealthKit on iOS9

//- (IBAction)addProtein:(UIButton *)sender {
//    // Some weight in gram
//    double proteinInGrams = [self.proteinText.text doubleValue];
//
//    // Create an instance of HKQuantityType and HKQuantity to specify the data type and value you want to update
//    NSDate *now = [NSDate date];
//    HKQuantityType *hkQuantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryProtein];
//    HKQuantity *hkQuantity = [HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:proteinInGrams];
//
//    // Create the concrete sample
//    HKQuantitySample *proteinSample = [HKQuantitySample quantitySampleWithType:hkQuantityType
//                                                                      quantity:hkQuantity
//                                                                     startDate:now
//                                                                       endDate:now];
//
//    // Update the protein consumed in the health store
//    [self.healthStore saveObject:proteinSample withCompletion:^(BOOL success, NSError *error) {
//        if (!success) {
//            NSLog(@"you crashed, homie: %@. this is your proteinSample data: %@", error, proteinSample);
//            abort();
//        }
//    }];
//
//}

// - (IBAction)addWater:(UIButton *)sender {
//
//     double waterInOunces = [self.proteinText.text doubleValue];
//
//     NSDate *now = [NSDate date];
//     HKQuantityType *hkQuantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryWater];
//     HKQuantity *hkQuantity = [HKQuantity quantityWithUnit:[HKUnit ounceUnit] doubleValue:waterInOunces];
//
//     HKQuantitySample *drinkSample = [HKQuantitySample quantitySampleWithType:hkQuantityType
//                                                                     quantity:hkQuantity
//                                                                    startDate:now
//                                                                      endDate:now];
//
//     [self.healthStore saveObject:drinkSample withCompletion:^(BOOL success, NSError *error) {
//         if (!success) {
//            NSLog(@"An error occured saving the drink sample %@. The error was: %@.", drinkSample, error);
//             abort();
//        }
//     }];
//
// }

@end