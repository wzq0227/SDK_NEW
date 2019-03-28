//
//  DevPushManagement.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/12.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "DevPushManagement.h"
#import "PushDevListModel.h"
#import "TMCacheExtend.h"
#import "NetSDK.h"
#import "SaveDataModel.h"


#define PUSH_LIST_CACHE_KEY @"pushDevListCache"

//#define DIS    0
//#define DEV    1


#define DEV 0

//#ifdef DEBUG
//#define DEV 1 //debug模式下是1
//#else
//#define DEV 0 //release下是0
//#endif

static const NSString *baseUrl  = @"htttp://www.12323/";
static const NSString *push_Url = @"http://push.iotcplatform.com/";


@interface DevPushManagement ()

@property (nonatomic, strong) dispatch_queue_t devPushManagerQueue;
@property (nonatomic, strong) PushDevListModel *pushListModel;
@property (strong, nonatomic)  NSMutableDictionary *urlReqTimeMapping;

@end


@implementation DevPushManagement

+ (instancetype)shareDevPushManager
{
    static DevPushManagement *g_devPushManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if (nil == g_devPushManager)
        {
            g_devPushManager = [[DevPushManagement alloc] init];
        }
    });
    return g_devPushManager;
}


- (instancetype)init
{
    if (self = [super init])
    {
        self.devPushManagerQueue = dispatch_queue_create("DevPushManagerQueue", DISPATCH_QUEUE_CONCURRENT);
        self.isRegisteToken      = NO;
        PushDevListModel *listModel = [[TMCache sharedCache] objectForKey:PUSH_LIST_CACHE_KEY];
        
        _urlReqTimeMapping = [NSMutableDictionary dictionaryWithCapacity:1];
        if (!listModel)
        {
            self.pushListModel = [[PushDevListModel alloc] init];
            self.pushListModel.deviceArray = [[NSMutableArray alloc] initWithCapacity:0];
        }
        else
        {
            BOOL deleteFlag = NO;
            for (int i = 0; i <  listModel.deviceArray.count; i++)
            {
                PushDevModel *pushDevModel = listModel.deviceArray[i];
                if ([pushDevModel isKindOfClass:[NSString class]])
                {
                    deleteFlag = YES;
                    break;
                }
            }
            if (YES == deleteFlag)
            {
                [[TMCache TemporaryCache] removeObjectForKey:PUSH_LIST_CACHE_KEY];
                self.pushListModel = [[PushDevListModel alloc]init];
                self.pushListModel.deviceArray = [[NSMutableArray alloc] initWithCapacity:0];
            }
            else
            {
                self.pushListModel = listModel;
            }
            [self savePushListCache];
        }
    }
    return self;
}


#pragma mark - 私有方法
#pragma mark -- 保存注册缓存
- (void)savePushListCache
{
    @synchronized (self) {
        if (!self.pushListModel)
        {
            return;
        }
        [[TMCache sharedCache] setObject:self.pushListModel
                                  forKey:PUSH_LIST_CACHE_KEY];
    }
}


#pragma mark -- 保存新注册设备
- (BOOL)savePushDevModel:(PushDevModel *)devModel
{
    //加锁
    @synchronized (self) {
        if (!devModel || IS_STRING_EMPTY(devModel.deviceId))
        {
            NSLog(@"无法添加注册新设备！");
            return NO;
        }
        
        BOOL isExist = NO;
        int index = 0;
        for (int i = 0; i < self.pushListModel.deviceArray.count; i++)
        {
            PushDevModel *tempDevModel = self.pushListModel.deviceArray[i];
            if ([devModel.deviceId isEqualToString:tempDevModel.deviceId])
            {
                isExist = YES;
                index = i;
                break;
            }
        }
        if (NO == isExist)
        {
            [self.pushListModel.deviceArray addObject:devModel];
            isExist = YES;
        }
        else{
            [self.pushListModel.deviceArray replaceObjectAtIndex:index
                                                      withObject:devModel];
        }
        [self savePushListCache];
        return isExist;
    }
}


