#include "GoscamProtocol.h"

#define BLOCK_CHANNEL_ID	0
#define FREE_CHANNEL_START (BLOCK_CHANNEL_ID+1)

CGoscamProtocol::CGoscamProtocol()
{
	for(int i = 0; i < MAX_CONN_CHANNEL; i++)
	{
		m_gocamChannel[i] = NULL;
	}

	//m_pGoscamUser = new CGoscamUser();
}


CGoscamProtocol::~CGoscamProtocol()
{
	//SAFE_DELETE(m_pGoscamUser);
	for(int i = 0; i < MAX_CONN_CHANNEL; i++)
	{
		if(m_gocamChannel[i])
		{
			SAFE_DELETE(m_gocamChannel[i]);
		}
	}
	JTRACE("~CGoscamProtocol \r\n");
}

int	 CGoscamProtocol::GetFreeChannel()
{

	for( int i = FREE_CHANNEL_START; i < MAX_CONN_CHANNEL; i++ )
	{
		if( NULL == m_gocamChannel[i] )
		{
			m_gocamChannel[i] = new CGoscamProtocolChannel(i);
			if(m_gocamChannel[i])
				return i;
			else
				return -1;
		}
	}
	return -1;
}


long	CGoscamProtocol::S_Connect(const char* pAddr, int nPort, int nServerType, RecvCallBack serverCB, long lUserParam ,int autoRecnnt)
{
	long	lHandle = -1;
	int		nRet	= -1;

	lHandle = GetFreeChannel();
	
	if( lHandle < 0 ) return NetSDKErr_GetChannel;

	nRet = m_gocamChannel[lHandle]->S_Connect(pAddr, nPort, nServerType, serverCB, lUserParam,autoRecnnt);

	if(nRet != NetSDKErr_Success ) 
	{
		SAFE_DELETE(m_gocamChannel[lHandle]);
		return nRet;
	}

	return lHandle;
}
long	CGoscamProtocol::S_StartHeartBeat(long lHandle, const char* pData, int nDataLen )
{
	if( lHandle < 0 ) return NetSDKErr_GetChannel;

	return m_gocamChannel[lHandle]->S_StartHeartBeat(pData, nDataLen);

}
long	CGoscamProtocol::S_StopHeartBeat(long lHandle)
{
	if( lHandle < 0 ) return NetSDKErr_GetChannel;

	return m_gocamChannel[lHandle]->S_StopHeartBeat();
}
long	CGoscamProtocol::S_Send(long lHandle, const char* pData, int nDataLen )
{
	if( lHandle < 0 ) return NetSDKErr_GetChannel;

	return m_gocamChannel[lHandle]->S_Send(pData, nDataLen);
}
long CGoscamProtocol::S_Exe_Cmd(long lHandle, const char* pData, int nDataLen ,int block, int timeout, int *nerror,char* pRlt,int *pRltLen)
{
	if( lHandle < 0 ) return NetSDKErr_GetChannel;

	return m_gocamChannel[lHandle]->S_Exe_Cmd(pData, nDataLen,block,timeout,nerror,pRlt,pRltLen);
}

long	CGoscamProtocol::S_SetKey(long lHandle, unsigned char *pKey, int nKeyLen)
{
	if( lHandle < 0 ) return NetSDKErr_GetChannel;

	return m_gocamChannel[lHandle]->S_SetKey(pKey, nKeyLen);
}

long	CGoscamProtocol::S_Close(long lHandle )
{
	if( lHandle < 0 ) return NetSDKErr_GetChannel;
	
	SAFE_DELETE(m_gocamChannel[lHandle]);
	return 0;
}


long	CGoscamProtocol::Init()
{
	return 0;
}
long	CGoscamProtocol::UnInit()
{
	delete this;
	return 0;
}

