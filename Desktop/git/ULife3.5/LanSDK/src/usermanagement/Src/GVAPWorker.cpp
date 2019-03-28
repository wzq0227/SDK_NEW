#include "GVAPWorker.h"
#include "QuickSocket.h"
//#include "UTF8Utils.h"
#include "tinyxml.h"
#include "Tlib_ProtocolAX.h"
#include <stdlib.h>

#ifndef WIN32
#include <unistd.h>
#endif

typedef enum
{
	GET_VRESIONS,
	GET_PBDEVLIST,
	GET_DEVLIST,
	GET_DEVINFO,
	GET_USRINFO,
	GET_DEVSTATUS,
	GET_DEVAUTH,
	GET_MAX
}GetType;

typedef enum
{	
	GET_ALL,
	GET_PUBTYPE,
	GET_MYTYPE
};

char gcmdGetDayEventList[]								= "4030";	//获取某天事件列表,比如录像事件,
char gcmdGetDayEventListACK[]							= "4031";	//获取某天事件列表,比如录像事件, ACK
char gcmdDownloadEvent[]									= "4032";	//下载音视频命令
char gcmdDownloadEventACK[]								= "4033";	//下载音视频命令 ACK
char gcmdStopDownloadEvent[]								= "4034";	//中止下载音视频命令
char gcmdStopDownloadEventACK[]							= "4035";	//中止下载音视频命令 ACK
char gcmdGetImageColor[]									= "5000";	//获取图像颜色
char gcmdGetImageColorACK[]								= "5001";	//获取图像颜色 ACK
char gcmdSetImageColor[]									= "5002";	//设置图像颜色
char gcmdSetImageColorACK[]								= "5003";	//设置图像颜色 ACK
char gcmdSetDefaultColor[]								= "4012";	//恢复默认图像颜色
char gcmdSetDefaultColorACK[]							= "4013";	//恢复默认图像颜色ACK
char gcmdSetRtspAudioSwitch[]							= "4004";	//设置rtsp音频开关
char gcmdSetRtspAudioSwitchACK[]							= "4005";	//设置rtsp音频开关ACK
char gcmdSetNoiseLvl[]									= "4006";	//设置低噪度降噪等级
char gcmdSetNoiseLvlACK[]								= "4007";	//设置低噪度降噪等级ACK
char gcmdGetRtspAudioSwitch[]							= "4008";	//获取rtsp音频开关
char gcmdGetRtspAudioSwitchACK[]							= "4009";	//获取rtsp音频开关ACK
char gcmdGetNoiseLvl[]									= "4010";	//获取低噪度降噪等级
char gcmdGetNoiseLvlACK[]								= "4011";	//获取低噪度降噪等级ACK
char gcmdGetResolution[]									= "5004";	//获取分辨率
char gcmdGetResolutionACK[]								= "5005";	//获取分辨率 ACK
char gcmdSetResolution[]									= "5006";	//设置分辨率
char gcmdSetResolutionACK[]								= "5007";	//设置分辨率 ACK
char gcmdGetWifiList[]									= "5008";	//获取wifi列表
char gcmdGetWifiListACK[]								= "5009";	//获取wifi列表 ACK
char gcmdSetWifi[]										= "5010";	//设置wifi
char gcmdSetWifiACK[]									= "5011";	//设置wifi ACK
char gcmdGetWorkEn[]										= "5012";	//设置工作环境
char gcmdGetWorkEnACK[]									= "5013";	//设置工作环境 ACK
char gcmdSetWorkEn[]										= "5014";	//设置工作环境
char gcmdSetWorkEnACK[]									= "5015";	//设置工作环境 ACK
char gcmdQueryDayLog[]									= "200";	//查询日志
char gcmdQueryDayLogACK[]								= "201";	//查询日志 ACK

#define DEVICE_SETPORT_default 8628
#define DEVICE_GETPORT_default 8629
static int   s_wPortDeviceSet = DEVICE_SETPORT_default ;
static int   s_wPortDeviceGet = DEVICE_GETPORT_default ;
static int  s_dwLastGroupID  = 0 ;
static int  s_dwLastParentID  = 0;
static int  s_dwLocalGroupID = 100 ;

int g_bStartGetGroupEvent = 1;
// global function
#define IsEmptyStr(pstr)  ( (pstr == NULL) || (strlen(pstr) == 0) )

/////////////////////////////////////////////////
	static void  			StartLogin(GVAPWorker* pworker);
	static void  			StartRecvLoacalDev(GVAPWorker* pworker);
	static void  			GetDevInfos(GVAPWorker* pworker) ;
	static void  			GetDevStatus(GVAPWorker* pworker) ;
	static int				KeepAlive(GVAPWorker* pworker);
	
	static THREADRETURN 	ThreadLogin(void *pvoid);
	static THREADRETURN  	ThreadDataRecv(void *pvoid);
	static THREADRETURN  	ThreadHeartBeat(void *pvoid);
	static THREADRETURN  	ThreadGetGroupSub(void *pvoid) ;
	static void 			SetUserName(GVAPWorker* pworker,const char* lpszUsername,const char* lpszPassword) ;
	static void 			DoLogout(GVAPWorker* pworker) ;
	static int 				DoCtrlDevice(GVAPWorker* pworker,void* param,int len);
	static int 				Connect2UsrServer(GVAPWorker* pworker);
	static int 				DoUserRegister(GVAPWorker* pworker,const char* lpszUsername,const char* lpszPassword,const char* lpszNickname) ;	
	static int 				DoUserModify(GVAPWorker* pworker,const char* lpszUsername,const char* lpszPassword,const char* lpszNickname,const char* lpNewPwd) ;
	static int 				DoUserUnRegister(GVAPWorker* pworker,const char* lpszUsername,const char* slpzPassword);
	static int 				DoDevRegister(GVAPWorker* pworker,const char* lpszDevID,const char* lpszDevName,int nType,const char* lpszHversion, const char* lpszSversion,  const char* lpszDataserver);
	static int 				DoDevUnRegister(GVAPWorker* pworker,const char* lpszDevID) ;
	static int 				DoDevQuery(GVAPWorker* pworker,const char* lpszDevID) ;
	static int 				DoDevModify(GVAPWorker* pworker,const char* lpszDevID,const char* lpszDevName,int nType,const char* lpszHversion, const char* lpszSversion,  const char* lpszDataserver) ;
	static int 				DoDevBind(GVAPWorker* pworker,const char* lpDevID,const char* lpszOldUserName,const char* lpszOldPassword)   ;
	static int 				DoDevUnBind(GVAPWorker* pworker,const char* lpDevID,const char* lpszOldUserName,const char* lpszOldPassword) ;
	static void 			SendCmd2LoginSrv(GVAPWorker* pworker,int dwSendType,int dwGetType,const char* lpAddValue) ;
	static void 			GenSendData2LoginSrv(GVAPWorker* pworker) ;
	static int 				RecvDataAndProcess(GVAPWorker* pworker) ;
	static void 			SortDevsStatus(GVAPWorker* pworker) ;
	static UserInfo*		GetUserInfo(GVAPWorker* pworker) ;
	static void  			SetHeaderCmd(GVAPWorker* pworker,const char* lpszHeaderName,const char* lpszResourceName,int bAutoAddUsername,int nType) ;
	static DeviceInfo*		GetDevInfoByID(GVAPWorker* pworker,const char* lpszDevID,int bGetDevType) ;
	static void  			AddHeaderSection(GVAPWorker* pworker,const char* lpszName,const char* lpszValue) ;
	static void  			Cleanup(GVAPWorker* pworker);
	static int  			TalktoRegSrv(GVAPWorker* pworker) ;
	static void  			LoadGVAPConfigure(GVAPWorker* pworker) ;
	static int  			DoDealWithAck(GVAPWorker* pworker,const char* lpRecvBuf,int dwBufLen) ;
	static int  			DoDealWithAck_Notify(GVAPWorker* pworker);
	static void  			DoDealWithAck_List(GVAPWorker* pworker);
	static void  			DoDealWithAck_Status(GVAPWorker* pworker,const char* lpRecvBuf,int dwBufLen);
	static void  			SendNotifyMsg(GVAPWorker* pworker,int dwNotifyType, long dwRelData) ;
	static void  			GetGroupSub(GVAPWorker* pworker,char *pszGroupID);
	static void  			RemoveMyList(GVAPWorker* pworker,char* strID);
	static void  			RemoveMyGroupList(GVAPWorker* pworker);
	static int 				ErrorCode(GVAPWorker* pworker);
// 	static void  ClearSearchLocalDevsArr();
	//static void 			GetLocSubDevInfo(GVAPWorker* pworker,int dwGroupID,std::vector<DeviceInfo *> & arrGets) ;
	static GroupType*				FindGroupTypeByParentID(GVAPWorker* pworker,int parentid);
	static int				BuildParams(int cmd,void* param,int len,char* pdst,int pdstlen);
// 	static int  IsPrivateIP(const char* lpszIP);

/////////////////////////////////////////////////

void LoadGVAPConfigure(GVAPWorker* pworker)
{
	pworker->m_wPortRegister = 5560;
	pworker->m_wPortLogin    = 5590;
	s_wPortDeviceGet= DEVICE_GETPORT_default;
	s_wPortDeviceSet= DEVICE_SETPORT_default;

	// gvap.net
	if(pworker->m_bInland)
	{
		//����
		strcpy(pworker->m_szIPRegisterSvr,"cnreg.gvap.net");
		strcpy(pworker->m_szIPLoginSvr,"cnuser.gvap.net");
	}
	else
	{
		//����ע��������
		strcpy(pworker->m_szIPRegisterSvr,"register.gvap.net");
		//����ת��������
		strcpy(pworker->m_szIPLoginSvr,"user.gvap.net");
	}
}

