//
//  TrackerViewController.m
//  FinalProject
//
//  Created by Nader Neyzi on 6/18/15.
//  Copyright (c) 2015 Brent Dady. All rights reserved.
//

#import "TrackerViewController.h"
#import "PDTSimpleCalendarViewHeader.h"
#import "BEMSimpleLineGraphView.h"
#import "PDTSimpleCalendarViewFlowLayout.h"
#import <Parse/Parse.h>
#import "ConsumptionEvent.h"

@interface TrackerViewController () <BEMSimpleLineGraphDataSource, BEMSimpleLineGraphDelegate, PDTSimpleCalendarViewDelegate>

@property NSMutableArray *waterIntakeValues;
@property NSMutableArray *dateValues;
@property NSMutableArray *goalPrecentageValues;
@property int totalNumber;

@property BEMSimpleLineGraphView *graphView;

@property (nonatomic, strong) NSDateFormatter *headerDateFormatter; //Will be used to format date in header view and on scroll.

@property UILabel *overlayView;

@end

@implementation TrackerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationController.navigationBarHidden = NO;

    //Remove existing constraints made by super
    [self.view removeConstraints:self.view.constraints];

    //Get overlayView
    self.overlayView = [self.view.subviews objectAtIndex:1];
    self.overlayView.alpha = 1;
    self.overlayView.backgroundColor = [UIColor grayColor];
    self.overlayView.text = [self.headerDateFormatter stringFromDate:[NSDate date]];
    self.navigationItem.title = self.overlayView.text;

    //Placeholder view to put behind status bar for it to display
    UIView *placeholderView = [UIView new];
    [self.view addSubview:placeholderView];
    placeholderView.backgroundColor = self.graphView.backgroundColor; //TODO: check color if it looks good
    [placeholderView setTranslatesAutoresizingMaskIntoConstraints:NO];

    //Add graphView that will be the graph
    self.graphView = [[BEMSimpleLineGraphView alloc] initWithFrame:CGRectMake(0, 60, 320, 250)];
    [self.view addSubview:self.graphView];
    [self.graphView setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.graphView.dataSource = self;
    self.graphView.delegate = self;

    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    float graphViewHeight = screenHeight / 2;
    float placeholderViewHeight = 20;

    //Add constraints
    NSDictionary *viewsDictionary = @{@"overlayView": self.overlayView, @"topLayoutGuide": self.topLayoutGuide, @"graphView": self.graphView, @"placeholderView": placeholderView};
    NSDictionary *metricsDictionary = @{@"overlayViewHeight": @(PDTSimpleCalendarFlowLayoutHeaderHeight), @"placeholderViewHeight": @(placeholderViewHeight), @"graphViewHeight": @(graphViewHeight)};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[overlayView]|" options:NSLayoutFormatAlignAllTop metrics:nil views:viewsDictionary]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[placeholderView(==placeholderViewHeight)][overlayView(==overlayViewHeight)][graphView(==graphViewHeight)]" options:0 metrics:metricsDictionary views:viewsDictionary]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[graphView]|" options:0 metrics:nil views:viewsDictionary]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[placeholderView]|" options:0 metrics:nil views:viewsDictionary]];

    //Make collectionViews height dynamic
    [self.collectionView setFrame:CGRectMake(self.collectionView.frame.origin.x, (self.collectionView.frame.origin.y + graphViewHeight + placeholderViewHeight + PDTSimpleCalendarFlowLayoutHeaderHeight), self.collectionView.frame.size.width, (screenHeight - graphViewHeight - placeholderViewHeight - PDTSimpleCalendarFlowLayoutHeaderHeight - 20))];
    self.automaticallyAdjustsScrollViewInsets = NO;


    // Graph Settings //
    // Create a gradient to apply to the bottom portion of the graph
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    CGFloat components[8] = {
        1.0, 1.0, 1.0, 1.0,
        1.0, 1.0, 1.0, 0.0
    };

    // Apply the gradient to the bottom portion of the graph
    self.graphView.gradientBottom = CGGradientCreateWithColorComponents(colorspace, components, locations, num_locations);

    // Enable and disable various graph properties and axis displays
    self.graphView.enableTouchReport = YES;
    self.graphView.enablePopUpReport = YES;
    self.graphView.enableYAxisLabel = YES;
    self.graphView.autoScaleYAxis = YES;
    self.graphView.alwaysDisplayDots = YES;
