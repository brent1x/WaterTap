//
//  User.m
//  FinalProject
//
//  Created by Nader Neyzi on 6/18/15.
//  Copyright (c) 2015 Brent Dady. All rights reserved.
//

#import "User.h"
#import <Parse/PFObject+Subclass.h>

@implementation User

@dynamic fullName;

+ (void)load {
    [self registerSubclass];
}

@end
