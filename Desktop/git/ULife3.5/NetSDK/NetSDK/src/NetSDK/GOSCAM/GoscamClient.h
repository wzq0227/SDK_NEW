#ifndef _GOSCAM_CLIENT_H_
#define _GOSCAM_CLIENT_H_

#include "EasySocket.h"

class CGoscamClient : public CEasySocket
{
public:
	CGoscamClient();
	virtual ~CGoscamClient();

	int GosSend(SOCKET nSocket, void* pBuf, int nBufLen);

	int GosRecvHead(SOCKET nSocket, char** pRecvHead);



protected:

	int				m_nSerialNo;
	CMutexLock		m_mutexRecv;
	

};

#endif