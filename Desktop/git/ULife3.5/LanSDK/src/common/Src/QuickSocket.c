#include "QuickSocket.h"
#include "ws_socket.h"
#include "ThreadUtil.h"
#include "DebugPrint.h"

#ifdef WIN32
#include <ws2def.h>
#include <WS2TCPIP.H>
#pragma comment(lib, "ws2_32.lib")
#else
#include <errno.h>
#include <unistd.h>
#include <sys/select.h>
#include <sys/time.h>
#include<netinet/tcp.h>
#endif

#define MAX_SERSOCKETCOUNT 2048

static int   s_bSockStarup = 0 ;

int StartUpSock()
{
	if(s_bSockStarup)
		return 1 ;
	WS_socket_init();
	s_bSockStarup = 1;
	return 1 ;
}

void CleanupSock()
{
#ifdef WIN32
	WSACleanup() ;
#endif
	s_bSockStarup = 0 ;
}

int SetRecvSendBufferSize(int hSocket, int dwBufferSize)
{
	int sizebuffer = 0;
	int len = sizeof(int);
	int rlt = 0;
	if (hSocket == -1)
		return 0;
	rlt = WS_setsockopt(hSocket, SOL_SOCKET, SO_SNDBUF, (char*)&dwBufferSize, sizeof(int));
	rlt = WS_setsockopt(hSocket, SOL_SOCKET, SO_RCVBUF, (char*)&dwBufferSize, sizeof(int));

	rlt = getsockopt(hSocket, SOL_SOCKET, SO_RCVBUF, (char*)&sizebuffer,&len);
	pr_debug("current SO_RCVBUF SIZE = %d,return = %d\n",sizebuffer,rlt);
	return 1;
}

int SetSendTimeOut(int hSocket, int dwTimeOut)
{
	if (hSocket == -1)
		return 0;
	WS_settimeout(hSocket, SOL_SOCKET, SO_SNDTIMEO, dwTimeOut);
	return 1;
} 

int SetRecvTimeOut(int hSocket, int dwTimeOut)
{
	if (hSocket == -1)
		return 0;
	WS_settimeout(hSocket, SOL_SOCKET, SO_RCVTIMEO, dwTimeOut);
	return 1;
}

int WaitSocketData(int socket,int timeout,int bWaitToRecv)
{
	int    nCount = 0;
	fd_set fdWait = {0};
	struct timeval tmv ;
	tmv.tv_sec = timeout/1000;
	tmv.tv_usec= timeout%1000;
	if(socket == -1)
		return 0 ;

	FD_ZERO(&fdWait);
	FD_SET(socket,&fdWait);

	if(bWaitToRecv)
		nCount = WS_select(socket,&fdWait,NULL,NULL,&tmv) ;
	else
		nCount = WS_select(socket,NULL,&fdWait,NULL,&tmv) ;

// 	int iRet = 0;
// 	int len = 0;
// 	if((nCount <= 0 || !FD_ISSET(socket,&fdWait)))
// 		if (getsockopt(socket, SOL_SOCKET, SO_ERROR, (char*)&iRet, &len) == -1)
// 			return 1;
// 		else
// 			return 0;
// 	else
// 		return 1;
	return (nCount <= 0 || !FD_ISSET(socket,&fdWait)) ? 0:1;
}

//#define  TCP_NOBLOCK_SWITCH

