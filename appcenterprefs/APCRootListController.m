#include "APCRootListController.h"
#define PREFS_PATH [[@"~/Library" stringByExpandingTildeInPath] stringByAppendingPathComponent:@"/Preferences/com.eswick.appcenter.plist"]

@implementation APCRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}

@end

@implementation APCHeaderCell
- (id)initWithSpecifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell" specifier:specifier];
	if (self) {
		_headerImgV = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/AppCenter.bundle/AppCenter_large.png"]];
		[self addSubview:_headerImgV];
		_headerImgV.center = CGPointMake(UIScreen.mainScreen.bounds.size.width/2, 125);
		[_headerImgV release];
	}
	return self;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width {
	// Return a custom cell height.
	return 250.f;
}
@end
