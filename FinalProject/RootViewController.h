//
//  ViewController.h
//  FinalProject
//
//  Created by Brent Dady on 6/12/15.
//  Copyright (c) 2015 Brent Dady. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
@import HealthKit;

@interface RootViewController : UIViewController

@property (nonatomic) HKHealthStore *healthStore;

@end

