#include "JLogWriter.h"

CJLogWriter	CJLogWriter::s_jlog;

CJLogWriter::CJLogWriter()
{/*
	m_pfLog		= NULL;						// 日志文件指针
	m_dwStartTm	= (DWORD)time(NULL);		// 开始时间(用于获取当前时间)
	m_dwStartTickCount	= JGetTickCount();	// 开始时的TickCount(用于
	m_lMaxSize	= JLOG_DEF_FILE_LEN;		// 默认大小
	memset(m_szDir,0,MAX_PATH);				// 所在目录
	memset(m_szName,0,MAX_PATH);			// 日志名称
	memset(m_szExt,0,JLOG_MAX_EXT_LEN);		// 后缀名称
*/
}

CJLogWriter::~CJLogWriter()
{
	CJTrunk::Close();
}

bool CJLogWriter::Init(LPCTSTR lpszDir,LPCTSTR lpszName,LPCTSTR lpszExt,long lMaxSize)
{
/*
	char	szPath[MAX_PATH]	= {0};		// 日志路径

	if ( m_mutexLog.IsCreate()==false )
	{
		m_mutexLog.CreateMutex();
	}

	if ( m_pfLog==NULL )
	{
		m_lMaxSize	= lMaxSize;							// 最大大小
		strcpy_s(m_szDir,MAX_PATH,lpszDir);				// 所在目录
		strcpy_s(m_szName,MAX_PATH,lpszName);			// 日志名称
		strcpy_s(m_szExt,JLOG_MAX_EXT_LEN,lpszExt);		// 后缀名称
		sprintf_s(szPath,MAX_PATH,"%s%s%s",m_szDir,m_szName,m_szExt);
		
		OpenFile(szPath);
	}
	return true;
*/
#if (defined __APPLE_CPP__) || (defined __APPLE_CC__)
    return true;
#else
	return CJTrunk::Init(lpszDir, lpszName, lpszExt, lMaxSize);    
#endif
}

bool CJLogWriter::Close()
{/*
	m_mutexLog.CloseMutex();
	
	if ( m_pfLog )
	{
		fclose(m_pfLog);
		m_pfLog = NULL;
	}

	return true;
*/
	time_t  tNow			= 0;
	tm		tmFm;
	char	szDate[30]		= {0};

	tNow = GetCurTime();
	localtime_s(&tmFm,&tNow);
	sprintf_s(szDate,30,"%04d-%02d-%02d %02d:%02d:%02d",
		tmFm.tm_year+1900,tmFm.tm_mon+1,tmFm.tm_mday,
		tmFm.tm_hour,tmFm.tm_min,tmFm.tm_sec);

	WriteLog("CJLogWriter::Close at %s\r\n", szDate);
	return CJTrunk::Close();
}

time_t CJLogWriter::GetCurTime()
{/*
	time_t	tRet	= m_dwStartTm;
	DWORD	dwSpan	= JGetTickCount()-m_dwStartTickCount;

	tRet+=long(dwSpan/1000);
	return tRet;
*/
	return CJTrunk::GetCurTime();
}

const char* CJLogWriter::GetLogFilePath()
{
	return GetLogFilePath();
	return m_szPath;
}

// 打开文件
bool CJLogWriter::OpenFile(LPCTSTR lpszPath)
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

void CJLogWriter::WriteLog(LPCTSTR fmt,... )
{
	int		iResult				= 0;
	char	szPath[MAX_PATH]	= {0};		// 日志路径
	char	szPathBack[MAX_PATH]= {0};		// 备份日志路径
    char	szOutStr[4096]	= {0};
    char	szDate[30]		= {0};
	time_t	tNow			= 0;
	tm		tmFm;
	long	lSize			= 0;
	
	CJTrunk::WriteBegin();

	tNow = GetCurTime();
	localtime_s(&tmFm,&tNow);
/*
	sprintf_s(szDate,30,"%04d-%02d-%02d %02d:%02d:%02d\t",
		tmFm.tm_year+1900,tmFm.tm_mon+1,tmFm.tm_mday,
		tmFm.tm_hour,tmFm.tm_min,tmFm.tm_sec);*/

	WriteData("%04d-%02d-%02d %02d:%02d:%02d\t",
		tmFm.tm_year+1900,tmFm.tm_mon+1,tmFm.tm_mday,
		tmFm.tm_hour,tmFm.tm_min,tmFm.tm_sec);

	va_list ap;
	va_start(ap, fmt);
	//iResult = vsprintf_s(szOutStr+strlen(szDate), fmt, ap);
	WriteData(fmt, ap);
	va_end(ap);

	CJTrunk::WriteEnd();
	/*
	if (iResult > 0)
	{
		WriteData(szOutStr, iResult);
	}*/
	//return;
/////////////////////////////////////////////////////////////////////
//	OutputDebugString(szOutStr);
	if ( m_pfLog )
	{
		fwrite(szDate,strlen(szDate),1,m_pfLog);
		fwrite(szOutStr,strlen(szOutStr),1,m_pfLog);
		fflush(m_pfLog);
		lSize = ftell(m_pfLog);
		if ( lSize>m_lMaxSize )
		{
			m_mutexLog.Lock();
			// 切换文件
			if ( fclose(m_pfLog)==0 )
			{
				m_pfLog = NULL;

				sprintf_s(szPath,MAX_PATH,"%s%s%s",m_szDir,m_szName,m_szExt);
				sprintf_s(szPathBack,MAX_PATH,"%s%s%04d%02d%02d%02d%02d%02d%s",m_szDir,m_szName,
					tmFm.tm_year+1900,tmFm.tm_mon+1,tmFm.tm_mday,
					tmFm.tm_hour,tmFm.tm_min,tmFm.tm_sec,
					m_szExt);
				if ( rename(szPath,szPathBack)==0 )
				{
					// 切换成功
					OpenFile(szPath);
				}
			}
			m_mutexLog.Unlock();
		}
	}
	else
	{
		#if (defined _WIN32) || (defined _WIN64)
		OutputDebugString(szOutStr);
		#else
		printf("%s",szOutStr);
		#endif
	}
}

void CJLogWriter::JTrace(LPCTSTR fmt,... )
{
    char	szOutStr[4096]	= {0};
	va_list ap;
	va_start(ap, fmt);
// 	vsprintf_s(szOutStr, fmt, ap);
	vsprintf(szOutStr, fmt, ap);
	va_end(ap);
	#if (defined _WIN32) || (defined _WIN64)
	OutputDebugString(szOutStr);
	#else
	printf("%s",szOutStr);
	#endif
}

