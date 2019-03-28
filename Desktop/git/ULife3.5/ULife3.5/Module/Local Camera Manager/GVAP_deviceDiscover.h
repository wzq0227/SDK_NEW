#ifndef __GVAP_DEVICEDISCOVER_H__
#define __GVAP_DEVICEDISCOVER_H__

#define  SEARCH_BROADCAST_PORT  8628
//#define  SEARCH_BROADCAST_PORT  9628

//cmd 命令
#define GOSGET 0x66         //获取设备信息命令标识
#define RESPONDGOSGET 0x67  //回复获取设备信息的命令标识
#define GOSSET 0x77         //设置设备信息命令标识
#define GOSSET_3G 0x80         //设置设备信息命令标识3G paras, by marshal
#define RIGHTGOSSET 0x89    //回复正确设置设备信息命令标识
#define WRONGGOSSET 0x93    //回复错误设置设备信息命令标识


enum
{
    DataPort_Changed,               //数据端口改变标志
    WebServerPort_Changed,          //WEB 端口改变标志
    DeviceName_Changed,             //设备名称改变标志
    WanServerIP_Changed,            //广域网IP改变标志
    ServerPort_Changed,             //广域网端口改变标志
    ImageSizeAndAudio_Changed,      //开启音频并且分辨率改变
    NeedChangePWD_Changed,          //允许更改密码改变标志
    ImageSize_Changed,              //当前视频分辨率改变但音频未开启标志
    RequestStream_Changed,          //
    Bitrate1_Changed,               //第一路码流波特率改变标志
    Framerate1_Changed,             //第一路码流帧率改变标志
    Mirror_Changed,                 //视频镜像改变标志
    Flip_Changed,                   //视频翻转改变标志
    DeviceIP_Changed,               //设备IP改变标志
    DeviceMasK_Changed,             //设备子网掩码改变标志
    DeviceGateWay_Changed,          //设备网关改变标志
    DNS0_Changed,                   //设备DNS地址改变标志
    EnableDHCP_Changed,             //允许设备DHCP改变标志
    EnableWiFi_Changed,             //是否允许WiFi改变标志
    WiFiEncryMode_Changed,          //WiFi加密模式改变标志
    WiFiSSID_Changed,               //WiFi名称改变标志
    WiFiPwd_Changed,                //WiFi密码改变标志
    WiFiIP_Changed,                 //WiFi的IP改变标志
    WiFiMasK_Changed,               //WiFi的子网掩码改变标志
    WiFiGateWay_Changed,            //WiFi的网关改变标志
    WiFiDNS0_Changed,               //WiFi的DNS地址改变标志
    EnableWiFiDHCP_Changed,         //是否允许WiFi的DHCP改变标志
    Imagesource_Changed,            //分辨率 改变标志
    EnableAudio_Changed,            //开启音频但分辨率未改变标志
    BindAccont_Changed,             //绑定用户名改变标志
    Bitrate2_Changed,               //第二路码流波特率改变标志
    Framerate2_Changed,             //第二路码流帧率改变标志
    DEV_S_Changed,                  //设备服务器地址改变标志
    DEV_PORT_Changed,               //设备服务器地址改变标志
    EnableWiFi_Reset,               //重新设置wifi
    WIFI_NEW_MODE,                  //ap wifi 状态切换
    SMTP_RCV_EMAIL_AD,              //设置报警接收邮箱地址
    DEVICE_RESET,                   //设备复位
    SET_MOTIONENABLE,               ///< Enable motion detection or not.
    SET_MOTIONCENABLE,              ///< Use customer define or normal mode.
    SET_MOTIONLEVEL,                ///< Set motion level in normal mode.
    SET_MOTIONCVALUE,               ///< Set customer value at customer mode.
    SET_MOTIONBLOCK,                ///< Define motion blocks.
    SET_SMTPAENABLE,                ///设置是否开启 接收报警的邮件
    SET_ATTFILEFORMAT,              ///设置 邮件附件类型  0->avi  1->jpeg 2->不带附件
    SET_NTP_TIMEZONE,               ///设置时区
    SET_SchedulesUploadFTP,         ///< Schedule录像的文件上传到ftp
    SET_SchedulesSaveToSD, 	        ///< Schedule录像文件保存到sd卡，最高位为1表示录像覆盖
    SET_Schedules,                  ///设置Schedules时间表
    SET_AlarmUploadFTP,	            ///< 报警录像的文件上传到ftp
    SET_AlarmSaveToSD,	            ///< 报警录像的文件上传到ftp
	SET_MSG_SET_FTP_FQDN,           ///< Set FTP FQDN.
	SET_MSG_SET_FTP_USERNAME,       ///< Set FTP username.
	SET_MSG_SET_FTP_PASSWORD,       ///< Set FTP password.
	SET_MSG_SET_FTP_PORT,           ///< Set FTP port.
	SET_MSG_SET_SMTP_SERVER_IP,     ///< Set SMTP FQDN.
	SET_MSG_SET_SMTP_SERVER_PORT,   ///< Set SMTP PORT.
	SET_MSG_SET_SMTP_USERNAME,      ///< Set SMTP user name.
	SET_MSG_SET_SMTP_PASSWORD,      ///< Set SMTP password.
	SET_ALARMDURATION,              ///< Set how long will one alarm last.
	SET_ALARM_AUDIOPLAY,            ///< Set alarm playaudio
	///add by marshal, u588x gpio settings, 2013-02-21
	SET_GIOIN_ENABLE,              ///< Set gpio in alarm enable or disable
	SET_GIOIN_TYPE,            ///< Set  gpio in alarm type high or low
	SET_GIOOUT_ENABLE,              ///<Set gpio out alarm enable or disable
	SET_GIOOUT_TYPE,            ///< Set  gpio out alarm type high or low
	SET_ALARM_ENABLE,            ///alarm enable or disable, one key disable alarm
	//end
};

