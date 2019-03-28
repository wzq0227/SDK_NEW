#ifndef _QRCODE_CONFIG_H_
#define _QRCODE_CONFIG_H_

// 二维码协议的一些默认值
#define QRC_DEFAULT_USR "admin"
#define QRC_DEFAULT_PWD "goscam123"
#define QRC_DEFAULT_ENCRYPT_METHOD QRC_ENCRYPT_MTH_BASE64

#define SIZEOF_CGetQrCode_Origin 256 // CGetQrCode 原始大小, 版本兼容过渡期, 此处不要更改


#define QRC_DEF_STR_LEN 64
#define QRC_CAP_BITS    32
#define QRC_RESERVE_LEN 46//52

typedef enum _QRC_BIT {
    QRC_BIT_ENCRYPTED_IC		= 0x2,			// 是否有加密IC
    QRC_BIT_PIR					= 0x4,			// 是否有PIR传感器，0:无，1:有，下同
    QRC_BIT_PTZ					= 0x8,			// 是否有云台
    QRC_BIT_MICROPHONE			= 0x10,			// 是否有咪头/麦克风
    QRC_BIT_SPEAKER				= 0x20,			// 是否有喇叭
    QRC_BIT_SDCARD_SLOT			= 0x40,			// 是否有SD卡
    QRC_BIT_TEMPERATURE			= 0x80,			// 是否有温感探头
    QRC_BIT_AUTO_TIMEZONE		= 0x100,		// 是否支持同步时区
    QRC_BIT_NIGHT_VISON			= 0x200,		// 是否支持夜视
    QRC_BIT_ETHERNET_SLOT		= 0x400,		// 是否带网口
    QRC_BIT_SMART_WIFI			= 0x800,		// 设备端WiFi模块是否支持SmartConfig功能
    QRC_BIT_MOTION_DETECTION	= 0x1000,		// 是否支持移动侦测
    QRC_BIT_RECORD_DURATION		= 0x2000,		// 是否支持录像时长定制
    QRC_BIT_LIGHT_FLAG			= 0x4000,		// 是否有设置照明灯开关
    QRC_BIT_VOICE_DETECTION		= 0x8000,		// 是否支持声音侦测报警
} QRC_BIT, E_AbilityInfo;

/*注意：(-项已废弃,+项新增)
 +	1. sizeof(CGetQrCode)  要小于1024
 -	2. 生成二维码之前 数据前增加9个字节 如：goscam@1:    @符号前为厂家名 @符号后位编码方式 1代表base64编码 冒号后为数据
 （厂家名称可协商定义，目前固定长度）。
 + 2. 二维码结构体仍保留CGetQrCode, 二维码文本形如:
 #   00301xxxx QRC://G.xxxx  QRC://R.xxxx
 */
typedef struct {
    unsigned int   nAction;		                  // 0.出厂;1.分享;2.
    unsigned int   nDevCap; 		                // 设备能力集 对应 E_AbilityInfo
    unsigned char  szDevID   [QRC_DEF_STR_LEN]; // 设备ID
    unsigned char  szDevMAC  [QRC_DEF_STR_LEN];	// 设备MAC
    unsigned char  szUser    [QRC_DEF_STR_LEN]; // 取流用户名
    unsigned char  szPwd     [QRC_DEF_STR_LEN];	// 取流密码
    unsigned char  szWifiSSID[QRC_DEF_STR_LEN]; // 配置Wifi: SSID
    unsigned char  szWifiPwd [QRC_DEF_STR_LEN]; // 配置Wifi: 密码
    unsigned char  reserve   [QRC_RESERVE_LEN]; // 预留
    unsigned char  cIsRawID;                    // 是否裸UID识别的二维码: 0代表不是; 1代表是
    unsigned char  cWifiMod;                    // 是否支持smart扫描	0代表不支持，1代表7601smart  2代表8188smart
    unsigned int   nDevType;                    // 设备类型:900中性版;901高视安;101彩易;100海尔
    unsigned short nEncryptMth;                 // 加解密/编解码方法
    unsigned short nVersion;                    // 版本号
} CGetQrCode;

