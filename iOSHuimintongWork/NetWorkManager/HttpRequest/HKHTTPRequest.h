//
//  HKHTTPRequest.h
//  iOSHuimintongWork
//
//  Created by gongpengyang on 2021/5/19.
//

#import <Foundation/Foundation.h>
#import "HKNetwork.h"

NS_ASSUME_NONNULL_BEGIN



@interface HKHTTPRequest : NSObject

#pragma mark - Request
/** GET*/
+ (void)GET:(NSString *)URL parameters:(id)parameters  cachePolicy:(HKCachePolicy)cachePolicy success:(HKHttpSuccess)success  failure:(HKHttpFail)failure;
/**  POST*/
+ (void)POST:(NSString *)URL parameters:(id)parameters cachePolicy:(HKCachePolicy)cachePolicy success:(HKHttpSuccess)success failure:(HKHttpFail)failure;

@end

NS_ASSUME_NONNULL_END
