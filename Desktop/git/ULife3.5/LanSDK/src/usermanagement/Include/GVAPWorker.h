// GVAPWorker.h


#ifndef _GVAPWORKER_H_
#define _GVAPWORKER_H_

#include "GVAP_Protocal.h"
#include "GVAP_PackageHeader.h"
#include "UlifeDefines.h"
#include "ThreadUtil.h"

typedef void *LPVOID;
#define MAX_ARRAY_COUNT		1000
#define MAX_GROUP_COUNT		20

typedef struct _userinfo
{
	int  nStatus ;
	char  szUserName[128];
	char  szPassword[256] ;
	char  szNickName[128];
	int         nType;
}UserInfo;

typedef struct 
{
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
} struWiFiPara;


#pragma pack(1)
typedef struct 
{
	char sz3GUser[60];           //user name
	char sz3GPWD[60];			 //pwd
	char sz3GAPN[128];           //apn
	char szDialNum[44];          //WiFi����������
} stru3GPara;
#pragma pack()

typedef struct
{
	char szDevID[128];
	char szMessTitle[128];
	char szMessContent[256];
	char szMessTime[48];
}AlarmMessage;

typedef enum
{
	NOTIFY_LOGIN,
	NOTIFY_LOGOUT,
	NOTIFY_USERDATA,
	NOTIFY_USERSTATUS,
	NOTIFY_DEVLIST,
	NOTIFY_DEVSTATUS,
	NOTIFY_ALARMINFO,
	NOTIFY_DISCONNECTION,
}NotifyType;

typedef struct  
{
	int dwGroupID;
	int dwCountIndex;
	int dwCountTotal;
	int dwPageTotal;
	int dwPageIndex;
}GroupType;

typedef struct _cgvapworker 
{
	UMMsgCallback							m_callback;
	int												m_bManuRMyList;
	DeviceInfo *						m_arrPubDevs[MAX_ARRAY_COUNT];
	int									m_pubdevcounts;
	DeviceInfo *						m_arrMyDevs[MAX_ARRAY_COUNT];
	int			m_mydevcounts;
	DeviceInfo *						m_arrLocDevs[MAX_ARRAY_COUNT];
	int m_locdevcounts;
	DeviceInfo*	s_arrSubGroups[MAX_ARRAY_COUNT];
	int  m_parentid[MAX_GROUP_COUNT];
	GroupType*						m_arrGroupList[MAX_GROUP_COUNT];
	int m_grouptypecount;
	CGVAPPackageParser								*m_GenParser;
	CGVAPPackageBuilder									*m_ProtocolPacket;
	int  											m_dwTotalDevs;
	int  											m_dwCountDevs;
	int												m_errcode;
	int												m_binitiativelogout;
	int												m_iPubVersion;
	int												m_iPubCurVersion;
	int												m_iMyVersion;
	int												m_iMyCurVersion;
	int												m_sLoginSock ;
	int												m_bInLogin   ;
	int												m_dwHeartBeatInterval ;
	char											m_szStatusDesc[2048];
	int												m_dwGetInfosCount ;
	int												m_dwGetStatusCount ;
	char  											m_szUsername[128] ;
	char  											m_szPassword[256] ;
	char  											m_szIPRegisterSvr[256] ;
	char  											m_szIPLoginSvr[256] ;
	int												m_wPortRegister ;
	int												m_wPortLogin ;
	int												m_bInland;
	THREAD_HANDLE							m_thdatarecv;
}GVAPWorker;

/////////////////////////////////////////////
GVAPWorker* GVAP_Create();
void GVAP_Destroy(GVAPWorker* pworker);
void GVAP_SetCallback(GVAPWorker* pworker,UMMsgCallback callback);
int GVAP_Register(GVAPWorker* pworker,const char* username,const char* password,const char* evidenceaddr);
int GVAP_Login(GVAPWorker* pworker,const char* username,const char* password);
int GVAP_Verify(GVAPWorker* pworker,const char* authcode);
int GVAP_Logout(GVAPWorker* pworker);
int GVAP_BindDevice(GVAPWorker* pworker,const char* devid);
int GVAP_UnBindDevice(GVAPWorker* pworker,const char* devid);
int GVAP_GetDeviceListCounts(GVAPWorker* pworker);
DeviceInfo* GVAP_GetDevice(GVAPWorker* pworker,int nIndex);
int GVAP_SetDeviceInfo(GVAPWorker* pworker,const char* devid,int cmd,void* param,int len );

//CamNetParam *GetDevInfoBySerial(const char* lpDeviceID) ;

#endif 