int QuickConnectToTCPNew(const char *pAddr, int nPort, int bTcp,int dwTimeOut,int bBlock)
{
	struct sockaddr_in		serAddr		= {0};
	int				nRet		= -1;
	int				nError		= -1;
	int				nStdIn		= 0;
	int				nMaxFd		= 0;
	int				optLen		= sizeof(int);
	int				nFamily		= 0;
	int				nType		= 0;
	int				nProtocol	= 0;
	fd_set			fdWrite;
	char			strPort[8]	= {0};
	int			nSocket		= -1;
	struct addrinfo addrCriteria;
	struct addrinfo *server_addr = NULL;
	struct addrinfo *addr = NULL;

	memset(&addrCriteria, 0, sizeof(struct addrinfo));
	sprintf(strPort, "%d", nPort);

	addrCriteria.ai_family = AF_UNSPEC;
	if(bTcp)
		addrCriteria.ai_socktype = SOCK_STREAM;
	else
		addrCriteria.ai_socktype = SOCK_DGRAM;

	nRet = getaddrinfo(pAddr, strPort, &addrCriteria, &server_addr);
	if(nRet != 0)
	{
		printf("CEasySocket::Connect error[getaddrinfo error]\r\n");
		return -1;
	}

	addr = server_addr;
	while (addr != NULL) 
	{
		nSocket = socket(server_addr->ai_family, server_addr->ai_socktype, server_addr->ai_protocol);
		if(nSocket != -1)
		{
			SetNoDelay(nSocket);
			if(bBlock)
				SetRecvSendBufferSize(nSocket,0x10000);
			else
				SetRecvSendBufferSize(nSocket,220000);
			nRet = WS_setblocking(nSocket, 0);
			if(nRet == 0)
			{
				struct timeval tm;
				tm.tv_sec  = dwTimeOut/1000;
				tm.tv_usec = (dwTimeOut%1000)*1000;
				nRet = connect(nSocket, addr->ai_addr, addr->ai_addrlen);
				if(nRet == -1)
				{
#ifdef WIN32
					if(WSAGetLastError() != WSAEWOULDBLOCK)
					{
						printf("when connect non-block failed ,return errno is not WSAEWOULDBLOCK,%d\n",WSAGetLastError());
						WS_close(nSocket);
						nSocket = -1;
						addr = addr->ai_next;
						continue;
					}
#else
					printf("connect returned ,EINPROGRESS = %d,errno = %d\n",EINPROGRESS,errno);
					if(errno != EINPROGRESS)
					{
						printf("linux when connect non-block ,return errno is not EINPROGRESS\n");
						WS_close(nSocket);
						nSocket = -1;
						addr = addr->ai_next;
						continue;
					}
#endif
					FD_ZERO(&fdWrite);
					FD_SET(nSocket, &fdWrite);
					nRet = select(nSocket + 1, NULL, &fdWrite, NULL, &tm);
					if(nRet > 0) //
					{
						getsockopt(nSocket, SOL_SOCKET, SO_ERROR, (char*)&nError, (socklen_t *)&optLen);
						nRet = (0 != nError) ? -1 : 1;
					}
				}
				if(nRet == 1)
				{
					nRet = WS_setblocking(nSocket, bBlock);	
					if(nRet == 0)
						break;
				}
				WS_close(nSocket);
				nSocket = -1;
			}

			addr = addr->ai_next;
		}
	}
	freeaddrinfo(server_addr);

	return nSocket;
}

int  QuickConnectToTCP(int wServerPort,const char* lpServerIP,int dwTimeOut/*=2000*/)
{
	if(lpServerIP == NULL)
		return -1;
	else
		return QuickConnectToTCPNew(lpServerIP,wServerPort,1,dwTimeOut,1);
#if 0
	int  nSocket = WS_socket(AF_INET,SOCK_STREAM,0);
	struct sockaddr_in sAddress={0};
	struct sockaddr_in *paddrs = NULL;
	int addrcount = 0;
	int i = 0;

	if (nSocket == -1) 
		return -1;
	SetRecvSendBufferSize(nSocket,0x10000);
	if (WS_setblocking(nSocket,0) != 0)
	{
		WS_close(nSocket);
		return -1;
	}

	sAddress.sin_addr.s_addr = inet_addr("127.0.0.1");
	if(lpServerIP != NULL)
	{
		WS_gethostbyname(lpServerIP,wServerPort,&paddrs,&addrcount);
	}
	else
	{
		WS_close(nSocket);
		return -1;
	}


	for (i = 0; i < addrcount; i++)
	{
		memcpy(&sAddress,paddrs+i,sizeof(struct sockaddr_in));
		printf("current ip = %x\n",sAddress.sin_addr.s_addr);
#ifdef WIN32
		sAddress.sin_family = AF_INET;
		sAddress.sin_port = htons(wServerPort);
#endif

		printf("connect to ip = %s\n",inet_ntoa(sAddress.sin_addr));
		if (WS_connect(nSocket,(WS_SOCKADDR*)&sAddress,sizeof(sAddress)) == -1)
		{
#ifndef WIN32
			printf("connect returned ,EINPROGRESS = %d,errno = %d\n",EINPROGRESS,errno);
			if(errno != EINPROGRESS)
			{
				printf("linux when connect non-block ,return errno is not EINPROGRESS\n");
				continue;
			}
#endif
			fd_set fds;
			int errSelect = 0;
			struct timeval tm = {dwTimeOut/1000,dwTimeOut%1000};
			FD_ZERO(&fds);
			FD_SET(nSocket,&fds);

			//errSelect = WS_select(0,NULL,&fds,NULL,&tm);
#ifdef WIN32
			errSelect = WS_select(0,NULL,&fds,NULL,&tm);
			if (errSelect == 1)
#else
			errSelect = WS_select(nSocket,NULL,&fds,NULL,&tm);
			if(errSelect >= 0)
#endif
			{
				if(paddrs)
					free(paddrs);

				printf("select ok when connect,nSocket = %d\n",nSocket);
				WS_setblocking(nSocket,1);
				return nSocket;
			}
			if(errSelect <= 0)
				printf("select timeout or error when connect\n");
		}
		else
		{
			if(paddrs)
				free(paddrs);

			WS_setblocking(nSocket,1);
			return nSocket;	
		}
	}
	if(paddrs)
		free(paddrs);
	WS_close(nSocket);
	nSocket = -1;

	return -1;
#endif
}


