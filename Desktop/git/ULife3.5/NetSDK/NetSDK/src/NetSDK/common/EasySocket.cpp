#include "EasySocket.h"
#include "TestLog.h"

CEasySocket::CEasySocket()
{
	m_pKeyData = NULL;

	for(int i =0 ;i < MAX_GETADDR_COUNT; i++)
	{
		m_checkGetAddr[i].nFlag = 0;
		m_checkGetAddr[i].nError = 0;
		m_checkGetAddr[i].server_addr = NULL;
	}

	memset(m_strPort, 0, sizeof(m_strPort));
	memset(m_strAddr, 0, sizeof(m_strAddr));
	m_nCurGetAddrIndex = 0;
}


CEasySocket::~CEasySocket()
{
	SAFE_DELETE(m_pKeyData);
}

void CEasySocket::Close(SOCKET* nSocket)
{
	if(*nSocket != INVALID_SOCKET)
	{
		TEST_LOG_DATA("SYSTEMCALL","Close socket -> socket = %d",*nSocket);
		SAFE_CLOSE_SOCK(*nSocket);
		*nSocket = INVALID_SOCKET ;
	}
}

int		CEasySocket::SetSendTimeOut(SOCKET nSocket, int nTimeOut)
{
	if( nSocket == INVALID_SOCKET )
		return -1;
#if (defined _WIN32) || (defined _WIN64)
	setsockopt(nSocket, SOL_SOCKET, SO_SNDTIMEO, (const char *) &nTimeOut, sizeof(nTimeOut));
#else
	struct timeval sendTimeOut;
	sendTimeOut.tv_sec = 0;
	sendTimeOut.tv_usec = nTimeOut*1000;
	setsockopt(nSocket, SOL_SOCKET, SO_SNDTIMEO, (const char *) &sendTimeOut, sizeof(struct timeval));
#endif
	return 0;
}

int		CEasySocket::SetRecvTimeOut(SOCKET nSocket, int nTimeOut)
{
	if( nSocket == INVALID_SOCKET )
		return -1;

#if (defined _WIN32) || (defined _WIN64)
	setsockopt(nSocket, SOL_SOCKET, SO_RCVTIMEO, (const char *)&nTimeOut, sizeof(nTimeOut));
#else
	struct timeval recvTimeOut;
	recvTimeOut.tv_sec = 0;
	recvTimeOut.tv_usec = nTimeOut*1000;
	setsockopt(nSocket, SOL_SOCKET, SO_RCVTIMEO, (const char *)&recvTimeOut, sizeof(struct timeval));
#endif

	return 0;
}

