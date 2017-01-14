#import "ControlCenterUI.h"
#import "ControlCenterUIKit.h"

@class ACAppIconCell;

@interface ACIconButton : CCUIControlCenterButton

@end

@interface ACAppIconCell : UICollectionViewCell <CCUIControlCenterButtonDelegate>

@property (nonatomic, retain) NSString *appIdentifier;
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) UIView *tintView;
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) CCUIControlCenterButton *button;

- (void)configureForApplication:(NSString*)appIdentifier;

@end

@interface ACAppSelectionGridViewController : UICollectionViewController

- (void)fixButtonEffects;

@end

@interface ACAppSelectionContainerView : UIView

@property (nonatomic, retain) ACIconButton *iconButton;
@property (nonatomic, retain) UILabel *titleLabel;

@end

@interface ACAppSelectionPageViewController : UIViewController <CCUIControlCenterPageContentProviding>

@property (nonatomic, retain) ACAppSelectionGridViewController *gridViewController;
@property (nonatomic, retain) ACAppSelectionContainerView *view;
@property (nonatomic, assign) ACAppIconCell *selectedCell;

@end
