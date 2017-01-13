#pragma mark Includes & Defines

#include <substrate.h>
#define REQUESTER @"com.eswick.appcenter"

#import "ControlCenterUI.h"
#import "SpringBoard.h"
#import "FrontBoard.h"
#import "FrontBoardServices.h"
#import "SelectionPage.h"
#import "Tweak.h"

#pragma mark Helpers

static CGAffineTransform transformToRect(CGRect sourceRect, CGRect finalRect) {
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, -(CGRectGetMidX(sourceRect)-CGRectGetMidX(finalRect)), -(CGRectGetMidY(sourceRect)-CGRectGetMidY(finalRect)));
    transform = CGAffineTransformScale(transform, finalRect.size.width/sourceRect.size.width, finalRect.size.height/sourceRect.size.height);

    return transform;
}


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
      self.hostView.backgroundColor = [UIColor blackColor];

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
NSMutableDictionary<NSString*, SBAppSwitcherSnapshotView*> *snapshotViewCache = nil;
static BOOL animatingAppLaunch = false;
static BOOL waitingForAppLaunch = false;
static BOOL filterPlatterViews = false;

%hook CCUIControlCenterViewController


- (id)pagePlatterViewsForContainerView:(id)arg1 {
  if (filterPlatterViews) {
    NSArray *result = %orig;
    NSMutableArray *mutableResult = [result mutableCopy];
    NSMutableArray *platterViewsToRemove = [NSMutableArray new];

    for (CCUIControlCenterPagePlatterView *platterView in mutableResult) {
      if ([platterView.contentView isKindOfClass:[ACAppPageView class]]) {
        [platterViewsToRemove addObject:platterView];
      }
    }

    for (CCUIControlCenterPagePlatterView *platterView in platterViewsToRemove) {
      [mutableResult removeObject:platterView];
    }

    [platterViewsToRemove release];

    return [mutableResult autorelease];

  } else {
    return %orig;
  }
}

