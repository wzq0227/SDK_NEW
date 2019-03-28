//
//  AppDelegate.m
//  ULifeNew3.0
//
//  Created by goscam on 2017/5/24.
//  Copyright © 2017年 goscam. All rights reserved.
//

#import "AppDelegate.h"
#import "YYModel.h"
#import "APNSManager.h"
#import "UIImage+YYAdd.h"
#import <RealReachability.h>
#import "LogFileDebug.h"
#import "NetAPISet.h"
#import "UserDB.h"
#import "DevPushManagement.h"
#import "MainNavigationController.h"
#import "LoginViewFristController.h"
#import "PlayVideoViewController.h"
#import <IQKeyboardManager.h>
#import "NetSDK.h"
#import "SaveDataModel.h"
#import "CMSCommand.h"
#import "HWLaunchViewController.h"
#import "DeviceConnectManager.h"
#import "HWLogManager.h"
#import "UIColor+YYAdd.h"
#import "APPVersionTool.h"
#import "Header.h"
#import "CatchExceptionHandler.h"
#import "UserGuideViewController.h"

#import "CloudServicePaymentTypeVC.h"
#import "WXApi.h"
#import <AlipaySDK/AlipaySDK.h>
#import "BraintreeCore.h"
static NSString *PayPalURLScheme = @"com.xm.gosbell.payments";

@interface AppDelegate ()<WXApiDelegate>


@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundUpdateTask;

@property (nonatomic,strong)  NetSDK *netSDK;

@end

@implementation AppDelegate



/**
 判断是否是新版本 APP

 @return YES：新版本（启动引导页），NO：旧版本（不启动引导页）
 */
- (BOOL)isNewVersionApp
{
    NSString *bundldKey   = (NSString *)kCFBundleVersionKey;
    NSString *version     = [[[NSBundle mainBundle] infoDictionary] objectForKey:bundldKey];
    NSString *saveVersion = [[NSUserDefaults  standardUserDefaults] objectForKey:bundldKey];
    
    if([version isEqualToString:saveVersion])   // 相同版本，不是第一次打开 APP
    {
        return NO;
    }
    else
    {
        [[NSUserDefaults  standardUserDefaults] setObject:version forKey:bundldKey];
        [mUserDefaults setBool:YES forKey:SHOW_EXP_CENTER];
        [[NSUserDefaults  standardUserDefaults] synchronize];
        
        return YES;
    }
}





