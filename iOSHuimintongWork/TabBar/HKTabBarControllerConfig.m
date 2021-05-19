//
//  HKTabBarControllerConfig.m
//  iOSHuimintongWork
//
//  Created by gongpengyang on 2021/5/19.
//

#import "HKTabBarControllerConfig.h"
#import "HKTabBarController.h"
#import "ViewController.h"
#import "HKNavigationController.h"
#import "HKHomeViewController.h"

@interface HKTabBarControllerConfig ()<UITabBarControllerDelegate>

@property (nonatomic, readwrite, strong) UIViewController *rootVC;


@end

@implementation HKTabBarControllerConfig
/**
 *  lazy load tabBarController
 *
 *  @return HKTabBarController
 */
- (UIViewController *)rootVC {
    if (!_rootVC) {
        HKTabBarController *tabBartVC = [HKTabBarController tabBarControllerWithViewControllers:self.viewControllers tabBarItemsAttributes:self.tabBarItemsAttributesForController];
      UIViewController *rootVC =  [self customizeTabBarAppearance:tabBartVC];
        _rootVC = rootVC;
    }
    return _rootVC;
}

- (NSArray *)viewControllers {
    HKHomeViewController *firstViewController = [[HKHomeViewController alloc] init];
    UIViewController *firstNavigationController = [[HKNavigationController alloc] initWithRootViewController:firstViewController];
    
    ViewController *secondViewController = [[ViewController alloc] init];
    UIViewController *secondNavigationController = [[HKNavigationController alloc] initWithRootViewController:secondViewController];
    
    ViewController *thirdViewController = [[ViewController alloc] init];
    UIViewController *thirdNavigationController = [[HKNavigationController alloc] initWithRootViewController:thirdViewController];
    
    ViewController *fourthViewController = [[ViewController alloc] init];
    UIViewController *fourthNavigationController = [[HKNavigationController alloc] initWithRootViewController:fourthViewController];
    
    /**
     * 以下两行代码目的在于手动设置让TabBarItem只显示图标，不显示文字，并让图标垂直居中。
     * 等效于在 `-tabBarItemsAttributesForController` 方法中不传 `CYLTabBarItemTitle` 字段。
     * 更推荐后一种做法。
     */
    //tabBarController.imageInsets = UIEdgeInsetsMake(4.5, 0, -4.5, 0);
    //tabBarController.titlePositionAdjustment = UIOffsetMake(0, MAXFLOAT);

    NSArray *viewControllers = @[
                                 firstNavigationController,
                                 secondNavigationController,
                                 thirdNavigationController,
                                 fourthNavigationController
                                 ];
    return viewControllers;
}

- (NSArray *)tabBarItemsAttributesForController {
    NSDictionary *firstTabBarItemsAttributes = @{
                                                 CYLTabBarItemTitle:@"首页",
                                                 CYLTabBarItemImage:@"home_normal",
                                                 CYLTabBarItemSelectedImage:@"home_highlight"
                                                 };
    NSDictionary *secondTabBarItemsAttributes = @{
                                                 CYLTabBarItemTitle:@"同城",
                                                 CYLTabBarItemImage:@"mycity_normal",
                                                 CYLTabBarItemSelectedImage:@"mycity_highlight"
                                                 };
    NSDictionary *thirdTabBarItemsAttributes = @{
                                                 CYLTabBarItemTitle:@"消息",
                                                 CYLTabBarItemImage:@"message_normal",
                                                 CYLTabBarItemSelectedImage:@"message_highlight"
                                                 };
    NSDictionary *fourthTabBarItemsAttributes = @{
                                                  CYLTabBarItemTitle:@"我的",
                                                  CYLTabBarItemImage:@"account_normal",
                                                  CYLTabBarItemSelectedImage:@"account_highlight"
                                                  };
    NSArray *tabBarItemsAttributes = @[
                                       firstTabBarItemsAttributes,
                                       secondTabBarItemsAttributes,
                                       thirdTabBarItemsAttributes,
                                       fourthTabBarItemsAttributes
                                       ];
    return tabBarItemsAttributes;
}

