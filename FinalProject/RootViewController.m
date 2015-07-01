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
@import AVFoundation;

#define kNSUserWaterLevelKey @"kNSUserWaterLevelKey"
#define kNSUserDailyGoalKey @"kNSUserDailyGoalKey"
#define kNSUserUnitTypeSelected @"kNSUserUnitTypeSelected"
#define kNSUserDefaultsContainerOneSize @"kNSUserDefaultsContainerOneSize"
#define kNSUserDefaultsContainerTwoSize @"kNSUserDefaultsContainerTwoSize"
#define kNSUserDefaultsDateCheck @"kNSUserDefaultsDateCheck"

@interface RootViewController () <SettingsViewControllerDelegate>

//the button pressed to bring up the container buttons
@property (weak, nonatomic) IBOutlet ContainerButton *addWaterButton;
//@property (weak, nonatomic) IBOutlet ContainerButton *menuButton1;
//@property (weak, nonatomic) IBOutlet ContainerButton *menuButton2;
//@property (weak, nonatomic) IBOutlet ContainerButton *menuButton3;

//@property NSMutableArray *menuButtons;

//properties for animation for the button
@property UIDynamicAnimator *animator;
@property BOOL isFannedOut;

//water level properties
@property (weak, nonatomic) IBOutlet UIView *waterLevel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *waterlevelTopConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *blurredBackground;
@property float initialViewHeight;
@property (weak, nonatomic) IBOutlet UILabel *goalExceededLabel;
@property BOOL shouldShowGoalExceededAlert;

//this property is to check if the goal has changed in the settings view controller
@property BOOL didGoalChange;
@end

@implementation RootViewController
{
    CGFloat viewHeight;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self backgroundEffect];

    [self loadGoalFromUserDefaults];
    
    if (self.currentDailyGoal == 0) {
        self.currentDailyGoal = 64;
        [self saveGoalToUserDefaults];
    }

    [self dateCheck];

    self.navigationController.navigationBarHidden = TRUE;

    self.initialViewHeight = CGRectGetHeight(self.view.frame);
//
//    //animation for buttons
//    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
//    [self.addWaterButton addTarget:self action:@selector(toggleFan) forControlEvents:UIControlEventTouchUpInside];
//    self.menuButtons = [NSMutableArray arrayWithObjects:self.menuButton1, self.menuButton2, self.menuButton3, nil];
//    for (ContainerButton *button in self.menuButtons) {
//        button.center = self.addWaterButton.center;
//    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {

  [self.navigationController setNavigationBarHidden:YES animated:YES];

    [self checkIfGoalHasBeenMet];

    [self loadGoalFromUserDefaults];
    [self dateCheck];
    [self setWaterHeightFromTotalConsumedToday];

    [self.navigationController setNavigationBarHidden:YES animated:YES];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dateCheck) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dateCheck) name:UIApplicationWillEnterForegroundNotification object:nil];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    NSString *bottleOneAmount = [userDefaults objectForKey:kNSUserDefaultsContainerOneSize];

    if ([bottleOneAmount intValue] > 0) {
        self.addWaterButton.customAmount = [bottleOneAmount intValue];
    } else {
        self.addWaterButton.customAmount = 8;
    }
//
//    //    self.menuButton1.customAmount = [bottleTwoAmount intValue];
//    self.menuButton2.customAmount = 10;
//    self.menuButton3.customAmount = 10;
//    //    self.menuButton3.customAmount = [bottleOneAmount intValue];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

- (void)viewDidLayoutSubviews {
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    self.shouldShowGoalExceededAlert = NO;
    self.goalExceededLabel.hidden = YES;
}

#pragma mark // Water Level Methods

