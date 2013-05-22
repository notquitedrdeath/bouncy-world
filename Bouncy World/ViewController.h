//
//  ViewController.h
//  Bouncy World
//
//  Created by Timothy Death on 25/03/13.
//  Copyright (c) 2013 Timothy Death. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "chipmunk.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreMotion/CoreMotion.h>
#import "Debug.h"
#import "UIColor+RandColor.h"

@interface ViewController : UIViewController <UIGestureRecognizerDelegate> {
    cpSpace * space;
    CMMotionManager * motionManager;
    CGPoint acceleratedGravity;
    NSInteger ballCount;
    CGPoint swipeStart;
    CGPoint swipeEnd;
    cpVect diff;
    UIButton * plus, * minus, * refresh;
    BOOL removeBall, removeAllBalls;
}

@end