/**
 *  更多TabBar自定义设置：比如：tabBarItem 的选中和不选中文字和背景图片属性、tabbar 背景图片属性等等
 */
- (UIViewController *)customizeTabBarAppearance:(CYLTabBarController *)tabBarControleller {
    //Customize UITabBar height
    //自定义 TabBar 高度
    tabBarControleller.tabBarHeight = 40.f;
    
    //set the text color for unselected state
    //普通状态下的文字属性
    NSMutableDictionary *normalAttrs = [NSMutableDictionary dictionary];
    normalAttrs[NSForegroundColorAttributeName] = [UIColor grayColor];
    
    //set the text color for selected state
    //选中状态下的文字属性
    NSMutableDictionary *selectedAttrs = [NSMutableDictionary dictionary];
    selectedAttrs[NSForegroundColorAttributeName] = [UIColor blackColor];
    
    //set the text Attributes
    //设置文字属性
    UITabBarItem *tabBar = [UITabBarItem appearance];
    [tabBar setTitleTextAttributes:normalAttrs forState:UIControlStateNormal];
    [tabBar setTitleTextAttributes:selectedAttrs forState:UIControlStateSelected];
    
    // Set the dark color to selected tab (the dimmed background)
    // TabBarItem选中后的背景颜色
    // [self customizeTabBarSelectionIndicatorImage];
    
    // update TabBar when TabBarItem width did update
    // If your app need support UIDeviceOrientationLandscapeLeft or UIDeviceOrientationLandscapeRight，
    // remove the comment '//'
    // 如果你的App需要支持横竖屏，请使用该方法移除注释 '//'
    // [self updateTabBarCustomizationWhenTabBarItemWidthDidUpdate];
    
    // set the bar shadow image
    // This shadow image attribute is ignored if the tab bar does not also have a custom background image.So at least set somthing.

    [[UITabBar appearance] setBackgroundImage:[[UIImage alloc] init]];
    [[UITabBar appearance] setBackgroundColor:[UIColor whiteColor]];
    [[UITabBar appearance] setShadowImage:[UIImage imageNamed:@"tapbar_top_line"]];
    
    // set the bar background image
    // 设置背景图片
    // UITabBar *tabBarAppearance = [UITabBar appearance];
    // [tabBarAppearance setBackgroundImage:[UIImage imageNamed:@"tabbar_background"]];
    
    // remove the bar system shadow image
    // 去除 TabBar 自带的顶部阴影
    // [[UITabBar appearance] setShadowImage:[[UIImage alloc] init]];
    
    return  tabBarControleller;
}

- (void)updateTabBarCustomizationWhenTabBarItemWidthDidUpdate {
    void (^deviceOrientationDidChangeBlock)(NSNotification *) = ^(NSNotification *notification) {
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        if ((orientation == UIDeviceOrientationLandscapeLeft) || (orientation == UIDeviceOrientationLandscapeRight)) {
            NSLog(@"Landscape Left or Right !");
        } else if (orientation == UIDeviceOrientationPortrait) {
            NSLog(@"Landscape portrait !");
        }
        [self customizeTabBarSelectionIndicatorImage];
    };
    [[NSNotificationCenter defaultCenter] addObserverForName:CYLTabBarItemWidthDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:deviceOrientationDidChangeBlock];
}

- (void)customizeTabBarSelectionIndicatorImage {
    //Get initialized TabBar Height if exists, otherwise get Default TabBar Height.
    UITabBarController *tabBarController = [self cyl_tabBarController] ?: [[UITabBarController alloc] init];
    CGFloat tabBarHeight = tabBarController.tabBar.frame.size.height;
    CGSize selectionIndicatorImageSize = CGSizeMake(CYLTabBarItemWidth, tabBarHeight);
    //Get initialized TabBar if exists.
    UITabBar *tabBar = [self cyl_tabBarController].tabBar ?: [UITabBar appearance];
    [tabBar setSelectionIndicatorImage:[[self class] imageWithColor:[UIColor redColor] size:selectionIndicatorImageSize]];
}

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size {
    if (!color || size.width <= 0 || size.height <= 0) return nil;
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width + 1, size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
