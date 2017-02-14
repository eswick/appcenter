#import "AppPage.h"

@implementation ACAppPageView

- (id)init {
  self = [super init];
  if (self) {
    self.touchBlockerView = [[UIView alloc] init];
    self.touchBlockerView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.01];
    [self addSubview:self.touchBlockerView];
    [self.touchBlockerView release];
  }
  return self;
}

- (void)layoutSubviews {
  self.touchBlockerView.frame = self.hostView.frame;
  [self bringSubviewToFront:self.touchBlockerView];
}

@end

@implementation ACAppPageViewController
@synthesize delegate;
@dynamic view;

- (id)initWithBundleIdentifier:(NSString*)bundleIdentifier {
  self = [super init];
  if (self) {
    self.app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:bundleIdentifier];
    if (!self.app) {
      return nil;
    }

    self.appIconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [%c(SBIconView) defaultIconImageSize].width, [%c(SBIconView) defaultIconImageSize].height)];
    SBIconModel *iconModel = [(SBIconController*)[%c(SBIconController) sharedInstance] model];
    SBIcon *icon = [iconModel expectedIconForDisplayIdentifier:bundleIdentifier];
    int iconFormat = [icon iconFormatForLocation:0];
    self.appIconImageView.image = [icon getCachedIconImage:iconFormat];
    [self.view addSubview:self.appIconImageView];
    self.appIconImageView.alpha = 0.0;
    [self.appIconImageView release];

    self.infoLabel = [[CCUIControlCenterLabel alloc] initWithFrame:CGRectMake(0,0,300, 20)];
    [self setInfoLabelText];
    self.infoLabel.numberOfLines = 2;
    self.infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.infoLabel.textAlignment = NSTextAlignmentCenter;
    self.infoLabel.font = [UIFont systemFontOfSize:[ACManualLayout appDisplayNameFontSize]];
    [self.infoLabel setStyle:(unsigned long long) 2];//white text
    self.infoLabel.alpha = 0.0;
    self.infoLabel.hidden = true;
    [self.view addSubview:self.infoLabel];
    [self.infoLabel release];

    self.appLoadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.appLoadingIndicator.hidesWhenStopped = false;
    self.appLoadingIndicator.alpha = 0.0;
    [self.view addSubview:self.appLoadingIndicator];
    [self.appLoadingIndicator release];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(controlCenterDidSetRevealPercentage:)
                                                 name:NOTIFICATION_REVEAL_ID
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(controlCenterDidBeginScrolling)
                                                 name:SCROLL_BEGIN_ID
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(controlCenterDidEndScrolling)
                                                 name:SCROLL_END_ID
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(reloadForPrefsChange)
                                                name:@PREFS_CHANGE_ID
                                              object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [super dealloc];
}

- (void)reloadForPrefsChange {
  if (self) {
    if (self.app) {
      if (self.hostView) {
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationCurveEaseInOut animations:^{
          CGFloat scale = [ACManualLayout defaultAppPageScale]*appPageScaleMultiplier;
          self.hostView.transform = CGAffineTransformMakeScale(scale, scale);
          self.hostView.transform = CGAffineTransformRotate(self.hostView.transform, rotationRadiansForInterfaceOrientation([self.app statusBarOrientation]));
        } completion:^(BOOL success) {}];
      }
    }
  }
}

- (BOOL)isDeviceUnlocked {
  return ![(SpringBoard*)[%c(SpringBoard) sharedApplication] isLocked];
}

- (void)setInfoLabelText {
  self.infoLabel.text = [self isDeviceUnlocked] ?
    [NSString stringWithFormat:@"%@ is running in the foreground", self.app.displayName] :
    [NSString stringWithFormat:@"Unlock to use %@", self.app.displayName];
}

- (void)reloadForUnlock {
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [self controlCenterWillPresent];
    [self viewDidAppear:false];
    [self viewWillLayoutSubviews];
    [self controlCenterDidEndScrolling];
  });
}

- (void)setIsPageAnimating:(BOOL)value {
  self.isBeingCreated = value;
}

- (void)stopSendingTouchesToApp {
  self.view.touchBlockerView.hidden = false;
}

- (void)startSendingTouchesToApp {
  self.view.touchBlockerView.hidden = true;
}

- (void)controlCenterDidFinishTransition {
  self.controlCenterTransitioning = false;
}

- (void)controlCenterWillBeginTransition {
  self.controlCenterTransitioning = true;
}

- (void)controlCenterDidBeginScrolling {
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startSendingTouchesToApp) object:self];
  [self stopSendingTouchesToApp];
}

- (void)controlCenterDidEndScrolling {
  if ([self isDeviceUnlocked]) {
    [self performSelector:@selector(startSendingTouchesToApp) withObject:self afterDelay:0.5];
  }
}

- (void)controlCenterDidSetRevealPercentage:(NSNotification*)notification {
  CGRect frame = self.hostView.frame;

  CGFloat openedY = [self.view convertPoint:CGPointMake(0, CGRectGetMidY([[UIScreen mainScreen] bounds])) fromView:[UIApplication sharedApplication].keyWindow].y - (frame.size.height / 2) - APP_PAGE_PADDING;
  CGFloat percentage = MIN(1.0, [[notification userInfo][@"revealPercentage"] floatValue]);

  frame.origin.y = openedY * percentage;
  self.hostView.frame = frame;

  [UIView animateWithDuration:0.1 animations:^{
    self.appIconImageView.alpha = percentage > 0.7 ? percentage : 0.0;
    self.appLoadingIndicator.alpha = percentage > 0.7 ? percentage : 0.0;
    self.infoLabel.alpha = percentage > 0.7 ? percentage : 0.0;;
  }];
}