typedef int (*OnGVAPDiscoverCallback)(int);

typedef struct{
    unsigned char bStatus;	        ///< schedule status ( 0:disable 1:录像 2:报警时录像 }
	unsigned char nDay;		        ///< schedule day of week (1:Mon 2:Tue 3:Wed 4:Thr 5:Fri 6:Sat 7:Sun 8:Everyday 9:Working day)
	unsigned char nStartHour;	    ///< Hour from 0 to 23.
	unsigned char nStartMin;	    ///< Minute from 0 to 59.
	unsigned char nStartnSec;	    ///< Second from 0 to 59.
	unsigned char nDurationHour;	///< Hour from 0 to 23.
	unsigned char nDurationMin;	    ///< Minute from 0 to 59.
	unsigned char nDurationSec;	    ///< Second from 0 to 59.
} Schedule;

/* 命名规则 char-->sz, int-->n, unsigned int-->u, char *-->psz */
typedef struct _struWifiInfo_t
{
	int  nEnableWiFiDHCP;        //是否允许WiFi的DHCP
	int  nEnableWiFi;            //是否允许WiFi
	int  nWiFiEncryMode;         //WiFi加密模式
	char szWiFiIP[20];           //WiFi的IP
	char szWiFiSSID[128];        //WiFi名称
	char szWiFiPwd[64];          //WiFi密码
    
	int  nEnableDeviceDHCP;		 //设备DHCP
    char szWiFiMasK[16];         //WiFi的子网掩码
    char szWiFiGateWay[16];      //WiFi的网关
    char szWiFiDNS0[16];         //WiFi的DNS地址
    char szWiFiDNS1[16];         //
}struWifiInfo;
typedef struct _stru3GInfo_t
{
	char sz3GUser[60];           //user name
	char sz3GPWD[60];        //pwd
	char sz3GAPN[128];          //apn
    char szDialNum[44];         //WiFi的子网掩码
}stru3GInfo;

