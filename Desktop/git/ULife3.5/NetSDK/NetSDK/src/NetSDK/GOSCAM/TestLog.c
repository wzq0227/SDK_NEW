#include "TestLog.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <time.h>

#ifdef WIN32
#include <Windows.h>
#else
#include <sys/time.h>
#include <unistd.h>
#endif
#ifdef WIN32
static int gettimeofday(struct timeval *tp, void *tzp)
{
	time_t clock;
	struct tm tm;
	SYSTEMTIME wtm;
	GetLocalTime(&wtm);
	tm.tm_year    = wtm.wYear - 1900;
	tm.tm_mon     = wtm.wMonth - 1;
	tm.tm_mday    = wtm.wDay;
	tm.tm_hour    = wtm.wHour;
	tm.tm_min     = wtm.wMinute;
	tm.tm_sec     = wtm.wSecond;
	tm. tm_isdst  = -1;
	clock = mktime(&tm);
	tp->tv_sec = (long)clock;
	tp->tv_usec = wtm.wMilliseconds * 1000;
	return (0);
}
#endif

//millisecond
long long now_ms_time()
{
	long long ret;
	struct timeval t;
	gettimeofday(&t, NULL);
	ret = t.tv_sec;
	return ret*1000 + t.tv_usec/1000;
}


static FILE* gs_fpData = NULL;
int gs_fileDataLen = 0;
char g_logfilepath[1024] = {0};
int g_bOpenLog = 0;

int Test_Open()
{
	if(g_bOpenLog == 0)
	{
		return -1;
	}
	if ( gs_fileDataLen > 1024*1024*2) //2M
	{
		fclose(gs_fpData);
		gs_fpData = NULL;
		gs_fileDataLen = 0;
	}

	if (gs_fpData == NULL)
	{
		gs_fpData = fopen(g_logfilepath,"wb+");
	}

	if(gs_fpData == NULL)
	{
		return -1;
	}

	return 0;
}

int TimeStr(int *year, int *month, int *day, int *hour, int *minute, int *second)
{
	time_t now;
	struct tm *timenow;
	time(&now);
	timenow = localtime(&now);
	/*注释：time_t是一个在time.h中定义好的结构体。而tm结构体的原形如下
	struct   tm
	{
	int   tm_sec;//seconds	0-61
	int   tm_min;//minutes	1-59
	int   tm_hour;//hours	0-23
	int   tm_mday;//day of the month	1-31
	int   tm_mon;//months since jan	0-11
	int   tm_year;//years from 1900
	int   tm_wday;//days since Sunday 0-6
	int   tm_yday;//days since Jan 1, 0-365
	int   tm_isdst;//Daylight Saving time indicator
	}*/
	if(timenow == NULL){
		return -1;
	}
	if(year!= NULL){
		*year = timenow->tm_year + 1900;
	}
	if(month!= NULL){
		*month = timenow->tm_mon + 1;
	}
	if(day!= NULL){
		*day = timenow->tm_mday;
	}
	if(hour!= NULL){
		*hour = timenow->tm_hour;
	}
	if(minute!= NULL){
		*minute = timenow->tm_min;
	}
	if(second!= NULL){
		*second = timenow->tm_sec;
	}
	return 0;
}

int Test_Log_Data( const char* key, const char* format, ... )
{
	if(Test_Open() == 0)
	{
		if(gs_fpData)
		{
			char log_cache[65536+40] = {0};
			long long time_ms = now_ms_time();
			int mo, day, hour, minute, second;
			va_list argptr;
			TimeStr(NULL, &mo, &day, &hour, &minute, &second);
			sprintf(log_cache,"%02d-%02d %02d:%02d:%02d.%.3d [%-20s] ",mo, day, hour, minute, second,(int)(time_ms%1000),key);

			va_start(argptr, format);
			vsprintf(log_cache+strlen(log_cache), format, argptr);
			va_end(argptr);

			sprintf(log_cache+strlen(log_cache),"%s","\r\n");

			fwrite(log_cache,strlen(log_cache),1,gs_fpData);
			fflush(gs_fpData);
		}
		return 0;
	}
	return -1;
}