@class FBScene;

@interface SBApplication : NSObject

- (FBScene*)mainScene;
- (NSString*)bundleIdentifier;
- (BOOL)isRunning;

@end

@interface SBApplicationController : NSObject

+ (id)sharedInstance;
- (SBApplication*)applicationWithBundleIdentifier:(NSString*)bundleIdentifier;

@end

@interface SBDisplayItem : NSObject

@property(readonly, copy, nonatomic) NSString *displayIdentifier;

@end

@interface SBAppSwitcherModel : NSObject

+ (id)sharedInstance;
- (NSArray<SBDisplayItem*>*)mainSwitcherDisplayItems;

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
