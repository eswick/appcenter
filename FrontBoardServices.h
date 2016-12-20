extern NSString* FBSOpenApplicationOptionKeyActivateSuspended;

@interface FBSSceneSettings : NSObject <NSMutableCopying>

@end

@interface FBSMutableSceneSettings : FBSSceneSettings

@property(nonatomic, getter=isBackgrounded) BOOL backgrounded;

@end

@interface FBSSettingsDiff : NSObject

@end

@interface FBSSceneSettingsDiff : FBSSettingsDiff

+ (id)diffFromSettings:(id)arg1 toSettings:(id)arg2;

@end

@interface FBSSystemService : NSObject

+ (id)sharedService;
- (void)openApplication:(id)arg1 options:(id)arg2 withResult:(void (^)(void))arg3;

@end
