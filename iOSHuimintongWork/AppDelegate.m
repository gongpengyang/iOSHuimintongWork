//
//  AppDelegate.m
//  iOSHuimintongWork
//
//  Created by gongpengyang on 2021/5/19.
//

#import "AppDelegate.h"
#import "HKTabBarControllerConfig.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //设置主窗口，并设置根控制器
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    HKTabBarControllerConfig *tabBarControllerConfig = [[HKTabBarControllerConfig alloc] init];
    [self.window setRootViewController:tabBarControllerConfig.rootVC];
    [self.window makeKeyAndVisible];
    return YES;
}






@end
