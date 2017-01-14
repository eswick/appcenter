#import "ManualLayout.h"

@implementation ACManualLayout : NSObject

+(CGFloat)appCellCornerRadius {
  return CGFloat(8.0);
}
+(CGFloat)appIconScale {
  return 0.90;
}
+(UIEdgeInsets)collectionViewContentInset {
  CGFloat inset = [ACManualLayout screenWidth] * [ACManualLayout getScale] / 30;
  return UIEdgeInsetsMake(inset, inset, inset, inset);
}
+(CGSize)collectionViewFlowLayoutItemSize {
  return CGSizeMake(98, 98);
}
+(CGFloat)collectionViewFlowLayoutItemSpacing {
  return CGFloat(5.0);
}

+(CGSize)screenSize {
  return UIScreen.mainScreen.bounds.size;
}
+(BOOL)isIPad {
  return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}
+(CGFloat)appCenterLabelOffset {
  return 16.5;
}
+(CGFloat)screenWidth {
  CGSize size = [ACManualLayout screenSize];
  if ([ACManualLayout isIPad]) {
    return MIN(size.width, size.height);
  } else {
    return size.width;
  }
}
+(CGFloat)getScale {
  return UIScreen.mainScreen.scale;
}

@end
