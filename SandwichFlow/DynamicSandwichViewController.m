//
//  DynamicSandwichViewController.m
//  SandwichFlow
//
//  Created by Perry on 14-7-31.
//  Copyright (c) 2014年 Colin Eberhardt. All rights reserved.
//

#import "DynamicSandwichViewController.h"
#import "SandwichViewController.h"
#import "AppDelegate.h"
@interface DynamicSandwichViewController ()
{
    NSMutableArray *_views;
    
    UIGravityBehavior* _gravity;
    UIDynamicAnimator* _animator;
    CGPoint _previousTouchPoint;
    BOOL _draggingView;
}
@end

@implementation DynamicSandwichViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (NSArray *)sandwiches
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    return appDelegate.sandwiches;
}

- (void)handlePan:(UIPanGestureRecognizer*)gesture {
    CGPoint touchPoint = [gesture locationInView:self.view];
    UIView  *draggedView = gesture.view;
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        /**
         *  When the gesture begins, check if the pan was initiated near the top of the view.
         *  If so, set a flag so later gestures will know there's a pan and drag in progress.
         *  In your own apps, you might want to replace this hard-coded value of 200 points with a value derived from the view's layout`
         */
         // 1. was the pan initiated from the top of the recipe
        CGPoint dragStartLocation = [gesture locationInView:draggedView];
        if (dragStartLocation.y < 200.0f) {
            _draggingView = YES;
            _previousTouchPoint = touchPoint;
        }
    } else if (gesture.state == UIGestureRecognizerStateChanged && _draggingView) {
        /**
         *  If a drag is in progress, use the difference in Y locations between the previous and the current
         *  touches to offset the view's center, making it move.
         */
        // 2. handle dragging
        float yOffset = _previousTouchPoint.y - touchPoint.y;
        gesture.view.center = CGPointMake(draggedView.center.x, draggedView.center.y - yOffset);
        _previousTouchPoint = touchPoint;
        
    } else if (gesture.state == UIGestureRecognizerStateEnded && _draggingView) {
        /**
         *  The final case is when the drag finishes. The vital step here is messaging the animator with updateItemUsingCurrentState. This message informs the dynamics engine that the item state has changed and that it must update its own representation. This is similar to sending setNeedsDisplay to a UIView subclass.
         *
         */
        // 3. the gesture has ended
        [_animator updateItemUsingCurrentState:draggedView];
        _draggingView = NO;
    }
}

- (UIView *)addRecipeAtOffset:(float)offset forSandwich:(NSDictionary *)sandwich {
    CGRect frameForView = CGRectOffset(self.view.bounds, 0.0, self.view.bounds.size.height - offset);
    NSLog(@"frame for view is %@",NSStringFromCGRect(frameForView));
    /**
     * Create a SandwichViewController instance. Notice that this uses the SandwichVC identifier you set earlier.
     *
     */
    // 1. create the view controller
    UIStoryboard *mystoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SandwichViewController *viewController = [mystoryboard instantiateViewControllerWithIdentifier:@"SandwichVC"];
    
    /**
     *  Set the frame of this recipe and the supply the sandwich data
     *
     */
    // 2. set the frame and provide some data
    UIView *view = viewController.view;
    view.frame = frameForView;
    viewController.sandwich = sandwich;
    
    /**
     *  Add the view controller as a child and to the view
     *
     */
    // 3. add as a child
    [self addChildViewController:viewController];
    [self.view addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];

    /**
     *  Create a pan gesture recognizer associate it with the view. The handlePan: message is sent when a pan occurs.
     *  You'll add this method shortly.
     */
    // 1. add a gesture recognizer
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [viewController.view addGestureRecognizer:pan];
    
    /**
     *  Create a collision behaviour for this view so it doesn't go into immediate free fall.
     *
     */
    // 2. create a collision
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[view]];
    [_animator addBehavior:collision];
    
    /**
     *  Create a boundary where this specific view controller will come to rest.
     *  It is based on the bottom edge of the current view location.
     */
    // 3. lower boundary, where the tab resets
    float boundary = view.frame.origin.y + view.frame.size.height + 1;
    CGPoint boundaryStart = CGPointMake(0.0, boundary);
    CGPoint boundaryEnd = CGPointMake(self.view.bounds.size.width, boundary);
    [collision addBoundaryWithIdentifier:@1 fromPoint:boundaryStart toPoint:boundaryEnd];
    NSLog(@"boundary is %f",boundary);
    
    /**
     *  apply the gravity behaviour to the view
     *
     */
    // 4. apply some gravity
    [_gravity addItem:view];
    
    return view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Background image
    UIImageView* backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Background-LowerLayer.png"]];
    [self.view addSubview:backgroundImageView];
    
    // Header logo
    UIImageView *header = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Sarnie.png"]];
    header.center = CGPointMake(220, 190);
    [self.view addSubview:header];
    
    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    _gravity = [[UIGravityBehavior alloc] init];
    [_animator addBehavior:_gravity];
    _gravity.magnitude = 4.0f;
    
    /**
     *  iterate over the recipes and use the above method to add each recipe to the view
     *
     */
    _views = [NSMutableArray new];
    float offset = 250.0f;
    for (NSDictionary *sandwich in [self sandwiches]) {
        [_views addObject:[self addRecipeAtOffset:offset forSandwich:sandwich]];
        offset -= 50.0f;
    }
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
