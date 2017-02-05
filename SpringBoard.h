@class FBScene;

@interface SBApplication : NSObject

- (FBScene*)mainScene;
- (NSString*)bundleIdentifier;
- (BOOL)isRunning;
- (NSString*)displayName;
- (BOOL)hasHiddenTag;
- (BOOL)isActivating;

@end

@interface SBApplicationController : NSObject

+ (id)sharedInstance;
- (SBApplication*)applicationWithBundleIdentifier:(NSString*)bundleIdentifier;

@end

@interface SBDisplayItem : NSObject

@property(readonly, copy, nonatomic) NSString *displayIdentifier;

+ (id)displayItemWithType:(NSString *)arg1 displayIdentifier:(id)arg2;

@end

@interface SBAppSwitcherModel : NSObject

+ (id)sharedInstance;
- (NSArray<SBDisplayItem*>*)mainSwitcherDisplayItems;
- (id)_displayItemForApplication:(id)arg1;

@end

@interface SBIcon : NSObject

- (id)getCachedIconImage:(int)location;
- (int)iconFormatForLocation:(int)arg1;

@end

@interface SBIconModel : NSObject

- (id)expectedIconForDisplayIdentifier:(NSString*)displayIdentifier;

@end

@interface SBIconController : NSObject

+ (SBIconController*)sharedInstance;

- (SBIconModel*)model;

@end

@interface SBIconView : UIView

+ (CGSize)defaultIconSize;
+ (CGSize)defaultIconImageSize;

@end

@interface SpringBoard : UIApplication

- (SBApplication*)_accessibilityFrontMostApplication;
- (_Bool)isLocked;

@end

@interface SBAppSwitcherModel (AppCenter)

@property (nonatomic, retain) NSMutableArray *recentAppIdentifiers;

- (NSArray<NSString*>*)appcenter_model;

@end

@interface SBApplication (AppCenter)

- (void)appcenter_setBackgrounded:(BOOL)backgrounded withCompletion:(void (^)(BOOL))completion;
- (void)appcenter_startBackgroundingWithCompletion:(void (^)(BOOL))completion;
- (void)appcenter_stopBackgroundingWithCompletion:(void (^)(BOOL))completion;

@end

@interface SBAppSwitcherSnapshotView : UIView

+ (id)appSwitcherSnapshotViewForDisplayItem:(id)arg1 orientation:(long long)arg2 preferringDownscaledSnapshot:(_Bool)arg3 loadAsync:(_Bool)arg4 withQueue:(id)arg5;

@end

@interface SBDeckSwitcherPageViewProvider : NSObject

- (id)pageViewForDisplayItem:(id)arg1 synchronously:(BOOL)arg2;
- (id)initWithDelegate:(id)delegate;

@end
