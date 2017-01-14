#import "SelectionPage.h"
#import "SpringBoard.h"
#import "Tweak.h"
#import "UIImage+Tint.h"

@implementation ACIconButton

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    UIImage *image = [UIImage imageWithContentsOfFile:@"/Library/Application Support/App Center/appcenter.png"];
    [self setGlyphImage:image selectedGlyphImage:image name:@"ACIconButton"];
  }
  return self;
}

- (CGSize)intrinsicContentSize {
  return CGSizeMake(35, 35);
}

@end

@implementation ACAppIconCell

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    CGFloat cornerRadius = 8.0;
    self.contentView.layer.cornerRadius = cornerRadius;

    self.button = [CCUIControlCenterButton roundRectButton];
    [self.button setRoundCorners:0];
    self.button.delegate = self;
    self.button.userInteractionEnabled = false;
    self.button.animatesStateChanges = false;
    self.button.translatesAutoresizingMaskIntoConstraints = false;

    [self.contentView addSubview:self.button];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[button]|" options:nil metrics:nil views:@{ @"button" : self.button }]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[button]|" options:nil metrics:nil views:@{ @"button" : self.button }]];

    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [%c(SBIconView) defaultIconImageSize].width * 0.90, [%c(SBIconView) defaultIconImageSize].height * 0.90)];
    self.imageView.center = CGPointMake(self.contentView.bounds.size.width / 2, (self.contentView.bounds.size.height * 0.80) / 2);
    [self.button addSubview:self.imageView];
    [self.imageView release];

    self.tintView = [[UIView alloc] initWithFrame:self.contentView.frame];
    self.tintView.center = CGPointMake(self.contentView.bounds.size.width / 2, self.contentView.bounds.size.height / 2);
    self.tintView.backgroundColor = [UIColor whiteColor];
    self.tintView.layer.cornerRadius = cornerRadius;
    self.tintView.alpha = 0.0;
    [self.contentView insertSubview:self.tintView belowSubview:self.button];
    [self.tintView release];

    CGPoint center = self.imageView.center;
    center.x = self.bounds.size.width / 2;
    self.imageView.center = center;

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.adjustsFontSizeToFitWidth = false;
    self.titleLabel.font = [UIFont systemFontOfSize:13];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = false;

    [self.button addSubview:self.titleLabel];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label]|" options:nil metrics:nil views:@{ @"label" : self.titleLabel }]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[imageView][label]|" options:nil metrics:nil views:@{ @"label" : self.titleLabel, @"imageView" : self.imageView }]];
  }
  return self;
}

- (id)controlCenterSystemAgent {
  return nil;
}

- (void)buttonTapped:(CCUIControlCenterButton *)arg1 {

}

- (void)button:(CCUIControlCenterButton *)arg1 didChangeState:(long long)arg2 {
  if (arg2 == 0) {
    self.titleLabel.textColor = [UIColor whiteColor];
  } else {
    self.titleLabel.textColor = [UIColor blackColor];
  }
}

- (BOOL)isInternal {
  return false;
}

- (void)configureForApplication:(NSString*)appIdentifier {
  self.appIdentifier = appIdentifier;

  SBIconModel *iconModel = [(SBIconController*)[%c(SBIconController) sharedInstance] model];
  SBIcon *icon = [iconModel expectedIconForDisplayIdentifier:appIdentifier];
  int iconFormat = [icon iconFormatForLocation:0];

  self.imageView.image = [icon getCachedIconImage:iconFormat];
  //self.imageView.highlightedImage = [self.imageView.image tintedImageUsingColor:[UIColor colorWithWhite:0.0 alpha:0.3]];

  self.titleLabel.text = [[[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:self.appIdentifier] displayName];

  if ([appPages containsObject:appIdentifier]) {
    self.button.selected = true;
  } else {
    self.button.selected = false;
  }
}

@end

@implementation ACAppSelectionGridViewController

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return MIN([[[%c(SBAppSwitcherModel) sharedInstance] appcenter_model] count] + appPages.count, 9);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  ACAppIconCell *cell = (ACAppIconCell*)[self.collectionView dequeueReusableCellWithReuseIdentifier:@"AppIconCell" forIndexPath:indexPath];

  NSString *appIdentifier = nil;

  if (indexPath.row < appPages.count) {
    appIdentifier = appPages[indexPath.row];
  } else {
    appIdentifier = [[%c(SBAppSwitcherModel) sharedInstance] appcenter_model][indexPath.row - appPages.count];
  }

  [cell configureForApplication:appIdentifier];

  return cell;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
  //ACAppIconCell *cell = (ACAppIconCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
  //cell.imageView.highlighted = true;
}