/*********************************************************************\
**		Thread
\*********************************************************************/
THREADRETURN ThreadLogin(void *pvoid)
{
	GVAPWorker* pworker = (GVAPWorker*)pvoid;
	if (pworker)
	{
		SetHeaderCmd(pworker,"login","usr",1,1);
		if (Connect2UsrServer(pworker))
		{
			pworker->m_thdatarecv = thread_create_normal(&ThreadDataRecv,pworker);
		}
		thread_create_normal(&ThreadHeartBeat,pworker);
	}

	return THREADRETURNVALUE;
}

THREADRETURN ThreadDataRecv(void *pvoid)
{
	GVAPWorker* pworker = (GVAPWorker*)pvoid;

	if (pworker == NULL)
	{
		return THREADRETURNVALUE;
	}

	int bRet = 0;
	int dwFailed = 0;

	while(1)
	{
		bRet = RecvDataAndProcess(pworker);

		if (!pworker->m_bInLogin)
			break;

		if (!bRet)
		{
			SetHeaderCmd(pworker,"login","usr",1,1);
			Connect2UsrServer(pworker);
		}

// #ifdef _WIN32
// 		Sleep(1000);
// #else
// 		sleep(1);
// #endif
	}
	pworker->m_thdatarecv = THREAD_HANDLENULL;

	return THREADRETURNVALUE;
}

// int IsPrivateIP(const char* lpszIP)
// {
// 	unsigned int nIP = WS_htonl(WS_inet_aton((char*)lpszIP));
// 
// 	if ((nIP>>24 == 0xa) ||(nIP>>16 == 0xc0a8) ||(nIP>>22 == 0x2b0))
// 	{
// 		return 1;
// 	}
// 	else
// 	{
// 		return 0;
// 	}
// }

THREADRETURN ThreadHeartBeat(void *pvoid) 
{
	GVAPWorker* pworker = (GVAPWorker*)pvoid;
	if (pworker)
	{
		while(1)
		{
			if(!pworker->m_bInLogin)
				break ;

			KeepAlive(pworker);
#ifdef WIN32
			Sleep(pworker->m_dwHeartBeatInterval*1000);
#else
			sleep(pworker->m_dwHeartBeatInterval);
#endif
		}
	}

	return THREADRETURNVALUE;
}

int Connect2UsrServer(GVAPWorker* pworker)
{	
	int nSock = QuickConnectToTCP(pworker->m_wPortLogin,pworker->m_szIPLoginSvr,2000);
	if (nSock != -1)
	{
		pworker->m_sLoginSock = nSock ;
		GenSendData2LoginSrv(pworker) ;
		return 1 ;
	}

	StopSocket(nSock) ;
	pworker->m_sLoginSock = -1 ;
	SendNotifyMsg(pworker,NOTIFY_LOGIN,2);		// �������ڷ�������,�޷����ӷ�����
	return 0 ;
}

void SortDevsStatus(GVAPWorker* pworker)
{
	int i=0;
	int j=0;
	char* strDevName1 = NULL;
	char* strDevName2 = NULL;
	int nSize = pworker->m_pubdevcounts ;
	for(i=0; i<nSize -1; i++)
	{
		for(j=i+1; j<nSize; j++)
		{
			strDevName1 = pworker->m_arrPubDevs[j]->szDevName;
			strDevName2 = pworker->m_arrPubDevs[i]->szDevName;
			if (strcmp(strDevName1,"") != 0 && strcmp(strDevName2 , "") != 0)
			{
#ifdef WIN32
				if(stricmp(strDevName1,strDevName2) < 0)
#else
				if(strcasecmp(strDevName1,strDevName2) < 0)
#endif
				{
					DeviceInfo *pTmp = pworker->m_arrPubDevs[j];
					pworker->m_arrPubDevs[j]  = pworker->m_arrPubDevs[i] ;
					pworker->m_arrPubDevs[i]  = pTmp ;
				}
			}
		}
	}

	for(i=0; i<nSize-1; i++)
	{
		for(j=i+1; j<nSize; j++)
		{
			if(pworker->m_arrPubDevs[j]->dwStatus > pworker->m_arrPubDevs[i]->dwStatus)
			{
				DeviceInfo *pTmp = pworker->m_arrPubDevs[j];
				pworker->m_arrPubDevs[j]  = pworker->m_arrPubDevs[i];
				pworker->m_arrPubDevs[i]  = pTmp ;
			}
		}
	}
	
	nSize = pworker->m_mydevcounts ;
	for(i=0; i<nSize-1; i++)
	{
		for(j=i+1; j<nSize; j++)
		{
			strDevName1 = pworker->m_arrMyDevs[j]->szDevName;
			strDevName2 = pworker->m_arrMyDevs[i]->szDevName;
			if (strcmp(strDevName1,"") != 0 && strcmp(strDevName2 , "") != 0)
			{
#ifdef WIN32
				if(stricmp(strDevName1,strDevName2) < 0)
#else
				if(strcasecmp(strDevName1,strDevName2) < 0)
#endif
				{
					DeviceInfo *pTmp = pworker->m_arrMyDevs[j];
					pworker->m_arrMyDevs[j]   = pworker->m_arrMyDevs[i] ;
					pworker->m_arrMyDevs[i]   = pTmp ;
				}
			}
		}
	}

	for(i=0; i<nSize-1; i++)
	{
		for(j=i+1; j<nSize; j++)
		{
			if(pworker->m_arrMyDevs[j]->dwStatus > pworker->m_arrMyDevs[i]->dwStatus)
			{
				DeviceInfo *pTmp = pworker->m_arrMyDevs[j];
				pworker->m_arrMyDevs[j]   = pworker->m_arrMyDevs[i] ;
				pworker->m_arrMyDevs[i]   = pTmp ;
			}
		}
	}
}

void GenSendData2LoginSrv(GVAPWorker* pworker)
{
	if (pworker->m_sLoginSock == -1)
		return ;

	char *pLogoutBuf = pworker->m_ProtocolPacket->getBuffer() ;
	int   nBufLen    = pworker->m_ProtocolPacket->getDataLen() ;

	ForceSend(pworker->m_sLoginSock,pLogoutBuf,nBufLen,5000,0,NULL) ;
	
	
	static int nSend = 0 ;
	pworker->m_ProtocolPacket->reset() ;
}

int RecvDataAndProcess(GVAPWorker* pworker)
{
	int nSocket = pworker->m_sLoginSock ;
	if(nSocket == -1)
		return 0;

	if(WaitSocketData(nSocket,10000,1) != 1)
	{
		return 1;//�����ݵ���
	}

	int  nBufLen = 0;
	char szBufLen[20] = {0};
	if (4 == ForceRecv(nSocket,szBufLen,4,5000,0,NULL))
	{
		sscanf(szBufLen,"%x",&nBufLen);		
		if(nBufLen > 0)
		{
			char *pszBuf = (char *)malloc(nBufLen+1);
			if(pszBuf != NULL)
			{
				SetRecvSendBufferSize(nSocket,nBufLen);
				if (ForceRecv(nSocket,pszBuf,nBufLen,15000,0,NULL) == nBufLen)
				{
					pszBuf[nBufLen] = 0 ;
					DoDealWithAck(pworker,pszBuf,nBufLen) ;
					free(pszBuf) ;
					return 1;
				}
				free(pszBuf) ;
			}
		}
	}

	StopSocket(pworker->m_sLoginSock);
	pworker->m_sLoginSock = -1;
	if(!pworker->m_binitiativelogout)
		SendNotifyMsg(pworker,NOTIFY_DISCONNECTION,0);

	return 0;
}

// type: 0:Public(default), 1:My, 2:Local
DeviceInfo *GetDevInfoByID(GVAPWorker *pworker,const char* lpszDevID,int bGetDevType)
{
	int i = 0 ;
	int nSize = 0 ;
//	if(lpszDevID == NULL || strlen(lpszDevID) == 0)
//		return NULL ;

	switch(bGetDevType)
	{
	case 0:
	{
		nSize = pworker->m_pubdevcounts ;
		for(i=0; i<nSize; i++)
		{
			DeviceInfo *pInfo = pworker->m_arrPubDevs[i] ;
			if(strcmp(pInfo->szDevID,lpszDevID) == 0)
			{
				return pInfo ;
			}
		}
	}
	break;
	
	case 1:
	{
		nSize = pworker->m_mydevcounts ;
		for(i=0; i<nSize; i++)
		{
			DeviceInfo *pInfo = pworker->m_arrMyDevs[i] ;
			if(strcmp(pInfo->szDevID,lpszDevID) == 0)
			{
				return pInfo ;
			}
		}
	}
	break;

	case 2:
		{
			nSize = pworker->m_locdevcounts ;
			for(i=0; i<nSize; i++)
			{
				DeviceInfo *pInfo = pworker->m_arrLocDevs[i] ;
				if(strcmp(pInfo->szDevID,lpszDevID) == 0)
				{
					return pInfo ;
				}
			}
		}
		break;
	}

	return NULL ;
}


void  GetGroupSub(GVAPWorker *pworker,char *pszGroupID)
{
	//s_dwLastGroupID = atoi(pszGroupID) ;

	SetHeaderCmd(pworker,"get","dev-list",0,1);
	AddHeaderSection(pworker,"group-id",pszGroupID);

	char szCSEQ[32]={0} ;
	sprintf(szCSEQ,"%d [%s]",GET_DEVLIST,pszGroupID) ;
	AddHeaderSection(pworker,"cseq",szCSEQ);

	GenSendData2LoginSrv(pworker) ;
}