SOCKET CEasySocket::ConnectNew(const char *pAddr, int nPort, int bTcp)
{
	int				nIndex		= 0;
	int				nRet		= -1;
	char				strPort[EASYPORT_PORTLEN]	= {0};
	SOCKET			nSocket		= INVALID_SOCKET;
	struct addrinfo addrCriteria;
	//struct addrinfo *server_addr = NULL;
	CJLThreadCtrl	tcCheck;

	strcpy_s(tcCheck.m_szName,J_DGB_NAME_LEN,"tcCheck");
	tcCheck.SetOwner(this);							
	tcCheck.SetParam(this);
	memset(&addrCriteria, 0, sizeof(struct addrinfo));
	sprintf(strPort, "%d", nPort);
	TEST_LOG_DATA("ConnectNew","Start connect server ->  ip = %s,port = %d",pAddr,nPort);

	addrCriteria.ai_family = AF_UNSPEC;
	if(bTcp)
		addrCriteria.ai_socktype = SOCK_STREAM;
	else
		addrCriteria.ai_socktype = SOCK_DGRAM;
#if 0
	nRet = getaddrinfo(pAddr, strPort, &addrCriteria, &server_addr);
	if(nRet != 0)
	{
		TEST_LOG_DATA("ConnectNew","getaddrinfo -> nRet = %d",nRet);
		JTRACE("CEasySocket::Connect error[getaddrinfo error]\r\n");
		return INVALID_SOCKET;
	}
#else
	m_nCurGetAddrIndex = GetAddrIndex();
	nIndex = m_nCurGetAddrIndex;
	if(m_nCurGetAddrIndex < 0) return INVALID_SOCKET;

	m_checkGetAddr[nIndex].nFlag = 1;
	tcCheck.StartThread(RunCheckThread);

	int nSleepCount = 0;
	while(m_checkGetAddr[nIndex].nFlag != 0 && nSleepCount < 30)
	{
		JSleep(100);
		nSleepCount ++;
	}
	if(m_checkGetAddr[nIndex].nFlag != 0)
	{
		m_checkGetAddr[nIndex].nError = 1;
		JTRACE("CEasySocket::getaddr timeout.......\r\n");
		return INVALID_SOCKET;
	}
#endif
	struct addrinfo *addr = m_checkGetAddr[nIndex].server_addr/*server_addr*/;
	while (addr != NULL) 
	{
		nSocket = socket(m_checkGetAddr[nIndex].server_addr->ai_family, m_checkGetAddr[nIndex].server_addr->ai_socktype, m_checkGetAddr[nIndex].server_addr->ai_protocol);
		if(nSocket != INVALID_SOCKET)
		{
			nRet = connect(nSocket, addr->ai_addr, addr->ai_addrlen);
			TEST_LOG_DATA("ConnectNew","Connect -> nRet = %d,ip = %s, port = %d",nRet,inet_ntoa(((sockaddr_in*)addr->ai_addr)->sin_addr),ntohs(((sockaddr_in*)addr->ai_addr)->sin_port));
			if (nRet == 0)
			{
				nRet = SetIoSock(nSocket, 1);
				break;
			}
			else
			{
				TEST_LOG_DATA("ConnectNew","Connect failed-> nRet = %d",nRet);
			}
			SAFE_CLOSE_SOCK(nSocket);
		}
		else
		{
			TEST_LOG_DATA("ConnectNew","Create socket failed-> nSocket = %d",nSocket);
		}
		addr = addr->ai_next;
	}

	freeaddrinfo(m_checkGetAddr[nIndex].server_addr);

	TEST_LOG_DATA("ConnectNew","Return socket ->  socket = %d",nSocket);
	return nSocket;
}


fJThRet CEasySocket::RunCheckThread(void* pParam)
{
	int					iIsRun				= 0;
	CJLThreadCtrl*		pThreadCtrl			= NULL;	
	CEasySocket*		pChannel			= NULL;	


	pThreadCtrl	= (CJLThreadCtrl*)pParam;
	if ( pThreadCtrl==NULL )
	{
		return 0;
	}
	pChannel	= (CEasySocket *)pThreadCtrl->GetOwner();
	if ( pChannel == NULL )
	{
		pThreadCtrl->SetThreadState(THREAD_STATE_STOP);		// 运行状态
		return 0;
	}
	
	pChannel->RunCheckAction();
	
	pThreadCtrl->NotifyStop();


	iIsRun = 0;
	return 0;
}


int CEasySocket::RunCheckAction()
{
	int nIndex = m_nCurGetAddrIndex;
	struct addrinfo addrCriteria;
	memset(&addrCriteria, 0, sizeof(struct addrinfo));
	addrCriteria.ai_family = AF_UNSPEC;
	addrCriteria.ai_socktype = SOCK_STREAM;
	int nRet = getaddrinfo(m_strAddr, m_strPort, &addrCriteria, &m_checkGetAddr[nIndex].server_addr);

	if(m_checkGetAddr[nIndex].nError == 1)
	{
		m_checkGetAddr[nIndex].nError = 0;
		if(m_checkGetAddr[nIndex].server_addr)
		{
			freeaddrinfo(m_checkGetAddr[nIndex].server_addr);
			m_checkGetAddr[nIndex].server_addr = NULL;
		}
		
	}
	if(nRet != 0)
	{
		m_checkGetAddr[nIndex].nFlag = 0;
		JTRACE("CEasySocket::Connect error[getaddrinfo error]\r\n");
		return INVALID_SOCKET;
	}
	
	m_checkGetAddr[nIndex].nFlag = 0;

	return 0;
	
}

