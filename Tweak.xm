#pragma mark Includes & Defines

#import <substrate.h>
#import "ControlCenterUI.h"
#import "SpringBoard.h"
#import "FrontBoard.h"
#import "FrontBoardServices.h"
#import "SelectionPage.h"
#import "Tweak.h"
#import "ManualLayout.h"

#pragma mark Constants

#define REQUESTER @"com.eswick.appcenter"
#define ANIMATION_REQUESTER @"com.eswick.appcenter.animation"
#define NOTIFICATION_REVEAL_ID @"com.eswick.appcenter.notification.revealpercentage"
#define SCROLL_BEGIN_ID @"com.eswick.appcenter.notification.scrollbegin"
#define SCROLL_END_ID @"com.eswick.appcenter.notification.scrollend"
#define APP_PAGE_PADDING 5.0
#define SCALE_MULTIPLIER 0.925
#define PREFS_PATH [[@"~/Library" stringByExpandingTildeInPath] stringByAppendingPathComponent:@"/Preferences/com.eswick.appcenter.plist"]

#pragma mark Helpers

static CGAffineTransform transformToRect(CGRect sourceRect, CGRect finalRect) {
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, -(CGRectGetMidX(sourceRect)-CGRectGetMidX(finalRect)), -(CGRectGetMidY(sourceRect)-CGRectGetMidY(finalRect)));
    transform = CGAffineTransformScale(transform, finalRect.size.width/sourceRect.size.width, finalRect.size.height/sourceRect.size.height);

    return transform;
}


#pragma mark Implementations

@interface ACAppPageView : UIView

@property (nonatomic, retain) NSString *appIdentifier;
@property (nonatomic, retain) UIView *touchBlockerView;
@property (nonatomic, assign) FBSceneHostWrapperView *hostView;

@end

@implementation ACAppPageView

- (id)init {
  self = [super init];
  if (self) {
    self.touchBlockerView = [[UIView alloc] init];
    self.touchBlockerView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.01];
    [self addSubview:self.touchBlockerView];
    [self.touchBlockerView release];
  }
  return self;
}

- (void)layoutSubviews {
  self.touchBlockerView.frame = self.hostView.frame;
  [self bringSubviewToFront:self.touchBlockerView];
}

@end

@interface ACAppPageViewController : UIViewController <CCUIControlCenterPageContentProviding>

@property (nonatomic, retain) SBApplication *app;
@property (nonatomic, assign) id <CCUIControlCenterPageContentViewControllerDelegate> delegate;
@property (nonatomic, retain) FBSceneHostManager *sceneHostManager;
@property (nonatomic, retain) FBSceneHostWrapperView *hostView;
@property (nonatomic, assign) BOOL controlCenterTransitioning;
@property (nonatomic, retain) ACAppPageView *view;
@property (nonatomic, retain) UIImageView *appIconImageView;
@property (nonatomic, retain) CCUIControlCenterLabel *lockedLabel;

- (id)initWithBundleIdentifier:(NSString*)bundleIdentifier;
- (void)controlCenterDidFinishTransition;
- (void)startSendingTouchesToApp;

@end

@implementation ACAppPageViewController
@synthesize delegate;
@dynamic view;

- (id)initWithBundleIdentifier:(NSString*)bundleIdentifier {
  self = [super init];
  if (self) {
    self.app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:bundleIdentifier];
    self.appIconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [%c(SBIconView) defaultIconImageSize].width, [%c(SBIconView) defaultIconImageSize].height)];
    SBIconModel *iconModel = [(SBIconController*)[%c(SBIconController) sharedInstance] model];
    SBIcon *icon = [iconModel expectedIconForDisplayIdentifier:bundleIdentifier];
    int iconFormat = [icon iconFormatForLocation:0];
    self.appIconImageView.image = [icon getCachedIconImage:iconFormat];
    [self.view addSubview:self.appIconImageView];
    self.appIconImageView.alpha = 0.0;
    [self.appIconImageView release];

    self.lockedLabel = [[CCUIControlCenterLabel alloc] initWithFrame:CGRectMake(0,0,300,15)];
    self.lockedLabel.text = [NSString stringWithFormat:@"Unlock to use %@", self.app.displayName];
    self.lockedLabel.textAlignment = NSTextAlignmentCenter;
    self.lockedLabel.font = [UIFont systemFontOfSize:[ACManualLayout appDisplayNameFontSize]];
    [self.lockedLabel setStyle:(unsigned long long) 2];//white text
    self.lockedLabel.alpha = 0.0;
    [self.view addSubview:self.lockedLabel];
    [self.lockedLabel release];

    if (!self.app) {
      return nil;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(controlCenterDidSetRevealPercentage:)
                                                 name:NOTIFICATION_REVEAL_ID
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(controlCenterDidBeginScrolling)
                                                 name:SCROLL_BEGIN_ID
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(controlCenterDidEndScrolling)
                                                 name:SCROLL_END_ID
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [super dealloc];
}

