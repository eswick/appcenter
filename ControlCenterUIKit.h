@protocol CCUIControlCenterButtonDelegate;

@interface CCUIControlCenterButton : UIButton
+ (id)capsuleButtonWithText:(id)arg1;
+ (id)roundRectButton;
+ (id)roundRectButtonWithText:(id)arg1;
+ (id)capsuleButtonWithText:(id)arg1;
- (void)setGlyphImage:(id)arg1 selectedGlyphImage:(id)arg2 name:(id)arg3;
- (long long)_currentState;
- (void)_updateEffects;
- (void)setRoundCorners:(unsigned long long)arg1;

@property (nonatomic, assign) BOOL animatesStateChanges;
@property (nonatomic, assign) id<CCUIControlCenterButtonDelegate> delegate;
@property (nonatomic, retain) NSString *text;

@end

@interface CCUIControlCenterLabel : UILabel

@end
