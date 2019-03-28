#include "libUlife_API.h"
#include "AV_Stream.h"
#include "WlanDeviceSearch.h"
#include "GVAPWorker.h"
#include "DeviceParamsConfig.h"
#include "DebugPrint.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#ifndef WIN32
#include <unistd.h>
#include<signal.h>
#endif

int g_isDeviceSearchInit = 0;

static int StartModuleGvap();
static void StopModuleGvap();

#ifndef WIN32
static void sig_handler(int signal)
{
	if (SIGPIPE == signal)
	{
		pr_debug("sig_handler *********\n");
	}
}
#endif

int Init_Sdk()
{
	if(g_isDeviceSearchInit)
	{
		WlanDevSearchUnInit();
	}

	StartModuleGvap();

#ifndef WIN32
	signal(SIGPIPE,sig_handler);
#endif

	return 0;
	
}

int Release_Sdk()
{
	StopModuleGvap();
	return 0;
}

//////////////////////////////////////////////////////////////////////////
//user management module
GVAPWorker* g_pworker = NULL;

int StartModuleGvap()
{
	if(g_pworker == NULL)
	{
		g_pworker = GVAP_Create();
	}

	if(g_pworker == NULL)
		return -1;
	else
		return 0;
}

void StopModuleGvap()
{
	if(g_pworker != NULL)
	{
		GVAP_Destroy(g_pworker);
		g_pworker = NULL;
	}
}

int UM_SetCallbak(UMMsgCallback msgcallback)
{
	GVAP_SetCallback(g_pworker,msgcallback);
	return 0;
}

int UM_Register( const char* username,const char* password,const char* evidenceaddr )
{
	return GVAP_Register(g_pworker,username,password,evidenceaddr);
}

int UM_Login(const char* username,const char* password)
{
	GVAP_Login(g_pworker,username,password);
	return 0;
}

int UM_Verify( const char* authcode )
{
	return GVAP_Verify(g_pworker,authcode);
	return 0;
}

int UM_Logout()
{
	GVAP_Logout(g_pworker);
	return 0;
}

int UM_BindDevice( const char* devid )
{
	return GVAP_BindDevice(g_pworker,devid);
	return -1;
}

int UM_UnBindDevice( const char* devid )
{
	return GVAP_UnBindDevice(g_pworker,devid);
	return -1;
}

int UM_GetDeviceListCounts()
{
	return GVAP_GetDeviceListCounts(g_pworker);
	return -1;
}

DeviceInfo* UM_GetDevice( int nIndex )
{
	return GVAP_GetDevice(g_pworker,nIndex);
	return NULL;
}

int UM_SetDeviceInfo( const char* devid,int cmd,void* param,int len )
{
	return GVAP_SetDeviceInfo(g_pworker,devid,cmd,param,len);
}

//////////////////////////////////////////////////////////////////////////
int LanSearchDevice(int timeout,const char* camType)
{
	if(!g_isDeviceSearchInit)
	{
		WlanDevSearchInit(camType);
		g_isDeviceSearchInit = 1;
	}
	return WlanDevSearchSearch(timeout);
}

DeviceInfo* LanGetDeviceBySearch( int index )
{
	return WlanDevSearchGetDeviceByIndex(index);
}

//////////////////////////////////////////////////////////////////////////
//param control : device params config
#define MAX_PCTRL_CHANNEL_COUNT 128
SPCtrlData* g_spcdata[MAX_PCTRL_CHANNEL_COUNT] = {0};

int PM_CreateChannel( const char* addr ,int port,const char* devid,const char* username, const char* password,MsgCallback msgcallback,	void* popt)
{
	int i = 0;
	int channel = -1;
	int nMinChannel = -1;
	for( i = 0; i < MAX_PCTRL_CHANNEL_COUNT; i++)
	{
		if(g_spcdata[i] != NULL)
		{
			if(strcmp(g_spcdata[i]->ipaddr,addr) == 0)
			{
				channel = i;
				break;
			}
		}
		else
		{
			if(nMinChannel != -1)
			{
				nMinChannel = nMinChannel < i ? nMinChannel : i;
			}
			else
			{
				nMinChannel = i;
			}
		}
	}
	if (channel == -1)
	{
		if(nMinChannel == -1)
			return ECODE_CHANNEL_OUTOF_RANGE;
		else	
			channel = nMinChannel;
	}

	g_spcdata[channel] = PCTRL_Create(addr,port);//5552

	if(g_spcdata[channel] == NULL)
		return ECODE_ALLOC_FAILED;
	
	g_spcdata[channel]->popt = popt;
	g_spcdata[channel]->msgCallback = msgcallback;
	strcpy(g_spcdata[channel]->username,username);
	strcpy(g_spcdata[channel]->password,password);
	strcpy(g_spcdata[channel]->devid,devid);

	return channel;
}

