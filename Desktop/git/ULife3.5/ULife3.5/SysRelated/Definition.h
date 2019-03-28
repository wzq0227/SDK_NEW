//
//  Definition.h
//  Custom Ulife
//
//  Created by yuanx on 13-11-12.
//  Copyright (c) 2013年 yuanx. All rights reserved.
//

#ifndef Custom_Ulife_Definition_h
#define Custom_Ulife_Definition_h

//打包版本标识 0是中文版 1是英文版


//extern int isENVersion;
#define isENVersion [[LanguageManager manager] currentLanguage]

//云存储服务是否已好
#define isCloudServiceReady 1

//解绑子设备UI 是否已好
#define isUnbindDeviceUIReady (0)

#define KeepAcousticAdd (0)

//系统版本号判断
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)


#define iPhone6p ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2208), [[UIScreen mainScreen] currentMode].size) : NO)


//xib名字
#define getXibName(x) (([UIDevice currentDevice].isPad) ? [[NSString alloc] initWithFormat:@"%@_ipad", x] : [[NSString alloc] initWithFormat:@"%@_iphone", x])


#define SCREEN_WIDTH    [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT   [UIScreen mainScreen].bounds.size.height
#define SCREEN_SCALE   [UIScreen mainScreen].scale


#define SAVERECORD  @"saverecord"


/**
 *  自定义 Log，用于需要输入文件名、函数名、行号情况下（如条件不满足的 log 打印时）
 */
#define ULifeLog(fmt, ...) NSLog((@"[File:%s] - [Function:%s] - [Line:%d] \n" fmt), __FILE__, __FUNCTION__, __LINE__, ##__VA_ARGS__);



#define iPhone4 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ?CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size) : NO)



//token 本地保存的key
#define ULIFE_REMOTE_NOTIFICATION_TOKEN     @"ULIFE_REMOTE_NOTIFICATION_TOKEN"


#define STRING_FROM_ENUM(x) #x
#define localString(x) NSLocalizedString(x, nil)



//#define  CAMERA_TYPE_IBaby @"7626"
#define CAMERA_TYPE_IBaby @"7"

typedef enum CameraType
{
    CameraTypeUlife,
    CameraTypePoe,
    CameraTypeDvr,
    CameraTypeIBaby
}CameraType;
#endif

#pragma mark -  NSUserDefaults 命名

//
#define IsPlayerViewShown   @"IsPlayerViewShown"
//本地保存的已登录的账号:
#define LAST_LOGIN_USERNAME @"LAST_LOGIN_USERNAME"
#define LAST_LOGIN_PASSWORD @"LAST_LOGIN_PASSWORD"
#define USER_TOKEN @"USER_TOKEN"


#define LOGOUT_STATE @"logout_state";

//用户登录状态
#define USER_HAS_LOGGED     @"USER_HAS_LOGGED"

//历史账号信息
#define ACCOUNT_HISTORY     @"ACCOUNT_HISTORY"
#define SSID_HISTORY        @"SSID_HISTORY"



#pragma mark - NSNotificationCenter 命名

#define LOGOUT_NOTIFICATION                     @"logout_natification"
#define LOGOGIN_NOTIFICATION                    @"login_natification"

//登录返回结果通知
#define NOTIFY_LOGIN_RESULT                 @"NOTIFY_LOGIN_RESULT"
#define NOTIFY_ROOT_CAMERA_LIST_IS_SHOWN    @"NOTIFY_ROOT_CAMERA_LIST_IS_SHOWN"
#define BEGINDOWNLOADCAMERALIST             @"BEGIN_DOWNLOAD_CAMERA_LIST"
#define ADDDEVCIEREFRESH                    @"ADD_DEVICE_REFRESH"
#define LOGOUT_DISMISS                      @"LOGOUT_DISMISS"


#define ADDUID                             @"addUID"
#define DELETEUID                          @"deleteUID"


//打开安装引导通知
#define NOTIFY_OPEN_SETUP                   @"NOTIFY_OPEN_SETUP"

//关闭安装引导通知
#define NOTIFY_CLOSE_SETUP                  @"NOTIFY_CLOSE_SETUP"

#define NOTIFY_PUSH_MAPPING                 @"NOTIFY_PUSH_MAPPING"

//安装新摄像头成功, 刷新根列表通知
#define NOTIFY_UPDATE_TABLE                 @"NOTIFY_UPDATE_TABLE"
#define NOTIFY_DELETE_CAMERA                @"NOTIFY_DELETE_CAMERA"

//分享功能通知
#define NOTIFY_GOT_SHARED_CAMERA                @"NOTIFY_GOT_SHARED_CAMERA"
#define NOTIFY_GOT_USER_LIST_SHARING_CAMERA     @"NOTIFY_GOT_USER_LIST_SHARING_CAMERA"
#define NOTIFY_GOT_SHARE_CAMERA_REQUEST         @"NOTIFY_GOT_SHARE_CAMERA_REQUEST"
#define NOTIFY_GOT_SHARE_CAMERA_REPLY           @"NOTIFY_GOT_SHARE_CAMERA_REPLY"
#define NOTIFY_GOT_USER_INFO                    @"NOTIFY_GOT_USER_INFO"
#define NOTIFY_GET_CAMERA_STATUS                @"NOTIFY_GET_CAMERA_STATUS"

//刷新设备在线状态通知
#define REFRESH_DEV_CONN_STATE_NOTIFICATION     @"REFRESH_DEV_CONN_STATE_NOTIFICATION"

