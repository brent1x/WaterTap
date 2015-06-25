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
#import "PDTSimpleCalendarViewCell.h"

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

    // Calendar Settings //

    [[PDTSimpleCalendarViewCell appearance] setTextTodayColor:[UIColor blueColor]];//BG color

    self.lastDate = [NSDate date];
    self.firstDate = [self.lastDate dateByAddingTimeInterval:-(15778454)]; //seconds in 6 months

    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 40, 0);//Extra space on bottom because it wouldn't scroll all the way down and the navigation title wouldn't change for current month

    // View Settings //

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
    float graphViewHeight = screenHeight / 2.5;
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

}


//-(void)viewWillAppear:(BOOL)animated {
//    CGPoint bottomOffset = CGPointMake(0, self.collectionView.contentSize.height - self.collectionView.bounds.size.height);
//    [self.collectionView setContentOffset:bottomOffset animated:YES];
//
//
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

    //    NSString *label = [self labelForDateAtIndex:index];
    NSString *label = @"";
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

    NSDate *startDay = [self makeDayStartOfDay:day];
    [self.dateValues addObject:[self makeDayStartOfDay:day]];
    NSDate *endDay = [self makeDayNextStartOfDay:day];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%@ <= consumedAt) && (consumedAt < %@)", startDay, endDay];

    PFQuery *query = [PFQuery queryWithClassName:@"ConsumptionEvent" predicate:predicate];
    [query fromLocalDatastore];
    [query orderByAscending:@"consumedAt"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *events, NSError *error) {
        if (!error) {
            // Do something with the found objects
            float dayTotal = 0;
            float goal = 0;
            for (ConsumptionEvent *event in events) {
                dayTotal += (float)event.volumeConsumed;
                goal = (float)event.consumptionGoal;
                NSLog(@"GOAL: %d", event.consumptionGoal);
            }
            [self.waterIntakeValues addObject:[NSNumber numberWithFloat:dayTotal]];
            self.totalNumber += (int)dayTotal;
            float goalPrecentage = 0;
            if (dayTotal != 0 && goal != 0) {
                goalPrecentage = dayTotal/goal;
            }
            [self.goalPrecentageValues addObject:[NSNumber numberWithFloat:goalPrecentage]];
            if (shouldReload) {
                [self.graphView reloadGraph];
                [self.collectionView reloadData];
                [self.waterIntakeValues removeAllObjects];
                [self.dateValues removeAllObjects];
                [self.goalPrecentageValues removeAllObjects];
            }
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];


    //TEST
    //    [self.waterIntakeValues addObject:[NSNumber numberWithFloat:[self getRandomFloat]]];
    //    [self.goalPrecentageValues addObject:[NSNumber numberWithFloat:10000]];
    //    if (shouldReload) {
    //        [self.graphView reloadGraph];
    //        [self.collectionView reloadData];
    //    }
}