//    self.graphView.enableReferenceXAxisLines = YES;
//    self.graphView.enableRefe renceYAxisLines = YES;
    self.graphView.enableReferenceAxisFrame = YES;

    // Draw an average line
//    self.graphView.averageLine.enableAverageLine = YES;
//    self.graphView.averageLine.alpha = 0.6;
//    self.graphView.averageLine.color = [UIColor darkGrayColor];
//    self.graphView.averageLine.width = 2.5;
//    self.graphView.averageLine.dashPattern = @[@(2),@(2)];

    // Set the graph's animation style to draw, fade, or none
    self.graphView.animationGraphStyle = BEMLineAnimationDraw;

    // Dash the y reference lines
//    self.graphView.lineDashPatternForReferenceYAxisLines = @[@(2),@(2)];

    // Show the y axis values with this format string
    self.graphView.formatStringForValues = @"%.1f";

    // Setup initial curve selection segment
    self.graphView.enableBezierCurve = YES;

    //Get rid of lines in background
    self.graphView.alphaLine = 1;

    [self hydrateDataSetsForMonth:self.overlayView.text];

    self.delegate = self;

    // Calendar Settings //
//    [self setFirstDateAs6MonthBeforeFirstIntake];


}


//-(NSDate *)setFirstDateAs6MonthBeforeFirstIntake {
//    PFQuery *query = [PFQuery queryWithClassName:@"ConsumptionEvent"];
//    [query fromLocalDatastore];
//    [query orderByAscending:@"consumedAt"];
//    [query findObjectsInBackgroundWithBlock:^(NSArray *events, NSError *error) {
//        if (!error) {
//            if ([events firstObject]) {
//                self.firstDate = [events firstObject];
//                NSLog(@"first date: %@", self.firstDate);
//            } else {
//
//            }
//        } else {
//            // Log details of the failure
//            NSLog(@"Error: %@ %@", error, [error userInfo]);
//        }
//    }];
//    return [NSDate date];
//}


// Graph //

#pragma mark - PDTSimpleLineGraphDelegate & DataSource

- (NSInteger)numberOfPointsInLineGraph:(BEMSimpleLineGraphView *)graph {
    return (int)[self.waterIntakeValues count];;
}

- (CGFloat)lineGraph:(BEMSimpleLineGraphView *)graph valueForPointAtIndex:(NSInteger)index {
    return [[self.waterIntakeValues objectAtIndex:index] doubleValue];
}

#pragma mark - PDTSimpleLineGraph methods to override
- (NSString *)lineGraph:(BEMSimpleLineGraphView *)graph labelOnXAxisForIndex:(NSInteger)index {

    NSString *label = [self labelForDateAtIndex:index];
    return [label stringByReplacingOccurrencesOfString:@" " withString:@"\n"];
}

#pragma mark - PDTSimpleLineGraph Helpers

-(void)hydrateDataSetsForMonth:(NSString *)month {
    //Initialize data arrays and totalNumber
    if (!self.waterIntakeValues) self.waterIntakeValues = [[NSMutableArray alloc] init];
    if (!self.dateValues) self.dateValues = [[NSMutableArray alloc] init];
    if (!self.goalPrecentageValues) self.goalPrecentageValues = [[NSMutableArray alloc] init];
    [self.waterIntakeValues removeAllObjects];
    [self.dateValues removeAllObjects];
    [self.goalPrecentageValues removeAllObjects];
    self.totalNumber = 0;

    //Load dateValues and waterIntakeValues in loadWaterIntakeForADay
    unsigned int comps = NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear;
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDate *dateOfInterest = [NSDate new];
    NSDateComponents* dayComponent = [NSDateComponents new];
    NSInteger amountOfDaysInMonth  = 0;
    //Edge case current month
    if ([month isEqualToString:[self.headerDateFormatter stringFromDate:[NSDate date]]]) {
        dateOfInterest = [NSDate date];
        dayComponent = [calendar components:comps fromDate:dateOfInterest];
        amountOfDaysInMonth = [dayComponent day]; //Last Day
    } else {
        //Get month NSDate from overlayView.text
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"MMMM yyyy"];
        dateOfInterest = [dateFormatter dateFromString:self.navigationItem.title];
        //Get how many days there are in that month from calendar
        NSRange rng = [calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:dateOfInterest];
        amountOfDaysInMonth = rng.length;
        dayComponent = [calendar components:comps fromDate:dateOfInterest];
    }
    for (int i = 1; i <= amountOfDaysInMonth; i++) {
        [dayComponent setDay:i];
        if (i == amountOfDaysInMonth) {
            [self loadWaterIntakeForADay:[calendar dateFromComponents:dayComponent] shouldReloadGraph:YES];
        } else {
            [self loadWaterIntakeForADay:[calendar dateFromComponents:dayComponent] shouldReloadGraph:NO];
        }
    }
}

