//
//  HttpTool.m
//  e_life_mobile
//
//  Created by caiyi on 15/7/21.
//  Copyright (c) 2015年 caiyi. All rights reserved.
//

#import "AFNetworking.h"
#import "HttpTool.h"


@implementation HttpTool

+ (void)requestWithPath:(NSString *)path
                 params:(NSDictionary *)params
                timeout:(NSInteger)timeout
                 method:(NSString *)method
                success:(SuccessBlock)success
                failure:(ServerHandleFailBlock)failure
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    
    // 拼接传进来的参数
    NSMutableDictionary *allParams = [NSMutableDictionary dictionary];
    if (params)
    {
        [allParams setDictionary:params];
    }
    
    // 生成并设置请求
    NSMutableURLRequest *myRequest;
    if (method && ![method isEqualToString:@"GET"])
    {
        // 非get方式不需要allParams
        myRequest = [[AFJSONRequestSerializer serializer] requestWithMethod:method URLString:path parameters:nil error:nil];
        
        // 在post情况下设置http头和内容
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:allParams options:NSJSONWritingPrettyPrinted error: &error];
        if (error) {
            NSLog(@"转换dic成json出错，error-%@",error);
            return;
        }
        [myRequest setValue:[NSString stringWithFormat:@"application/json; charset=utf-8"] forHTTPHeaderField:@"Content-Type"];
        [myRequest setHTTPBody:jsonData];
    }
    else
    {
        // get
        myRequest = [[AFJSONRequestSerializer serializer] requestWithMethod:method URLString:path parameters:nil error:nil];;
    }

    myRequest.cachePolicy = NSURLRequestUseProtocolCachePolicy;
    myRequest.timeoutInterval = timeout;
    
    NSLog(@"发送请求Url--%@，allParams = %@",myRequest.URL.absoluteString,allParams.description);
    
    // 2.创建AFJSONRequestOperation对象
    [manager dataTaskWithRequest:myRequest completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        
        if (!error) {
            // 3.请求成功，先统一显示处理服务器的错误码
            [self dealWithServerJSON:responseObject success:^(id JSON) {
                if (success) {
                    success(JSON);
                }
            } failure:^(NSInteger code, NSString *err_msg) {
                if (failure) {
                    failure(code, err_msg);
                }
            }];
        }
        else{
            failure((int)[(NSHTTPURLResponse *)response statusCode], nil);
        }
    }];

}


+ (void)postWithPath:(NSString *)path params:(NSDictionary *)params timeout:(NSInteger)timeout success:(SuccessBlock)success failure:(ServerHandleFailBlock)failure
{
    [self requestWithPath:path params:params timeout:timeout method:@"POST" success:^(id JSON) {
        if (success) {
            success(JSON);
        }
    } failure:^(NSInteger code, NSString *err_msg) {
        if (failure) {
            failure(code, err_msg);
        }
    }];
}


+ (void)getWithPath:(NSString *)path
             params:(NSDictionary *)params
            timeout:(NSInteger)timeout
            success:(SuccessBlock)success
            failure:(ServerHandleFailBlock)failure
{
    [[AFHTTPSessionManager manager] GET:path
                             parameters:params
                               progress:^(NSProgress * _Nonnull downloadProgress) {
                                   
                               }
                                success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                    
                                    if (success)
                                    {
                                        success(responseObject);
                                    }
                                }
                                failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                    
                                    if (failure)
                                    {
                                        NSInteger statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
                                        failure(statusCode, nil);
                                    }
                                }];
    
//    [self requestWithPath:path params:params timeout:timeout method:@"GET" success:^(id JSON) {
//        if (success) {
//            success(JSON);
//        }
//    } failure:^(NSInteger code, NSString *err_msg) {
//        if (failure) {
//            failure(code, err_msg);
//        }
//    }];
}


+ (void)putWithPath:(NSString *)path params:(NSDictionary *)params timeout:(NSInteger)timeout success:(SuccessBlock)success failure:(ServerHandleFailBlock)failure
{
    [self requestWithPath:path params:params timeout:timeout method:@"PUT" success:^(id JSON) {
        if (success) {
            success(JSON);
        }
    } failure:^(NSInteger code, NSString *err_msg) {
        if (failure) {
            failure(code, err_msg);
        }
    }];
}


+ (void)deleteWithPath:(NSString *)path params:(NSDictionary *)params timeout:(NSInteger)timeout success:(SuccessBlock)success failure:(ServerHandleFailBlock)failure
{
    [self requestWithPath:path params:params timeout:timeout method:@"DELETE" success:^(id JSON) {
        if (success) {
            success(JSON);
        }
    } failure:^(NSInteger code, NSString *err_msg) {
        if (failure) {
            failure(code, err_msg);
        }
    }];
}

// 处理连接请求成功，处理服务器返回的JSON
+ (void)dealWithServerJSON:(id)JSON success:(SuccessBlock)success failure:(ServerHandleFailBlock)failure
{
    // 判断返回信息
    NSInteger code = 0;
    NSString *err_msg = @"";
    code = [JSON[@"ret"] integerValue];
    err_msg = JSON[@"msg"];


    switch (code)
    {
        case 0: // 处理成功
            if (success)
            {
                success(JSON);
            }
            break;
    }
    
    if (code != 0 && failure)
    {
        failure(code, err_msg);
    }
}

@end
