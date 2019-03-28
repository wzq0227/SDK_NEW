//
//  APNSManager.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/12.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "APNSManager.h"
#import "DeviceManagement.h"
#import "PushMessageManagement.h"
#import <MJPhotoBrowser/MJPhotoBrowser.h>
#import "AppDelegate.h"
#import "DevPushManagement.h"
#import "SaveDataModel.h"
#import "UserDB.h"
#import <RESideMenu.h>
#import "PersonalCenterViewController.h"


#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif



@interface APNSManager()<UNUserNotificationCenterDelegate>
{
    
}
@end

@implementation APNSManager

+ (instancetype)shareManager
{
    static APNSManager *g_apnsManger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if (nil == g_apnsManger)
        {
            g_apnsManger = [[APNSManager alloc] init];
        }
    });
    return g_apnsManger;
}


#pragma mark -- 注册 APNS
- (void)registerPush
{
    float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (systemVersion>=10) {
        //iOS10特有
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        // 必须写代理，不然无法监听通知的接收与点击
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (granted) {
                // 点击允许
                NSLog(@"注册成功");
                [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
                    NSLog(@"%@", settings);
                }];
            } else {
                // 点击不允许
                NSLog(@"注册失败");
            }
        }];
        
    }
    else if(systemVersion < 8)
    {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert |
                                                                               UIRemoteNotificationTypeBadge |
                                                                               UIRemoteNotificationTypeSound)];
        return;
    }
    else
    {
        UIMutableUserNotificationCategory *categorys = [[UIMutableUserNotificationCategory alloc] init];
        UIUserNotificationSettings *userSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge |UIUserNotificationTypeSound|UIUserNotificationTypeAlert
            
                                                                                     categories:[NSSet setWithObject:categorys]];
        [[UIApplication sharedApplication] registerUserNotificationSettings:userSettings];
    }
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void)showAlertWithTitle:(NSString*)title Msg:(NSString *)msg{
    UIAlertView *msgAlert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:DPLocalizedString(@"Title_Confirm") otherButtonTitles:nil, nil];
    //:DPLocalizedString(@"Setting_Cancel") :DPLocalizedString(@"Setting_Setting")
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [msgAlert show];
    });
}

// 通知的点击事件
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)())completionHandler{
    
    NSDictionary * userInfo = response.notification.request.content.userInfo;
    UNNotificationRequest *request = response.notification.request; // 收到推送的请求
    UNNotificationContent *content = request.content; // 收到推送的消息内容
    NSNumber *badge = content.badge;  // 推送消息的角标
    NSString *body = content.body;    // 推送消息体
    UNNotificationSound *sound = content.sound;  // 推送消息的声音
    NSString *subtitle = content.subtitle;  // 推送消息的副标题
    NSString *title = content.title;  // 推送消息的标题
    if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [self handleRemoteNotification:userInfo withClick:YES];
        NSLog(@"iOS10 收到远程通知:%@", userInfo);
        
    }
    else {
        // 判断为本地通知

        if ([userInfo[@"LocalNotification"] isEqualToString:@"APWifiConnected"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"APWifiConnected" object:nil];
        }
        
        NSLog(@"iOS10 收到本地通知:{\\\\nbody:%@，\\\\ntitle:%@,\\\\nsubtitle:%@,\\\\nbadge：%@，\\\\nsound：%@，\\\\nuserInfo：%@\\\\n}",body,title,subtitle,badge,sound,userInfo);
    }
    
    // Warning: UNUserNotificationCenter delegate received call to -userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler: but the completion handler was never called.
    completionHandler();  // 系统要求执行这个方法
    
}


// iOS 10收到通知
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler{
    NSDictionary * userInfo = notification.request.content.userInfo;
    UNNotificationRequest *request = notification.request; // 收到推送的请求
    UNNotificationContent *content = request.content; // 收到推送的消息内容
    NSNumber *badge = content.badge;  // 推送消息的角标
    NSString *body = content.body;    // 推送消息体
    UNNotificationSound *sound = content.sound;  // 推送消息的声音
    NSString *subtitle = content.subtitle;  // 推送消息的副标题
    NSString *title = content.title;  // 推送消息的标题
    
    if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [self handleRemoteNotification:userInfo withClick:NO];
        NSLog(@"iOS10 前台收到远程通知:%@", userInfo);
        
    }
    else {
        // 判断为本地通知
        NSLog(@"iOS10 前台收到本地通知:{\\\\nbody:%@，\\\\ntitle:%@,\\\\nsubtitle:%@,\\\\nbadge：%@，\\\\nsound：%@，\\\\nuserInfo：%@\\\\n}",body,title,subtitle,badge,sound,userInfo);
    }
    completionHandler(0);
    // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以设置
    //(UNNotificationPresentationOptionBadge|UNNotificationPresentationOptionSound|UNNotificationPresentationOptionAlert)
}