- (void)controlCenterDidFinishTransition {
  self.controlCenterTransitioning = false;
}

- (void)controlCenterWillBeginTransition {
  self.controlCenterTransitioning = true;
}

- (void)controlCenterDidBeginScrolling {
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startSendingTouchesToApp) object:self];

  self.view.touchBlockerView.hidden = false;
}

- (void)controlCenterDidEndScrolling {
  [self performSelector:@selector(startSendingTouchesToApp) withObject:self afterDelay:0.5];
}

- (void)stopSendingTouchesToApp {
  self.view.touchBlockerView.hidden = false;
}

- (void)startSendingTouchesToApp {
  self.view.touchBlockerView.hidden = true;
}

- (void)controlCenterDidSetRevealPercentage:(NSNotification*)notification {
  CGRect frame = self.hostView.frame;

  CGFloat openedY = [self.view convertPoint:CGPointMake(0, CGRectGetMidY([[UIScreen mainScreen] bounds])) fromView:[UIApplication sharedApplication].keyWindow].y - (frame.size.height / 2) - APP_PAGE_PADDING;
  CGFloat percentage = MIN(1.0, [[notification userInfo][@"revealPercentage"] floatValue]);

  frame.origin.y = openedY * percentage;
  self.appIconImageView.alpha = percentage;
  if ([(SpringBoard*)[%c(SpringBoard) sharedApplication] isLocked]) {
    self.lockedLabel.alpha = percentage;
  }

  self.hostView.frame = frame;
}

- (void)controlCenterDidDismiss {
  [self.sceneHostManager disableHostingForRequester:REQUESTER];

  if (![self.app.bundleIdentifier isEqualToString:[[(SpringBoard*)[%c(SpringBoard) sharedApplication] _accessibilityFrontMostApplication] bundleIdentifier]]) {
    [self.app appcenter_stopBackgroundingWithCompletion:nil];
  }
}

- (void)controlCenterWillPresent {
  [self.app appcenter_startBackgroundingWithCompletion:^void(BOOL success) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if ([self.app.bundleIdentifier isEqualToString:[[(SpringBoard*)[%c(SpringBoard) sharedApplication] _accessibilityFrontMostApplication] bundleIdentifier]]) {
        return;
      }

      self.sceneHostManager = [[self.app mainScene] contextHostManager];
      self.hostView = [self.sceneHostManager hostViewForRequester:REQUESTER enableAndOrderFront:true];

      self.hostView.layer.cornerRadius = 10;
      self.hostView.layer.masksToBounds = true;
      self.hostView.backgroundColor = [UIColor blackColor];

      CGFloat scale = self.view.bounds.size.width / [[UIScreen mainScreen] bounds].size.width;
      scale = scale * SCALE_MULTIPLIER;
      self.hostView.transform = CGAffineTransformMakeScale(scale, scale);

      self.hostView.alpha = 0.0;

      self.view.hostView = self.hostView;
      [self.view addSubview:self.hostView];

      [UIView animateWithDuration:0.25 animations:^{
        self.appIconImageView.alpha = 1.0;
        if (![(SpringBoard*)[%c(SpringBoard) sharedApplication] isLocked]) {
          self.hostView.alpha = 1.0;
          [self stopSendingTouchesToApp];
          [self performSelector:@selector(startSendingTouchesToApp) withObject:self afterDelay:0.6];
        }
      }];
    });
  }];
}

- (void)viewWillLayoutSubviews {
  CGRect frame = self.hostView.frame;

  frame.origin.x = CGRectGetMidX(self.view.bounds) - (self.hostView.frame.size.width / 2);

  if (self.controlCenterTransitioning) {
    frame.origin.y = 0;
  } else {
    frame.origin.y = [self.view convertPoint:CGPointMake(0, CGRectGetMidY([[UIScreen mainScreen] bounds])) fromView:[UIApplication sharedApplication].keyWindow].y - (frame.size.height / 2) - APP_PAGE_PADDING;
  }

  self.hostView.frame = frame;
  if ([(SpringBoard*)[%c(SpringBoard) sharedApplication] isLocked]) {
    self.appIconImageView.center = CGPointMake(self.view.center.x, [ACManualLayout ccEdgeSpacing]);
    self.lockedLabel.center = CGPointMake(self.view.center.x, [ACManualLayout ccEdgeSpacing]+16+self.appIconImageView.bounds.size.height/2);
  } else {
    self.appIconImageView.center = CGPointMake(self.view.center.x, 0);
  }
}