-(void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
  //ACAppIconCell *cell = (ACAppIconCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
  //cell.imageView.highlighted = false;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  CCUIControlCenterViewController *ccViewController = (CCUIControlCenterViewController*)self.parentViewController.parentViewController.parentViewController;

  ACAppIconCell *cell = (ACAppIconCell*)[self.collectionView cellForItemAtIndexPath:indexPath];

  ((ACAppSelectionPageViewController*)self.parentViewController).selectedCell = cell;

// NEW
  BOOL nowSelected = !cell.button.selected;
  CGFloat newValue;
  if (nowSelected == false) {
    newValue = CGFloat(0.0);
  } else {
    newValue = CGFloat(1.0);
  }
  [UIView animateWithDuration:0.2
                        delay:0.0
                      options:UIViewAnimationOptionCurveEaseIn
                   animations:^{
                            cell.tintView.alpha = newValue;
                            }
                   completion:^(BOOL finished){
                            cell.button.selected = !cell.button.selected;
                            [ccViewController appcenter_appSelected:cell.appIdentifier];
                          }];
}

- (void)loadView {

  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.itemSize = CGSizeMake(98, 98);
  layout.minimumLineSpacing = 5.0;
  layout.minimumInteritemSpacing = 5.0;

  self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];

  self.collectionView.delegate = self;
  self.collectionView.dataSource = self;

  self.collectionView.translatesAutoresizingMaskIntoConstraints = false;
  self.collectionView.backgroundColor = [UIColor clearColor];

  [self.collectionView registerClass:[ACAppIconCell class] forCellWithReuseIdentifier:@"AppIconCell"];
  self.view = self.collectionView;

  [layout release];
}

- (void)fixButtonEffects {
  if ([self collectionView:self.collectionView numberOfItemsInSection:0] > 0) {
    [[(ACAppIconCell*)[self collectionView:self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] button] _updateEffects];
  }
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
    self.titleLabel.font = [UIFont systemFontOfSize:16.5 weight:UIFontWeightMedium];
    self.titleLabel.alpha = 0.999;

    [self addSubview:self.iconButton];
    [self addSubview:self.titleLabel];

    NSDictionary *views = @{
      @"iconButton": self.iconButton,
      @"titleLabel": self.titleLabel
    };

    NSMutableArray *constraints = [NSMutableArray new];

    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[iconButton]" options:nil metrics:nil views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(-6)-[iconButton]" options:nil metrics:nil views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[iconButton]-(5)-[titleLabel]" options:nil metrics:nil views:views]];

    NSLayoutConstraint *labelFirstBaseline = [NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeFirstBaseline relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:15];
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
  return UIEdgeInsetsMake(25.0, 25.0, 25.0, 25.0);
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
  static dispatch_once_t onceToken;

  dispatch_once (&onceToken, ^{
    [self.gridViewController.collectionView reloadData];
  });
}

- (void)controlCenterDidFinishTransition {

}

- (void)controlCenterWillBeginTransition {
  [self.gridViewController fixButtonEffects];
}

- (void)controlCenterDidDismiss {
  [self.gridViewController.collectionView reloadData];
}

@end