GroupType* FindGroupTypeByParentID(GVAPWorker* pworker,int parentid)
{
	int nIndex = 0;
	for ( int i = 0; i < pworker->m_grouptypecount; i++)
	{
		if (parentid == pworker->m_parentid[i])
		{
			break;
		}
	}
	return pworker->m_arrGroupList[nIndex];
}

void SendCmd2LoginSrv(GVAPWorker* pworker,int dwSendType, int dwGetType, const char* lpAddValue)
{
	if(pworker->m_bInLogin)
	{
		static const char *pszGetRes[]=
		{
			"versions",
			"pub-list",		// 1
			"dev-list",		// 2 ��Ӧ���ҵ��б�
			"dev-info",		// 3
			"usr-info",		// 4
			"dev-status",	// 5
			"dev-auth"
		};

		if (dwSendType > 6)
			return;

		char szCSEQ[32]={0} ;

		if(GET_MYTYPE == dwGetType)
		{
			int i=0; 

			int nIndex=0 ;
			int nCount = pworker->m_mydevcounts;

			for(i=0; i<nCount; i++)
			{
				DeviceInfo *pInfo = pworker->m_arrMyDevs[i];
				if(GET_DEVSTATUS == dwSendType && pInfo->bIsGroup)
					continue;

				if(nIndex==0)
					SetHeaderCmd(pworker,"get",pszGetRes[dwSendType],0,1);

				if(pworker->m_arrMyDevs[i]->bIsGroup)
					AddHeaderSection(pworker,"group-id",pInfo->szDevID);
				else
					AddHeaderSection(pworker,"device-id",pInfo->szDevID);

				nIndex ++ ;

				if(nIndex >= 50 || i == nCount-1)
				{
					nIndex = 0 ;
					sprintf(szCSEQ,"%d [%s]",dwSendType,pszGetRes[dwSendType]) ;
					AddHeaderSection(pworker,"cseq",szCSEQ);
					GenSendData2LoginSrv(pworker) ;
				}
			}

			return ;
		}

		SetHeaderCmd(pworker,"get",pszGetRes[dwSendType],0,1);
		
		switch(dwSendType)
		{
		case GET_VRESIONS:
			{
			}
			break;

		case GET_DEVSTATUS:
		case GET_DEVINFO:
			if(lpAddValue != NULL)
			{
				AddHeaderSection(pworker,"device-id",lpAddValue);
			}
			else
			{
				int i=0; 

				if (dwGetType == GET_PUBTYPE)
				{
					for(i=0; i<pworker->m_pubdevcounts; i++)
					{
						AddHeaderSection(pworker,"device-id",pworker->m_arrPubDevs[i]->szDevID);
					}
				}
			}
			break ;

		case GET_USRINFO:
			if(lpAddValue != NULL)
			{
				AddHeaderSection(pworker,"user-id",lpAddValue);
			}
			break ;
		}
		
		if (dwSendType == 2)
		{	
			sprintf(szCSEQ,"%d [%d]",dwSendType, 0) ;
			RemoveMyGroupList(pworker);	
			GroupType* temp = (GroupType*) calloc(1, sizeof(GroupType));
			temp->dwGroupID = 0;
			temp->dwCountIndex = 0;
			temp->dwCountTotal = 0;
			temp->dwPageTotal = 0;
			temp->dwPageIndex = 0;
			pworker->m_arrGroupList[0] =temp;
			pworker->m_grouptypecount = 1;
		}
		else
			sprintf(szCSEQ,"%d [%s]",dwSendType,pszGetRes[dwSendType]) ;
		AddHeaderSection(pworker,"cseq",szCSEQ);

		GenSendData2LoginSrv(pworker) ;
	}
}

void Cleanup(GVAPWorker* pworker)
{	
	StopSocket(pworker->m_sLoginSock);

	int i=0; 

	int nCount = pworker->m_pubdevcounts;
	for (i=0; i<nCount; i++)
	{
		DeviceInfo *pTemp = pworker->m_arrPubDevs[i];
		if (pTemp != NULL)
		{	
			free(pTemp);
			pTemp = NULL;
		}
		pworker->m_arrPubDevs[i] = NULL;
	}
	
	nCount = pworker->m_mydevcounts;
	for (i=0; i<nCount; i++)
	{
		DeviceInfo *pTemp = pworker->m_arrMyDevs[i];
		if (pTemp != NULL)
		{	
			free(pTemp);
			pTemp = NULL;
		}
		pworker->m_arrMyDevs[i] = NULL;
	}	
	
	RemoveMyGroupList(pworker);
}

// ��������ʧ�ܻ��ǳ���ʱ��������
void DoLogout(GVAPWorker* pworker)
{
	if(pworker->m_bInLogin)
	{
		pworker->m_binitiativelogout = 1;
		SetHeaderCmd(pworker,"Logout","usr",1,1);
		GenSendData2LoginSrv(pworker) ;
		pworker->m_bInLogin = 0 ;

		Cleanup(pworker);
		//SendNotifyMsg(NOTIFY_LOGOUT) ;
		memset(pworker->m_szUsername,0,sizeof(pworker->m_szUsername));
		memset(pworker->m_szPassword,0,sizeof(pworker->m_szPassword));
	}
}

void SetUserName(GVAPWorker* pworker,const char* lpszUsername,const char* lpszPassword)
{
	strcpy(pworker->m_szUsername,lpszUsername) ;
	strcpy(pworker->m_szPassword,lpszPassword) ;
}


int TalktoRegSrv(GVAPWorker* pworker)
{
	char *pszBuf = pworker->m_ProtocolPacket->getBuffer()  ;
	int  nBufLen = pworker->m_ProtocolPacket->getDataLen() ;

	int dwCode = 0 ;
	if (nBufLen > 0)
	{
		int nLen = 0;
		char szBufLen[100] ={0};
		pworker->m_szStatusDesc[0]=0;
		
		int nSocket = QuickConnectToTCP(pworker->m_wPortRegister,pworker->m_szIPRegisterSvr,2000) ;
		if(nSocket != -1)
		{
			ForceSend(nSocket,pszBuf,nBufLen,MAX_QS_TIMEOUT,0,NULL) ;
			ForceRecv(nSocket,szBufLen,4,5000,0,NULL);
			sscanf(szBufLen,"%x",&nLen);
			if(nLen > 0)
			{
				char *pszRecvBuf = (char*)malloc(nLen+1);
				if (nLen == ForceRecv(nSocket,pszRecvBuf,nLen,5000,0,NULL))
				{
					pszRecvBuf[nLen] = 0 ;
 					CGVAPPackageParser  Parser  ;
 					Parser.parse(pszRecvBuf,nLen);
 					dwCode = Parser.getStatusCode() ;
 					int nDescLen = 0 ;
 					char *pszError = NULL;
 					Parser.getStatusDescription(&pszError,nDescLen);
 					strncpy(pworker->m_szStatusDesc,pszError,nDescLen);
 					pworker->m_szStatusDesc[nDescLen]=0 ;
				}
				
				free(pszRecvBuf) ;
			}
			StopSocket(nSocket) ;
		}
	}

	pworker->m_ProtocolPacket->reset() ;
	pworker->m_errcode = dwCode;
	return dwCode == 200;
}

// ������(Э����׼ȷ�Ľз�Ӧ��Ϊ��)
void AddHeaderSection(GVAPWorker* pworker,const char* lpszName,const char* lpszValue)
{
	pworker->m_ProtocolPacket->addSection((char *)lpszName,strlen(lpszName),(char *)lpszValue,strlen(lpszValue));
}

// Ĭ��������,nTypeΪ2��ʾ��Ӧ
void SetHeaderCmd(GVAPWorker* pworker,const char* lpCmd,const char* lpResourceName,int bAutoAddUsername,int nType)
{
	char szHeader[1024]={0} ;
	sprintf(szHeader,"%s %s",lpCmd,lpResourceName) ;

	pworker->m_ProtocolPacket->reset() ;
	pworker->m_ProtocolPacket->setHeader(szHeader,nType);

	if(bAutoAddUsername)
	{
		AddHeaderSection(pworker,"username",pworker->m_szUsername);
		AddHeaderSection(pworker,"password",pworker->m_szPassword);
	}
}

int DoUserModify(GVAPWorker* pworker,const char* lpszUsername,const char* lpszPassword,const char* lpszNickname,const char* lpszNewPwd)
{
	SetHeaderCmd(pworker,"modify_user","reg-s",0,1) ;
	AddHeaderSection(pworker,"username",lpszUsername);
	AddHeaderSection(pworker,"password",lpszPassword);

	AddHeaderSection(pworker,"nickname_new",lpszNickname);
// 	char *pszTemp = EncodeToUTF8(lpszNickname);
// 	if(!IsEmptyStr(pszTemp))
// 	{
// 		AddHeaderSection(pworker,"nickname_new",pszTemp);
// 		free(pszTemp);
// 	}

	if(!IsEmptyStr(lpszNewPwd) )
		AddHeaderSection(pworker,"password_new",lpszNewPwd);

	int bDoOK = TalktoRegSrv(pworker);
	if(bDoOK && lpszNewPwd != NULL && strlen(lpszNewPwd))
	{
		SetUserName(pworker,lpszUsername,lpszNewPwd) ;
	}
	return bDoOK ;
}

