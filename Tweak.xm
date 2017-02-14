#pragma mark Includes & Defines

#import <notify.h>
#import <substrate.h>
#import "ControlCenterUI.h"
#import "SpringBoard.h"
#import "FrontBoard.h"
#import "FrontBoardServices.h"
#import "SelectionPage.h"
#import "Tweak.h"
#import "ManualLayout.h"
#import "AppPage.h"

#pragma mark Helpers

static void LoadPrefs() {
  CFPreferencesAppSynchronize(CFSTR(BUNDLEID_C));
  CFBooleanRef enabled = (CFBooleanRef)CFPreferencesCopyAppValue(CFSTR(PREFS_ENABLED_C), CFSTR(BUNDLEID_C));
  if (enabled) {
    isTweakEnabled = CFBooleanGetValue(enabled);
  }
  CFNumberRef aPSM = (CFNumberRef)CFPreferencesCopyAppValue(CFSTR(PREFS_APPPAGESCALE_C), CFSTR(BUNDLEID_C));
  if (aPSM) {
    appPageScaleMultiplier = [(NSNumber*)aPSM doubleValue];
  }
  CFBooleanRef iFR = (CFBooleanRef)CFPreferencesCopyAppValue(CFSTR(PREFS_ISFIRSTRUN_C), CFSTR(BUNDLEID_C));
  if (iFR) {
    isNotFirstRun = !CFBooleanGetValue(iFR);
  } else {
    isNotFirstRun = false;
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:@PREFS_CHANGE_ID object:nil];
}

static CGFloat DegreesToRadians(CGFloat degrees) {
  return degrees * M_PI / 180;
};

int rotationDegreesForInterfaceOrientation(UIInterfaceOrientation orientation) {
  int rotationDegrees;

  switch(orientation) {
    case UIInterfaceOrientationPortrait:
      rotationDegrees = 0;
      break;
    case UIInterfaceOrientationPortraitUpsideDown:
      rotationDegrees = 180;
      break;
    case UIInterfaceOrientationLandscapeLeft:
      rotationDegrees = 90;
      break;
    case UIInterfaceOrientationLandscapeRight:
      rotationDegrees = 270;
      break;
  }

  return rotationDegrees;
}

CGFloat rotationRadiansForInterfaceOrientation(UIInterfaceOrientation orientation) {
  return DegreesToRadians(rotationDegreesForInterfaceOrientation(orientation));
}

static CGAffineTransform transformToRect(CGRect sourceRect, CGRect finalRect, UIInterfaceOrientation viewRotation) {
    if (UIInterfaceOrientationIsLandscape(viewRotation)) {
      CGFloat width = finalRect.size.width;
      CGFloat y = finalRect.origin.y;

      finalRect.origin.y = finalRect.origin.x;
      finalRect.origin.x = y;

      finalRect.size.width = finalRect.size.height;
      finalRect.size.height = width;
    }

    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, -(CGRectGetMidX(sourceRect)-CGRectGetMidX(finalRect)), -(CGRectGetMidY(sourceRect)-CGRectGetMidY(finalRect)));
    transform = CGAffineTransformScale(transform, finalRect.size.width/sourceRect.size.width, finalRect.size.height/sourceRect.size.height);
    transform = CGAffineTransformRotate(transform, rotationRadiansForInterfaceOrientation(viewRotation));

    return transform;
}

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
      SBAppSwitcherModel *model = [%c(SBAppSwitcherModel) sharedInstance];
      SBApplication *application = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:[self bundleIdentifier]];
      [model addToFront:[model _displayItemForApplication:application] role:2];
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
BOOL isTweakEnabled = true;
CGFloat appPageScaleMultiplier = 1.0;
BOOL isNotFirstRun = false;

%hook CCUIFirstUsePanelViewController

