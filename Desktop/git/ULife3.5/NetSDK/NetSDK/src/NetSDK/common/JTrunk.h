#ifndef __JTRUNK_H__
#define __JTRUNK_H__

#include "stdio.h"
#include "stdlib.h"
#include "JBipBuffer.h"
#include "MutexLock.h"
#include "JLThreadCtrl.h"

#define JLOG_MAX_EXT_LEN	10
#define JLOG_DEF_FILE_LEN	1024*1024*5


class CJTrunk
{
public:
							CJTrunk();
	virtual					~CJTrunk();

	bool					Init(LPCTSTR lpszDir,LPCTSTR lpszName,LPCTSTR lpszExt,long lMaxSize);
	bool					Close();
	const char*				GetLogFilePath();

	void					Output();
	int						WriteData(const char* format, ...);
	int						WriteData(const char *format, va_list args);
	int						WriteData(LPCTSTR lpszBuf, int iLen);
	
	void					WriteBegin();
	void					WriteEnd();

	void					AdjustTarget(char* msgTargetAddr, unsigned int msgTargetPort);

protected:
	time_t					GetCurTime();

  	bool					OpenFile(LPCTSTR lpszPath);	// 打开文件
	
	static fJThRet			RunOutputThread(void *pParam);

protected: 
	JBipBuffer				m_BipBuffer;				// 环形缓存
	FILE*					m_pfLog;					// 日志文件指针
	CMutexLock				m_mutexLog;					// 写入锁
	PJHANDLE				m_hEventLog;				// 写日志事件
	
	bool					m_bStart;
	CJLThreadCtrl			m_tcWriterLog;				// 日志backend线程

	DWORD					m_dwStartTm;				// 开始时间(用于获取当前时间)
	DWORD					m_dwStartTickCount;			// 开始时的TickCount(用于获取当前时间)

	long					m_lMaxSize;					// 最大大小
	char					m_szDir[MAX_PATH];			// 所在目录
	char					m_szName[MAX_PATH];			// 日志名称
	char					m_szExt[JLOG_MAX_EXT_LEN];	
	char					m_szPath[MAX_PATH];			// 日志路径

	int						m_iFlushTO;					// 强制写文件(毫秒)

};

#endif
