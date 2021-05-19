//
//  HKNetwork.m
//  HKNetwork
//
//  Created by lztb on 2019/8/27.
//  Copyright © 2019 lztbwlkj. All rights reserved.
//

#import "HKNetwork.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "AFNetworking.h"
#import <YYCache/YYCache.h>

#ifdef DEBUG
#define HKLog(FORMAT, ...) fprintf(stderr,"[%s:%d行] %s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define HKLog(...)
#endif

#define NSStringFormat(format,...) [NSString stringWithFormat:format,##__VA_ARGS__]

@implementation HKNetwork

static BOOL _isOpenLog;   // 是否已开启日志打印
static NSMutableArray *_allSessionTask;
static AFHTTPSessionManager *_sessionManager;

static NSDictionary *_baseParameters;
static NSArray *_filtrationCacheKey;
static NSString *const NetworkResponseCache = @"ATNetworkResponseCache";
static NSString * _baseURL;
static YYCache *_dataCache;

/*所有的请求task数组*/
+ (NSMutableArray *)allSessionTask{
    if (!_allSessionTask) {
        _allSessionTask = [NSMutableArray array];
    }
    return _allSessionTask;
}

/*json转字符串*/
#pragma mark 字典转化字符串
+(NSString*)dictionaryToJson:(id)jsonObject{
    if (!jsonObject) return nil;
    if ([jsonObject isKindOfClass:[NSData class]]) {
        if (_isOpenLog) {
            HKLog(@"原数据请求返回响应=== %@",jsonObject);
        }
        return [[NSString alloc] initWithData:jsonObject encoding:NSUTF8StringEncoding];
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:NULL];
    if (jsonData.length == 0) return nil;
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

#pragma mark -- 初始化相关属性
+ (void)initialize{
    _sessionManager = [AFHTTPSessionManager manager];
    //设置请求超时时间
    _sessionManager.requestSerializer.timeoutInterval = 30.f;
    //设置服务器返回结果的类型:JSON(AFJSONResponseSerializer,AFHTTPResponseSerializer)
    _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    _sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    
    _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*",@"multipart/form-data",@"application/x-www-form-urlencoded", nil];
    //开始监测网络状态
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    //打开状态栏菊花
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    _dataCache = [YYCache cacheWithName:NetworkResponseCache];
    
    _isOpenLog = YES;
}


/// 开启日志打印 (Debug级别)
+ (void)openLog{
    _isOpenLog = YES;
}

/// 关闭日志打印,默认关闭
+ (void)closeLog{
    _isOpenLog = NO;
}

/// 有网YES, 无网:NO
+ (BOOL)isNetwork{
    return [AFNetworkReachabilityManager sharedManager].reachable;
}

/// 手机网络:YES, 反之:NO
+ (BOOL)isWWANNetwork{
    return [AFNetworkReachabilityManager sharedManager].reachableViaWWAN;
}

/// WiFi网络:YES, 反之:NO
+ (BOOL)isWiFiNetwork{
    return [AFNetworkReachabilityManager sharedManager].reachableViaWiFi;
}

/// 取消指定URL的HTTP请求
+ (void)cancelRequestWithURL:(NSString *)URL{
    if (!URL) return;
    
    @synchronized (self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task.currentRequest.URL.absoluteString isEqualToString:URL]) {
                [task cancel];
                [[self allSessionTask] removeObject:task];
                *stop = YES;
            }
        }];
    }
}

/// 取消所有HTTP请求
+ (void)cancelAllRequest{
    @synchronized (self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            [task cancel];
        }];
        [[self allSessionTask] removeAllObjects];
    }
}

+ (void)startMonitoring{
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

/// 实时获取网络状态,通过Block回调实时获取(此方法可多次调用)
+ (void)networkStatusWithBlock:(HKNetworkStatus)networkStatus{
    //开启网络监听
    [self startMonitoring];
    
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
       
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                networkStatus ? networkStatus(HKNetworkStatusUnknown) : nil;
                break;
            case AFNetworkReachabilityStatusNotReachable:
                networkStatus ? networkStatus(HKNetworkStatusNotReachable) : nil;
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                networkStatus ? networkStatus(HKNetworkStatusReachableWWAN) : nil;
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                networkStatus ? networkStatus(HKNetworkStatusReachableWiFi) : nil;
                break;
            default:
                break;
        }
    }];
}