int DoUserRegister(GVAPWorker* pworker,const char* lpszUsername,const char* lpszPassword,const char* lpszNickname) 
{
	SetHeaderCmd(pworker,"register_user","reg-s",0,1) ;
	AddHeaderSection(pworker,"username",lpszUsername);
	AddHeaderSection(pworker,"password",lpszPassword);

	AddHeaderSection(pworker,"nickname",lpszNickname);
// 	char *pszTemp = EncodeToUTF8(lpszNickname);
// 	if(pszTemp != NULL)
// 	{
// 		AddHeaderSection(pworker,"nickname",pszTemp);
// 		free(pszTemp);
// 	}

	if(TalktoRegSrv(pworker))
		return ECODE_OK;
	else
		return ErrorCode(pworker);
}

int DoUserUnRegister(GVAPWorker* pworker,const char* lpszUsername,const char* lpszPassword) 
{
	SetHeaderCmd(pworker,"unregister_user","reg-s",0,1) ;
	AddHeaderSection(pworker,"username",lpszUsername);
	AddHeaderSection(pworker,"password",lpszPassword);
	return TalktoRegSrv(pworker) ;
}

int DoDevRegister(GVAPWorker*pworker,const char* lpszDevID,const char* lpszDevName,int nType,const char* lpszHversion, const char* lpszSversion,  const char* lpszDataserver)
{
	char szValue[512]={0} ;
	SetHeaderCmd(pworker,"register_device","reg-s",0,1);
	AddHeaderSection(pworker,"hid",lpszDevID);

	AddHeaderSection(pworker,"name",lpszDevName);

	sprintf(szValue,"%d",nType);
	AddHeaderSection(pworker,"type",szValue);
	return TalktoRegSrv(pworker) ;
}

int DoDevUnRegister(GVAPWorker* pworker,const char* lpszDevID)
{	
	SetHeaderCmd(pworker,"unregister_device","reg-s",0,1) ;
	AddHeaderSection(pworker,"hid",lpszDevID);
	return TalktoRegSrv(pworker) ;
}

int DoDevQuery(GVAPWorker* pworker,const char* lpszDevID)
{
	SetHeaderCmd(pworker,"query_device","reg-s",0,1) ;
	AddHeaderSection(pworker,"hid",lpszDevID);
	return TalktoRegSrv(pworker) ;
}

int DoDevModify(GVAPWorker* pworker,const char* lpszDevID,const char* lpszDevName,int nType,const char* lpszHversion, const char* lpszSversion,  const char* lpszDataserver) 
{
	char szValue[512]={0} ;
	SetHeaderCmd(pworker,"modify_device","reg-s", 1,1) ;
	AddHeaderSection(pworker,"hid",lpszDevID);

	AddHeaderSection(pworker,"name",lpszDevName);
// 	char *pszTemp = EncodeToUTF8(lpszDevName);
// 	if(pszTemp != NULL)
// 	{
// 		AddHeaderSection(pworker,"name",pszTemp);
// 		free(pszTemp);
// 	}
	sprintf(szValue,"%d",nType);
	AddHeaderSection(pworker,"type",szValue);
	int bDone = TalktoRegSrv(pworker) ;
	if(bDone)
	{
		SendCmd2LoginSrv(pworker,GET_DEVINFO, GET_MYTYPE,NULL) ;
		SendCmd2LoginSrv(pworker,GET_DEVSTATUS, GET_MYTYPE,NULL);	
	}
	return bDone ;
}

int DoDevBind(GVAPWorker* pworker,const char* lpszDevID,const char* lpszOldUserName,const char* lpszOldPassword)
{
	if (!pworker->m_bInLogin)
	{
		return ECODE_NOT_LOGIN;
	}

	if(lpszOldUserName == NULL)
		SetHeaderCmd(pworker,"bind","reg-s",1,1) ;
	else
		SetHeaderCmd(pworker,"bind","reg-s",0,1) ;

	if (lpszOldUserName != NULL)
	{
		AddHeaderSection(pworker,"username",lpszOldUserName);
		AddHeaderSection(pworker,"password",lpszOldPassword);
	}

	AddHeaderSection(pworker,"hid",lpszDevID);
	int bDone = TalktoRegSrv(pworker) ;
	if (bDone)
	{
		// send bind-ccount info to dev the update the info to ui
		//CamNetParam *pInfo = GetDevInfoBySerial(lpszDevID);
		//if (pInfo != NULL)
		//{
		//	pInfo->nCmd = 0x77 ;							// 0x66 GosGet
		//	strcpy(pInfo->szBindAccont,m_szUsername) ;
		//	strcpy(pInfo->szPacketFlag,"GosSetInfo") ;
		//	QuickSendToUDP(s_wPortDeviceSet,(char *)pInfo,sizeof(CamNetParam),0) ;
		//}

		pworker->m_bManuRMyList = 1;
		SendCmd2LoginSrv(pworker,GET_DEVLIST,0,NULL);
		return ECODE_OK;
	}
	else
	{
		return ErrorCode(pworker);
	}
}

int DoDevUnBind(GVAPWorker* pworker,const char* lpszDevID,const char* lpszOldUserName,const char* lpszOldPassword)
{	
	if(lpszOldUserName == NULL)
		SetHeaderCmd(pworker,"unbind","reg-s",1,1) ;
	else
		SetHeaderCmd(pworker,"unbind","reg-s",0,1) ;

	if(lpszOldUserName != NULL)
	{
		AddHeaderSection(pworker,"username",lpszOldUserName);
		AddHeaderSection(pworker,"password",lpszOldPassword);
	}

	AddHeaderSection(pworker,"hid",lpszDevID);
	int bDone = TalktoRegSrv(pworker) ;
	if(bDone)
	{
		//CamNetParam *pInfo = GetDevInfoBySerial(lpszDevID);
		//if(pInfo != NULL)
		//{
		//	pInfo->nCmd = 0x77 ;						// 0x77 ����
		//	memset(pInfo->szBindAccont,0,48) ;
		//	strcpy(pInfo->szPacketFlag,"GosSetInfo") ;
		//	QuickSendToUDP(s_wPortDeviceSet,(char *)pInfo,sizeof(CamNetParam),0) ;
		//}
		
		pworker->m_bManuRMyList = 1;
		RemoveMyList(pworker,(char*)lpszDevID);
		SendCmd2LoginSrv(pworker,GET_DEVLIST,0,NULL);
		return ECODE_OK;
	}
	else
	{
		return ErrorCode(pworker) ;
	}
}