- (NSString *)extractTokenWithData:(NSData *)tokenData
{
    NSString *tokenString = [NSString stringWithFormat:@"%@",tokenData];
    tokenString = [tokenString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    tokenString = [tokenString stringByReplacingOccurrencesOfString:@" "
                                                         withString:@""];
    return tokenString;
}


#pragma mark -- 发送设备 token 到服务器
-(void)sendDeviceTokenToServer:(NSData *)deviceToken
{
    if (!deviceToken || 0 >= deviceToken.length)
    {
        NSLog(@"无法发送设备 APNS token 到服务器， deviceToke = nil");
        
        return;
    }
    [[DevPushManagement shareDevPushManager] registTutkPushWithToken:[self extractTokenWithData:deviceToken]resultBlock:^(BOOL isSuccess) {
                                                             
                                                         }];
}


#pragma mark -- 处理 APNS 消息
- (void)handleRemoteNotification:(NSDictionary *)userInfo withClick:(BOOL)isClick
{
    NSString *pushType = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
    pushType = [pushType stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    NSString *deviceId = userInfo[@"uid"];
    NSString *pushUrl  = userInfo[@"event_time"];
//    NSString *sound = [[userInfo objectForKey:@"aps"] objectForKey:@"sound"];
//    int event_type = [[userInfo objectForKey:@"event_type"] intValue];
    NSString *receivedTime = userInfo[@"received_at"];
    NSInteger channel = !userInfo[@"channel"]?-1:[userInfo[@"channel"] intValue];
    
    
    [self parseApnsMsgWithDeviceId:deviceId
                          pushType:pushType
                           pushUrl:pushUrl
                      receivedTime:receivedTime
                     subDevChannel:channel
                      isClicked:isClick];
}


#pragma mark -- 解析推送消息
- (void)parseApnsMsgWithDeviceId:(NSString *)deviceId
                        pushType:(NSString *)pushType
                         pushUrl:(NSString *)pushUrl
                    receivedTime:(NSString *)recvTime
                   subDevChannel:(NSInteger )channel
                       isClicked:(BOOL)isClicked;
{
    if (IS_STRING_EMPTY(deviceId)
        || IS_STRING_EMPTY(pushType)
        )
    {
        NSLog(@"参数为空，无法解析推送消息！");
        return;
    }
    
//    if (NO == [self isLegalUrl:pushUrl])
//    {
//        NSLog(@"pushUrl 不合法，无法解析推送消息！");
//        return;
//    }
    
    NSString *pushTime = @"";
    if (![self isLegalUrl:pushUrl]) {
        NSTimeInterval timeInterval = recvTime.doubleValue;
        pushTime = [self formattedDateStringFromTimeInterval:timeInterval];
    }else{
        pushTime = [self extractTimeWithPushUrl:pushUrl];
    }
    
    APNSMsgReadState msgReadState = APNSMsgReadNo;
    
    APNSMsgType msgPushType;
    
    if ([pushType isEqualToString:APNS_MSG_MOVE_KEY] || [pushType isEqualToString:APNS_MSG_MOVE_KEY1])
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
    else if([pushType isEqualToString:APNS_MSG_VOICE_KEY] || [pushType isEqualToString:APNS_MSG_VOICE_KEY1])
    {
        msgPushType = APNSMsgVoice;
    }
    else if([pushType isEqualToString:APNS_MSG_LOW_LIMIT_KEY])
    {
        msgPushType = APNSMsgTemperatureLowerLimit;
    }
    else if([pushType isEqualToString:APNS_MSG_LOW_BATTERY_KEY])
    {
        msgPushType = APNSMsgLowBattery;
    }
    else if([pushType isEqualToString:APNS_MSG_BELL_RING_KEY])
    {
        msgPushType = APNSMsgBellRing;
    }
    else
    {
        msgPushType = APNSMsgMove;
    }
    
   PushMessageModel *msgModel =  [self saveApnsMsgWithDeviceId:deviceId
                                                       pushurl:pushUrl
                                                      pushTime:pushTime
                                                  msgReadState:msgReadState
                                                       msgType:msgPushType
                                                 subDevChannel:channel];
    
    //如果点击了的话
    if (isClicked)
    {
        msgReadState = APNSMsgReaded;
        
        //展示相册 -这个不要--改成推送控制器
//        [self showBrowerPhotoWithURL:pushUrl];
//        UIView *view = [[UIView alloc]initWithFrame:CGRectMake(50, 50, 100, 100)];
//        [[UIApplication sharedApplication].keyWindow addSubview:view];
        
        RESideMenu *resideMenu = (RESideMenu *)[UIApplication sharedApplication].keyWindow.rootViewController;
        if ([resideMenu isKindOfClass:[RESideMenu class]]) {
            PersonalCenterViewController *personVC = (PersonalCenterViewController *)resideMenu.leftMenuViewController;
            if ([personVC isKindOfClass:[PersonalCenterViewController class]]) {
                if (msgModel) {
                    self.pushDeviceModel = msgModel;
                }
                //回首页
                [personVC backToFirstView];
                
                //发通知
//                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_PUSHMESSAGE_NOTIFICATION object:deviceId];
//                });
            }
            else{
                return;
            }
        }
        else{
            return;
        }
    }
   
}


#pragma mark -- 保存推送消息
- (PushMessageModel *)saveApnsMsgWithDeviceId:(NSString *)deviceId
                        pushurl:(NSString *)pushUrl
                       pushTime:(NSString *)pushTime
                   msgReadState:(APNSMsgReadState)msgReadState
                        msgType:(APNSMsgType)msgType
                  subDevChannel:(NSInteger )channel

{
    @synchronized(self){
        BOOL devBelongToCurUser=NO;
        NSMutableArray <DeviceDataModel *>*devListArray = [[DeviceManagement sharedInstance] deviceListArray];
        for (DeviceDataModel *model in devListArray) {
            if ([model.DeviceId containsString:deviceId]) {
                devBelongToCurUser = YES;
                break;
            }
        }
        
        if (!devBelongToCurUser) {
            [[DevPushManagement shareDevPushManager] deletePushWithDeviceId:deviceId resultBlock:^(BOOL isSuccess) {
                NSLog(@"移除多余设备______________ret:%d",isSuccess);
            }];
        }
        
        if (IS_STRING_EMPTY(deviceId)
            || IS_STRING_EMPTY(pushTime))
        {
            NSLog(@"推送消息不完整，无法保存！");
            return nil;
        }
        
        if (!devListArray || 0 >= devListArray.count)
        {
            devListArray = nil;
            devListArray = [[UserDB sharedInstance] deviceListArray];
            if (!devListArray || 0 >= devListArray.count)
            {
                NSLog(@"当前账号无设备，无法保存推送消息！");
                return nil;
            }
        }
        DeviceDataModel *exsitModel;
        for (int i = 0; i < devListArray.count; i++)
        {
            DeviceDataModel *tempDevModel = devListArray[i];
            NSString *tutkDevId = tempDevModel.DeviceId;
            NSString *pushDevId = [NSString stringWithString:deviceId];
            if (pushDevId.length == 28) {
                pushDevId = [pushDevId substringFromIndex:8];
            }
            if (28 == tempDevModel.DeviceId.length)             // 平台新定义设备 ID 28 位
            {
                tutkDevId = [tempDevModel.DeviceId substringFromIndex:8];
            }
            else if (20 == tempDevModel.DeviceId.length)        // TUTK 定义设备 ID 20 位
            {
                tutkDevId = tempDevModel.DeviceId;
            }
            else
            {
                tutkDevId = tempDevModel.DeviceId;
            }
            if ([pushDevId isEqualToString:tutkDevId])
            {
                exsitModel = tempDevModel; //[tempDevModel mutableCopy];
                break;
            }
        }
        
        
        
        if (exsitModel) {
            
            //兼容子设备
            NSString *subDevName = @"";
            NSString *subDeviceID = @"";
            for (SubDevInfoModel *subInfoModel in exsitModel.SubDevice) {
                if (channel == subInfoModel.ChanNum) {
                    subDevName = subInfoModel.ChanName;
                    subDeviceID = subInfoModel.SubId;
                }
            }
            
            PushMessageModel *pushMsgModel = [[PushMessageModel alloc] init];
            pushMsgModel.email             = [SaveDataModel getUserName];
            pushMsgModel.deviceId          = exsitModel.DeviceId;
            pushMsgModel.deviceName        = subDevName.length >0 ? subDevName: exsitModel.DeviceName;
            pushMsgModel.pushUrl           = pushUrl;
            pushMsgModel.pushTime          = pushTime;
            pushMsgModel.apnsMsgReadState  = msgReadState;
            pushMsgModel.apnsMsgType       = msgType;
            pushMsgModel.subDeviceID       = subDeviceID;
            [[PushMessageManagement sharedInstance] addPushMessage:pushMsgModel];
            return pushMsgModel;
        }
        return nil;
    }
   
}


#pragma mark -- 显示相册
- (void)showBrowerPhotoWithURL:(NSString *)url
{
    dispatch_async_on_main_queue(^{
        
        NSMutableArray *photoArray = [NSMutableArray array];
        MJPhotoBrowser *photoBrowser = [[MJPhotoBrowser alloc] init];
        MJPhoto *photo = [[MJPhoto alloc] init];
        NSString *imageURL = url;
        photo.url = [NSURL URLWithString:imageURL];
        [photoArray addObject:photo];
        photoBrowser.photos = photoArray;
        photoBrowser.currentPhotoIndex = 0;
        [photoBrowser show];
    });

}


#pragma mark -- 检验 pushUrl 是否合法
- (BOOL)isLegalUrl:(NSString *)pushUrl
{
    if (IS_STRING_EMPTY(pushUrl))
    {
        NSLog(@"无法检验 pushUrl 是否合法， pushUrl = nil");
        return NO;
    }
    if (![pushUrl hasPrefix:@"h"]
        || ![pushUrl hasSuffix:@".jpg"])
    {
        return NO;
    }
    
    return YES;
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

#pragma mark -- 提取推送消息中的时间串‘yyyy-MM-dd HH:mm:ss’
- (NSString *)extractTimeWithPushUrl:(NSString *)pushUrl
{
    

    
    if (![self isLegalUrl:pushUrl]) {
        NSTimeInterval timeInterval = pushUrl.longLongValue;
        return [self formattedDateStringFromTimeInterval:timeInterval];
    }
    
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

@end
