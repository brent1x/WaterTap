//
//  ConsumptionEvent.h
//  FinalProject
//
//  Created by Brent Dady on 6/18/15.
//  Copyright (c) 2015 Brent Dady. All rights reserved.
//

#import <Parse/Parse.h>

@interface ConsumptionEvent : PFObject <PFSubclassing>

@property (nonatomic, strong) PFUser *user;
@property int volumeConsumed;
@property int consumptionGoal;


+ (NSString *)parseClassName;
@end

