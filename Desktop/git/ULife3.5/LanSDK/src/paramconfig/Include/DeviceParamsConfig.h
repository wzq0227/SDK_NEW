#ifndef	__TCP_TRANSMIT_WITH_DEVICE_HH__
#define __TCP_TRANSMIT_WITH_DEVICE_HH__


#include "UlifeDefines.h"
#include <stdio.h>

#ifndef WIN32
#include <pthread.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct _paramctrldata
{
	int								nSockTrans;
	char							ipaddr[20];	//ip地址
	char							devid[64];
	char							username[64];
	char							password[64];
	int    							port;				//端口
	char							*pAcks;			//用于接收查询返回的数据

	int								dwRecvErrTime;
	char*							dayEventAck;	//保存“询问某天发生事件的返回列表”
	char*							daylogs;
	char*					strdownloadsavePath;

	int								bDownloading;
	FILE*							stroedFile;
	int								fileLen;
	int								fileLenBase;
	int								brightness;
	int								contrast;
	int								saturation;
	int								hue;
	int								lastEventType;
	int								workEnType;
	int								bRtspOn;
	int								noiseLvl;
	char								strErrorInfo[1024];

	AVResolutionN*	arrAVResolution;
	int rescount;
	WifiInfoN*								arrWifi;
	int											wificount;
	void*							popt;
	MsgCallback					msgCallback;
	SCurTempHum				*m_curTemp;
	char								transcmd[256];
	int								m_cmdType;
	SSwitchMotion				m_motion;
	char								m_RetAudio[64];
	int								m_curAlarmRing;
	SDevAttr*						m_devAtrr;	
	SSdcardRecQuery*		m_SdcardRecQuery;
	int								m_setWifi;
	int								m_setAp;
	int								m_pwm3Type;
#ifndef WIN32
	pthread_mutex_t			m_mutex;
#endif
}SPCtrlData;

SPCtrlData* PCTRL_Create(const char* ipaddr,int port);
void PCTRL_Destroy(SPCtrlData* pspctrldata);
int PCTRL_CtrlParam(SPCtrlData* pspctrldata,int cmd,void* param,int paramlen);
char* PCTRL_GetErrorInfo(SPCtrlData* pspctrldata);

#ifdef __cplusplus
}
#endif

#endif	//__TCP_TRANSMIT_WITH_DEVICE_HH__
