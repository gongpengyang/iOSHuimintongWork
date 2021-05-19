//
//  HKInterfaceConst.m
//  iOSHuimintongWork
//
//  Created by gongpengyang on 2021/5/19.
//

#import "HKInterfaceConst.h"

#if DEBUG //测试环境
NSString *const kApiPrefix = @"https://api.pingping6.com/tools/baidutop/";
#else//生产环境
NSString *const kApiPrefix = @"http://api.wpbom.com/api/wallpa.php";
#endif


/** 测试 */
NSString *const kTest = @""; //例子:   /kTest