#pragma mark -- 删除注册设备
- (BOOL)deletePushDevModelWihDeviceId:(NSString *)deviceId
{
    @synchronized (self) {
        if (IS_STRING_EMPTY(deviceId))
        {
            NSLog(@"无法删除注册设备, deviceId = nil !");
            return NO;
        }
        
        BOOL isExsit = NO;
        int index = 0;
        for (int i = 0; i < self.pushListModel.deviceArray.count; i++)
        {
            PushDevModel *tempDevModel = self.pushListModel.deviceArray[i];
            if ([deviceId isEqualToString:tempDevModel.deviceId])
            {
                index = i;
                isExsit = YES;
            }
        }
        
        if (isExsit) {
            [self.pushListModel.deviceArray removeObjectAtIndex:index];
            NSLog(@"删除注册推送设备, deviceId = %@ !", deviceId);
        }
        [self savePushListCache];
        return YES;
    }
}


#pragma mark - 公有方法
#pragma mark -- 注册 iOS 设备 TUTK 推送 token
- (void)registTutkPushWithToken:(NSString *)pushToken
                    resultBlock:(void (^) (BOOL isSuccess))resultBlock
{
    if (IS_STRING_EMPTY(pushToken))
    {
        NSLog(@"无法注册 TUTK推送，pushToken = nil ");
        return;
    }
    if ([pushToken isEqualToString:self.pushListModel.pushToken])
    {
        //        NSLog(@"TUTK 推送已经注册成功！");
        self.isRegisteToken = YES;
        //        [self savePushListCache];
        //        if (resultBlock)
        //        {
        //            resultBlock(YES);
        //        }
        //        return;
    }
    // 注意一定确保真机可以正常访问下面的地址
    // NSString *urlStr = @"/tpns?cmd=client&os=ios&appid={%APPID%}&udid={%UDID}%token={%TOKEN%}lang=enUS%ucid=&dev=<1>";
    dispatch_async(self.devPushManagerQueue, ^{
        NSString *token   = [NSString stringWithFormat:@"&token=%@",pushToken];
        NSString *postUrl = [NSString stringWithFormat:@"tpns?cmd=client&os=ios%@%@%@%@&ucid=&dev=%d",[self getAppId], token,[self getUdid], [self getLanguage], DEV];
        NSString *urlresp = [NSString stringWithFormat:@"%@%@",push_Url,postUrl];
        NSString *urlStr  = [urlresp stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSLog(@"regist tutk apns token url = %@", urlStr);
        [self httpGetWithUrl:urlStr
                successBlock:^(NSData *data) {
                    NSString *dataStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                    NSLog(@"TUTK 推送注册成功！%@",dataStr);
                    self.pushListModel.pushToken = pushToken;
                    self.isRegisteToken = YES;
                    [self savePushListCache];
                    if (resultBlock)
                    {
                        resultBlock(YES);
                    }
                }
                failureBlock:^(NSError *error) {
                    NSLog(@"TUTK 推送注册失败, errorCode = %ld", (long)error.code);
                    self.isRegisteToken = NO;
                    if (resultBlock)
                    {
                        resultBlock(NO);
                    }
                } withDeviceID:nil];
    });
}


- (NSString *)getPushToken
{
    return self.pushListModel.pushToken;
}


#pragma mark -- 查询设备推送是否打开
- (BOOL)isOpenPushWithDeviceId:(NSString *)deviceId
{
    if (IS_STRING_EMPTY(deviceId))
    {
        return NO;
    }
    for (int i = 0; i < self.pushListModel.deviceArray.count; i++)
    {
        PushDevModel *tempDevModel = self.pushListModel.deviceArray[i];
        if ([deviceId isEqualToString:tempDevModel.deviceId])
        {
            return tempDevModel.isRegistry;
        }
    }
    return YES;
}




#pragma mark -- 打开设备推送
- (void)openPushWithDeviceId:(NSString *)deviceId
                 resultBlock:(void (^)(BOOL isSuccess))resultBlock
{
    if (IS_STRING_EMPTY(deviceId))
    {
        NSLog(@"无法打开设备推送，deviceId = nil！");
        if (resultBlock)
        {
            resultBlock(NO);
        }
        return;
    }
    if (NO == self.isRegisteToken)
    {
        NSLog(@"pushToken 没有注册，无法打开设备推送！");
        if (resultBlock)
        {
            resultBlock(NO);
        }
        return;
    }
    //    if (YES == [self isOpenPushWithDeviceId:deviceId])
    //    {
    //        NSLog(@"打开设备推送成功，deviceId = %@", deviceId);
    //        if (resultBlock)
    //        {
    //            resultBlock(YES);
    //        }
    //        return;
    //    }
    
    //不去校验，就去打开
    [self addPushWithDeviceId:deviceId
                  resultBlock:^(BOOL isSuccess) {
                      if (resultBlock)
                      {
                          resultBlock(isSuccess);
                      }
                  }];
}


#pragma mark -- 关闭设备推送
- (void)closePushWithDeviceId:(NSString *)deviceId
                  resultBlock:(void (^)(BOOL isSuccess))resultBlock
{
    if (IS_STRING_EMPTY(deviceId))
    {
        NSLog(@"无法关闭设备推送，deviceId = nil！");
        if (resultBlock)
        {
            resultBlock(NO);
        }
        return;
    }
    //    if (NO == [self isOpenPushWithDeviceId:deviceId])
    //    {
    //        NSLog(@"关闭设备推送成功，deviceId = %@", deviceId);
    //        if (resultBlock)
    //        {
    //            resultBlock(YES);
    //        }
    //        return;
    //    }
    
    //不去校验--直接去关闭推送
    [self removePushWithDeviceId:deviceId
                     resultBlock:^(BOOL isSuccess) {
                         
                         if (resultBlock)
                         {
                             resultBlock(isSuccess);
                         }
                     }];
}


#pragma mark -- 删除设备推送
- (void)deletePushWithDeviceId:(NSString *)deviceId
                   resultBlock:(void (^)(BOOL isSuccess))resultBlock
{
    if (IS_STRING_EMPTY(deviceId))
    {
        NSLog(@"无法删除设备推送，deviceId = nil！");
        if (resultBlock)
        {
            resultBlock(NO);
        }
        return;
    }
    __weak typeof(self)weakSelf = self;
    [self closePushWithDeviceId:deviceId
                    resultBlock:^(BOOL isSuccess) {
                        
                        if (NO == isSuccess)
                        {
                            if (resultBlock)
                            {
                                resultBlock(NO);
                            }
                        }
                        else
                        {
                            __strong typeof(weakSelf)strongSelf = weakSelf;
                            if (!strongSelf)
                            {
                                NSLog(@"对象丢失，无法删除缓存推送！");
                                return ;
                            }
                            if (resultBlock)
                            {
                                resultBlock(YES);
                            }
                            [strongSelf deletePushDevModelWihDeviceId:deviceId];
                        }
                    }];
}


#pragma mark - TUTK 推送对接
#pragma mark -- 开启设备 TUTK 推送
- (void)addPushWithDeviceId:(NSString *)deviceId
                resultBlock:(void (^) (BOOL isSuccess))resultBlock
{
    if (IS_STRING_EMPTY(deviceId))
    {
        NSLog(@"添加设备推送失败！");
        if (resultBlock)
        {
            resultBlock(NO);
        }
        return;
    }
    dispatch_async(self.devPushManagerQueue, ^{
        NSString *tutkDevId = deviceId;
        if (20 == deviceId.length)
        {
            tutkDevId = deviceId;
        }
        else if (28 == deviceId.length)
        {
            tutkDevId = [deviceId substringFromIndex:8];
        }
        else
        {
            tutkDevId = deviceId;
        }
        NSString *uid      = [NSString stringWithFormat:@"&uid=%@",tutkDevId];
        NSString *interavl = [NSString stringWithFormat:@"&interval=%d",0];
        //        NSString *sound    = [NSString stringWithFormat:@"&sound=sound.alf"];
        //        NSString *format   = [NSString stringWithFormat:@"&format=base64"];
        NSString *postStr  = [NSString stringWithFormat:@"tpns?cmd=mapping&os=ios%@%@%@%@", [self getAppId], uid, [self getUdid], interavl];
        NSString *urlStr   = [NSString stringWithFormat:@"%@%@",push_Url,postStr];
        urlStr             = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSLog(@"Open pushUrl = %@", urlStr);
        
        [self httpGetWithUrl:urlStr
                successBlock:^(NSData *data) {
                    NSString *str = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                    NSLog(@"deviceId = %@ 添加推送注册成功！%@", deviceId,str);
                    PushDevModel *newDevModel = [[PushDevModel alloc] init];
                    newDevModel.deviceId      = deviceId;
                    newDevModel.isRegistry    = YES;
                    //用户设置是打开的
                    [self savePushDevModel:newDevModel];
                    if (resultBlock)
                    {
                        resultBlock(YES);
                    }
                }
                failureBlock:^(NSError *error) {
                    
                    NSLog(@"deviceId = %@ 添加推送注册失败, errorCode = %ld", deviceId, (long)error.code);
                    PushDevModel *newDevModel = [[PushDevModel alloc] init];
                    newDevModel.deviceId      = deviceId;
                    newDevModel.isRegistry    = NO;
                    //用户设置是关闭的
                    [self savePushDevModel:newDevModel];
                    if (resultBlock)
                    {
                        resultBlock(NO);
                    }
                } withDeviceID:deviceId];
    });
    
    
    //打开自有平台推送
    dispatch_async(self.devPushManagerQueue, ^{
        NSString *tutkDevId = deviceId;
        NSArray *deviceArray = @[@{@"DeviceId":deviceId,@"PushFlag":@1}];
        NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
        NSString *uuidStr = [SYDeviceInfo identifierForVender];
        NSDictionary *addDeviceDict = @
        {
            @"MessageType":@"SetDevicePushStateRequest",//APP用户把设备是否推送消息的设置发送到服务器
            @"Body":
            @{
              @"Terminal":@"iphone",//终端系统类型
              @"UUID":uuidStr,//手机唯一标识
              @"AppId":bundleId,//APP唯一表示符号
              @"DeviceList": deviceArray,
              @"UserName":[SaveDataModel getUserName],//app就填账户名，dev就填ID
              }
        };
        
        
        [[NetSDK sharedInstance] net_sendCBSRequestWithData:addDeviceDict timeout:15000 responseBlock:^(int result, NSDictionary *dict) {
            if ([dict[@"MessageType"] isEqualToString:@"SetDevicePushStateResponse"]) {
                if (result == 0) {
                    //添加成功
                    NSLog(@"deviceId = %@ 添加推送注册成功!",tutkDevId);
                    //                PushDevModel *newDevModel = [[PushDevModel alloc] init];
                    //                newDevModel.deviceId      = deviceId;
                    //                newDevModel.isRegistry    = YES;
                    //                //用户设置是打开的
                    //                [self savePushDevModel:newDevModel];
                    //                if (resultBlock)
                    //                {
                    //                    resultBlock(YES);
                    //                }
                    
                }
                else{
                    NSLog(@"deviceId = %@ 添加推送注册失败", deviceId);
                    //                PushDevModel *newDevModel = [[PushDevModel alloc] init];
                    //                newDevModel.deviceId      = deviceId;
                    //                newDevModel.isRegistry    = NO;
                    //                //用户设置是关闭的
                    //                [self savePushDevModel:newDevModel];
                    //                if (resultBlock)
                    //                {
                    //                    resultBlock(NO);
                    //                }
                }
            }
        }];
    });
    
    
}


#pragma mark -- 关闭设备 TUTK 推送
- (void)removePushWithDeviceId:(NSString *)deviceId
                   resultBlock:(void (^) (BOOL isSuccess))resultBlock
{
    if (IS_STRING_EMPTY(deviceId))
    {
        NSLog(@"删除设备推送失败！");
        if (resultBlock)
        {
            resultBlock(NO);
        }
        return;
    }
    dispatch_async(self.devPushManagerQueue, ^{
        NSString *tutkDevId = deviceId;
        if (20 == deviceId.length)
        {
            tutkDevId = deviceId;
        }
        else if (28 == deviceId.length)
        {
            tutkDevId = [deviceId substringFromIndex:8];
        }
        else
        {
            tutkDevId = deviceId;
        }
        NSString *uid     = [NSString stringWithFormat:@"&uid=%@",tutkDevId];
        NSString *postStr = [NSString stringWithFormat:@"tpns?cmd=rm_mapping&os=ios%@%@%@", [self getAppId], uid, [self getUdid]];
        NSString *urlStr  = [NSString stringWithFormat:@"%@%@",push_Url,postStr];
        urlStr            = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSLog(@"Close pushUrl = %@", urlStr);
        [self httpGetWithUrl:urlStr
                      successBlock:^(NSData *data) {
                          NSLog(@"deviceId = %@ 移除TUTK推送注册成功！", deviceId);
                          PushDevModel *newDevModel = [[PushDevModel alloc] init];
                          newDevModel.deviceId      = deviceId;
                          newDevModel.isRegistry    = NO;
                          [self savePushDevModel:newDevModel];
                          if (resultBlock)
                          {
                              resultBlock(YES);
                          }
                      }
                      failureBlock:^(NSError *error) {
                          NSLog(@"deviceId = %@ 移除TUTK推送注册失败, errorCode = %ld", deviceId, (long)error.code);
                          PushDevModel *newDevModel = [[PushDevModel alloc] init];
                          newDevModel.deviceId      = deviceId;
                          newDevModel.isRegistry    = YES;
                          //用户设置是打开的 --因为没有删除成功
                          [self savePushDevModel:newDevModel];
                          if (resultBlock)
                          {
                              resultBlock(NO);
                          }
                      } withDeviceID:deviceId];
    });
    
    
    //关闭自有平台推送
    dispatch_async(self.devPushManagerQueue, ^{
        NSArray *deviceArray = @[@{@"DeviceId":deviceId,@"PushFlag":@0}];
        NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
        NSString *uuidStr = [SYDeviceInfo identifierForVender];
        NSDictionary *removeDeviceDict = @
        {
            @"MessageType":@"SetDevicePushStateRequest",//APP用户把设备是否推送消息的设置发送到服务器
            @"Body":
            @{
              @"Terminal":@"iphone",//终端系统类型
              @"UUID":uuidStr,//手机唯一标识
              @"AppId":bundleId,//APP唯一表示符号
              @"DeviceList": deviceArray,
              @"UserName":[SaveDataModel getUserName],//app就填账户名，dev就填ID
              }
        };
        
        
        [[NetSDK sharedInstance] net_sendCBSRequestWithData:removeDeviceDict timeout:15000 responseBlock:^(int result, NSDictionary *dict) {
            //SetDevicePushStateResponse
            
            if ([dict[@"MessageType"] isEqualToString:@"SetDevicePushStateResponse"]) {
                if (result == 0) {
                    //添加成功
                    NSLog(@"deviceId = %@ 移除平台推送注册成功!",deviceId);
                    //                PushDevModel *newDevModel = [[PushDevModel alloc] init];
                    //                newDevModel.deviceId      = deviceId;
                    //                newDevModel.isRegistry    = NO;
                    //                [self savePushDevModel:newDevModel];
                    //                if (resultBlock)
                    //                {
                    //                    resultBlock(YES);
                    //                }
                    
                }
                else{
                    NSLog(@"deviceId = %@ 移除平台推送注册失败", deviceId);
                    //                PushDevModel *newDevModel = [[PushDevModel alloc] init];
                    //                newDevModel.deviceId      = deviceId;
                    //                newDevModel.isRegistry    = YES;
                    //                //用户设置是打开的 --因为没有删除成功
                    //                [self savePushDevModel:newDevModel];
                    //                if (resultBlock)
                    //                {
                    //                    resultBlock(YES);
                    //                }
                }
            }

        }];
    });
}


- (NSString *)getAppId
{
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    NSString *appidStr = [NSString stringWithFormat:@"&appid=%@",bundleId];
    return appidStr;
}


- (NSString *)getUdid
{
    NSString *uuidStr = [SYDeviceInfo identifierForVender];
    NSString *udid    = [NSString stringWithFormat:@"&udid=%@",uuidStr];
    return udid;
}


- (NSString *)getLanguage
{
    NSString *language = [NSString stringWithFormat:@"&lang=enUS"];
    return language;
}


#pragma mark -- 网络请求
- (void)httpGetWithUrl:(NSString *)urlStr
          successBlock:(void (^)(NSData *data))successBlock
          failureBlock:(void (^)(NSError *error))failureBlock withDeviceID:(NSString *)deviceID
{
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setTimeoutInterval:3];
    NSURLSession *session = [NSURLSession sharedSession];
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *sessionDataTask = [session dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
                                             {
                                                 NSHTTPURLResponse *httpResp =(NSHTTPURLResponse*)response;
                                                 NSString *str = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                                                 if (!error && httpResp.statusCode==200)
                                                 {
                                                     if ([str containsString:@"422"])
                                                         [weakSelf addToNoWhiteList:deviceID];
                                                     
                                                     successBlock(data);
                                                 }
                                                 else
                                                 {
                                                     if (YES == [weakSelf isInNoWhiteList:deviceID])    {
                                                         successBlock(data);
                                                         return;
                                                     }
                                                     
                                                     if (![weakSelf.urlReqTimeMapping objectForKey:urlStr]) {
                                                         [weakSelf.urlReqTimeMapping setObject:@(0) forKey:urlStr];
                                                     }else{
                                                         NSNumber *failedTimes = [weakSelf.urlReqTimeMapping valueForKey:urlStr];
                                                         [weakSelf.urlReqTimeMapping setValue:@(failedTimes.intValue +1) forKey:urlStr];
                                                         if (failedTimes.intValue > 5) {
                                                             failureBlock(nil);
                                                             return ;
                                                         }
                                                     }
                                                     [weakSelf httpGetWithUrl:urlStr successBlock:^(NSData *data) {
                                                         successBlock(data);
                                                     } failureBlock:^(NSError *error) {
                                                         failureBlock(error);
                                                     } withDeviceID:deviceID];
                                                 }
                                             }];
    [sessionDataTask resume];
}

