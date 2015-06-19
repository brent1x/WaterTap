//
//  User.h
//  FinalProject
//
//  Created by Nader Neyzi on 6/18/15.
//  Copyright (c) 2015 Brent Dady. All rights reserved.
//

#import <Parse/Parse.h>

@interface User : PFUser <PFSubclassing>

@property (nonatomic, strong) NSString *fullName;


@end
