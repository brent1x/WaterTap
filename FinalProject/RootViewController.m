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


//    PFObject *testObject = [PFObject objectWithClassName:@"TestObject"];
//    testObject[@"foo"] = @"bar";
//    [testObject saveInBackground];

//    self.waterLevelHeight = 0;
//    self.waterLevelY = 0;

//    self.waterLevel.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);



    NSLog(@"DIIICK: %f %f", self.view.frame.size.height,self.view.frame.origin.y);

    NSLog(@"self.waterLevel height is %f and self.waterLevel y position is %f", self.waterLevel.frame.size.height, self.waterLevel.frame.origin.y);

    self.consumptionEvents = [NSArray new];

    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        [self refreshWaterLevel];
        self.welcomeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Welcome %@!", nil), [[PFUser currentUser] username]];
    }

    //DEPRECATED DUE TO REMOVAL OF LOGIN AND SIGN UP FLOW
//    else {
//        [self performSegueWithIdentifier:@"LogInOrSignUpSegue" sender:self];
//    }

}

-(void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = YES;


    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        [self refreshWaterLevel];
    }


}

//-(void)viewDidAppear:(BOOL)animated {
//    [UIView animateWithDuration:0.5 animations:^{
//        self.waterLevel.frame = CGRectMake(self.view.frame.origin.x, self.waterLevelY, self.view.frame.size.width, self.waterLevelHeight);
//    }];
//}


- (IBAction)onAddWaterButtonTapped:(id)sender {

    ConsumptionEvent *myConsumptionEvent = [ConsumptionEvent new];

    myConsumptionEvent.volumeConsumed = 10;
    [self changeWaterLevel:myConsumptionEvent.volumeConsumed];
    myConsumptionEvent.user = [PFUser currentUser];
    myConsumptionEvent.consumptionGoal = 32;

    [myConsumptionEvent saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){

        if(!succeeded) {
            NSLog(@"There was an error and u better check yo shit");
        }
        [self totalVolumeConsumed];
    }];

}

-(void)changeWaterLevel:(int) heightChange{

    NSLog(@"1 self.waterLevel height is %f and self.waterLevel y position is %f", self.waterLevel.frame.size.height, self.waterLevel.frame.origin.y);

    CGRect newFrameRect = self.waterLevel.frame;
    newFrameRect.size.height = self.waterLevel.frame.size.height + heightChange;

    newFrameRect.origin.y = self.waterLevel.frame.origin.y - heightChange;

    NSLog(@"2 self.waterLevel height is %f and self.waterLevel y position is %f", self.waterLevel.frame.size.height, self.waterLevel.frame.origin.y);


//    NSLog(@"Height is %f and y position is %f", newFrameRect.size.height, newFrameRect.origin.y);

    [UIView animateWithDuration:0.5 animations:^{

        //        self.waterLevelHeightConstraint.constant += heightChange;
        self.waterLevel.frame = newFrameRect;
        self.waterLevelY = self.waterLevel.frame.origin.y;
        self.waterLevelHeight = self.waterLevel.frame.size.height;
    }];
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