- (void)loadView {
  ACAppPageView *pageView = [[ACAppPageView alloc] init];
  self.view = pageView;
  self.view.appIdentifier = [self.app bundleIdentifier];
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
static BOOL filterPlatterViews = false;
BOOL reloadingControlCenter = false;

%hook CCUIControlCenterViewController

%property (nonatomic, retain) FBSceneHostWrapperView *animationWrapperView;

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

%new
- (void)appcenter_savePages {
  NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithContentsOfFile:PREFS_PATH];

  if (!dictionary) {
    dictionary = [NSMutableDictionary new];
  } else {
    [dictionary retain];
  }

  dictionary[@"appPages"] = [NSArray arrayWithArray:appPages];

  [dictionary writeToFile:PREFS_PATH atomically:true];

  [dictionary release];
}

- (void)_loadPages {
  %orig;
  snapshotViewCache = [NSMutableDictionary new];
  appPages = [NSMutableArray new];

  NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithContentsOfFile:PREFS_PATH];


  if (dictionary) {
    for (NSString *bundleID in dictionary[@"appPages"]) {
      [appPages addObject:bundleID];
      ACAppPageViewController *appPage = [[ACAppPageViewController alloc] initWithBundleIdentifier:bundleID];
      [self _addContentViewController:appPage];
    }
  }

  selectionViewController = [[ACAppSelectionPageViewController alloc] initWithNibName:nil bundle:nil];
  [self _addContentViewController:selectionViewController];
  [selectionViewController release];
}

%new
- (void)appcenter_appSelected:(NSString*)bundleIdentifier {

  if ([appPages containsObject:bundleIdentifier]) {

    for (UIViewController *contentViewController in [self contentViewControllers]) {
      if ([contentViewController isKindOfClass:[ACAppPageViewController class]]) {
        if ([[[(ACAppPageViewController*)contentViewController app] bundleIdentifier] isEqualToString:bundleIdentifier]) {

          ACAppPageViewController *appPageViewController = (ACAppPageViewController*)contentViewController;

          if (![bundleIdentifier isEqualToString:[[(SpringBoard*)[%c(SpringBoard) sharedApplication] _accessibilityFrontMostApplication] bundleIdentifier]]) {
            [[appPageViewController app] appcenter_stopBackgroundingWithCompletion:nil];
          }

          [appPageViewController.sceneHostManager disableHostingForRequester:REQUESTER];

          [self _removeContentViewController:contentViewController];
          [appPages removeObject:bundleIdentifier];
          [self appcenter_savePages];

          reloadingControlCenter = true;
          [self controlCenterWillPresent];
          reloadingControlCenter = false;
        }
      }
    }

    return;
  }

  [appPages addObject:bundleIdentifier];
  [self appcenter_savePages];

  SBApplication *application = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:bundleIdentifier];

  ACAppIconCell *selectedCell = selectionViewController.selectedCell;
  CGRect initialIconPosition = [selectedCell.imageView convertRect:selectedCell.imageView.bounds toView:self.view];

  SBIcon *icon = [[(SBIconController*)[%c(SBIconController) sharedInstance] model] expectedIconForDisplayIdentifier:bundleIdentifier];
  int iconFormat = [icon iconFormatForLocation:0];

  UIImageView *imageView = [[UIImageView alloc] initWithFrame:initialIconPosition];
  imageView.image = [icon getCachedIconImage:iconFormat];
  imageView.hidden = true;

  [self.view addSubview:imageView];

  ACAppPageViewController *appPage = [[ACAppPageViewController alloc] initWithBundleIdentifier:bundleIdentifier];
  appPage.appIconImageView.hidden = true;

  [self _removeContentViewController:selectionViewController];
  [self _addContentViewController:appPage];
  [self _addContentViewController:selectionViewController];

  reloadingControlCenter = true;
  [self controlCenterWillPresent];
  reloadingControlCenter = false;

  [self scrollToPage:[self.contentViewControllers count] - 1 animated:false withCompletion:^(BOOL b){
    [appPage startSendingTouchesToApp];
  }];

  MSHookIvar<UIViewController*>(self, "_selectedViewController") = [self appcenter_containerViewControllerForContentView:appPage.view];
  [self _updatePageControl];

  [application appcenter_startBackgroundingWithCompletion:^(BOOL success) {
    dispatch_async(dispatch_get_main_queue(), ^{

      FBSceneHostManager *sceneHostManager = [[application mainScene] contextHostManager];
      self.animationWrapperView = [sceneHostManager hostViewForRequester:ANIMATION_REQUESTER enableAndOrderFront:true];

      imageView.hidden = false;

      self.animationWrapperView.layer.cornerRadius = 10;
      self.animationWrapperView.transform = transformToRect(self.animationWrapperView.bounds, imageView.frame);
      self.animationWrapperView.alpha = 0;
      self.animationWrapperView.clipsToBounds = true;
      [self.view addSubview:self.animationWrapperView];

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

        CGFloat scale = platterView.bounds.size.width / [[UIScreen mainScreen] bounds].size.width;
        scale = scale * SCALE_MULTIPLIER;
        CGRect toRect = CGRectApplyAffineTransform([[UIScreen mainScreen] bounds], CGAffineTransformMakeScale(scale, scale));
        toRect.origin = CGPointMake(CGRectGetMidX([[UIScreen mainScreen] bounds]) - (toRect.size.width / 2), CGRectGetMidY([[UIScreen mainScreen] bounds]) - (toRect.size.height / 2) - APP_PAGE_PADDING);

        self.animationWrapperView.transform = transformToRect(self.animationWrapperView.bounds, toRect);
        self.animationWrapperView.alpha = 1;

      } completion:^(BOOL completed) {
        [[self.animationWrapperView.scene contextHostManager] disableHostingForRequester:ANIMATION_REQUESTER];
        [[self.animationWrapperView.scene contextHostManager] enableHostingForRequester:REQUESTER orderFront:true];
        [self.animationWrapperView removeFromSuperview];

        [[NSNotificationCenter defaultCenter] postNotificationName:@"ACAppCellStopActivity" object:self];

        [[[selectionViewController gridViewController] collectionView] reloadData];
        appPage.appIconImageView.hidden = false;
      }];
    });
  }];


  [imageView release];
  [appPage release];
}

