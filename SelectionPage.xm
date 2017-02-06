#import "SelectionPage.h"
#import "SpringBoard.h"
#import "Tweak.h"
#import "UIImage+Tint.h"
#import "ManualLayout.h"
#import <substrate.h>

@implementation ACSearchButton

- (id)init {
  CGSize size = [ACManualLayout searchButtonSize];
  self = [super initWithFrame:CGRectMake(0, 0, size.width, size.height)];
  if (self) {
    UIImage *image = [UIImage imageWithContentsOfFile:@"/Library/Application Support/App Center/mag.png"];
    [self setImage:image forState:UIControlStateNormal];
  }
  return self;
}

- (CGSize)intrinsicContentSize {
  return [ACManualLayout searchButtonSize];
}

@end

@implementation ACIconButton

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    UIImage *image = [UIImage imageWithContentsOfFile:@"/Library/Application Support/App Center/appcenter.png"];
    [self setGlyphImage:image selectedGlyphImage:image name:@"ACIconButton"];
  }
  self.userInteractionEnabled = false;
  return self;
}

- (CGSize)intrinsicContentSize {
  return [ACManualLayout appCenterButtonSize];
}

@end

@implementation ACAppIconCell

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    CGFloat cornerRadius = [ACManualLayout appCellCornerRadius];
    self.contentView.layer.cornerRadius = cornerRadius;

    self.longPressRec = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress)];
    self.longPressRec.minimumPressDuration = 0.75;
    [self.contentView addGestureRecognizer:self.longPressRec];
    [self.longPressRec release];

    self.button = [CCUIControlCenterButton roundRectButton];
    self.button.delegate = self;
    self.button.userInteractionEnabled = false;
    self.button.animatesStateChanges = true;
    self.button.translatesAutoresizingMaskIntoConstraints = false;

    [self.contentView addSubview:self.button];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[button]|" options:nil metrics:nil views:@{ @"button" : self.button }]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[button]|" options:nil metrics:nil views:@{ @"button" : self.button }]];


    CGFloat appIconScale = [ACManualLayout appIconScale];
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [%c(SBIconView) defaultIconImageSize].width * appIconScale, [%c(SBIconView) defaultIconImageSize].height * appIconScale)];
    self.imageView.center = CGPointMake(self.contentView.bounds.size.width / 2, (self.contentView.bounds.size.height * 0.80) / 2);

    UIImage *dropShadowImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/App Center/app icon drop shadow.png"];
    UIImageView *dropShadowView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.imageView.frame.size.width * 1.1, self.imageView.frame.size.height * 1.1)];

    dropShadowView.center = CGPointMake(self.contentView.bounds.size.width / 2, (self.contentView.bounds.size.height * 0.80) / 2);
    dropShadowView.image = dropShadowImage;

    [self.button addSubview:dropShadowView];
    [self.button addSubview:self.imageView];
    [dropShadowView release];
    [self.imageView release];


    self.loadingView = [[UIActivityIndicatorView alloc] initWithFrame:self.imageView.frame];
    self.loadingView.hidesWhenStopped = true;
    [self.loadingView stopAnimating];
    [self.button addSubview:self.loadingView];

    CGPoint center = self.imageView.center;
    center.x = self.bounds.size.width / 2;
    self.imageView.center = center;

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.adjustsFontSizeToFitWidth = false;
    self.titleLabel.font = [UIFont systemFontOfSize:[ACManualLayout appDisplayNameFontSize]];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = false;

    [self.button addSubview:self.titleLabel];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label]|" options:nil metrics:nil views:@{ @"label" : self.titleLabel }]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[imageView][label]|" options:nil metrics:nil views:@{ @"label" : self.titleLabel, @"imageView" : self.imageView }]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideActivity) name:@"ACAppCellStopActivity" object:nil];
  }
  return self;
}

- (void)showActivity {
  [self.loadingView startAnimating];
  self.imageView.highlighted = true;
}

- (void)hideActivity {
  [self.loadingView stopAnimating];
  self.imageView.highlighted = false;
}

- (void)handleLongPress {
  [[UIApplication sharedApplication] launchApplicationWithIdentifier:self.appIdentifier suspended:NO];
}