// s_wPortDeviceSet, (char *)&Infos,sizeof(CamNetParam), 0, NULL
int  QuickSendToUDP(int wPort, const char* szDataBuffer, int dwSize, int bRetSock,const char*  lpServerIP)
{
	struct sockaddr_in addr_to={0};
	int      sockUDP = -1;
	int i = 0;
	// get host IP list

	char szHostName[1024];
	memset(szHostName, 0, 1024);
	//WS_gethostname(szHostName, 1024);

	if( gethostname(szHostName, 1023) == 0 )
	{
#ifndef WIN32
		// 发送端套接字
		struct sockaddr_in addr_from={0};
		int         nLen = 0;

		sockUDP = WS_socket(AF_INET,SOCK_DGRAM,0);
		//SetRecvSendBufferSize(sockUDP,0x10000);
		// 发送端地址		
		addr_to.sin_family = AF_INET;
		addr_to.sin_port   = htons(wPort);
		addr_to.sin_addr.s_addr = htonl(INADDR_BROADCAST);

		printf("call gethostbyname(),%s\n",lpServerIP);
		int bEnabel = 1;
		WS_setsockopt(sockUDP, SOL_SOCKET, SO_BROADCAST, (char*) &bEnabel, sizeof(bEnabel));

		// 本地 地址
		addr_from.sin_family = AF_INET;
		addr_from.sin_port = 8629;	// DEVICE_GETPORT_default 监听端口
		
		// bind it
		printf("bind to ip = %s\n",inet_ntoa(addr_from.sin_addr));
		bind(sockUDP, (struct sockaddr*)&addr_from, sizeof(addr_from));

		nLen    = sizeof(struct sockaddr_in);
		printf("sendto to ip = %s\n",inet_ntoa(addr_to.sin_addr));
		sendto(sockUDP, szDataBuffer, dwSize, 0, (struct sockaddr *)&addr_to, nLen);
		//////////////////////////////////////////////////////////////////////////

		if(sockUDP != -1)
		{
			WS_close(sockUDP);
			sockUDP = -1;
		}
#else

		struct hostent * pHost = gethostbyname(szHostName); 
		if(!pHost)
			return sockUDP;

		for( i = 0; pHost->h_addr_list[i]!= NULL; i++ )  
		{
			// 发送端套接字
			struct sockaddr_in addr_from={0};
			int         nLen = 0;
			struct hostent* ptmp = NULL;

			sockUDP = WS_socket(AF_INET,SOCK_DGRAM,0);
			SetRecvSendBufferSize(sockUDP,0x10000);
			// 发送端地址		
			addr_to.sin_family = AF_INET;
			addr_to.sin_port   = htons(wPort);
			addr_to.sin_addr.s_addr = htonl(INADDR_BROADCAST);
			
			printf("call gethostbyname(),%s\n",lpServerIP);
			if(lpServerIP != NULL)
				ptmp = gethostbyname(lpServerIP);
			printf("end call gethostbyname()\n");
			if(ptmp == NULL)
			{
				int bEnabel = 1;
				WS_setsockopt(sockUDP, SOL_SOCKET, SO_BROADCAST, (char*) &bEnabel, sizeof(bEnabel));
			}
			else
			{
				printf("%s\n",ptmp->h_addr_list[0]);
				memcpy(&addr_to.sin_addr,ptmp->h_addr_list[0],4);
			}
			
			// 本地 地址
			addr_from.sin_family = AF_INET;
			addr_from.sin_port = 8629;	// DEVICE_GETPORT_default 监听端口
			memcpy(&addr_from.sin_addr,pHost->h_addr_list[i],4);
			// bind it
			printf("bind to ip = %s\n",inet_ntoa(addr_from.sin_addr));
			bind(sockUDP, (struct sockaddr*)&addr_from, sizeof(addr_from));
			
			nLen    = sizeof(struct sockaddr_in);
			printf("sendto to ip = %s\n",inet_ntoa(addr_to.sin_addr));
			sendto(sockUDP, szDataBuffer, dwSize, 0, (struct sockaddr *)&addr_to, nLen);
			//////////////////////////////////////////////////////////////////////////

			if(sockUDP != -1)
			{
				WS_close(sockUDP);
				sockUDP = -1;
			}
		}
#endif
	}

	return bRetSock ;
}