+ (void)stopMonitoring{
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
}

/**是否打开网络加载菊花(默认打开)*/
+ (void)openNetworkActivityIndicator:(BOOL)open{
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:open];
}

/**设置请求超时时间(默认30s) */
+ (void)setRequestTimeoutInterval:(NSTimeInterval)time{
    _sessionManager.requestSerializer.timeoutInterval = time;
}


/**过滤缓存Key*/
+ (void)setFiltrationCacheKey:(NSArray *)filtrationCacheKey{
    _filtrationCacheKey = filtrationCacheKey;
}

/**设置接口根路径, 设置后所有的网络访问都使用相对路径 尽量以"/"结束*/
+ (void)setBaseURL:(NSString *)baseURL{
    _baseURL = baseURL;
}

/**设置接口基本参数(如:用户ID, Token)*/
+ (void)setBaseParameters:(NSDictionary *)parameters{
    _baseParameters = parameters;
}

/** 设置接口请求头 */
+ (void)setHeader:(NSDictionary *)header{
    for (NSString * key in header.allKeys) {
        [_sessionManager.requestSerializer setValue:header[key] forHTTPHeaderField:key];
    }
}



#pragma mark -- 缓存描述文字
+ (NSString *)cachePolicyStr:(HKCachePolicy)cachePolicy
{
    switch (cachePolicy) {
        case HKCachePolicyOnlyNetNoCache:
            return @"只从网络获取数据，且数据不会缓存在本地";
            break;
        case HKCachePolicyCacheElseNet:
            return @"从缓存读取数据并返回，再从网络获取并缓存，每次只读取缓存数据";
            break;
        case HKCachePolicyNetElseCache:
            return @"先从网络获取数据并缓存数据，如果访问网络失败再从缓存读取，失败的Block和成功的Block都会执行";
            break;
        case HKCachePolicyCacheThenNet:
            return @"先从缓存读取数据，然后再从网络获取数据，成功的Block将产生两次调用";
            break;
        default:
            break;
    }
}

#pragma mark -- GET请求
+ (void)GET:(NSString *)URL
 parameters:(NSDictionary *)parameters
    headers:(NSDictionary<NSString *,NSString *>*)headers
cachePolicy:(HKCachePolicy)cachePolicy
    success:(HKHttpSuccess)success
    failure:(HKHttpFail)failure{
    [self HTTPWithMethod:HKRequestMethodGET url:URL parameters:parameters headers:headers cachePolicy:cachePolicy success:success failure:failure];
}


#pragma mark -- POST请求
+ (void)POST:(NSString *)URL
  parameters:(NSDictionary *)parameters
     headers:(NSDictionary<NSString *,NSString *>*)headers
 cachePolicy:(HKCachePolicy)cachePolicy
     success:(HKHttpSuccess)success
     failure:(HKHttpFail)failure{
    [self HTTPWithMethod:HKRequestMethodPOST url:URL parameters:parameters headers:headers cachePolicy:cachePolicy success:success failure:failure];
}

#pragma mark -- HEAD请求
+ (void)HEAD:(NSString *)url
  parameters:(NSDictionary *)parameters
     headers:(NSDictionary<NSString *,NSString *>*)headers
 cachePolicy:(HKCachePolicy)cachePolicy
     success:(HKHttpSuccess)success
     failure:(HKHttpFail)failure{
    [self HTTPWithMethod:HKRequestMethodHEAD url:url parameters:parameters headers:headers cachePolicy:cachePolicy success:success failure:failure];
}


#pragma mark -- PUT请求
+ (void)PUT:(NSString *)url
 parameters:(NSDictionary *)parameters
    headers:(NSDictionary<NSString *,NSString *>*)headers
cachePolicy:(HKCachePolicy)cachePolicy
    success:(HKHttpSuccess)success
    failure:(HKHttpFail)failure{
    [self HTTPWithMethod:HKRequestMethodPUT url:url parameters:parameters headers:headers cachePolicy:cachePolicy success:success failure:failure];
}


#pragma mark -- PATCH请求
+ (void)PATCH:(NSString *)url
   parameters:(NSDictionary *)parameters
      headers:(NSDictionary<NSString *,NSString *>*)headers
  cachePolicy:(HKCachePolicy)cachePolicy
      success:(HKHttpSuccess)success
      failure:(HKHttpFail)failure{
    [self HTTPWithMethod:HKRequestMethodPATCH url:url parameters:parameters headers:headers cachePolicy:cachePolicy success:success failure:failure];
}