- (void)viewDidLoad {
  %orig;
  MSHookIvar<UILabel*>(self, "_titleLabel").text = @"App Center";
  NSString *text = @"iPhone controls, Now Playing, and App Center each have their own cards.";
  MSHookIvar<UILabel*>(self, "_explanitoryText").text = text;
  //[MSHookIvar<UIButton*>(self, "_continueButton") setTitle:@"Open App Center" forState:UIControlStateNormal];
  MSHookIvar<UIImageView*>(self, "_lastPageGlyphImageView").transform = CGAffineTransformMakeScale(-1, 1);
}

- (void)_tappedContinueButton:(id)arg1 {
  [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SCROLL_TO_SELECTIONPAGE object:self];
  %orig;
}

%end

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
- (void)appcenter_displayFirstRunAlert {
  [[CCUIControlCenterDefaults standardDefaults] setHasAcknowledgedFirstUseAlert:false];
}

%new
- (void)appcenter_scrollToSelectionPage {
  [self scrollToPage:[self.contentViewControllers count] - 1 animated:true withCompletion:^(BOOL b){}];
}

%new
- (void)appcenter_savePages {
  CFPreferencesSetAppValue(CFSTR(PREFS_APPPAGES_C), appPages, CFSTR(BUNDLEID_C));
  CFPreferencesAppSynchronize(CFSTR(BUNDLEID_C));
}

- (void)_loadPages {
  LoadPrefs();
  if (!isTweakEnabled) {
    %orig;
    return;
  }
  if (!isNotFirstRun) {
    [self appcenter_displayFirstRunAlert];
    CFPreferencesSetAppValue(CFSTR(PREFS_ISFIRSTRUN_C), kCFBooleanFalse, CFSTR(BUNDLEID_C));
    CFPreferencesAppSynchronize(CFSTR(BUNDLEID_C));
  }

  %orig;

  CFNotificationCenterAddObserver(
    CFNotificationCenterGetDarwinNotifyCenter(),
    NULL,
    (CFNotificationCallback)LoadPrefs,
    CFSTR(PREFS_CHANGE_ID),
    NULL,
    CFNotificationSuspensionBehaviorCoalesce
  );

  snapshotViewCache = [NSMutableDictionary new];
  appPages = [NSMutableArray new];

  NSArray *savedPages = (NSArray*)CFPreferencesCopyAppValue(CFSTR(PREFS_APPPAGES_C), CFSTR(BUNDLEID_C));

  if (savedPages) {
    for (NSString *bundleID in savedPages) {
      [appPages addObject:bundleID];
      ACAppPageViewController *appPage = [[ACAppPageViewController alloc] initWithBundleIdentifier:bundleID];
      [self _addContentViewController:appPage];
    }
  }

  selectionViewController = [[ACAppSelectionPageViewController alloc] initWithNibName:nil bundle:nil];
  [self _addContentViewController:selectionViewController];
  [selectionViewController release];

  [self appcenter_registerForDetectingLockState];
}

%new
- (void)appcenter_registerForDetectingLockState {
  int notify_token;
  notify_register_dispatch("com.apple.springboard.lockstate", &notify_token,dispatch_get_main_queue(), ^(int token) {
    uint64_t state = UINT64_MAX;
    notify_get_state(token, &state);
    if (state == 0) { // unlocked
      [self appcenter_reloadForUnlock];
    }
  });
}

