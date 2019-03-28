#include "NetProSDKAPI.h"
#include "NetProCommon.h"
#include <stdio.h>
#include <string>
#include <map>
//#include "JLogWriter.h"
using namespace std;

typedef map<int, CNetProCommon*>	mNetProCommon;
typedef map<int, CNetProCommon*>::iterator	g_mNetProCommon_iter;
mNetProCommon	g_mNetProCommon;


#define  SDK_MAX_CONN_CHANNEL	500

#define			P2P_CHANNEL_ADDVALUE	200


int				g_nCurType[SDK_MAX_CONN_CHANNEL];
int				g_nInit		= 0;

#if (defined _WIN32) || (defined _WIN64)

BOOL APIENTRY DllMain( HANDLE hModule, DWORD  ul_reason_for_call, LPVOID lpReserved )
{
	switch (ul_reason_for_call)
	{
	case DLL_PROCESS_ATTACH:
	case DLL_THREAD_ATTACH:
	case DLL_THREAD_DETACH:
	case DLL_PROCESS_DETACH:
		break;
	}

	return TRUE;
}
#endif


CNetProCommon*	GetChildPro(int i, int nType)
{
	CNetProCommon*			pNet = NULL;
	g_mNetProCommon_iter	iter ;
	if(i == -1)
		iter = g_mNetProCommon.find(nType);
	else
		iter = g_mNetProCommon.find(g_nCurType[i]);

	if (iter != g_mNetProCommon.end())
	{
		return iter->second;
	}

	return pNet;
}


long	SetChildPro(eNetProType eType)
{
	CNetProCommon*			pNetProCommon	= NULL;
	g_mNetProCommon_iter	iter			= g_mNetProCommon.find(eType);
	int						nRet			= -1;
	if (iter == g_mNetProCommon.end())
	{
		pNetProCommon = CreateChildPro(eType);
		if (pNetProCommon)
		{
			g_mNetProCommon.insert(pair<eNetProType, CNetProCommon*>(eType, pNetProCommon));
			//g_nCurType = eType;
			nRet = pNetProCommon->Init();
			if( nRet != NetProErr_Success )
			{
				return NetProErr_Init;
			}
		}
		return NetProErr_Success;
	}
	else
	{
		return NetProErr_Success;
	}

}

void CleanChildPro()
{
	g_mNetProCommon_iter iter = g_mNetProCommon.begin();
	for (; iter!=g_mNetProCommon.end();)
	{
		CNetProCommon* pNet = iter->second;
		if (pNet)
		{
			pNet->UnInit();
			delete pNet;
			pNet = NULL;
			g_mNetProCommon.erase(iter++);	
		}
	}
}

// 初始化
NETPROSDK_API	long	NetPro_Init()
{
	if(g_nInit) return NetProErr_Success;
	for(int i = 0; i < SDK_MAX_CONN_CHANNEL; i++)
	{
		g_nCurType[i] = 0;
	}
	SetChildPro(NETPRO_USE_TUTK);
	SetChildPro(NETPRO_USE_4_0);
	g_nInit = 1;
	return NetProErr_Success;
}

// 反初始化
NETPROSDK_API	long	NetPro_UnInit()
{
	if(!g_nInit)	return NetProErr_Success;
	CleanChildPro();
	g_nInit = 0;
	return NetProErr_Success;
}


// 登录（连接设备）
NETPROSDK_API	long	NetPro_ConnDev(const char* pUID, const char* pUser, const char* pPwd, int nTimeOut,  int nProjectType,  eNetConnType eConnType, EventCallBack eventCB, long lUserParam)
{
	long	lHandle		= 0;
	int		nType		= NETPRO_USE_TUTK;
	int		nProType	= nProjectType;

	if(eConnType == NETPRO_CONNECT_4_0_P2P || eConnType == NETPRO_CONNECT_4_0_TCP)
	{
		nType = NETPRO_USE_4_0;
		if(eConnType == NETPRO_CONNECT_4_0_TCP)
		{
			nProType = nProjectType+10;
		}
	}

	CNetProCommon*	pNet	= GetChildPro(-1, nType);
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}

	lHandle = pNet->ConnDev( pUID, pUser, pPwd, nTimeOut, nProType, eventCB, lUserParam );

	if(lHandle < 0) return lHandle;

	if(nType == NETPRO_USE_4_0 ) lHandle += P2P_CHANNEL_ADDVALUE;

	g_nCurType[lHandle] = nType;

	return lHandle;
}

