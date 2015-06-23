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

#define kNSUserDailyGoalKey @"kNSUserDailyGoalKey"

@interface RootViewController () <SettingsViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *addWaterButton;
@property (weak, nonatomic) IBOutlet ContainerButton *menuButton1;
@property (weak, nonatomic) IBOutlet ContainerButton *menuButton2;
@property (weak, nonatomic) IBOutlet ContainerButton *menuButton3;
@property NSMutableArray *menuButtons;
//@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;
@property NSArray *consumptionEvents;
@property int currentTotalAmountConsumedToday;
@property (weak, nonatomic) IBOutlet UIView *waterLevel;
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *waterLevelHeightConstraint;
@property float waterLevelHeight;
@property float waterLevelY;
@property UIDynamicAnimator *animator;
@property BOOL isFannedOut;
@property NSString *unitTypeSelected;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self loadGoalFromUserDefaults];

    if (self.currentDailyGoal == 0) {
        self.currentDailyGoal = 64;
    }

    self.unitTypeSelected = @"ounce";
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];

    [self.addWaterButton addTarget:self action:@selector(toggleFan) forControlEvents:UIControlEventTouchUpInside];

    self.menuButtons = [NSMutableArray arrayWithObjects:self.menuButton1, self.menuButton2, self.menuButton3, nil];

    for (ContainerButton *button in self.menuButtons) {
        button.center = self.addWaterButton.center;
    }

    self.menuButton1.customAmount = 10;
    self.menuButton2.customAmount = 10;
    self.menuButton3.customAmount = 10;

    self.navigationController.navigationBarHidden = YES;
    self.consumptionEvents = [NSArray new];

//    PFUser *currentUser = [PFUser currentUser];
    NSLog(@"ANON: %@", [PFUser currentUser]);

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

    NSLog(@"%i", self.currentDailyGoal);
    NSLog(@"viewdidappear %@", self.unitTypeSelected);
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
- (void)unitTypeSelected:(NSString *)unitType {
    self.unitTypeSelected = unitType;
    NSLog(@"unittypeselected %@", unitType);
}

#pragma MARK -ADDING WATER METHODS

- (IBAction)onAddWaterButtonTapped:(id)sender {

    ConsumptionEvent *myConsumptionEvent = [ConsumptionEvent new];

    ContainerButton *button = sender;
    myConsumptionEvent.volumeConsumed = button.customAmount;

    myConsumptionEvent.user = [PFUser currentUser];
    myConsumptionEvent.consumptionGoal = self.currentDailyGoal;
    myConsumptionEvent.consumedAt = [NSDate date];
    [myConsumptionEvent pinInBackground];


     NSLog(@"changing the water level by %i", myConsumptionEvent.volumeConsumed);
    [self changeWaterLevel:myConsumptionEvent.volumeConsumed];

    [self toggleFan];
}


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


- (void)changeWaterLevel:(int) heightChange {

    int adjustedHeightForDailyGoal = (self.view.frame.size.height/self.currentDailyGoal);
    int height = heightChange*adjustedHeightForDailyGoal;

    CGRect newFrameRect = self.waterLevel.frame;

    newFrameRect.size.height = self.waterLevel.frame.size.height + (height);

    newFrameRect.origin.y = self.waterLevel.frame.origin.y - (height);

    if(self.waterLevel.frame.size.height + height >= 667) {


        newFrameRect.size.height = self.waterLevel.frame.size.height + height;

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

    else {
        newFrameRect.size.height = self.waterLevel.frame.size.height + height;

        [UIView animateWithDuration:0.5 animations:^{

            //        self.waterLevelHeightConstraint.constant += heightChange;
            self.waterLevel.frame = newFrameRect;
            self.waterLevelY = self.waterLevel.frame.origin.y;
            self.waterLevelHeight = self.waterLevel.frame.size.height;
        }];
        
    }
}

@end
