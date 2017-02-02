#import "MenuViewController.h"
#import "SelectionPage.h"
#import "ManualLayout.h"
#import <substrate.h>

@implementation ACMenuViewController
@dynamic view;
@synthesize menuDelegate;

- (void)loadView {
  UIView *view = [[UIView alloc] init];
  view.translatesAutoresizingMaskIntoConstraints = false;
  self.closeAllPagesButton = [CCUIControlCenterButton capsuleButtonWithText: @"Close all App Center pages"];
  self.closeAllPagesButton.delegate = self;
  self.closeAllPagesButton.translatesAutoresizingMaskIntoConstraints = false;
  self.closeAllPagesButton.animatesStateChanges = true;
  [view addSubview: self.closeAllPagesButton];

  self.closeAllAppsButton = [CCUIControlCenterButton capsuleButtonWithText: @"Kill all apps"];
  self.closeAllAppsButton.delegate = self;
  self.closeAllAppsButton.translatesAutoresizingMaskIntoConstraints = false;
  self.closeAllAppsButton.animatesStateChanges = true;
  [view addSubview: self.closeAllAppsButton];

  self.view = view;
  [view release];

  NSDictionary *views = @{
    @"closeAllPagesButton": self.closeAllPagesButton,
    @"closeAllAppsButton": self.closeAllAppsButton,
  };

  NSMutableArray *constraints = [NSMutableArray new];

  double spacing = [ACManualLayout collectionViewContentInset].left;
  NSString *closeAllPagesButtonFormatH = [NSString stringWithFormat:@"H:|[closeAllPagesButton]"];
  [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:closeAllPagesButtonFormatH options:nil metrics:nil views:views]];
  NSString *closeAllAppsButtonFormatH = [NSString stringWithFormat:@"H:|[closeAllAppsButton]"];
  [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:closeAllAppsButtonFormatH options:nil metrics:nil views:views]];
  NSString *verticalLayout = [NSString stringWithFormat:@"V:|-(%f)-[closeAllPagesButton]-(8)-[closeAllAppsButton]", spacing];
  [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:verticalLayout options:nil metrics:nil views:views]];
  [constraints addObject:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.closeAllPagesButton attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
  [constraints addObject:[NSLayoutConstraint constraintWithItem:self.closeAllPagesButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.closeAllAppsButton attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];

  [self.view addConstraints:constraints];
}

// MARK: - CCUIControlCenterButtonDelegate
-(BOOL)isInternal {
  return false;
}
- (void)buttonTapped:(CCUIControlCenterButton *)arg1 {
  if ([arg1.text isEqualToString: @"Close all App Center pages"]) {
    [menuDelegate closeAllPagesButtonTapped];
  } else {
    [menuDelegate closeAllAppsButtonTapped];
  }
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    arg1.selected = false;
  });
}

@end
