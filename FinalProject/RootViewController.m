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

#define kNSUserWaterLevelKey @"kNSUserWaterLevelKey"
#define kNSUserDailyGoalKey @"kNSUserDailyGoalKey"
#define kNSUserUnitTypeSelected @"kNSUserUnitTypeSelected"
#define kNSUserDefaultsContainerOneSize @"kNSUserDefaultsContainerOneSize"
#define kNSUserDefaultsContainerTwoSize @"kNSUserDefaultsContainerTwoSize"
#define kNSUserDefaultsDateCheck @"kNSUserDefaultsDateCheck"

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

    //TODO: Fix currentDailyGoal problem. It needs to be set to something. >=64. app crashes if user tries to set 0 as daily goal
    self.currentDailyGoal = 64;

    self.unitTypeSelected = @"ounce";

    //animation for buttons
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    [self.addWaterButton addTarget:self action:@selector(toggleFan) forControlEvents:UIControlEventTouchUpInside];
    self.menuButtons = [NSMutableArray arrayWithObjects:self.menuButton1, self.menuButton2, self.menuButton3, nil];
    for (ContainerButton *button in self.menuButtons) {
        button.center = self.addWaterButton.center;
    }

    self.consumptionEvents = [NSArray new];
    [self dateCheck];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {

    NSLog(@"%i", self.currentDailyGoal);

    [self checkForZeroGoal];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dateCheck) name:UIApplicationDidBecomeActiveNotification object:nil];

    self.navigationController.navigationBarHidden = YES;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *bottleOneAmount = [userDefaults objectForKey:kNSUserDefaultsContainerOneSize];
    NSString *bottleTwoAmount = [userDefaults objectForKey:kNSUserDefaultsContainerTwoSize];

    self.menuButton1.customAmount = [bottleTwoAmount intValue];
    self.menuButton2.customAmount = 8;
    self.menuButton3.customAmount = [bottleOneAmount intValue];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidLayoutSubviews {
    [self checkForZeroGoal];
    [self loadWaterLevelBeforeDisplay];
}

- (void)checkForZeroGoal {
    if (self.currentDailyGoal == 0) {
        self.currentDailyGoal = 64;
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Yo." message:@"You can't have a goal of zero." preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Go set a goal." style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self performSegueWithIdentifier:@"settingsSegue" sender:self];
        }];

        [alertController addAction:action];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

#pragma MARK -ADDING WATER METHODS

- (IBAction)onAddWaterButtonTapped:(id)sender {

    ConsumptionEvent *myConsumptionEvent = [ConsumptionEvent new];
    ContainerButton *button = sender;
    myConsumptionEvent.volumeConsumed = button.customAmount;
    myConsumptionEvent.user = [PFUser currentUser];
    myConsumptionEvent.consumptionGoal = self.currentDailyGoal;
    myConsumptionEvent.consumedAt = [NSDate date];
    //save the consumption event to local data store, eventually to be uploaded to Parse (or not)
    [myConsumptionEvent pinInBackground];

    //Change the current water level by the volume consumed in the consumption event (See "changeWaterLevel" method

    NSNumber *toBeSent = [NSNumber numberWithInt:myConsumptionEvent.volumeConsumed];
    [self addWaterLevel:toBeSent];
    [self.undoManager registerUndoWithTarget:self selector:@selector(subtractWaterLevel:) object:toBeSent];

    //check and switch the state of the animation so the buttons pop back in
    [self toggleFan];
}

