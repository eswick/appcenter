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
