#pragma mark Includes & Defines

#include <substrate.h>
#define REQUESTER @"com.eswick.appcenter"

#import "ControlCenterUI.h"
#import "SpringBoard.h"
#import "FrontBoard.h"
#import "FrontBoardServices.h"
#import "SelectionPage.h"
#import "Tweak.h"

#pragma mark Implementations

@interface ACAppPageView : UIView

@end

@implementation ACAppPageView

@end

@interface ACAppPageViewController : UIViewController <CCUIControlCenterPageContentProviding>

@property (nonatomic, retain) SBApplication *app;
@property (nonatomic, assign) id <CCUIControlCenterPageContentViewControllerDelegate> delegate;
@property (nonatomic, retain) FBSceneHostManager *sceneHostManager;
@property (nonatomic, retain) FBSceneHostWrapperView *hostView;

- (id)initWithBundleIdentifier:(NSString*)bundleIdentifier;
- (void)controlCenterDidFinishTransition;

@end

@implementation ACAppPageViewController
@synthesize delegate;

- (id)initWithBundleIdentifier:(NSString*)bundleIdentifier {
  self = [super init];
  if (self) {
    self.app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:bundleIdentifier];

    if (!self.app) {
      return nil;
    }
  }
  return self;
}

- (void)controlCenterDidFinishTransition {

}

- (void)controlCenterWillBeginTransition {

}

- (void)controlCenterDidDismiss {
  [self.sceneHostManager disableHostingForRequester:REQUESTER];
  [self.app appcenter_stopBackgroundingWithCompletion:nil];
}

- (void)controlCenterWillPresent {
  [self.app appcenter_startBackgroundingWithCompletion:^void(BOOL success) {
    dispatch_async(dispatch_get_main_queue(), ^{
      self.sceneHostManager = [[self.app mainScene] contextHostManager];
      self.hostView = [self.sceneHostManager hostViewForRequester:REQUESTER enableAndOrderFront:true];

      self.hostView.layer.cornerRadius = 10;
      self.hostView.layer.masksToBounds = true;

      CGFloat scale = self.view.bounds.size.width / [[UIScreen mainScreen] bounds].size.width;
      self.hostView.transform = CGAffineTransformMakeScale(scale, scale);

      self.hostView.alpha = 0.0;

      [self.view addSubview:self.hostView];

      [UIView animateWithDuration:0.25 animations:^{
        self.hostView.alpha = 1.0;
      }];
    });
  }];
}

- (void)viewWillLayoutSubviews {
  CGRect frame = self.hostView.frame;

  frame.origin.x = self.view.frame.origin.x;
  frame.origin.y = self.view.frame.size.height - self.hostView.frame.size.height;

  self.hostView.frame = frame;
}

- (void)loadView {
  ACAppPageView *pageView = [[ACAppPageView alloc] init];
  self.view = pageView;
  [pageView release];
}

- (void)viewWillAppear:(BOOL)arg1 {
  [super viewWillAppear:arg1];
}

@end

#pragma mark Hooks

%hook SBApplication

%new
- (void)appcenter_setBackgrounded:(BOOL)backgrounded withCompletion:(void (^)(BOOL))completion {
  FBSceneManager *sceneManager = [%c(FBSceneManager) sharedInstance];
  FBScene *scene = [sceneManager sceneWithIdentifier:[self bundleIdentifier]];
  id <FBSceneClientProvider> clientProvider = [scene clientProvider];
  id <FBSceneClient> client = [scene client];

  FBSSceneSettings *settings = [scene settings];
  FBSMutableSceneSettings *mutableSettings = [settings mutableCopy];

  [mutableSettings setBackgrounded:backgrounded];

  FBSSceneSettingsDiff *settingsDiff = [%c(FBSSceneSettingsDiff) diffFromSettings:settings toSettings:mutableSettings];

  [clientProvider beginTransaction];
  [client host:scene didUpdateSettings:mutableSettings withDiff:settingsDiff transitionContext:nil completion:completion];
  [clientProvider endTransaction];
}

%new
- (void)appcenter_startBackgroundingWithCompletion:(void (^)(BOOL))completion {
  if (![self isRunning]) {

    [[%c(FBSSystemService) sharedService] openApplication:[self bundleIdentifier] options:@{ FBSOpenApplicationOptionKeyActivateSuspended : @true } withResult:^{
      [self appcenter_setBackgrounded:false withCompletion:completion];
    }];

    return;
  }
  [self appcenter_setBackgrounded:false withCompletion:completion];
}

%new
- (void)appcenter_stopBackgroundingWithCompletion:(void (^)(BOOL))completion {
  [self appcenter_setBackgrounded:true withCompletion:completion];
}

