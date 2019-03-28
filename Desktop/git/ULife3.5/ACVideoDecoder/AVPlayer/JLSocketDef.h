
#ifndef		__JLSOCKET_DEF__
#define		__JLSOCKET_DEF__

#define		JSOCKET_VER	"v1.0.0.4"

#ifndef		SAFE_FREE
#define		SAFE_FREE(pMem)				if(pMem){free(pMem);pMem=NULL;}
#endif
#ifndef		SAFE_DELETE
#define		SAFE_DELETE(pMem)			if(pMem){delete pMem;pMem=NULL;}
#endif
#ifndef		SAFE_DELETE_A
#define		SAFE_DELETE_A(pMem)			if(pMem){delete [] pMem;pMem=NULL;}
#endif
#ifndef		SAFE_DELETE_T
#define		SAFE_DELETE_T(pMem,Type)	if(pMem){delete (Type *)pMem;pMem=NULL;}
#endif
#ifndef		SAFE_CLOSE_A
#define		SAFE_CLOSE_A(pMem)			if(pMem){pMem->Close();delete(pMem);pMem=NULL;}
#endif
#ifndef		SAFE_CLOSE_B
#define		SAFE_CLOSE_B(pMem)			if(pMem){pMem->Close();pMem=NULL;}
#endif
#ifndef		SAFE_RELEASE_A
#define		SAFE_RELEASE_A(pMem)		if(pMem){pMem->Release();delete(pMem);pMem=NULL;}
#endif
#ifndef		SAFE_RELEASE_B
#define		SAFE_RELEASE_B(pMem)		if(pMem){pMem->Release();pMem=NULL;}
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "AVCommon.h"

#if (defined _WIN32) || (defined _WIN64)
	// CJLSocket 类相关的宏定义 begin
	#include <winsock2.h>
	#include <WS2TCPIP.H>
	#pragma comment(lib,"ws2_32.lib")
	typedef int				socklen_t;
	typedef	int				ssize_t; 
	#define MSG_NOSIGNAL	0
	#define close			closesocket
	#define fcntl			ioctlsocket
	#ifndef	SAFE_CLOSE_SOCK
	#define	SAFE_CLOSE_SOCK(sock)		if(sock!=INVALID_SOCKET){closesocket(sock);sock=INVALID_SOCKET;}
	#endif
	// CJLSocket 类相关的宏定义 end
#else	
	// CJLSocket 类相关的宏定义 begin
	#include <fcntl.h>
	#include <errno.h>
	#include <unistd.h>
	#include <sys/types.h>
	#include <netinet/in.h>
	#include <sys/socket.h>
	#include <arpa/inet.h>
	#include <netdb.h>
	typedef	unsigned int	SOCKET;
	typedef unsigned int	UINT;
	typedef unsigned char	byte;
	#define	INVALID_SOCKET	(SOCKET)(~0)
	#define SOCKET_ERROR	(-1)
	#ifndef	SAFE_CLOSE_SOCK
	#define	SAFE_CLOSE_SOCK(sock)		if(sock!=INVALID_SOCKET){close(sock);sock=INVALID_SOCKET;}
	#endif
	// CJLSocket 类相关的宏定义 end
#endif


// 检查回调函数
typedef int (__stdcall fcbCheckState)(void* pParam, DWORD dwTick, void* pUserData);
// 接收回调函数
typedef int (__stdcall fcbRecvMsg)(void* pParam, void* pUserData);

#endif	// __JLSOCKET_DEF__
