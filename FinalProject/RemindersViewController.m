//
//  RemindersViewController.m
//  FinalProject
//
//  Created by Brent Dady on 6/18/15.
//  Copyright (c) 2015 Brent Dady. All rights reserved.
//

#import "RemindersViewController.h"

@interface RemindersViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property NSArray *notifications;

@end

@implementation RemindersViewController

- (void)viewDidLoad {
    [super viewDidLoad];


    self.navigationController.navigationBarHidden = NO;

    self.navigationItem.title = @"Reminders";

    UIColor *myGrayColor = [UIColor colorWithRed:232.0/255.0 green:241.0/255.0 blue:242.0/255.0 alpha:1];
    UIColor *myBlueColor = [UIColor colorWithRed:27.0/255.0 green:152.0/255.0 blue:224.0/255.0 alpha:1];

    self.datePicker.backgroundColor = [UIColor whiteColor];
    [self.datePicker setValue:myBlueColor forKeyPath:@"textColor"];

    self.view.backgroundColor = myGrayColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Clear All" style:UIBarButtonItemStylePlain target:self action:@selector(killAllReminders:)];

    UIUserNotificationType types = UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];

    self.notifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    UIColor *myBlueColor = [UIColor colorWithRed:27.0/255.0 green:152.0/255.0 blue:224.0/255.0 alpha:1];
    [self.datePicker setValue:myBlueColor forKeyPath:@"textColor"];
}

- (IBAction)setReminder:(id)sender {

    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = self.datePicker.date;
    localNotification.repeatInterval = NSCalendarUnitDay;
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    localNotification.alertBody = @"Time to drink some water.";
    localNotification.soundName = @"water.aiff";
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self hax];
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.notifications.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellID"];
    UILocalNotification *notification = [self.notifications objectAtIndex:indexPath.row];
    UIColor *myDarkBlueColor = [UIColor colorWithRed:19.0/255.0 green:41.0/255.0 blue:61.0/255.0 alpha:1];
    cell.textLabel.textColor = myDarkBlueColor;
    cell.detailTextLabel.textColor = myDarkBlueColor;

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"hh:mm a"];
    NSString *stringFromDate = [formatter stringFromDate:notification.fireDate];

    cell.textLabel.text = stringFromDate;
    cell.detailTextLabel.text = @"Every Day";
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        UILocalNotification *notif = [[[UIApplication sharedApplication] scheduledLocalNotifications] objectAtIndex:indexPath.row];
        [[UIApplication sharedApplication] cancelLocalNotification:notif];
        [self hax];
    }
}

- (void)hax {
    self.notifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
    [self.tableView reloadData];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Delete";
}

- (void)killAllReminders:(id)sender {
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self hax];
    });
}

@end
