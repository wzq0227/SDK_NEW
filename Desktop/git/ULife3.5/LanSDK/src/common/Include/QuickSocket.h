
#ifndef __QUICKSOCKET__H__
#define __QUICKSOCKET__H__

#ifdef __cplusplus
extern "C" {
#endif

#ifndef WIN32
#include "ws_socket.h"
#endif

#define  MAX_QS_TIMEOUT    0x7FFFFFFF


void StopSocket(int nSock);
int    StartUpSock();
void    CleanupSock();
int    StopServerSocket(int nSock) ;

int  QuickStartTCPServer(int wListenPort);
int  QuickStartUDPServer(int wListenPort,int bBoradCast);
int    WaitSocketData(int socket,int timeout,int bWaitToRecv);
int    WaitSocketsData(int socket,int socketList[],int socketCount,int timeout,int bWaitToRecv);
int  QuickConnectToTCP(int wServerPort,const char* lpServerIP,int dwTimeOut);
int  QuickSendToUDP(int wPort, const char* szDataBuffer, int dwSize, int bRetSock,const char*  lpServerIP);
int  AcceptTCPClient(int nListenSock,int timeout, struct sockaddr_in *pInAddr);

int    SetRecvSendBufferSize(int nSocket, int dwBufferSize);
int    SetRecvTimeOut(int nSocket, int dwTimeOut);
int    SetSendTimeOut(int nSocket, int dwTimeOut);
int	SetNoDelay(int nSocket);
int   ForceSend(int sock,void *pszBuf,int dwLen,int dwTimeOut,int bUDPFlag, struct sockaddr_in *pCLAddr);
int   ForceRecv(int sock,void *pszBuf,int dwLen,int dwTimeOut,int bUDPFlag, struct sockaddr_in *pCLAddr);

void    NotifySocketToEnd(int wPort, int bIsTcpMode);


int QuickConnectToTCPNonBlock(int wServerPort,const char* lpServerIP,int dwTimeOut);	//return a nonblock socket
int QuickCheckIsReadytoWriteorRead(int sockfd,int timeout,int onlyRead);	//return 0 -> timeout, 1 -> ready to read, 2 -> ready to write, 3 -> ready to read and write,-1 -> error
int QuickWrite(int sockfd,char* pszbuf,int len);	//return send data len,-1 -> socket close by peer, 0 -> send failed
int QuickRead(int sockfd,char* pszbuf,int len);	//return recv data len

#ifdef __cplusplus
}
#endif

#endif

