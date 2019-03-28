
#ifndef _ULIFEDEFINES_H__
#define _ULIFEDEFINES_H__

#ifdef __cplusplus
extern "C" {
#endif

//PARAM_CONTROL_CMD
#define PCT_CMD_GET_PM_CONTROL_ERROR_INFO 0x9F		//SPmErrorInfo获取参数配置时的错误信息
#define PCT_CMD_GET_LIST_OF_DAY_HAS_VIDEO 0x100		//SSdcardRecQuery ;ptime取值 ex:201601
#define PCT_CMD_GET_VIDEO_LIST						0x101			//SSdcardRecQuery ;ptime取值 ex:20160101
#define PCT_CMD_START_DOWNLOAD_VIDEO	0x102			//SSdcardRecDownload
#define PCT_CMD_STOP_DOWNLOAD_VIDEO		0x103			//SSdcardRecDownload
#define PCT_CMD_GET_IMAGE_COLOR				0x104			//SImageColor
#define PCT_CMD_SET_IMAGE_COLOR				0x105			//SImageColor
#define PCT_CMD_GET_RESOLUTION					0x106			//SResolution
#define PCT_CMD_SET_RESOLUTION					0x107			//SResolution
#define PCT_CMD_GET_WORK_ENVIRONMENT	0x108			//SWorkEn
#define PCT_CMD_SET_WORK_ENVIRONMENT	0x109			//SWorkEn
#define PCT_CMD_GET_RTSP_SWITCH_STUS		0x10A			//SRtspSwitch
#define PCT_CMD_SET_RTSP_SWITCH_STUS		0x10B			//SRtspSwitch
#define PCT_CMD_GET_NOISE_LEVEL					0x10C			//SNoiseLevel
#define PCT_CMD_SET_NOISE_LEVEL					0x10D			//SNoiseLevel
#define PCT_CMD_QUERY_DAY_LOG					0x10E			//SDaylogs
#define PCT_CMD_GET_WIFI_LIST						0x10F			//SWifiInfo
#define PCT_CMD_SET_WIFI									0x110			//SWifiInfo
#define PCT_CMD_PTZ_LEFT									0x111
#define PCT_CMD_PTZ_RIGHT								0x112
#define PCT_CMD_PTZ_UP									0x113
#define PCT_CMD_PTZ_DOWN							0x114
#define PCT_CMD_PTZ_ZOON_IN						0x115	//放大
#define PCT_CMD_PTZ_ZOON_OUT						0x116	//缩小
#define PCT_CMD_PTZ_H_SCAN							0x117	//水平扫描
#define PCT_CMD_PTZ_V_SCAN							0x118	//垂直扫描
#define PCT_CMD_AUTO_SCAN							0x119 //自动扫描
#define PCT_CMD_STOP_SCAN							0x11A //停止扫描
#define PCT_CMD_PTZ_MIRROR							0x11B //镜像
#define PCT_CMD_PTZ_FLIP									0x11C //翻转
#define PCT_CMD_PTZ_KEEP_LEFT						0x11D //连续左
#define PCT_CMD_PTZ_KEEP_RIGHT						0x11E //连续右
#define PCT_CMD_PTZ_KEEP_UP							0x11F //连续上
#define PCT_CMD_PTZ_KEEP_DOWN					0x120 //连续下
#define PCT_CMD_SET_AP									0x140 //设置AP信息,SWifiInfo

#pragma pack(1)
typedef struct  _spmerrorinfo 
{
	char info[1024];
}SPmErrorInfo;

typedef struct _sdcardrecordquery{
	char ptime[32];	//ex:201601或者20160101
	char* plist;
}SSdcardRecQuery;

typedef struct _sdcardrecorddownload{
	char filename[256];	//下载文件文件名
	char savepath[256]; //本地存储路径
}SSdcardRecDownload;

typedef struct _imagecolor{
	int brightness;
	int contrast;
	int saturation;
	int hue;
}SImageColor;

typedef struct _sdaylog{
	char ptime[20];	//reserved,保留,目前不需要填写值
	char *pszlog;
}SDaylogs;

typedef struct _rtspswitch{
	int status;
}SRtspSwitch;

typedef struct _noiselvl{
	int level;
}SNoiseLevel;

typedef struct _workenviroment{
	int type;
}SWorkEn;

typedef struct  _wifiinfo
{
	char wifiSsid[128];
	char password[128];
	int signalLevel;
}WifiInfoN;

typedef struct _swifiinfolist{
	WifiInfoN *plist;
	int totalcount;
}SWifiInfo;

typedef struct _avresolution
{
	char resName[20];
	int width;
	int height;
	int frameRate;
	int bitRate;
	int iGap;		//i帧间隔
}AVResolutionN;

typedef struct _sresolution{
	AVResolutionN major;
	AVResolutionN minor;
}SResolution;

#pragma pack()

#pragma pack(4)
typedef struct
{
// 	bool  bIsPBDevice ;
	int dwStatus  ;						//状态
	int  bIsGroup ;						
	int dwSelfID;
	int dwParentID;

	char  szSWVer[32];				//软件版本
	char  szHWVer[32];				//硬件版本

	char  szDevID[128] ;				//设备ID
	char  szDevName[128] ;		//设备名称
	char  szKeyText[1024];			//tips

	char  szDataURL[1024];		//服务器地址

	char szDeviceType[24];			//设备类型
	int	nettype;						//设备网络类型
	char szDeviceIP[16];				//设备IP
	char szMacAddr_LAN[8];      //设备MAC 地址
	char szWiFiSSID[128];			//WiFi名称
	char szWiFiPwd[64];				//WiFi密码
    int ybindFlag;                        //硬解绑开启标志，0->未开启,1->开启
}DeviceInfo;
#pragma pack()

typedef enum
{
	UM_MSG_NOTIFY_UNKNOW = -1,
	UM_MSG_NOTIFY_LOGIN = 0,
	UM_MSG_NOTIFY_LOGOUT,
	UM_MSG_NOTIFY_USERDATA,
	UM_MSG_NOTIFY_USERSTATUS,
	UM_MSG_NOTIFY_DEVLIST,
	UM_MSG_NOTIFY_DEVSTATUS,
	UM_MSG_NOTIFY_ALARMINFO,
	UM_MSG_NOTIFY_DISCONNECTION,

	AVM_MSG_QS= 500,
	AVM_MSG_CONNECTIONS,

	PM_MSG_QS=1000,

	DSM_MSG_QS=1500,

}MESSAGETYPE;

typedef enum{
	UM_SUBMSG_UNKNOW = -1,
	UM_SUBMSG_LOGIN_OK = 0,
	UM_SUBMSG_LOGIN_INVALID_PASSWORD,
	UM_SUBMSG_LOGIN_INVALID_USER,
	UM_SUBMSG_LOGIN_CONNECT_FAILED,
	UM_SUBMSG_DEVSTATUS_ALL,
	UM_SUBMSG_DEVSTATUS_ONE,
	AVM_SUMMSG_QS = 100,
	AVM_SUMMSG_DISCONNECTED,
}MESSAGESUBTYPE;

//EErrorCode list
#define ECODE_OK											0x000		//成功
#define ECODE_UNKNOW										-0x200		//未定义错误
#define ECODE_ALLOC_FAILED									-0x201		//分配空间失败
#define ECODE_REGISTER_INVALID_USER							-0x202		//无效用户名
#define ECODE_REGISTER_USERNAME_IN_USE						-0x203		//用户名已经存在
#define ECODE_REGISTER_INVALID_EMAIL						-0x204		//无效邮箱地址
#define ECODE_REQUEST_RESOURCE_NOT_FOUND					-0x205		//请求资源未找到
#define ECODE_BAD_REQUEST									-0x206		//错误请求
#define ECODE_INTERNAL_SERVER_ERROR							-0x207		//服务器内部错误
#define ECODE_NOT_IMPLEMENTED								-0x208		//未实现功能
#define ECODE_DEVICE_ID_NOT_FOUND							-0x209		//设备ID不存在
#define ECODE_DEVICE_NOT_ONLINE								-0x20A		//当前设备不在线
#define ECODE_DEVICE_ALREADY_BIND							-0x20B		//设备已经被其他用户绑定
#define ECODE_NOT_LOGIN										-0x20C		//没有登录
#define ECODE_INVALID_CHANNEL								-0x20D		//无效通道
#define ECODE_CHANNEL_OUTOF_RANGE							-0x20E		//超出有效通道范围
#define ECODE_CREATE_THREAD_FAILED								-0x20F		//创建线程失败


//EErrorCode list

typedef enum{
	e_param_none = -1,
}EPARAMTYPE;

typedef struct _stFrameHeader
{
	unsigned long nIFrame;
	unsigned long nAVType;		//1 means video,2 means audio
	unsigned long dwSize;		//audio or video data size
	unsigned long dwFrameRate;	//video frame rate or audio samplingRate
	unsigned long dwTimeStamp;
	unsigned long gs_video_cap;	//video's capability
	unsigned long gs_reserved; 
}stFrameHeader;

typedef int (*UMMsgCallback)(MESSAGETYPE msgtype,MESSAGESUBTYPE submsgtype, void* msgbody,int msglen);
typedef int (*AvDataCallback)(int channelid,stFrameHeader* pheader,unsigned char* pdata, int datalen,void* popt);
typedef int (*MsgCallback)(int channelid,MESSAGETYPE msgtype,MESSAGESUBTYPE submsgtype, unsigned char* pdata, int datalen,void* popt);

#ifdef __cplusplus
}
#endif

#endif //_ULIFEDEFINES_H__
