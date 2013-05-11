//
//  ViewController.m
//  Bouncy World
//
//  Created by Timothy Death on 25/03/13.
//  Copyright (c) 2013 Timothy Death. All rights reserved.
//

#import "ViewController.h"

#define GRAVITY 400.0f
#define STEP_INTERVAL 1/100.0f
#define RADIUS 16.0f
#define BLAST_RADIUS 20.0f       // possibly user-defined
#define BUTTON_SPACE_OFFSET 62

typedef struct LinearLine {
	CGPoint a, b;
} LinearLine;

@interface ViewController ()

@end

@implementation ViewController

#pragma mark - Inherited Functions

-(void) dealloc {
    cpSpaceFree(space);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //Create the motion manager
    motionManager = [[CMMotionManager alloc] init];
    ballCount = 0;
    [self.view setBackgroundColor:[UIColor blackColor]];
    //Build the space for the balls to bounce in.
    [self buildSpace];
    CGRect screenSize = [[UIScreen mainScreen] bounds];
    [self dropBallAtPoint:CGPointMake(screenSize.size.width/2, screenSize.size.height/2)];
    
    
    CALayer * layer = [CALayer layer];
    layer.position  = CGPointMake(screenSize.size.width/2, 429);
    layer.bounds = CGRectMake(screenSize.size.width/2, 415, 40, 40);
    layer.backgroundColor = [UIColor redColor].CGColor;
    [self.view.layer addSublayer:layer];
    
    //Set up the tapping for extra balls
    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self.view addGestureRecognizer:tapGesture];
    
}

-(void) viewDidAppear:(BOOL)animated {
    [self becomeFirstResponder];
    //Set a timer for the physics sim
    [NSTimer scheduledTimerWithTimeInterval:STEP_INTERVAL
                                     target:self
                                   selector:@selector(step)
                                   userInfo:nil
                                    repeats:YES];
    
    [motionManager startAccelerometerUpdates];
    
    [NSTimer scheduledTimerWithTimeInterval:1/10.0f target:self selector:@selector(doAccelUpdate) userInfo:nil repeats:YES];
    [super viewDidAppear:animated];
    
}

-(void) viewDidDisappear:(BOOL)animated {
    [self resignFirstResponder];
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return NO;
}

#pragma mark - Physics Functions

-(void) buildSpace {    
    //Create the space that everything will happen in and set the Gravity
    space = cpSpaceNew();
    space->gravity = cpv(0.0f, GRAVITY);
    acceleratedGravity = CGPointMake(0.0f, GRAVITY);
    
    CGSize size = [[UIScreen mainScreen] bounds].size;
    
    cpBody *edge = cpBodyNewStatic();
    cpShape *shape = NULL;
    
    //Left Wall
    shape = cpSegmentShapeNew(edge, cpv(0.0f, -10.0f), cpv(0.0f,size.height+10), 10.0f);
    shape->u = 0.1f;
    shape->e = 0.7f;
    cpSpaceAddStaticShape(space, shape);
    
    //Top Wall
    shape = cpSegmentShapeNew(edge, cpv(-10.0f, 0.0f), cpv(size.width+10,0.0f), 10.0f);
    shape->u = 0.1f;
    shape->e = 0.7f;
    cpSpaceAddStaticShape(space, shape);
    
    //Right Wall
    shape = cpSegmentShapeNew(edge, cpv(size.width, -10.0f), cpv(size.width,size.height+10), 10.0f);
    shape->u = 0.1f;
    shape->e = 0.7f;
    cpSpaceAddStaticShape(space, shape);
    
    //Bottom Wall
    shape = cpSegmentShapeNew(edge, cpv(-10.0f, size.height-BUTTON_SPACE_OFFSET), cpv(size.width+10,size.height-BUTTON_SPACE_OFFSET), 10.0f);
    shape->u = 0.1f;
    shape->e = 0.7f;
    cpSpaceAddStaticShape(space, shape);
    
}

-(void) step {
    cpSpaceStep(space, STEP_INTERVAL);
    
    [CATransaction setDisableActions:YES];
    cpSpaceEachShape(space, &updateSpace, (__bridge void *) self);
    [CATransaction setDisableActions:NO];
}