#pragma mark -- 处理 APNS 消息
- (void)handleRemoteNotification:(NSDictionary *)userInfo
{    
    NSString *pushType = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
    pushType = [pushType stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSString *deviceId = userInfo[@"uid"];
    NSString *pushUrl  = userInfo[@"event_time"];
    NSString *pushTime = [self extractTimeWithPushUrl:pushUrl];
    NSString *receivedTime = userInfo[@"received_at"];
    NSInteger subChannel = !userInfo[@"channel"]?-1:[userInfo[@"channel"] intValue];
    
    if ( pushTime.length <= 0 ) {
        NSTimeInterval timeInterval = receivedTime.doubleValue;
        pushTime = [self formattedDateStringFromTimeInterval:timeInterval];
    }
    
    APNSMsgReadState msgReadState = APNSMsgReadNo;
    
    APNSMsgType msgPushType;
    
    if ([pushType isEqualToString:APNS_MSG_MOVE_KEY])
    {
        msgPushType = APNSMsgMove;
    }
    else if([pushType isEqualToString:APNS_MSG_PIR_KEY])
    {
        msgPushType = APNSMsgPir;
    }
    else if([pushType isEqualToString:APNS_MSG_UP_LIMIT_KEY])
    {
        msgPushType = APNSMsgTemperatureUpperLimit;
    }
    else if([pushType isEqualToString:APNS_MSG_VOICE_KEY])
    {
        msgPushType = APNSMsgVoice;
    }
    else if([pushType isEqualToString:APNS_MSG_LOW_LIMIT_KEY])
    {
        msgPushType = APNSMsgTemperatureLowerLimit;
    }
    else
    {
        msgPushType = APNSMsgMove;
    }
    
    
    PushMessageModel *dataModel = [[PushMessageModel alloc]init];
   
     dataModel.deviceId = deviceId;
    
    [[HWLogManager manager] logMessage:[NSString stringWithFormat:@"PUSH------------------pushTime:%@ chan:%d \r\n",pushTime,subChannel]];

    dataModel.pushUrl = pushUrl;
    dataModel.apnsMsgType = msgPushType;
    dataModel.apnsMsgReadState = msgReadState;
    dataModel.pushTime = pushTime;
    dataModel.subChannel = subChannel;
    
    [APNSManager shareManager].pushDeviceModel = dataModel;
    [APNSManager shareManager].isPushLaunch = YES;
}

- (NSString *)formattedDateStringFromTimeInterval:(NSTimeInterval)timeInterval{
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    //    NSTimeZone *systemTimeZone = [NSTimeZone systemTimeZone];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970: timeInterval];//+systemTimeZone.secondsFromGMT
    NSString *DateTime = [formatter stringFromDate:date];
    return DateTime;
}

- (NSString *)extractTimeWithPushUrl:(NSString *)pushUrl
{
    
    //    NSDate *date = [NSDate date];
    //    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    //    [formatter setDateStyle:NSDateFormatterMediumStyle];
    //    [formatter setTimeStyle:NSDateFormatterShortStyle];
    //    [formatter setDateFormat:@"YYYY-MM-dd hh:mm:ss"];
    //    NSString *DateTime = [formatter stringFromDate:date];
    //    return DateTime;
    
    //取设备时间
    if (IS_STRING_EMPTY(pushUrl))
    {
        NSLog(@"无法提取推送时间串， pushUrl = nil");
        return nil;
    }
    NSArray *strArray = [pushUrl componentsSeparatedByString:@"/"];
    if (0 >= strArray.count)
    {
        NSLog(@"提取推送时间串失败！");
        return nil;
    }
    NSString *timeStr     = strArray[strArray.count - 1];
    if (14 >= timeStr.length)
    {
        NSLog(@"提取推送时间串失败！");
        return nil;
    }
    NSString *realTimeStr = [timeStr substringToIndex:14];
    NSString *yearStr     = [realTimeStr substringToIndex:4];
    NSString *monthStr    = [realTimeStr substringWithRange:NSMakeRange(4, 2)];
    NSString *dayStr      = [realTimeStr substringWithRange:NSMakeRange(6, 2)];
    NSString *hourStr     = [realTimeStr substringWithRange:NSMakeRange(8, 2)];
    NSString *minuteStr   = [realTimeStr substringWithRange:NSMakeRange(10,2)];
    NSString *secondStr   = [realTimeStr substringWithRange:NSMakeRange(12,2)];
    NSString *dateStr     = [NSString stringWithFormat:@"%@-%@-%@ %@:%@:%@", yearStr, monthStr, dayStr, hourStr, minuteStr, secondStr];
    
    return dateStr;
}

- (void)cacheCBSIPPort{
    
    [[NSUserDefaults standardUserDefaults] setObject:@"no" forKey:@"CBS"];
    NSString *ip   = nil;
    

    if (isENVersion) {
        ip = enCBS_IP;
    }
    else{
        UserChosenVersion version = [mUserDefaults integerForKey:mUserChosenVersion];
        if (version!= UserChosenVersionOverseas && version != UserChosenVersionDomestic) {
            [mUserDefaults setInteger:UserChosenVersionDomestic forKey:mUserChosenVersion];
            [mUserDefaults synchronize];
        }
        ip = kCBS_IP;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:ip forKey:@"kCBS_IP"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:kCBS_PORT] forKey:@"CBS_PORT"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [CatchExceptionHandler initHandler];
    
    //设置语言参数
    [self configLanguage];
    
    //存储CBS IP
    [self cacheCBSIPPort];
    
    //注册推送
    [[APNSManager shareManager] registerPush];
    
    //注册支付
    [self registerPayment];
    
    NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        [self handleRemoteNotification:userInfo];
    }


    self.window = [[UIWindow alloc]initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
    
    self.window.rootViewController = [[MainNavigationController alloc]initWithRootViewController:[UserGuideViewController new]];
    
//    if (NO == [self isNewVersionApp])
//    {
//
//    }
//    else
//    {
//        self.window.rootViewController= [[HWLaunchViewController alloc] init];
//    }
    
    [self.window makeKeyWindow];
    
//    [IQKeyboardManager sharedManager].enable = YES;
//    [IQKeyboardManager sharedManager].shouldResignOnTouchOutside = YES;
    [SaveDataModel SaveCBSNetWorkState:NO];

   //设置默认UI属性
    [self setAppearance];
    
    //初始化网络IP
//    [self setupNetwork];
    

    //初始化数据相关
    [self setupDataInitial];
 
    //网络状态监听
    [GLobalRealReachability startNotifier];
    

    
    [[HWLogManager manager] logMessage:@"APP Start"];
    
    //开始设备连接管理
//    [[DeviceConnectManager shareInstance] startMonitor];

    return YES;
}


- (void)registerPayment{
    [WXApi registerApp:@"wx70a6dc2f10c50f94"];
    [BTAppSwitch setReturnURLScheme:PayPalURLScheme];
}

- (void)configLanguage{
    //初始化
    [[LanguageManager manager]initLanguage];
    
}


- (void)setAppearance{

     //设置导航栏默认颜色字体
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName:[UIFont boldSystemFontOfSize:18],
                                    NSForegroundColorAttributeName : [UIColor whiteColor]
                                    };
    [[UINavigationBar appearance] setTitleTextAttributes:attributeDict];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageWithColor:myColor] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [UINavigationBar appearance].barStyle = UIStatusBarStyleLightContent;
    // 取消所有返回按钮标题'back' --这个在ios11下有兼容性的问题
