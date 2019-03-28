//
//  SaveDataModel.m
//  goscamapp
//
//  Created by goscam_sz on 17/5/5.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "SaveDataModel.h"
//本地保存的已登录的账号:
#define LAST_LOGIN_USERNAME @"LAST_LOGIN_USERNAME"
#define LAST_LOGIN_PASSWORD @"LAST_LOGIN_PASSWORD"

@implementation SaveDataModel

//保存Token
+ (void)SaveUserToken:(NSString *)token
{
    [[NSUserDefaults standardUserDefaults] setObject:token
                                              forKey:USER_TOKEN];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

//保存账号
+ (void)SaveUsrInforUserName:(NSString *)userName
{
    [[NSUserDefaults standardUserDefaults] setObject:userName
                                              forKey:LAST_LOGIN_USERNAME];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

//保存密码
+ (void)SaveUsrInforPassWord:(NSString *)password
{
    [[NSUserDefaults standardUserDefaults] setObject:password
                                              forKey:LAST_LOGIN_PASSWORD];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// 保存用户ID
+ (void)SaveUsrInforuserid:(NSString *)userid
{
    [[NSUserDefaults standardUserDefaults] setObject:userid
                                              forKey:@"userLoginId"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// 保存MDS服务器IP地址
+ (void)SaveUsrInforIp:(NSString *)Ip
{
    [[NSUserDefaults standardUserDefaults] setObject:Ip
                                              forKey:@"MDSIP"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// 缓存服务器端口
+ (void)SaveUsrInforPort:(NSString *)Port
{
    [[NSUserDefaults standardUserDefaults] setObject:Port
                                              forKey:@"MDSPort"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// 缓存二维码扫描弹出框状态
+ (void)SaveQRscanState:(BOOL)state
{
    if (state) {
        [[NSUserDefaults standardUserDefaults] setObject:@"yes" forKey:@"QRscan"];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setObject:@"no" forKey:@"QRscan"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// 缓存CBS网络状态
+ (void)SaveCBSNetWorkState:(BOOL)state
{
    if (state) {
        [[NSUserDefaults standardUserDefaults] setObject:@"yes" forKey:@"CBS"];
    }
    else
    {
        [mUserDefaults setObject:@"no" forKey:@"CBS"];
    }
    [mUserDefaults synchronize];
}

// 缓存wifi添加显示图片缓存
+ (void)SaveWifiAddevice:(BOOL)state
{
    if (state) {
        [[NSUserDefaults standardUserDefaults] setObject:@"yes" forKey:@"WIFIADD"];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setObject:@"no" forKey:@"WIFIADD"];
    }
}

// 缓存扫描二维码添加显示图片缓存
+ (void)SaveScanQrAddevice:(BOOL)state
{
    if (state) {
        [[NSUserDefaults standardUserDefaults] setObject:@"yes" forKey:@"WIFIScanQr"];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setObject:@"no" forKey:@"WIFIScanQr"];
    }

}

// 缓存好友分享添加显示图片缓存
+ (void)SaveFriendAddevice:(BOOL)state
{
    if (state) {
        [[NSUserDefaults standardUserDefaults] setObject:@"yes" forKey:@"FriendADD"];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setObject:@"no" forKey:@"FriendADD"];
    }

}

// 缓存网线添加显示图片缓存
+ (void)SaveWringAddevice:(BOOL)state
{
    if (state) {
        [[NSUserDefaults standardUserDefaults] setObject:@"yes" forKey:@"WringADD"];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setObject:@"no" forKey:@"WringADD"];
    }
    
}



+ (BOOL)getWIFIaddState
{
    NSString *getUserInforIp = [[NSUserDefaults standardUserDefaults] objectForKey:@"WIFIADD"];
    if ([getUserInforIp isEqualToString:@"yes"]) {
        return YES;
    }
    else{
        return NO;
    }
}


+ (BOOL)getScanQraddState
{
    NSString *getUserInforIp = [[NSUserDefaults standardUserDefaults] objectForKey:@"WIFIScanQr"];
    if ([getUserInforIp isEqualToString:@"yes"]) {
        return YES;
    }
    else{
        return NO;
    }
}


+ (BOOL)getFriendAddState
{
    NSString *getUserInforIp = [[NSUserDefaults standardUserDefaults] objectForKey:@"FriendADD"];
    if ([getUserInforIp isEqualToString:@"yes"]) {
        return YES;
    }
    else{
        return NO;
    }
}

+ (BOOL)getWringAddState
{
    NSString *getUserInforIp = [[NSUserDefaults standardUserDefaults] objectForKey:@"WringADD"];
    if ([getUserInforIp isEqualToString:@"yes"]) {
        return YES;
    }
    else{
        return NO;
    }
}


+ (void)SaveloginState:(BOOL)state
{
    if (state) {
        [[NSUserDefaults standardUserDefaults] setObject:@"yes" forKey:@"online"];
    }
    else{
        [[NSUserDefaults standardUserDefaults] setObject:@"no" forKey:@"online"];
    }
}

//获取Token
+ (NSString *)getUserToken
{
    NSString *userToken = [[NSUserDefaults standardUserDefaults] objectForKey:USER_TOKEN];
    return userToken;
}

//获取账号
+ (NSString *)getUserName
{
    NSString *userName = [[NSUserDefaults standardUserDefaults] objectForKey:LAST_LOGIN_USERNAME];
    return userName;
}

//获取密码
+ (NSString *)getUserPassword
{
    NSString *userName = [[NSUserDefaults standardUserDefaults] objectForKey:LAST_LOGIN_PASSWORD];
    return userName;
}

// 获取用户ID
+ (NSString *)getUserld
{
    NSString *getUserld = [[NSUserDefaults standardUserDefaults] objectForKey:@"userLoginId"];
    return getUserld;
}

// 获取缓存MDS服务器IP
+ (NSString *)getUserInforIp
{
    NSString *getUserInforIp = [[NSUserDefaults standardUserDefaults] objectForKey:@"MDSIP"];
    return getUserInforIp;
}

// 获取缓存服务器端口
+ (NSString *)getUserInforPort
{
    NSString *getUserInforIp = [[NSUserDefaults standardUserDefaults] objectForKey:@"MDSPort"];
    return getUserInforIp;
}

// 是否保存密码
+ (void)isSaveUsername:(BOOL)isSave
{
    if (isSave) {
        [[NSUserDefaults standardUserDefaults] setObject:@"yes"
                                                  forKey:@"remember"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else{
        [[NSUserDefaults standardUserDefaults] setObject:@"no"
                                                  forKey:@"remember"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

// 是否获取密码
+ (NSString *)isGetUserPassword
{
    NSString *str = [[NSUserDefaults standardUserDefaults] objectForKey:@"remember"];
    if ([str isEqualToString: @"yes"]){
        NSString * password=  [self getUserPassword];
        return password;
    }
    else{
        return nil;
    }
}

// 获取CBS网络状态
+ (BOOL)isCbsNetWorkSate
{
    NSString *getUserInforIp = [[NSUserDefaults standardUserDefaults] objectForKey:@"CBS"];
    if ([getUserInforIp isEqualToString:@"yes"]) {
        return YES;
    }
    else{
        return NO;
    }
}



// 获取CBS网络状态
+ (BOOL)isQrscanSate
{
    NSString *getUserInforIp = [[NSUserDefaults standardUserDefaults] objectForKey:@"QRscan"];
    if ([getUserInforIp isEqualToString:@"yes"]) {
        return YES;
    }
    else{
        return NO;
    }
}

// 获取登录状态
+ (BOOL)isLogin
{
    
    NSString *getUserInforIp = [[NSUserDefaults standardUserDefaults] objectForKey:@"online"];
    if ([getUserInforIp isEqualToString:@"yes"]) {
        return YES;
    }
    else{
        return NO;
    }
}


@end
