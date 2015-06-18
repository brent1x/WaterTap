//
//  ConsumptionEvent.m
//  FinalProject
//
//  Created by Brent Dady on 6/18/15.
//  Copyright (c) 2015 Brent Dady. All rights reserved.
//

#import "ConsumptionEvent.h"
#import <Parse/PFObject+Subclass.h>

@implementation ConsumptionEvent

@dynamic user;
@dynamic volumeConsumed;
@dynamic consumptionGoal;

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {

    return @"ConsumptionEvent";
}

@end