int				CEasySocket::GetAddrIndex()
{
	for(int i =0; i < MAX_GETADDR_COUNT; i++)
	{
		if(m_checkGetAddr[i].nFlag == 0)
		{
			return i;
		}
	}

	return -1;
}
SOCKET CEasySocket::Connect(const char *pAddr, int nPort, int nConnType, int nTimeOut )
{
	sockaddr_in		serAddr		= {0};
	int				nRet		= -1;
	int				nError		= -1;  
	int				nStdIn		= 0;
	int				nMaxFd		= 0;
	int				optLen		= sizeof(int);  
	int				nFamily		= 0;
	int				nType		= 0;
	int				nProtocol	= 0;
	fd_set			fdWrite;  
	//char			strPort[EASYPORT_PORTLEN]	= {0};
	SOCKET			nSocket		= INVALID_SOCKET;
	
	//struct addrinfo *server_addr = NULL;
	CJLThreadCtrl	tcCheck;
	int				nIndex = 0;

	strcpy_s(tcCheck.m_szName,J_DGB_NAME_LEN,"tcCheck");
	tcCheck.SetOwner(this);							
	tcCheck.SetParam(this);

	
	sprintf(m_strPort, "%d", nPort);
	sprintf(m_strAddr, "%s", pAddr);

	nRet = GetSockType((SOCK_TYPE)nConnType, &nFamily, &nType, &nProtocol);

	
	if(nRet != 0 ) return INVALID_SOCKET;
#if 1
	if (nConnType == SOCK_TCP4 || nConnType == SOCK_TCP6)
	{
		return ConnectNew(pAddr,nPort,1);
	}
	else
	{
		return ConnectNew(pAddr,nPort,0);
	}
#endif
	

	
	m_nCurGetAddrIndex = GetAddrIndex();
	nIndex = m_nCurGetAddrIndex;
	if(m_nCurGetAddrIndex < 0) return INVALID_SOCKET;

	m_checkGetAddr[nIndex].nFlag = 1;
	tcCheck.StartThread(RunCheckThread);

	int nSleepCount = 0;
	while(m_checkGetAddr[nIndex].nFlag != 0 && nSleepCount < 30)
	{
		JSleep(100);
		nSleepCount ++;
	}
	if(m_checkGetAddr[nIndex].nFlag != 0)
	{
		m_checkGetAddr[nIndex].nError = 1;
		JTRACE("CEasySocket::getaddr timeout.......\r\n");
		return INVALID_SOCKET;
	}
// 	nRet = getaddrinfo(pAddr, strPort, &addrCriteria, &server_addr);
// 	if(nRet != 0)
// 	{
// 		JTRACE("CEasySocket::Connect error[getaddrinfo error]\r\n");
// 		return INVALID_SOCKET;
// 	}

	struct addrinfo *addr = m_checkGetAddr[nIndex].server_addr;  
	while(addr != NULL)
	{  
		if(addr->ai_family == nFamily && addr->ai_socktype == nType)
			break;
		addr = addr->ai_next;  
	}  
	if(addr == NULL)
	{
		JTRACE("CEasySocket::Connect error[no found addr]\r\n");
		return INVALID_SOCKET;
	}


	nSocket = socket(m_checkGetAddr[nIndex].server_addr->ai_family, m_checkGetAddr[nIndex].server_addr->ai_socktype, m_checkGetAddr[nIndex].server_addr->ai_protocol);
	//nSocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

	if(m_checkGetAddr[nIndex].server_addr)
	{
		freeaddrinfo(m_checkGetAddr[nIndex].server_addr);
		m_checkGetAddr[nIndex].server_addr = NULL;
	}

	if(nSocket == INVALID_SOCKET) return nSocket;

	serAddr.sin_family		= AF_INET;
	serAddr.sin_port		= htons(nPort);
	serAddr.sin_addr.s_addr	= DomainToIP(pAddr); 


	// 设置为非阻塞的socket 
	nRet = SetIoSock(nSocket, 1);
	if(nRet != 0) 
	{
		JTRACE("CEasySocket::Connect error[SetIoSock 1].......\r\n");
		nSocket  = INVALID_SOCKET;
		return nSocket;
	}
	// 超时时间  
	struct timeval tm;  
	tm.tv_sec  = 3;  
	tm.tv_usec = 0;  
	nRet = connect(nSocket, (sockaddr *)&serAddr, sizeof(sockaddr_in));
	if(nRet == -1)
	{
		FD_ZERO(&fdWrite);  
		FD_SET(nSocket, &fdWrite);  

		nRet = select(nSocket + 1, NULL, &fdWrite, NULL, &tm);
		if(nRet > 0) //没有错误(select错误或者超时) 
		{  
			getsockopt(nSocket, SOL_SOCKET, SO_ERROR, (char*)&nError, (socklen_t *)&optLen);   
			nRet = (0 != nError) ? -1 : 1;
		}  
	}

	if(nRet == 1)
	{
#if 0
		//设置为阻塞模式  
		nRet = SetIoSock(nSocket, 0);
		if(nRet != 0) 
		{
			JTRACE("CEasySocket::Connect error[SetIoSock 0].......\r\n");
			SAFE_CLOSE_SOCK(nSocket);
			return INVALID_SOCKET;
		}
#endif
		int flags =1;
		setsockopt(nSocket, IPPROTO_TCP, TCP_NODELAY, (const char *)&flags, sizeof(int));


	}
	else
	{
		JTRACE("CEasySocket::Connect error.......\r\n");
		SAFE_CLOSE_SOCK(nSocket);
		return INVALID_SOCKET;
	}
	
	JTRACE("CEasySocket::Connect success.......\r\n");
	return nSocket;
}