int  AcceptTCPClient(int nListenSock,int timeout, struct sockaddr_in *pInAddr)
{
	int  nAddrSize   = sizeof(struct sockaddr_in) ;
	int nNewSock  = -1 ;
	struct sockaddr_in cin  = {0};
	if(WaitSocketData(nListenSock,timeout,1))
	{
		nNewSock = accept( nListenSock, (struct sockaddr *)&cin, &nAddrSize);
		SetRecvSendBufferSize(nNewSock,0x10000);
		if(pInAddr != NULL)
			memcpy(pInAddr,&cin,nAddrSize);
	}
	return nNewSock ;
}

int QuickStartTCPServer(int wListenPort)
{
	int    nReuse = 1 ;
	struct sockaddr_in sin = {0} ;
	int nLSock = WS_socket(AF_INET, SOCK_STREAM, IPPROTO_TCP); 

	sin.sin_family= AF_INET ;
	sin.sin_port  = htons(wListenPort) ;
	WS_setsockopt(nLSock,SOL_SOCKET,SO_REUSEADDR,(char *)&nReuse,sizeof(int));
	if(bind(nLSock,(struct sockaddr *)&sin,sizeof(sin)) != -1)
	{
		listen(nLSock,5);

		return nLSock ;
	}
	WS_close(nLSock) ;
	return -1 ;
}

int  QuickStartUDPServer(int wListenPort,int bBoradCast)
{
	int     nReuse  = 1 ;
	struct sockaddr_in sin = {0} ;
	int dwBufferSize = 220*1024;
	int nLSock = WS_socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP); 

	sin.sin_family= AF_INET ;
	sin.sin_port  = htons(wListenPort) ;
	sin.sin_addr.s_addr = htonl(INADDR_ANY);

	if(bBoradCast)
		WS_setsockopt(nLSock,SOL_SOCKET,SO_BROADCAST,(char *)&nReuse,sizeof(int));

	WS_setsockopt(nLSock,SOL_SOCKET,SO_REUSEADDR,(char *)&nReuse,sizeof(int));

	WS_setsockopt(nLSock, SOL_SOCKET, SO_RCVBUF, (char*)&dwBufferSize, sizeof(int));
	//WS_setsockopt(nLSock,SOL_SOCKET,SO_OOBINLINE,(char *)&nReuse,sizeof(int));
	if(bind(nLSock,(struct sockaddr *)&sin,sizeof(sin)) != -1)
	{
		return nLSock ;
	}
	//TRACE("\n^^^^ QuickStartUDPServer  ERROR: %d ^^^^\n\n",GetLastError()) ;
	WS_close(nLSock) ;
	return -1 ;
}

int ForceSend(int sock,void *pBuf,int dwLen,int dwTimeOut,int bUDPFlag, struct sockaddr_in *pCLAddr)
{
	int dwToSendLen = dwLen;
	int dwSendSum = 0 ;
	int   nSendLen  = 0 ;
	char  *pszBuf = (char *)pBuf ;
	SetSendTimeOut(sock,dwTimeOut);
	if(dwLen == 0)
		dwToSendLen = strlen(pszBuf);
	while(1)
	{
		if(bUDPFlag)
		{
			int nLen = sizeof(struct sockaddr) ;
			nSendLen = sendto(sock,pszBuf + dwSendSum,dwToSendLen-dwSendSum,0,(struct sockaddr *)pCLAddr,nLen);
		}
		else
		{
			nSendLen = send(sock,pszBuf + dwSendSum,dwToSendLen-dwSendSum,0) ;
		}
		printf("send buf = %s,sendlen = %d\n",pszBuf,nSendLen);

		if(nSendLen != -1)
		{
			dwSendSum += nSendLen;
			if(dwToSendLen <= dwSendSum)
				break;
			continue;
		}
		break ;
	}
	
	return dwSendSum ;
}