- (void)subtractWaterLevel:(NSNumber *)amountConsumed {

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *totalConsumedToday = [userDefaults objectForKey:kNSUserWaterLevelKey];
    totalConsumedToday = [NSNumber numberWithFloat:([totalConsumedToday floatValue] - [amountConsumed floatValue])];
    [userDefaults setObject:totalConsumedToday forKey:kNSUserWaterLevelKey];

   float amountConsumedToBeSubtractedFromY = (([amountConsumed floatValue] * self.view.frame.size.height) / self.currentDailyGoal);

    CGRect rect = CGRectMake(self.waterLevel.frame.origin.x, (self.waterLevel.frame.origin.y) +amountConsumedToBeSubtractedFromY, self.waterLevel.frame.size.width, [self getWaterHeightFromTotalConsumedToday]);


    if ([self getWaterHeightFromTotalConsumedToday] > 0) {

        [UIView animateWithDuration:0.5 animations:^{
            self.waterLevel.frame = rect;
        }];

    } else {
        [UIView animateWithDuration:0.5 animations:^{
            self.waterLevel.frame = rect;
        }];
        NSString *messageString = @"You're at zero consumption";
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nothing more to undo, so get gulping!" message:messageString delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }


}

- (void)loadWaterLevelBeforeDisplay {

    [self checkForZeroGoal];
    CGRect rect = CGRectMake(self.waterLevel.frame.origin.x, (self.waterLevel.frame.origin.y - [self getWaterHeightFromTotalConsumedToday]), self.waterLevel.frame.size.width, [self getWaterHeightFromTotalConsumedToday]);
    self.waterLevel.frame = rect;
}

#pragma mark // DATE CHECK VALIDATION

- (void)logDate {
    NSUserDefaults *userDefaults  = [NSUserDefaults standardUserDefaults];
    NSDate *today = [NSDate new];
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"dd MM yyyy"];
    NSString *todayString = [formatter stringFromDate:today];
    [userDefaults setObject:todayString forKey:kNSUserDefaultsDateCheck];
}

- (void)dateCheck {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDate *today = [NSDate new];
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"dd MM yyyy"];
    NSString *todayStringToCheck = [formatter stringFromDate:today];
    NSString *todayStringFromUserDefaults = [userDefaults objectForKey:kNSUserDefaultsDateCheck];

    NSLog(@"todaystring %@, todaystringfromud %@", todayStringToCheck, todayStringFromUserDefaults);

    if (![todayStringToCheck isEqualToString:todayStringFromUserDefaults]) {
        [userDefaults removeObjectForKey:kNSUserWaterLevelKey];
    }
}

- (float)getWaterHeightFromTotalConsumedToday {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *totalConsumedToday = [userDefaults objectForKey:kNSUserWaterLevelKey];
    return (([totalConsumedToday floatValue] * self.view.frame.size.height) / self.currentDailyGoal);
}

- (void)addWaterLevel:(NSNumber *)amountConsumed {

    [self logDate];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *totalConsumedToday = [userDefaults objectForKey:kNSUserWaterLevelKey];
    totalConsumedToday = [NSNumber numberWithFloat:([totalConsumedToday floatValue] + [amountConsumed floatValue])];
    [userDefaults setObject:totalConsumedToday forKey:kNSUserWaterLevelKey];

    CGRect rect = CGRectMake(self.waterLevel.frame.origin.x, (self.view.frame.size.height - [self getWaterHeightFromTotalConsumedToday]), self.waterLevel.frame.size.width, [self getWaterHeightFromTotalConsumedToday]);

    if ([self getWaterHeightFromTotalConsumedToday] < self.view.frame.size.height) {

        [UIView animateWithDuration:0.5 animations:^{
            self.waterLevel.frame = rect;
        }];

    } else {
        [UIView animateWithDuration:0.5 animations:^{
            self.waterLevel.frame = rect;
        }];
        NSString *messageString = @"You've reached your water intake goal for the day.";
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nice work!" message:messageString delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
        [alert show];
    }
}

#pragma mark // Change Daily Goal Methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"settingsSegue"]) {
        SettingsViewController *sVC = segue.destinationViewController;
        sVC.delegate = self;
    }
}

#pragma mark // Button Animation Methods
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

#pragma mark // Daily Goal Methods

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

@end
