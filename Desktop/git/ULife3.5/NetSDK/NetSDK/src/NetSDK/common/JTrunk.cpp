
#include "JTrunk.h"


#include <stdio.h>
#include <string.h>
#include <stdarg.h>

CJTrunk::CJTrunk()
{ 
	m_pfLog			= NULL;
	m_hEventLog		= NULL;
	m_dwStartTm		= (DWORD)time(NULL);		// 开始时间(用于获取当前时间)
	m_dwStartTickCount	= JGetTickCount();		// 开始时的TickCount(用于

	m_BipBuffer.allocateBuffer(65536);

	m_bStart		= false;
	m_iFlushTO		= 3000;						// 每3秒强制写一次日志
}

CJTrunk::~CJTrunk()
{
	Close();
	m_BipBuffer.freeBuffer();	
}

bool CJTrunk::Init(LPCTSTR lpszDir, LPCTSTR lpszName, LPCTSTR lpszExt, long lMaxSize)
{
	char szPath[MAX_PATH]	= {0};		// 日志路径

	if (m_mutexLog.IsCreate() == false)
	{
		m_mutexLog.CreateMutex();
	}

	if (m_hEventLog == NULL)
	{
		m_hEventLog  = JCreateEvent(NULL, TRUE, FALSE, NULL);
		if (m_hEventLog)	ResetEvent(m_hEventLog);
	}
	
	m_tcWriterLog.StartThread(RunOutputThread);
	m_tcWriterLog.SetParam(this);
	m_tcWriterLog.SetOwner(this);

	if (m_pfLog == NULL)
	{
		m_lMaxSize	= lMaxSize;							// 最大大小
		strcpy_s(m_szDir, MAX_PATH,lpszDir);				// 所在目录
		strcpy_s(m_szName, MAX_PATH,lpszName);			// 日志名称
		strcpy_s(m_szExt, JLOG_MAX_EXT_LEN,lpszExt);		// 后缀名称
		sprintf_s(szPath, MAX_PATH, "%s%s%s", m_szDir, m_szName, m_szExt);
		
		OpenFile(szPath);
	}

	return true;
}

bool CJTrunk::Close()
{

	if (m_hEventLog)	
    {
        SetEvent(m_hEventLog);
    }
    else
    {// android环境下，不像win32会产生两个log类,而android只有一个，close两次会出错 zouc 2014/5/14
        return false;
    }
    
	m_tcWriterLog.StopThread(true);
    
	m_mutexLog.CloseMutex();
	if (m_hEventLog)	
    {
        CloseEventHandle(m_hEventLog);
        m_hEventLog = NULL;
    }
	if ( m_pfLog )
	{
		fclose(m_pfLog);
		m_pfLog = NULL;
	}
	return true;
}

const char* CJTrunk::GetLogFilePath()
{
	return m_szPath;
}

int CJTrunk::WriteData(const char* format, ...)
{
	va_list			args;

	va_start(args, format);
	WriteData(format, args);
	va_end(args);

	return 0;
}

int CJTrunk::WriteData(const char *format, va_list args)
{
	int result,		len;
	unsigned char	*buf;
    char			szDate[30]		= {0};
	time_t			tNow			= 0;
//	tm				tmFm;

	CMutexLockAuto autoLock(&m_mutexLog);		  // 锁住race condition m_BipBuffer

	buf = m_BipBuffer.reserve(1024, len);
	if (buf == NULL)
	{
		return 0;
	}
/*
	tNow = GetCurTime();
	localtime_s(&tmFm,&tNow);
	sprintf_s(szDate,30,"%04d-%02d-%02d %02d:%02d:%02d\t",
		tmFm.tm_year+1900,tmFm.tm_mon+1,tmFm.tm_mday,
		tmFm.tm_hour,tmFm.tm_min,tmFm.tm_sec);
*/	
	//memcpy((char*)buf, szDate, strlen(szDate));
#if (defined _WIN32) || (defined _WIN64)	
	result = _vsnprintf((char *)buf, len, format, args);
#else
    result = vsnprintf((char *)buf, len, format, args);
#endif
    if (result < 0)
		result = 0;
    //*(buf + result - 1) == '\n';				  // 保持一行行输出 
	m_BipBuffer.commit(result);

	if (m_BipBuffer.getCommittedSize() >= 256)    // 提交的字节总数一旦大于256，通知线程输出
	{
		if (*(buf + result - 1) == '\n') // 保持一行行输出
		if (m_hEventLog)	SetEvent(m_hEventLog);
	}
	return result;
}

int CJTrunk::WriteData(LPCTSTR lpszBuf, int iLen)
{
	int result = 0,		len;
	unsigned char	*buf;
    char			szDate[30]		= {0};
	time_t			tNow			= 0;
//	tm				tmFm;

	//CMutexLockAuto autoLock(&m_mutexLog);		// 锁住race condition m_BipBuffer

	buf = m_BipBuffer.reserve(1024, len);
	if (buf == NULL)
	{
		return 0;
	}
/*
	if (len <= iLen)
	{
		len = iLen;
	}
	memcpy(buf, lpszBuf, len); 

	result = _vsnprintf((char *)buf, len, format, args);
	if (result < 0)
		result = 0;
*/  
	m_BipBuffer.commit(result);

  //if (m_BipBuffer.getCommittedSize() >= 256)    // 提交的字节总数一旦大于256，通知线程输出
  //if (*(buf + result - 1) == '\n') // 保持一行行输出
	if (m_hEventLog)	SetEvent(m_hEventLog);
	return result;
}

void CJTrunk::WriteBegin()
{
	m_mutexLog.Lock();
}

void CJTrunk::WriteEnd()
{
	m_mutexLog.Unlock();
}

