//
//  SettingsViewController.h
//  FinalProject
//
//  Created by Brent Dady on 6/18/15.
//  Copyright (c) 2015 Brent Dady. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SettingsViewControllerDelegate

- (void)dailyGoalChanged:(int)dailyGoalAmount;

@end

@interface SettingsViewController : UIViewController

@property id <SettingsViewControllerDelegate> delegate;
@property NSString *recoTotal;

@end