#pragma pack(1)
typedef struct _tmDeviceInfo_t
{
	int  nCmd;                    //标识命令字
	char szPacketFlag[24];       //标识字符
	char szDeviceName[20];       //设备名称
	char szDeviceType[24];       //设备类型
	int  nMaxChannel;            //最大通道数
	char szDeviceIP[16];         //设备IP
	char szDeviceMasK[16];       //设备子网掩码
	char szDeviceGateWay[16];    //设备网关
	char szMultiAddr[16];        //设备多播地址
	char szMacAddr_LAN[8];          //lan 设备MAC 地址
	char szMacAddr_WIFI[8];          //wifi 设备MAC 地址
	char szRevsered0[16];
	char szDNS0[16];             //设备DNS地址
	char szDNS1[16];             //DNS地址 暂没用
	int  nMultiPort;             //多播端口
	int  nDataPort;              //数据端口
	int  nWebServerPort;         //WEB 端口
    
	char szUserName[16];         //用户名
	char szPwd[16];              //密码
	char szCameraVer[8];         //软件版本
    
	char szWanServerIP[24];      //广域网IP
	char szServerPort[8];        //广域网端口
	char szCamSerial[64];        //设备序列号
#if 1
	int  nEnableWiFiDHCP;        //是否允许WiFi的DHCP
	int  nEnableWiFi;            //是否允许WiFi
	int  nWiFiEncryMode;         //WiFi加密模式
	char szWiFiIP[20];           //WiFi的IP
	char szWiFiSSID[128];        //WiFi名称
	char szWiFiPwd[64];          //WiFi密码
    
	int  nEnableDeviceDHCP;		 //设备DHCP
    char szWiFiMasK[16];         //WiFi的子网掩码
    char szWiFiGateWay[16];      //WiFi的网关
    char szWiFiDNS0[16];         //WiFi的DNS地址
    char szWiFiDNS1[16];         //
#endif
    unsigned int uOfferSize;    //提供的视频分辨率
	unsigned int uImageSize;    //当前视频分辨率
	unsigned int uMirror;       //视频镜像
	unsigned int uFlip;         //视频翻转
	unsigned int uRequestStream;//
	unsigned int uBitrate1;      //波特率
	unsigned int uFramerate1;    //帧率
	//第二路码流
	unsigned int uBitrate2;      //波特率
	unsigned int uFramerate2;    //帧率
    
	unsigned int uImagesource;      //分辨率 (NTSC/PAL)
	unsigned int uChangePWD;        //1: need to change 0: not to change
	char szNewPwd[16];              //the new password
	int  nDeviceNICType;             //0 wired NIC;1 wifi NIC
	unsigned int uEnableAudio;      //是否开启音频
	///add by marshal, u588x gpio settings, 2013-02-21
	unsigned char			bgioinenable;					///< GIO input enable, < bit0 Set gpio in alarm enable or disable, bit1 motion and io individual or both triggered. cation!!!
	unsigned char			bgiointype;						///< GIO input type
	unsigned char			bgiooutenable;					///< GIO output enable
	unsigned char			bgioouttype;						///< GIO output type
	unsigned char			bAlarmEnable;						///alarm enable or disable
	char szRevsered1[41];
	//end
    unsigned char nAlarmAudioPlay;		///< alarm audio play enable/disable
    unsigned char nAlarmDuration;		///< alarm duration 0~5{10, 30, 60, 300, 600, NON_STOP_TIME}
    unsigned char bAlarmUploadFTP;	    ///< 报警录像的文件上传到ftp
    unsigned char bAlarmSaveToSD;	    ///< 报警录像的文件保存到sd卡
    unsigned char bSetFTPSMTP;	    ///< 为1表示设置FTP参数，为2表示设置SMTP参数
	char servier_ip[37];            ///< FTP or SMTP server address
	char username[16];              ///< FTP or SMTP login username
	char password[16];              ///< FTP or SMTP login password
	unsigned int uPort;             ///< FTP or SMTP
    
	/*GVAP*/
	char szBindAccont[48];          //绑定用户名
	char szDevSAddr[48];            //设备服务器地址或域名
	unsigned int uDevSPort;         //设备服务器端口
    
    char szSMTPReceiver[64];        //接收邮件邮箱
    unsigned char motionenable;		///< motion detection enable
    unsigned char motioncenable;	///< customized sensitivity enable
    unsigned char motionlevel;		///< predefined sensitivity level
    unsigned char motioncvalue;		///< customized sensitivity value
    unsigned char motionblock[4];   ///< motion detection block data
    unsigned char bDeviceRest;      /// 设备复位命令为1表示复位，为2表示重启设备
    unsigned char bEnableEmailRcv;      /// 开启报警邮件的接收
    unsigned char bAttachmentType;      /// 设置邮件附件的类型 0->avi  1->jpeg  2->不带附件
    //
    unsigned char ntp_timezone;      /// 设置系统时区，0-24 详细定义看下面的注释，
    //最高位可以用来设置夏令时，默认自动设置夏令时
    unsigned int  nYear;	        ///< 当前年份.
    unsigned char nMon;	            ///< Mounth from 1 to 12. 修改时间时请先将月份赋值好，
    //再将月份最高位设置为1(nMon|0x80)
    unsigned char nDay;	            ///< Second from 1 to 31.
    unsigned char nHour;	        ///< Hour from 0 to 23.
    unsigned char nMin;	            ///< Minute from 0 to 59.
    unsigned char nSec;	            ///< Second from 0 to 59.
    
    unsigned char nSdinsert;		        ///< SD card inserted，值为3表示sd卡可正常使用
    unsigned char bSchedulesUploadFTP;	    ///< Schedule录像的文件上传到ftp
    unsigned char bSchedulesSaveToSD;	    ///< Schedule录像文件保存到sd卡，最高位为1表示录像覆盖
    
	Schedule  aSchedules[8];		///< schedule data
}_tmDeviceInfo_t;
#pragma pack()