int ForceRecvNonBlock(int sock,void *pBuf,int dwLen,int dwTimeOut,int bUDPFlag, struct sockaddr_in *pCLAddr)
{
	int dwRecvSum = 0 ;
	int   nRecvLen  = 0 ;
	char* szBuf = (char*)pBuf;

	if( -1==sock || dwLen==0 || pBuf==NULL)
		return 0 ;

	//	SetRecvSendBufferSize(sock,0x40000);

	if (bUDPFlag)
	{
		struct sockaddr_in addrFrom = {0};
		int nLen = sizeof(addrFrom);

		SetRecvTimeOut(sock,dwTimeOut);

		while (dwRecvSum < dwLen)
		{
			printf("start recvfrom data\n");
			nRecvLen = recvfrom(sock,szBuf+dwRecvSum,dwLen-dwRecvSum,0,(struct sockaddr*)&addrFrom,&nLen);
			printf("nRcvlen = %d\n",nRecvLen);
			if (nRecvLen == -1) return -1;
			if (pCLAddr) memcpy(pCLAddr,&addrFrom,sizeof(addrFrom));
			dwRecvSum += nRecvLen;
		}
	}
	else
	{
		struct timeval timeout;
		timeout.tv_sec = dwTimeOut/1000;
		timeout.tv_usec = (dwTimeOut%1000)*1000;
		while (dwRecvSum < dwLen)
		{
  			fd_set frds;
			int ret;
  			FD_ZERO(&frds);
  			FD_SET(sock,&frds);
			printf("start recv data\n");
  			//WS_select 返回0，表示超时，-1 表示出错，其他数字 表示包含在fd_set结构体中的socket是处于ready状态
  			ret = WS_select(sock,&frds,NULL,NULL,&timeout);
 // 			ret = 0 // socket 没有数据
 // 			ret = 1; // recv = 0, socket断开
			if(ret > 0) //有数据
				nRecvLen = recv(sock,szBuf+dwRecvSum,dwLen-dwRecvSum,0);
			else if (ret <= 0) //超时或者失败
				return -1;
			//printf("----recv buf = %s,recvlen = %d----\n",szBuf,nRecvLen);

			//如果recv返回错误，直接return掉
			if (nRecvLen <= 0) 
				return -1;

			dwRecvSum += nRecvLen;
		}

	}
	// 	TRACE("\n%d",dwRecvSum);
	return dwRecvSum ;
}

int ForceRecv(int sock,void *pBuf,int dwLen,int dwTimeOut,int bUDPFlag, struct sockaddr_in *pCLAddr)
{
	int dwRecvSum = 0 ;
	int   nRecvLen  = 0 ;
	char* szBuf = (char*)pBuf;

	if( -1==sock || dwLen==0 || pBuf==NULL)
		return 0 ;

#ifdef TCP_NOBLOCK_SWITCH
	return ForceRecvNonBlock(sock,pBuf,dwLen,dwTimeOut,bUDPFlag,pCLAddr);
#endif

 	SetRecvTimeOut(sock,dwTimeOut);
//	SetRecvSendBufferSize(sock,0x40000);

	if (bUDPFlag)
	{
		struct sockaddr_in addrFrom = {0};
		int nLen = sizeof(addrFrom);
		while (dwRecvSum < dwLen)
		{
			printf("start recvfrom data\n");
			nRecvLen = recvfrom(sock,szBuf+dwRecvSum,dwLen-dwRecvSum,0,(struct sockaddr*)&addrFrom,&nLen);
			printf("nRcvlen = %d\n",nRecvLen);
			if (nRecvLen == -1) return -1;
			if (pCLAddr) memcpy(pCLAddr,&addrFrom,sizeof(addrFrom));
			dwRecvSum += nRecvLen;
		}
	}
	else
	{
		while (dwRecvSum < dwLen)
		{
			printf("start recv data\n");
//  			fd_set frds;
//  			FD_ZERO(&frds);
//  			FD_SET(sock,&frds);
//  			timeval timeout;
//  			timeout.tv_sec = dwTimeOut/1000;
//  			timeout.tv_usec = dwTimeOut%1000;
//  			//WS_select 返回0，表示超时，-1 表示出错，其他数字 表示包含在fd_set结构体中的socket是处于ready状态
//  			int ret = WS_select(sock,&frds,NULL,NULL,&timeout);
// // 			ret = 0 // socket 没有数据
// // 			ret = 1; // recv = 0, socket断开
			nRecvLen = recv(sock,szBuf+dwRecvSum,dwLen-dwRecvSum,0);
			//printf("----recv buf = %s,recvlen = %d----\n",szBuf,nRecvLen);
			
			//如果recv返回错误，直接return掉
			if (nRecvLen == -1) 
				return -1;

// 			if(nRecvLen == 0)
// 			{
// 				fd_set frds;
// 				int ret = 0;
// 				struct timeval timeout;
// 				FD_ZERO(&frds);
// 				FD_SET(sock,&frds);
// 				timeout.tv_sec = dwTimeOut/1000;
// 				timeout.tv_usec = dwTimeOut%1000;
// 				//WS_select 返回0，表示超时，-1 表示出错，其他数字 表示包含在fd_set结构体中的socket是处于ready状态
// 				ret = WS_select(sock,&frds,NULL,NULL,&timeout);
// 
// 	 			if(ret == 1)	//如果sock处于ready状态，但是接收到的数据为0，表示对端断开，直接返回
// 	 				return -1;
// 	 			else if(ret == 0)				//如果超时，直接返回
// 	 				return -1;	
// 	 			else if(ret == -1)	//如果WS_select发生错误，直接返回 
// 	 				return -1;
// 			}
// 			if(ret == 1 && nRecvLen == 0)	//如果sock处于ready状态，但是接收到的数据为0，表示对端断开，直接返回
// 				return -1;
// 			else if(ret == 0)				//如果超时，直接返回
// 				return -1;	
// 			else if(ret == -1)	//如果WS_select发生错误，直接返回 
// 				return -1;
			//其他情况，继续读取

			dwRecvSum += nRecvLen;
		}

	}
// 	TRACE("\n%d",dwRecvSum);
	return dwRecvSum ;
}


