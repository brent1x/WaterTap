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


@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    PFObject *testObject = [PFObject objectWithClassName:@"TestObject"];
//    testObject[@"foo"] = @"bar";
//    [testObject saveInBackground];


//    self.waterLevel.frame = CGRectMake(self.view.frame.origin.x,self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);

    NSLog(@"self.waterLevel height is %f and self.waterLevel y position is %f", self.waterLevel.frame.size.height, self.waterLevel.frame.origin.y);

    self.consumptionEvents = [NSArray new];
    //need to make self the delegate of the root view controller??
    //refactor root view controller
    //make rvc something like "LogInAndSignUpViewController"

    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        self.welcomeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Welcome %@!", nil), [[PFUser currentUser] username]];
    } else {
        [self performSegueWithIdentifier:@"LogInOrSignUpSegue" sender:self];
    }

}


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


    NSLog(@"self.waterLevel height is %f and self.waterLevel y position is %f", self.waterLevel.frame.size.height, self.waterLevel.frame.origin.y);

    CGRect newFrameRect = self.waterLevel.frame;
    newFrameRect.size.height = self.waterLevel.frame.size.height + heightChange;

    newFrameRect.origin.y = self.waterLevel.frame.origin.y - heightChange;


    NSLog(@"Height is %f and y position is %f", newFrameRect.size.height, newFrameRect.origin.y);

    [UIView animateWithDuration:0.5 animations:^{

        //        self.waterLevelHeightConstraint.constant += heightChange;
        self.waterLevel.frame = newFrameRect;

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


@end