void DoDealWithAck_Status(GVAPWorker* pworker,const char* lpRecvBuf,int dwBufLen)
{
	if(dwBufLen == 0)
		return ;

	int nCntLen  = CGVAPPackageParser::getContentLength((char *)lpRecvBuf,dwBufLen);
	if (nCntLen > 0)
	{
		char *pszCntBuf = (char *)malloc(nCntLen+1) ;
		if (pszCntBuf != NULL && nCntLen == ForceRecv(pworker->m_sLoginSock,pszCntBuf,nCntLen,5000,0,NULL))
		{
			pszCntBuf[nCntLen] = 0 ;

			TiXmlDocument AX ;
			AX.Parse(pszCntBuf) ;
			TiXmlHandle	xmlFile(&AX);

			int nRetCSEQ = pworker->m_GenParser->getIntegerSectionWithDefault("cseq",0);
			switch(nRetCSEQ)
			{
			case GET_DEVINFO:
				{
					TiXmlElement *pElement = xmlFile.FirstChildElement("dev-info").Element();
					if(pElement != NULL)
					{
						int nCount = atoi(pElement->Attribute("count"));

						TiXmlElement *pItem = pElement->FirstChildElement("group") ;
						while(pItem != NULL)
						{
							const char* lpszID = pItem->Attribute("id");
							DeviceInfo *pInfo2 = GetDevInfoByID(pworker,lpszID,1) ;		// M
							const char *pName =  pItem->Attribute("name") ;
// 							char *pName =  DecodeFromUTF8(pItem->Attribute("name")) ;

							if(pInfo2 != NULL)
							{
								if(pName != NULL)
									strcpy(pInfo2->szDevName,pName);
								const char* lpszGroup = pItem->Attribute("parent") ;
								if(lpszGroup != NULL)
									pInfo2->dwParentID = atoi(lpszGroup);
							}

// 							if(pName != NULL)
// 							{
// 								free(pName) ;
// 							}

							pItem = pItem->NextSiblingElement() ;
						}
						pItem = pElement->FirstChildElement("dev") ;

						while(pItem != NULL)
						{
							const char* lpszID = pItem->Attribute("id");

							DeviceInfo *pInfo1 = GetDevInfoByID(pworker,lpszID,0) ;		// pub
							DeviceInfo *pInfo2 = GetDevInfoByID(pworker,lpszID,1) ;		// M
							TiXmlElement *pEle = pItem->FirstChildElement("name");

							const char *pName = NULL ;
							const char* lpszType  = NULL ;
							const char* lpszHWVer = NULL ;
							const char* lpszSWVer = NULL ;
							const char* lpszGroup = NULL ;
							const char* lpszTips  = NULL ;

  							if(pEle != NULL)
								pName =  pEle->GetText() ;
// 							if(pEle != NULL)
// 								pName =  DecodeFromUTF8(pEle->GetText()) ;
						
							pEle = pItem->FirstChildElement("type");
							if(pEle != NULL)
								lpszType  = pEle->GetText();
							
							pEle = pItem->FirstChildElement("hversion");
							if(pEle != NULL)
								lpszHWVer = pEle->GetText() ;
							
							pEle = pItem->FirstChildElement("sversion");
							if(pEle != NULL)
								lpszSWVer = pEle->GetText() ;

							pEle = pItem->FirstChildElement("group");
							if(pEle != NULL)
								lpszGroup = pEle->GetText() ;

							pEle = pItem->FirstChildElement("tips");
							if(pEle != NULL)
							{
								lpszTips = pEle->GetText() ;
// 								lpszTips = DecodeFromUTF8_S(lpszTips) ;
							}

							if(pInfo1 != NULL)
							{
								if(pName != NULL)
									strcpy(pInfo1->szDevName,pName);
								
// 								if(lpszType != NULL)
// 									pInfo1->bIsPBDevice = atoi(lpszType) ;

								if(lpszHWVer != NULL)
									strcpy(pInfo1->szHWVer,lpszHWVer) ;

								if(lpszSWVer != NULL)
									strcpy(pInfo1->szSWVer,lpszSWVer) ;

								if(lpszGroup != NULL)
									pInfo1->dwParentID = atoi(lpszGroup) ;

								if(lpszTips != NULL)
									strcpy(pInfo1->szKeyText,lpszTips) ;
							}

							if(pInfo2 != NULL)
							{
								pworker->m_dwGetInfosCount ++ ;
								if(pName != NULL)
									strcpy(pInfo2->szDevName,pName);
							
// 								if(lpszType != NULL)
// 									pInfo2->bIsPBDevice = atoi(lpszType) ;
								
								if(lpszHWVer != NULL)
									strcpy(pInfo2->szHWVer,lpszHWVer) ;

								if(lpszSWVer != NULL)
									strcpy(pInfo2->szSWVer,lpszSWVer) ;

								if(lpszGroup != NULL)
									pInfo2->dwParentID = atoi(lpszGroup) ;

								if(lpszTips != NULL)
									strcpy(pInfo2->szKeyText,lpszTips) ;
							}

// 							if(pName != NULL)
// 							{
// 								free(pName) ;
// 							}

							pItem = pItem->NextSiblingElement() ;
						}
					}

				}
				break;

			case GET_DEVSTATUS:
				{
					TiXmlElement *pElement = xmlFile.FirstChildElement("dev-status").Element();
					if (pElement != NULL)
					{
						TiXmlElement *pItem = pElement->FirstChildElement("dev") ;
						while(pItem != NULL)
						{
							const char* lpszID     = pItem->Attribute("id");
							const char* lpszStatus = pItem->Attribute("status");
							const char* lpszURL    = pItem->Attribute("url");


							DeviceInfo *pInfo1 = GetDevInfoByID(pworker,lpszID,0) ;		// pub device
							DeviceInfo *pInfo2 = GetDevInfoByID(pworker,lpszID,1) ;		// my device
							if(pInfo1 != NULL)
							{
								if(lpszURL != NULL)
									strcpy(pInfo1->szDataURL,lpszURL) ;

								pInfo1->dwStatus = atoi(lpszStatus) ;
								if (pInfo1->dwStatus > 2)
									pInfo1->dwStatus = 0 ;
							}

							if(pInfo2 != NULL)
							{
								pInfo2->dwStatus = atoi(lpszStatus) ;

								if(lpszURL != NULL)
									strcpy(pInfo2->szDataURL,lpszURL) ;

								if (pInfo2->dwStatus > 2)
									pInfo2->dwStatus = 0 ;
							}
							pItem = pItem->NextSiblingElement() ;
						}


						if(pworker->m_dwGetStatusCount >= pworker->m_mydevcounts)
						{
							SortDevsStatus(pworker) ;
							SendNotifyMsg(pworker,NOTIFY_DEVSTATUS,0) ;
						}
					}
				}
				break ;

			case GET_USRINFO:
				{
// 					TiXmlElement *pElement = xmlFile.FirstChildElement("usr-info").Element();
// 					if(pElement != NULL)
// 					{
// 						int nCount = atoi(pElement->Attribute("count"));
// 
// 						TiXmlElement *pItem = pElement->FirstChildElement("usr") ;
// 						while(pItem != NULL)
// 						{
// 							const char* lpszID = pItem->Attribute("usrname");
// 						
// 							int nSize = m_arrUsers.size() ;
// 							for(int i=0; i<nSize; i++)
// 							{
// 								UserInfo *pInfo = m_arrUsers[i] ;
// 								if (stricmp(pInfo->szUserName,lpszID) == 0)
// 								{
// 									TiXmlElement *pEle; 
// 									pEle = pItem->FirstChildElement("name");
// 									if (pEle)
// 									{
// 										char *pName = DecodeFromUTF8(pEle->GetText()) ;
// 										if (pName)
// 										{
// 											strcpy(pInfo->szNickName,pName);
// 											free(pName) ;
// 										}
// 									}
// 		
// 									pEle = pItem->FirstChildElement("type");
// 									if (pEle)
// 									{
// 										const char* strType = pEle->GetText();
// 										pInfo->nType = atoi(strType);
// 									}
// 									break;
// 								}
// 							}
// 
// 							pItem = pItem->NextSiblingElement() ;
// 						}
// 					}
				}
				break ;

			default:
				break;
			}

			free(pszCntBuf) ;
		}
	}
}


static int   s_bGetGroupInRunning = 0 ;
static DeviceInfo* s_arrSubGroups[MAX_GROUP_COUNT] = {0};
int s_subgroupcounts = 0;

static THREADRETURN ThreadGetGroupSub(void *pvoid) 
{
	GVAPWorker* pworker = (GVAPWorker*)pvoid;
	if (pworker)
	{
		s_bGetGroupInRunning = 1 ;
		while(1)
		{
			int nSize = s_subgroupcounts ;
			if(nSize>0)
			{
				GetGroupSub(pworker,s_arrSubGroups[0]->szDevID) ;
				DeviceInfo* temp = s_arrSubGroups[0];
				free(temp);
				temp = NULL;
				s_arrSubGroups[0] = NULL;
				s_subgroupcounts--;
				for(int i = 0; i < s_subgroupcounts; i++)
				{
					s_arrSubGroups[i] = s_arrSubGroups[i+1];
				}
			}

			if (!g_bStartGetGroupEvent)
			{
#ifdef _WIN32
				Sleep(3000);
#else
				sleep(3);
#endif

				GetDevInfos(pworker) ;

				break;
			}
			else
			{
				g_bStartGetGroupEvent = 0;
			}

			SendNotifyMsg(pworker,NOTIFY_DEVSTATUS,0) ;
		}
		s_bGetGroupInRunning = 0 ;
	}

	return THREADRETURNVALUE;
}

static int   s_bGetPageInRunning = 0 ;
static int    s_nGetPages  = 1 ;
static int    s_nPageIndex = 1 ;

static THREADRETURN ThreadGetPage(LPVOID lpParam) 
{
	s_bGetPageInRunning = 1 ;
	GVAPWorker *pW = (GVAPWorker *)lpParam ;

	while(1)
	{
		//if(s_nGetPages>s_nPageIndex)
		GroupType* ptemp = FindGroupTypeByParentID(pW,s_dwLastParentID);
		if (ptemp != NULL)
		{
			if (ptemp->dwPageTotal> ptemp->dwPageIndex)
			{
				char szGroup[100]= {0} ;
				char szPages[100]= {0} ;
				char szCSEQ[32]  = {0} ;

				//sprintf(szGroup,"%d",s_dwLastGroupID) ;
				sprintf(szGroup,"%d",s_dwLastParentID) ;
				SetHeaderCmd(pW,"get","dev-list",0,1);
				AddHeaderSection(pW,"group-id",szGroup);

				//sprintf(szPages,"%d",s_nPageIndex) ;
				sprintf(szPages,"%d", ptemp->dwPageIndex) ;
				AddHeaderSection(pW,"page",szPages) ;

				sprintf(szCSEQ,"%d [%s] ",GET_DEVLIST,szGroup) ;
				AddHeaderSection(pW,"cseq",szCSEQ);

				GenSendData2LoginSrv(pW) ;
				//s_nPageIndex ++ ;
				ptemp->dwPageIndex++;
			}
		}
		int nCount = 0;
		while (1)
		{

			if (g_bStartGetGroupEvent)
			{
				break;
			}
			else
			{
#ifdef _WIN32
				Sleep(1000);
#else
				sleep(1);
#endif
			}
			if (nCount++ > 75*60)
			{
				break;
			}
		}
	}
	return THREADRETURNVALUE;
}

static THREADRETURN ThreadGetInfo(void* lpParam) 
{
	GVAPWorker *pW = (GVAPWorker *)lpParam ;

	int i=0; 
	int nIndex = 0 ;
	int nCount = pW->m_mydevcounts;

	for(i=0; i<nCount; i++)
	{
		DeviceInfo *pInfo = pW->m_arrMyDevs[i];

		if(nIndex==0)
			SetHeaderCmd(pW,"get","dev-info",0,1);

		if(pInfo->bIsGroup)
			AddHeaderSection(pW,"group-id",pInfo->szDevID);
		else
			AddHeaderSection(pW	,"device-id",pInfo->szDevID);

		nIndex ++ ;

		if(nIndex >= 50 || i == nCount-1)
		{
			nIndex = 0 ;
			char szCSEQ[32]={0} ;
			sprintf(szCSEQ,"%d [dev-info]",GET_DEVINFO) ;
			AddHeaderSection(pW,"cseq",szCSEQ);
			GenSendData2LoginSrv(pW) ;
		}
	}
	GetDevStatus(pW) ;
	return THREADRETURNVALUE;
}

void GetDevInfos(GVAPWorker* pworker)
{
	pworker->m_dwGetInfosCount = 0 ;
	thread_create_normal(ThreadGetInfo,pworker);	
}

