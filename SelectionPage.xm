#import "SelectionPage.h"
#import "SpringBoard.h"

@implementation ACIconButton

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    UIImage *image = [UIImage imageWithContentsOfFile:@"/Library/Application Support/App Center/appcenter@2x.png"];
    [self setGlyphImage:image selectedGlyphImage:image name:@"ACIconButton"];
  }
  return self;
}

- (CGSize)intrinsicContentSize {
  return CGSizeMake(25, 25);
}

@end

@implementation ACAppIconCell

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {

    self.contentView.layer.cornerRadius = 12;

    CCUIControlCenterButton *button = [CCUIControlCenterButton roundRectButton];

    button.delegate = self;
    button.animatesStateChanges = true;
    button.translatesAutoresizingMaskIntoConstraints = false;

    [self.contentView addSubview:button];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[button]|" options:nil metrics:nil views:@{ @"button" : button }]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[button]|" options:nil metrics:nil views:@{ @"button" : button }]];

    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [%c(SBIconView) defaultIconImageSize].width * 0.80, [%c(SBIconView) defaultIconImageSize].height * 0.80)];
    self.imageView.center = CGPointMake(self.contentView.bounds.size.width / 2, (self.contentView.bounds.size.height * 0.80) / 2);
    [button addSubview:self.imageView];
    [self.imageView release];

    CGPoint center = self.imageView.center;
    center.x = self.bounds.size.width / 2;
    self.imageView.center = center;

    self.titleLabel = [[CCUIControlCenterLabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.adjustsFontSizeToFitWidth = false;
    self.titleLabel.font = [UIFont systemFontOfSize:13];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = false;

    [button addSubview:self.titleLabel];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label]|" options:nil metrics:nil views:@{ @"label" : self.titleLabel }]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[imageView][label]|" options:nil metrics:nil views:@{ @"label" : self.titleLabel, @"imageView" : self.imageView }]];
  }
  return self;
}

- (id)controlCenterSystemAgent {
  return nil;
}

- (void)buttonTapped:(CCUIControlCenterButton *)arg1 {
  [self.delegate appIconCell:self stateChanged:[arg1 _currentState]];
}

- (BOOL)isInternal {
  return false;
}

- (void)loadIconForApplication:(NSString*)appIdentifier {
  self.appIdentifier = appIdentifier;

  SBIconModel *iconModel = [(SBIconController*)[%c(SBIconController) sharedInstance] model];
  SBIcon *icon = [iconModel expectedIconForDisplayIdentifier:appIdentifier];
  int iconFormat = [icon iconFormatForLocation:0];

  self.imageView.image = [icon getCachedIconImage:iconFormat];

  self.titleLabel.text = [[[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:self.appIdentifier] displayName];
}

@end

@implementation ACAppSelectionGridViewController

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return MIN([[[%c(SBAppSwitcherModel) sharedInstance] appcenter_model] count], 9);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  ACAppIconCell *cell = (ACAppIconCell*)[self.collectionView dequeueReusableCellWithReuseIdentifier:@"AppIconCell" forIndexPath:indexPath];

  cell.delegate = self;

  NSString *appIdentifier = [[%c(SBAppSwitcherModel) sharedInstance] appcenter_model][indexPath.row];
  [cell loadIconForApplication:appIdentifier];

  return cell;
}

- (void)appIconCell:(ACAppIconCell*)appIconCell stateChanged:(long long)state {
  CCUIControlCenterViewController *ccViewController = (CCUIControlCenterViewController*)self.parentViewController.parentViewController.parentViewController;
  [ccViewController appcenter_appSelected:appIconCell.appIdentifier];
}

- (void)loadView {

  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.itemSize = CGSizeMake(80, 80);

  self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];

  self.collectionView.delegate = self;
  self.collectionView.dataSource = self;

  self.collectionView.translatesAutoresizingMaskIntoConstraints = false;
  self.collectionView.backgroundColor = [UIColor clearColor];

  [self.collectionView registerClass:[ACAppIconCell class] forCellWithReuseIdentifier:@"AppIconCell"];
  self.view = self.collectionView;

  [layout release];
}

@end

@implementation ACAppSelectionContainerView

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.translatesAutoresizingMaskIntoConstraints = false;

    ACIconButton *iconButton = [[ACIconButton alloc] initWithFrame:CGRectZero];
    self.iconButton = iconButton;
    [iconButton release];

    [self.iconButton setTranslatesAutoresizingMaskIntoConstraints:false];

    UILabel *titleLabel = [[CCUIControlCenterLabel alloc] init];
    self.titleLabel = titleLabel;
    [titleLabel release];

    [self.titleLabel setAllowsDefaultTighteningForTruncation:true];
    [self.titleLabel setAdjustsFontSizeToFitWidth:true];
    [self.titleLabel setMinimumScaleFactor:(float)0x3f400000];
    [self.titleLabel setTranslatesAutoresizingMaskIntoConstraints:false];
    self.titleLabel.text = @"App Center";
    self.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];

    [self addSubview:self.iconButton];
    [self addSubview:self.titleLabel];

    NSDictionary *views = @{
      @"iconButton": self.iconButton,
      @"titleLabel": self.titleLabel
    };

    NSMutableArray *constraints = [NSMutableArray new];

    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(5)-[iconButton]" options:nil metrics:nil views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(-1)-[iconButton]" options:nil metrics:nil views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[iconButton]-(10)-[titleLabel]" options:nil metrics:nil views:views]];

    NSLayoutConstraint *labelFirstBaseline = [NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeFirstBaseline relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:17.0];
    [constraints addObject:labelFirstBaseline];

    [self addConstraints:constraints];

    [constraints release];
  }
  return self;
}

@end

@implementation ACAppSelectionPageViewController
@dynamic view;
@synthesize delegate;

- (id)initWithNibName:(NSString*)nibName bundle:(NSBundle*)bundle {
  self = [super initWithNibName:nibName bundle:bundle];
  if (self) {
    self.gridViewController = [[ACAppSelectionGridViewController alloc] initWithNibName:nil bundle:nil];
  }
  return self;
}

- (UIEdgeInsets)contentInsets {
  return UIEdgeInsetsMake(16.0, 16.0, 16.0, 16.0);
}

- (BOOL)wantsVisible {
  return YES;
}

- (void)loadView {
  ACAppSelectionContainerView *view = [[ACAppSelectionContainerView alloc] init];
  self.view = view;
  [view release];

  [self addChildViewController:self.gridViewController];
  [self.gridViewController.view setFrame:self.view.bounds];
  [self.view addSubview:self.gridViewController.view];
  [self.gridViewController didMoveToParentViewController:self];

  NSMutableArray *constraints = [NSMutableArray new];

  NSDictionary *views = @{
    @"gridView": self.gridViewController.view,
    @"iconButton": self.view.iconButton
  };

  [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[gridView]|" options:nil metrics:nil views:views]];
  [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[iconButton]-10-[gridView]|" options:nil metrics:nil views:views]];

  [self.view addConstraints:constraints];
}

- (void)controlCenterWillPresent {

}

- (void)controlCenterDidFinishTransition {

}

- (void)controlCenterWillBeginTransition {

}

- (void)controlCenterDidDismiss {

}

@end