#define NOTIFY_PUSHMESSAGE_NOTIFICATION  @"notify_pushmessage_natification"

#define UID_DEFAULT          @"uid_default"
#define DEVICENAME_DEFAULT   @"device_default"





//颜色设置
#define BACKCOLOR(R,G,B,A)     [UIColor colorWithRed:R/255.0f green:G/255.0f blue:B/255.0f alpha:A]

#define mCustomBgColor ([UIColor colorWithRed:238/255.0f green:238/255.0f blue:238/255.0f alpha:1])

#define mFileManager  ([NSFileManager defaultManager])

#define mUserDefaults ([NSUserDefaults standardUserDefaults])

#define mDocumentPath (NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0])

#define mRecordFileFolderName @"RecordFileList"

//192.168.20.176:000000 1.250
//120.24.84.182:010101
//120.24.12.43:
//120.24.84.182
#define LAN_IP @"192.168.20.176"
#define CHINA_IP @"120.24.84.182"
#define Public_IP @"120.24.12.43"
#define FOREIGN_IP @"52.41.26.100"

#define LAN_DOMAIN @"000000"
#define Public_Domain @"010101";
#define CHINA_DOMAIN @"010101"
#define FOREIGN_DOMAIN @"900101"

#define kCurrentIP @"kCurrentIP"
#define kCurrentDomain @"kCurrentDomain"

#define mUserChosenVersion (@"UserChosenVersion")

#define IsBetaVersion (@"IsBetaVersion")

#define kCBS_IP ([mUserDefaults integerForKey:mUserChosenVersion]!=3 ?([mUserDefaults integerForKey:IsBetaVersion]!=1?@"cngos-cms.ulifecam.com":@"119.23.124.137"):([mUserDefaults integerForKey:IsBetaVersion]!=1?@"engos-cms.ulifecam.com":@"47.88.77.127") )   //
//119.23.124.137

//云存储IP
#define kCloud_IP ((isENVersion)?(@"css.ulifecam.com"):([mUserDefaults integerForKey:mUserChosenVersion]!=3 ?(@"cn-css.ulifecam.com"):(@"css.ulifecam.com")))
//cn-css.ulifecam.com 119.23.124.137:9998

// 国外域名
#define enCBS_IP ([mUserDefaults integerForKey:IsBetaVersion]!=1?@"engos-cms.ulifecam.com":@"47.88.77.127")
//47.88.77.127
//"engos-cms.ulifecam.com"

#define kCBS_PORT (8000) //8000

#define CSSERVER_IP ((isENVersion)?(enCBS_IP):(kCBS_IP))

//中文系统下用户没有选择海外版，界面才是中文语言，其他英文
#define kCGSA_ADDRESS (([mUserDefaults integerForKey:mUserChosenVersion]!=3&&isENVersion==0) ?(@"CGSAAddressCN"):(@"CGSAAddressEN"))


#define isENVersionNew ( !([mUserDefaults integerForKey:mUserChosenVersion]!=3&&isENVersion==0) )


#define kAppKey @"abcef0930277aadbdd"

#define kCGSA_IP @"kCGSA_IP"
#define kCGSA_Port @"kCGSA_Port"

#define IOS_VERSION_11 (NSFoundationVersionNumber >= NSFoundationVersionNumber10_11)?YES:NO

#define HIGH_TEMPERATURE_ALARM_PUSH @"HIGH TEMPERATURE ALARM"//温度上限推送
#define LOW_TEMPERATURE_ALARM_PUSH @"LOW TEMPERATURE ALARM"//温度下限推送
static const NSString *video_motion = @"VIDEO MOTION"; //移动监测推送
static const NSString *pir_motion = @"PIR MOTION"; //PIR推送



// 判断字符串是否为空
#define IS_STRING_EMPTY(str) ([str isKindOfClass:[NSNull class]] || str == nil || [str length] < 1 ? YES : NO )


// rgb颜色转换（16进制->10进制）
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

// rgb颜色 10进制
#define UIColorFromRGBA(r,g,b,a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]


// 刷新设备列表通知 key
#define REFRESH_DEV_LIST_NOTIFY @"RefreshDeviceListNotify"

//成功开通云存储通知
#define ORDER_CS_SUCCESSFULLY @"ORDER_CS_SUCCESSFULLY"

// 有新推送通知 key
#define NEW_APNS_NOTIFY @"newPushMsgtNotify"

// 修改设备昵称通知 key
#define UPDATE_DEV_NAME_NOTIFY @"updateDevNameNotify"

//进入系统设置切换WIFI回来通知 key
#define CHANGE_WIFI_BACK       @"CHANGE_WIFI_BACK"

#define WECHAT_PAY_CALL_BACK    @"WECHAT_PAY_CALL_BACK"

/** 视频播放宽高比 4:3 */
#define PLAY_VIEW_SCALE 0.75f

#define SCREEN_WIDTH_RATIO ((SCREEN_WIDTH)/360)

/** 是否显示体验中心 */
#define SHOW_EXP_CENTER       @"SHOW_EXP_CENTER"

/** 锁屏通知 */
#define LOCK_SCREEN_NOTIFY @"LockScreenNotify"

/** 解锁通知 */
#define UN_LOCK_SCREEN_NOTIFY @"UnLockScreenNotify"

/** NVR 停止视频流结果 通知 */
#define NVR_STOP_VIDEO_NOTIFY @"NvrStopVideoNotify"
