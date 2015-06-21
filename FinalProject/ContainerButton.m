//
//  ContainerButton.m
//  FinalProject
//
//  Created by Anders Chaplin on 6/20/15.
//  Copyright (c) 2015 Brent Dady. All rights reserved.
//

#import "ContainerButton.h"

@implementation ContainerButton

-(void)prepareForInterfaceBuilder {
    [super prepareForInterfaceBuilder];
    [self setUp];
}

-(void)awakeFromNib {
    [super awakeFromNib];
    [self setUp];
}

-(void)setUp {


    [self setTitleColor:[UIColor colorWithRed:0.13 green:0.3 blue:0.38 alpha:1] forState:UIControlStateNormal];

    [self setTitle:@"Button" forState:UIControlStateNormal];

    self.layer.borderColor = [UIColor colorWithRed:0.33 green:0.71 blue:0.89 alpha:1].CGColor;


    self.layer.backgroundColor = [UIColor colorWithRed:1 green:0.69 blue:0.36 alpha:1].CGColor;
   self.layer.borderWidth = 10;
   self.layer.cornerRadius = self.bounds.size.height/2;
}

@end
