//
//  HKHTTPRequest.m
//  iOSHuimintongWork
//
//  Created by gongpengyang on 2021/5/19.
//

#import "HKHTTPRequest.h"
#import "HKInterfaceConst.h"


@implementation HKHTTPRequest
/** GET */
+ (void)GET:(NSString *)URL parameters:(id)parameters  cachePolicy:(HKCachePolicy)cachePolicy success:(HKHttpSuccess)success  failure:(HKHttpFail)failure{
    //设置对应接口的Url
    [self requestWithMethod:HKRequestMethodGET url:URL parameters:parameters cachePolicy:cachePolicy success:success failure:failure];
}
/** POST */
+ (void)POST:(NSString *)URL parameters:(id)parameters cachePolicy:(HKCachePolicy)cachePolicy success:(HKHttpSuccess)success failure:(HKHttpFail)failure{
    //设置对应接口的Url
    [self requestWithMethod:HKRequestMethodPOST url:URL parameters:parameters cachePolicy:cachePolicy success:success failure:failure];
}



#pragma mark - 请求的公共方法

+ (void)requestWithMethod:(HKRequestMethod)method url:(NSString *)URL  parameters:(NSDictionary *)parameters cachePolicy:(HKCachePolicy)cachePolicy success:(HKHttpSuccess)success  failure:(HKHttpFail)failure{
    // 在请求之前你可以统一配置你请求的相关参数 ,设置请求头, 请求参数的格式, 返回数据的格式....这样你就不需要每次请求都要设置一遍相关参数
    [HKNetwork openLog];

    [HKNetwork setBaseURL:kApiPrefix];

    //设置缓存过滤 设置后会移除该参数进行缓存
    //
    //[HKNetwork setFiltrationCacheKey:@[@"time",@"ts"]];
    //设置超时时间
    //[HKNetwork setRequestTimeoutInterval:15.0f];
    
    // 设置请求头
    //可一次设置多个也可单独设置
    //[HKNetwork setHeadr:@{@"api-version":@"v1.0.0"}];
    [HKNetwork setValue:@"9" forHTTPHeaderField:@"fromType"];

    //设置公用请求参数
//    NSDictionary *dic = @{@"accountToken":@{@"tokenId":@"",@"userId":@"",@"initDate":@"",@"clientType":@"mobilType",@"tokenKey":@""}};
//    [HKNetwork setBaseParameters:dic];
    
    //可以设置全局等待的指示器
//    [MBProgressHUD mb_loading:^{
//        NSLog(@"hud已经隐藏");
//    }];

    // 发起请求
    [HKNetwork HTTPWithMethod:method url:URL parameters:parameters headers:nil cachePolicy:cachePolicy success:^(id  _Nonnull responseObject) {
        //loading hidden
        success(responseObject);
    } failure:^(NSError * _Nonnull error) {
        //loading hidden
        failure(error);
    }];
}
@end
