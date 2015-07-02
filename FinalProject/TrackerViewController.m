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

#define kNSUserUnitTypeSelected @"kNSUserUnitTypeSelected"

@interface TrackerViewController () <BEMSimpleLineGraphDataSource, BEMSimpleLineGraphDelegate, PDTSimpleCalendarViewDelegate>

@property NSMutableArray *waterIntakeValues;
@property NSMutableArray *dateValues;

@property int totalNumber;

@property NSMutableDictionary *waterHeightProportionsForDays;

@property BEMSimpleLineGraphView *graphView;

@property (nonatomic, strong) NSDateFormatter *headerDateFormatter; //Will be used to format date in header view and on scroll.

@property UILabel *overlayView;

@property UIColor *cellColor;
@property UIColor *cellTextColor;
@property UIColor *waterFillColor;
@property UIColor *waterFillTextColor;
@property UIColor *cellCoverColor;
@property UIColor *cellBorderColor;

@end

@implementation TrackerViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    // View Settings //

    UIColor *myGrayColor = [UIColor colorWithRed:232.0/255.0 green:241.0/255.0 blue:242.0/255.0 alpha:1];
    UIView *hugePlaceholder = [[UIView alloc]initWithFrame:[[UIScreen mainScreen] bounds]];
    hugePlaceholder.backgroundColor = myGrayColor;
    [self.view insertSubview:hugePlaceholder belowSubview:self.collectionView];

//  [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBarHidden = NO;

    //Remove existing constraints made by super
    [self.view removeConstraints:self.view.constraints];

    //Get overlayView
    self.overlayView = [self.view.subviews objectAtIndex:2];
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
//    float placeholderViewHeight = 0;
    float graphViewHeight = (screenHeight / 4);

    //Add constraints
    NSDictionary *viewsDictionary = @{@"overlayView": self.overlayView, @"topLayoutGuide": self.topLayoutGuide, @"graphView": self.graphView, @"placeholderView": placeholderView, @"navigationBar": self.navigationController.navigationBar};
    NSDictionary *metricsDictionary = @{@"overlayViewHeight": @(PDTSimpleCalendarFlowLayoutHeaderHeight), @"graphViewHeight": @(graphViewHeight)};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[overlayView]|" options:NSLayoutFormatAlignAllTop metrics:nil views:viewsDictionary]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[overlayView(==overlayViewHeight)][graphView(==graphViewHeight)]" options:0 metrics:metricsDictionary views:viewsDictionary]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[graphView]|" options:0 metrics:nil views:viewsDictionary]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[placeholderView]|" options:0 metrics:nil views:viewsDictionary]];

    //Add placeholder view behind GraphView
//    UIView *placeholderForGraph = [[UIView alloc] initWithFrame:self.graphView.frame];
//    placeholderForGraph.backgroundColor = [UIColor magentaColor];
//    [self.graphView addSubview:placeholderForGraph];
//    [self.graphView bringSubviewToFront:self.graphView];
//    [self.graphView sendSubviewToBack:placeholderForGraph];
//    [self.graphView sendSubviewToBack:placeholderForGraph];
//    [self.graphView sendSubviewToBack:placeholderForGraph];

    //Make collectionViews height dynamic
    [self.collectionView setFrame:CGRectMake(self.collectionView.frame.origin.x, (self.collectionView.frame.origin.y + graphViewHeight), self.collectionView.frame.size.width, (screenHeight - graphViewHeight - 20))];
    self.automaticallyAdjustsScrollViewInsets = NO;


    // Graph Settings //
    // Create a gradient to apply to the bottom portion of the graph
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.5,1.0 };
//    CGFloat components[8] = {
//        1.0, 1.0, 1.0, 1.0,
//        1.0, 1.0, 1.0, 0.0
//    };
    CGFloat components[8] = {
        27./255., 152./255., 224./255., 1.0,
        27./255., 152./255., 224./255., 0.0
    };

    // Apply the gradient to the bottom portion of the graph
    self.graphView.gradientBottom = CGGradientCreateWithColorComponents(colorspace, components, locations, num_locations);

    // Enable and disable various graph properties and axis displays
    self.graphView.enableTouchReport = YES;
    self.graphView.enablePopUpReport = YES;
//    self.graphView.enableYAxisLabel = YES;
//    self.graphView.autoScaleYAxis = YES;
//    self.graphView.alwaysDisplayDots = YES;
    //    self.graphView.enableReferenceXAxisLines = YES;
    //    self.graphView.enableRefe renceYAxisLines = YES;
