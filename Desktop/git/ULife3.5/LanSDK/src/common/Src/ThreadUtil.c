#include "ThreadUtil.h"
#include <stdlib.h>

THREAD_HANDLE thread_create_normal(thread_run pthread,void *pvoid)
{
	THREAD_HANDLE thread_id;
	int ret;
#ifdef WIN32	
	thread_id = (THREAD_HANDLE)_beginthread(pthread, 0, pvoid);
#else
	pthread_attr_t attr;
	pthread_attr_init(&attr);
	pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
	ret = pthread_create(&thread_id, &attr, pthread, pvoid);
	pthread_attr_destroy(&attr);
#endif
	return thread_id;
}