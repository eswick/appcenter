#import "SpringBoard.h"
#import "FrontBoard.h"
#import "FrontBoardServices.h"
#import "ControlCenterUI.h"
#import "ControlCenterUIKit.h"
#import "ManualLayout.h"
#import "SelectionPage.h"
#import "Tweak.h"

@interface ACAppPageView : UIView

@property (nonatomic, retain) NSString *appIdentifier;
@property (nonatomic, retain) UIView *touchBlockerView;
@property (nonatomic, assign) FBSceneHostWrapperView *hostView;

@end

@interface ACAppPageViewController : UIViewController <CCUIControlCenterPageContentProviding>

@property (nonatomic, retain) SBApplication *app;
@property (nonatomic, assign) id <CCUIControlCenterPageContentViewControllerDelegate> delegate;
@property (nonatomic, retain) FBSceneHostManager *sceneHostManager;
@property (nonatomic, retain) FBSceneHostWrapperView *hostView;
@property (nonatomic, assign) BOOL controlCenterTransitioning;
@property (nonatomic, retain) ACAppPageView *view;
@property (nonatomic, retain) UIImageView *appIconImageView;
@property (nonatomic, retain) CCUIControlCenterLabel *infoLabel;
@property (nonatomic, retain) UIActivityIndicatorView *appLoadingIndicator;
@property (nonatomic, assign) BOOL isBeingCreated;

- (id)initWithBundleIdentifier:(NSString*)bundleIdentifier;
- (void)controlCenterDidFinishTransition;
- (void)startSendingTouchesToApp;
- (void)reloadForUnlock;
- (void)setIsPageAnimating:(BOOL)value;

@end