//    self.graphView.enableReferenceAxisFrame = YES;

    // Draw an average line
    //    self.graphView.averageLine.enableAverageLine = YES;
    //    self.graphView.averageLine.alpha = 0.6;
    //    self.graphView.averageLine.color = [UIColor darkGrayColor];
    //    self.graphView.averageLine.width = 2.5;
    //    self.graphView.averageLine.dashPattern = @[@(2),@(2)];

    // Set the graph's animation style to draw, fade, or none
    self.graphView.animationGraphStyle = BEMLineAnimationDraw;
    self.graphView.widthLine = 3.;

    // Dash the y reference lines
    //    self.graphView.lineDashPatternForReferenceYAxisLines = @[@(2),@(2)];

    // Show the y axis values with this format string
    self.graphView.formatStringForValues = @"%.1f";

    // Setup initial curve selection segment
    self.graphView.enableBezierCurve = YES;

    //Get rid of lines in background
    self.graphView.alphaLine = 1;

    [self hydrateDataSetsForMonth:self.overlayView.text];

    // Calendar Settings //

    [[PDTSimpleCalendarViewCell appearance] setTextTodayColor:[UIColor blueColor]];//BG color

    self.lastDate = [NSDate date];
    self.firstDate = [self.lastDate dateByAddingTimeInterval:-(15778454)]; //- seconds for 6 months

    PFQuery *query = [PFQuery queryWithClassName:@"ConsumptionEvent"];
    [query fromLocalDatastore];
    [query orderByDescending:@"consumedAt"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *events, NSError *error) {
        if (!error) {
            if ([events firstObject] && [events firstObject] < self.firstDate) {
                self.firstDate = [events firstObject];
                [self.collectionView reloadData];
            }
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];

    if(screenHeight < 667) {
         self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 110, 0);//Extra space on bottom because it wouldn't scroll all the way down and the navigation title wouldn't change for current month
    } else {
         self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 130, 0);//Extra space on bottom because it wouldn't scroll all the way down and the navigation title wouldn't change for current month
    }

    self.delegate = self;

    // Colors //
    UIColor *myBlueColor = [UIColor colorWithRed:27.0/255.0 green:152.0/255.0 blue:224.0/255.0 alpha:1];
    UIColor *myDarkBlueColor = [UIColor colorWithRed:19./255. green:41./255. blue:61./255. alpha:1];
    // UIColor *myMediumBlueColor = [UIColor colorWithRed:0 green:100./255. blue:148./255. alpha:.5];
    self.collectionView.backgroundColor = [UIColor colorWithRed:27./255. green:152./255. blue:224./255. alpha:1.0]; //Calendar
    self.collectionView.backgroundColor = myGrayColor; //Calendar
    self.cellColor = myGrayColor;
    self.graphView.colorLine = myBlueColor;
    self.graphView.colorBottom = myGrayColor;
    self.graphView.colorTop = myGrayColor;
    self.cellTextColor = myBlueColor;
    self.waterFillColor = myBlueColor;
    self.waterFillTextColor = myDarkBlueColor;
    self.cellCoverColor = myGrayColor;
    self.cellBorderColor = myBlueColor;

    //Load all events to a dictionary key:day value:amountConsumed/goal
    self.waterHeightProportionsForDays = [NSMutableDictionary new];
    PFQuery *query2 = [PFQuery queryWithClassName:@"ConsumptionEvent"];
    [query2 fromLocalDatastore];
    [query2 orderByDescending:@"consumedAt"];
    [query2 findObjectsInBackgroundWithBlock:^(NSArray *events, NSError *error) {
        if (!error && events.count > 0) {
            ConsumptionEvent *firstEvent = [events firstObject];
            NSDate *previousEventDate = firstEvent.consumedAt;
            previousEventDate = [self zeroTimeDate:previousEventDate];
            int goal = firstEvent.consumptionGoal;
            NSNumber *proportion = [NSNumber numberWithFloat:((float)firstEvent.volumeConsumed / (float)goal)];
            [self.waterHeightProportionsForDays setObject:proportion forKey:previousEventDate];
            for (ConsumptionEvent *event in events) {
                if (event != [events firstObject]) {
                    NSDate *currentEventDate = event.consumedAt;
                    currentEventDate = [self zeroTimeDate:currentEventDate];
                    if (currentEventDate == previousEventDate) {
                        float singularProportion = (float)event.volumeConsumed / (float)goal;
                        proportion = [self.waterHeightProportionsForDays objectForKeyedSubscript:currentEventDate];
                        proportion = [NSNumber numberWithFloat:[proportion floatValue] + singularProportion];
                        [self.waterHeightProportionsForDays setObject:proportion forKey:currentEventDate];
                    } else {
                        goal = event.consumptionGoal;
                        proportion = [NSNumber numberWithFloat:((float)event.volumeConsumed / (float)goal)];
                        [self.waterHeightProportionsForDays setObject:proportion forKey:currentEventDate];
                        previousEventDate = event.consumedAt;
                    }
                }
            }
//            //For display Demo purposes
//            for (int i = 0; i < 200; i++) {
//                NSTimeInterval timeInterval = (60*60*24) * arc4random_uniform(30*6);
//                NSDate *randomDate = [[NSDate alloc]initWithTimeInterval:-timeInterval sinceDate:firstEvent.consumedAt];
//                randomDate = [self zeroTimeDate:randomDate];
//                if (![self.waterHeightProportionsForDays objectForKey:randomDate]) {
//                    NSNumber *proportion = [NSNumber numberWithFloat:arc4random_uniform(101) / 100.0];
//                    [self.waterHeightProportionsForDays setObject:proportion forKey:randomDate];
//                }
//            }
            [self.collectionView reloadData];
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];

}

- (float)getRandomFloat {
    float i1 = (float)(arc4random() % 1000000) / 100 ;
    return i1;
}

-(void)viewWillAppear:(BOOL)animated{


//    NSInteger section = [self numberOfSectionsInCollectionView:self.collectionView] - 1;
//    NSInteger item = [self collectionView:self.collectionView numberOfItemsInSection:section] - 1;
//    NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:item inSection:section];
//    UICollectionViewLayoutAttributes *attributes = [self.collectionView layoutAttributesForItemAtIndexPath:lastIndexPath];
//    CGRect rect = [attributes frame];
//    [self.collectionView setContentOffset:CGPointMake(self.collectionView.frame.origin.x, rect.origin.y)];
//
//    self.navigationController.navigationBarHidden = YES;
//    [self.navigationController setNavigationBarHidden:NO animated:YES];


    NSInteger section = [self numberOfSectionsInCollectionView:self.collectionView] - 1;
    NSInteger item = [self collectionView:self.collectionView numberOfItemsInSection:section] - 1;
    NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:item inSection:section];
    [self.collectionView scrollToItemAtIndexPath:lastIndexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];

//    NSLog(@"graphView datevaluesbackup: %@", self.dateValuesBackup);
//    NSLog(@"graphView datevalues: %@", self.dateValues);
//    NSLog(@"graphView waterIntakeValuesbackup: %@", self.waterIntakeValuesBackup);
//    NSLog(@"graphView waterIntakeValues: %@", self.waterIntakeValues);

//    NSLog(@"dictionary: %@" , self.waterHeightProportionsForDays);

}

