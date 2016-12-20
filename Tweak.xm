#pragma mark Includes & Defines


#include <substrate.h>
#define REQUESTER @"com.eswick.appcenter"


#pragma mark Class Definitions


@interface CCUIControlCenterViewController : NSObject

- (void)_addContentViewController:(UIViewController*)arg1;

@end

@protocol CCUIControlCenterObserver
- (void)controlCenterDidFinishTransition;
- (void)controlCenterWillBeginTransition;
- (void)controlCenterDidDismiss;
- (void)controlCenterWillPresent;

@optional
- (void)controlCenterWillFinishTransitionOpen:(BOOL)arg1 withDuration:(NSTimeInterval)arg2;
@end

@protocol CCUIControlCenterPageContentProviding, CCUIControlCenterSystemAgent;
@protocol CCUIControlCenterPageContentViewControllerDelegate
- (void)endSuppressingPunchOutMaskCachingForReason:(NSString *)arg1;
- (void)beginSuppressingPunchOutMaskCachingForReason:(NSString *)arg1;
- (void)visibilityPreferenceChangedForContentViewController:(UIViewController<CCUIControlCenterPageContentProviding> *)arg1;
- (long long)layoutStyle;
- (id <CCUIControlCenterSystemAgent>)controlCenterSystemAgent;
- (void)contentViewControllerWantsDismissal:(UIViewController<CCUIControlCenterPageContentProviding> *)arg1;
@end

@protocol CCUIControlCenterPageContentProviding <CCUIControlCenterObserver>
@property (nonatomic, assign) id <CCUIControlCenterPageContentViewControllerDelegate> delegate;

@optional
@property(readonly, nonatomic) BOOL wantsVisible;
@property(readonly, nonatomic) struct UIEdgeInsets contentInsets;
- (void)controlCenterDidScrollToThisPage:(BOOL)arg1;
- (BOOL)dismissModalFullScreenIfNeeded;
@end

@protocol FBSceneClientProvider
- (void)endTransaction;
- (void)beginTransaction;
@end

@interface FBSSceneSettings : NSObject <NSMutableCopying>

@end

@interface FBSMutableSceneSettings : FBSSceneSettings

@property(nonatomic, getter=isBackgrounded) BOOL backgrounded;

@end

@interface FBSSettingsDiff : NSObject

@end

@interface FBSSceneSettingsDiff : FBSSettingsDiff

+ (id)diffFromSettings:(id)arg1 toSettings:(id)arg2;

@end

@class FBSSceneTransitionContext;

@protocol FBSceneClient
- (void)host:(id/* <FBSceneHost>*/)arg1 didUpdateSettings:(FBSSceneSettings *)arg2 withDiff:(FBSSceneSettingsDiff *)arg3 transitionContext:(FBSSceneTransitionContext *)arg4 completion:(void (^)(BOOL))arg5;
@end

@interface FBSceneHostWrapperView : UIView

@end

@interface FBSceneHostManager : NSObject

- (void)disableHostingForRequester:(NSString*)requester;
- (FBSceneHostWrapperView*)hostViewForRequester:(NSString*)requester enableAndOrderFront:(BOOL)arg2;

@end

@interface FBScene : NSObject

@property(readonly, retain, nonatomic) id <FBSceneClientProvider> clientProvider;
@property(readonly, retain, nonatomic) id <FBSceneClient> client;
@property(readonly, retain, nonatomic) FBSSceneSettings *settings;

- (FBSceneHostManager*)contextHostManager;

@end

extern NSString* FBSOpenApplicationOptionKeyActivateSuspended;

@interface FBSceneManager : NSObject

+ (FBSceneManager*)sharedInstance;
- (FBScene*)sceneWithIdentifier:(NSString*)identifier;

@end

@interface FBSSystemService : NSObject

+ (id)sharedService;
- (void)openApplication:(id)arg1 options:(id)arg2 withResult:(void (^)(void))arg3;

@end

@interface SBApplication : NSObject

- (FBScene*)mainScene;
- (NSString*)bundleIdentifier;
- (BOOL)isRunning;

// NEW
- (void)appcenter_setBackgrounded:(BOOL)backgrounded withCompletion:(void (^)(BOOL))completion;
- (void)appcenter_startBackgroundingWithCompletion:(void (^)(BOOL))completion;
- (void)appcenter_stopBackgroundingWithCompletion:(void (^)(BOOL))completion;

@end

@interface SBApplicationController : NSObject

+ (id)sharedInstance;
- (SBApplication*)applicationWithBundleIdentifier:(NSString*)bundleIdentifier;

@end


#pragma mark Implementations


@interface ACAppPageViewController : UIViewController <CCUIControlCenterPageContentProviding>

@property (nonatomic, retain) SBApplication *app;
@property (nonatomic, assign) id <CCUIControlCenterPageContentViewControllerDelegate> delegate;
@property (nonatomic, retain) FBSceneHostManager *sceneHostManager;
@property (nonatomic, retain) FBSceneHostWrapperView *hostView;
@property (nonatomic, assign) BOOL controlCenterOpening;

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

  if (self.controlCenterOpening) {
    self.controlCenterOpening = false;
    [self.app appcenter_startBackgroundingWithCompletion:^void(BOOL success) {
      dispatch_async(dispatch_get_main_queue(), ^{
        self.sceneHostManager = [[self.app mainScene] contextHostManager];
        self.hostView = [self.sceneHostManager hostViewForRequester:REQUESTER enableAndOrderFront:true];

        self.hostView.layer.cornerRadius = 10;
        self.hostView.layer.masksToBounds = true;

        CGFloat scale = self.view.bounds.size.width / [[UIScreen mainScreen] bounds].size.width;
        self.hostView.transform = CGAffineTransformMakeScale(scale, scale);

        [self.view addSubview:self.hostView];
      });
    }];
  }
}

- (void)controlCenterWillBeginTransition {

}

- (void)controlCenterDidDismiss {
  [self.sceneHostManager disableHostingForRequester:REQUESTER];
  [self.app appcenter_stopBackgroundingWithCompletion:nil];
}

- (void)controlCenterWillPresent {
  self.controlCenterOpening = true;
}

- (void)viewWillLayoutSubviews {
  CGPoint screenCenter = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height / 2);
  self.hostView.center = [self.view convertPoint:screenCenter fromView:[[UIApplication sharedApplication] keyWindow]];
}

- (void)loadView {
  [super loadView];
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

- (id)init {
  self = %orig;
  if (self) {
    [self _addContentViewController:[[ACAppPageViewController alloc] initWithBundleIdentifier:@"com.apple.mobilesafari"]];
  }
  return self;
}

%end
