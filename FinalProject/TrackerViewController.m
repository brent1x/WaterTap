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
    self.graphView.alwaysDisplayDots = NO;
    self.graphView.enableReferenceXAxisLines = YES;
    self.graphView.enableReferenceYAxisLines = YES;
    self.graphView.enableReferenceAxisFrame = YES;

    // Draw an average line
    self.graphView.averageLine.enableAverageLine = YES;
    self.graphView.averageLine.alpha = 0.6;
    self.graphView.averageLine.color = [UIColor darkGrayColor];
    self.graphView.averageLine.width = 2.5;
    self.graphView.averageLine.dashPattern = @[@(2),@(2)];

    // Set the graph's animation style to draw, fade, or none
    self.graphView.animationGraphStyle = BEMLineAnimationDraw;

    // Dash the y reference lines
    self.graphView.lineDashPatternForReferenceYAxisLines = @[@(2),@(2)];

    // Show the y axis values with this format string
    self.graphView.formatStringForValues = @"%.1f";

    // Setup initial curve selection segment
    self.graphView.enableBezierCurve = YES;

    [self hydrateDatasets];

    self.delegate = self;

}

//To delete
- (float)getRandomFloat {
    float i1 = (float)(arc4random() % 10000) / 1000 ;
    return i1;
}

#pragma mark - PDTSimpleLineGraphDelegate & DataSource

- (NSInteger)numberOfPointsInLineGraph:(BEMSimpleLineGraphView *)graph {
    return (int)[self.waterIntakeValues count];;
}

- (CGFloat)lineGraph:(BEMSimpleLineGraphView *)graph valueForPointAtIndex:(NSInteger)index {
    return [[self.waterIntakeValues objectAtIndex:index] doubleValue];
}

#pragma mark - PDTSimpleLineGraph Helpers

//- (NSInteger)numberOfGapsBetweenLabelsOnLineGraph:(BEMSimpleLineGraphView *)graph {
//    return 2;
//}

- (void)hydrateDatasets {

    //TODO:Implement monthValues array data

    // Reset the arrays of values (Y-Axis points) and dates (X-Axis points / labels)
    if (!self.waterIntakeValues) self.waterIntakeValues = [[NSMutableArray alloc] init];
    if (!self.dateValues) self.dateValues = [[NSMutableArray alloc] init];
    [self.waterIntakeValues removeAllObjects];
    [self.dateValues removeAllObjects];

    self.totalNumber = 0;
    NSDate *baseDate = [NSDate date];
    BOOL showNullValue = true;

    // Add objects to the array based on the stepper value
    for (int i = 0; i < 9; i++) {
        [self.waterIntakeValues addObject:@([self getRandomFloat])]; // Random values for the graph
        if (i == 0) {
            [self.dateValues addObject:baseDate]; // Dates for the X-Axis of the graph
        } else if (showNullValue && i == 4) {
            [self.dateValues addObject:[self dateForGraphAfterDate:self.dateValues[i-1]]]; // Dates for the X-Axis of the graph
            self.waterIntakeValues[i] = @(BEMNullGraphValue);
        } else {
            [self.dateValues addObject:[self dateForGraphAfterDate:self.dateValues[i-1]]]; // Dates for the X-Axis of the graph
        }

        self.totalNumber = self.totalNumber + [[self.waterIntakeValues objectAtIndex:i] intValue]; // All of the values added together
    }
}

- (void)hydrateDatasetsForMonth {

    // Reset the arrays of values (Y-Axis points) and dates (X-Axis points / labels)
    if (!self.waterIntakeValues) self.waterIntakeValues = [[NSMutableArray alloc] init];
    if (!self.dateValues) self.dateValues = [[NSMutableArray alloc] init];
    [self.waterIntakeValues removeAllObjects];
    [self.dateValues removeAllObjects];





    self.totalNumber = 0;
    NSDate *baseDate = [NSDate date];
    BOOL showNullValue = true;

    // Add objects to the array based on the stepper value
    for (int i = 0; i < 9; i++) {
        [self.waterIntakeValues addObject:@([self getRandomFloat])]; // Random values for the graph
        if (i == 0) {
            [self.dateValues addObject:baseDate]; // Dates for the X-Axis of the graph
        } else if (showNullValue && i == 4) {
            [self.dateValues addObject:[self dateForGraphAfterDate:self.dateValues[i-1]]]; // Dates for the X-Axis of the graph
            self.waterIntakeValues[i] = @(BEMNullGraphValue);
        } else {
            [self.dateValues addObject:[self dateForGraphAfterDate:self.dateValues[i-1]]]; // Dates for the X-Axis of the graph
        }

        self.totalNumber = self.totalNumber + [[self.waterIntakeValues objectAtIndex:i] intValue]; // All of the values added together
    }
}

-(void)getAllWaterIntake:(NSString *)month {

    PFQuery *query = [ConsumptionEvent query];

    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query orderByDescending:@"createdAt"];

    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {


    }];


}

- (NSString *)lineGraph:(BEMSimpleLineGraphView *)graph labelOnXAxisForIndex:(NSInteger)index {

    NSString *label = [self labelForDateAtIndex:index];
    return [label stringByReplacingOccurrencesOfString:@" " withString:@"\n"];
}

//TODO: Call it somehow from super ?
- (NSDate *)dateForGraphAfterDate:(NSDate *)date {
    NSTimeInterval secondsInTwentyFourHours = 24 * 60 * 60;
    NSDate *newDate = [date dateByAddingTimeInterval:secondsInTwentyFourHours];
    return newDate;
}

#pragma mark - PDTSimpleCalendarViewController methods to override

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
    self.navigationItem.title = self.overlayView.text;
    //TODO: Hydrategraph with month values
}

// Override these methods //
//Blank so these dont hide the overlay
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

-(NSDate *)zeroTimeDate:(NSDate *)date {

    unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth| NSCalendarUnitDay;
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:flags fromDate:date];
    NSDate* dateOnly = [calendar dateFromComponents:components];
    
    return dateOnly;
    
}





@end