#pragma mark -- DELETE请求
+ (void)DELETE:(NSString *)url
    parameters:(NSDictionary *)parameters
       headers:(NSDictionary<NSString *,NSString *>*)headers
   cachePolicy:(HKCachePolicy)cachePolicy
       success:(HKHttpSuccess)success
       failure:(HKHttpFail)failure {
    [self HTTPWithMethod:HKRequestMethodDELETE url:url parameters:parameters headers:headers cachePolicy:cachePolicy success:success failure:failure];
}

#pragma mark -- 上传文件
+ (NSURLSessionTask *)uploadFileWithURL:(NSString *)url parameters:(NSDictionary *)parameters
                                headers:(NSDictionary<NSString *,NSString *>*)headers
                                   name:(NSString *)name filePath:(NSString *)filePath
                               progress:(HKHttpProgress)progress
                                success:(HKHttpSuccess)success
                                failure:(HKHttpFail)failure{
    NSURLSessionTask *sessionTask = [_sessionManager POST:url parameters:parameters headers:headers constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        //添加-文件
        NSError *error = nil;
        [formData appendPartWithFileURL:[NSURL URLWithString:filePath] name:name error:&error];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        //上传进度
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(uploadProgress) : nil;
        });
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [[self allSessionTask] removeObject:task];
        success ? success(responseObject) : nil;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [[self allSessionTask] removeObject:task];
        failure? failure(error) : nil;
    }];
    //添加最新的sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
    
    return sessionTask;
}

#pragma mark -- 上传图片文件
+ (NSURLSessionTask *)uploadImageURL:(NSString *)url parameters:(NSDictionary *)parameters
                             headers:(NSDictionary<NSString *,NSString *>*)headers
                              images:(NSArray<UIImage *> *)images
                                name:(NSString *)name
                            fileName:(NSString *)fileName
                          imageScale:(CGFloat)imageScale
                           imageType:(NSString *)imageType
                            progress:(HKHttpProgress)progress
                             success:(HKHttpSuccess)success
                             failure:(HKHttpFail)failure{
    
    NSURLSessionTask *sessionTask = [_sessionManager POST:url parameters:parameters headers:headers constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        //压缩-添加-上传图片
        [images enumerateObjectsUsingBlock:^(UIImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull stop) {
            NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
            
            NSString *imageFileName = fileName;
            if (!imageFileName) {
                // 默认图片的文件名, 若fileNames为nil就使用
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateFormat = @"yyyyMMddHHmHKs";
                NSString *str = [formatter stringFromDate:[NSDate date]];
                imageFileName = NSStringFormat(@"%@%lu.%@", str, idx, imageType ?: @"jpg");
            }
            
            [formData appendPartWithFileData:imageData name:name fileName:NSStringFormat(@"%@%lu.%@",fileName,(unsigned long)idx,imageType ? imageType : @"jpeg")
                                    mimeType:NSStringFormat(@"image/%@",imageType ? imageType : @"jpeg")];
        }];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        //上传进度
        if (_isOpenLog) {
            HKLog(@"上传进度:%.2f%%",100.0*uploadProgress.completedUnitCount / uploadProgress.totalUnitCount);
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(uploadProgress) : nil;
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [[self allSessionTask] removeObject:task];
        success ? success(responseObject) : nil;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [[self allSessionTask] removeObject:task];
        failure? failure(error) : nil;
    }];
    //添加最新的sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
    
    return sessionTask;
};

#pragma mark -- 下载文件
+ (NSURLSessionTask *) downloadWithURL:(NSString *)url fileDir:(NSString *)fileDir progress:(HKHttpProgress)progress success:(HKHttpDownload)success
                               failure:(HKHttpFail)failure{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    __block NSURLSessionDownloadTask *downloadTask = [_sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        if (_isOpenLog) {
            HKLog(@"下载进度:%.2f%%",100.0*downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(downloadProgress) : nil;
        });
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        //拼接缓存目录
        NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileDir ? fileDir : @"Download"];
        
        //打开文件管理器
        NSFileManager *fileManager = [NSFileManager defaultManager];
        //创建DownLoad目录
        [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        //拼接文件路径
        NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
        if (_isOpenLog) {
            HKLog(@"DownLoad filePath = %@",filePath);
        }
        return [NSURL fileURLWithPath:filePath];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        [[self allSessionTask] removeObject:downloadTask];
        if (failure && error) {
            failure ? failure(error) : nil;
            return;
        }
        success ? success(filePath.absoluteString) : nil;
    }];
    //开始下载
    [downloadTask resume];
    
    //添加sessionTask到数组
    downloadTask ? [[self allSessionTask] addObject:downloadTask] : nil;
    
    return downloadTask;
}