//    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(-20, -60)
//                                                         forBarMetrics:UIBarMetricsDefault];
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor clearColor]} forState:UIControlStateNormal];
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor clearColor]} forState:UIControlStateHighlighted];

    //SVProgress设置
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    [SVProgressHUD setMinimumDismissTimeInterval:3];
}

- (void)setChangeVersionLang{
    
}


- (void)setupDataInitial{
    
//    _isBackgroud = NO;

    //本地日志文件创建
//    LogFileDebug *logfile = [LogFileDebug shareInstance];
//    [logfile CreateLogFile:@"IdeaNext"];
    
    
    //存沙盒key
    [mUserDefaults setObject:@"0" forKey:@"AudioSessionInitialize"];
    SAVE_OBJECT(@APP_NAME, @"APP_NAME");
    [mUserDefaults synchronize];
}

#pragma mark 支付回调
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    if ([url.scheme localizedCaseInsensitiveCompare:PayPalURLScheme] == NSOrderedSame) {
        return [BTAppSwitch handleOpenURL:url sourceApplication:sourceApplication];
    }
    if ([url.host isEqualToString:@"safepay"]) {
        // 支付跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            NSLog(@"result = %@",resultDic);
        }];
        
        // 授权跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processAuth_V2Result:url standbyCallback:^(NSDictionary *resultDic) {
            NSLog(@"result = %@",resultDic);
            // 解析 auth code
            NSString *result = resultDic[@"result"];
            NSString *authCode = nil;
            if (result.length>0) {
                NSArray *resultArr = [result componentsSeparatedByString:@"&"];
                for (NSString *subResult in resultArr) {
                    if (subResult.length > 10 && [subResult hasPrefix:@"auth_code="]) {
                        authCode = [subResult substringFromIndex:10];
                        break;
                    }
                }
            }
            NSLog(@"授权结果 authCode = %@", authCode?:@"");
        }];
    }
    else if ([url.host isEqualToString:@"pay"])
    {
        //微信支付，处理支付结果
        return [WXApi handleOpenURL:url delegate:self];
    }
    return NO;
}
/**
 微信支付完成回调
 */
