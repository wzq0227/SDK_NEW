#ifndef	_BROADCASTWORKER_H__
#define _BROADCASTWORKER_H__

#ifdef __cplusplus
extern "C" {
#endif

#include "UlifeDefines.h"

#pragma pack(1)
typedef struct
{
	unsigned char bStatus;	        ///< schedule status ( 0:disable 1:enable }
	unsigned char nDay;		        ///< schedule day of week (1:Mon 2:Tue 3:Wed 4:Thr 5:Fri 6:Sat 7:Sun 8:Everyday 9:Working day 10:Today)
	unsigned char nStartHour;	    ///< Hour from 0 to 23.
	unsigned char nStartMin;	    ///< Minute from 0 to 59.
	unsigned char nStartnSec;	    ///< Second from 0 to 59.
	unsigned char nDurationHour;	///< Hour from 0 to 23.
	unsigned char nDurationMin;	    ///< Minute from 0 to 59.
	unsigned char nDurationSec;	    ///< Second from 0 to 59.
} Schedule;
#pragma pack()

#pragma pack(1)
typedef struct
{
	int  nCmd;                   //标识命令字
	char szPacketFlag[24];       //标识字符
	char szDeviceName[20];       //设备名称
	char szDeviceType[24];       //设备类型
	int  nMaxChannel;            //最大通道数
	char szDeviceIP[16];         //设备IP
	char szDeviceMasK[16];       //设备子网掩码
	char szDeviceGateWay[16];    //设备网关
	char szMultiAddr[16];        //设备多播地址
	char szMacAddr_LAN[8];       //设备MAC 地址
	char szMacAddr_WIFI[8];      //设备MAC 地址
	//char szRevsered0[16];
	int ybind;			//绑定状态,0->未开启开启硬解绑，1->开启硬解绑
	char szRevsered0[12];			
	char szDevDNS0[16];          //设备DNS地址
	char szDevDNS1[16];          //DNS地址暂没用
	int  nMultiPort;             //多播端口
	int  nDataPort;              //数据端口
	int  nWebServerPort;         //WEB 端口

	char szUserName[16];         //用户名
	char szPwd[16];              //密码
	char szCameraVer[8];         //软件版本

	char szWanServerIP[24];      //广域网IP
	char szServerPort[8];        //广域网端口
	char szDevID[64];            //设备序列号

	int  nEnableWiFiDHCP;        //是否允许WiFi的DHCP
	int  nEnableWiFi;            //是否允许WiFi
	int  nWiFiEncryMode;         //WiFi加密模式
	char szWiFiIP[20];           //WiFi的IP
	char szWiFiSSID[128];        //WiFi名称
	char szWiFiPwd[64];          //WiFi密码

	int  nEnableDevDHCP;		 //设备DHCP
	char szWiFiMasK[16];         //WiFi的子网掩码
	char szWiFiGateWay[16];      //WiFi的网关
	char szWiFiDNS0[16];         //WiFi的DNS地址
	char szWiFiDNS1[16];         //

	unsigned int uOfferSize;     //提供的视频分辨率
	unsigned int uImageSize;     //当前视频分辨率
	unsigned int uMirror;        //视频镜像
	unsigned int uFlip;          //视频翻转
	unsigned int uRequestStream; //
	unsigned int uBitrate1;      //波特率
	unsigned int uFramerate1;    //帧率
	//第二路码流
	unsigned int uBitrate2;      //波特率
	unsigned int uFramerate2;    //帧率

	unsigned int uImagesource;   //分辨率(NTSC/PAL)
	unsigned int uChangePWD;     //1: need to change 0: not to change
	char szNewPwd[16];           //the new password
	int  nDeviceNICType;         //0 wired NIC;1 wifi NIC
	unsigned int uEnableAudio;   //是否开启音频
	unsigned char	 bgioinenable;	 ///< GIO input enable
	unsigned char	 bgiointype;	 ///< GIO input type
	unsigned char	 bgiooutenable;	 ///< GIO output enable
	unsigned char	 bgioouttype;	 ///< GIO output type
	unsigned char	 bAlarmEnable;	 ///alarm enable or disable
	unsigned char	 cRs485baudrate; ///0-9600 1-4800 2-2400 
	char	szRemoteIP[16];			 //传参借用，非结构体定义
	unsigned int uNicType;			 //传参借用，非结构体定义

	char szRevsered1[20];

	unsigned char nAlarmAudioPlay;
	unsigned char nAlarmDuration;
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
	unsigned char bDeviceRest;      /// 设备复位命令
	unsigned char bEnableEmailRcv;      /// 开启报警邮件的接收
	unsigned char bAttachmentType;      /// 设置邮件附件的类型 0->avi  1->jpeg  2->不带附件
	//
	unsigned char ntp_timezone;      /// 设置系统时区，0-24 详细定义看下面的注释，
	//最高位可以用来设置夏令时，默认自动设置夏令时
	unsigned int  nYear;	        ///< 当前年份值减去1900.
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

}CamNetParam;
#pragma pack()

int WlanDevSearchInit(const char* camType);
void WlanDevSearchUnInit();
int WlanDevSearchSearch(int timeout);
DeviceInfo* WlanDevSearchGetDeviceByIndex(int nIndex);

#ifdef __cplusplus
}
#endif

#endif