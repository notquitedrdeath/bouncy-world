//
//  UIColor+RandColor.m
//  Bouncy World
//
//  Created by Timothy Death on 9/05/13.
//  Copyright (c) 2013 Timothy Death. All rights reserved.
//

#import "UIColor+RandColor.h"

@implementation UIColor (RandColor)
+(UIColor *) getRandColorRGB {
    return [UIColor colorWithRed:(arc4random() % 100)/100
                           green:(arc4random() % 100)/100
                            blue:(arc4random() % 100)/100
                           alpha:1];
}

+(UIColor *) getRandColorHSB {
    CGFloat hue = (arc4random() % 256 / 256.0);
    CGFloat saturation = (arc4random() % 256 / 256.0) + 0.5;
    CGFloat brightness = (arc4random() % 256 / 256.0) + 0.5;
    return [UIColor colorWithHue:hue
               saturation:saturation
               brightness:brightness
                    alpha:1];
}
@end