int		CEasySocket::SetIoSock(SOCKET nSocket, int nMode)
{
	int nRet = -1;
#if (defined _WIN32) || (defined _WIN64)
	unsigned long nModeTemp = nMode;
	nRet = ioctlsocket(nSocket, FIONBIO, &nModeTemp);	
#else
	int nModeTemp = fcntl(nSocket, F_GETFL, 0);                       // 获取文件的flags值
	if(nModeTemp < 0) return -1;
	if ( nMode ) nModeTemp |= O_NONBLOCK;
	else nModeTemp &= ~O_NONBLOCK;
	nRet = fcntl(nSocket, F_SETFL, nModeTemp);
#endif

	return nRet;
}
int	CEasySocket::Send(SOCKET nSocket, const void* pBuf, int nBufLen)
{
	int	nRet		= 0;
	int	nHasSend	= 0;
	
	if ( nSocket == INVALID_SOCKET || pBuf == NULL || nBufLen < 0) return -1;
	SetSendTimeOut(nSocket, 100);
	try
	{
		while(nHasSend < nBufLen)
		{
			nRet = send(nSocket,(const char*)(pBuf)+nHasSend,nBufLen-nHasSend,0);
			if(nBufLen - nHasSend > 4)
			{
				TEST_LOG_DATA("SYSTEMCALL","System send data -> socket = %d,nRet = %d,pBuf[0~3] = %c%c%c%c",nSocket,nRet,*((const char*)pBuf+nHasSend),
				*((const char*)pBuf+nHasSend+1),
				*((const char*)pBuf+nHasSend+2),
				*((const char*)pBuf+nHasSend+3));
			}
			else
			{
				TEST_LOG_DATA("SYSTEMCALL","System send data -> socket = %d,nRet = %d,pBuf[0] = %c",nSocket,nRet,*((const char*)pBuf+nHasSend));
			}
			if ( nRet<=0 ) 
			{
#ifdef WIN32
				int err = WSAGetLastError();
				if((err == WSAEINTR) || (err == WSAEWOULDBLOCK) )
#else
				if((errno == EINTR) ||(errno == EAGAIN) || (errno == EWOULDBLOCK))
#endif	
				{
					return -10;//缓冲区已满
				}
				else
				{
					return -1; //连接异常
				}

				break;
			}

			nHasSend += nRet;
		}
	}
	catch(...)
	{
		JTRACE("try-catch CEasySocket::Send\r\n");
		return -1;
	}

	return nHasSend;
}