- (float)getRandomFloat {
    float i1 = (float)(arc4random() % 1000000) / 100 ;
    return i1;
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

//- (UIColor *)simpleCalendarViewController:(PDTSimpleCalendarViewController *)controller circleColorForDate:(NSDate *)date {
//
////    if ([self.dateValues containsObject:date] && self.waterIntakeValues.count == self.dateValues.count && [[self.waterIntakeValues objectAtIndex:[self.dateValues indexOfObject:date]] integerValue] > 0) {
//////        NSLog(@"DATE: %@", date);
//////        NSLog(@"dateValues: %@", self.dateValues);
//////        NSLog(@"waterIntakeValues: %@", self.waterIntakeValues);
//////        NSLog(@"Index: %lu", (unsigned long)[self.dateValues indexOfObject:date]);
//////        NSLog(@"waterIntake: %@", [self.waterIntakeValues objectAtIndex:[self.dateValues indexOfObject:date]]);
////        return [UIColor clearColor];
////    }
//    return [UIColor blueColor];
//
//}

#pragma mark - PDTSimpleCalendarViewController methods to override

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (![self.navigationItem.title isEqualToString:self.overlayView.text]) {
        self.navigationItem.title = self.overlayView.text;
    }

}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

    [self hydrateDataSetsForMonth:self.overlayView.text];


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

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PDTSimpleCalendarViewCell *cell = (PDTSimpleCalendarViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];

    NSDate *date = [self dateForCellAtIndexPath:indexPath];

    //Anders added >>>>

    UIView *customRectangle = [[UILabel alloc]initWithFrame:cell.dayLabel.frame];
    customRectangle.backgroundColor = [UIColor magentaColor];
    customRectangle.layer.borderColor = [UIColor blackColor].CGColor;
    customRectangle.layer.borderWidth = 1;

    //    customRectangle.layer.cornerRadius = 16;
    //just to eliminate white spots
    //cell.dayLabel.layer.cornerRadius += 2;

    [cell bringSubviewToFront:cell.dayLabel];
    [cell insertSubview:customRectangle belowSubview:cell.dayLabel];
    [cell sendSubviewToBack:customRectangle];


    CGRect newFrameForSecondRectangle = customRectangle.frame;
    //    newFrameForSecondRectangle.origin.y = customRectangle.frame.origin.y/2;
    newFrameForSecondRectangle.size.height = customRectangle.frame.size.height /2;

    UIView *secondCustomRectangle = [[UILabel alloc] initWithFrame:newFrameForSecondRectangle];
    secondCustomRectangle.backgroundColor = [UIColor whiteColor];
    //    secondCustomRectangle.layer.cornerRadius = 16;
    //    secondCustomRectangle.layer.borderColor = [UIColor blackColor].CGColor;
    //    secondCustomRectangle.layer.borderWidth = 1;

    CALayer *upperBorder = [CALayer layer];
    upperBorder.backgroundColor = [[UIColor blackColor] CGColor];
    upperBorder.frame = CGRectMake(0, 0, secondCustomRectangle.frame.size.width, 1.0f);
    [secondCustomRectangle.layer addSublayer:upperBorder];


    // [cell bringSubviewToFront:cell.dayLabel];
    //    cell.dayLabel.alpha = 0.7;
    cell.dayLabel.backgroundColor = [UIColor clearColor];
    [cell insertSubview:secondCustomRectangle aboveSubview:customRectangle];
    [cell sendSubviewToBack:customRectangle];
    [cell bringSubviewToFront:cell.dayLabel];
    //<<<<<<

    if ([self.dateValues containsObject:date] && self.waterIntakeValues.count == self.dateValues.count && [[self.waterIntakeValues objectAtIndex:[self.dateValues indexOfObject:date]] integerValue] > 0) {
        //        cell.dayLabel.backgroundColor = [UIColor blueColor];

        //        cell.dayLabel.layer.masksToBounds = NO;


        //        UIView *customCircle = [[UILabel alloc]initWithFrame:cell.dayLabel.frame];
        //        customCircle.backgroundColor = [UIColor magentaColor];
        //        customCircle.layer.cornerRadius = 16;
        //
        //        [cell bringSubviewToFront:cell.dayLabel];
        //
        //


        // /[cell insertSubview:customCircle belowSubview:cell.dayLabel];

        //        UILabel *rectangleCover = [[UILabel alloc]initWithFrame:cell.dayLabel.frame];
        //        rectangleCover.backgroundColor = [UIColor clearColor];
        //        rectangleCover.frame = CGRectMake(rectangleCover.frame.origin.x, rectangleCover.frame.origin.y, 32, 16);
        //        [cell insertSubview:rectangleCover belowSubview:cell.dayLabel];



        //        //// Bezier Drawing
        //        UIBezierPath* bezierPath = UIBezierPath.bezierPath;
        //        [bezierPath moveToPoint: CGPointMake(45, 82.5)];
        //        [bezierPath addCurveToPoint: CGPointMake(24.5, 62) controlPoint1: CGPointMake(45, 71.18) controlPoint2: CGPointMake(35.82, 62)];
        //        [bezierPath addCurveToPoint: CGPointMake(4, 82.5) controlPoint1: CGPointMake(13.18, 62) controlPoint2: CGPointMake(4, 71.18)];
        //        [bezierPath addCurveToPoint: CGPointMake(4.01, 83) controlPoint1: CGPointMake(4, 82.67) controlPoint2: CGPointMake(4, 82.83)];
        //        [bezierPath addLineToPoint: CGPointMake(44.99, 83)];
        //        [bezierPath addCurveToPoint: CGPointMake(45, 82.5) controlPoint1: CGPointMake(45, 82.83) controlPoint2: CGPointMake(45, 82.67)];
        //        [bezierPath closePath];
        //        [UIColor.grayColor setFill];
        //        [bezierPath fill];
        //
        //
        //        //// Bezier 2 Drawing
        //        UIBezierPath* bezier2Path = UIBezierPath.bezierPath;
        //        [bezier2Path moveToPoint: CGPointMake(99, 78.76)];
        //        [bezier2Path addCurveToPoint: CGPointMake(81.5, 62) controlPoint1: CGPointMake(99, 69.5) controlPoint2: CGPointMake(91.16, 62)];
        //        [bezier2Path addCurveToPoint: CGPointMake(71.66, 64.9) controlPoint1: CGPointMake(77.85, 62) controlPoint2: CGPointMake(74.46, 63.07)];
        //        [bezier2Path addCurveToPoint: CGPointMake(64, 78.76) controlPoint1: CGPointMake(67.03, 67.92) controlPoint2: CGPointMake(64, 73)];
        //        [bezier2Path addCurveToPoint: CGPointMake(64.87, 84) controlPoint1: CGPointMake(64, 80.59) controlPoint2: CGPointMake(64.31, 82.35)];
        //        [bezier2Path addLineToPoint: CGPointMake(98.13, 84)];
        //        [bezier2Path addCurveToPoint: CGPointMake(99, 78.76) controlPoint1: CGPointMake(98.69, 82.35) controlPoint2: CGPointMake(99, 80.59)];
        //        [bezier2Path closePath];
        //        [UIColor.grayColor setFill];
        //        [bezier2Path fill];

    }



    //    UILabel *customCircle = [[UILabel alloc]initWithFrame:cell.bounds];
    //    customCircle.bounds = CGRectMake(customCircle.bounds.origin.x, customCircle.bounds.origin.y, 32, 32);
    //    customCircle.layer.cornerRadius = 16;
    //    customCircle.layer.masksToBounds = YES;
    //    customCircle.backgroundColor = [UIColor magentaColor];
    //    [cell addSubview:customCircle];
    //    [cell sendSubviewToBack:customCircle];
    //

    //
    //    if ([self.dateValues containsObject:date] && self.goalPrecentageValues.count == self.dateValues.count && [[self.goalPrecentageValues objectAtIndex:[self.dateValues indexOfObject:date]] floatValue] > 0) {
    //
    //        float goalPrecentage = [[self.goalPrecentageValues objectAtIndex:[self.dateValues indexOfObject:date]] floatValue];
    //
    //        float yValue = 32;
    //        if (goalPrecentage > 0) {
    //            yValue = (32 * goalPrecentage) / 100;
    //        }
    //
    ////        NSLog(@"yvalue: %f", yValue);
    //
    //        UILabel *rectangleCover = [[UILabel alloc]initWithFrame:cell.bounds];
    //        rectangleCover.backgroundColor = [UIColor blackColor];
    //        rectangleCover.frame = CGRectMake(rectangleCover.bounds.origin.x, rectangleCover.bounds.origin.y, 32, 32);
    //        rectangleCover.layer.masksToBounds = YES;
    //        [cell insertSubview:rectangleCover aboveSubview:customCircle];
    //        //        rectangleCover.center = cell.center;
    //        //        [cell addSubview:rectangleCover];
    //        //        [cell bringSubviewToFront:rectangleCover];
    ////            [cell sendSubviewToBack:rectangleCover];
    //    }

    return cell;
}

- (NSDate *)dateForCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSDate *firstOfMonth = [self firstOfMonthForSection:indexPath.section];
    NSInteger ordinalityOfFirstDay = [self.calendar ordinalityOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitWeekOfYear forDate:firstOfMonth];
    NSDateComponents *dateComponents = [NSDateComponents new];
    dateComponents.day = (1 - ordinalityOfFirstDay) + indexPath.item;

    return [self.calendar dateByAddingComponents:dateComponents toDate:firstOfMonth options:0];
}

- (NSDate *)firstOfMonthForSection:(NSInteger)section
{
    NSDateComponents *offset = [NSDateComponents new];
    offset.month = section;

    return [self.calendar dateByAddingComponents:offset toDate:self.firstDateMonth options:0];
}

- (NSDate *)firstDateMonth
{
    NSDateComponents *components = [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay
                                                    fromDate:self.firstDate];
    components.day = 1;

    return [self.calendar dateFromComponents:components];
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