%new
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  [[NSNotificationCenter defaultCenter] postNotificationName:SCROLL_BEGIN_ID object:self];
}

%new
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  [[NSNotificationCenter defaultCenter] postNotificationName:SCROLL_END_ID object:self];
}

- (void)viewDidLoad {
  %orig;

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillHide:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];
}

- (void)viewWillLayoutSubviews {
  if (!selectionViewController.searching) {
    %orig;
  }
}

%new
- (void)keyboardWillShow:(NSNotification*)notification {
  CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
  [[NSNotificationCenter defaultCenter] postNotificationName:@"KeyboardWillShow" object:nil];

  UIViewController *containerVC = [self appcenter_containerViewControllerForContentView:selectionViewController.view];

  if (selectionViewController.searching) {
    [UIView animateWithDuration:0.5 animations:^{
      CGRect frame = containerVC.view.frame;
      CGFloat maxMove = -[self.view convertPoint:[containerVC.view convertPoint:containerVC.view.frame.origin toView:nil] fromView:nil].y;
      frame.origin.y = [ACManualLayout ccEdgeSpacing] + MAX(-keyboardSize.height, maxMove);
      containerVC.view.frame = frame;
    }];
  }
}

%new
- (void)keyboardWillHide:(NSNotification*)notification {
  UIViewController *containerVC = [self appcenter_containerViewControllerForContentView:selectionViewController.view];
  if (containerVC.view.frame.origin.y != 0) {
    [UIView animateWithDuration:0.5 animations:^{
      CGRect frame = containerVC.view.frame;
      frame.origin.y = 0;
      containerVC.view.frame = frame;
    }];
  }
}

%new
- (CCUIControlCenterPageContainerViewController*)appcenter_containerViewControllerForContentView:(UIView*)contentView {
  NSArray *pageContainers = MSHookIvar<NSArray*>(self, "_allPageContainerViewControllers");

  for (CCUIControlCenterPageContainerViewController *vc in pageContainers) {
    if (vc.contentViewController.view == contentView) {
      return vc;
    }
  }

  return nil;
}

%end

%hook CCUIControlCenterContainerView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  if (!selectionViewController.searching) {
    return %orig;
  }

  CGPoint pointInView = [self convertPoint:point toView:selectionViewController.view];

  return [selectionViewController.view hitTest:pointInView withEvent:event];
}

