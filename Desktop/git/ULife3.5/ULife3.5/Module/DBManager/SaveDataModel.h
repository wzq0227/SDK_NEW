//
//  SaveDataModel.h
//  goscamapp
//
//  Created by goscam_sz on 17/5/5.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SaveDataModel : NSObject

+ (void)SaveUserToken:(NSString *)token;

// 磁盘缓存用户账号
+ (void)SaveUsrInforUserName:(NSString *)userName;

// 缓存用户密码
+ (void)SaveUsrInforPassWord:(NSString *)password;

// 缓存用户ID
+ (void)SaveUsrInforuserid:(NSString *)userid;

// 缓存MDS服务器IP
+ (void)SaveUsrInforIp:(NSString *)Ip;

// 缓存服务器端口
+ (void)SaveUsrInforPort:(NSString *)Port;

// 缓存二维码扫描弹出框状态
+ (void)SaveQRscanState:(BOOL)state;

// 缓存CBS网络状态
+ (void)SaveCBSNetWorkState:(BOOL)state;

// 缓存wifi添加显示图片缓存
+ (void)SaveWifiAddevice:(BOOL)state;

// 缓存扫描二维码添加显示图片缓存
+ (void)SaveScanQrAddevice:(BOOL)state;

// 缓存好友分享添加显示图片缓存
+ (void)SaveFriendAddevice:(BOOL)state;

// 缓存网线添加显示图片缓存
+ (void)SaveWringAddevice:(BOOL)state;


// 获取图片是否被点击
+ (BOOL)getWIFIaddState;


+ (BOOL)getScanQraddState;


+ (BOOL)getFriendAddState;

+ (BOOL)getWringAddState;


+ (void)getUserToken:(NSString *)token;

// 获取用户账号
+ (NSString *)getUserName;

// 获取用户密码
+ (NSString *)getUserPassword;

// 获取用户ID
+ (NSString *)getUserld;

// 获取缓存MDS服务器IP
+ (NSString *)getUserInforIp;

// 获取缓存服务器端口
+ (NSString *)getUserInforPort;

// 是否保存密码
+ (void)isSaveUsername:(BOOL)isSave;

// 是否获取密码
+ (NSString *)isGetUserPassword;

// 获取CBS网络状态
+ (BOOL)isCbsNetWorkSate;

// 获取扫描二维码弹出框状态
+ (BOOL)isQrscanSate;

+ (BOOL)isLogin;

+ (void)SaveloginState:(BOOL)state;
@end