static THREADRETURN ThreadGetStatus(LPVOID lpParam) 
{
	GVAPWorker *pW = (GVAPWorker *)lpParam ;	

	int i = 0; 
	int nIndex = 0 ;
	int nCount = pW->m_mydevcounts;

	for(i=0; i<nCount; i++)
	{
		DeviceInfo *pInfo = pW->m_arrMyDevs[i];

		if(nIndex==0)
			SetHeaderCmd(pW,"get","dev-status",0,1);

		pW->m_dwGetStatusCount ++ ;

		if(!pInfo->bIsGroup)
			AddHeaderSection(pW,"device-id",pInfo->szDevID);

		nIndex ++ ;

		if(nIndex >= 50 || i == nCount-1)
		{
			nIndex = 0 ;
			char szCSEQ[32]={0} ;
			sprintf(szCSEQ,"%d",GET_DEVSTATUS) ;
			AddHeaderSection(pW,"cseq",szCSEQ);
			GenSendData2LoginSrv(pW) ;
		}
	}
	return THREADRETURNVALUE;
}

void  GetDevStatus(GVAPWorker* pworker)
{
	pworker->m_dwGetStatusCount =0 ;
	thread_create_normal(&ThreadGetStatus,pworker);
}

void DoDealWithAck_List(GVAPWorker* pworker)
{
	int nRetCSEQ = pworker->m_GenParser->getIntegerSectionWithDefault("cseq",0);
	switch(nRetCSEQ)
	{
	case GET_VRESIONS:
		if (pworker->m_iPubVersion == 0 || pworker->m_iMyVersion == 0)
		{	
			pworker->m_iPubVersion    = pworker->m_GenParser->getIntegerSectionWithDefault("pub-version",0);
			pworker->m_iPubCurVersion = pworker->m_iPubVersion;

			pworker->m_iMyVersion     = pworker->m_GenParser->getIntegerSectionWithDefault("dev-version",0);
			pworker->m_iMyCurVersion  = pworker->m_iMyVersion;
		}
		break;

	case GET_PBDEVLIST:
	case GET_DEVLIST:
		{
			int   nNameLen  = 0 ;
			int   nValueLen = 0 ;
			char *pszValue  =NULL;
			char *pszSecName=NULL;
			char  szTmpDevID[256]={0};
			char  szTmpName[256] ={0};

			int i = 0;
			int nCount = 0 ;
			int nTotal = 0 ;
			int nPages = 0 ;
			char *pszCSEQ = NULL;
			int nParentId = 0;
			int nSeq = 0;
			if(pworker->m_GenParser->getSectionByName("cseq",&pszValue,nValueLen)>0)
			{
				sscanf(pszValue,"%d [%d]",&nSeq, &nParentId) ;
			}
		
			while(pworker->m_GenParser->getNextSection(&pszSecName,nNameLen,&pszValue,nValueLen))
			{
				strncpy(szTmpDevID,pszValue,nValueLen);
				szTmpDevID[nValueLen]=0 ;

				strncpy(szTmpName,pszSecName,nNameLen);
				szTmpName[nNameLen]=0 ;

#ifdef WIN32
				if(strnicmp("total",pszSecName,nNameLen) == 0)
#else
				if(strncasecmp("total",pszSecName,nNameLen) == 0)
#endif
				{
					nTotal = atoi(szTmpDevID);
					if (nTotal>1000)
					{
						printf("hello");
					}
					
					GroupType* ptempgtype = FindGroupTypeByParentID(pworker,nParentId);

					if (ptempgtype != NULL)
					{
						ptempgtype->dwCountTotal =nTotal;
						ptempgtype->dwPageTotal = nTotal/100+1;
						ptempgtype->dwPageIndex = 1;
					}
					
					if(nTotal%100)
						nPages++;
					else
						nPages = nTotal/100 + 1 ;

					pworker->m_dwTotalDevs = nTotal ;
					pworker->m_dwCountDevs = 0 ;
					s_nGetPages   = nPages ;
					s_nPageIndex  = 1 ;
				}

#ifdef WIN32
				int bIsGroup = strnicmp("group-id",pszSecName,nNameLen)  == 0 ;
				int bIsDev   = strnicmp("device-id",pszSecName,nNameLen) == 0 ;
#else
				int bIsGroup = strncasecmp("group-id",pszSecName,nNameLen)  == 0 ;
				int bIsDev   = strncasecmp("device-id",pszSecName,nNameLen) == 0 ;
#endif				
				if(bIsDev || bIsGroup)
				{
					int bToAdd = 1 ;
					for(int i=0; i<pworker->m_mydevcounts; i++)
					{
						if(strcmp(pworker->m_arrMyDevs[i]->szDevID,szTmpDevID) == 0)
						{
							bToAdd = 0;
							break;
						}
					}

					if(!bToAdd)
						continue;

					DeviceInfo *pInfo = (DeviceInfo *)calloc(1,sizeof(DeviceInfo)); //GetDevInfoByID(szTmpDevID) ;
					if (pInfo != NULL)
					{
						strcpy(pInfo->szDevID,szTmpDevID);
						pInfo->bIsGroup    = bIsGroup ;
						//pInfo->dwParentID  = s_dwLastGroupID ;
						s_dwLastParentID     = nParentId;
						pInfo->dwParentID    = nParentId;
					
						if(bIsGroup)
						{
							pInfo->dwSelfID = atoi(szTmpDevID);	
							s_arrSubGroups[s_subgroupcounts++] = pInfo;
							GroupType * temp = (GroupType*)calloc(1, sizeof(GroupType));
							temp->dwGroupID = pInfo->dwSelfID;
							temp->dwCountIndex = 0;
							temp->dwCountTotal = 0;
							temp->dwPageTotal = 0;
							temp->dwPageIndex = 0;
							GroupType* ptempgtype = FindGroupTypeByParentID(pworker,pInfo->dwSelfID);
							if (ptempgtype != NULL)
							{
								pworker->m_arrGroupList[pInfo->dwSelfID] = temp;
							}
						}
					}

					if(nRetCSEQ == GET_PBDEVLIST)
					{
						pworker->m_arrPubDevs[pworker->m_pubdevcounts++] = pInfo;
					}
					else
					{
						 ;
						pworker->m_arrMyDevs[pworker->m_dwCountDevs ++] = pInfo;
						GroupType* ptempgtype = FindGroupTypeByParentID(pworker,pInfo->dwSelfID);
						if (ptempgtype != NULL)
						{
							pworker->m_arrGroupList[nParentId]->dwCountIndex++;
						}
					}
				}
			}

			if(nRetCSEQ == GET_PBDEVLIST)
			{
				SendCmd2LoginSrv(pworker,GET_DEVINFO, GET_PUBTYPE,NULL) ;
				SendCmd2LoginSrv(pworker,GET_DEVSTATUS, GET_PUBTYPE,NULL);
			}
			else
			{
				//if(m_dwCountDevs >= m_dwTotalDevs/*||m_bManuRMyList*/)/**/
				GroupType* ptempgp = FindGroupTypeByParentID(pworker,nParentId);
				if (ptempgp != NULL)
				{
					if (pworker->m_arrGroupList[nParentId]->dwCountIndex>=pworker->m_arrGroupList[nParentId]->dwCountTotal||pworker->m_bManuRMyList)
					{
						pworker->m_dwCountDevs = 0 ;
						pworker->m_dwTotalDevs = 0 ;

						if(!s_bGetGroupInRunning)
						{
							thread_create_normal(&ThreadGetGroupSub,pworker);
						}
						else
						{
							g_bStartGetGroupEvent = 1;
						}
						pworker->m_bManuRMyList = 0;
					}
					else
					{
						if(!s_bGetPageInRunning)
						{
							thread_create_normal(&ThreadGetPage,pworker);
						}
					}
				}
			}
//  			if(nRetCSEQ == GET_DEVLIST)
//  				SendNotifyMsg(NOTIFY_DEVLIST);
		}

		break;

	case GET_USRINFO:
	case GET_DEVSTATUS:
	case GET_DEVAUTH:
		break;

	default:
		break;
	}
}

// Ŀǰֻ���豸״̬��֪ͨ
// use the infos which come from server to update the dev status
int DoDealWithAck_Notify(GVAPWorker* pworker)
{
	int  nCmdLen = 0;
	char *pszCmd = NULL ;
	pworker->m_GenParser->getCommand(&pszCmd,nCmdLen) ;
	
#ifdef WIN32
	if(pszCmd && strnicmp("notify",pszCmd,6) == 0)
#else
	if(pszCmd && strncasecmp("notify",pszCmd,6) == 0)
#endif
	{
		int   nResLen  = 0 ;
		int   nDevIDLen= 0 ;
		int   nUserLen = 0 ;
		int   nURLLen  = 0 ;
		int   nAuthLen = 0 ;
		int	  nTitleLen = 0;
		int   nMessageLen = 0;

		int   nStatus  = 0 ;
		char *pszRes   = NULL ;
		char *pszDevID = NULL ;
		char *pszUser  = NULL ;
		char *pszURL   = NULL ;
		char *pszAuth  = NULL ;
		char *pszTitle = NULL;
		char *pszMessage = NULL;

		char  szResurce[256]={0} ;
		pworker->m_GenParser->getResourceName(&pszRes,nResLen);
		strncpy(szResurce,pszRes,nResLen);

		if ( strncmp(szResurce,"alarm", 5) == 0)
		{
			//do nothing
			return 1 ;
		}
		else
		{
			nStatus  = pworker->m_GenParser->getIntegerSectionWithDefault("status",0) ;
			pworker->m_GenParser->getSectionByName("device-id",&pszDevID,nDevIDLen);
			pworker->m_GenParser->getSectionByName("username",&pszUser,nUserLen);
			pworker->m_GenParser->getSectionByName("data-url",&pszURL,nURLLen);
			pworker->m_GenParser->getSectionByName("auth",&pszAuth,nAuthLen);
			
#ifdef WIN32
			if(stricmp("dev-status",szResurce)==0)
#else
			if(strcasecmp("dev-status",szResurce)==0)
#endif
			{
				char szDevID[256]={0};
				strncpy(szDevID,pszDevID,nDevIDLen);
				DeviceInfo *pInfo1 = GetDevInfoByID(pworker,szDevID,0) ;
				DeviceInfo *pInfo2 = GetDevInfoByID(pworker,szDevID,1) ;

				if(pInfo1 != NULL)
				{
					pInfo1->dwStatus = nStatus;
					strncpy(pInfo1->szDataURL,pszURL,nURLLen);
					SendNotifyMsg(pworker,NOTIFY_DEVSTATUS,(long)pInfo1) ;
				}
				
				if(pInfo2 != NULL)
				{
					pInfo2->dwStatus = nStatus;
					strncpy(pInfo2->szDataURL,pszURL,nURLLen);				
					SendNotifyMsg(pworker,NOTIFY_DEVSTATUS,(long)pInfo2) ;
				}			
			}
		}

		return 1;
	}

	return 0;
}