//时区定义如下 下标 0-24
#if  0 /* BEGIN: Comment by liubing, 2012/6/11 */
char *TZname[] = {
	"GMT-12 Eniwetok, Kwajalein",
	"GMT-11 Midway Island, Samoa",
	"GMT-10 Hawaii",
	"GMT-09 Alaska",
	"GMT-08 Pacific Time (US & Canada), Tijuana",
	"GMT-07 Mountain Time (US & Canada), Arizona",
	"GMT-06 Central Time (US & Canada), Mexico City, Tegucigalpa, Saskatchewan",
	"GMT-05 Eastern Time (US & Canada), Indiana(East), Bogota, Lima",
	"GMT-04 Atlantic Time (Canada), Caracas, La Paz",
	"GMT-03 Brasilia, Buenos Aires, Georgetown",
	"GMT-02 Mid-Atlantic",
	"GMT-01 Azores, Cape Verdes Is.",
	"GMT+00 GMT, Dublin, Edinburgh, London, Lisbon, Monrovia, Casablanca",
	"GMT+01 Berlin, Stockholm, Rome, Bern, Brussels, Vienna, Paris, Madrid, Amsterdam, Prague, Warsaw, Budapest",
	"GMT+02 Athens, Helsinki, Istanbul, Cairo, Eastern Europe, Harare, Pretoria, Israel",
	"GMT+03 Baghdad, Kuwait, Nairobi, Riyadh, Moscow, St. Petersburg, Kazan, Volgograd",
	"GMT+04 Abu Dhabi, Muscat, Tbilisi",
	"GMT+05 Islamabad, Karachi, Ekaterinburg, Tashkent",
	"GMT+06 Alma Ata, Dhaka",
	"GMT+07 Bangkok, Jakarta, Hanoi",
	"GMT+08 Taipei, Beijing, Chongqing, Urumqi, Hong Kong, Perth, Singapore",
	"GMT+09 Tokyo, Osaka, Sapporo, Seoul, Yakutsk",
	"GMT+10 Brisbane, Melbourne, Sydney, Guam, Port Moresby, Vladivostok, Hobart",
	"GMT+11 Magadan, Solomon Is., New Caledonia",
	"GMT+12 Fiji, Kamchatka, Marshall Is., Wellington, Auckland"
};
#endif /* #if 0 END:   Comment by liubing, 2012/6/11 */

//int GVAP_receiveBroadcast(DeviceInfo_t *tDeviceInfo, int sockfd);
//int GVAP_sendBroadcast(DeviceInfo_t *tDeviceInfo, int sockfd);
//int GVAP_getDeviceInfo( DeviceInfo_t *pDeviceInfo);
//int GVAP_setDeviceInfo( DeviceInfo_t *pDeviceInfo, int *binduserChanged);
int GVAP_discoverInit(OnGVAPDiscoverCallback callback);
void* GVAP_startDiscoverService(_tmDeviceInfo_t *deviceInfo);

#endif



//以下是袁雪加的

#define CMD_GET_FLAG "GosGet"
#define CMD_SET_INFO_FLAG "GosSetInfo"
#define CMD_SET_SUCCESS_FLAG "gosset succsuss"


typedef _tmDeviceInfo_t DeviceInfo;
typedef _tmDeviceInfo_t DeviceInfo_t;

#define UDP_PORT_RECV 8629			//局域网广播用
#define UDP_PORT_SEND 8628