-(void)loadWaterIntakeForADay:(NSDate *)day shouldReloadGraph:(BOOL)shouldReload{

    [self.dateValues addObject:day];

    NSDate *startDay = [self makeDayStartOfDay:day];
    NSDate *endDay = [self makeDayNextStartOfDay:day];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%@ <= consumedAt) && (consumedAt < %@)", startDay, endDay];

    PFQuery *query = [PFQuery queryWithClassName:@"ConsumptionEvent" predicate:predicate];
    [query fromLocalDatastore];
    [query orderByAscending:@"consumedAt"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *events, NSError *error) {
        if (!error) {
            // Do something with the found objects
            int dayTotal = 0;
            int goal = 0;
            for (ConsumptionEvent *event in events) {
                dayTotal += event.volumeConsumed;
                goal = event.consumptionGoal;
            }
            [self.waterIntakeValues addObject:[NSNumber numberWithInt:dayTotal]];
            self.totalNumber += dayTotal;
//            int goalPrecentage = dayTotal/goal;
//            [self.goalPrecentageValues addObject:[NSNumber numberWithInt:goalPrecentage]];
            if (shouldReload) {
                [self.graphView reloadGraph];
            }
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

-(NSDate *)makeDayNextStartOfDay:(NSDate *)day {
    day = [self zeroTimeDate:day];
    day = [day dateByAddingTimeInterval:60*60*24];
    return day;
}

-(NSDate *)makeDayStartOfDay:(NSDate *)day {

    day = [self zeroTimeDate:day];
    return day;
}

- (NSDate *)dateForGraphBeforeDate:(NSDate *)date {
    NSTimeInterval secondsInTwentyFourHours = -24 * 60 * 60;
    NSDate *newDate = [date dateByAddingTimeInterval:secondsInTwentyFourHours];
    return newDate;
}

// Calendar //

#pragma mark - PDTSimpleCalendar Delegate methods

- (BOOL)simpleCalendarViewController:(PDTSimpleCalendarViewController *)controller shouldUseCustomColorsForDate:(NSDate *)date {
    return YES;
}

- (UIColor *)simpleCalendarViewController:(PDTSimpleCalendarViewController *)controller circleColorForDate:(NSDate *)date {

    for (NSDate *aDate in self.dateValues) {
        if ([date isEqualToDate:[self zeroTimeDate:aDate]]) {
            return [UIColor blueColor];
        }
    }
    return nil;
}

#pragma mark - PDTSimpleCalendarViewController methods to override

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
    if (![self.navigationItem.title isEqualToString:self.overlayView.text]) {
        self.navigationItem.title = self.overlayView.text;
        [self hydrateDataSetsForMonth:self.overlayView.text];
    }
}

//Blank so these dont hide the overlay when not srcolling
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
}

- (NSDateFormatter *)headerDateFormatter;
{
    if (!_headerDateFormatter) {
        _headerDateFormatter = [[NSDateFormatter alloc] init];
        _headerDateFormatter.calendar = self.calendar;
        _headerDateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"yyyy LLLL" options:0 locale:self.calendar.locale];
    }
    return _headerDateFormatter;
}

- (NSString *)labelForDateAtIndex:(NSInteger)index {
    NSDate *date = self.dateValues[index];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"MM/dd";
    NSString *label = [df stringFromDate:date];
    return label;
}

#pragma mark - PDTSimpleCalendarViewController Helper Methods

-(NSDate *)zeroTimeDate:(NSDate *)date {

    unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth| NSCalendarUnitDay;
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:flags fromDate:date];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];
    NSDate* dateOnly = [calendar dateFromComponents:components];
    
    return dateOnly;
}

@end