NETPROSDK_API	long	NetPro_CheckDevConn(long lConnHandle)
{
	CNetProCommon*	pNet	= GetChildPro(lConnHandle, 0);
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}

	if(g_nCurType[lConnHandle] == NETPRO_USE_4_0)
	{
		lConnHandle -= P2P_CHANNEL_ADDVALUE;
	}
	return pNet->CheckDevConn( lConnHandle );
}



NETPROSDK_API	long	NetPro_CloseDev(long lHandle)
{
	CNetProCommon*	pNet	= GetChildPro(lHandle, 0);;
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}
	if(g_nCurType[lHandle] == NETPRO_USE_4_0)
	{
		lHandle -= P2P_CHANNEL_ADDVALUE;
	}
	return pNet->CloseDev(lHandle); 
}


NETPROSDK_API	long	NetPro_GetDevChnNum(long lConnHandle)
{
	CNetProCommon*	pNet	= GetChildPro(lConnHandle, 0);;
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}
	if(g_nCurType[lConnHandle] == NETPRO_USE_4_0)
	{
		lConnHandle -= P2P_CHANNEL_ADDVALUE;
	}
	return pNet->GetDevChnNum( lConnHandle );
}

NETPROSDK_API	long	NetPro_CreateDevChn(long lConnHandle, int nNum)
{
	CNetProCommon*	pNet	= GetChildPro(lConnHandle, 0);;
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}
	if(g_nCurType[lConnHandle] == NETPRO_USE_4_0)
	{
		lConnHandle -= P2P_CHANNEL_ADDVALUE;
	}
	return pNet->CreateDevChn( lConnHandle , nNum);
}

NETPROSDK_API	long	NetPro_SetCheckConnTimeinterval(long lConnHandle, int nMillisecond)
{
	CNetProCommon*	pNet	= GetChildPro(lConnHandle, 0);;
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}
	if(g_nCurType[lConnHandle] == NETPRO_USE_4_0)
	{
		lConnHandle -= P2P_CHANNEL_ADDVALUE;
	}
	return pNet->SetCheckConnTimeinterval(lConnHandle, nMillisecond); 
}



NETPROSDK_API	long	NetPro_OpenStream(long lHandle, int nChannel, char* pPassword, eNetStreamType eType, long lTimeSeconds, long lTimeZone, StreamCallBack streamCB, long lUserParam)
{
	CNetProCommon*	pNet	= GetChildPro(lHandle, 0);;
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}
	if(g_nCurType[lHandle] == NETPRO_USE_4_0)
	{
		lHandle -= P2P_CHANNEL_ADDVALUE;
	}
	return pNet->OpenStream(lHandle, nChannel, pPassword, eType ,lTimeSeconds, lTimeZone, streamCB, lUserParam); 
}

NETPROSDK_API	long	NetPro_CloseStream(long lHandle, int nChannel, eNetStreamType eType)
{
	CNetProCommon*	pNet	= GetChildPro(lHandle, 0);;
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}
	if(g_nCurType[lHandle] == NETPRO_USE_4_0)
	{
		lHandle -= P2P_CHANNEL_ADDVALUE;
	}
	return pNet->CloseStream(lHandle, nChannel, eType); 
}


