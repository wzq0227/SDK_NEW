//
//  HttpTool.h
//  e_life_mobile
//
//  Created by caiyi on 15/7/21.
//  Copyright (c) 2015年 caiyi. All rights reserved.
//

#import <Foundation/Foundation.h>

#define HTTP_SO_TIMEOUT 5 // 最短超时时间
#define HTTP_SHORT_TIMEOUT 10 // 较短超时时间
#define HTTP_DEFAULT_TIMEOUT 15 // 默认超时时间
#define HTTP_MODERATE_TIMEOUT 25 // 适中超时时间
#define HTTP_LONG_TIMEOUT 30 // 较长超时时间
#define HTTP_ONE_MINUTE_TIMEOUT 60 // 一分钟超时时间
#define HTTP_MAX_TIMEOUT 120 // 最大超时时间
#define HTTP_VIDEO_PLAY_MAX_TIMEOUT 90 // 视频点播，HTTP最大超时

typedef void(^SuccessBlock)(id obj);
typedef void(^FailureBlock)(NSInteger code, NSString *errStr);
typedef void(^ServerHandleFailBlock) (NSInteger code, NSString *err_msg); // 发送请求给服务器，服务器处理失败,code为返回的失败代码

@interface HttpTool : NSObject

// post方法
+ (void)postWithPath:(NSString *)path
              params:(NSDictionary *)params
             timeout:(NSInteger)timeout
             success:(SuccessBlock)success
             failure:(ServerHandleFailBlock)failure;

// get方法
+ (void)getWithPath:(NSString *)path
             params:(NSDictionary *)params
            timeout:(NSInteger)timeout
            success:(SuccessBlock)success
            failure:(ServerHandleFailBlock)failure;

// put方法
+ (void)putWithPath:(NSString *)path
             params:(NSDictionary *)params
            timeout:(NSInteger)timeout
            success:(SuccessBlock)success
            failure:(ServerHandleFailBlock)failure;

// delete方法
+ (void)deleteWithPath:(NSString *)path
                params:(NSDictionary *)params
               timeout:(NSInteger)timeout
               success:(SuccessBlock)success
               failure:(ServerHandleFailBlock)failure;

+ (void)requestWithPath:(NSString *)path
                 params:(NSDictionary *)params
                timeout:(NSInteger)timeout
                 method:(NSString *)method
                success:(SuccessBlock)success
                failure:(ServerHandleFailBlock)failure;

@end
