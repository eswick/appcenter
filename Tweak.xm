#pragma mark Includes & Defines

#include <substrate.h>
#define REQUESTER @"com.eswick.appcenter"

#pragma mark Class Definitions

#import "ControlCenterUI.h"
#import "SpringBoard.h"
#import "FrontBoard.h"
#import "FrontBoardServices.h"

@interface SBAppSwitcherModel ()

- (NSArray<NSString*>*)appcenter_model;

@end

@interface SBApplication ()

- (void)appcenter_setBackgrounded:(BOOL)backgrounded withCompletion:(void (^)(BOOL))completion;
- (void)appcenter_startBackgroundingWithCompletion:(void (^)(BOOL))completion;
- (void)appcenter_stopBackgroundingWithCompletion:(void (^)(BOOL))completion;

@end

@interface CCUIControlCenterViewController ()

- (void)appcenter_appSelected:(NSString*)bundleIdentifier;

@end

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


@interface ACAppIconCell : UICollectionViewCell

@property (nonatomic, retain) NSString *appIdentifier;
@property (nonatomic, retain) UIImageView *imageView;

- (void)loadIconForApplication:(NSString*)appIdentifier;

@end

@implementation ACAppIconCell

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [%c(SBIconView) defaultIconImageSize].width, [%c(SBIconView) defaultIconImageSize].height)];
    [self.contentView addSubview:self.imageView];
    [self.imageView release];

    CGPoint center = self.imageView.center;
    center.x = self.bounds.size.width / 2;
    self.imageView.center = center;
  }
  return self;
}

- (void)loadIconForApplication:(NSString*)appIdentifier {
  self.appIdentifier = appIdentifier;

  SBIconModel *iconModel = [(SBIconController*)[%c(SBIconController) sharedInstance] model];
  SBIcon *icon = [iconModel expectedIconForDisplayIdentifier:appIdentifier];
  int iconFormat = [icon iconFormatForLocation:0x0];

  self.imageView.image = [icon getCachedIconImage:iconFormat];
}

@end

@interface ACAppSelectionPageViewController : UIViewController <CCUIControlCenterPageContentProviding, UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, retain) UICollectionView *collectionView;
@property (nonatomic, assign) id <CCUIControlCenterPageContentViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL controlCenterIsOpening;

@end

@implementation ACAppSelectionPageViewController

- (CGSize)defaultCellSize {
  return CGSizeMake(75, 75);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

  int cellsPerRow = self.view.bounds.size.width / [self defaultCellSize].width;
  int totalRows = self.view.bounds.size.height / [self defaultCellSize].height;

  return MIN([[[%c(SBAppSwitcherModel) sharedInstance] appcenter_model] count], cellsPerRow * totalRows);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  ACAppIconCell *cell = (ACAppIconCell*)[self.collectionView dequeueReusableCellWithReuseIdentifier:@"AppIconCell" forIndexPath:indexPath];

  NSString *appIdentifier = [[%c(SBAppSwitcherModel) sharedInstance] appcenter_model][indexPath.row];
  [cell loadIconForApplication:appIdentifier];

  return cell;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0.0, 20.0, 0.0, 20.0);
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  CCUIControlCenterViewController *ccViewController = (CCUIControlCenterViewController*)self.parentViewController.parentViewController;
  [ccViewController appcenter_appSelected:[[%c(SBAppSwitcherModel) sharedInstance] appcenter_model][indexPath.row]];
}

- (void)loadView {

  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.itemSize = [self defaultCellSize];

  self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];

  self.collectionView.delegate = self;
  self.collectionView.dataSource = self;

  self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  self.collectionView.translatesAutoresizingMaskIntoConstraints = true;
  self.collectionView.backgroundColor = [UIColor clearColor];

  [self.collectionView registerClass:[ACAppIconCell class] forCellWithReuseIdentifier:@"AppIconCell"];
  self.view = self.collectionView;

  [layout release];
}

- (void)viewWillLayoutSubviews {

}

- (void)controlCenterWillPresent {
  self.controlCenterIsOpening = true;
}

- (void)controlCenterDidFinishTransition {
  self.controlCenterIsOpening = false;
}

- (void)controlCenterWillBeginTransition {
  if (self.controlCenterIsOpening) {
    [self.collectionView reloadData];
  }
}

- (void)controlCenterDidDismiss {

}

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

%hook CCUIControlCenterViewController

static NSMutableArray<NSString*> *appPages = nil; // TODO: Make this an instance variable with associated objects

- (void)_loadPages {
  %orig;
  ACAppSelectionPageViewController *pageViewController = [[ACAppSelectionPageViewController alloc] initWithNibName:nil bundle:nil];
  [self _addContentViewController:pageViewController];
  [pageViewController release];
}

%new
- (void)appcenter_appSelected:(NSString*)bundleIdentifier {
  if (!appPages) {
    appPages = [NSMutableArray new];
  }

  [appPages addObject:bundleIdentifier];

  for (UIViewController *contentViewController in [self contentViewControllers]) {
    if ([contentViewController isKindOfClass:[ACAppSelectionPageViewController class]]) {
      [UIView animateWithDuration:0.25 animations:^{
        contentViewController.view.alpha = 0;
      } completion:^(BOOL completed){
        [self _removeContentViewController:contentViewController];

        [[(ACAppSelectionPageViewController*)contentViewController collectionView] reloadData];

        contentViewController.view.alpha = 1;

        SBApplication *application = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:bundleIdentifier];
        [application appcenter_startBackgroundingWithCompletion:^(BOOL success) {
          dispatch_async(dispatch_get_main_queue(), ^{
            ACAppPageViewController *appPage = [[ACAppPageViewController alloc] initWithBundleIdentifier:bundleIdentifier];
            [self _addContentViewController:appPage];
            [self _addContentViewController:contentViewController];

            [self controlCenterWillPresent];
            MSHookIvar<UIViewController*>(self, "_selectedViewController") = appPage;
          });
        }];
      }];

      break;
    }
  }
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