NETPROSDK_API	long	NetPro_PasueRecvStream(long lConnHandle, int nChannel, int nPasueFlag)
{
	
	CNetProCommon*	pNet	= GetChildPro(lConnHandle, 0);;
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}
	
	if(g_nCurType[lConnHandle] == NETPRO_USE_4_0)
	{
		lConnHandle -= P2P_CHANNEL_ADDVALUE;
	}

	return pNet->PasueRecvStream(lConnHandle, nChannel, nPasueFlag); 
}

// 设置参数   事件回调返回 相同类型的事件  根据事件做对应处理
NETPROSDK_API	long	NetPro_GetParam(long lConnHandle, int nChannel, eNetProParam eParam, void* lData, int nDataSize)
{
	CNetProCommon*	pNet	= GetChildPro(lConnHandle, 0);;
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}
	if(g_nCurType[lConnHandle] == NETPRO_USE_4_0)
	{
		lConnHandle -= P2P_CHANNEL_ADDVALUE;
	}
	return pNet->GetParam(lConnHandle, nChannel, eParam, lData, nDataSize); 
}

// 获取参数
NETPROSDK_API	long	NetPro_SetParam(long lConnHandle, int nChannel, eNetProParam eParam, void* lData, int nDataSize)
{
	CNetProCommon*	pNet	= GetChildPro(lConnHandle, 0);;
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}
	if(g_nCurType[lConnHandle] == NETPRO_USE_4_0)
	{
		lConnHandle -= P2P_CHANNEL_ADDVALUE;
	}
	return pNet->SetParam(lConnHandle, nChannel, eParam, lData, nDataSize); 
}

NETPROSDK_API	long	NetPro_RecDownload(long lConnHandle, int nChannel, const char* pFileName, char *pSrcFileName)
{
	CNetProCommon*	pNet	= GetChildPro(lConnHandle, 0);;
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}
	if(g_nCurType[lConnHandle] == NETPRO_USE_4_0)
	{
		lConnHandle -= P2P_CHANNEL_ADDVALUE;
	}
	return pNet->RecDownload(lConnHandle, nChannel, pFileName, pSrcFileName); 
}

NETPROSDK_API	long	NetPro_TalkSendFile(long lConnHandle, int nChannel, const char *pFileName, int nIsPlay)
{
	CNetProCommon*	pNet	= GetChildPro(lConnHandle, 0);;
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}
	if(g_nCurType[lConnHandle] == NETPRO_USE_4_0)
	{
		lConnHandle -= P2P_CHANNEL_ADDVALUE;
	}
	return pNet->TalkSendFile(lConnHandle, nChannel, pFileName, nIsPlay); 
}


// 开始对讲
NETPROSDK_API	long	NetPro_TalkStart(long lConnHandle, int nChannel)
{
	CNetProCommon*	pNet	= GetChildPro(lConnHandle, 0);;
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}
	if(g_nCurType[lConnHandle] == NETPRO_USE_4_0)
	{
		lConnHandle -= P2P_CHANNEL_ADDVALUE;
	}
	return pNet->TalkStart(lConnHandle, nChannel); 
}

// 发送对讲数据
NETPROSDK_API	long	NetPro_TalkSend(long lConnHandle, int nChannel, const char* pData, DWORD dwSize)
{
	CNetProCommon*	pNet	= GetChildPro(lConnHandle, 0);;
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}
	if(g_nCurType[lConnHandle] == NETPRO_USE_4_0)
	{
		lConnHandle -= P2P_CHANNEL_ADDVALUE;
	}
	return pNet->TalkSend(lConnHandle, nChannel, pData, dwSize); 
}

// 结束对讲
NETPROSDK_API	long	NetPro_TalkStop(long lConnHandle, int nChannel)
{
	CNetProCommon*	pNet	= GetChildPro(lConnHandle, 0);;
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}
	if(g_nCurType[lConnHandle] == NETPRO_USE_4_0)
	{
		lConnHandle -= P2P_CHANNEL_ADDVALUE;
	}
	return pNet->TalkStop(lConnHandle, nChannel); 
}