-(void)viewDidAppear:(BOOL)animated {
    self.navigationItem.title = [self.headerDateFormatter stringFromDate:[NSDate date]]; //Fixes initial title mismatch
    [self performSelector:@selector(changeGraphAnimationStyle) withObject:nil afterDelay:1.5];
}

-(void)changeGraphAnimationStyle{
    self.graphView.animationGraphStyle = BEMLineAnimationExpand;
}

//////////// Graph ////////////

#pragma mark - PDTSimpleLineGraphDelegate & DataSource

- (NSInteger)numberOfPointsInLineGraph:(BEMSimpleLineGraphView *)graph {
    return (int)[self.waterIntakeValues count];;
}

- (CGFloat)lineGraph:(BEMSimpleLineGraphView *)graph valueForPointAtIndex:(NSInteger)index {
    return [[self.waterIntakeValues objectAtIndex:index] doubleValue];
}

- (NSString *)popUpSuffixForlineGraph:(BEMSimpleLineGraphView *)graph {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *unitTypeSelected = [userDefaults objectForKey:kNSUserUnitTypeSelected];
    if ([unitTypeSelected isEqualToString:@"milliliter"]) {
        return @" ml";
    }else {
        return @" oz";
    }
}

- (BOOL)noDataLabelEnableForLineGraph:(BEMSimpleLineGraphView *)graph {
    return NO;
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
    [self.waterIntakeValues removeAllObjects];
    [self.dateValues removeAllObjects];
    self.totalNumber = 0;

    //Load dateValues and waterIntakeValues in loadWaterIntakeForADay
    unsigned int comps = NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear;
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDate *dateOfInterest = [NSDate new];
    NSDateComponents* dayComponent = [NSDateComponents new];
    NSInteger amountOfDaysInMonth  = 0;
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"MMMM yyyy"];
    dateOfInterest = [dateFormatter dateFromString:self.navigationItem.title];
    //Get how many days there are in that month from calendar
    NSRange rng = [calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:dateOfInterest];
    amountOfDaysInMonth = rng.length;
    dayComponent = [calendar components:comps fromDate:dateOfInterest];
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
            if (shouldReload) {
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                NSString *unitTypeSelected = [userDefaults objectForKey:kNSUserUnitTypeSelected];
                if ([unitTypeSelected isEqualToString:@"milliliter"]) {
                    for (int i = 0; i < self.waterIntakeValues.count; i++) {
                        NSNumber *number = [self.waterIntakeValues objectAtIndex:i];
                        float floatNumber = [number floatValue];
                        floatNumber = floatNumber * 29.5735;
                        number = [NSNumber numberWithFloat:floatNumber];
                        [self.waterIntakeValues setObject:number atIndexedSubscript:i];
                    }
                }

                //For display Demo purposes (does not work this way)
//                [self.waterIntakeValues removeAllObjects];
//                for (int i = 0; i < self.dateValues.count; i++) {
//                    if ([self.waterHeightProportionsForDays objectForKey:day]) {
//                        NSNumber *proportion = [self.waterHeightProportionsForDays objectForKey:day];
//                        float waterIntake = [proportion floatValue] * 400;
//                        [self.waterIntakeValues addObject:[NSNumber numberWithFloat:waterIntake]];
//                    } else{
//                        [self.waterIntakeValues addObject:[NSNumber numberWithFloat:0]];
//                    }
//                }

                [self.graphView reloadGraph];
                [self.waterIntakeValues removeAllObjects];
                [self.dateValues removeAllObjects];
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

//////////// Calendar ////////////

#pragma mark - PDTSimpleCalendarViewController methods to override

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PDTSimpleCalendarViewCell *cell = (PDTSimpleCalendarViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];

    cell.dayLabel.textColor = self.cellTextColor;
    cell.dayLabel.backgroundColor = self.cellColor;

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

    if ([self.waterHeightProportionsForDays objectForKey:date] && ![cell.dayLabel.text isEqualToString:@""]) {

        cell.dayLabel.textColor = self.waterFillTextColor;

        //Static backgroundRectangle
        UIView *backgroundRectangle = [[UILabel alloc]initWithFrame:cell.dayLabel.frame];

        backgroundRectangle.backgroundColor = self.waterFillColor;
        backgroundRectangle.layer.borderColor = self.cellBorderColor.CGColor;
        backgroundRectangle.layer.borderWidth = 1;

        [cell bringSubviewToFront:cell.dayLabel];
        [cell insertSubview:backgroundRectangle belowSubview:cell.dayLabel];
        [cell sendSubviewToBack:backgroundRectangle];

        //Dynamic frame for cover based on waterIntake and goal for that date
        CGRect coverFrame = backgroundRectangle.frame;
        NSNumber *proportion = [self.waterHeightProportionsForDays objectForKey:date];

        coverFrame.size.height = ((float)backgroundRectangle.frame.size.height - (float)backgroundRectangle.frame.size.height * [proportion floatValue]);

        UIView *coverRectangle = [[UILabel alloc] initWithFrame:coverFrame];
        coverRectangle.backgroundColor = self.cellCoverColor;

        //Borders for cover
        UIView *topBorder = [UIView new];
        topBorder.backgroundColor = self.cellBorderColor;
        topBorder.frame = CGRectMake(backgroundRectangle.frame.origin.x, backgroundRectangle.frame.origin.y, coverRectangle.frame.size.width, 1.0f);
        [cell addSubview:topBorder];
        UIView *leftBorder = [UIView new];
        leftBorder.backgroundColor = self.cellBorderColor;
        leftBorder.frame = CGRectMake(backgroundRectangle.frame.origin.x, backgroundRectangle.frame.origin.y, 1.0f, backgroundRectangle.frame.size.height);
        [cell addSubview:leftBorder];
        UIView *rightBorder = [UIView new];
        rightBorder.backgroundColor = self.cellBorderColor;
        rightBorder.frame = CGRectMake(backgroundRectangle.frame.origin.x +backgroundRectangle.frame.size.width - 1.0f, backgroundRectangle.frame.origin.y, 1.0f, backgroundRectangle.frame.size.height);
        [cell addSubview:rightBorder];

        cell.dayLabel.backgroundColor = [UIColor clearColor];

        [cell sendSubviewToBack:backgroundRectangle];
        [cell insertSubview:coverRectangle aboveSubview:backgroundRectangle];
        [cell bringSubviewToFront:cell.dayLabel];
    }


    return cell;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{

    [super scrollViewDidScroll:scrollView];
//    if (![self.navigationItem.title isEqualToString:self.overlayView.text]) {
//        self.navigationItem.title = self.overlayView.text;
//    }

    CGRect serachRect = CGRectMake(self.collectionView.bounds.origin.x, self.collectionView.bounds.origin.y, self.collectionView.bounds.size.width, (self.collectionView.bounds.size.height / 1.5));
    NSArray *layoutsInSearchRect = [self.collectionView.collectionViewLayout layoutAttributesForElementsInRect:serachRect];
    UICollectionViewLayoutAttributes *lastSection = [layoutsInSearchRect lastObject];
    PDTSimpleCalendarViewHeader *header = (PDTSimpleCalendarViewHeader *)[super collectionView:self.collectionView viewForSupplementaryElementOfKind:UICollectionElementKindSectionHeader atIndexPath:lastSection.indexPath];
    if (lastSection.representedElementKind == UICollectionElementKindSectionHeader) {
        self.navigationItem.title = [header.titleLabel.text capitalizedString];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (velocity.y == 0.f) {
        // A 0 velocity means the user dragged and stopped (no flick)
        // In this case, tell the scroll view to animate to the closest index
        CGRect serachRect = CGRectMake(self.collectionView.bounds.origin.x, self.collectionView.bounds.origin.y, self.collectionView.bounds.size.width, (self.collectionView.bounds.size.height / 1.5));
        NSArray *layoutsInSearchRect = [self.collectionView.collectionViewLayout layoutAttributesForElementsInRect:serachRect];
        UICollectionViewLayoutAttributes *lastSection = [layoutsInSearchRect lastObject];

        PDTSimpleCalendarViewHeader *header = (PDTSimpleCalendarViewHeader *)[super collectionView:self.collectionView viewForSupplementaryElementOfKind:UICollectionElementKindSectionHeader atIndexPath:lastSection.indexPath];
        CGRect rect = [lastSection frame];
        if (lastSection.representedElementKind == UICollectionElementKindSectionHeader) {
            [UIView animateWithDuration:0.5 animations:^{
                [scrollView setContentOffset:CGPointMake(0, rect.origin.y) animated:YES];
            } completion:^(BOOL finished) {
                [self hydrateDataSetsForMonth:[header.titleLabel.text capitalizedString]];
            }];
        }
    } else if (velocity.y > 0.f) {
        // User scrolled downwards
        // Evaluate to the nearest index

    } else {
        // User scrolled upwards
        // Evaluate to the nearest index
        //        [scrollView setContentOffset:CGPointMake(0, self.sectionHeaderViewDisplayed.frame.origin.y) animated:YES];
        
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self hydrateDataSetsForMonth:self.navigationController.title];
}


-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    //Empty so it doesn't hide overlay from super
//    [self hydrateDataSetsForMonth:self.overlayView.text];
}

- (BOOL)simpleCalendarViewController:(PDTSimpleCalendarViewController *)controller isEnabledDate:(NSDate *)date {
    return NO;
}

#pragma mark - PDTSimpleCalendarViewController Helper Methods

- (NSString *)labelForDateAtIndex:(NSInteger)index {
    NSDate *date = self.dateValues[index];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"MM/dd";
    NSString *label = [df stringFromDate:date];
    return label;
}

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

- (NSDateFormatter *)headerDateFormatter;
{
    if (!_headerDateFormatter) {
        _headerDateFormatter = [[NSDateFormatter alloc] init];
        _headerDateFormatter.calendar = self.calendar;
        _headerDateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"yyyy LLLL" options:0 locale:self.calendar.locale];
    }
    return _headerDateFormatter;
}

@end

