//
//  ViewController.m
//  FinalProject
//
//  Created by Brent Dady on 6/12/15.
//  Copyright (c) 2015 Brent Dady. All rights reserved.
//

#import "RootViewController.h"
#import "ConsumptionEvent.h"
#import "CustomWaterLevelView.h"

@interface RootViewController ()

@property (weak, nonatomic) IBOutlet UIButton *addWaterButton;
@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;
@property NSArray *consumptionEvents;
@property int totalVolumeSummed;

@property (weak, nonatomic) IBOutlet UIView *waterLevel;
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *waterLevelHeightConstraint;

@property float waterLevelHeight;
@property float waterLevelY;


@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];

 self.navigationController.navigationBarHidden = YES;
    self.consumptionEvents = [NSArray new];

//    PFUser *currentUser = [PFUser currentUser];
    NSLog(@"ANON: %@", [PFUser currentUser]);
}

- (IBAction)onAddWaterButtonTapped:(id)sender {

    ConsumptionEvent *myConsumptionEvent = [ConsumptionEvent new];

    myConsumptionEvent.volumeConsumed = 10;

    myConsumptionEvent.user = [PFUser currentUser];
    myConsumptionEvent.consumptionGoal = 32;
    myConsumptionEvent.consumedAt = [NSDate date];
    [myConsumptionEvent pinInBackground];

    [self changeWaterLevel:myConsumptionEvent.volumeConsumed];
}

-(void)changeWaterLevel:(int) heightChange{



    NSLog(@"1 self.waterLevel height is %f and self.waterLevel y position is %f", self.waterLevel.frame.size.height, self.waterLevel.frame.origin.y);

    CGRect newFrameRect = self.waterLevel.frame;
    newFrameRect.size.height = self.waterLevel.frame.size.height + heightChange;

    newFrameRect.origin.y = self.waterLevel.frame.origin.y - heightChange;

    NSLog(@"2 self.waterLevel height is %f and self.waterLevel y position is %f", self.waterLevel.frame.size.height, self.waterLevel.frame.origin.y);

//    NSLog(@"Height is %f and y position is %f", newFrameRect.size.height, newFrameRect.origin.y);

    if(self.waterLevel.frame.size.height + heightChange >= 667) {


        newFrameRect.size.height = self.waterLevel.frame.size.height + heightChange;

        [UIView animateWithDuration:0.5 animations:^{

            //        self.waterLevelHeightConstraint.constant += heightChange;
            self.waterLevel.frame = newFrameRect;
            self.waterLevelY = self.waterLevel.frame.origin.y;
            self.waterLevelHeight = self.waterLevel.frame.size.height;
            self.waterLevel.backgroundColor = [UIColor colorWithRed:0.96 green:0.85 blue:0.27 alpha:1];
            

        }];
        NSString *messageString = @"You've reached your water intake goal for the day!!!";
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Congratulations you gulper!!" message:messageString delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];

    }

    else{
         newFrameRect.size.height = self.waterLevel.frame.size.height + heightChange;

        [UIView animateWithDuration:0.5 animations:^{

            //        self.waterLevelHeightConstraint.constant += heightChange;
            self.waterLevel.frame = newFrameRect;
            self.waterLevelY = self.waterLevel.frame.origin.y;
            self.waterLevelHeight = self.waterLevel.frame.size.height;
        }];
        
    }
}


- (void)totalVolumeConsumed {
    PFQuery *query = [ConsumptionEvent query];

    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query selectKeys:@[@"volumeConsumed"]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        // NSLog(@"%@", objects);
        self.consumptionEvents = objects;

        self.totalVolumeSummed = 0;

        for (ConsumptionEvent *event in self.consumptionEvents) {

            self.totalVolumeSummed += event.volumeConsumed;
        }

        NSLog(@"%i", self.totalVolumeSummed);
    }];


}

-(void)refreshWaterLevel {

    [self changeWaterLevel:-self.waterLevel.frame.origin.y];
    [self totalVolumeConsumed];
    [self changeWaterLevel:self.totalVolumeSummed];
}
@end
