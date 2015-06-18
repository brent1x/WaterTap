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
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    localNotification.alertBody = @"Time to drink some water.";
    localNotification.soundName = @"water.aiff";
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];


    UILocalNotification *notificationToLog = [self.notifications lastObject];
    NSLog(@"%@", notificationToLog.fireDate);

    NSLog(@"number: %lu", (unsigned long)self.notifications.count);

    self.notifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
    [self.tableView reloadData];
}

- (void)killAllNotifications {
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.notifications.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellID"];
    UILocalNotification *notification = [self.notifications objectAtIndex:indexPath.row];
    NSLog(@"%lu", (unsigned long)self.notifications.count);
    cell.textLabel.text = [NSString stringWithFormat:@"%@", notification.fireDate.description];
    return cell;
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
