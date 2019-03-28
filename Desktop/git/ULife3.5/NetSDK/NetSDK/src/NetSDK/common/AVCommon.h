#ifndef AVCOMMON_H_
#define AVCOMMON_H_


#define		MAX_DEC_CHANNEL		128

#define		H264_SPS_FLAG		0x67
#define		H264_PPS_FLAG		0x68
#define		H264_SPS_FLAG_		0x47
#define		H264_PPS_FLAG_		0x48

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include "time.h"
#include "memory.h"

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

#if (defined _WIN32) || (defined _WIN64)
#include <direct.h>
//#define _WIN32_WINNT 0x0500
#define WIN32_LEAN_AND_MEAN
#include "windows.h"
#define INT_MAX 2147483647 
#include "ERRNO.H"
#define EWOULDBLOCK             WSAEWOULDBLOCK
#else
#if (defined __APPLE_CPP__) || (defined __APPLE_CC__)
#define MSG_NOSIGNAL		0
#endif
#define	MAX_PATH			260
typedef char				CHAR;
typedef int					INT;
typedef unsigned int		UINT;
typedef long				LONG;
typedef unsigned long		ULONG;
typedef	const char*			LPCTSTR;
typedef	char*				LPTSTR;
typedef	const char*			LPCSTR;
typedef unsigned char		BYTE;
typedef unsigned char*		LPBYTE;
typedef unsigned short		WORD;
//typedef unsigned long		DWORD;
typedef int64_t				DWORD64;
typedef	void*				HANDLE;
typedef long				BOOL;
typedef	int8_t				__int8;
typedef	int16_t				__int16;
typedef	int32_t				__int32;
typedef	int64_t				__int64;
typedef int64_t				LONGLONG;
#ifndef	__stdcall
#define __stdcall
#endif

#if (defined __APPLE_CPP__) || (defined __APPLE_CC__)
#if defined(__arm__) //debug++
typedef unsigned long       DWORD;
#elif defined(__arm64__)
typedef unsigned int        DWORD;
#endif
#else
typedef unsigned long		DWORD;
#endif

#include <sys/stat.h>
#include <time.h>
#include <sys/time.h>
#include <ctype.h>
#include <pthread.h>
//	#include <sys/prctl.h> to do
inline char* strupr(char* str)
{ 
	char* ptr = str;

	while (*ptr!='\0')
	{
		if (islower(*ptr))
		{
			*ptr = toupper(*ptr);
		}
		ptr++;
	}
	return str;
}
#endif
#include "MutexLock.h"

/*
inline DWORD JGetTickCount()
{
#if (defined _WIN32) || (defined _WIN64)
return GetTickCount();
#elif (defined __APPLE_CPP__) || (defined __APPLE_CC__)
struct timeval tv;
gettimeofday(&tv,NULL);
return (tv.tv_sec*1000+tv.tv_usec/1000);
#else
//	#ifdef __ANDROID__
struct timespec ts;
clock_gettime(CLOCK_MONOTONIC, &ts);
return (ts.tv_sec * 1000 + ts.tv_nsec / 1000000);
#endif
}
*/

inline DWORD JGetTickCount()
{
#if (defined _WIN32) || (defined _WIN64)
	return GetTickCount();
#else
	struct timeval tv;
	gettimeofday(&tv,NULL);
	return (tv.tv_sec*1000+tv.tv_usec/1000);
#endif
}

#if _MSC_VER<=1200
#define	_tfopen_s(pFile,szFileName,iMode)			*(pFile)=_tfopen(szFileName,iMode)
#define	fopen_s(pFile,szFileName,iMode)				*(pFile)=fopen(szFileName,iMode)
#define	fread_s(szBuf,iBufSize,iSize,iCount,pFile)	fread(szBuf,iSize,iCount,pFile)
#define	fscanf_s(pFile,szFM,szOutput)				fscanf(pFile,szFM,szOutput)
#define	strncpy_s(szTag,szSrc,iSize)				strncpy(szTag,szSrc,iSize)
#define	strcpy_s(szTag,iSize,szSrc)					strcpy(szTag,szSrc)
#define	strcat_s(szTag,iSize,szSrc)					strcat(szTag,szSrc)
#define vsprintf_s(szOutStr, fmt, ap)				vsprintf(szOutStr, fmt, ap)
#define sscanf_s									sscanf
#define	strupr_s(szTag,iSize)						strupr(szTag)
inline void localtime_s(tm* ptmFM, time_t* pTM){tm* pFM = localtime(pTM);memcpy(ptmFM,pFM,sizeof(tm));}
inline int sprintf_s(char *buffer,size_t iBufLen,const char *fmt,...)
{
	int	iRet	= 0;
	va_list ap;
	va_start(ap, fmt);
	iRet = vsprintf(buffer, fmt, ap);
	va_end(ap);
	return iRet;
}
#else
#endif

__inline void jmemcpy( void *d, const void *s, int i)
{
#if (defined _WIN32) || (defined _WIN64)
	_asm
	{
		mov ecx, i
			mov esi, s
			mov edi, d
			rep movsb
	}
#else
	memcpy(d,s,i);
#endif
}

#if (defined _WIN32) || (defined _WIN64)
#include <time.h>
typedef HANDLE PJHANDLE;
#define	JCreateEvent		CreateEvent
#define	CloseEventHandle	CloseHandle
#define	WaitForEvent		WaitForSingleObject
#else
#include <sys/socket.h>
#include <pthread.h>
#include <unistd.h>
#include <ctype.h>
typedef struct JHANDLE
{
	pthread_mutex_t mtx;
	pthread_cond_t cond;
	bool manual_reset;
	bool signaled;
}*PJHANDLE;
#define INFINITE 0xFFFFFFFF
#define WAIT_TIMEOUT 0x00000102L
#define WAIT_OBJECT_0 0
#define TRUE true
#define FALSE false
PJHANDLE JCreateEvent(void *pSec,bool bManualReset,bool bInitialState,char *pStr);
void CloseEventHandle(PJHANDLE handle);
void SetEvent(PJHANDLE handle);
void ResetEvent(PJHANDLE handle);
int WaitForEvent(PJHANDLE handle,unsigned int timeout);
#endif

void JSleep(long lMilliseconds);
bool JCreateDirectory(LPCTSTR lpPathName);


/*
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

*/

typedef struct
{
	DWORD	nIFrame;	// 1,yes;	2,no
	DWORD	nAVType;	// 1,video;	2,audio
	DWORD	dwSize;		// audio or video data size
	DWORD	gs_frameRate_samplingRate;	// video frame rate or audio samplingRate
	DWORD	lTMStamp;
	DWORD	gs_video_cap;				// video's capability
	DWORD	gs_reserved; 
}StDataInfo;



#endif