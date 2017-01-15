#import "ControlCenterUI.h"
#import "ControlCenterUIKit.h"

@class ACAppIconCell;

@interface ACSearchButton : UIButton

@end

@interface ACIconButton : CCUIControlCenterButton

@end

@interface ACAppIconCell : UICollectionViewCell <CCUIControlCenterButtonDelegate>

@property (nonatomic, retain) NSString *appIdentifier;
@property (nonatomic, retain) UIImageView *imageView;
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
@property (nonatomic, retain) UIButton *searchButton;
@property (nonatomic, retain) UISearchBar *searchBar;

@end

@interface ACAppSelectionPageViewController : UIViewController <CCUIControlCenterPageContentProviding, UISearchBarDelegate>

@property (nonatomic, retain) ACAppSelectionGridViewController *gridViewController;
@property (nonatomic, retain) ACAppSelectionContainerView *view;
@property (nonatomic, assign) ACAppIconCell *selectedCell;
@property (nonatomic, assign) BOOL searching;

- (void)beginSearching;
- (void)endSearching;

@end
