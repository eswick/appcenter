#import "ControlCenterUI.h"
#import "ControlCenterUIKit.h"

@class ACAppIconCell;

@interface ACIconButton : CCUIControlCenterButton

@end

@protocol ACAppIconCellDelegate
- (void)appIconCell:(ACAppIconCell *)arg1 stateChanged:(long long)arg2;
@end

@interface ACAppIconCell : UICollectionViewCell <CCUIControlCenterButtonDelegate>

@property (nonatomic, retain) NSString *appIdentifier;
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) CCUIControlCenterButton *button;
@property (nonatomic, assign) id<ACAppIconCellDelegate> delegate;

- (void)loadIconForApplication:(NSString*)appIdentifier;

@end

@interface ACAppSelectionGridViewController : UICollectionViewController <ACAppIconCellDelegate>

- (void)fixButtonEffects;

@end

@interface ACAppSelectionContainerView : UIView

@property (nonatomic, retain) ACIconButton *iconButton;
@property (nonatomic, retain) UILabel *titleLabel;

@end

@interface ACAppSelectionPageViewController : UIViewController <CCUIControlCenterPageContentProviding>

@property (nonatomic, retain) ACAppSelectionGridViewController *gridViewController;
@property (nonatomic, retain) ACAppSelectionContainerView *view;

@end