// 切换码流
NETPROSDK_API	long	NetPro_SetStream(long lConnHandle, int nChannel, eNetVideoStreamType eLevel)
{
	CNetProCommon*	pNet	= GetChildPro(lConnHandle, 0);;
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}
	if(g_nCurType[lConnHandle] == NETPRO_USE_4_0)
	{
		lConnHandle -= P2P_CHANNEL_ADDVALUE;
	}
	return pNet->SetStream(lConnHandle, nChannel, eLevel); 
}

// 停止录像下载
NETPROSDK_API	long	NetPro_StopDownload(long lConnHandle, int nChannel)
{
	CNetProCommon*	pNet	= GetChildPro(lConnHandle, 0);;
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}
	if(g_nCurType[lConnHandle] == NETPRO_USE_4_0)
	{
		lConnHandle -= P2P_CHANNEL_ADDVALUE;
	}
	return pNet->StopDownload(lConnHandle, nChannel); 
}

// 删除录像文件
NETPROSDK_API	long	NetPro_DelRec(long lConnHandle, int nChannel, const char *pFileName)
{
	CNetProCommon*	pNet	= GetChildPro(lConnHandle, 0);;
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}
	if(g_nCurType[lConnHandle] == NETPRO_USE_4_0)
	{
		lConnHandle -= P2P_CHANNEL_ADDVALUE;
	}
	return pNet->DelRec(lConnHandle, nChannel, pFileName); 
}

// 创建NVR历史流回放通道
NETPROSDK_API	long	NetPro_RecStreamPlay(long lConnHandle, const char *pRecName, int nRecNameLen)
{
	CNetProCommon*	pNet	= GetChildPro(lConnHandle, 0);;
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}
	if(g_nCurType[lConnHandle] == NETPRO_USE_4_0)
	{
		lConnHandle -= P2P_CHANNEL_ADDVALUE;
	}
	return pNet->CreateRecPlayChn(lConnHandle, pRecName, nRecNameLen); 
}

// 释放历史流回放通道
NETPROSDK_API	long	NetPro_DeleteRecPlayChn(long lConnHandle, int nChn)
{
	CNetProCommon*	pNet	= GetChildPro(lConnHandle, 0);;
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}
	if(g_nCurType[lConnHandle] == NETPRO_USE_4_0)
	{
		lConnHandle -= P2P_CHANNEL_ADDVALUE;
	}
	return pNet->DeleteRecPlayChn(lConnHandle, nChn); 
}

// 历史流控制
NETPROSDK_API	long	NetPro_RecStreamCtrl(long lConnHandle, int nChn, eNetRecCtrlType eCtrlType, long lData)
{
	CNetProCommon*	pNet	= GetChildPro(lConnHandle, 0);;
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}
	if(g_nCurType[lConnHandle] == NETPRO_USE_4_0)
	{
		lConnHandle -= P2P_CHANNEL_ADDVALUE;
	}
	return pNet->RecStreamCtrl(lConnHandle, nChn, eCtrlType, lData); 
}

NETPROSDK_API	long	NetPro_SetTransportProType(eNetProTransportProType eProType, char* pServerAddr)
{
	CNetProCommon*	pNet	= GetChildPro(-1, NETPRO_USE_4_0);
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}

	return pNet->SetTransportProType(eProType, pServerAddr); 
}
/*
NETPROSDK_API	long	NetPro_ConnServer(char* pServerAddr, int nPort, int nUseTcp, EventCallBack eventCB, long lUserParam)
{
	CNetProCommon*	pNet	= GetChildPro(-1, NETPRO_USE_4_0);
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}

	return pNet->ConnServer(pServerAddr, nPort, nUseTcp, eventCB, lUserParam); 
}


NETPROSDK_API	long	NetPro_CloseServer()
{
	CNetProCommon*	pNet	= GetChildPro(-1, NETPRO_USE_4_0);
	if( pNet ==  NULL)
	{
		return NetProErr_Pro;
	}
	return pNet->CloseServer(); 
}	*/	