int		CEasySocket::Recv(SOCKET nSocket, void* pBuf, int nRecvLen)
{
	int	nRet	= 0;
	int	nHasRecv= 0;

	if ( nSocket == INVALID_SOCKET || pBuf == NULL || nRecvLen < 0) return -1;
	//SetRecvTimeOut(nSocket, 100);
	TEST_LOG_DATA("SYSTEMCALL","System need recv data = %d",nRecvLen);
	try
	{
		while(nHasRecv < nRecvLen)
		{
			TEST_LOG_DATA("SYSTEMCALL","Start recv -> socket = %d,nHasRecv = %d,nRecvlen = %d",nSocket,nHasRecv,nRecvLen);
			nRet = recv(nSocket,(char*)(pBuf)+nHasRecv,nRecvLen-nHasRecv,0);
			if ( nRet<0 )
			{
				// 返回值<0时并且(errno == EINTR || errno == EWOULDBLOCK || errno == EAGAIN)的情况下认为连接是正常的,继续接收.
				// 只是阻塞模式下recv会阻塞着接收数据,非阻塞模式下如果没有数据会返回,不会阻塞着读,因此需要循环读取).
				int err = 0;
 				return -1; //阻塞直接返回
#ifdef WIN32
				err = WSAGetLastError();
				if((err == WSAEINTR) || (err == WSAEWOULDBLOCK) )
#else
				err = errno;
				if( (errno == EINTR) ||(errno == EAGAIN) || (errno == EWOULDBLOCK) )
#endif		
				{
						TEST_LOG_DATA("SYSTEMCALL","Recv sleep 10 ms,errno = %d,%s",err,strerror(err));
						JSleep(10);
				}
				else
				{
					TEST_LOG_DATA("SYSTEMCALL","Recv return -1,errno = %d,%s",err,strerror(err));
					return -1;
				}
			}
			else if (nRet == 0)
			{
				return -2;
			}
			else
			{
				nHasRecv += nRet;
				TEST_LOG_DATA("SYSTEMCALL","System recv data -> socket = %d,nRet = %d,nHasRecv = %d",nSocket,nRet,nHasRecv);
			}
		}
		TEST_LOG_DATA("SYSTEMCALL","CEasySocket::Recv Jump out while");
	}
	catch(...)
	{
		TEST_LOG_DATA("SYSTEMCALL","Recv return -1 by catch");
		JTRACE("try-catch CEasySocket::Recv\r\n");
		return -1;
	}

	return nHasRecv;
}