- (void)prepareForReuse {
  [self.button _updateEffects];
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
  self.imageView.highlightedImage = [self.imageView.image tintedImageUsingColor:[UIColor colorWithWhite:0.0 alpha:0.5]];

  self.titleLabel.text = [[[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:self.appIdentifier] displayName];

  if ([appPages containsObject:appIdentifier]) {
    self.button.selected = true;
  } else {
    self.button.selected = false;
  }
}

@end

@implementation ACAppSelectionGridViewController

- (NSArray*)searchResults {
  NSDictionary *applications = MSHookIvar<NSDictionary*>([%c(SBApplicationController) sharedInstance], "_applicationsByBundleIdentifer");

  NSMutableArray *result = [NSMutableArray new];

  for (NSString *key in applications) {
    SBApplication *application = applications[key];
    if ([[[application displayName] lowercaseString] hasPrefix:[selectionViewController.view.searchBar.text lowercaseString]]) {
      if ([application hasHiddenTag]) {
        continue;
      }
      if ([appPages containsObject:[application bundleIdentifier]]) {
        continue;
      }
      if ([key isEqualToString:[(SpringBoard*)[%c(SpringBoard) sharedApplication] _accessibilityFrontMostApplication].bundleIdentifier]) {
        continue;
      }
      [result addObject:application];
    }
  }

  return [result autorelease];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
  ACAppIconCell *iconCell = (ACAppIconCell*)cell;

  [iconCell.button _updateEffects];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  if (selectionViewController.searching) {
    return MIN([[self searchResults] count], 9);
  }
  return MIN([[[%c(SBAppSwitcherModel) sharedInstance] appcenter_model] count] + appPages.count, 9);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  ACAppIconCell *cell = (ACAppIconCell*)[self.collectionView dequeueReusableCellWithReuseIdentifier:@"AppIconCell" forIndexPath:indexPath];

  NSString *appIdentifier = nil;

  if (selectionViewController.searching) {
    appIdentifier = [[self searchResults][indexPath.row] bundleIdentifier];
  } else if (indexPath.row < appPages.count) {
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

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
   ACAppIconCell *cell = (ACAppIconCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
   cell.imageView.highlighted = true;
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
   ACAppIconCell *cell = (ACAppIconCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
   cell.imageView.highlighted = false;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  CCUIControlCenterViewController *ccViewController = (CCUIControlCenterViewController*)self.parentViewController.parentViewController.parentViewController;

  ACAppIconCell *cell = (ACAppIconCell*)[self.collectionView cellForItemAtIndexPath:indexPath];

  ((ACAppSelectionPageViewController*)self.parentViewController).selectedCell = cell;

  if (!cell.button.selected && ![[[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:cell.appIdentifier] isRunning]) {
    [cell showActivity];
  }

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (selectionViewController.searching ? 0.5 : 0.2) * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [ccViewController appcenter_appSelected:cell.appIdentifier];
  });

  if (selectionViewController.searching && !cell.button.selected) {
    [selectionViewController endSearching];
  }

  cell.button.selected = !cell.button.selected;
}

- (void)loadView {

  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.itemSize = [ACManualLayout collectionViewFlowLayoutItemSize];
  layout.minimumLineSpacing = [ACManualLayout collectionViewFlowLayoutItemSpacing];
  layout.minimumInteritemSpacing = [ACManualLayout collectionViewFlowLayoutItemSpacing];

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
    self.titleLabel.font = [UIFont systemFontOfSize:[ACManualLayout appCenterLabelFontSize] weight:UIFontWeightMedium];

    self.searchButton = [[ACSearchButton alloc] init];
    [self.searchButton setTranslatesAutoresizingMaskIntoConstraints:false];
    self.searchButton.alpha = 1.0;

    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.translatesAutoresizingMaskIntoConstraints = false;
    self.searchBar.alpha = 0.0;
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.tintColor = [UIColor blackColor];
    self.searchBar.showsCancelButton = true;
    // Tint the magnifying glass and clear button the same color as the search bar
    NSArray *searchBarSubViews = [[self.searchBar.subviews objectAtIndex:0] subviews];
    for (UIView *view in searchBarSubViews) {
      if([view isKindOfClass:[UITextField class]]) {
        UITextField *textField = (UITextField*)view;
        UIImageView *imgView = (UIImageView*)textField.leftView;
        imgView.image = [imgView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        imgView.tintColor = self.searchBar.tintColor;

        UIButton *btnClear = (UIButton*)[textField valueForKey:@"clearButton"];
        [btnClear setImage:[btnClear.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        btnClear.tintColor = self.searchBar.tintColor;
      }
    }
    [self.searchBar reloadInputViews];

    UIImage *backgroundImage = [UIImage new];
    [self.searchBar setBackgroundImage:backgroundImage];
    [self.searchBar setTranslucent:true];
    [backgroundImage release];

    [self addSubview:self.searchButton];
    [self addSubview:self.iconButton];
    [self addSubview:self.titleLabel];
    [self addSubview:self.searchBar];

    [self.searchButton release];
    [self.iconButton release];
    [self.titleLabel release];
    [self.searchBar release];

    NSDictionary *views = @{
      @"iconButton": self.iconButton,
      @"titleLabel": self.titleLabel,
      @"searchButton": self.searchButton,
      @"searchBar": self.searchBar
    };

    NSMutableArray *constraints = [NSMutableArray new];

    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[iconButton]" options:nil metrics:nil views:views]];
    NSString *iconButtonTopSpacingVF = [NSString stringWithFormat:@"V:|-(%f)-[iconButton]", [ACManualLayout appCenterButtonTopSpacing]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:iconButtonTopSpacingVF options:nil metrics:nil views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[iconButton]-(8)-[titleLabel]" options:nil metrics:nil views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[searchButton]|" options:nil metrics:nil views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[iconButton][searchBar]-(-8)-|" options:nil metrics:nil views:views]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self.searchBar attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.iconButton attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self.searchButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.iconButton attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];

    CGFloat labelBaselineOffset = [ACManualLayout appCenterLabelOffset];
    NSLayoutConstraint *labelFirstBaseline = [NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeFirstBaseline relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:labelBaselineOffset];
    [constraints addObject:labelFirstBaseline];

    [constraints addObject:[NSLayoutConstraint constraintWithItem:self.searchButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.iconButton attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];

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

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

- (UIEdgeInsets)contentInsets {
  return [ACManualLayout collectionViewContentInset];
}

- (BOOL)wantsVisible {
  return YES;
}

- (void)loadView {
  ACAppSelectionContainerView *view = [[ACAppSelectionContainerView alloc] init];
  self.view = view;
  [view release];

  [self.view.searchButton addTarget:self action:@selector(searchPressed:) forControlEvents:UIControlEventTouchUpInside];
  self.view.searchBar.delegate = self;

  [self addChildViewController:self.gridViewController];
  [self.gridViewController.view setFrame:self.view.bounds];
  [self.view addSubview:self.gridViewController.view];
  [self.gridViewController didMoveToParentViewController:self];

  NSMutableArray *constraints = [NSMutableArray new];

  NSDictionary *views = @{
    @"gridView": self.gridViewController.view,
    @"iconButton": self.view.iconButton,
  };

  [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[gridView]|" options:nil metrics:nil views:views]];
  [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[iconButton]-15-[gridView]|" options:nil metrics:nil views:views]];

  self.lockedLabel = [[CCUIControlCenterLabel alloc] initWithFrame:CGRectMake(0,0,200,10)];
  self.lockedLabel.translatesAutoresizingMaskIntoConstraints = false;
  self.lockedLabel.text = @"Unlock to use App Center";
  self.lockedLabel.textAlignment = NSTextAlignmentCenter;
  self.lockedLabel.font = [UIFont systemFontOfSize:[ACManualLayout appDisplayNameFontSize]*3/2];
  [self.lockedLabel setStyle:(unsigned long long) 0];//dark translucent text
  [self.lockedLabel release];

  [self.view addConstraints:constraints];
}

- (void)beginSearching {
  self.searching = true;

  [self.gridViewController.collectionView reloadData];

  [UIView animateWithDuration:0.25 animations:^{
    self.view.searchBar.alpha = 0.9;
    self.view.searchButton.alpha = 0.0;
    self.view.titleLabel.alpha = 0.0;
  }];

  CCUIControlCenterViewController *ccViewController = (CCUIControlCenterViewController*)self.parentViewController.parentViewController;
  MSHookIvar<UIGestureRecognizer*>(ccViewController, "_tapGesture").enabled = false;
  MSHookIvar<UIView*>(ccViewController, "_pagesScrollView").userInteractionEnabled = false;

  [self.view.searchBar becomeFirstResponder];
}

- (void)endSearching {
  self.searching = false;

  [UIView animateWithDuration:0.25 animations:^{
    self.view.searchBar.alpha = 0.0;
    self.view.searchButton.alpha = 1.0;
    self.view.titleLabel.alpha = 1.0;
  }];

  CCUIControlCenterViewController *ccViewController = (CCUIControlCenterViewController*)self.parentViewController.parentViewController;
  MSHookIvar<UIGestureRecognizer*>(ccViewController, "_tapGesture").enabled = true;
  MSHookIvar<UIView*>(ccViewController, "_pagesScrollView").userInteractionEnabled = true;

  [self.view.searchBar resignFirstResponder];
}

- (void)searchPressed:(id)sender {
  [self beginSearching];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
   [self endSearching];
   [self.gridViewController.collectionView reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
  [self.gridViewController.collectionView reloadData];
}

- (void)controlCenterWillPresent {
  if (!reloadingControlCenter) {
    [self.gridViewController.collectionView reloadData];
    if ([(SpringBoard*)[%c(SpringBoard) sharedApplication] isLocked]) {
      self.gridViewController.view.hidden = true;
      self.view.searchButton.hidden = true;
      [self.view addSubview:self.lockedLabel];
      [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.gridViewController.view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.lockedLabel attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
      [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.gridViewController.view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.lockedLabel attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    }
  }
}

- (void)controlCenterDidFinishTransition {

}

- (void)controlCenterWillBeginTransition {

}

- (void)controlCenterDidDismiss {
  if (self.searching) {
    [self endSearching];
  }
  self.gridViewController.view.hidden = false;
  self.view.searchButton.hidden = false;
  [self.gridViewController.collectionView reloadData];
  [self.lockedLabel removeFromSuperview];
}

- (void)reloadForUnlock {
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [self controlCenterWillPresent];
    self.gridViewController.view.alpha = 0.0;
    self.gridViewController.view.hidden = false;
    self.view.searchButton.alpha = 0.0;
    self.view.searchButton.hidden = false;
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
      self.gridViewController.view.alpha = 1.0;
      self.view.searchButton.alpha = 1.0;
      self.lockedLabel.alpha = 0.0;
    } completion:nil];
  });
}

@end
