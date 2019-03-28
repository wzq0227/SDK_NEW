#ifndef _GOSCAM_PROTOCOL_H_
#define _GOSCAM_PROTOCOL_H_

#define  ENC_MAC_LEN	32


#include "../crypt/encrypt_def.h"
#include "GoscamProtocolChannel.h"

class CGoscamProtocol
{
public:
	CGoscamProtocol();
	virtual ~CGoscamProtocol();

	 long	Init();
	 long	UnInit();
	 long	S_Connect(const char* pAddr, int nPort, int nServerType, RecvCallBack serverCB, long lUserParam ,int autoRecnnt);
	 long	S_StartHeartBeat(long lHandle, const char* pData, int nDataLen );
	 long	S_StopHeartBeat(long lHandle);
	 long	S_Send(long lHandle, const char* pData, int nDataLen );
	 long	S_Exe_Cmd(long lHandle, const char* pData, int nDataLen ,int block, int timeout, int *nerror,char* pRlt,int *pRltLen);
	 long	S_SetKey(long lHandle, unsigned char *pKey, int nKeyLen);
	 long	S_Close(long lHandle );
	 long	EncodeData(unsigned char* pSrcData, unsigned int nSrcDataLen, unsigned char** pOutData, unsigned int* nOutLen);
	 long	DecodeData(unsigned char* pSrcData, unsigned int nSrcDataLen, unsigned char** pOutData, unsigned int* nOutLen);
	 long	DeleteData(unsigned char *pOutData);
	 long BlockRequest( const char* pAddr, int nPort, char* pData, int nDataLen , int timeout, char** pRlt, int *pRltLen , unsigned char *pKey, int nKeyLen);
	 void BlockRequestFree(char* pRlt );

protected:
	int				GetFreeChannel();

	
	CGoscamProtocolChannel*		m_gocamChannel[MAX_CONN_CHANNEL];

};
#endif