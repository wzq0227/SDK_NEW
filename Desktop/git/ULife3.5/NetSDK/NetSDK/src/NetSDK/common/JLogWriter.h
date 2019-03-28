#ifndef	__JLOG_WRITER__ 
#define	__JLOG_WRITER__

//#define JLOG_MAX_EXT_LEN	10
//#define JLOG_DEF_FILE_LEN	1024*1024*5
#ifdef __ANDROID__
#include <android/log.h>
#define	LOG_TAG		"JLogWriter.h"
#define LOGD(...)	__android_log_print(ANDROID_LOG_DEBUG,LOG_TAG,__VA_ARGS__)
#define LOGI(...)	__android_log_print(ANDROID_LOG_INFO,LOG_TAG,__VA_ARGS__)
#define LOGW(...)	__android_log_print(ANDROID_LOG_WARN,LOG_TAG,__VA_ARGS__)
#define LOGE(...)	__android_log_print(ANDROID_LOG_ERROR,LOG_TAG,__VA_ARGS__)
#define LOGF(...)	__android_log_print(ANDROID_LOG_FATAL,LOG_TAG,__VA_ARGS__)
#define	JTRACE(...)	__android_log_print(ANDROID_LOG_DEBUG,LOG_TAG,__VA_ARGS__)
#define	DbgStrOut			JTRACE
#else

#if (defined __APPLE_CPP__) || (defined __APPLE_CC__)
#define	DbgStrOut			CJLogWriter::JTrace
#define	JTRACE				CJLogWriter::JTrace
#else
#define	DbgStrOut			CJLogWriter::s_jlog.WriteLog
#define	JTRACE				CJLogWriter::JTrace
#endif

#endif
#define JLOG_TRY			try{
#define JLOG_CATCH(str)		}catch (...){DbgStrOut(str);}

#include "stdio.h"
#include "stdlib.h"
#include "AVCommon.h"
#include "MutexLock.h"
#include "JTrunk.h"


namespace JSocketCtrl
{
class CJLogWriter : protected CJTrunk
{
public:
	CJLogWriter();
	~CJLogWriter();

	bool Init(LPCTSTR lpszDir,LPCTSTR lpszName,LPCTSTR lpszExt,long lMaxSize);
	bool Close();
	time_t	GetCurTime();
	const char* GetLogFilePath();
	void WriteLog(LPCTSTR fmt,... );
	
	static void JTrace(LPCTSTR fmt,... );
	static CJLogWriter	s_jlog;
	static int s_iCatchNO;
protected:
	bool OpenFile(LPCTSTR lpszPath);	// 打开文件
	
	FILE*		m_pfLog;				// 日志文件指针
	CMutexLock	m_mutexLog;				// 写入锁
	DWORD		m_dwStartTm;			// 开始时间(用于获取当前时间)
	DWORD		m_dwStartTickCount;		// 开始时的TickCount(用于获取当前时间)
	long		m_lMaxSize;				// 最大大小
	char		m_szDir[MAX_PATH];		// 所在目录
	char		m_szName[MAX_PATH];		// 日志名称
	char		m_szExt[JLOG_MAX_EXT_LEN];			// 后缀名称
	char		m_szPath[MAX_PATH];		// 日志路径
};
}
using namespace JSocketCtrl;


#endif	// __JLOG_WRITER__
