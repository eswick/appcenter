@class FBSSceneTransitionContext, FBSSceneSettings, FBSSceneSettingsDiff;

@protocol FBSceneClientProvider

- (void)endTransaction;
- (void)beginTransaction;

@end

@protocol FBSceneClient

- (void)host:(id/* <FBSceneHost>*/)arg1 didUpdateSettings:(FBSSceneSettings *)arg2 withDiff:(FBSSceneSettingsDiff *)arg3 transitionContext:(FBSSceneTransitionContext *)arg4 completion:(void (^)(BOOL))arg5;

@end

@interface FBSceneHostWrapperView : UIView
@property(readonly, retain, nonatomic) FBScene *scene;
@end

@interface FBSceneHostManager : NSObject

- (void)disableHostingForRequester:(NSString*)requester;
- (FBSceneHostWrapperView*)hostViewForRequester:(NSString*)requester enableAndOrderFront:(BOOL)arg2;
- (void)enableHostingForRequester:(id)arg1 orderFront:(BOOL)arg2;

@end

@interface FBScene : NSObject

@property(readonly, retain, nonatomic) id <FBSceneClientProvider> clientProvider;
@property(readonly, retain, nonatomic) id <FBSceneClient> client;
@property(readonly, retain, nonatomic) FBSSceneSettings *settings;

- (FBSceneHostManager*)contextHostManager;

@end

@interface FBSceneManager : NSObject

+ (FBSceneManager*)sharedInstance;
- (FBScene*)sceneWithIdentifier:(NSString*)identifier;

@end
