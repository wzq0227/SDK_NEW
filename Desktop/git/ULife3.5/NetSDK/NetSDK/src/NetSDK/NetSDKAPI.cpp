#include "NetSDKAPI.h"
#include "JLSocketDef.h"
#include "GoscamProtocol.h"
#include "TestLog.h"
#include <stdio.h>


static CGoscamProtocol g_proNet;


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



// 初始化
NETSDK_API	long	Net_Init(const char* logFilePath)
{
#if (defined _WIN32) || (defined _WIN64)
	WSADATA wsdata;
	WORD wVersionRequested = MAKEWORD(2, 2);
	WSAStartup(wVersionRequested, &wsdata);
#endif
	
	if(logFilePath)
	{
		strcpy(g_logfilepath,logFilePath);
		g_bOpenLog = 1;
	}

	return NetSDKErr_Success;
}

// 反初始化
NETSDK_API	long	Net_UnInit()
{

#if (defined _WIN32) || (defined _WIN64)
	WSACleanup();
#endif
	return NetSDKErr_Success;
}



#if 0
NETSDK_API	long	Net_CMS_Config(const char* pServerAddr, int nPort, CMSCallBack localCB, long lUserParam )
{
	CGoscamProtocol*	pNet	= GetChildPro();
	if( pNet ==  NULL)
	{
		return NetSDKErr_Pro;
	}
	return pNet->LocalConfig(pServerAddr, nPort, localCB, lUserParam ); 
}


NETSDK_API	long	Net_CMS_Send(const char* pData, int nDataLen )
{
	CGoscamProtocol*	pNet	= GetChildPro();
	if( pNet ==  NULL)
	{
		return NetSDKErr_Pro;
	}
	return pNet->CMS_Send( pData, nDataLen ); 
}

#endif



NETSDK_API	long	Net_S_Connect(const char* pAddr, int nPort, int nServerType, RecvCallBack serverCB, long lUserParam  ,int autoRecnnt)
{
	
	return g_proNet.S_Connect( pAddr, nPort, nServerType, serverCB,  lUserParam, autoRecnnt); 
}


NETSDK_API	long	Net_S_StartHeartBeat(long lHandle, const char* pData, int nDataLen )
{
	
	return  g_proNet.S_StartHeartBeat(lHandle,  pData, nDataLen ); 
}


NETSDK_API	long	Net_S_StopHeartBeat(long lHandle)
{

	return  g_proNet.S_StopHeartBeat( lHandle ); 
}


NETSDK_API	long	Net_S_Send(long lHandle, const char* pData, int nDataLen )
{
	
	return  g_proNet.S_Send( lHandle, pData, nDataLen ); 
}

NETSDK_API	long	Net_S_Exe_Cmd(long lHandle, const char* pData, int nDataLen ,int block, int timeout, int *nerror,char* pRlt,int *pRltLen)
{

	return  g_proNet.S_Exe_Cmd( lHandle, pData, nDataLen, block, timeout, nerror, pRlt, pRltLen ); 
}

NETSDK_API	long	Net_S_SetKey(long lHandle, unsigned char *pKey, int nKeyLen)
{
	return  g_proNet.S_SetKey( lHandle, pKey, nKeyLen); 
}

NETSDK_API	long	Net_S_Close(long lHandle)
{

	return  g_proNet.S_Close(lHandle); 
}

NETSDK_API	long	Net_EncodeData(unsigned char* pSrcData, unsigned int nSrcDataLen, unsigned char** pOutData, unsigned int* nOutLen)
{
	return g_proNet.EncodeData(pSrcData, nSrcDataLen, pOutData, nOutLen);
}

NETSDK_API	long	Net_DecodeData(unsigned char* pSrcData, unsigned int nSrcDataLen, unsigned char** pOutData, unsigned int* nOutLen)
{
	return g_proNet.DecodeData(pSrcData, nSrcDataLen, pOutData, nOutLen);
}

NETSDK_API	long	Net_DeleteData(unsigned char *pOutData)
{
	return g_proNet.DeleteData(pOutData);
}

NETSDK_API	long Net_S_BlockRequest( const char* pAddr, int nPort, char* pData, int nDataLen , int timeout, char** pRlt, int *pRltLen , unsigned char *pKey, int nKeyLen)
{
	return g_proNet.BlockRequest(pAddr,nPort,pData,nDataLen,timeout,pRlt,pRltLen, pKey, nKeyLen);
}

NETSDK_API void Net_S_BlockRequestFree( char* pRlt )
{
	return g_proNet.BlockRequestFree(pRlt);
}