- (IBAction)onAddWaterButtonTapped:(id)sender {

    ConsumptionEvent *myConsumptionEvent = [ConsumptionEvent new];
    ContainerButton *button = sender;
    myConsumptionEvent.volumeConsumed = button.customAmount;
    myConsumptionEvent.user = [PFUser currentUser];
    myConsumptionEvent.consumptionGoal = self.currentDailyGoal;
    myConsumptionEvent.consumedAt = [NSDate date];
    [myConsumptionEvent pinInBackground];

    //Change the water level by the volume of the consumption event (which is the same as the relevant button's amount property)

    float amountToAdd = myConsumptionEvent.volumeConsumed;
    [self addWaterLevel:[NSNumber numberWithFloat:(amountToAdd)]];
    [self.undoManager registerUndoWithTarget:self selector:@selector(addWaterLevel:) object:[NSNumber numberWithFloat:-1*amountToAdd]];


    //check and switch the state of the animation so the buttons pop back in
//     [self toggleFan];
}

-(float)convertAmountToAddAndReturnWaterConstant:(float)amountConsumed {
    return (-1*(amountConsumed * self.view.frame.size.height)/self.currentDailyGoal);
}

- (void)addWaterLevel:(NSNumber *)amountFloat {

    [self logDate];

    float amountConsumed = [amountFloat floatValue];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *totalConsumedToday = [userDefaults objectForKey:kNSUserWaterLevelKey];
    totalConsumedToday = [NSNumber numberWithFloat:([totalConsumedToday floatValue] + (amountConsumed))];
    [userDefaults setObject:totalConsumedToday forKey:kNSUserWaterLevelKey];


    float waterConstant = [self convertAmountToAddAndReturnWaterConstant:amountConsumed];

    [UIView animateWithDuration:0.5 animations:^{
            self.waterlevelTopConstraint.constant += waterConstant;
        [self.view layoutIfNeeded];

    }];

    self.shouldShowGoalExceededAlert = YES;
    [self checkIfGoalHasBeenMet];

    if ([amountFloat intValue] <= 0) {

        NSNumber *redoAmount = [NSNumber numberWithFloat:([amountFloat intValue] * -1)];
        [self.undoManager registerUndoWithTarget:self selector:@selector(addWaterLevel:) object:redoAmount];
    }

}

- (float)getWaterHeightFromTotalConsumedToday {

    [self loadGoalFromUserDefaults];

//    NSLog(@"loadGoalFromUserDefaults %@", [self loadGoalFromUserDefaults]);
    [self dateCheck];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *totalConsumedToday = [userDefaults objectForKey:kNSUserWaterLevelKey];
    NSLog(@"totalConsumedToday %@", totalConsumedToday);
    return (([totalConsumedToday floatValue] * self.initialViewHeight)/self.currentDailyGoal);

}

- (void)setWaterHeightFromTotalConsumedToday {

    float waterHeight =  [self getWaterHeightFromTotalConsumedToday];
    self.waterlevelTopConstraint.constant = self.initialViewHeight - waterHeight;
    NSLog(@"waterLevelTopConstraint.constant %f", self.waterlevelTopConstraint.constant);
    NSLog(@"initialViewHeight %f", self.initialViewHeight);
    NSLog(@"waterheight %f", waterHeight);
}

- (void)checkIfGoalHasBeenMet {

    [self loadGoalFromUserDefaults];
    [self dateCheck];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *totalConsumedToday = [userDefaults objectForKey:kNSUserWaterLevelKey];

    if ((([totalConsumedToday floatValue]/self.currentDailyGoal) >= 1) && (self.shouldShowGoalExceededAlert)) {

        NSString *messageString = @"You've reached your water intake goal for the day.";
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nice work!" message:messageString delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
        [alert show];
        self.goalExceededLabel.hidden = NO;
    }

    else if (([totalConsumedToday floatValue]/self.currentDailyGoal) >= 1) {
        self.goalExceededLabel.hidden = NO;
    }

    else {
        self.goalExceededLabel.hidden = YES;
    }
}
#pragma mark // Date Check Methods

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

    if (![todayStringToCheck isEqualToString:todayStringFromUserDefaults]) {
       // [userDefaults removeObjectForKey:kNSUserWaterLevelKey];
        // may need to do below command, removeObjectForKey says that it does not reset the value.
        NSNumber *reset = [NSNumber numberWithFloat:0.0];
        [userDefaults setObject:reset forKey:kNSUserWaterLevelKey];
        self.shouldShowGoalExceededAlert = YES;
        self.goalExceededLabel.hidden = YES;
    }
}