- (void)_loadPages {
  %orig;
  snapshotViewCache = [NSMutableDictionary new];
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

          //[[[selectionViewController gridViewController] collectionView] reloadSections:[NSIndexSet indexSetWithIndex:0]];
          //[[selectionViewController gridViewController] fixButtonEffects];
        }
      }
    }

    return;
  }

  [appPages addObject:bundleIdentifier];

  SBApplication *application = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:bundleIdentifier];

  ACAppIconCell *selectedCell = selectionViewController.selectedCell;
  CGRect initialIconPosition = [selectedCell.imageView convertRect:selectedCell.imageView.bounds toView:self.view];

  SBIcon *icon = [[(SBIconController*)[%c(SBIconController) sharedInstance] model] expectedIconForDisplayIdentifier:bundleIdentifier];
  int iconFormat = [icon iconFormatForLocation:0];

  UIImageView *imageView = [[UIImageView alloc] initWithFrame:initialIconPosition];
  imageView.image = [icon getCachedIconImage:iconFormat];

  [self.view addSubview:imageView];

  ACAppPageViewController *appPage = [[ACAppPageViewController alloc] initWithBundleIdentifier:bundleIdentifier];

  [self _removeContentViewController:selectionViewController];
  [self _addContentViewController:appPage];
  [self _addContentViewController:selectionViewController];
  [self controlCenterWillPresent];
  [self scrollToPage:[self.contentViewControllers count] - 1 animated:false withCompletion:nil];

  SBAppSwitcherSnapshotView *snapshotView = snapshotViewCache[bundleIdentifier];

  snapshotView.transform = transformToRect(snapshotView.bounds, imageView.frame);
  snapshotView.alpha = 0;
  [self.view addSubview:snapshotView];

  appPage.view.alpha = 0;

  void (^animationComplete)(void) = ^{
    dispatch_async(dispatch_get_main_queue(), ^{
      appPage.view.alpha = 1;

      [UIView animateWithDuration:0.25
                            delay:0
                          options:UIViewAnimationCurveEaseInOut
                       animations:^{
                         snapshotView.alpha = 0;
                     } completion:^(BOOL finished) {
                         [snapshotView removeFromSuperview];
                     }];

      [[[selectionViewController gridViewController] collectionView] reloadData];
      [[selectionViewController gridViewController] fixButtonEffects];
    });
  };

  animatingAppLaunch = true;
  waitingForAppLaunch = true;

  [UIView animateWithDuration:0.5
                        delay:0
                      options:UIViewAnimationCurveEaseInOut
                   animations:^{
    UIScrollView *pagesScrollView = MSHookIvar<UIScrollView*>(self, "_pagesScrollView");
    pagesScrollView.contentOffset = CGPointMake(pagesScrollView.frame.size.width * ([self.contentViewControllers count] - 2), 0);

    imageView.transform = CGAffineTransformMakeScale(5.0, 5.0);
    imageView.center = CGPointMake([[UIScreen mainScreen] bounds].size.width / 2, [[UIScreen mainScreen] bounds].size.height / 2);
    imageView.alpha = 0;

    UIView *platterView = [MSHookIvar<NSArray<UIViewController*>*>(self, "_allPageContainerViewControllers")[0] view];

    // FIXME: Position snapshot view properly (close enough for now)

    CGFloat scale = platterView.bounds.size.width / [[UIScreen mainScreen] bounds].size.width;
    CGRect toRect = CGRectApplyAffineTransform([[UIScreen mainScreen] bounds], CGAffineTransformMakeScale(scale, scale));
    toRect.origin = CGPointMake(CGRectGetMidX([[UIScreen mainScreen] bounds]) - (toRect.size.width / 2), CGRectGetMidY([[UIScreen mainScreen] bounds]) - (toRect.size.height / 2));

    snapshotView.transform = transformToRect(snapshotView.bounds, toRect);
    snapshotView.alpha = 1;

  } completion:^(BOOL completed) {
    animatingAppLaunch = false;
    if (!waitingForAppLaunch) {
      animationComplete();
    }
  }];

  [application appcenter_startBackgroundingWithCompletion:^(BOOL success) {
    waitingForAppLaunch = false;
    if (!animatingAppLaunch) {
      animationComplete();
    }
  }];

  [imageView release];
  [appPage release];
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

%hook CCUIControlCenterContainerView

- (void)_updateMasks {
  filterPlatterViews = true;
  %orig;
  filterPlatterViews = false;
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
  NSArray<SBDisplayItem*>* model = [[self mainSwitcherDisplayItems] subarrayWithRange:NSMakeRange(0, MIN(9, [[self mainSwitcherDisplayItems] count]))];
  NSMutableArray<NSString*> *filteredModel = [NSMutableArray new];

  for (SBDisplayItem *item in model) {
    if ([item.displayIdentifier isEqualToString:[[(SpringBoard*)[UIApplication sharedApplication] _accessibilityFrontMostApplication] bundleIdentifier]]) {
      continue;
    }

    if (![snapshotViewCache objectForKey:[item displayIdentifier]]) {
      SBAppSwitcherSnapshotView *snapshotView = [%c(SBAppSwitcherSnapshotView) appSwitcherSnapshotViewForDisplayItem:item orientation:UIInterfaceOrientationPortrait preferringDownscaledSnapshot:true loadAsync:false withQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
      snapshotView.layer.cornerRadius = 10;
      snapshotView.clipsToBounds = true;
      snapshotViewCache[[item displayIdentifier]] = snapshotView;
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

  NSMutableArray *unfilteredModel = [NSMutableArray new];
  [unfilteredModel addObjectsFromArray:appPages];
  [unfilteredModel addObjectsFromArray:filteredModel];

  for (NSString *identifier in [snapshotViewCache allKeys]) {
    if (![unfilteredModel containsObject:identifier]) {
      [snapshotViewCache removeObjectForKey:identifier];
    }
  }

  [unfilteredModel release];

  return [filteredModel autorelease];
}

%end
