#include <UIKit/UIKit.h>

@interface CCUIControlCenterViewController : UIViewController

- (void)_addContentViewController:(UIViewController*)arg1;
- (void)_removeContentViewController:(UIViewController*)arg1;
- (void)_loadPages;
- (id)contentViewControllers;
- (void)_updatePageControl;
- (void)_updateScrollViewContentSize;
- (void)_layoutScrollView;
- (void)controlCenterWillPresent;
- (void)scrollViewDidEndDecelerating:(id)arg1;
- (id)sortedVisibleViewControllers;
- (void)_addOrRemovePagesBasedOnVisibility;
- (void)scrollToPage:(unsigned long long)arg1 animated:(BOOL)arg2 withCompletion:(void(^)(BOOL))completion;

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

@interface CCUIControlCenterPagePlatterView : UIView

@property(retain, nonatomic) UIView *contentView;

@end

@interface CCUIControlCenterPageContainerViewController : UIViewController
@property(readonly, nonatomic) UIViewController<CCUIControlCenterPageContentProviding> *contentViewController;
@end

@class CCUIControlCenterButton;

@protocol CCUIControlCenterButtonDelegate
- (BOOL)isInternal;
- (void)buttonTapped:(CCUIControlCenterButton *)arg1;

@optional
- (void)button:(CCUIControlCenterButton *)arg1 didChangeState:(long long)arg2;
@end

@interface CCUIControlCenterViewController (AppCenter)

- (void)appcenter_appSelected:(NSString*)bundleIdentifier;
- (CCUIControlCenterPageContainerViewController*)appcenter_containerViewControllerForContentView:(UIView*)contentView;

@end