// ThreadDataRecv
int DoDealWithAck(GVAPWorker* pworker,const char* lpRecvBuf,int dwBufLen)
{
	if(dwBufLen == 0)
		return 0;
	
	pworker->m_GenParser->parse((char *)lpRecvBuf,dwBufLen) ;
	int nStatusCode = pworker->m_GenParser->getStatusCode();

	// first time	
	if (!pworker->m_bInLogin)
	{
		if (nStatusCode == 200)
		{
			pworker->m_bInLogin = 1;

			pworker->m_dwHeartBeatInterval = pworker->m_GenParser->getIntegerSectionWithDefault("expire",300);
			SendCmd2LoginSrv(pworker,GET_USRINFO,0,0);
			SendCmd2LoginSrv(pworker,GET_VRESIONS,0,0);
			SendCmd2LoginSrv(pworker,GET_PBDEVLIST,0,0);
			SendCmd2LoginSrv(pworker,GET_DEVLIST,0,0) ;

			SendCmd2LoginSrv(pworker,GET_DEVAUTH,0,0);

			SendNotifyMsg(pworker,NOTIFY_LOGIN,0);
		}
		else
		{
			SendNotifyMsg(pworker,NOTIFY_LOGIN,nStatusCode);
		}

		//s_dwLastGroupID = 0 ;

		return 1;
	}
	
	if (!DoDealWithAck_Notify(pworker))
	{
		DoDealWithAck_List(pworker);
		DoDealWithAck_Status(pworker,lpRecvBuf,dwBufLen);
	}

	return 1;
}


void StartLogin(GVAPWorker* pworker) 
{
	thread_create_normal(&ThreadLogin,pworker);
}

void RemoveMyList(GVAPWorker* pworker,char* strID)
{	
	for(int i = 0; i < pworker->m_mydevcounts; i++)
	{
		DeviceInfo *pTemp = pworker->m_arrMyDevs[i];
		if (pTemp != NULL && strcmp(strID,pTemp->szDevID) == 0)
		{
			free(pTemp);
			pTemp = NULL;
			pworker->m_arrMyDevs[i] = NULL;
			pworker->m_mydevcounts--;
			break;
		}
	}
}

void  RemoveMyGroupList(GVAPWorker* pworker)
{
	memset(pworker->m_parentid,0,sizeof(int)*MAX_GROUP_COUNT);
	GroupType *temp =NULL;
	for (int i = 0;i < pworker->m_grouptypecount; i++) 
	{	
		temp = pworker->m_arrGroupList[i];
		if (temp != NULL)
		{
			free(temp);
			temp = NULL;
		}
		pworker->m_arrGroupList[i] = NULL;
	}
	pworker->m_grouptypecount = 0;
}

int KeepAlive(GVAPWorker* pworker)
{
	if(pworker->m_sLoginSock == -1)
		return 0;
	CGVAPPackageBuilder HBPack ;
	HBPack.setHeader("HeartBeat user",1) ;
	
	if(ForceSend(pworker->m_sLoginSock,HBPack.getBuffer(),HBPack.getDataLen(),5000,0,NULL) >= 0)
		return 1;
	else
		return 0;
}

void SendNotifyMsg(GVAPWorker* pworker, int dwNotifyType, long dwRelData/*=0*/ )
{
	if (pworker->m_callback)
	{
		MESSAGETYPE dwType = UM_MSG_NOTIFY_UNKNOW;
		MESSAGESUBTYPE dwSubType = UM_SUBMSG_UNKNOW;
		int msgbodylen = 0;
		switch(dwNotifyType)
		{
		case NOTIFY_LOGIN:
			{
				dwType = UM_MSG_NOTIFY_LOGIN;
				if(dwRelData == 0)
				{
					dwSubType = UM_SUBMSG_LOGIN_OK;
				}
				else if (dwRelData == 2)
				{
					dwSubType = UM_SUBMSG_LOGIN_CONNECT_FAILED;
				}
				else if(dwRelData == 406)
				{
					dwSubType = UM_SUBMSG_LOGIN_INVALID_PASSWORD;
				}
				else if(dwRelData == 405)
				{
					dwSubType = UM_SUBMSG_LOGIN_INVALID_USER;
				}

				pworker->m_callback(dwType,dwSubType,NULL,msgbodylen);

			}
			break;
		case NOTIFY_LOGOUT:
			{
				dwType = UM_MSG_NOTIFY_LOGOUT;
			}
			break;
		case NOTIFY_USERDATA:
			{
			}
			break;
		case NOTIFY_USERSTATUS:
			{

			}
			break;
		case NOTIFY_DEVSTATUS:
			{
				dwType = UM_MSG_NOTIFY_DEVSTATUS;
				if (dwRelData == 0)
				{
					msgbodylen = 0;
					dwSubType = UM_SUBMSG_DEVSTATUS_ALL;
				}
				else
				{
					msgbodylen = sizeof(DeviceInfo);
					dwSubType = UM_SUBMSG_DEVSTATUS_ONE;
				}
				pworker->m_callback(dwType,dwSubType,(void*)dwRelData,msgbodylen);
			}
			break;
		case NOTIFY_ALARMINFO:
			{

			}
			break;
		case NOTIFY_DISCONNECTION:
			{
				dwType = UM_MSG_NOTIFY_DISCONNECTION;
				msgbodylen = 0;
				//���������˳����Żص�����Ϣ
				pworker->m_callback(dwType,dwSubType,NULL,msgbodylen);
			}
			break;
		case NOTIFY_DEVLIST:
			{
				dwType = UM_MSG_NOTIFY_DEVLIST;
				msgbodylen = 0;
				pworker->m_callback(dwType,dwSubType,NULL,msgbodylen);
			}
			break;
		}
	}
}

int ErrorCode(GVAPWorker* pworker)
{
	int rlt = ECODE_UNKNOW;

	if (pworker->m_errcode == 405)
	{
		rlt = ECODE_REGISTER_INVALID_USER;
	}
	else if (pworker->m_errcode == 409)
	{
		rlt = ECODE_REGISTER_USERNAME_IN_USE;
	}
	else if (pworker->m_errcode == 413)
	{
		rlt = ECODE_REGISTER_INVALID_EMAIL;
	}
	else if (pworker->m_errcode == 404)
	{
		rlt = ECODE_REQUEST_RESOURCE_NOT_FOUND;
	}
	else if (pworker->m_errcode == 400)
	{
		rlt = ECODE_BAD_REQUEST;
	}	
	else if (pworker->m_errcode == 500)
	{
		rlt = ECODE_INTERNAL_SERVER_ERROR;
	}	
	else if (pworker->m_errcode == 501)
	{
		rlt = ECODE_NOT_IMPLEMENTED;
	}	
	else if (pworker->m_errcode == 407)
	{
		rlt = ECODE_DEVICE_ID_NOT_FOUND;
	}	
	else if (pworker->m_errcode == 411)
	{
		rlt = ECODE_DEVICE_NOT_ONLINE;
	}	
	else if (pworker->m_errcode == 412)
	{
		rlt = ECODE_DEVICE_ALREADY_BIND;
	}	
	else
	{
		rlt = ECODE_UNKNOW;
	}

	return rlt;
}

////////////////////////////////////////////
GVAPWorker* GVAP_Create()
{
	GVAPWorker* pworker = (GVAPWorker*)malloc(sizeof(GVAPWorker));
	if(pworker == NULL)
		return NULL;
	
	memset(pworker,0,sizeof(GVAPWorker));
	pworker->m_bInland = 1;
	pworker->m_sLoginSock = -1 ;
	pworker->m_dwHeartBeatInterval  = 30 ;	// seconds
	pworker->m_GenParser = new CGVAPPackageParser();
	pworker->m_ProtocolPacket = new CGVAPPackageBuilder();
	pworker->m_thdatarecv = THREAD_HANDLENULL;
	LoadGVAPConfigure(pworker);
	StartUpSock();

	return pworker;
}

void GVAP_Destroy(GVAPWorker* pworker)
{
	if(pworker != NULL)
	{
		//clear somethings
		DoLogout(pworker);

		int nCount = pworker->m_locdevcounts;
		for (int i=0; i<nCount; i++)
		{
			DeviceInfo *pTemp = pworker->m_arrLocDevs[i];
			if (pTemp != NULL)
			{	
				free(pTemp);
				pTemp = NULL;
			}
			pworker->m_arrLocDevs[i] = NULL;
		}

		while (1)
		{
			if(pworker->m_thdatarecv == THREAD_HANDLENULL)
				break;
#ifdef WIN32
			Sleep(50);
#else
			usleep(1000*50);
#endif
		}

		delete pworker->m_GenParser;
		pworker->m_GenParser = NULL;
		delete pworker->m_ProtocolPacket;
		pworker->m_ProtocolPacket = NULL;

		free(pworker);
	}
}