void  NotifySocketToEnd(int wPort, int bIsTcpMode)
{
	char szBuffer[128] = "NotifySocketToEnd";

	if (bIsTcpMode)
	{
		int nSocket = QuickConnectToTCP(wPort,"127.0.0.1",2000);
		if (nSocket != -1)
		{
			send(nSocket, szBuffer, sizeof(szBuffer), 0);
			WS_close(nSocket);
		}
	}
	else
	{
		QuickSendToUDP(wPort, szBuffer, sizeof(szBuffer),0,"127.0.0.1");
	}
}

int WaitSocketsData(int socket, int socketList[],int socketCount,int timeout,int bWaitToRecv/*=1*/ )
{
	int    nCount = 0;
	fd_set fdWait = {0};
	struct timeval tmv ;
	int i = 0;
	int bHasOneAtLeast = 0;
	tmv.tv_sec = timeout/1000;
	tmv.tv_usec= timeout%1000;

	FD_ZERO(&fdWait);
	for (i = 0; i < socketCount ; i++)
	{
		if(socketList[i] == -1)
			continue;
		bHasOneAtLeast = 1;
		FD_SET(socketList[i],&fdWait);
	}
	if(!bHasOneAtLeast)
		return 0;

	if(bWaitToRecv)
		nCount = WS_select(socket,&fdWait,NULL,NULL,&tmv) ;
	else
		nCount = WS_select(socket,NULL,&fdWait,NULL,&tmv) ;

	return (nCount <= 0 || !FD_ISSET(socket,&fdWait)) ? 0:1;

// 	if(socket == -1)
// 		return 0 ;

// 	FD_ZERO(&fdWait);
// 	FD_SET(socket,&fdWait);
// 
// 	if(bWaitToRecv)
// 		nCount = WS_select(0,&fdWait,NULL,NULL,&tmv) ;
// 	else
// 		nCount = WS_select(0,NULL,&fdWait,NULL,&tmv) ;
// 
// 	return (nCount <= 0 || !FD_ISSET(socket,&fdWait)) ? 0:1;
}

void StopSocket( int nSock )
{
	WS_close(nSock);
}

int QuickCheckIsReadytoWriteorRead( int sockfd,int timeout ,int onlyRead)
{
	int rlt = 0;
	fd_set fdreads,fdwrites;
	int maxfd = sockfd + 1;
	struct timeval tm = { timeout/1000,(timeout%1000)*1000};
	//clear and add socket to fd_set
	if(sockfd == -1)
		return -1;
	FD_ZERO(&fdreads);
	FD_SET(sockfd,&fdreads);
	//
	FD_ZERO(&fdwrites);
	FD_SET(sockfd,&fdwrites);

	//return 0 -> timeout, 1 -> ready to read, 2 -> ready to write, 3 -> ready to read and write,-1 -> error
	if(!onlyRead)
	{
		switch ( select(maxfd,&fdreads,&fdwrites,NULL,&tm) )
		{
		case -1:
			rlt = -1;
			break;
		case 0:
			rlt = 0;
			break;
		default:
			{
				if(FD_ISSET(sockfd,&fdreads))	//ready to read
					rlt = 1;
				if (FD_ISSET(sockfd,&fdwrites)) //read to write
				{
					if(rlt == 1)	//ready to read and write
						rlt = 3;
					else
						rlt = 2;		//ready to write
				}
			}
			break;
		}
	}
	else
	{
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
				if(FD_ISSET(sockfd,&fdreads))	//ready to read
					rlt = 1;
				else
				{
#ifdef WIN32
					printf("FD_ISSET read error %d,\n",WSAGetLastError());
#else
					printf("FD_ISSET read error %d,\n",errno);
#endif
				}
			}
			break;
		}
	}

	return rlt;
}