int		CEasySocket::Recv1(SOCKET nSocket, void* pBuf, int nRecvLen)
{
	int	nRet	= 0;
	int	nHasRecv= 0;

	if ( nSocket == INVALID_SOCKET || pBuf == NULL || nRecvLen < 0) return -1;
	SetRecvTimeOut(nSocket, 100);
	try
	{
		while(nHasRecv < nRecvLen)
		{
			nRet = recv(nSocket,(char*)(pBuf)+nHasRecv,nRecvLen-nHasRecv,0);
			if ( nRet<0 )
			{
				// 返回值<0时并且(errno == EINTR || errno == EWOULDBLOCK || errno == EAGAIN)的情况下认为连接是正常的,继续接收.
				// 只是阻塞模式下recv会阻塞着接收数据,非阻塞模式下如果没有数据会返回,不会阻塞着读,因此需要循环读取).
#ifdef WIN32
				int err = WSAGetLastError();
				if((err == WSAEINTR) || (err == WSAEWOULDBLOCK) )
#else
				if((errno == EINTR) ||(errno == EAGAIN) || (errno == EWOULDBLOCK))
#endif					
				{
					break;
				}
				else
				{
					return -1;
				}
			}
			else if (nRet == 0)
			{
				return -2;
			}
			nHasRecv += nRet;
		}
	}
	catch(...)
	{
		JTRACE("try-catch CEasySocket::Recv\r\n");
		return -1;
	}

	return nHasRecv;
}

SOCKET		CEasySocket::StartTCPServer(int nPort)
{
	int					optval = 0;
	sockaddr_in			sockIn = {0};
	
	SOCKET	sHandle = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
	sockIn.sin_family	= AF_INET;
	sockIn.sin_port		= htons(nPort);

	setsockopt(sHandle, SOL_SOCKET, SO_REUSEADDR, (const char *)&optval, sizeof(int));

	if(bind(sHandle, (struct sockaddr*)&sockIn, sizeof(sockIn)) != INVALID_SOCKET)
	{
		listen(sHandle, 5);
		return sHandle;
	}

	SAFE_CLOSE_SOCK(sHandle);

	return INVALID_SOCKET;
}

SOCKET	CEasySocket::AcceptTCPClient(SOCKET sListen, int nTimeOut, char *strAddr)
{
	int				nRet		= 0;
	sockaddr_in		sockIn		= {0};
	SOCKET			sClient		= INVALID_SOCKET;
	int				nAddrSize	= sizeof(sockaddr_in);

	nRet = WaitSocketData(sListen, nTimeOut, TRUE);

	if(nRet == 0 )
	{
        sClient = accept(sListen, (struct sockaddr *)&sockIn, (socklen_t *)&nAddrSize);
		SetRecvSendBufferSize(sClient);
		if(strAddr != NULL)
		{
			sprintf(strAddr, "%s", inet_ntoa(sockIn.sin_addr));
		}
	}

	return sClient;

}


DWORD CEasySocket::DomainToIP(const char* szDomain)
{
	DWORD			dwRet		= 0;
	struct hostent*	pHostEnt	= NULL;

	dwRet = inet_addr(szDomain);
	if(dwRet == INADDR_NONE)
	{
		pHostEnt = NULL;
		pHostEnt = gethostbyname(szDomain);
		if(pHostEnt != NULL)
		{
			dwRet = *((unsigned long*)pHostEnt->h_addr_list[0]);
		}
		else
		{
			return 0;
		}
	}

	return dwRet;
}


int CEasySocket::WaitSocketData(SOCKET socket,int timeout,BOOL bWaitToRecv)
{
	int    nCount = 0;
	fd_set fdWait = {0};
	FD_ZERO(&fdWait);
	timeval tmv ;
	tmv.tv_sec = timeout/1000;
	tmv.tv_usec= timeout%1000;
	if(socket == INVALID_SOCKET)
		return -1 ;

	FD_SET(socket,&fdWait);

	if(bWaitToRecv)
		nCount = select(socket,&fdWait,NULL,NULL,&tmv) ;
	else
		nCount = select(socket,NULL,&fdWait,NULL,&tmv) ;

	if (nCount<=0 || FD_ISSET(socket,&fdWait)==FALSE)
	{
		return -1;
	}

	return 0;
}


int CEasySocket::SetRecvSendBufferSize(SOCKET hSocket, DWORD dwBufferSize)
{

	if (hSocket == INVALID_SOCKET)
		return -1;


	setsockopt(hSocket, SOL_SOCKET, SO_SNDBUF, (const char *) &dwBufferSize, sizeof(dwBufferSize));
	setsockopt(hSocket, SOL_SOCKET, SO_RCVBUF, (const char *) &dwBufferSize, sizeof(dwBufferSize));

	return 0;
}


