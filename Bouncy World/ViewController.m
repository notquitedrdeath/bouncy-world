//
//  ViewController.m
//  Bouncy World
//
//  Created by Timothy Death on 25/03/13.
//  Copyright (c) 2013 Timothy Death. All rights reserved.
//

#import "ViewController.h"

#define GRAVITY 400.0f
#define STEP_INTERVAL 1/60.0f
#define RADIUS 16.0f
#define BUTTON_SPACE_OFFSET 62

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
    cpBodyApplyImpulse(shape->body, viewCont->diff, cpvzero);
}

static void applyRandImpulse (cpShape * shape, void *data) {
    CALayer *layer = (__bridge CALayer *) shape->data;
    if(!layer)
        return;
    cpBodyApplyImpulse(shape->body, cpv(arc4random() % 1000+1000, arc4random() % 1000 + 1000), cpvzero);

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
    CGPoint swipeEnd = [touch locationInView:self.view];
    diff = cpv((swipeStart.x - swipeEnd.x - (swipeStart.x - swipeEnd.x)*2)*5, (swipeStart.y - swipeEnd.y - (swipeStart.y - swipeEnd.y)*2)*5);
    cpSpaceEachShape(space, &applyImpulse, (__bridge void *) self);
}

-(void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if(motion == UIEventSubtypeMotionShake) {
        cpSpaceEachShape(space, &applyRandImpulse, (__bridge void *) self);
    }
}

@end