- (void)_updateMasks {
  filterPlatterViews = true;
  %orig;
  filterPlatterViews = false;
}

- (void)setRevealPercentage:(CGFloat)revealPercentage {
  [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_REVEAL_ID object:nil userInfo:@{ @"revealPercentage" : @(revealPercentage) }];
  %orig;
}

- (void)controlCenterWillPresent {
  %orig;

  NSArray *platterViews = [[self delegate] pagePlatterViewsForContainerView:self];

  for (CCUIControlCenterPagePlatterView *platterView in platterViews) {
    [platterView layoutSubviews];
  }
}

%end

%hook CCUIControlCenterPagePlatterView

- (void)layoutSubviews {
  if ([self.contentView isKindOfClass:[ACAppPageView class]]) {
    if ([[(ACAppPageView*)self.contentView appIdentifier] isEqualToString:[[(SpringBoard*)[%c(SpringBoard) sharedApplication] _accessibilityFrontMostApplication] bundleIdentifier]]) {
      MSHookIvar<UIView*>(self, "_baseMaterialView").hidden = false;
      MSHookIvar<UIView*>(self, "_whiteLayerView").hidden = false;
      %orig;
      return;
    }
    MSHookIvar<UIView*>(self, "_baseMaterialView").hidden = true;
    MSHookIvar<UIView*>(self, "_whiteLayerView").hidden = true;
  } else {
    %orig;
  }
}

- (void)_recursivelyVisitSubviewsOfView:(id)arg1 forPunchedThroughView:(id)arg2 collectingMasksIn:(id)arg3 {
  if ([self.contentView isKindOfClass:[ACAppPageView class]]) {
    if ([[(ACAppPageView*)self.contentView appIdentifier] isEqualToString:[[(SpringBoard*)[%c(SpringBoard) sharedApplication] _accessibilityFrontMostApplication] bundleIdentifier]]) {
      %orig;
    }
    return;
  }

  %orig;
}

%end

%hook SBAppSwitcherModel

%property (nonatomic, retain) NSMutableArray *recentAppIdentifiers;

- (id)initWithUserDefaults:(id)arg1 andIconController:(id)arg2 andApplicationController:(id)arg3 {
  self = %orig;
  if (self) {
    self.recentAppIdentifiers = [NSMutableArray new];
    NSMutableArray* recentDisplayItems = MSHookIvar<NSMutableArray*>(self, "_recentDisplayItems");

    for (SBDisplayItem *item in recentDisplayItems) {
      [self.recentAppIdentifiers addObject:item.displayIdentifier];
    }

    [self.recentAppIdentifiers release];
  }
  return self;
}

- (void)_applicationActivationStateDidChange:(SBApplication*)arg1 withLockScreenViewController:(id)arg2 andLayoutElement:(id)arg3 {
  %orig;

  if ([arg1 isActivating]) {
    if ([self.recentAppIdentifiers containsObject:[arg1 bundleIdentifier]]) {
      [self.recentAppIdentifiers removeObject:[arg1 bundleIdentifier]];
    }
    [self.recentAppIdentifiers addObject:[arg1 bundleIdentifier]];
  }
}

%new
- (NSArray<NSString*>*)appcenter_model {
  NSArray<NSString*>* model = [self.recentAppIdentifiers subarrayWithRange:NSMakeRange(0, MIN(9, [self.recentAppIdentifiers count]))];
  NSMutableArray<NSString*> *filteredModel = [NSMutableArray new];

  for (NSString *displayIdentifier in model) {
    if ([displayIdentifier isEqualToString:[[(SpringBoard*)[UIApplication sharedApplication] _accessibilityFrontMostApplication] bundleIdentifier]]) {
      continue;
    }

    SBApplication *application = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:displayIdentifier];

    if (![snapshotViewCache objectForKey:displayIdentifier]) {
      SBAppSwitcherSnapshotView *snapshotView = [%c(SBAppSwitcherSnapshotView) appSwitcherSnapshotViewForDisplayItem:[self _displayItemForApplication:application] orientation:UIInterfaceOrientationPortrait preferringDownscaledSnapshot:true loadAsync:false withQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
      snapshotView.layer.cornerRadius = 10;
      snapshotView.clipsToBounds = true;
      snapshotViewCache[displayIdentifier] = snapshotView;
    }

    for (NSString *bundleIdentifier in appPages) {
      if ([displayIdentifier isEqualToString:bundleIdentifier]) {
        goto skip;
      }
    }

    [filteredModel addObject:displayIdentifier];
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
