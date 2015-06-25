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
#import "ContainerButton.h"
#import "SettingsViewController.h"
#define kNSUserWaterLevel @"kNSUserWaterLevelKey"
#define kNSUserDailyGoalKey @"kNSUserDailyGoalKey"
#define kNSUserUnitTypeSelected @"kNSUserUnitTypeSelected"

@interface RootViewController () <SettingsViewControllerDelegate>

//the image view for the water measurement marks on the right side of the view controller
@property (weak, nonatomic) IBOutlet UIImageView *waterMarkImageView;
//the button pressed to bring up the container buttons
@property (weak, nonatomic) IBOutlet UIButton *addWaterButton;

//properties for the buttons that pop up with animation
@property (weak, nonatomic) IBOutlet ContainerButton *menuButton1;
@property (weak, nonatomic) IBOutlet ContainerButton *menuButton2;
@property (weak, nonatomic) IBOutlet ContainerButton *menuButton3;
@property NSMutableArray *menuButtons;

@property NSArray *consumptionEvents;
@property int currentTotalAmountConsumedToday;
@property (weak, nonatomic) IBOutlet UIView *waterLevel;

//ignore these two variables, nader added them in and I'm not sure what they do
@property float waterLevelHeight;
@property float waterLevelY;

//properties for animation for the button
@property UIDynamicAnimator *animator;
@property BOOL isFannedOut;
//unit type persistence (old, updated in Brent's new push)
@property NSString *unitTypeSelected;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//Loading the goal from user defaults upon opening the app
    [self loadGoalFromUserDefaults];

    //if the current daily goal is 0, set it to a default of 64 and save to user defaults
    if (self.currentDailyGoal == 0) {
        self.currentDailyGoal = 100;
        [self saveGoalToUserDefaults];
    }

    self.unitTypeSelected = @"ounce";

    // setting default unit to 'ounce' and then checking to determine if unit type has changed to 'milliliter'
    // note: also running the test in viewWillAppear
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *goalFromDefault = [userDefaults objectForKey:kNSUserUnitTypeSelected];
    NSLog(@"user defaults type: %@", goalFromDefault);


    // self.unitTypeSelected = @"ounce";


    //this is all animation set up for the buttons

    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    [self.addWaterButton addTarget:self action:@selector(toggleFan) forControlEvents:UIControlEventTouchUpInside];
    self.menuButtons = [NSMutableArray arrayWithObjects:self.menuButton1, self.menuButton2, self.menuButton3, nil];
    for (ContainerButton *button in self.menuButtons) {
        button.center = self.addWaterButton.center;
    }
    self.menuButton1.customAmount = 10;
    self.menuButton2.customAmount = 10;
    self.menuButton3.customAmount = 10;

    self.consumptionEvents = [NSArray new];

    //user defaults test for whether the app has been launched, this would be used for creating a tutorial for first time users
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"]) {

    }

    else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedOnce"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        // This is the first launch ever
        //Take user through tutorial
    }
}


- (void)viewDidAppear:(BOOL)animated {


}

- (void)viewWillAppear:(BOOL)animated{
    self.navigationController.navigationBarHidden = YES;
    [self.view sendSubviewToBack:self.waterMarkImageView];
    [self.view sendSubviewToBack:self.waterLevel];


    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *goalFromDefault = [userDefaults objectForKey:kNSUserUnitTypeSelected];
    NSLog(@"user defaults type: %@", goalFromDefault);


    self.navigationController.navigationBarHidden = YES;
    //when the root view controller appears, either initially or after coming back from another view controller, get the water level that is stored in user defaults, and pass it in to the "loadPersistentWaterLevel" method. This method adjusts the persistent water level back to a non-goal-relative amount so that it can be used in the regular changeWaterLevel method.
//    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//    int persistentWaterHeight = [[userDefaults objectForKey:kNSUserWaterLevel]intValue];
////    [self loadPersistentWaterLevel:persistentWaterHeight];
    [self loadWaterLevel];

    if (self.currentDailyGoal == 0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Yo." message:@"You can't have a goal of zero." preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Go set a goal." style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self performSegueWithIdentifier:@"settingsSegue" sender:self];
        }];

        [alertController addAction:action];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

#pragma MARK - Change Daily Goal Methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"settingsSegue"]) {
        SettingsViewController *sVC = segue.destinationViewController;
        sVC.delegate = self;
    }
}