+ (NSURLSessionTask *) downloadTaskWithResumeData:(NSData *)resumeData
                                          fileDir:(NSString *)fileDir
                                         progress:(HKHttpProgress)progress
                                          success:(HKHttpDownload)success
                                          failure:(HKHttpFail)failure{
    
    __block NSURLSessionDownloadTask *downloadTask = [_sessionManager downloadTaskWithResumeData:resumeData progress:^(NSProgress * _Nonnull downloadProgress) {
        if (_isOpenLog) {
            HKLog(@"下载进度:%.2f%%",100.0*downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(downloadProgress) : nil;
        });
        
    }destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        //拼接缓存目录
        NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileDir ? fileDir : @"Download"];
        
        //打开文件管理器
        NSFileManager *fileManager = [NSFileManager defaultManager];
        //创建DownLoad目录
        [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        //拼接文件路径
        NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
        if (_isOpenLog) {
            HKLog(@"DownLoad filePath = %@",filePath);
        }
        return [NSURL fileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        [[self allSessionTask] removeObject:downloadTask];
        if (failure && error) {
            failure ? failure(error) : nil;
            return;
        }
        success ? success(filePath.absoluteString) : nil;
    }];
    
    //开始下载
    [downloadTask resume];
    
    //添加sessionTask到数组
    downloadTask ? [[self allSessionTask] addObject:downloadTask] : nil;
    
    return downloadTask;
}




+ (void)HTTPWithMethod:(HKRequestMethod)method
                   url:(NSString *)url
            parameters:(NSDictionary *)parameters
               headers:(NSDictionary<NSString *,NSString *>*)headers
           cachePolicy:(HKCachePolicy)cachePolicy
               success:(HKHttpSuccess)success
               failure:(HKHttpFail)failure{
    
    if (_baseURL.length) {
        url = NSStringFormat(@"%@%@",_baseURL,url);
    }
    
    if (_baseParameters.count) {
        NSMutableDictionary * mutableBaseParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [mutableBaseParameters addEntriesFromDictionary:_baseParameters];
        parameters = [mutableBaseParameters copy];
    }
    
    if (_isOpenLog) {
        HKLog(@"\n请求参数 = %@\n 请求URL = %@\n 请求方式 = %@\n 缓存策略 = %@\n",parameters ? parameters:@"", url, [self getMethodStr:method], [self cachePolicyStr:cachePolicy]);
    }
    
    switch (cachePolicy) {
        case HKCachePolicyOnlyNetNoCache:{
            //只从网络获取数据，且数据不会缓存在本地
            [self httpWithMethod:method url:url parameters:parameters headers:headers success:success failure:failure];
        }
            break;
        case  HKCachePolicyCacheElseNet:{
            //从缓存读取数据并返回，再从网络获取并缓存，每次只读取缓存数据
            [self httpCacheForURL:url parameters:parameters withBlock:^(id<NSCoding> object) {
                success ? success(object) : nil;
                [self httpWithMethod:method url:url parameters:parameters headers:headers success:^(id responseObject) {
                    [self setHttpCache:responseObject url:url parameters:parameters];
                } failure:failure];
            }];
        }
            break;
        case HKCachePolicyNetElseCache:{
            //先从网络获取数据，同时会在本地缓存数据，如果没有（此处的没有可以理解为访问网络失败）再从缓存读取，并且返回Error
            [self httpWithMethod:method url:url parameters:parameters headers:headers success:^(id responseObject) {
                success ? success(responseObject) : nil;
                [self setHttpCache:responseObject url:url parameters:parameters];
            } failure:^(NSError *error) {
                [self httpCacheForURL:url parameters:parameters withBlock:^(id<NSCoding> object) {
                    success ? success(object) : nil;
                }];
                failure(error);
            }];
        }
            break;
        case HKCachePolicyCacheThenNet:{
            //先从缓存读取数据，然后在从网络获取并且缓存，在这种情况下，Block将产生两次调用
            [self httpCacheForURL:url parameters:parameters withBlock:^(id<NSCoding> object) {
                if (object) {
                    success ? success(object) : nil;
                }
                [self httpWithMethod:method url:url parameters:parameters headers:headers success:^(id responseObject) {
                    //尽量避免多次调用Block
                    if (object != responseObject && responseObject) {
                        [self setHttpCache:responseObject url:url parameters:parameters];
                        success ? success(responseObject) : nil;
                    }
                } failure:failure];
            }];
        }
            break;
            
        default:
            break;
    }
}


