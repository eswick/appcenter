#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>

@interface APCRootListController : PSListController

@end


@protocol PreferencesTableCustomView
- (id)initWithSpecifier:(PSSpecifier *)specifier;
- (CGFloat)preferredHeightForWidth:(CGFloat)width;
@end

@interface APCHeaderCell : PSTableCell <PreferencesTableCustomView> {
	UIImageView *_headerImgV;
}
@end