- (void)dailyGoalChanged:(int)dailyGoalAmount {
    self.currentDailyGoal = dailyGoalAmount;
    [self saveGoalToUserDefaults];
}

- (void)saveGoalToUserDefaults {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *string = [NSString stringWithFormat:@"%i", self.currentDailyGoal];
    [userDefaults setObject:string forKey:kNSUserDailyGoalKey];
} 

- (void)loadGoalFromUserDefaults {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *goalFromDefault = [userDefaults objectForKey:kNSUserDailyGoalKey];
    self.currentDailyGoal = [goalFromDefault intValue];
}

#pragma MARK -UNIT SELECTION METHOD 
//This method probably should just be removed, doesn't do anything of value, and Brent's push should take care of this

- (void)unitTypeSelected:(NSString *)unitType {
    self.unitTypeSelected = unitType;
    NSLog(@"unittypeselected %@", unitType);
}

#pragma MARK -ADDING WATER METHODS


- (IBAction)onAddWaterButtonTapped:(id)sender {

    //make a new consumption event, and do required set up. Assign the volume consumed of the consumption event to be equal to the  custom amount property of the Container Button instance. This will allow us to assign different values to the different container buttons (and eventually make them related to custom containers added by the user
     ConsumptionEvent *myConsumptionEvent = [ConsumptionEvent new];
    ContainerButton *button = sender;
    myConsumptionEvent.volumeConsumed = button.customAmount;
    myConsumptionEvent.user = [PFUser currentUser];
    myConsumptionEvent.consumptionGoal = self.currentDailyGoal;
    myConsumptionEvent.consumedAt = [NSDate date];
    //save the consumption event to local data store, eventually to be uploaded to Parse (or not)
    [myConsumptionEvent pinInBackground];

    //Change the current water level by the volume consumed in the consumption event (See "changeWaterLevel" method
    [self changeWaterLevel:[NSNumber numberWithInt:myConsumptionEvent.volumeConsumed]];

    //check and switch the state of the animation so the buttons pop back in
    [self toggleFan];
}


