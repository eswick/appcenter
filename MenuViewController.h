#import "ControlCenterUI.h"
#import "ControlCenterUIKit.h"


@protocol ACMenuViewControllerDelegate

-(void)closeAllPagesButtonTapped;
-(void)closeAllAppsButtonTapped;

@end

@interface ACMenuViewController : UIViewController <CCUIControlCenterButtonDelegate>

@property (nonatomic, retain) NSObject<ACMenuViewControllerDelegate> *menuDelegate;
@property (nonatomic, retain) CCUIControlCenterButton *closeAllPagesButton;
@property (nonatomic, retain) CCUIControlCenterButton *closeAllAppsButton;

@end
