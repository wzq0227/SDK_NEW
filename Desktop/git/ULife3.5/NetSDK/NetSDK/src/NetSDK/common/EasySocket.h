#ifndef _EAST_SOCKET_H_
#define _EAST_SOCKET_H_

#include <stdio.h>

#include "JLogWriter.h"
#include "JLSocketDef.h"
#include "GoscamDef.h"
#include "../crypt/encrypt_def.h"
#include "cJSON.h"

#define  EASYPORT_PORTLEN		8
#define MAX_GETADDR_COUNT		32
typedef enum
{
	SOCK_TCP4 = 0,
	SOCK_UDP4,
	SOCK_TCP6,
	SOCK_UDP6
} SOCK_TYPE;

typedef struct _CheckGetAddr
{
	int nFlag;
	int nError;
	struct addrinfo *server_addr;
}CheckGetAddr;

class CEasySocket
{
public:
	CEasySocket();
	virtual ~CEasySocket();

	static DWORD	DomainToIP(const char* szDomain);

	virtual SOCKET	Connect(const char *pAddr, int nPort, int nConnType, int nTimeOut = 3);

	virtual int		SetSendTimeOut(SOCKET nSocket, int nTimeOut);

	virtual int		SetRecvTimeOut(SOCKET nSocket, int nTimeOut);

	virtual int		Send(SOCKET nSocket, const void* pBuf, int nBufLen);

	virtual int		Recv(SOCKET nSocket, void* pBuf, int nRecvLen);

	virtual int		Recv1(SOCKET nSocket, void* pBuf, int nRecvLen);

	virtual int		IsReadyToRead(SOCKET nSocket, int timeout);

	virtual int		IsReadyToWrite(SOCKET nSocket, int timeout);

	virtual SOCKET	StartTCPServer(int nPort);

	virtual SOCKET	AcceptTCPClient(SOCKET sListen, int nTimeOut, char *strAddr);

	virtual void	Close(SOCKET* nSocket);

	virtual int		DealWithMessage(char *pBuf, int nBufLen);

	virtual int		SetKey(unsigned char *pKey, int nKeyLen);

	static fJThRet RunCheckThread(void* pParam);
	int	 RunCheckAction();

protected:
	SOCKET			ConnectNew(const char *pAddr, int nPort, int bTcp);
	int				SetIoSock(SOCKET nSocket, int nMode);
	int				WaitSocketData(SOCKET socket,int timeout,BOOL bWaitToRecv);
	int				SetRecvSendBufferSize(SOCKET hSocket, DWORD dwBufferSize=0xFFFF);
	int				GetSockType(SOCK_TYPE type, int *family, int *stype, int *protocol);
	int				PrintLastErrorToScreen();
	int				GetAddrIndex();
	
	char			m_strPort[MAX_GETADDR_COUNT];
	char			m_strAddr[MAX_GETADDR_COUNT];
	int				m_nCurGetAddrIndex;
	CheckGetAddr	m_checkGetAddr[MAX_GETADDR_COUNT];
	unsigned char	*m_pKeyData;
};


#endif