int PM_DestroyChannel( int channelid )
{
	if (channelid >= 0 && channelid < MAX_PCTRL_CHANNEL_COUNT)
	{
		PCTRL_Destroy(g_spcdata[channelid]);
		g_spcdata[channelid] = NULL;
	}
	return 0;
}

int PM_CtrlParam( int channelid,int cmd,void* param,int len )
{
	if (channelid >= 0 && channelid < MAX_PCTRL_CHANNEL_COUNT)
	{
		return PCTRL_CtrlParam(g_spcdata[channelid],cmd,param,len);
	}
	return -1;
}

//////////////////////////////////////////////////////////////////////////
//audio video managment module
#define MAX_CHANNEL_COUNT 36
SAVStream* g_gvapstream[MAX_CHANNEL_COUNT] = {0};
THREAD_HANDLE g_thavmessage[MAX_CHANNEL_COUNT] = {0};
int g_thmsgswitch[MAX_CHANNEL_COUNT] = {0};

static THREADRETURN ThreadAvMessage(void *param)
{
	if(param)
	{
		int channelid = *(int*)param;
		free(param);
		int disconnectFlag[MAX_CHANNEL_COUNT] = {-1};
		while (1)
		{
//			if (g_gvapstream[channelid]->m_nSockTrans == -1 && g_gvapstream[channelid]->m_isstart && g_gvapstream[channelid]->m_msgcallback != NULL)
			if(g_gvapstream[channelid]->bReCnntFlag && g_gvapstream[channelid]->m_msgcallback != NULL)
			{
				if(disconnectFlag[channelid] != g_gvapstream[channelid]->bReCnntFlag)	//3s钟提示提示一次
				{
					g_gvapstream[channelid]->m_msgcallback(channelid,AVM_MSG_CONNECTIONS,AVM_SUMMSG_DISCONNECTED,NULL,0,g_gvapstream[channelid]->popt);
// 					disconnectFlag[channelid] = g_gvapstream[channelid]->m_lastDisconnectCount;
				}
			}
			disconnectFlag[channelid] = g_gvapstream[channelid]->bReCnntFlag;
			

#ifdef WIN32
			Sleep(500);
#else
			usleep(1000*500);
#endif
			
			if(g_thmsgswitch[channelid])
				break;
		}
		g_thavmessage[channelid] = THREAD_HANDLENULL;
	}
	return THREADRETURNVALUE ;
}

static void DestroyThread(int type,int channelid)
{
	//audio 0, video 1, all 2
	if (channelid >= 0 && channelid < MAX_CHANNEL_COUNT)
	{
		if (type >= 2)
		{
			while (g_thavmessage[channelid] != THREAD_HANDLENULL)
			{
#ifdef WIN32
				Sleep(10);
#else
				usleep(1000*10);
#endif
			}
			g_thmsgswitch[channelid] = 0;
		}
	}
}

