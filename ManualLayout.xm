#import "ManualLayout.h"

@implementation ManualLayout : NSObject

+(CGFloat)appCellCornerRadius {
  return CGFloat(8.0);
}
+(CGFloat)appIconScale {
  return 0.90;
}
+(UIEdgeInsets)collectionViewContentInset {
  CGFloat inset = [ManualLayout screenWidth] / 30;
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
+(CGFloat)screenWidth {
  CGSize size = [ManualLayout screenSize];
  if ([ManualLayout isIPad]) {
    return MIN(size.width, size.height);
  } else {
    return size.width;
  }
}

@end