//IPC 能力集结构体，主要用于给APP端提供隐藏或显示相关件UI 的依据
typedef struct
{
    unsigned int   c_device_type; //设备类型900中性版101彩益100海尔
    unsigned int   un_resolution_0_flag;	//主码流分辨率大小 Width:高16位 Height:低16位  Ming@2016.06.14
    unsigned int   un_resolution_1_flag;	//子码流
    unsigned int   un_resolution_2_flag;	//第3路码流
    unsigned char  c_encrypted_ic_flag;	//是否有加密IC
    unsigned char  c_pir_flag; 			//是否有PIR传感器，0:无，1:有，下同
    unsigned char  c_ptz_flag; 			//是否有云台
    unsigned char  c_mic_flag; 			//是否有咪头
    unsigned char  c_speaker_flag; 		//是否有喇叭
    unsigned char  c_sd_flag;			//是否有SD卡
    unsigned char  c_temperature_flag; 	//是否有温感探头
    unsigned char  c_timezone_flag;		//是否支持同步时区
    unsigned char  c_night_vison_flag;	//是否支持夜视
    
    unsigned char  ethernet_flag;	//是否带网卡
    unsigned char  c_smart_connect_flag;	//是否支持smart扫描	0代表不支持，1代表7601smart  2代表8188smart
    unsigned char  c_motion_detection_flag; //是否支持移动侦测
    unsigned char  c_record_duration_flag;
}T_SDK_DEVICE_ABILITY_INFO1;


// wwei add begin 20161107
typedef struct
{
    unsigned int   c_device_type; //设备类型   900中性版     101彩益     100海尔	    901高世安
    unsigned int   un_resolution_0_flag;	//主码流分辨率大小 Width:高16位 Height:低16位  Ming@2016.06.14
    unsigned int   un_resolution_1_flag;	//子码流
    unsigned int   un_resolution_2_flag;	//第3路码流
    unsigned char  c_encrypted_ic_flag;	//是否有加密IC
    unsigned char  c_pir_flag; 			//是否有PIR传感器，0:无，1:有，下同
    unsigned char  c_ptz_flag; 			//是否有云台
    unsigned char  c_mic_flag; 			//是否有咪头
    
    unsigned char  c_speaker_flag; 		//是否有喇叭
    unsigned char  c_sd_flag;			//是否有SD卡
    unsigned char  c_temperature_flag; 	//是否有温感探头
    unsigned char  c_timezone_flag;		//是否支持同步时区
    
    unsigned char  c_night_vison_flag;	//是否支持夜视
    unsigned char  ethernet_flag;		//是否带网卡0:wifi 1有线2wifi加有线
    unsigned char  c_smart_connect_flag;	/* 是否支持smart扫描
                                             0代表不支持，
                                             1代表7601smart
                                             2代表8188smart
                                             3代表ap6212
                                             101代表二维码扫描+7601smart
                                             102代表二维码扫描+8188smart
                                             */
    unsigned char  c_motion_detection_flag; //是否支持移动侦测
    
    unsigned char  c_record_duration_flag; // 是否有设置录像录像时长
    unsigned char  c_light_flag; // 是否有设置照明灯开关
    unsigned char  c_voice_detection_flag; //是否支持声音侦测报警
    unsigned char  align1;	 // 用来字节对齐
    unsigned char  reserver_default_off[32]; // 预留能力集默认关闭
    unsigned char  reserver_default_on[32]; // 预留能力集默认开启
}T_SDK_DEVICE_ABILITY_INFO2;	
// wwei add end 20161107

typedef enum {
    E_QRC_VERSION_UNKNOWN = -1,
    E_QRC_VERSION_OLD = 0,
    E_QRC_VERSION_V1  = 1,
    E_QRC_VERSION_V2  = 2,
} E_QRC_VERSION;

typedef struct {
    CGetQrCode qrc;
    T_SDK_DEVICE_ABILITY_INFO1 info;
    T_SDK_DEVICE_ABILITY_INFO2 info2;
    int have_abi;
} CGQRCodeCompatV1;

#endif //_QRCODE_CONFIG_H_
