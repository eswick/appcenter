#import "ManualLayout.h"

@implementation ACManualLayout : NSObject

// Top Row
+(CGSize)appCenterButtonSize {
  CGFloat scaled = 35 * [ACManualLayout relativeTo47InchScale];
  return CGSizeMake(scaled, scaled);
}
+(CGFloat)appCenterButtonTopSpacing {
  return -6.0 * [ACManualLayout relativeTo47InchScale];
}
+(CGFloat)appCenterLabelOffset {
  return [ACManualLayout appCenterButtonSize].height / 2 - (3-[ACManualLayout screenScale]);
}
+(CGFloat)appCenterLabelFontSize {
  return 17.5 * [ACManualLayout relativeTo47InchScale];
}
// Search
+(CGSize)searchButtonSize {
  CGFloat scaled = 25 * [ACManualLayout relativeTo47InchScale];
  return CGSizeMake(scaled, scaled);
}
// Grid View
+(CGFloat)appCellCornerRadius {
  return CGFloat(8.0);
}
+(CGFloat)appIconScale {
  return MIN(0.90 * [ACManualLayout relativeTo47InchScale], 1);
}
+(UIEdgeInsets)collectionViewContentInset {
  CGFloat inset = ([ACManualLayout isTinyScreen] ? 22 : 27) * ([ACManualLayout isSmallScreen] ? [ACManualLayout relativeTo47InchScale] : 0.815);
  return UIEdgeInsetsMake(inset, inset, inset, inset);
}
+(CGSize)collectionViewFlowLayoutItemSize {
  CGFloat scaled = ([ACManualLayout isTinyScreen] ? 88 : 98) * [ACManualLayout relativeTo47InchScale];
  return CGSizeMake(scaled, scaled);
}
+(CGFloat)collectionViewFlowLayoutItemSpacing {
  return [ACManualLayout isTinyScreen] ? CGFloat(3.0) : CGFloat(5.0);
}
+(CGFloat)appDisplayNameFontSize {
  return 13 * [ACManualLayout relativeTo47InchScale];
}

+(CGFloat)ccEdgeSpacing {
  return [ACManualLayout isTinyScreen] ? 8.5 * [ACManualLayout relativeTo47InchScale] : [ACManualLayout isSmallScreen] ? 8 : 9 ;
}

// Helpers
+(CGSize)screenSize {
  return UIScreen.mainScreen.bounds.size;
}
+(BOOL)isIPad {
  return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}
+(BOOL)isSmallScreen {
  return [ACManualLayout largerScreenEdge] * [ACManualLayout screenScale] <= 1334.0;
}
+(BOOL)isTinyScreen {
  return [ACManualLayout largerScreenEdge] * [ACManualLayout screenScale] < 1334.0;
}
+(CGFloat)screenWidth {
  CGSize size = [ACManualLayout screenSize];
  if ([ACManualLayout isIPad]) {
    return MIN(size.width, size.height);
  } else {
    return size.width;
  }
}
+(CGFloat)largerScreenEdge {
  CGSize size = [ACManualLayout screenSize];
  return MAX(size.width, size.height);
}
+(CGFloat)screenScale {
  return UIScreen.mainScreen.scale;
}
+(CGFloat)relativeTo47InchScale {
  CGFloat diff = [ACManualLayout largerScreenEdge] * [ACManualLayout screenScale] - 1334.0;
  return diff/5500.0 + 1.0;
}

@end
