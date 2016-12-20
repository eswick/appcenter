#pragma mark Includes & Defines

#include <substrate.h>
#define REQUESTER @"com.eswick.appcenter"

#pragma mark Class Definitions

#import "ControlCenterUI.h"
#import "SpringBoard.h"
#import "FrontBoard.h"
#import "FrontBoardServices.h"

@interface SBApplication ()

- (void)appcenter_setBackgrounded:(BOOL)backgrounded withCompletion:(void (^)(BOOL))completion;
- (void)appcenter_startBackgroundingWithCompletion:(void (^)(BOOL))completion;
- (void)appcenter_stopBackgroundingWithCompletion:(void (^)(BOOL))completion;

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
