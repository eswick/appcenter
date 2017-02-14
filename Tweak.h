
extern NSMutableArray<NSString*> *appPages;
extern ACAppSelectionPageViewController *selectionViewController;
extern NSMutableDictionary<NSString*, SBAppSwitcherSnapshotView*> *snapshotViewCache;
extern BOOL reloadingControlCenter;
// Preferences
extern BOOL isTweakEnabled;
extern CGFloat appPageScaleMultiplier;
extern BOOL isNotFirstRun;
extern int rotationDegreesForInterfaceOrientation(UIInterfaceOrientation orientation);
extern CGFloat rotationRadiansForInterfaceOrientation(UIInterfaceOrientation orientation);

#pragma mark Constants

#define REQUESTER @"com.eswick.appcenter"
#define BUNDLEID_C "com.eswick.appcenter"
#define ANIMATION_REQUESTER @"com.eswick.appcenter.animation"
#define NOTIFICATION_REVEAL_ID @"com.eswick.appcenter.notification.revealpercentage"
#define SCROLL_BEGIN_ID @"com.eswick.appcenter.notification.scrollbegin"
#define SCROLL_END_ID @"com.eswick.appcenter.notification.scrollend"
#define PREFS_CHANGE_ID "com.eswick.appcenter.notification.prefschange"
#define NOTIFICATION_SCROLL_TO_SELECTIONPAGE @"com.eswick.appcenter.notification.scrolltoselectionpage"
#define APP_PAGE_PADDING 5.0
#define PREFS_PATH [[@"~/Library" stringByExpandingTildeInPath] stringByAppendingPathComponent:@"/Preferences/com.eswick.appcenter.plist"]
#define PREFS_ENABLED_C "IsTweakEnabled"
#define PREFS_APPPAGESCALE_C "AppPageScaleMultiplier"
#define PREFS_ISFIRSTRUN_C "IsFirstRun"
#define PREFS_APPPAGES_C "AppPages"