int QuickConnectToTCPNonBlock( int wServerPort,const char* lpServerIP,int dwTimeOut )
{
	int  nSocket = -1;
	struct sockaddr_in sAddress={0};	
	struct sockaddr_in *paddrs = NULL;
	int addrcount = 0;
	int i = 0;

	if (lpServerIP == NULL)
	{
		return -1;
	}
 	else
 	{
 		return QuickConnectToTCPNew(lpServerIP,wServerPort,1,dwTimeOut,0);
 	}
	
	nSocket = WS_socket(AF_INET,SOCK_STREAM,0);
	if (nSocket == -1) 
		return -1;
	SetRecvSendBufferSize(nSocket,220000);
	if (WS_setblocking(nSocket,0) != 0)
	{
		WS_close(nSocket);
		return -1;
	}

	//sAddress.sin_addr.s_addr = inet_addr("127.0.0.1");
	WS_gethostbyname(lpServerIP,wServerPort,&paddrs,&addrcount);

	SetNoDelay(nSocket);

	for (i = 0; i < addrcount; i++)
	{
		memcpy(&sAddress,paddrs+i,sizeof(struct sockaddr_in));
		printf("current ip = %x\n",sAddress.sin_addr.s_addr);
#ifdef WIN32
 		sAddress.sin_family = AF_INET;
 		sAddress.sin_port = htons(wServerPort);
#endif
		printf("connect to ip = %s\n",inet_ntoa(sAddress.sin_addr));
		if (WS_connect(nSocket,(WS_SOCKADDR*)&sAddress,sizeof(sAddress)) == -1)
		{
// 			fd_set fds;
// 			int errSelect = 0;
// 			int maxfd = nSocket + 1;
// 			struct timeval tm = {dwTimeOut/1000,dwTimeOut%1000};

#ifdef WIN32
			if(WSAGetLastError() != WSAEWOULDBLOCK)
			{
				printf("when connect non-block failed ,return errno is not WSAEWOULDBLOCK,%d\n",WSAGetLastError());
				continue;
			}
#else
			printf("connect returned ,EINPROGRESS = %d,errno = %d\n",EINPROGRESS,errno);
			if(errno != EINPROGRESS)
			{
				printf("linux when connect non-block ,return errno is not EINPROGRESS\n");
				continue;
			}
#endif
// 			FD_ZERO(&fds);
// 			FD_SET(nSocket,&fds);
// 
// 			errSelect = WS_select(maxfd,NULL,&fds,NULL,&tm);
// 			if(errSelect > 0)
 			{
				int checkrlt = QuickCheckIsReadytoWriteorRead(nSocket,dwTimeOut,0);
				if(checkrlt == 2 || checkrlt == 3)
				{
					//可写，表示连接建立成功；
					//既可独又可写，需要检测是否连接建立后，对端发送了数据过来，此时如果对端发送数据过来，连接建立成功
					//否则，连接建立失败，（由于有未决的错误，导致既可读又可写）
					if(checkrlt == 3)
					{
						int rlt = WS_connect(nSocket,(WS_SOCKADDR*)&sAddress,sizeof(sAddress));
#ifdef WIN32
						//mdns上说，当用非阻塞的套接字尝试完成一次连接时，再次针对该套接字调用connect，将会失败，
						//并且返回错误码为WSAEISCONN时，连接成功，错误码为WSAEALREADY时，连接失败
						if (rlt == -1 && WSAGetLastError() != WSAEISCONN)
						{
							printf("connect failed or timeout\n");
							continue;
						}
#else
						//Unix Network Programming,提供了一种方法，但经验证在linux上无效
						//如果连接建立是成功的，则通过getsockopt(sockfd,SOL_SOCKET,SO_ERROR,(char *)&error,&len) 获取的error 值将是0
						//另一种有效的判断方法，再次调用connect，相应返回失败，如果错误errno是EISCONN，表示socket连接已经建立，否则认为连接失败
						if (rlt == -1 && errno != EISCONN)
						{
							printf("connect failed or timeout\n");
							continue;
						}
#endif
					}
					if(paddrs)
						free(paddrs);

					printf("connect success,nSocket = %d\n",nSocket);
					return nSocket;
				}
				else
				{
					printf("connect failed or timeout,0 -> timeout, -1 -> failed!,error = %d\n",checkrlt);
					continue;
				}
 			}
// 			else
// 			{
// 				printf("connect failed or timeout\n");
// 				continue;
// 			}
		}
		else
		{
			if(paddrs)
				free(paddrs);

			return nSocket;	
		}
	}
	if(paddrs)
		free(paddrs);
	WS_close(nSocket);
	return -1;	
}