long	CGoscamProtocol::EncodeData(unsigned char* pSrcData, unsigned int nSrcDataLen, unsigned char** pOutData, unsigned int* nOutLen)
{
	const char*		key					= "SensitivityCrypt2468$@&*^%";
	unsigned char	k_mac[ENC_MAC_LEN]	= {0};
	unsigned char*	en_data				= NULL;
	unsigned int	en_len				= 0;
	unsigned char	s_mac[ENC_MAC_LEN]	= {0};


	if(*pOutData != NULL) return NetSDKErr_Param;

	sha256_mac((unsigned char *)key, strlen((char*)key), k_mac);
	sha256_mac(pSrcData, nSrcDataLen, s_mac);

	aes256_cbc_enc(s_mac, sizeof(s_mac), &en_data, &en_len, k_mac);

	if(en_data != NULL && en_len > 0)
	{

		base64_encode(en_data, en_len, pOutData, nOutLen);
		if(pOutData != NULL && *nOutLen > 0)
		{
			free_data(en_data);
			en_data = NULL;
			return *nOutLen;
		}

		free_data(en_data);
		en_data = NULL;
	}
	return -1;
}
#if 0
long	CGoscamProtocol::EncodeData(unsigned char* pSrcData, unsigned int nSrcDataLen, unsigned char** pOutData, unsigned int* nOutLen)
{
	const char*		key					= "#@FDAkfdjial$#JFLDIjklfjdi7987#@FDAkfdjial";
	unsigned char	k_mac[ENC_MAC_LEN]	= {0};
	unsigned char*	en_data				= NULL;
	unsigned int	en_len				= 0;


	if(*pOutData != NULL) return NetSDKErr_Param;

	sha256_mac((unsigned char *)key, strlen((char*)key), k_mac);

	aes256_cbc_enc(pSrcData, nSrcDataLen, &en_data, &en_len, k_mac);

	if(en_data != NULL && en_len > 0)
	{

		base64_encode(en_data, en_len,pOutData, nOutLen);
		if(pOutData != NULL && *nOutLen > 0)
		{
			free_data(en_data);
			en_data = NULL;
			return *nOutLen;
		}

		free_data(en_data);
		en_data = NULL;
	}
	return -1;
}
#endif

long CGoscamProtocol::DecodeData(unsigned char* pSrcData, unsigned int nSrcDataLen, unsigned char** pOutData, unsigned int* nOutLen)
{
	char* key = "GosServer&88899&%Msg$#Pwd";
	unsigned char key_mac[32] = {0};
	sha256_mac((unsigned char*)key, strlen((char*)key), key_mac);

	unsigned char* DecData64 = NULL;
	unsigned int DecLen64 = 0;
	int nRet = base64_decode(pSrcData, nSrcDataLen, &DecData64, &DecLen64);
	if(!nRet && DecLen64 > 1)
	{
		nRet = aes256_cbc_dec(DecData64, DecLen64, pOutData, nOutLen, key_mac);

		if(DecData64)
		{
			free_data(DecData64);
		}
	}
	return nRet;
}

long	CGoscamProtocol::DeleteData(unsigned char *pOutData)
{
	free_data(pOutData);
	pOutData = NULL;
	return NetSDKErr_Success;
}

long CGoscamProtocol::BlockRequest( const char* pAddr, int nPort,char* pData, int nDataLen , int timeout, char** pRlt, int *pRltLen , unsigned char *pKey, int nKeyLen)
{
	CGoscamProtocolChannel chan(BLOCK_CHANNEL_ID);
	return chan.BlockRequest(pAddr,nPort,pData,nDataLen,timeout,pRlt,pRltLen, pKey, nKeyLen);
	return NetSDKErr_Success;
}

void CGoscamProtocol::BlockRequestFree( char* pRlt )
{
	if (pRlt)
	{
		free(pRlt);
	}
// 	CGoscamProtocolChannel chan(BLOCK_CHANNEL_ID);
// 	return chan.BlockRequestFree(pRlt);
}