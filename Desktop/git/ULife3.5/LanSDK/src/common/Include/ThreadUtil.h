#ifndef _THREADUTIL_H__
#define _THREADUTIL_H__

#ifdef __cplusplus
extern "C" {
#endif

#ifdef WIN32
#include <process.h>
#include <Windows.h>
#else
#include "pthread.h"
#include <time.h>
#endif

#ifdef WIN32
#define THREADRETURN		void
#define THREADRETURNVALUE
#define THREAD_HANDLE		HANDLE 
#define THREAD_HANDLENULL NULL
#define TIME_TYPE			long	
#else
#define THREADRETURN		void*
#define THREADRETURNVALUE	NULL
#define THREAD_HANDLE		pthread_t
#define THREAD_HANDLENULL 0
#define TIME_TYPE			time_t
#endif


typedef THREADRETURN (*thread_run)(void* pvoid);
THREAD_HANDLE thread_create_normal(thread_run pthread,void *pvoid);

#ifdef __cplusplus
}
#endif

#endif