#pragma mark -- 网络请求处理
+ (void)httpWithMethod:(HKRequestMethod)method url:(NSString *)url parameters:(NSDictionary *)parameters headers:(NSDictionary<NSString *,NSString *>*)headers success:(HKHttpSuccess)success failure:(HKHttpFail)failure{
    
    [self dataTaskWithHTTPMethod:method url:url parameters:parameters headers:headers success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
        if (_isOpenLog) {
            HKLog(@"请求结果 = %@",[self dictionaryToJson:responseObject]);
        }
        [[self allSessionTask] removeObject:task];
        success ? success(responseObject) : nil;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (_isOpenLog) {
            HKLog(@"错误内容 = %@",error);
        }
        failure ? failure(error) : nil;
        [[self allSessionTask] removeObject:task];
    }];
    
}


+ (void)dataTaskWithHTTPMethod:(HKRequestMethod)method url:(NSString *)url
                    parameters:(NSDictionary *)parameters
                       headers:(NSDictionary<NSString *,NSString *>*)headers
                       success:(void (^)(NSURLSessionDataTask * _Nullable, id _Nullable))success
                       failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure {
    NSURLSessionTask *sessionTask;
    
    switch (method) {
        case HKRequestMethodGET:{
            sessionTask = [_sessionManager GET:url parameters:parameters headers:headers progress:nil success:success failure:failure];
        }
            break;
        case HKRequestMethodPOST:{
            sessionTask = [_sessionManager POST:url parameters:parameters headers:headers progress:nil success:success failure:failure];
        }
            break;
        case HKRequestMethodHEAD:{
            sessionTask = [_sessionManager HEAD:url parameters:parameters headers:headers success:^(NSURLSessionDataTask * _Nonnull task) {
                success(task,nil);
            } failure:failure];
        }
            break;
        case HKRequestMethodPUT:{
//            NSMutableString *appedUrl = [NSMutableString string];
//            [parameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
//                [appedUrl appendFormat:@"%@&%@",key,obj];
//            }];
//            url = NSStringFormat(@"%@?%@",url,appedUrl);
            sessionTask = [_sessionManager PUT:url parameters:parameters headers:headers success:success failure:failure];
        }
            break;
        case HKRequestMethodPATCH:{
            sessionTask = [_sessionManager PATCH:url parameters:parameters headers:headers success:success failure:failure];
        }
            break;
        case HKRequestMethodDELETE:{
            sessionTask = [_sessionManager DELETE:url parameters:parameters headers:headers success:success failure:failure];
            break;
        }
        default:
            break;
    }
    //添加最新的sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
}


+ (NSString *)getMethodStr:(HKRequestMethod)method{
    switch (method) {
        case HKRequestMethodGET:
            return @"GET";
            break;
        case HKRequestMethodPOST:
            return @"POST";
            break;
        case HKRequestMethodHEAD:
            return @"HEAD";
            break;
        case HKRequestMethodPUT:
            return @"PUT";
            break;
        case HKRequestMethodPATCH:
            return @"PATCH";
            break;
        case HKRequestMethodDELETE:
            return @"DELETE";
            break;
            
        default:
            break;
    }
}

#pragma mark -- 网络缓存
+ (YYCache *)getYYCache
{
    return _dataCache;
}

+ (void)setHttpCache:(id)httpData url:(NSString *)url parameters:(NSDictionary *)parameters{
    if (httpData) {
        NSString *cacheKey = [self cacheKeyWithURL:url parameters:parameters];
        //        NSString *cacheTime = NSStringFormat(@"%@Time",cacheKey);//缓存时间
        //        [_dataCache setObject:[NSDate date] forKey:cacheTime];
        [_dataCache setObject:httpData forKey:cacheKey withBlock:nil];
    }
}