%new
- (void)appcenter_reloadForUnlock {
  if (selectionViewController) {
    [selectionViewController reloadForUnlock];
  }
  if ([self isPresented]) {
    for (UIViewController *contentViewController in [self contentViewControllers]) {
      if ([contentViewController isKindOfClass:[ACAppPageViewController class]]) {
        [(ACAppPageViewController*) contentViewController reloadForUnlock];
      }
    }
  }
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
          } else {
            [[[selectionViewController gridViewController] collectionView] reloadData];
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
  [appPage setIsPageAnimating:true];

  [self _removeContentViewController:selectionViewController];
  [self _addContentViewController:appPage];
  [self _addContentViewController:selectionViewController];
  [self _addOrRemovePagesBasedOnVisibility];

  reloadingControlCenter = true;
  [self controlCenterWillPresent];
  reloadingControlCenter = false;

  [self scrollToPage:[self.contentViewControllers count] - 1 animated:false withCompletion:^(BOOL b) {
    [appPage startSendingTouchesToApp];
  }];

  MSHookIvar<UIViewController*>(self, "_selectedViewController") = [self appcenter_containerViewControllerForContentView:appPage.view];
  [self _updatePageControl];

  [application appcenter_startBackgroundingWithCompletion:^(BOOL success) {
    dispatch_async(dispatch_get_main_queue(), ^{

      // darkening view fix
      CCUIBackgroundDarkeningWithPlatterCutoutView *darkeningView = [[%c(CCUIBackgroundDarkeningWithPlatterCutoutView) alloc] initWithFrame:[[UIScreen mainScreen] bounds] darkeningColor:[UIColor colorWithWhite:0 alpha:0.6] platterCornerRadius:10];

      UIView *platterView = [(UIView*)[[self pagePlatterViewsForContainerView:MSHookIvar<id>(self, "_containerView")] lastObject] superview];

      CGRect frame = darkeningView.frame;
      frame.origin.x = ([self.contentViewControllers count] - 1) * MSHookIvar<UIScrollView*>(self, "_pagesScrollView").frame.size.width;
      frame.origin.y = -platterView.superview.frame.origin.y;

      darkeningView.frame = frame;

      [MSHookIvar<UIView*>(self, "_pagesScrollView") addSubview:darkeningView];
      [MSHookIvar<UIView*>(self, "_pagesScrollView") sendSubviewToBack:darkeningView];

      [darkeningView release];

      FBSceneHostManager *sceneHostManager = [[application mainScene] contextHostManager];
      self.animationWrapperView = [sceneHostManager hostViewForRequester:ANIMATION_REQUESTER enableAndOrderFront:true];

      imageView.hidden = false;

      self.animationWrapperView.layer.cornerRadius = 10;
      self.animationWrapperView.transform = transformToRect(self.animationWrapperView.bounds, imageView.frame, application.statusBarOrientation);
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

        CGFloat scale = [ACManualLayout defaultAppPageScale]*appPageScaleMultiplier;
        CGRect toRect = CGRectApplyAffineTransform([[UIScreen mainScreen] bounds], CGAffineTransformMakeScale(scale, scale));
        toRect.origin = CGPointMake(CGRectGetMidX([[UIScreen mainScreen] bounds]) - (toRect.size.width / 2), CGRectGetMidY([[UIScreen mainScreen] bounds]) - (toRect.size.height / 2) - APP_PAGE_PADDING);

        self.animationWrapperView.transform = transformToRect(self.animationWrapperView.bounds, toRect, application.statusBarOrientation);
        self.animationWrapperView.alpha = 1;

      } completion:^(BOOL completed) {
        [[self.animationWrapperView.scene contextHostManager] disableHostingForRequester:ANIMATION_REQUESTER];
        [[self.animationWrapperView.scene contextHostManager] enableHostingForRequester:REQUESTER orderFront:true];
        [self.animationWrapperView removeFromSuperview];

        [darkeningView removeFromSuperview];

        [[NSNotificationCenter defaultCenter] postNotificationName:@"ACAppCellStopActivity" object:self];

        [[[selectionViewController gridViewController] collectionView] reloadData];
        [appPage setIsPageAnimating:false];
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
  [[NSNotificationCenter defaultCenter] addObserver:self
                                          selector:@selector(appcenter_scrollToSelectionPage)
                                              name:NOTIFICATION_SCROLL_TO_SELECTIONPAGE
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
    } completion:^(BOOL success) {
      CCUIControlCenterContainerView *containerView = MSHookIvar<CCUIControlCenterContainerView*>(self, "_containerView");
      [containerView _updateMasks];
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

      CCUIControlCenterContainerView *containerView = MSHookIvar<CCUIControlCenterContainerView*>(self, "_containerView");
      [containerView _updateMasks];
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
