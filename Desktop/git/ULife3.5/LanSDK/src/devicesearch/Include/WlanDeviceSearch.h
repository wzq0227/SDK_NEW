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
	int  nCmd;                   //��ʶ������
	char szPacketFlag[24];       //��ʶ�ַ�
	char szDeviceName[20];       //�豸����
	char szDeviceType[24];       //�豸����
	int  nMaxChannel;            //���ͨ����
	char szDeviceIP[16];         //�豸IP
	char szDeviceMasK[16];       //�豸��������
	char szDeviceGateWay[16];    //�豸����
	char szMultiAddr[16];        //�豸�ಥ��ַ
	char szMacAddr_LAN[8];       //�豸MAC ��ַ
	char szMacAddr_WIFI[8];      //�豸MAC ��ַ
	//char szRevsered0[16];
	int ybind;			//��״̬,0->δ��������Ӳ���1->����Ӳ���
	char szRevsered0[12];			
	char szDevDNS0[16];          //�豸DNS��ַ
	char szDevDNS1[16];          //DNS��ַ��û��
	int  nMultiPort;             //�ಥ�˿�
	int  nDataPort;              //���ݶ˿�
	int  nWebServerPort;         //WEB �˿�

	char szUserName[16];         //�û���
	char szPwd[16];              //����
	char szCameraVer[8];         //�����汾

	char szWanServerIP[24];      //������IP
	char szServerPort[8];        //�������˿�
	char szDevID[64];            //�豸���к�

	int  nEnableWiFiDHCP;        //�Ƿ�����WiFi��DHCP
	int  nEnableWiFi;            //�Ƿ�����WiFi
	int  nWiFiEncryMode;         //WiFi����ģʽ
	char szWiFiIP[20];           //WiFi��IP
	char szWiFiSSID[128];        //WiFi����
	char szWiFiPwd[64];          //WiFi����

	int  nEnableDevDHCP;		 //�豸DHCP
	char szWiFiMasK[16];         //WiFi����������
	char szWiFiGateWay[16];      //WiFi������
	char szWiFiDNS0[16];         //WiFi��DNS��ַ
	char szWiFiDNS1[16];         //

	unsigned int uOfferSize;     //�ṩ����Ƶ�ֱ���
	unsigned int uImageSize;     //��ǰ��Ƶ�ֱ���
	unsigned int uMirror;        //��Ƶ����
	unsigned int uFlip;          //��Ƶ��ת
	unsigned int uRequestStream; //
	unsigned int uBitrate1;      //������
	unsigned int uFramerate1;    //֡��
	//�ڶ�·����
	unsigned int uBitrate2;      //������
	unsigned int uFramerate2;    //֡��

	unsigned int uImagesource;   //�ֱ���(NTSC/PAL)
	unsigned int uChangePWD;     //1: need to change 0: not to change
	char szNewPwd[16];           //the new password
	int  nDeviceNICType;         //0 wired NIC;1 wifi NIC
	unsigned int uEnableAudio;   //�Ƿ�����Ƶ
	unsigned char	 bgioinenable;	 ///< GIO input enable
	unsigned char	 bgiointype;	 ///< GIO input type
	unsigned char	 bgiooutenable;	 ///< GIO output enable
	unsigned char	 bgioouttype;	 ///< GIO output type
	unsigned char	 bAlarmEnable;	 ///alarm enable or disable
	unsigned char	 cRs485baudrate; ///0-9600 1-4800 2-2400 
	char	szRemoteIP[16];			 //���ν��ã��ǽṹ�嶨��
	unsigned int uNicType;			 //���ν��ã��ǽṹ�嶨��

	char szRevsered1[20];

	unsigned char nAlarmAudioPlay;
	unsigned char nAlarmDuration;
	unsigned char bAlarmUploadFTP;	    ///< ����¼����ļ��ϴ���ftp
	unsigned char bAlarmSaveToSD;	    ///< ����¼����ļ����浽sd��
	unsigned char bSetFTPSMTP;	    ///< Ϊ1��ʾ����FTP������Ϊ2��ʾ����SMTP����
	char servier_ip[37];            ///< FTP or SMTP server address 
	char username[16];              ///< FTP or SMTP login username
	char password[16];              ///< FTP or SMTP login password
	unsigned int uPort;             ///< FTP or SMTP 

	/*GVAP*/
	char szBindAccont[48];          //���û���
	char szDevSAddr[48];            //�豸��������ַ������
	unsigned int uDevSPort;         //�豸�������˿�

	char szSMTPReceiver[64];        //�����ʼ�����
	unsigned char motionenable;		///< motion detection enable
	unsigned char motioncenable;	///< customized sensitivity enable
	unsigned char motionlevel;		///< predefined sensitivity level
	unsigned char motioncvalue;		///< customized sensitivity value
	unsigned char motionblock[4];   ///< motion detection block data
	unsigned char bDeviceRest;      /// �豸��λ����
	unsigned char bEnableEmailRcv;      /// ���������ʼ��Ľ���
	unsigned char bAttachmentType;      /// �����ʼ����������� 0->avi  1->jpeg  2->��������
	//
	unsigned char ntp_timezone;      /// ����ϵͳʱ����0-24 ��ϸ���忴�����ע�ͣ�
	//���λ����������������ʱ��Ĭ���Զ���������ʱ
	unsigned int  nYear;	        ///< ��ǰ���ֵ��ȥ1900.
	unsigned char nMon;	            ///< Mounth from 1 to 12. �޸�ʱ��ʱ���Ƚ��·ݸ�ֵ�ã�
	//�ٽ��·����λ����Ϊ1(nMon|0x80)
	unsigned char nDay;	            ///< Second from 1 to 31.
	unsigned char nHour;	        ///< Hour from 0 to 23.
	unsigned char nMin;	            ///< Minute from 0 to 59.
	unsigned char nSec;	            ///< Second from 0 to 59.

	unsigned char nSdinsert;		        ///< SD card inserted��ֵΪ3��ʾsd��������ʹ��
	unsigned char bSchedulesUploadFTP;	    ///< Schedule¼����ļ��ϴ���ftp
	unsigned char bSchedulesSaveToSD;	    ///< Schedule¼���ļ����浽sd�������λΪ1��ʾ¼�񸲸�

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