-(void) onResp:(BaseResp*)resp{
    if([resp isKindOfClass:[PayResp class]]){
        //支付返回结果，实际支付结果需要去微信服务器端查询
        NSString *strMsg;
        
        switch (resp.errCode) {
            case WXSuccess:
                strMsg = @"支付结果：成功！";
                NSLog(@"支付成功－PaySuccess，retcode = %d", resp.errCode);
                break;
                
            default:
                strMsg = [NSString stringWithFormat:@"支付结果：失败！retcode = %d, retstr = %@", resp.errCode,resp.errStr];
                NSLog(@"错误，retcode = %d, retstr = %@", resp.errCode,resp.errStr);
                break;
        }
        NSDictionary *resultDict = @{@"PaymentResult":@(resp.errCode)};
        [[NSNotificationCenter defaultCenter] postNotificationName:WECHAT_PAY_CALL_BACK object:nil userInfo:resultDict];
    }
}

//9.0以前
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    
    if ([url.host isEqualToString:@"safepay"]) {
        // 支付跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            NSLog(@"result = %@",resultDic);
        }];
        
        // 授权跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processAuth_V2Result:url standbyCallback:^(NSDictionary *resultDic) {
            NSLog(@"result = %@",resultDic);
            // 解析 auth code
            NSString *result = resultDic[@"result"];
            NSString *authCode = nil;
            if (result.length>0) {
                NSArray *resultArr = [result componentsSeparatedByString:@"&"];
                for (NSString *subResult in resultArr) {
                    if (subResult.length > 10 && [subResult hasPrefix:@"auth_code="]) {
                        authCode = [subResult substringFromIndex:10];
                        break;
                    }
                }
            }
            NSLog(@"授权结果 authCode = %@", authCode?:@"");
        }];
    }
    else if ([url.host isEqualToString:@"pay"]){
        return  [WXApi handleOpenURL:url delegate:self];
    }
    return YES;
}

// NOTE: 9.0以后使用新API接口
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options
{
    if ([url.scheme localizedCaseInsensitiveCompare:PayPalURLScheme] == NSOrderedSame) {
        return [BTAppSwitch handleOpenURL:url options:options];
    }
    if ([url.host isEqualToString:@"safepay"]) {
        // 支付跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            NSLog(@"result = %@",resultDic);
        }];
        
        // 授权跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processAuth_V2Result:url standbyCallback:^(NSDictionary *resultDic) {
            NSLog(@"result = %@",resultDic);
            // 解析 auth code
            NSString *result = resultDic[@"result"];
            NSString *authCode = nil;
            if (result.length>0) {
                NSArray *resultArr = [result componentsSeparatedByString:@"&"];
                for (NSString *subResult in resultArr) {
                    if (subResult.length > 10 && [subResult hasPrefix:@"auth_code="]) {
                        authCode = [subResult substringFromIndex:10];
                        break;
                    }
                }
            }
            NSLog(@"授权结果 authCode = %@", authCode?:@"");
        }];
    }
    else if ([url.host isEqualToString:@"pay"])
    {
        //微信支付，处理支付结果
        return [WXApi handleOpenURL:url delegate:self];
    }
    return NO;
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}


- (void)application:(UIApplication *)app didReceiveLocalNotification:(UILocalNotification *)notif {
    NSDictionary *dict = notif.userInfo;
    if ([dict[@"LocalNotification"] isEqualToString:@"APWifiConnected"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"APWifiConnected" object:nil];
    }
    NSLog(@"didReceiveLocalNotification:%@",dict);
    app.applicationIconBadgeNumber = 0;
}


-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    //处理远程推送
    NSLog(@"收到的推送消息：%@", userInfo);
    [[APNSManager shareManager] handleRemoteNotification:userInfo withClick:YES];
    completionHandler(UIBackgroundFetchResultNewData);
}


- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    //推送注册失败
    NSString *error_str = [NSString stringWithFormat: @"%@", error];
    NSLog(@"Failed to get token, error:%@", error_str);
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
//    //推送token获取成功
//    NSLog(@"设备 APNS 推送 token：%@",deviceToken);
//    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        //添加token到服务器
//        NSString *tokenString = [NSString stringWithFormat:@"%@",deviceToken];
//        tokenString = [tokenString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
//        tokenString = [tokenString stringByReplacingOccurrencesOfString:@" "
//                                                             withString:@""];
//        
//        //发送Token到自有服务器
//        NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
//        NSString *uuidStr = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
//        NSDictionary *postDict = @{
//                                   @"MessageType":@"LoginRequest",
//                                   @"Body":
//                                       @{
//                                           @"Terminal":@"iphone", //终端系统类型
//                                           @"Language":@{@"Cur":@"chinese",@"Def":@"chinese"},//终端系统 当前语言  默认语言(服务器端转换语言时 找不到)
//                                           @"UserName":@"apptest",//app就填账户名，dev就填ID
//                                           @"Token":tokenString,  //对于APP没有token的就填写mac地址，对于camera写DEVICE ID,token是唯一的
//                                           @"AppId":bundleId,//APP唯一表示符号
//                                           @"UUID":uuidStr //手机唯一标识
//                                           }
//                                   };
////        NSData *reqData = [NSJSONSerialization dataWithJSONObject:postDict options:0 error:nil];
//        [[NetSDK sharedInstance] net_sendCBSRequestWithData:postDict timeout:15000 responseBlock:^(int result, NSDictionary *dict) {
//            
//        }];
//        
//    });
   
    [[APNSManager shareManager] sendDeviceTokenToServer:deviceToken];
    
    [APNSManager shareManager].deviceToken = deviceToken;

}


- (void)applicationWillResignActive:(UIApplication *)application {
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
//    _isBackgroud = YES;
    
    //切换网络退出app
//    if ([[CommenlyUsedFounctions getCurSSID] rangeOfString:CAMERA_TYPE_IBaby].length !=0) {
//        [self deleteLocalDevice];
//    }
//    
    //保活处理
    UIApplication*   app = [UIApplication sharedApplication];
    __block    UIBackgroundTaskIdentifier bgTask;
    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        dispatch_async_on_main_queue(^{
            if (bgTask != UIBackgroundTaskInvalid)
            {
                bgTask = UIBackgroundTaskInvalid;
            }
        });
    }];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async_on_main_queue(^{
            if (bgTask != UIBackgroundTaskInvalid)
            {
                bgTask = UIBackgroundTaskInvalid;
            }
        });
    });
}

////切换网络直接退出APP ---没搞懂
//-(void)deleteLocalDevice
//{
//    if (_isBackgroud) {
//        exit(0);
//    }
//}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    //比对语言发生变化，退出app
    int language = 0;
    
    NSArray *languages = [NSLocale preferredLanguages];
    NSString *currentLanguage = [languages objectAtIndex:0];
    
    if ([currentLanguage hasPrefix:@"zh"]) {
        //中文
        language = 0;
    }
    else{
        //英文
        language = 1;
    }
    
    //这个不相等
    if (language != isENVersion) {
        //退出app
        exit(0);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:CHANGE_WIFI_BACK object:nil];
//    _isBackgroud = NO;
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
}


- (void)applicationWillTerminate:(UIApplication *)application {
    
    
    
    //DB Close
    [[UserDB sharedInstance] closeDB];
    
    //网络关闭连接
    NetAPISet *api =[NetAPISet sharedInstance] ;
    [api stopConnect];
    
    [[DevPushManagement shareDevPushManager] savePushListCache];
    
    //日志关闭
    LogFileDebug *logFile = [LogFileDebug shareInstance];
    [logFile LogClose];
}



- (void)applicationProtectedDataWillBecomeUnavailable:(UIApplication *)application
{
    [[NSNotificationCenter defaultCenter] postNotificationName:LOCK_SCREEN_NOTIFY object:nil];
    NSLog(@"Lock screen.");
}



- (void)applicationProtectedDataDidBecomeAvailable:(UIApplication *)application
{
    [[NSNotificationCenter defaultCenter] postNotificationName:UN_LOCK_SCREEN_NOTIFY
                                                        object:nil];
    NSLog(@"UnLock screen.");
}


@end