int CEasySocket::GetSockType(SOCK_TYPE type, int *family, int *stype, int *protocol)
{
	switch(type)
	{
	case SOCK_TCP4:
		*family = AF_INET;
		*stype = SOCK_STREAM;
		*protocol = 0;
		break;

	case SOCK_UDP4:
		*family = AF_INET;
		*stype = SOCK_DGRAM;
		*protocol = 0;
		break;	

	case SOCK_TCP6:
		*family = AF_INET6;
		*stype = SOCK_STREAM;
		*protocol = IPPROTO_TCP;
		break;	

	case SOCK_UDP6:	
		*family = AF_INET6;
		*stype = SOCK_DGRAM;
		*protocol = IPPROTO_UDP;
		break;

	default:
		return -1;
	}
	return 0;
}

int CEasySocket::IsReadyToRead( SOCKET nSocket ,int timeout)
{
	int rlt = 0;
	fd_set fdreads,fdwrites;
	int maxfd = nSocket + 1;
	struct timeval tm = { timeout/1000,(timeout%1000)*1000};
	//clear and add socket to fd_set
	FD_ZERO(&fdreads);
	FD_SET(nSocket,&fdreads);
	//
	FD_ZERO(&fdwrites);
	FD_SET(nSocket,&fdwrites);

	//return 0 -> timeout, 1 -> ready to read,-1 -> error
	switch ( select(maxfd,&fdreads,NULL,NULL,&tm) )
	{
	case -1:
		rlt = -1;
		break;
	case 0:
		rlt = 0;
		break;
	default:
		{
			if(FD_ISSET(nSocket,&fdreads))	//ready to read
			{
				rlt = 1;
			}
			else
			{
				PrintLastErrorToScreen();
			}
		}
		break;
	}
	
	return rlt;
}

int CEasySocket::IsReadyToWrite( SOCKET nSocket ,int timeout)
{
	int rlt = 0;
	fd_set fdreads,fdwrites;
	int maxfd = nSocket + 1;
	struct timeval tm = { timeout/1000,(timeout%1000)*1000};
	//clear and add socket to fd_set
	FD_ZERO(&fdreads);
	FD_SET(nSocket,&fdreads);
	//
	FD_ZERO(&fdwrites);
	FD_SET(nSocket,&fdwrites);

	//return 0 -> timeout, 1 -> ready to read, 2 -> ready to write, 3 -> ready to read and write,-1 -> error

	switch ( select(maxfd,NULL,&fdwrites,NULL,&tm) )
	{
	case -1:
		rlt = -1;
		break;
	case 0:
		rlt = 0;
		break;
	default:
		{
			if(FD_ISSET(nSocket,&fdwrites))	//ready to write
			{
				rlt = 1;
			}
			else
			{
				PrintLastErrorToScreen();
			}
		}
		break;
	}

	return rlt;
}

int CEasySocket::PrintLastErrorToScreen()
{
#ifdef WIN32
	printf("last error = %d,\n",WSAGetLastError());
#else
	printf("last error =  %d,%s\n",errno,strerror(errno));
#endif
	return 0;
}



int		CEasySocket::DealWithMessage(char *pBuf, int nBufLen)
{
	cJSON* pRetRoot = cJSON_Parse( pBuf);

	cJSON* type =cJSON_GetObjectItem(pRetRoot, "MessageType");

	return 0;
}

int 	CEasySocket::SetKey(unsigned char *pKey, int nKeyLen)
{
	
	SAFE_DELETE(m_pKeyData);

	if(!pKey || nKeyLen < 1) return 0;

	m_pKeyData = new unsigned char[nKeyLen];

	memcpy(m_pKeyData, pKey, nKeyLen);

	return 0;
}