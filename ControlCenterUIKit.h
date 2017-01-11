@protocol CCUIControlCenterButtonDelegate;

@interface CCUIControlCenterButton : UIButton
+ (id)capsuleButtonWithText:(id)arg1;
+ (id)roundRectButton;
- (void)setGlyphImage:(id)arg1 selectedGlyphImage:(id)arg2 name:(id)arg3;
- (long long)_currentState;
- (void)_updateEffects;

@property (nonatomic, assign) BOOL animatesStateChanges;
@property (nonatomic, assign) id<CCUIControlCenterButtonDelegate> delegate;

@end

@interface CCUIControlCenterLabel : UILabel

@end