//This is the method that takes the water level stored in user defaults, then adjusts it to a non-goal relative amount so it can be passed in to the changeWaterLevel method
-(void)loadWaterLevel {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *totalConsumedToday = [userDefaults objectForKey:kNSUserWaterLevel];
    NSLog(@"Total consumed Today %@", totalConsumedToday);

    float proportion = [totalConsumedToday floatValue] / self.currentDailyGoal;
    float heightDisplayed = proportion * self.view.frame.size.height;

    CGRect newFrameRect = self.waterLevel.frame;
    newFrameRect.size.height += heightDisplayed;
    newFrameRect.origin.y -= heightDisplayed;

    [UIView animateWithDuration:0.5 animations:^{
        self.waterLevel.frame = newFrameRect;
    }];


}
- (void)changeWaterLevel:(NSNumber *)amountConsumed {

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *totalConsumedToday = [userDefaults objectForKey:kNSUserWaterLevel];
    totalConsumedToday = [NSNumber numberWithInt:([totalConsumedToday intValue] + [amountConsumed intValue])];
    NSLog(@"totaConsumedToday: %@", totalConsumedToday);
     [userDefaults setObject:totalConsumedToday forKey:kNSUserWaterLevel];


    float proportion = [totalConsumedToday floatValue] / self.currentDailyGoal;
    float heightDisplayed = proportion * self.view.frame.size.height;

    //
    CGRect newFrameRect = self.waterLevel.frame;
    newFrameRect.size.height += heightDisplayed;
    newFrameRect.origin.y -= heightDisplayed;

    if(newFrameRect.size.height <= self.view.frame.size.height) {

        [UIView animateWithDuration:0.5 animations:^{
            self.waterLevel.frame = newFrameRect;
        }];

    }

    else {

        [UIView animateWithDuration:0.5 animations:^{
            self.waterLevel.frame = newFrameRect;
        }];

        NSString *messageString = @"You've reached your water intake goal for the day!!!";
                   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Congratulations you gulper!!" message:messageString delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                  [alert show];
    }




//    //adjustments to make the height to be added proportional to the current goal and height of the view in the view controller
//    NSLog(@"Water change amount %i",heightChange);
//    float adjustedHeightForDailyGoal = (float)(self.view.frame.size.height/self.currentDailyGoal);
//    float height = (float)(heightChange*adjustedHeightForDailyGoal);
//    NSLog(@"Water change amount in proportion to goal %f",height);
//
//    //create a new rect that is equal to what will be the new current water height
//
//    CGRect newFrameRect = self.waterLevel.frame;
//    newFrameRect.size.height = self.waterLevel.frame.size.height + (height);
//    newFrameRect.origin.y = self.waterLevel.frame.origin.y - (height);
//     NSLog(@"the current water level height is %f and the current water level y is %f",self.waterLevel.frame.size.height, self.waterLevel.frame.origin.y);
//
//    //if the current water level height + the height to be added exceeds the height of the view, do the following
//    if(self.waterLevel.frame.size.height + height >= 667.0) {
//
//        [UIView animateWithDuration:0.5 animations:^{
//
//            //assign the current waterLevel frame to the newly made newFrameRect, thus adding the water to the current water level
//            self.waterLevel.frame = newFrameRect;
//            self.waterLevelY = self.waterLevel.frame.origin.y;
//            self.waterLevelHeight = self.waterLevel.frame.size.height;
//
//            //set the waterLevel color
//            self.waterLevel.backgroundColor = [UIColor colorWithRed:0.96 green:0.85 blue:0.27 alpha:1];
//
//            //create an alert to tell the user they've reached their goal
//            NSString *messageString = @"You've reached your water intake goal for the day!!!";
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Congratulations you gulper!!" message:messageString delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//            [alert show];
//
//        }];


//    }
////if the user has not reached their goal yet, do the following
//    else {
//
//        [UIView animateWithDuration:0.5 animations:^{
//
//            //assign the current water level frame to the newly created frame
//            self.waterLevel.frame = newFrameRect;
//   NSLog(@"the new frame height is %f and the new frame y is %f",self.waterLevel.frame.size.height, self.waterLevel.frame.origin.y);
//            self.waterLevelY = self.waterLevel.frame.origin.y;
//            self.waterLevelHeight = self.waterLevel.frame.size.height;
//
//            //save the new current water level to user defaults
//            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//            NSNumber *persistentWaterHeight = [NSNumber numberWithFloat:self.waterLevel.frame.size.height];
//            [userDefaults setObject:persistentWaterHeight forKey:kNSUserWaterLevel];
//            NSLog(@"%@", persistentWaterHeight);
//        }];
//        
//    }
//    
}


#pragma MARK -BUTTON ANIMATION METHODS
//checks the state of the buttons, whether they are "fanned out" or "fanned in," then switches the state

- (void)toggleFan {

    [self.animator removeAllBehaviors];
    if (self.isFannedOut){
        [self fanIn];
    }
    else {
        [self fanOut];
    }

    self.isFannedOut = !self.isFannedOut;
}

-(void)fanOut {
    CGPoint point = CGPointMake(self.addWaterButton.frame.origin.x + 100, self.addWaterButton.frame.origin.y - 50);
    UISnapBehavior *snapBehavior = [[UISnapBehavior alloc] initWithItem:self.menuButton1 snapToPoint:point];
    [self.animator addBehavior:snapBehavior];

    point = CGPointMake(self.addWaterButton.frame.origin.x+30, self.addWaterButton.frame.origin.y - 50);
    snapBehavior = [[UISnapBehavior alloc] initWithItem:self.menuButton2 snapToPoint:point];
    [self.animator addBehavior:snapBehavior];

    point = CGPointMake(self.addWaterButton.frame.origin.x - 40, self.addWaterButton.frame.origin.y - 50);
    snapBehavior = [[UISnapBehavior alloc] initWithItem:self.menuButton3 snapToPoint:point];
    [self.animator addBehavior:snapBehavior];

}

- (void)fanIn {

    CGPoint point = self.addWaterButton.center;

    UISnapBehavior *snapBehavior = [[UISnapBehavior alloc] initWithItem:self.menuButton1 snapToPoint:point];
    [self.animator addBehavior:snapBehavior];

    snapBehavior = [[UISnapBehavior alloc] initWithItem:self.menuButton2 snapToPoint:point];
    [self.animator addBehavior:snapBehavior];

    snapBehavior = [[UISnapBehavior alloc] initWithItem:self.menuButton3 snapToPoint:point];
    [self.animator addBehavior:snapBehavior];
    
}



@end
