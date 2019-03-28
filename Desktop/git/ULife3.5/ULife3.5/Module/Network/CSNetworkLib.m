//
//  CSNetworkLib.m
//  ULife3.5
//  云存储网络连接库
//
//  Created by Goscam on 2017/10/10.
//  Copyright © 2017年 GosCam. All rights reserved.
//


#import "CSNetworkLib.h"
#import <objc/runtime.h>

@implementation CSOrderItemInfo

@end


@implementation CSPackageInfo
@end

@implementation CSRequestBaseObject

///通过运行时获取当前对象的所有属性的名称，以数组的形式返回
- (NSArray *) allPropertyNames{
    ///存储所有的属性名称
    NSMutableArray *allNames = [[NSMutableArray alloc] init];
    
    ///存储属性的个数
    unsigned int propertyCount = 0;
    
    ///通过运行时获取当前类的属性
    objc_property_t *propertys = class_copyPropertyList([self class], &propertyCount);
    
    //把属性放到数组中
    for (int i = 0; i < propertyCount; i ++) {
        ///取出第一个属性
        objc_property_t property = propertys[i];
        
        const char * propertyName = property_getName(property);
        
        [allNames addObject:[NSString stringWithUTF8String:propertyName]];
    }
    ///释放
    free(propertys);
    
    return allNames;
}

#pragma mark -- 通过字符串来创建该字符串的Setter方法，并返回
- (SEL) creatGetterWithPropertyName: (NSString *) propertyName{
    
    //1.返回get方法: oc中的get方法就是属性的本身
    return NSSelectorFromString(propertyName);
}

- (NSString *)requestParamStr{
    
    //获取实体类的属性名
    NSArray *array = [self allPropertyNames];
    
    //拼接参数
    NSMutableString *resultString = [[NSMutableString alloc] init];
    
    for (int i = 0; i < array.count; i ++) {
        
        //获取get方法
        SEL getSel = [self creatGetterWithPropertyName:array[i]];
        
        if ([self respondsToSelector:getSel]) {
            
            //获得类和方法的签名
            NSMethodSignature *signature = [self methodSignatureForSelector:getSel];
            
            //从签名获得调用对象
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            
            //设置target
            [invocation setTarget:self];
            
            //设置selector
            [invocation setSelector:getSel];
            
            //接收返回的值
            NSObject *__unsafe_unretained returnValue = nil;
            
            //调用
            [invocation invoke];
            
            //接收返回值
            [invocation getReturnValue:&returnValue];
            
            if (i==0) {
                [resultString appendFormat:@"?%@=%@", array[i],returnValue];
            }else{
                [resultString appendFormat:@"&%@=%@", array[i],returnValue];
            }
        }
    }
//    NSLog(@"++++++++++++++===================requestParamStr:     %@", resultString);
    return resultString;
}

@end

@implementation CSQueryOrderListReq
@end
@implementation CSQueryOrderListResp
@end


@implementation CSCreateOrderReq
@end

@implementation CSCreateOrderResp
@end

@implementation CSQueryCurServiceResp
@end

@implementation CSAliPayCheckReq
@end

@implementation CSQueryFreePackageReq
@end
@implementation CSQueryFreePackageResp
@end

@implementation CSCreateFreePackageReq
@end
@implementation CSCreateFreePackageResp
@end

@implementation CSPayFreePackageReq
@end


@implementation CSNetworkLib

+(instancetype)sharedInstance {
    
    static dispatch_once_t onceToken;
    static CSNetworkLib *instance = nil;
    if (!instance) {
        dispatch_once(&onceToken, ^{
            instance = [[CSNetworkLib alloc] init];
        });
    }
    return instance;
}
- (void)requestWithURLStr:(NSString *)urlStr method:(NSString *)method result:(RequestResultBlock)result{
    
    NSLog(@"++++++++++++++++URLstr:%@",urlStr);
    
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod: method];
    [req setTimeoutInterval:15];

    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    __block int reqDataResult = -1;
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if ( data != nil) {
            NSMutableDictionary *dict = NULL;
            dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            NSLog(@"CS_ResponseData:%@",dict);
            if(dict != nil && [dict[@"code"] intValue] == 0){
                reqDataResult = 0;
            }else{
                if ([dict[@"code"] length]<=0) {
                    reqDataResult = -1;
                }else{
                    reqDataResult = [dict[@"code"] intValue];
                }
            }
        }else{
            NSDictionary *dict = @{@"code":@"-1",@"message":@"Request Error"};
            data = [dict yy_modelToJSONData];
            reqDataResult = -1;
        }
        result(reqDataResult, data);
    }];
    [dataTask resume];
}

@end