int QuickWrite( int sockfd,char* pszbuf,int len )
{
	int nwrite = 0;
	int nsendlen = 0;
	do 
	{
		nwrite = send(sockfd,pszbuf + nsendlen,len - nsendlen,0);

#ifdef WIN32
		if (nwrite < 0)
		{
			//== -1,call WSAGetLastError, see Error code(msdn); == 0 ,may be close by peer
			int err = WSAGetLastError();
			if(WSAEWOULDBLOCK != err) //暂时没数据可读
				nsendlen = -1;						//其他情况认为socket通道有问题
			break;
		}
		else if(nwrite == 0)
		{
			nsendlen = -1;
			break;
		}
		else
		{
			//On nonblocking stream oriented sockets, the number of bytes written can be between 1 and the requested length, see msdn
			nsendlen += nwrite;
			if(nsendlen == len)
				break;
			else
				continue;
		}
#else
		if(nwrite == 0)
		{
			printf("remote client close the connection\n");
			nsendlen = -1;
			break;
		}
		else if (nwrite < 0)
		{
			if(EINTR == errno)
			{
				printf("write interrupt,continue write\n");
				continue;
			}
			else if(EWOULDBLOCK == errno || EAGAIN== errno)
			{
				//当前不可写，退出
				printf("write EWOULDBLOCK or EAGAIN \n");
				break;
			}
			else
			{
				printf("my write failed %s\n", strerror(errno));
				nsendlen = -1; //认为当前 socket 异常
				break;
			}
		}
		else
		{
			nsendlen += nwrite;
			if (len == nsendlen)
			{
				//表示发送完成
				break;
			}
			else
			{
				//继续发送
				//linux 下直接break
				break;
				//continue;
			}
		}
#endif
	} while (1);

	return nsendlen;
}

int QuickRead( int sockfd,char* pszbuf,int len )
{
	int readedlen = 0;
	int recvlen = 0;
	do 
	{
		recvlen = recv(sockfd,pszbuf+readedlen,len-readedlen,0);
#ifdef WIN32
		if (recvlen < 0)
		{
			//== -1,call WSAGetLastError, see Error code(msdn); == 0 ,may be close by peer
			int err = WSAGetLastError();
			if(WSAEWOULDBLOCK != err) //暂时没数据可读
				readedlen = -1;						//其他情况认为socket通道有问题
			break;
		}
		else if(recvlen == 0)
		{
			//readedlen = -1;							//socket closed by peer; If the connection has been gracefully closed, the return value is zero
			break;
		}
		else
		{
			//On nonblocking stream oriented sockets, the number of bytes written can be between 1 and the requested length, see msdn
			readedlen += recvlen;

			break;
			if(readedlen == len)
				break;
			else
			{
				continue;
			}
		}
#else
		if (recvlen == 0)
		{
			printf("client close the connection\n");
			readedlen = -1;
			break;
		}
		else if (recvlen < 0)
		{
			if(EINTR == errno)
			{
				printf("read interrupt,continue read\n");
				continue;
			}
			else if(EWOULDBLOCK == errno || EAGAIN== errno)
			{
				//不可读，返回
				// 				rlt = 0;
				// 				usleep(60 * 1000);
				// 				continue;
				//printf("-------------------zusai\n");
				break;
			}
			else
			{
				//				close(sockfd);
				readedlen = -1;
				break;
			}
		}
		else
		{
			//recv some data
			readedlen += recvlen;
			if(len == readedlen)
			{
				break;	//recv ok
			}
			else
			{
				//printf("-------------------\n");
				break;
				//linux 下直接break
				//continue;
			}
		}
#endif

	} while (1);

	return readedlen;
}

int SetNoDelay( int nSocket )
{
	int on = 1;
#ifdef WIN32
	WS_setsockopt(nSocket, IPPROTO_TCP, TCP_NODELAY, (char*)&on, sizeof(int));
#else
	WS_setsockopt(nSocket, IPPROTO_TCP, TCP_NODELAY, (void*)&on, sizeof(int));
#endif
	return 0;
}
