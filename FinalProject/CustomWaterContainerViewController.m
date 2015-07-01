//
//  CustomWaterContainerViewController.m
//  FinalProject
//
//  Created by Brent Dady on 6/20/15.
//  Copyright (c) 2015 Brent Dady. All rights reserved.
//

#import "CustomWaterContainerViewController.h"

#define kNSUserDefaultsContainerOneSize @"kNSUserDefaultsContainerOneSize"
#define kNSUserUnitTypeSelected @"kNSUserUnitTypeSelected"

@interface CustomWaterContainerViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *containerOneText;
@property (weak, nonatomic) IBOutlet UIButton *containerOneAdd;
@property (weak, nonatomic) IBOutlet UILabel *explainerLabel;

@end

@implementation CustomWaterContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = @"Custom Container";

    // running a check in VDL to determine if custom containers have been set. if they have, I prepopulate
    // the text boxes with the saved values. if they haven't been set, I prompt user to create the containers
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *containerOneIntValue = [userDefaults objectForKey:kNSUserDefaultsContainerOneSize];
    NSString *unitTypeSelected = [userDefaults objectForKey:kNSUserUnitTypeSelected];
    if ([unitTypeSelected isEqualToString:@"milliliter"]) {
        self.containerOneText.placeholder = @"Size in mL";
        self.explainerLabel.text = @"Here you can set the size of your water container. The default size is set to 236.5 milliliters.";
        if ([containerOneIntValue intValue] > 0) {
            int containerOneIntValueMLConversion = ([containerOneIntValue intValue] * 29.5735);
            NSString *containerOneIntValueMLConversionString = [NSString stringWithFormat:@"%i", containerOneIntValueMLConversion];
            self.containerOneText.text = [NSString stringWithFormat:@"%@", containerOneIntValueMLConversionString];
        }
    } else {
        self.containerOneText.placeholder = @"Size in ounces";
        self.explainerLabel.text = @"Here you can set the size of your water container. The default size is set to 8 ounces.";
        if ([containerOneIntValue intValue] > 0) {
            self.containerOneText.text = [NSString stringWithFormat:@"%@", containerOneIntValue];
        }
    }

    UIColor *myBlueColor = [UIColor colorWithRed:27.0/255.0 green:152.0/255.0 blue:224.0/255.0 alpha:1];
    UIColor *myGrayColor = [UIColor colorWithRed:232.0/255.0 green:241.0/255.0 blue:242.0/255.0 alpha:1];
    self.view.backgroundColor = myGrayColor;

    self.containerOneText.layer.cornerRadius = 3.0f;
    self.containerOneText.layer.borderWidth = 1;
    self.containerOneText.layer.borderColor = myBlueColor.CGColor;

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Reset" style:UIBarButtonItemStylePlain target:self action:@selector(containerOneDeleted:)];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark // Update Custom Containers

- (IBAction)containerOneAdded:(id)sender {
    // these 2 methods save, as an integer, the value entered into the text box for a container's volume into NSUserDefaults

    if (![self.containerOneText.text intValue] > 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"You've broken physics!" message:@"Please enter a real size (greater than 0) for your custom container." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    } else {
        int containerOneIntValue = [self.containerOneText.text intValue];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setInteger:containerOneIntValue forKey:kNSUserDefaultsContainerOneSize];
    }
}

#pragma mark // Delete Custom Containers

- (void)containerOneDeleted:(id)sender {
    // these 2 methods set custom containers' volumes equal to null and clear the text box

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:kNSUserDefaultsContainerOneSize];
    NSString *unitTypeSelected = [userDefaults objectForKey:kNSUserUnitTypeSelected];

    if ([unitTypeSelected isEqualToString:@"ounce"]) {
        self.containerOneText.placeholder = @"Size in ounces";
    }
    else if ([unitTypeSelected isEqualToString:@"milliliter"]) {
        self.containerOneText.placeholder = @"Size in mL";
    }
}

@end
