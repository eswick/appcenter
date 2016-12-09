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

@interface FBSceneHostWrapperView : UIView

@end

@interface FBSceneHostManager : NSObject

- (void)disableHostingForRequester:(NSString*)requester;
- (FBSceneHostWrapperView*)hostViewForRequester:(NSString*)requester enableAndOrderFront:(BOOL)arg2;

@end

@interface FBScene : NSObject

- (FBSceneHostManager*)contextHostManager;

@end

@interface SBApplication : NSObject

- (FBScene*)mainScene;

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
}

- (void)controlCenterWillPresent {
  self.sceneHostManager = [[self.app mainScene] contextHostManager];
  self.hostView = [self.sceneHostManager hostViewForRequester:REQUESTER enableAndOrderFront:true];

  CGFloat scale = self.view.bounds.size.width / [[UIScreen mainScreen] bounds].size.width;
  scale -= 0.05;
  self.hostView.transform = CGAffineTransformMakeScale(scale, scale);

  [self.view addSubview:self.hostView];
}

- (void)viewWillLayoutSubviews {
  self.hostView.center = CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2);
}

- (void)loadView {
  [super loadView];
}

- (void)viewWillAppear:(BOOL)arg1 {
  [super viewWillAppear:arg1];
}

@end


#pragma mark Hooks


%hook CCUIControlCenterViewController

- (id)init {
  self = %orig;
  if (self) {
    [self _addContentViewController:[[ACAppPageViewController alloc] initWithBundleIdentifier:@"com.apple.mobilesafari"]];
  }
  return self;
}

%end