#pragma mark // Daily Goal Methods

- (void)dailyGoalChanged:(int)dailyGoalAmount {

    self.currentDailyGoal = dailyGoalAmount;
    [self saveGoalToUserDefaults];
    self.shouldShowGoalExceededAlert = YES;
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

#pragma mark // Segue Method

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"settingsSegue"]) {
        SettingsViewController *sVC = segue.destinationViewController;
        sVC.delegate = self;
        NSLog(@"Delegate is %@", sVC.delegate);
    }
}


#pragma mark // Button Animation Methods
//checks the state of the buttons, whether they are "fanned out" or "fanned in," then switches the state

//- (void)toggleFan {
//
//    [self.animator removeAllBehaviors];
//    if (self.isFannedOut){
//        [self fanIn];
//    }
//    else {
//        [self fanOut];
//    }
//    self.isFannedOut = !self.isFannedOut;
//}
//
//-(void)fanOut {
//    CGPoint point = CGPointMake(self.addWaterButton.frame.origin.x + 100, self.addWaterButton.frame.origin.y - 50);
//    UISnapBehavior *snapBehavior = [[UISnapBehavior alloc] initWithItem:self.menuButton1 snapToPoint:point];
//    [self.animator addBehavior:snapBehavior];
//    point = CGPointMake(self.addWaterButton.frame.origin.x+30, self.addWaterButton.frame.origin.y - 50);
//    snapBehavior = [[UISnapBehavior alloc] initWithItem:self.menuButton2 snapToPoint:point];
//    [self.animator addBehavior:snapBehavior];
//    point = CGPointMake(self.addWaterButton.frame.origin.x - 40, self.addWaterButton.frame.origin.y - 50);
//    snapBehavior = [[UISnapBehavior alloc] initWithItem:self.menuButton3 snapToPoint:point];
//    [self.animator addBehavior:snapBehavior];
//}
//
//- (void)fanIn {
//
//    CGPoint point = self.addWaterButton.center;
//
//    UISnapBehavior *snapBehavior = [[UISnapBehavior alloc] initWithItem:self.menuButton1 snapToPoint:point];
//    [self.animator addBehavior:snapBehavior];
//    snapBehavior = [[UISnapBehavior alloc] initWithItem:self.menuButton2 snapToPoint:point];
//    [self.animator addBehavior:snapBehavior];
//    snapBehavior = [[UISnapBehavior alloc] initWithItem:self.menuButton3 snapToPoint:point];
//    [self.animator addBehavior:snapBehavior];
//}

#pragma mark // Background Effect Method
- (void)backgroundEffect {
    // Initiate the capture sesh
    AVCaptureSession *session = [[AVCaptureSession alloc]init];
    session.sessionPreset = AVCaptureSessionPresetHigh;

    // Check for front-facing cam
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *frontCamera;
    AVCaptureDevice *backCamera;

    for (AVCaptureDevice *device in devices) {
        NSLog(@"Device name: %@", [device localizedName]);
        if ([device hasMediaType:AVMediaTypeVideo]) {
            if ([device position] == AVCaptureDevicePositionBack) {
                NSLog(@"Device position : back");
                backCamera = device;
            } else {
                NSLog(@"Device position : front");
                frontCamera = device;
            }
        }
    }

    NSError *error = nil;

    AVCaptureDeviceInput *frontFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];

    if (!error) {
        if ([session canAddInput:frontFacingCameraDeviceInput]) {
            [session addInput:frontFacingCameraDeviceInput];
            self.blurredBackground.hidden = TRUE;
        } else {
            self.blurredBackground.hidden = FALSE;
        }
    }

    // Output video capture
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [session addOutput:output];

    // Map video capture to preview
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    UIView *myView = self.view;
    previewLayer.frame = myView.bounds;
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:previewLayer];

    // Kick off capture session
    [session startRunning];
}

@end