+ (void)httpCacheForURL:(NSString *)url parameters:(NSDictionary *)parameters withBlock:(void(^)(id responseObject))block
{
    NSString *cacheKey = [self cacheKeyWithURL:url parameters:parameters];
    // NSString *cacheTime = NSStringFormat(@"%@Time",cacheKey);//缓存时间
    
    [_dataCache objectForKey:cacheKey withBlock:^(NSString * _Nonnull key, id<NSCoding>  _Nonnull object) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_isOpenLog) {
                HKLog(@"缓存结果 = %@",[self dictionaryToJson:object]);
            }
            block(object);
        });
    }];
    
}


+ (void)setCostLimit:(NSInteger)costLimit{
    [_dataCache.diskCache setCostLimit:costLimit];//磁盘最大缓存开销
}

+ (NSInteger)getAllHttpCacheSize{
    return [_dataCache.diskCache totalCost];
}

+ (void)getAllHttpCacheSizeBlock:(void(^)(NSInteger totalCount))block{
    return [_dataCache.diskCache totalCountWithBlock:block];
}

+ (void)removeAllHttpCache{
    [_dataCache.diskCache removeAllObjects];
}

+ (void)removeAllHttpCacheBlock:(void(^)(int removedCount, int totalCount))progress
                       endBlock:(void(^)(BOOL error))end{
    [_dataCache.diskCache removeAllObjectsWithProgressBlock:progress endBlock:end];
}

+ (NSString *)cacheKeyWithURL:(NSString *)url parameters:(NSDictionary *)parameters
{
    if(!parameters){return url;};
    
    if (_filtrationCacheKey.count) {
        NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [mutableParameters removeObjectsForKeys:_filtrationCacheKey];
        parameters =  [mutableParameters copy];
    }
    
    /// 将URL与转换好的参数字符串拼接在一起,成为最终存储的KEY值
    NSString *cacheKey = [NSString stringWithFormat:@"%@%@",url,[self dictionaryToJson:parameters]];
    
    return cacheKey;
}


/************************************重置AFHTTPSessionManager相关属性**************/
#pragma mark -- 重置AFHTTPSessionManager相关属性

+ (void)setAFHTTPSessionManagerProperty:(void (^)(AFHTTPSessionManager *))sessionManager {
    sessionManager ? sessionManager(_sessionManager) : nil;
}

+ (void)setRequestSerializer:(HKRequestSerializer)requestSerializer{
    _sessionManager.requestSerializer = requestSerializer== HKRequestSerializerHTTP ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer];
}

+ (void)setResponseSerializer:(HKResponseSerializer)responseSerializer{
    _sessionManager.responseSerializer = responseSerializer== HKResponseSerializerHTTP ? [AFHTTPResponseSerializer serializer] : [AFJSONResponseSerializer serializer];
}


+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field{
    [_sessionManager.requestSerializer setValue:value forHTTPHeaderField:field];
}


+ (void)setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName{
    
    NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
    //使用证书验证模式
    AFSecurityPolicy *securitypolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    //如果需要验证自建证书(无效证书)，需要设置为YES
    securitypolicy.allowInvalidCertificates = YES;
    //是否需要验证域名，默认为YES
    securitypolicy.validatesDomainName = validatesDomainName;
    securitypolicy.pinnedCertificates = [[NSSet alloc]initWithObjects:cerData, nil];
    [_sessionManager setSecurityPolicy:securitypolicy];
}


@end






#pragma mark -- NSDictionary,NSArray的分类
/*
 ************************************************************************************
 *新建NSDictionary与NSArray的分类, 控制台打印json数据中的中文
 ************************************************************************************
 */
//#ifdef DEBUG
@implementation NSArray (AT)

- (NSString *)descriptionWithLocale:(id)locale{
    
    NSMutableString *strM = [NSMutableString stringWithString:@"(\n"];
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [strM appendFormat:@"\t%@,\n",obj];
    }];
    [strM appendString:@")\n"];
    return  strM;
}
@end

@implementation NSDictionary (AT)

- (NSString *)descriptionWithLocale:(id)locale{
    
    NSMutableString *strM = [NSMutableString stringWithString:@"{\n"];
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [strM appendFormat:@"\t%@ = %@,\n",key,obj];
    }];
    [strM appendString:@"}\n"];
    return  strM;
}

@end