%end

ACAppSelectionPageViewController *selectionViewController = nil;
NSMutableArray<NSString*> *appPages = nil;

%hook CCUIControlCenterViewController

- (void)_loadPages {
  %orig;
  selectionViewController = [[ACAppSelectionPageViewController alloc] initWithNibName:nil bundle:nil];
  [self _addContentViewController:selectionViewController];
  [selectionViewController release];
}

%new
- (void)appcenter_appSelected:(NSString*)bundleIdentifier {
  if (!appPages) {
    appPages = [NSMutableArray new];
  }

  if ([appPages containsObject:bundleIdentifier]) {

    for (UIViewController *contentViewController in [self contentViewControllers]) {
      if ([contentViewController isKindOfClass:[ACAppPageViewController class]]) {
        if ([[[(ACAppPageViewController*)contentViewController app] bundleIdentifier] isEqualToString:bundleIdentifier]) {

          ACAppPageViewController *appPageViewController = (ACAppPageViewController*)contentViewController;

          [[appPageViewController app] appcenter_stopBackgroundingWithCompletion:nil];

          [appPageViewController.sceneHostManager disableHostingForRequester:REQUESTER];

          [self _removeContentViewController:contentViewController];
          [appPages removeObject:bundleIdentifier];
          [self controlCenterWillPresent];

          [[[selectionViewController gridViewController] collectionView] performBatchUpdates:^{
            [[[selectionViewController gridViewController] collectionView] reloadSections:[NSIndexSet indexSetWithIndex:0]];
          } completion:^(BOOL finished) {
            [[selectionViewController gridViewController] fixButtonEffects];
          }];
        }
      }
    }

    return;
  }

  [appPages addObject:bundleIdentifier];

  [UIView animateWithDuration:0.25 animations:^{
    selectionViewController.view.alpha = 0;
  } completion:^(BOOL completed) {
    [self _removeContentViewController:selectionViewController];

    [[[selectionViewController gridViewController] collectionView] reloadData];

    selectionViewController.view.alpha = 1;

    SBApplication *application = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:bundleIdentifier];
    [application appcenter_startBackgroundingWithCompletion:^(BOOL success) {
      dispatch_async(dispatch_get_main_queue(), ^{
        ACAppPageViewController *appPage = [[ACAppPageViewController alloc] initWithBundleIdentifier:bundleIdentifier];
        [self _addContentViewController:appPage];
        [self _addContentViewController:selectionViewController];

        [self controlCenterWillPresent];
        MSHookIvar<UIViewController*>(self, "_selectedViewController") = appPage;

        [[selectionViewController gridViewController] fixButtonEffects];
      });
    }];
  }];
}

- (void)_updatePageControl {
  if ([MSHookIvar<UIViewController*>(self, "_selectedViewController") isKindOfClass:[ACAppPageViewController class]]) {
    for (CCUIControlCenterPageContainerViewController *viewController in [self sortedVisibleViewControllers]) {
      if (viewController.contentViewController == MSHookIvar<UIViewController*>(self, "_selectedViewController")) {
        MSHookIvar<UIViewController*>(self, "_selectedViewController") = viewController;
      }
    }
  }
  %orig;
}

%end

%hook CCUIControlCenterPagePlatterView

- (void)layoutSubviews {
  if ([self.contentView isKindOfClass:[ACAppPageView class]]) {
    MSHookIvar<UIView*>(self, "_baseMaterialView").hidden = true;
    MSHookIvar<UIView*>(self, "_whiteLayerView").hidden = true;
  } else {
    %orig;
  }
}

- (void)_recursivelyVisitSubviewsOfView:(id)arg1 forPunchedThroughView:(id)arg2 collectingMasksIn:(id)arg3 {
  if ([self.contentView isKindOfClass:[ACAppPageView class]]) {
    return;
  }

  %orig;
}

%end

%hook SBAppSwitcherModel

%new
- (NSArray<NSString*>*)appcenter_model {
  NSArray<SBDisplayItem*>* model = [self mainSwitcherDisplayItems];
  NSMutableArray<NSString*> *filteredModel = [NSMutableArray new];

  for (SBDisplayItem *item in model) {
    if ([item.displayIdentifier isEqualToString:[[(SpringBoard*)[UIApplication sharedApplication] _accessibilityFrontMostApplication] bundleIdentifier]]) {
      continue;
    }

    for (NSString *bundleIdentifier in appPages) {
      if ([item.displayIdentifier isEqualToString:bundleIdentifier]) {
        goto skip;
      }
    }

    [filteredModel addObject:[item displayIdentifier]];
skip:
    continue;
  }

  return [filteredModel autorelease];
}

%end