static void updateSpace (cpShape * shape, void *data) {
    CALayer *layer = (__bridge CALayer *) shape->data;
    if(!layer)
        return;
    CGRect screenSize = [[UIScreen mainScreen] bounds];
    if(!CGRectContainsPoint(screenSize, shape->body->p)) {
        shape->body->p = cpv(screenSize.size.width/2, screenSize.size.height/2);
    }
    layer.position = shape->body->p;
}

- (void) dropBallAtPoint: (CGPoint)pt {
    CALayer * layer = [CALayer layer];
    layer.position = pt;
    layer.bounds = CGRectMake(0.0f, 0.0f, RADIUS*2, RADIUS*2);
    layer.cornerRadius = RADIUS;
    layer.backgroundColor = [UIColor getRandColorHSB].CGColor;
    
    [[self.view layer] addSublayer:layer];
    
    cpBody * body = cpBodyNew(1.0f, INFINITY);
    body->p = pt;
    cpSpaceAddBody(space, body);
    
    cpShape *ball = cpCircleShapeNew(body, RADIUS, cpvzero);
    ball->data = (__bridge void *) layer;
    ball->e = 0.7f;
    cpSpaceAddShape(space, ball);
}

static void applyImpulse (cpShape * shape, void *data) {
    CALayer *layer = (__bridge CALayer *) shape->data;
    if(!layer)
        return;
    
    ViewController * viewCont = (__bridge ViewController *) data;
    cpVect pulse = viewCont->diff;

    if (BLAST_RADIUS > 0.0) {
        // get linear line between swipe start and end
        LinearLine line;
        line.a = CGPointMake(viewCont->swipeStart.x, viewCont->swipeStart.y);
        line.b = CGPointMake(viewCont->swipeEnd.x, viewCont->swipeEnd.y);

        // get position of current ball and finds its distance from linear swipe line
        CGPoint position = [[layer presentationLayer] frame].origin;
        CGFloat distance = distanceFromPointToLine(position, line);
    
        // ensure distance is a number (!NaN)
        if (distance == distance) {
 
            // defines how the distance affects the current ball
            CGFloat affect = BLAST_RADIUS / distance;
            if (affect > 1.0)
                affect = 1.0;

            pulse = cpv(viewCont->diff.x * affect, viewCont->diff.y * affect);
        }
    }
    cpBodyApplyImpulse(shape->body, pulse, cpvzero);
}

static void applyRandImpulse (cpShape * shape, void *data) {
    CALayer *layer = (__bridge CALayer *) shape->data;
    if(!layer)
        return;
    cpBodyApplyImpulse(shape->body, cpv(arc4random() % 1000+1000, arc4random() % 1000 + 1000), cpvzero);
}

static CGFloat distanceFromPointToLine (CGPoint point, LinearLine line) {
    // calculate slope and equation y = mx + b
    CGFloat m = (line.b.y - line.a.y) / (line.b.x - line.a.x);
    CGFloat b = line.a.y - m * line.a.x;
   
    // calculate distance
    CGFloat distance = fabsf(point.y - m * point.x - b) / sqrtf(powf(m, 2.0) + 1);
    return distance;
}

#pragma mark - User Interaction

- (void) tap: (UITapGestureRecognizer *)gr {
    CGPoint pt = [gr locationInView:self.view];
    if(pt.y < [[UIScreen mainScreen] bounds].size.height-BUTTON_SPACE_OFFSET)
    [self dropBallAtPoint:pt];
}

- (void) doAccelUpdate {
    CMAcceleration acceleration = motionManager.accelerometerData.acceleration;
    acceleratedGravity.x = acceleration.x * GRAVITY;
    acceleratedGravity.y = -acceleration.y * GRAVITY;
    
     space->gravity = cpv(acceleratedGravity.x, acceleratedGravity.y);
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch * touch = [touches anyObject];
    swipeStart = [touch locationInView:self.view];
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch * touch = [touches anyObject];
    swipeEnd = [touch locationInView:self.view];
    diff = cpv((swipeStart.x - swipeEnd.x - (swipeStart.x - swipeEnd.x)*2)*5, (swipeStart.y - swipeEnd.y - (swipeStart.y - swipeEnd.y)*2)*5);
    cpSpaceEachShape(space, &applyImpulse, (__bridge void *) self);
}

-(void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if(motion == UIEventSubtypeMotionShake) {
        cpSpaceEachShape(space, &applyRandImpulse, (__bridge void *) self);
    }
}

@end
