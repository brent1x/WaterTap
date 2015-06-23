//
//  ContainerButton.h
//  FinalProject
//
//  Created by Anders Chaplin on 6/20/15.
//  Copyright (c) 2015 Brent Dady. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface ContainerButton : UIButton
@property int customAmount;
@end

//
//-(CGRect)makeFrameRectWithWidth:(int)width andHeight:(int)height {
//
//    CGPoint point = CGPointMake(width, height);
//    point.x -= 100;
//    point.y -= 100;
//
//    CGRect rect = CGRectMake(point.x, point.y,75,50);
//
//    return rect;
//    
//}