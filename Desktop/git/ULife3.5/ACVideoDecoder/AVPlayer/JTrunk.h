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

  	bool					OpenFile(LPCTSTR lpszPath);	// ���ļ�
	
	static fJThRet			RunOutputThread(void *pParam);

protected: 
	JBipBuffer				m_BipBuffer;				// ���λ���
	FILE*					m_pfLog;					// ��־�ļ�ָ��
	CMutexLock				m_mutexLog;					// д����
	PJHANDLE				m_hEventLog;				// д��־�¼�
	
	bool					m_bStart;
	CJLThreadCtrl			m_tcWriterLog;				// ��־backend�߳�

	DWORD					m_dwStartTm;				// ��ʼʱ��(���ڻ�ȡ��ǰʱ��)
	DWORD					m_dwStartTickCount;			// ��ʼʱ��TickCount(���ڻ�ȡ��ǰʱ��)

	long					m_lMaxSize;					// ����С
	char					m_szDir[MAX_PATH];			// ����Ŀ¼
	char					m_szName[MAX_PATH];			// ��־����
	char					m_szExt[JLOG_MAX_EXT_LEN];	
	char					m_szPath[MAX_PATH];			// ��־·��

	int						m_iFlushTO;					// ǿ��д�ļ�(����)

};

#endif