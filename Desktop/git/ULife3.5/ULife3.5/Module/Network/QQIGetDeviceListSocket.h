//
//  QQIGetDeviceListSocket.h
//  QQI
//
//  Created by shenyuanluo on 2017/2/22.
//  Copyright © 2017年 yuanx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"


typedef enum{
    ULIFE20_SUCCESS                         = 0,        // 成功
    ULIFE20_RETRY                           = 1,        // 系统忙 请重试
    ULIFE20_USER_NOT_EXIST                  = 2,        // 用户不存在 (登录等)
    ULIFE20_USERNAME_IS_USED                = 3,        // 用户名已经存在(创建账号时)
    ULIFE20_USERNAME_AT_FIRST_LOGIN_STATE   = 4,        // 用户名已经存在(创建账号时)
    ULIFE20_USER_EMAIL_ADDR_INVALID         = 5,        // 用户邮箱为无效邮箱
    ULIFE20_USER_EMAIL_SEND_FAIL            = 6,        // 邮件发送失败
    ULIFE20_PSWD_ERR                        = 7,        // 密码错误
    ULIFE20_CHECKCODE_ERR                   = 8,        // 验证码错误
    ULIFE20_CHECKCODE_TIMEOUT               = 9,        // 验证码已经失效
    ULIFE20_CHECKCODE_MAIL_SEND_FAIL        = 10,       // 验证码发送失败
    ULIFE20_DEVICE_BINDED_BY_SELF           = 11,       // 设备已经被自己绑定了
    ULIFE20_DEVICE_OWNER_OTHER              = 12,       // 设备已经被别人用oner方式绑定了
    ULIFE20_DEVICE_NO_OWNER                 = 13,       // 设备没被别人用oner方式绑定了
    ULIFE20_DEVICE_NOT_FOND                 = 14,       // 设备不存在
    ULIFE20_DEVICE_NOT_BINDED_BY_SELF       = 15,       // 设备自己没绑定
    ULIFE20_DB_ERR                          = 16,       // 数据库错误
    ULIFE20_DOMAIN_ERR                      = 17,       // 域id错误
    ULIFE20_JSON_FIELD_ERR                  = 18        // 某些json字段错误
    
}ULIFE20_ERR;


@protocol GetDeviceListDelegate <NSObject>

@required

- (void)didReceiveList:(NSMutableArray *)listArray
           userLoginId:(NSString *)userLoginId
             isSuccess:(BOOL)isSuccess;



- (void)didlogin:(NSString *)userIdString
          andMDS:(NSDictionary *)dic
          andresultCode:(int)resultCode
       isSuccess:(BOOL)isSuccess;



- (void)didChangPWD:(BOOL)isSuccess;



- (void)didRegisterResp:(NSString *)userNameString
              isSuccess:(BOOL)isSuccess
          andresultCode:(int)resultCode;



- (void)didSendCheckCodeRespisSuccess:(BOOL)isSuccess;



- (void)didUseCheckCodeChangePwdReqisSuccess:(BOOL)isSuccess
                               andresultCode:(int)resultCode;


- (void)didFindDevBindRespWithDevId:(NSString *)devId
                           andState:(int)state
                      andResultCode:(int)resultCode
                          isSuccess:(BOOL)isSuccess;


- (void)didBindDevRespWithResultCode:(int)resultCode
                           isSuccess:(BOOL)isSuccess;


- (void)didUnBindDevRespResultCode:(int)resultCode
                         isSuccess:(BOOL)isSuccess;


- (void)didChangeDevAttrRespResultCode:(int)resultCode
                             isSuccess:(BOOL)isSuccess;


@end


/**
 *  设备类型 枚举
 */
typedef NS_ENUM(NSInteger, DeviceType) {
    DeviceIPC = 0,         // 普通 IPC 设备
    DeviceNVR,             // NVR 设备
};


@interface QQIGetDeviceListSocket : NSObject <GCDAsyncSocketDelegate>

@property (nonatomic, weak) id <GetDeviceListDelegate> delegate;



+ (instancetype)shareInstance;




//刷列表初始化
+ (instancetype)shareInstanceUpListand:(NSString *)ip
                               andPort:(NSString *)port;



/**
 修改设备名称

 @param userld 用户登录 ID
 @param devid 设备裸 ID
 @param devName 设备新名称
 @param deviceType 设备列席
 */
- (void)DeviceChangeDevAttrReqWithUserId:(NSString *)userld
                                andDevId:(NSString *)devid
                              andDevName:(NSString *)devName
                              deviceType:(DeviceType)deviceType;


/**
 解绑设备

 @param userld 用户登录 ID
 @param devid 设备裸 ID
 @param deviceType 设备类型
 */
- (void)DeviceUnBindDevReqWithUserId:(NSString *)userld
                            andDevId:(NSString *)devid
                         deviceType:(DeviceType)deviceType;


/**
 绑定设备

 @param userId 用户登录 ID
 @param devId 设备裸 ID
 @param userRight 分享权限
 @param dic 设备信息
 @param deviceType 设备类型
 */
- (void)DeviceBindDevReqWithUserId:(NSString *)userId
                          andDevId:(NSString *)devId
                      andUserRight:(int)userRight
                        andDevInfo:(NSDictionary *)dic
                        deviceType:(DeviceType)deviceType;


//查找绑定状态
- (void)DeviceFindDevBindReqWithUserId:(NSString *)userId
                              andDevId:(NSString *)devId
                            deviceType:(DeviceType)deviceType;


//修改密码
-(void)DeviceChangePwdWithUsername:(NSString *)userNameString
                         andNewPwd:(NSString *)newPwd
                         andOldPwd:(NSString *)oldPwd;



//注册账号
-(void)DeviceRegisterUsername:(NSString *)userNameString
                   andUserPwd:(NSString *)userPwd
                     andemail:(NSString *)email;



//登录
-(void)DeviceloginWithUsename:(NSString *)useNameString
                    andUsePwd:(NSString *)usePwdSting;



//忘记密码
-(void)DeviceForgetPwdWithUsename:(NSString *)userNameString;



//根据验证码重置密码
-(void)DeviceUseCheckCodeChangePwdReqWithUsename:(NSString *)userNameString
                                       andNewPwd:(NSString *)NewPwdString
                                    andCheckCode:(NSString *)checkCode;



- (void)getDeviceListWithId:(NSString *)userLoginId
                resultClass:(Class)resultClass;


- (void)stopConnect;

@end