int AM_CreateChannel( const char* addr,int port,const char* devid,const char* username, const char* password ,AvDataCallback datacallback,MsgCallback msgcallback,void* popt)
{
	int channel = -1;
	for(int i = 0; i < MAX_CHANNEL_COUNT; i++)
	{
		if(g_gvapstream[i] == NULL)
		{
			channel = i;
			break;
		}
	}
	if (channel == -1)
	{
		return ECODE_CHANNEL_OUTOF_RANGE;
	}

	SAVStream* pstream = AV_Create();
	if (pstream == NULL)
	{
		return ECODE_ALLOC_FAILED;
	}
	g_gvapstream[channel] = pstream;
	pstream->m_port = port;
	strcpy(pstream->m_username,username);
	strcpy(pstream->m_password,password);
	strcpy(pstream->m_strdev,devid);
	strcpy(pstream->m_ipaddr,addr);
	pstream->m_datacallback = datacallback;
	pstream->m_msgcallback = msgcallback;
	pstream->m_channelid = channel;
	pstream->popt = popt;

	if(g_thavmessage[channel] == THREAD_HANDLENULL)
	{
		int *param = (int*)malloc(sizeof(int));
		*param = channel;
		g_thavmessage[channel] = thread_create_normal(ThreadAvMessage,param);
		if (g_thavmessage[channel] == THREAD_HANDLENULL)
		{
			free(param);
		}
	}

	if (channel >= 0 && channel < MAX_CHANNEL_COUNT)
	{
		if(AV_Start(g_gvapstream[channel]) == 0)
		{
			if(AV_CreateVideo(g_gvapstream[channel]))
				return channel;
			else
			{
				AM_DestroyChannel(channel);
				return -1;
			}
		}
		else
		{
			AM_DestroyChannel(channel);
			return -1;
		}
	}

	return channel;
}

int AM_DestroyChannel( int channelid )
{
	if (channelid >= 0 && channelid < MAX_CHANNEL_COUNT)
	{
		pr_debug("Start AM_destroy, channel = %d\n",channelid);
		if(g_gvapstream[channelid] == NULL)
			return ECODE_INVALIDE_CHANNEL;
		g_thmsgswitch[channelid] = 1;
		DestroyThread(2,channelid);
		AV_Destroy(g_gvapstream[channelid]);
		g_gvapstream[channelid] = NULL;
		pr_debug("end Am_destroy\n");
		return ECODE_OK;
	}
	
	pr_debug("End am_destroy failed\n");
	return ECODE_CHANNEL_OUTOF_RANGE;
}

int AM_OpenVideoStream( int channelid )
{
	if (channelid >= 0 && channelid < MAX_CHANNEL_COUNT)
	{
		if(g_gvapstream[channelid] == NULL)
			return -1;
		if(AV_Start(g_gvapstream[channelid]) == 0)
		{
			if(AV_OpenVideo(g_gvapstream[channelid]))
				return ECODE_OK;
			else
				return -1;
		}
		else
		{
			return -1;
		}
	}

	return ECODE_CHANNEL_OUTOF_RANGE;
}

int AM_CloseVideoStream( int channelid )
{
	if (channelid >= 0 && channelid < MAX_CHANNEL_COUNT)
	{
		if(g_gvapstream[channelid] == NULL)
			return -1;

		DestroyThread(1,channelid);

		if(AV_CloseVideo(g_gvapstream[channelid]))
			return 0;
	}

	return ECODE_CHANNEL_OUTOF_RANGE;
}

int AM_OpenAudioStream( int channelid )
{
	if (channelid >= 0 && channelid < MAX_CHANNEL_COUNT)
	{
		if(g_gvapstream[channelid] == NULL)
			return -1;

		if(AV_IsVideoOpen(g_gvapstream[channelid]))
		{
			if(AV_OpenAudio(g_gvapstream[channelid]))
				return 0;
			else
				return -1;
		}
		else
		{
			return -1;
		}
	}

	return ECODE_CHANNEL_OUTOF_RANGE;
}

int AM_CloseAudioStream( int channelid )
{
	if (channelid >= 0 && channelid < MAX_CHANNEL_COUNT)
	{

		if(g_gvapstream[channelid] == NULL)
			return -1;

		DestroyThread(0,channelid);

		if(AV_CloseAudio(g_gvapstream[channelid]))
			return 0;
	}

	return ECODE_CHANNEL_OUTOF_RANGE;
}

int AM_SwitchHdBd( int channelid,int hd )
{
	if (channelid >= 0 && channelid < MAX_CHANNEL_COUNT)
	{
		if(g_gvapstream[channelid] == NULL)
			return -1;

		return AV_SwitchHdBd(g_gvapstream[channelid],hd);
	}

	return ECODE_CHANNEL_OUTOF_RANGE;
}