void CJTrunk::Output()
{
    int             iRet            = -1;
	int				size			= 0;
	time_t			tNow			= 0;
	tm				tmFm;
	long			lSize			= 0;
	char			szDate[30]		= {0};
	char			szPath[MAX_PATH]		= {0};		// 日志路径
	char			szPathBack[MAX_PATH]	= {0};		// 备份日志路径

	unsigned char	*szOutStr, ch;

	if (m_hEventLog != NULL)
	{

        iRet = WaitForEvent(m_hEventLog, m_iFlushTO);
		if ((WAIT_OBJECT_0==iRet) || (WAIT_TIMEOUT==iRet))
		{
			ResetEvent(m_hEventLog);
			CMutexLockAuto autoLock(&m_mutexLog);
			szOutStr = m_BipBuffer.getContiguousBlock(size);
			if (szOutStr != NULL && size > 0)
			{
				ch = *(szOutStr + size);		// 保留最后一位
				*(szOutStr + size) = '\0';		// 字符串终止标识

				if (m_pfLog)
				{
					//tNow = GetCurTime();
					//localtime_s(&tmFm, &tNow);
					/*sprintf_s(szDate,30,"%04d-%02d-%02d %02d:%02d:%02d\t",
					tmFm.tm_year+1900, tmFm.tm_mon+1, tmFm.tm_mday,
					tmFm.tm_hour, tmFm.tm_min, tmFm.tm_sec);

					fwrite(szDate, strlen(szDate), 1, m_pfLog);*/
					
					fwrite(szOutStr, size, 1, m_pfLog);
					fflush(m_pfLog);
					// 重命名日志文件
					lSize = ftell(m_pfLog);
					if (lSize > m_lMaxSize)
					{
						//m_mutexLog.Lock();
						// 切换文件
						if (fclose(m_pfLog) == 0)
						{
							m_pfLog = NULL;
							
							tNow = GetCurTime();
							localtime_s(&tmFm, &tNow);
							
							sprintf_s(szPath, MAX_PATH, "%s%s%s", m_szDir, m_szName, m_szExt);
							sprintf_s(szPathBack, MAX_PATH, "%s%s%04d%02d%02d%02d%02d%02d%s", m_szDir, m_szName,
								tmFm.tm_year+1900, tmFm.tm_mon+1, tmFm.tm_mday,
								tmFm.tm_hour, tmFm.tm_min, tmFm.tm_sec,
								m_szExt);
							if (rename(szPath, szPathBack) == 0)
							{
								// 切换成功
								OpenFile(szPath);
							}
						}
						//m_mutexLog.Unlock();
					}
				}
				else
				{
					#if (defined _WIN32) || (defined _WIN64)
					OutputDebugString((LPCTSTR)szOutStr);
					#else
					printf("%s",szOutStr);
					#endif
				}
				
				*(szOutStr + size) = ch; // 恢复
				m_BipBuffer.decommitBlock(size);
			}
		}
	}
}

void CJTrunk::AdjustTarget(char* msgTargetAddr, unsigned int msgTargetPort)
{
	
}

time_t CJTrunk::GetCurTime()
{
	time_t	tRet	= m_dwStartTm;
	DWORD	dwSpan	= JGetTickCount() - m_dwStartTickCount;

	tRet += long(dwSpan/1000);
	return tRet;
}

bool CJTrunk::OpenFile(LPCTSTR lpszPath)
{
	time_t	tNow			= 0;
	tm		tmFm;
	char	szText[1024]	= {0};		// 文字
    char	szDate[30]		= {0};

	if ( m_pfLog ) return true;

	m_pfLog	= fopen(lpszPath,"ac+");
	if ( m_pfLog )
	{
		strcpy_s(m_szPath,MAX_PATH,lpszPath);
		tNow = GetCurTime();
		localtime_s(&tmFm,&tNow);
		sprintf_s(szDate,30,"%04d-%02d-%02d %02d:%02d:%02d",
			tmFm.tm_year+1900,tmFm.tm_mon+1,tmFm.tm_mday,
			tmFm.tm_hour,tmFm.tm_min,tmFm.tm_sec);
		fseek(m_pfLog,0,SEEK_END);

		if ( ftell(m_pfLog)>0 )
		{
			sprintf_s(szText,1024,"\r\n\r\n-------- %s Create by wwei at %s --------\r\n",lpszPath,szDate);
		}
		else
		{
			sprintf_s(szText,1024,"-------- %s Create by wwei at %s --------\r\n",lpszPath,szDate);
		}
		fwrite(szText,strlen(szText),1,m_pfLog);
		fflush(m_pfLog);
		return true;
	}
	else
	{
		return false;
	}

	return true;
}

fJThRet CJTrunk::RunOutputThread(void *pParam)
{
	CJLThreadCtrl*	pThreadCtrl			= NULL;
	CJTrunk* pThis						= NULL;

	pThreadCtrl = (CJLThreadCtrl*)pParam;
	if (pThreadCtrl == NULL)	return 0;

	pThis	= (CJTrunk*)pThreadCtrl->GetOwner();
	if (pThis == NULL)
	{
		pThreadCtrl->SetThreadState(THREAD_STATE_STOP);
		pThis->m_bStart	= false;
		return 0;
	}

	
	pThis->m_bStart    = true;
	while (pThis->m_bStart)
	{
		if (pThreadCtrl->GetNextAction() == THREAD_STATE_STOP)
		{
			pThreadCtrl->SetThreadState(THREAD_STATE_STOP);
			pThis->m_bStart = false;
			break;
		}

		// 做事 开始
		pThis->Output();
		// 做事 结束
		//JSleep(10);
	}
	pThreadCtrl->SetThreadState(THREAD_STATE_STOP);
	
	

	pThis->m_bStart = false;
	return 0;
}

