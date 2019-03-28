#ifndef _FILE_DATA_H_
#define _FILE_DATA_H_

#define TESTLOG_TOFILE		1

 #ifdef __cplusplus
 extern "C" {
 #endif

int Test_Log_Data(const char* key, const char* format, ...);

extern char g_logfilepath[1024];
extern int g_bOpenLog;

 #ifdef __cplusplus
 }
 #endif

#if TESTLOG_TOFILE

#ifdef WIN32

#define TEST_LOG_DATA(key, fmt, ...) do \
{\
	Test_Log_Data(key, fmt,##__VA_ARGS__);\
} while (0);

#else //WIN32

#define TEST_LOG_DATA(key, fmt,arg...) do \
{\
	Test_Log_Data(key ,fmt,##arg);\
} while (0);

#endif //WIN32


#else //TESTLOG_TOFILE

#define TEST_LOG_DATA(key, fmt,...) do \
{\
} while (0);

#endif //TESTLOG_TOFILE


#endif //_FILE_DATA_H_