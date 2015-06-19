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

    self.navigationItem.title = @"Create Reminder";

    UIUserNotificationType types = UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];

    self.notifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
    [self.tableView reloadData];
}

- (IBAction)setReminder:(id)sender {

    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = self.datePicker.date;
    localNotification.repeatInterval = NSCalendarUnitDay;
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    localNotification.alertBody = @"Time to drink some water.";
    localNotification.soundName = @"water.aiff";
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];

    //    UILocalNotification *notificationToLog = [self.notifications lastObject];
    //    NSLog(@"set method: %@", notificationToLog.fireDate);

    //    NSLog(@"number: %lu", (unsigned long)self.notifications.count);

    self.notifications = [[UIApplication sharedApplication] scheduledLocalNotifications];

    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.notifications.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellID"];
    UILocalNotification *notification = [self.notifications objectAtIndex:indexPath.row];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"hh:mm a"];
    NSString *stringFromDate = [formatter stringFromDate:notification.fireDate];

    cell.textLabel.text = stringFromDate;
    cell.detailTextLabel.text = @"Every Day";
    return cell;
}

- (IBAction)killAllReminders:(id)sender {
    self.notifications = @[];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

/*
 #pragma mark - Navigation

 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
