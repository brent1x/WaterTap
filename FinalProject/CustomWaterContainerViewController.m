//
//  CustomWaterContainerViewController.m
//  FinalProject
//
//  Created by Brent Dady on 6/20/15.
//  Copyright (c) 2015 Brent Dady. All rights reserved.
//

#import "CustomWaterContainerViewController.h"

#define kNSUserDefaultsContainerOneSize @"kNSUserDefaultsContainerOneSize"
#define kNSUserDefaultsContainerTwoSize @"kNSUserDefaultsContainerTwoSize"

@interface CustomWaterContainerViewController ()
@property (weak, nonatomic) IBOutlet UITextField *containerOneText;
@property (weak, nonatomic) IBOutlet UITextField *containerTwoText;
@property (weak, nonatomic) IBOutlet UIButton *containerOneAdd;
@property (weak, nonatomic) IBOutlet UIButton *containerTwoAdd;
@property (weak, nonatomic) IBOutlet UIButton *containerOneDelete;
@property (weak, nonatomic) IBOutlet UIButton *containerTwoDelete;

@end

@implementation CustomWaterContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *containerOneIntValue = [userDefaults objectForKey:kNSUserDefaultsContainerOneSize];
    NSString *containerTwoIntValue = [userDefaults objectForKey:kNSUserDefaultsContainerTwoSize];

    if ([containerOneIntValue intValue] > 0) {
        self.containerOneText.text = [NSString stringWithFormat:@"%@", containerOneIntValue];
    } else {
        self.containerOneText.placeholder = @"Enter a container size.";
    }

    if ([containerTwoIntValue intValue] > 0) {
        self.containerTwoText.text = [NSString stringWithFormat:@"%@", containerTwoIntValue];
    } else {
        self.containerTwoText.placeholder = @"Enter a container size.";
    }

}

- (IBAction)containerOneAdded:(id)sender {
    int containerOneIntValue = [self.containerOneText.text intValue];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:containerOneIntValue forKey:kNSUserDefaultsContainerOneSize];
    NSLog(@"%i", containerOneIntValue);
}

- (IBAction)containerTwoAdded:(id)sender {
    int containerTwoIntValue = [self.containerTwoText.text intValue];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:containerTwoIntValue forKey:kNSUserDefaultsContainerTwoSize];
    NSLog(@"%i", containerTwoIntValue);
}

- (IBAction)containerOneDeleted:(id)sender {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:kNSUserDefaultsContainerOneSize];
    self.containerOneText.text = @"";
    self.containerOneText.placeholder = @"Enter a container size.";
}

- (IBAction)containerTwoDeleted:(id)sender {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:kNSUserDefaultsContainerTwoSize];
    self.containerTwoText.text = @"";
    self.containerTwoText.placeholder = @"Enter a container size.";
}

@end
