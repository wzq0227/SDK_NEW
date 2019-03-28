
#ifndef _ULIFEDEFINES_H__
#define _ULIFEDEFINES_H__

#ifdef __cplusplus
extern "C" {
#endif

#define LANSDK_VERSION_D	"1.0.0.20180911"

//PARAM_CONTROL_CMD
#define PCT_CMD_DEBUG_FOR_GET_LAST_ACK		0x9D	//SPmDebug用作调试，获取最后一次接收到的数据
#define PCT_CMD_TRANSPANRENT_CMD				 0x9E	//透传命令,STransCmd
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

#define PCT_CMD_GET_CUR_TEMP_HUM				0x141 //获取实时温度,SCurTempHum
#define PCT_CMD_SET_MOTION_SWITCH			0x142 //设置设备侦测开关(开启或关闭),SSwitchMotion
#define PCT_CMD_RESET_FACTORY						0x143 //恢复出厂设置
#define PCT_CMD_PLAY_OR_STOP_CUR_ALARM_RING 0x144 //播放或暂停某一首摇篮曲,SAlarmRingPlay
#define PCT_CMD_SET_DEFAULT_ALARM_RING	0x145 //设置默认摇篮曲,SAlarmRing
#define PCT_CMD_START_SPEAK							0x146 //开启对讲
#define PCT_CMD_SEND_SPEAK_DATA				0x147 //发送对讲数据,SSpeakData
#define PCT_CMD_STOP_SPEAK							0x148 //关闭对讲
#define PCT_CMD_GET_DEVICE_ATRRIBUTE			0x149 //获取设备属性,SDevAttr
#define PCT_CMD_SET_SURVEILLANCE				0x14A //设置相关侦测参数,SSurveillance
#define PCT_CMD_GET_DOWNLOAD_PROCESS	0x14B //获取下载进度,SDownProcess
#define PCT_CMD_DELETE_FILE							0x14C //删除文件,SDelFile
#define PCT_CMD_SET_PWM3								0x14D //set pwm3, SPwm3
#define PCT_CMD_GET_PWM3								0x14E //get pwm3, SPwm3
#define PCT_CMD_ACK_SYS_REQ_RECORD			0x14F //回复设备端的请求（请求录像或者拍照）SysReqCmdAck
#define PCT_CMD_ACK_SYS_REQ_SHUTDOWN	0x150 //回复设备端的请求（请求关机）SysReqCmdAck
#define PCT_CMD_SYS_REQ_LED							0x151 //请求闪灯 SysReqCmd
#define PCT_CMD_TAKE_PHOTO							0x152 //拍照指令
#define PCT_CMD_SET_TIME							0x153 //设置时间
#define PCT_CMD_SET_WIFI_NEW						0x154 //设置wifi信息，SSetWifiInfo

#pragma pack(1)
	typedef struct _sysreqcmd {
		int led; //0->长灭； 1->常亮； 2->快闪； 3->慢闪
	}SysReqCmd;
	typedef struct _sysreqcmdack{
		int ret; //1->成功  0->失败
		int type; //0->拍照； 1->录像; 按接收到的type赋值即可
	}SysReqCmdAck;
	typedef struct _sdelfile{
		char pfile[256];
	}SDelFile;
	typedef struct _stransparentcmd{
		char pcmd[256]; //包含输入，输出；输入时为发送的命令，输出时为接收到的命令
	}STransCmd;
	typedef struct _sswitchmotion{
		int motion; //1 -> 开启, 0 -> 关闭
		int level; //0->高,1->中,2->低
	}SSwitchMotion;
	typedef struct _scurtemphum
	{
		unsigned int curtime; 
		char curTemp[32]; //温度
		char curHum[32]; //湿度
		int tempType; //温度类型, 0:表示摄氏温度.C， 1；表示华氏温度.F
	}SCurTempHum;

	typedef struct _spmdebut
	{
		char info[1024];	
	}SPmDebug;

typedef struct  _spmerrorinfo 
{
	char info[1024];
}SPmErrorInfo;

typedef struct _sdcardrecordquerysub{
	//day,count,PCT_CMD_GET_LIST_OF_DAY_HAS_VIDEO的返回结果
	char day[10]; //某一天
	int count; //某天包含的文件数
	//file，PCT_CMD_GET_VIDEO_LIST的返回结果
	char file[256];
	float size;
}SSdcardRecQuerySub;
typedef struct _sdcardrecordquery{
	char ptime[32];	//ex:PCT_CMD_GET_LIST_OF_DAY_HAS_VIDEO->201601或者PCT_CMD_GET_VIDEO_LIST->20160101
	int filetype; //0->mp4  1->jpg
	int subCount;
	SSdcardRecQuerySub *plist; //when plist is not null ,need free and must free;
}SSdcardRecQuery;

typedef struct _sdcardrecorddownload{
	char filename[256];	//下载文件文件名
	char savepath[256]; //本地存储路径
}SSdcardRecDownload;

typedef struct _sddownloadproc
{
	float process;
}SDownProcess;

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

typedef struct _setWifiInfo 
{
	int type; // 0->wifi, 1->ap
	WifiInfoN info;
}SSetWifiInfo;

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

typedef struct _speakdata{
	int len; //数据长度
	char* data; //数据
}SSpeakData;

typedef struct _salarmring{
	int ringNum;
}SAlarmRing;

typedef struct _salarmringplay{
	int play; //0->stop,1->play
}SAlarmRingPlay;

typedef struct _sdevattr{
	char devName[64]; //设备名称
	char devId[64]; //设备ID
	char wifiMac[20]; //无线mac地址
	char lineMac[20]; //有限mac地址
	char devType[20]; //设备型号
	char fw[32]; //软件版本
	char hw[32]; //硬件版本
	int allSafety; //一键布防
	int loopVideo; //循环录像
	int wdr; //强光照射型
	char recordDuration[32]; //录像时长
	int motion;//移动侦测是否开启,0->关,1->开
	int noise; //声音报警,0->关,1->开
	int night; //夜视
	int alarmtone; //摇篮曲，警铃
	int MotionSensitivity; //高->30，中->60，低->90
	int AudioSensitivity; //1->低，2->中，3->高
	int TemperatureAlarm; //温度侦测是否开启，0->上下限全部关闭,1->上限开启，下限关闭 ，2->上限关闭，下限开启
	float Upperlimit; //上限
	float Lowerlimit; //下限
	int tempType; //温度类型, 0:表示摄氏温度.C， 1；表示华氏温度.F
	int lowbatery; //低电量报警, 0->关，1->开
	int PlayCradlesong; //警铃:0->没有在播  1->正在播
	char apSsid[128]; //ap ssid
	char apPsw[128]; //ap psw
}SDevAttr;

typedef	 struct _surveillance
{
	int type;	//1->声音侦测,2->温度侦测,3->低电量侦测
	int nswitch; //0->关,1->开;当type==2时，0->上下限全部关闭,1->上限开启，下限关闭 ，2->上限关闭，下限开启
	int sensitivity; //灵敏度,0->高,1->中,2->低
	int tempType; //温度类型, 0:表示摄氏温度.C， 1；表示华氏温度.F
	char upperlimit[20]; //温度上限 
	char lowerlimit[20]; //温度下限
}SSurveillance;

typedef struct _spwm3
{
	int type;
}SPwm3;

//设置时间参数
typedef struct _SetTime
{
	char	date[16];
	char	time[8];
}SetTime_S;

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
	int ybindFlag;						//硬解绑开启标志，0->未开启,1->开启
}DeviceInfo;
typedef struct _pushinfo
{
	int type; //0->移动侦测,1->声音侦测,2->温度侦测,3->低电量侦测
	char temperature[64]; //温度
	int tempType; //0->摄氏温度  1->华氏温度
	int temperatureAlarmType;//:0->低温报警  1->高温报警
}SPushInfo;
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
	AVM_MSG_NORMAL,
	

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
	AVM_SUMMSG_TEMP, //pdata数据为为json格式:形如{"Temperature":"25643@30.6@32.2"};value(25643@30.6@32.2)的意思：格式形如:时间@温度@湿度
	AVM_SUMMSG_PIR, //pdata数据为空
	AVM_SUMMSG_PUSH, //pdata数据为json格式:形如{"Type":1,"Temperature","30.6"},Type:0->移动侦测,1->声音侦测,2->温度侦测,3->低电量侦测
	AVM_SUMMSG_SYS_REQ_RECORD, //请求录像或者拍照
	AVM_SUMMSG_SYS_REQ_SHUTDOWN, //请求关机
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

#define ECODE_INVALIDE_CHANNEL -0x210 //无效通道

//EErrorCode list

typedef enum{
	e_param_none = -1,
}EPARAMTYPE;

typedef struct _stFrameHeader
{
	unsigned int nIFrame;
	unsigned int nAVType;		//1 means video,2 means audio
	unsigned int dwSize;		//audio or video data size
	unsigned int dwFrameRate;	//video frame rate or audio samplingRate
	unsigned int dwTimeStamp;
	unsigned int gs_video_cap;	//video's capability
	unsigned int gs_reserved; 
}stFrameHeader;

typedef int (*UMMsgCallback)(MESSAGETYPE msgtype,MESSAGESUBTYPE submsgtype, void* msgbody,int msglen);
typedef int (*AvDataCallback)(int channelid,stFrameHeader* pheader,unsigned char* pdata, int datalen,void* popt);
typedef int (*MsgCallback)(int channelid,MESSAGETYPE msgtype,MESSAGESUBTYPE submsgtype, unsigned char* pdata, int datalen,void* popt);

#ifdef __cplusplus
}
#endif

#endif //_ULIFEDEFINES_H__
