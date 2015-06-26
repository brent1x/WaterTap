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

@property NSMutableArray *waterIntakeValuesBackup;
@property NSMutableArray *dateValuesBackup;
@property NSMutableArray *goalPrecentageValuesBackup;
@property int totalNumber;

@property BEMSimpleLineGraphView *graphView;

@property (nonatomic, strong) NSDateFormatter *headerDateFormatter; //Will be used to format date in header view and on scroll.

@property UILabel *overlayView;

@property NSMutableArray *sectionHeaderViewsDisplayed;

@end

@implementation TrackerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Calendar Settings //

    [[PDTSimpleCalendarViewCell appearance] setTextTodayColor:[UIColor blueColor]];//BG color

    self.lastDate = [NSDate date];
    self.firstDate = [self.lastDate dateByAddingTimeInterval:-(15778454)]; //seconds in 6 months

    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 40, 0);//Extra space on bottom because it wouldn't scroll all the way down and the navigation title wouldn't change for current month




//    [self.collectionView setPagingEnabled:YES];

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

-(void)viewWillAppear:(BOOL)animated{
    self.sectionHeaderViewsDisplayed = [NSMutableArray new];

    [self.collectionView setContentOffset:CGPointMake(self.collectionView.frame.origin.x, self.collectionView.frame.origin.y + 667)];
}

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
                self.waterIntakeValuesBackup = [NSMutableArray arrayWithArray:self.waterIntakeValues];
                self.dateValuesBackup = [NSMutableArray arrayWithArray:self.dateValues];
                self.goalPrecentageValuesBackup = [NSMutableArray arrayWithArray:self.goalPrecentageValues];
                [self.waterIntakeValues removeAllObjects];
                [self.dateValues removeAllObjects];
                [self.goalPrecentageValues removeAllObjects];
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











//[self numberOfSectionsInCollectionView:self.collectionView] - 1;




// Calendar //

#pragma mark - PDTSimpleCalendar Delegate methods

- (BOOL)simpleCalendarViewController:(PDTSimpleCalendarViewController *)controller shouldUseCustomColorsForDate:(NSDate *)date {
    return YES;
}

#pragma mark - PDTSimpleCalendarViewController methods to override

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{

    [super scrollViewDidScroll:scrollView];
    if (![self.navigationItem.title isEqualToString:self.overlayView.text]) {
        self.navigationItem.title = self.overlayView.text;
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self hydrateDataSetsForMonth:self.overlayView.text];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
//    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
//    UICollectionViewLayoutAttributes *attributes = [self.collectionView layoutAttributesForSupplementaryElementOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];
//    CGRect rect = [attributes frame];




//    [scrollView setContentOffset:CGPointMake(0, self.sectionHeaderViewDisplayed.frame.origin.y) animated:YES];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
}

-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {


    PDTSimpleCalendarViewHeader *collectionHeaderView = (PDTSimpleCalendarViewHeader *)[super collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];

    if (collectionHeaderView) {
//        self.sectionHeaderViewDisplayed = collectionHeaderView;
        NSLog(@"collectionHeaderView: %@", collectionHeaderView.titleLabel.text);
    }
    return collectionHeaderView;
}

//-(void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
//
//    if (elementKind == UICollectionElementKindSectionHeader) {
//        UICollectionReusableView *collectionHeaderView = [self.collectionView dequeueReusableCellWithReuseIdentifier:UICollectionElementKindSectionHeader forIndexPath:indexPath];
////        [self.sectionHeaderViewsWithIndexPaths removeObjectForKey:indexPath];
//    }
//
//}

























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

    NSArray *subviews = [cell subviews];
    if (subviews.count > 1) {
        UIView *viewToKeep = [[cell subviews] objectAtIndex:(subviews.count - 4)];
        for (UIView *view in subviews) {
            if (![view isEqual:viewToKeep]) {
                [view removeFromSuperview];
            }
        }
    }

    if ([self.dateValuesBackup containsObject:date] && self.waterIntakeValuesBackup.count == self.dateValuesBackup.count && [[self.waterIntakeValuesBackup objectAtIndex:[self.dateValuesBackup indexOfObject:date]] integerValue] > 0) {

        //Static backgroundRectangle
        UIView *backgroundRectangle = [[UILabel alloc]initWithFrame:cell.dayLabel.frame];

        backgroundRectangle.backgroundColor = [UIColor colorWithRed:0.49 green:0.81 blue:0.95 alpha:1];
        backgroundRectangle.layer.borderColor = [UIColor blackColor].CGColor;
        backgroundRectangle.layer.borderWidth = 1;

        [cell bringSubviewToFront:cell.dayLabel];
        [cell insertSubview:backgroundRectangle belowSubview:cell.dayLabel];
        [cell sendSubviewToBack:backgroundRectangle];

        //Dynamic frame for cover based on waterIntake and goal for that date   
        CGRect coverFrame = backgroundRectangle.frame;
        float proportion = [[self.goalPrecentageValuesBackup objectAtIndex:[self.dateValuesBackup indexOfObject:date]] floatValue];
        coverFrame.size.height = backgroundRectangle.frame.size.height * proportion;

        UIView *coverRectangle = [[UILabel alloc] initWithFrame:coverFrame];
        coverRectangle.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1];

        UIView *topBorder = [UIView new];
        topBorder.backgroundColor = [UIColor blackColor];
        topBorder.frame = CGRectMake(backgroundRectangle.frame.origin.x, backgroundRectangle.frame.origin.y, coverRectangle.frame.size.width, 1.0f);
        [cell addSubview:topBorder];

        UIView *leftBorder = [UIView new];
        leftBorder.backgroundColor = [UIColor blackColor];
        leftBorder.frame = CGRectMake(backgroundRectangle.frame.origin.x, backgroundRectangle.frame.origin.y, 1.0f, backgroundRectangle.frame.size.height);
        [cell addSubview:leftBorder];

        UIView *rightBorder = [UIView new];
        rightBorder.backgroundColor = [UIColor blackColor];
        rightBorder.frame = CGRectMake(backgroundRectangle.frame.origin.x +backgroundRectangle.frame.size.width - 1.0f, backgroundRectangle.frame.origin.y, 1.0f, backgroundRectangle.frame.size.height);
        [cell addSubview:rightBorder];

        cell.dayLabel.backgroundColor = [UIColor clearColor];

        [cell sendSubviewToBack:backgroundRectangle];
         [cell insertSubview:coverRectangle aboveSubview:backgroundRectangle];
        [cell bringSubviewToFront:cell.dayLabel];

    }
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