- (void)resendReqWithUrl:(NSString *)urlStr
            successBlock:(void (^)(NSData *data))resendSucBlock
            failureBlock:(void (^)(NSError *error))resendFailBlock
{
    if (!urlStr||urlStr.length<=0) {
        resendFailBlock(nil);
    }
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setTimeoutInterval:5];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *sessionDataTask = [session dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
                                             {
                                                 NSHTTPURLResponse *httpResp =(NSHTTPURLResponse*)response;
                                                 NSLog(@"TUTK_PUSH_OP_RESP_CODE1_________________:%ld",httpResp.statusCode);
                                                 if (!error && httpResp.statusCode==200)
                                                 {
                                                     resendSucBlock(data);
                                                 }
                                                 else
                                                 {
                                                     resendFailBlock(error);
                                                 }
                                             }];
    [sessionDataTask resume];
}

- (void)addToNoWhiteList:(NSString *)deviceID {
    if (!deviceID || deviceID.length <= 0)
        return;
    
    NSMutableArray *arrayM = [[[NSUserDefaults standardUserDefaults] objectForKey:@"NoWhiteList"] mutableCopy];
    if (!arrayM)
        arrayM = [@[] mutableCopy];
    
    if (![arrayM containsObject:deviceID])
        [arrayM addObject:deviceID];
    
    [[NSUserDefaults standardUserDefaults] setObject:arrayM forKey:@"NoWhiteList"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isInNoWhiteList:(NSString *)deviceID {
    if (!deviceID || deviceID.length <= 0)
        return NO;
    
    NSMutableArray *arrayM = [[NSUserDefaults standardUserDefaults] objectForKey:@"NoWhiteList"];
    if (!arrayM)
        return NO;
    
    if ([arrayM containsObject:deviceID])
        return YES;
    else
        return NO;
}
@end

