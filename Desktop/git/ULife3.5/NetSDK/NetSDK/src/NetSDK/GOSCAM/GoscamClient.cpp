#include "GoscamClient.h"


CGoscamClient::CGoscamClient() : CEasySocket()
{
	m_nSerialNo = 0;
	m_mutexRecv.CreateMutex();
}


CGoscamClient::~CGoscamClient()
{
	m_mutexRecv.CloseMutex();
	JTRACE("~CGoscamClient \r\n");
}

int CGoscamClient::GosRecvHead(SOCKET nSocket, char** pRecvHead)
{
	GosProHead	sHead = {0};
	
	if(*pRecvHead != NULL) return -1;

	*pRecvHead = new char[sizeof(GosProHead)];

	return Recv(nSocket, *pRecvHead, sizeof(GosProHead));
}

int CGoscamClient::GosSend(SOCKET nSocket, void* pBufSrc, int nBufLenSrc)
{
	char*		pSendBuf	= NULL;
	int			nCurPkt		= 1;
	int			nRet		= 0;
	int			nTotalSend	= 0;
	GosProHead	sHead		= {0};
	char*		pBuf		= new char[nBufLenSrc];
	int			nBufLen		= nBufLenSrc;

	if(!pBuf )	return 0;

	memcpy(pBuf, pBufSrc, nBufLenSrc);
	sHead.proType	= 1;
	if(CEasySocket::m_pKeyData)
	{
		sHead.proType	= 2;
		xor_encrypt_64((unsigned char *)pBuf, nBufLen, CEasySocket::m_pKeyData);
	}

	JTRACE("CGoscamClient::m_nSerialNo = %d, nBufLen = %d, GosSend=%s\r\n", m_nSerialNo, nBufLen, (char *)pBuf);
	sHead.magicNo	= 0x67736d70;
	sHead.serialNo	= m_nSerialNo;
	sHead.dataLen	= nBufLen;
	sHead.magicNo = htonl(sHead.magicNo);
	sHead.serialNo = htonl(sHead.serialNo);
	sHead.dataLen = htons(sHead.dataLen);
	
	sHead.msgType	= 1;
	
	pSendBuf = new char[nBufLen + sizeof(GosProHead)];
	memcpy(pSendBuf, (char *)&sHead, sizeof(GosProHead));
	memcpy(pSendBuf+sizeof(GosProHead), (char *)pBuf, nBufLen);
	nRet = Send(nSocket, pSendBuf, nBufLen+ sizeof(GosProHead));
	

#if 0
	if((nBufLen / GOS_PKT_DATA_LEN) == 0)
	{
		sHead.totalPkt	= 1;
		sHead.curPktNo	= nCurPkt;
		sHead.dataLen	= nBufLen;

		sHead.dataLen = htonl(sHead.dataLen);

		pSendBuf = new char[nBufLen + sizeof(GosProHead)];
		memcpy(pSendBuf, (char *)&sHead, sizeof(GosProHead));
		memcpy(pSendBuf+sizeof(GosProHead), (char *)pBuf, nBufLen);
		nRet = Send(nSocket, pSendBuf, nBufLen+ sizeof(GosProHead));
		nTotalSend = nRet;
	}
	else
	{
		sHead.totalPkt = nBufLen / GOS_PKT_DATA_LEN;
		if((nBufLen % GOS_PKT_DATA_LEN) != 0)	sHead.totalPkt += 1;

		pSendBuf = new char[GOS_PKT_DATA_LEN + sizeof(GosProHead)];

		while(nCurPkt < sHead.totalPkt)
		{
			sHead.dataLen = GOS_PKT_DATA_LEN;
			sHead.curPktNo = nCurPkt;
			sHead.dataLen = htonl(sHead.dataLen);
			memcpy(pSendBuf, (char *)&sHead, sizeof(GosProHead));
			memcpy(pSendBuf+sizeof(GosProHead), (char *)pBuf+((nCurPkt -1)*GOS_PKT_DATA_LEN), GOS_PKT_DATA_LEN);
			nRet = Send(nSocket, pSendBuf, nBufLen+ sizeof(GosProHead));
			if(nRet < 0 ) return nRet;
			nTotalSend += nRet;
			nCurPkt += 1;
		}

		sHead.dataLen = (nBufLen - (nCurPkt -1)*GOS_PKT_DATA_LEN);
		sHead.curPktNo = nCurPkt;
		sHead.dataLen = htonl(sHead.dataLen);

		memcpy(pSendBuf, (char *)&sHead, sizeof(GosProHead));
		memcpy(pSendBuf+sizeof(GosProHead), (char*)pBuf+((nCurPkt -1)*GOS_PKT_DATA_LEN), (nBufLen - (nCurPkt -1)*GOS_PKT_DATA_LEN));
		nRet = Send(nSocket, pSendBuf, nBufLen+ sizeof(GosProHead));
		nTotalSend += nRet;

	}
#endif

	++ m_nSerialNo;
	SAFE_DELETE(pBuf);
	SAFE_DELETE(pSendBuf);
	return nRet;
}


#if 0
int	CGoscamClient::Connect(const char *pUrl, int nPort, int nType)
{
	int			nRet			= -1;
	sockaddr_in	serAddr;

	//Close();
	
	
	
	if( m_hSocket == INVALID_SOCKET )
	{
		if( 0 != InitHandle(nType) )
		{
			return -1;
		}
	}

	serAddr.sin_family		= AF_INET;
	serAddr.sin_port		= htons(nPort);
	serAddr.sin_addr.s_addr	= DomainToIP(pUrl); 

	m_bConnecting	= true;							
	m_dwConnTick	= JGetTickCount();	
	nRet = connect(m_hSocket, (sockaddr *)&serAddr, sizeof(sockaddr_in));
	if(nRet != 0)
	{
		if(IsNoBlock() == false)
		{
			return 0;
		}
		else
		{
			m_bConnecting	= false;		
		}
	}
	else
	{
		SetNoBlock(true);
		if ( IsNoBlock() )
		{
			return 0;
		}
		else
		{
			
			return -1;
		}
	}


	return nRet;
}


// 梆定本机端口
int CGoscamClient::Bind(int uPort,const char* pAdd,int nType)
{
	sockaddr_in LocalAddr;
	LocalAddr.sin_family = AF_INET;						// 协议类型
	LocalAddr.sin_port = htons(uPort);					// 将端口转换成网络能识别的格式
	if (pAdd == NULL||strlen(pAdd)==0)
	{
		LocalAddr.sin_addr.s_addr = htonl(INADDR_ANY);	// 梆定本机
	}
	else
	{
		LocalAddr.sin_addr.s_addr = inet_addr(pAdd);
	}
	memset(&(LocalAddr.sin_zero),0,sizeof(LocalAddr.sin_zero));		// 清空结构体余下的内容

	if ( m_hSocket==INVALID_SOCKET )
	{
		if ( JLSOCK_SUCCESS != InitHandle(nType) )
		{
			return JLSOCK_ERR_CONNECT;
		}
	}

	int iBindResult = bind(m_hSocket, (sockaddr*)&LocalAddr, sizeof(struct sockaddr));
	if ( iBindResult == SOCKET_ERROR )
	{
		Close();
		return JLSOCK_ERR_BIND;
	}

	// 记录下梆定的端口
	m_uPort = uPort;
	return JLSOCK_SUCCESS;
}

#endif