void GVAP_SetCallback(GVAPWorker* pworker,UMMsgCallback callback)
{
	if(pworker != NULL)
	{
		pworker->m_callback = callback;
	}
}

int GVAP_Register(GVAPWorker* pworker,const char* username,const char* password,const char* evidenceaddr)
{
	return DoUserRegister(pworker,username,password,evidenceaddr);
}

int GVAP_Login(GVAPWorker* pworker,const char* username,const char* password)
{
	pworker->m_binitiativelogout = 0;
	SetUserName(pworker,username,password);
	StartLogin(pworker);
	return 0;

}

int GVAP_Verify(GVAPWorker* pworker,const char* authcode)
{
	return 0;
}

int GVAP_Logout(GVAPWorker* pworker)
{
	DoLogout(pworker);
	return 0;
}

int GVAP_BindDevice(GVAPWorker* pworker,const char* devid)
{
	return DoDevBind(pworker,devid,NULL,NULL);
}

int GVAP_UnBindDevice(GVAPWorker* pworker,const char* devid)
{
	return DoDevUnBind(pworker,devid,NULL,NULL);
}

int GVAP_GetDeviceListCounts(GVAPWorker* pworker)
{
	if(pworker)
		return pworker->m_mydevcounts;
	else
		return 0;
}

DeviceInfo* GVAP_GetDevice(GVAPWorker* pworker,int nIndex)
{
	if(pworker && nIndex >= 0 && nIndex < pworker->m_mydevcounts)
		return pworker->m_arrMyDevs[nIndex];
	else
		return NULL;
}

int GVAP_SetDeviceInfo( GVAPWorker* pworker,const char* devid,int cmd,void* param,int len )
{
	if(pworker)
	{
		char pParam[2048] = {0};
		if(BuildParams(cmd,param,len,pParam,sizeof(pParam)) == -1)
			return -1;

		SetHeaderCmd(pworker,"set","dev-info",0,1);
		AddHeaderSection(pworker	,"device-id",devid);
		//此处需要解析param，构建对应的param，传给设备
		AddHeaderSection(pworker	,"param",pParam);

		GenSendData2LoginSrv(pworker) ;
		return 0;
	}
	else
	{
		return -1;
	}
}

int BuildParams(int cmd,void* param,int len,char* pdst,int pdstlen)
{
	TlibFieldAx *pTlibfiled = NULL;
	pTlibfiled = Tlib_CreateFiled();
	if(pTlibfiled == NULL)
		return -1;
	Tlib_SetCommand(pTlibfiled,0x10);	//COMMAND_C_S_TRANSMIT_REQ

	switch(cmd)
	{
	case PCT_CMD_GET_VIDEO_LIST:
		{
			SSdcardRecQuery* temp = (SSdcardRecQuery*)param;

			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",gcmdGetDayEventList,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Date",temp->ptime,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait",(char*)"1",0,0);
		}
		break;
// 	case PCT_CMD_START_DOWNLOAD_VIDEO:
// 		{
// 			SSdcardRecDownload* temp = (SSdcardRecDownload*)param;
// 			
// 			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdDownloadEvent,0,0);
// 			Tlib_AddNewFiledVoid(pTlibfiled,"FileName",temp->filepath,0,0);
// 			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
// 		}
// 		break;
// 	case PCT_CMD_STOP_DOWNLOAD_VIDEO:
// 		{
// 			SSdcardRecDownload* temp = (SSdcardRecDownload*)param;
// 			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdStopDownloadEvent,0,0);
// 			Tlib_AddNewFiledVoid(pTlibfiled,"FileName",temp->filepath,0,0);
// 			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
// 		}
// 		break;
	case PCT_CMD_GET_IMAGE_COLOR:
		{
			SImageColor* temp = (SImageColor*)param;
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",gcmdGetImageColor,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait",(char*)"1",0,0);
		}
		break;
	case PCT_CMD_SET_IMAGE_COLOR:
		{
			SImageColor* temp = (SImageColor*)param;
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",gcmdSetImageColor,0,0);
			Tlib_AddNewFiledInt(pTlibfiled,"Brightness",temp->brightness,0,0);
			Tlib_AddNewFiledInt(pTlibfiled,"Contrast",temp->contrast,0,0);
			Tlib_AddNewFiledInt(pTlibfiled,"Saturation",temp->saturation,0,0);
			Tlib_AddNewFiledInt(pTlibfiled,"Hue",temp->hue,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait",(char*)"1",0,0);
		}
		break;
	case PCT_CMD_GET_RESOLUTION:
		{
			SResolution* temp = (SResolution*)param;
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",gcmdGetResolution,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait",(char*)"1",0,0);
		}
		break;
	case PCT_CMD_SET_RESOLUTION:
		{
			SResolution* temp = (SResolution*)param;
			char psend[1024] = {0};
			int count = 2;
			char pTemp[256] = {0};

			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",gcmdSetResolution,0,0);
#ifdef WIN32
			_snprintf(pTemp,256,"%d@",count);
#else
			snprintf(pTemp,256,"%d@",count);
#endif
			strcat(psend,pTemp);
			for (int i = 0; i < count; i++)
			{
				memset(pTemp,0,sizeof(pTemp));
				AVResolutionN tempRes = {0};
				if(i == 0)
				{
					memcpy(&tempRes,&(temp->major),sizeof(AVResolutionN));
				}
				else	if (i == 1)
				{
					memcpy(&tempRes,&(temp->minor),sizeof(AVResolutionN));
				}
#ifdef WIN32
				_snprintf(pTemp,256,"%s(%dX%d)@%d@%d@%d",tempRes.resName,tempRes.width,tempRes.height,tempRes.frameRate,tempRes.bitRate,tempRes.iGap);
#else
				snprintf(pTemp,256,"%s(%dX%d)@%d@%d@%d",tempRes.resName,tempRes.width,tempRes.height,tempRes.frameRate,tempRes.bitRate,tempRes.iGap);
#endif
				strcat(psend,pTemp);

				if(i  != count - 1)
				{
					strcat(psend,"@");
				}
			}
			Tlib_AddNewFiledVoid(pTlibfiled,"AVedioResolution",psend,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait",(char*)"1",0,0);
		}
		break;
	case PCT_CMD_GET_WORK_ENVIRONMENT:
		{
			SWorkEn* temp = (SWorkEn*)param;
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",gcmdGetWorkEn,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait",(char*)"1",0,0);
		}
		break;
	case PCT_CMD_SET_WORK_ENVIRONMENT:
		{
			SWorkEn* temp = (SWorkEn*)param;
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",gcmdSetWorkEn,0,0);
			Tlib_AddNewFiledInt(pTlibfiled,"SensorMode",temp->type,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait",(char*)"1",0,0);
		}
		break;
	case PCT_CMD_GET_RTSP_SWITCH_STUS:
		{
			SRtspSwitch* temp = (SRtspSwitch*)param;
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",gcmdGetRtspAudioSwitch,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait",(char*)"1",0,0);
		}
		break;
	case PCT_CMD_SET_RTSP_SWITCH_STUS:
		{
			SRtspSwitch* temp = (SRtspSwitch*)param;
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",gcmdSetRtspAudioSwitch,0,0);
			Tlib_AddNewFiledInt(pTlibfiled,"RtspAudioSwitch",temp->status,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait",(char*)"1",0,0);
		}
		break;
	case PCT_CMD_GET_NOISE_LEVEL:
		{
			SNoiseLevel* temp = (SNoiseLevel*)param;
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",gcmdGetNoiseLvl,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait",(char*)"1",0,0);
		}
		break;
	case PCT_CMD_SET_NOISE_LEVEL:
		{
			SNoiseLevel* temp = (SNoiseLevel*)param;
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",gcmdSetNoiseLvl,0,0);
			Tlib_AddNewFiledInt(pTlibfiled,"LowLightNoiseLvl",temp->level,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait",(char*)"1",0,0);
		}
		break;
	case PCT_CMD_QUERY_DAY_LOG:
		{
			SDaylogs* temp = (SDaylogs*)param;
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",gcmdQueryDayLog,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait",(char*)"1",0,0);
		}
		break;
	case PCT_CMD_GET_WIFI_LIST:
		{
			SWifiInfo* temp = (SWifiInfo*)param;
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",gcmdGetWifiList,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait",(char*)"1",0,0);
		}
		break;
	case PCT_CMD_SET_WIFI:
		{
			SWifiInfo* temp = (SWifiInfo*)param;
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",gcmdSetWifi,0,0);
			if(temp->totalcount)
			{
				char psend[1024] = {0};
				strcat(psend,"@");
				strcat(psend,temp->plist->wifiSsid);
				strcat(psend,temp->plist->password);

				Tlib_AddNewFiledVoid(pTlibfiled,"WifiListInfo",psend,0,0);
				Tlib_AddNewFiledVoid(pTlibfiled,"WifiSsid",temp->plist->wifiSsid,0,0);
				Tlib_AddNewFiledVoid(pTlibfiled,"WifiPwd",temp->plist->password,0,0);
			}
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait",(char*)"1",0,0);		}
		break;
	}

	Tlib_DoBuildString(pTlibfiled);

	if(pTlibfiled->dwBufLen > pdstlen)
		return -1;

	memcpy(pdst,pTlibfiled->szpCmdBuf,pTlibfiled->dwBufLen);

	return 0;
}