- (void)controlCenterDidDismiss {
  self.appLoadingIndicator.hidden = false;
  self.infoLabel.hidden = true;
  self.infoLabel.alpha = 0.0;
  [self.sceneHostManager disableHostingForRequester:REQUESTER];

  if (![self.app.bundleIdentifier isEqualToString:[[(SpringBoard*)[%c(SpringBoard) sharedApplication] _accessibilityFrontMostApplication] bundleIdentifier]]) {
    [self.app appcenter_stopBackgroundingWithCompletion:nil];
  }
}

- (void)controlCenterWillPresent {
  [self.app appcenter_startBackgroundingWithCompletion:^void(BOOL success) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if ([self.app.bundleIdentifier isEqualToString:[[(SpringBoard*)[%c(SpringBoard) sharedApplication] _accessibilityFrontMostApplication] bundleIdentifier]]) {
        return;
      }

      self.sceneHostManager = [[self.app mainScene] contextHostManager];
      self.hostView = [self.sceneHostManager hostViewForRequester:REQUESTER enableAndOrderFront:true];

      self.hostView.layer.cornerRadius = 10;
      self.hostView.layer.masksToBounds = true;
      self.hostView.backgroundColor = [UIColor blackColor];

      CGFloat scale = [ACManualLayout defaultAppPageScale]*appPageScaleMultiplier;
      self.hostView.transform = CGAffineTransformMakeScale(scale, scale);
      self.hostView.transform = CGAffineTransformRotate(self.hostView.transform, rotationRadiansForInterfaceOrientation([self.app statusBarOrientation]));

      self.hostView.alpha = 0.0;

      self.view.hostView = self.hostView;
      [self.view addSubview:self.hostView];

      [UIView animateWithDuration:0.25 animations:^{
        self.appIconImageView.alpha = 1.0;
        if ([self isDeviceUnlocked]) {
          self.hostView.alpha = 1.0;
          [self stopSendingTouchesToApp];
          [self performSelector:@selector(startSendingTouchesToApp) withObject:self afterDelay:0.6];
        }
      }];
    });
  }];
}

- (void)viewWillLayoutSubviews {
  CGRect frame = self.hostView.frame;

  frame.origin.x = CGRectGetMidX(self.view.bounds) - (self.hostView.frame.size.width / 2);

  if (self.controlCenterTransitioning) {
    frame.origin.y = 0;
  } else {
    frame.origin.y = [self.view convertPoint:CGPointMake(0, CGRectGetMidY([[UIScreen mainScreen] bounds])) fromView:[UIApplication sharedApplication].keyWindow].y - (frame.size.height / 2) - APP_PAGE_PADDING;
  }

  self.hostView.frame = frame;
  self.infoLabel.center = CGPointMake(self.view.center.x, [ACManualLayout ccEdgeSpacing]+16+self.appIconImageView.bounds.size.height/2);
  self.appIconImageView.center = CGPointMake(self.view.center.x, [ACManualLayout ccEdgeSpacing]);
  self.appLoadingIndicator.center = CGPointMake(self.appIconImageView.center.x, self.appIconImageView.center.y + self.appIconImageView.bounds.size.height);
}

- (void)loadView {
  ACAppPageView *pageView = [[ACAppPageView alloc] init];
  self.view = pageView;
  self.view.appIdentifier = [self.app bundleIdentifier];
  [pageView release];
}

- (void)viewDidAppear:(BOOL)arg1 {
  [super viewDidAppear:arg1];
  if ([self isDeviceUnlocked]) {
    if ([self.app.bundleIdentifier isEqualToString:[[(SpringBoard*)[%c(SpringBoard) sharedApplication] _accessibilityFrontMostApplication] bundleIdentifier]]) {
      [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.infoLabel.alpha = 0.0;
        self.appLoadingIndicator.alpha = 0.0;
      } completion:^(BOOL finished){
        self.appLoadingIndicator.hidden = true;
        self.infoLabel.hidden = false;
        [self setInfoLabelText];
        [UIView animateWithDuration:0.5 delay:0.5 options:UIViewAnimationOptionCurveEaseIn animations:^{
          self.infoLabel.alpha = 1.0;
        } completion:^(BOOL finished){}];
      }];
    } else {
      self.infoLabel.alpha = 0.0;
      self.infoLabel.hidden = true;
      [self.appLoadingIndicator startAnimating];
      self.appLoadingIndicator.alpha = 0.0;
      self.appLoadingIndicator.hidden = self.isBeingCreated;
      self.appIconImageView.hidden = self.isBeingCreated;
      [UIView animateWithDuration:0.5 delay:0.5 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.appLoadingIndicator.alpha = 1.0;
      } completion:nil];
    }
  } else {
    [self setInfoLabelText];
    self.infoLabel.hidden = false;
    self.appLoadingIndicator.hidden = true;
  }
}

@end
