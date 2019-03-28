/******************************************************************
*@file GVAPPackageHeader.cpp
*@brief 
*
*@Versin 1.0 
*
*@date 2011-6-13 16:59:24
*
*@author Eric Guo <guojl@goscam.com>
*******************************************************************/
#include "GVAP_PackageHeader.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#ifdef WIN32
#include <ctype.h>
char *strcasestr (const char *psz_big, const char *psz_little)
{
	char *p_pos = (char *)psz_big;
	if( !*psz_little ) return p_pos;
	while( *p_pos )
	{
		if( toupper( *p_pos ) == toupper( *psz_little ) )
		{
			char * psz_cur1 = p_pos + 1;
			char * psz_cur2 = (char *)psz_little + 1;
			while( *psz_cur1 && *psz_cur2 &&
				toupper( *psz_cur1 ) == toupper( *psz_cur2 ) )
			{
				psz_cur1++;
				psz_cur2++;
			}
			if( !*psz_cur2 ) return p_pos;
		}
		p_pos++;
	}
	return 0;
}
#endif

#pragma warning(disable:4996)

CGVAPPackageBuilder::CGVAPPackageBuilder()
{
#ifndef _USE_ACE_MESSAGE_BLOCK
	m_bufferLen = 256;
	m_dataLen = 4;
	m_pBuffer = (char*) malloc(m_bufferLen);
	memset(m_pBuffer, 0, m_bufferLen);
#else
	m_mb = MBPool::instance()->getMessageBlock(256);
	m_mb->wr_ptr(4);	
#endif
	setLen();
}
CGVAPPackageBuilder::CGVAPPackageBuilder(const char *cmdLine, int type)
{
#ifndef _USE_ACE_MESSAGE_BLOCK
	m_bufferLen = 256;
	m_dataLen = 4;
	m_pBuffer = (char*) malloc(m_bufferLen);
#else
	m_mb = MBPool::instance()->getMessageBlock(256);
	m_mb->wr_ptr(4);
#endif
	setHeader(cmdLine, type);
	setLen();
}

//#ifndef _USE_ACE_MESSAGE_BLOCK	
//// 重置数据
//void CGVAPPackageBuilder::reset()
//{
//	if(m_pBuffer != NULL)
//	{
//		if(m_bufferLen > 256)
//		{
//			m_bufferLen = 256;
//			m_pBuffer = (char*) realloc(m_pBuffer, m_bufferLen);
//		}
//	}
//	else
//	{
//		m_bufferLen = 256;
//		m_pBuffer = (char*) malloc(m_bufferLen);
//	}
//	m_dataLen = 0;
//}
//#endif

/*设置头域*/
int CGVAPPackageBuilder::setHeader(const char *cmdLine, int type)
{
	
#ifndef _USE_ACE_MESSAGE_BLOCK	
  	char *pBuf = m_pBuffer + 4;
	int   nDataLen = m_dataLen - 4;
#else
	char *pBuf = m_mb->rd_ptr() + 4;
	int   nDataLen = m_mb->length() - 4;	
#endif
	int nCmdLen = strlen(cmdLine);
	int len = nCmdLen + GVAP_VERSION_LEN + 5;
	if(checkBuffer(len) < 0)
		return -1;

	bool bAddBlank = true;
	if(nDataLen > 0)
	{
		len -= 2; // 已经有数据，去掉空行
		memmove(pBuf+len, pBuf,  nDataLen);
		bAddBlank = false;
	}
	int nPos = 0;
	if(type == TYPE_REQUEST)
	{
		memcpy(pBuf, cmdLine, nCmdLen);
		nPos += nCmdLen;
		pBuf[nPos] = 32; //添加空格
		nPos ++;
		memcpy(pBuf+nPos, GVAP_VERSION, GVAP_VERSION_LEN);
		nPos += GVAP_VERSION_LEN;
		pBuf[nPos] = '\r'; //添加'\r'
		pBuf[nPos+1] = '\n'; //添加'\n'
		nPos+=2;
	}
	else if(type == TYPE_RESPONSE)
	{
		memcpy(pBuf, GVAP_VERSION, GVAP_VERSION_LEN);
		nPos += GVAP_VERSION_LEN;
		pBuf[nPos] = 32; //添加空格
		nPos ++;
		memcpy(pBuf+nPos, cmdLine, nCmdLen);
		nPos += nCmdLen;
		pBuf[nPos] = '\r'; //添加'\r'
		pBuf[nPos+1] = '\n'; //添加'\n'
		nPos+=2;
	}
	else
	{
		assert(0);
		return 0;
	}

//全部转换为小写
	//int i = 0;
	// while(i < nPos)
	// {
	//	if(pBuf[i] >= 'A' && pBuf[i] <= 'Z')
	//	{
	//		pBuf[i] += 32;
	//	}
	//	i++;
	// }
	 if(bAddBlank)
	{
		pBuf[nPos] = '\r';
		pBuf[nPos+1] = '\n';
		nPos+=2;
	} 
#ifndef _USE_ACE_MESSAGE_BLOCK	
	m_dataLen += nPos;
#else
	m_mb->wr_ptr(nPos);
#endif
	setLen();
	return nPos;
}


CGVAPPackageBuilder::~CGVAPPackageBuilder()
{
#ifndef _USE_ACE_MESSAGE_BLOCK	
	if(m_pBuffer)
	{
		free(m_pBuffer);
	}
#else
	if(m_mb)
	{
		MBPool::instance()->release(m_mb);
	}
#endif
}

int  CGVAPPackageBuilder::addSection(const char *name, int nameLen, char *value, int valueLen)
{

	int len = nameLen + valueLen + 6;
	if(checkBuffer(len) < 0)
		return -1;
	char *newData = NULL;
#ifndef _USE_ACE_MESSAGE_BLOCK		
	if(m_dataLen > 4)
	{
		//删除前面的空行
		m_dataLen -= 2;
	}
	newData =  m_pBuffer+m_dataLen;// 记录新添加的值的起始位置
	//增加名称
	memcpy(m_pBuffer+m_dataLen, name, nameLen);
	m_dataLen += nameLen ;

	// 增加冒号
	//memcpy(m_pBuffer+m_dataLen, ": ", 2);
	//m_dataLen += 2 ;
	m_pBuffer[m_dataLen] = ':';
	m_dataLen++;
	// 增加值
	memcpy(m_pBuffer+m_dataLen, value,  valueLen);
	m_dataLen += valueLen ;

	// 添加行尾
	m_pBuffer[m_dataLen] = '\r';
	m_pBuffer[m_dataLen+1] = '\n';
	// 添加空行
	m_pBuffer[m_dataLen+2] = '\r';
	m_pBuffer[m_dataLen+3] = '\n';
	m_dataLen += 4 ;
#else
//删除之前添加的空行
	if(m_mb->length() > 4)
		m_mb->wr_ptr(-2);
	newData = m_mb->wr_ptr(); // 记录新添加的值的起始位置
	m_mb->copy(name, nameLen);
	m_mb->copy(": ", 2);
	m_mb->copy(value, valueLen);
	m_mb->copy("\r\n\r\n", 4);
#endif

	// 将新添加的域大写转换成小写
	//int i = 0;
	//for(; i < len && newData; i++)
	//{
	//	if(newData[i] >= 'A' && newData[i] <= 'Z')
	//	{
	//		newData[i] += 32;
	//	}
	//}
	setLen();
	return 0;
}

int  CGVAPPackageBuilder::addIntegerSection(const char *name, int nameLen, int value)
{
	char buf[20] = {0};
	int len = 0;
#ifdef _WIN32
	len = _snprintf(buf, 20,"%d", value);
#else
	len =  snprintf(buf,20, "%d", value);
#endif
	return addSection(name, nameLen, buf, len);
} 
#ifndef _USE_ACE_MESSAGE_BLOCK
char* CGVAPPackageBuilder::getBuffer()
{
	return m_pBuffer;
}
int  CGVAPPackageBuilder::getDataLen()
{
	return m_dataLen;
}
#else
ACE_Message_Block* CGVAPPackageBuilder::getMessageBlock()
{
	return m_mb;
}
#endif

int	  CGVAPPackageBuilder::checkBuffer(int len)
{
#ifndef _USE_ACE_MESSAGE_BLOCK
	if(m_dataLen + len > m_bufferLen)
	{
		m_bufferLen <<= 1;
		m_pBuffer = (char*) realloc(m_pBuffer, m_bufferLen);
		if(!m_pBuffer)
			return -1;
	}
	if(m_bufferLen == 0)
	{
		assert(0);
		printf("[CGVAPPackageBuilder::checkBuffer] : Out Of Memory\n");
		return -1;
	}
#else
	if(m_mb->space() < len)
	{
		int nSize = m_mb->size() << 1;
		return m_mb->size(nSize);
	}	
#endif
	return 0;
}
void CGVAPPackageBuilder::setLen()
{
	char buf[8] = {0};
#ifndef _USE_ACE_MESSAGE_BLOCK
	int len = m_dataLen - 4;
	char *pBuf = m_pBuffer;
#else	
	int len = m_mb->length() - 4;
	char *pBuf = m_mb->rd_ptr();
#endif
#ifdef _WIN32
	_snprintf(buf, 8,"%04X", len);
#else
	 snprintf(buf, 8, "%04X", len);
#endif
	memcpy(pBuf, buf, 4);
}
void CGVAPPackageBuilder::reset()
{
#ifndef _USE_ACE_MESSAGE_BLOCK
	memset(m_pBuffer, 0, m_bufferLen);
	m_dataLen = 4;
#else
	m_mb->length(4); //回退到开头	
#endif
	setLen();
}
//////////////////////////////////////////// CGVAPPackageParser ///////////////

CGVAPPackageParser::CGVAPPackageParser()
{
	m_pBuffer = NULL;
	m_bufLen = 0;
	m_type = TYPE_UNKNOWN;
	m_cmd = NULL;
	m_cmdLen = 0;
	m_resourceName = NULL;
	m_resourceNameLen = 0;
	m_status = 0;
	m_description = NULL;
	m_descriptionLen = 0;
	m_version = NULL;
	m_versionLen = 0;
	m_pCurPos = NULL;
	m_pHeadField = NULL;
}

int CGVAPPackageParser::parse(char *buffer, int len)
{
	m_pBuffer = buffer;
	m_bufLen = len;
	m_type = TYPE_UNKNOWN;
	m_cmd = NULL;
	m_cmdLen = 0;
	m_resourceName = NULL;
	m_resourceNameLen = 0;
	m_status = 0;
	m_description = NULL;
	m_descriptionLen = 0;
	m_version = NULL;
	m_versionLen = 0;
	m_pCurPos = NULL;

	int i = 0;
	//while(i < len)
	//{
	//	if(buffer[i] >= 'A' && buffer[i] <= 'Z')
	//	{
	//		buffer[i] += 32;
	//	}
	//	i++;
	//}
	//解析命令行
	return parseCmdLine();
}
CGVAPPackageParser::~CGVAPPackageParser()
{
	m_pBuffer = NULL;
	m_bufLen = 0;
}
// return request or response
int CGVAPPackageParser::getType()
{
	return m_type;
} 

int CGVAPPackageParser::getCommand(char **pCmd, int &cmdLen)
{
	*pCmd = m_cmd;
	return cmdLen = m_cmdLen;
}
int CGVAPPackageParser::getResourceName(char **pResource, int &resourceLen)
{
	*pResource = m_resourceName;
	return resourceLen = m_resourceNameLen;
}
int	CGVAPPackageParser::getStatusCode()
{
	return m_status;
}
int  CGVAPPackageParser::getStatusDescription(char **pDescription, int &discriptionLen)
{
	*pDescription = m_description;
	return discriptionLen = m_descriptionLen;
}
int CGVAPPackageParser::getVersion(char **pVersion, int &versionLen)
{
	*pVersion = m_version;
	return versionLen = m_versionLen;
}


char* CGVAPPackageParser::getBuffer()
{
	return m_pBuffer;
}
int CGVAPPackageParser::getBufferLen()
{
	return m_bufLen;
}
/**
 * @Function: CGVAPPackageParser::getNextWord
 * 
 * @Description: 获取一个字符串中的下一个单词
 * @Param:
 *    -(in, out) char *src: 输入源字符串的起始地址
 *    -(in) char **pWord:  指向当前单词的起始地址
 *    -(in) char endChar: 单词分割标识，默认为空格
 * @Return: 
 *    -int: 当前单词的长度
 * @Notice:
*/
int CGVAPPackageParser::getNextWord(char *src, char **pWord, char endChar)
{
	try
	{
		int  len = 0;
		if(src == NULL)
		{
			return 0;
		}
		char *pTemp = src;
		//去掉开头的所有空格 和冒号
		while(*pTemp == 0x20 || *pTemp == ':') pTemp++;

		//判断是否已经到达包尾
		if(strncmp(pTemp, "\r\n\r\n", 4) == 0)
		{
			return 0;
		}
		//跳过开头的换行符
		while(*pTemp != endChar && (*pTemp == '\r' || *pTemp == '\n')) pTemp++;
	
		//跳到结束符，碰到'\r' '\n'自然结束
		while(*(pTemp+len) != endChar && *(pTemp+len) != '\r' && *(pTemp+len) != '\n')
		{
			len++;
		}
		*pWord = pTemp;
		return len;
	}
	catch(...)
	{
		return 0;
	}
	return 0;
}

int CGVAPPackageParser::parseCmdLine()
{
	char *pTemp = m_pBuffer;
	char *pValue = NULL;
	int  len = 0;
	//检查包是否完整
	if(m_pBuffer == NULL || strstr(m_pBuffer, "\r\n\r\n") == NULL)
	{
		return -1;
	}

	try
	{
		if((len = getNextWord(pTemp, &pValue)) > 0)
		{
			pTemp = pValue+len; //跳到下一个单词的开始
			 
#ifdef _WIN32
			if(strnicmp(pValue, "GVAP", 4) == 0)
#else
			if(strncasecmp(pValue, "GVAP", 4) == 0)
#endif
			{
				m_type = TYPE_RESPONSE;
				m_version = pValue;
				m_versionLen = len;
		
				if((len = getNextWord(pTemp, &pValue)) > 0)
				{
					pTemp = pValue+len;  
					sscanf(pValue, "%d", &m_status);
				}
				else
				{
					return -1;
				}

				if((len = getNextWord(pTemp, &pValue, '\r')) > 0)
				{
					pTemp = pValue+len; //指向换行符  
					m_description = pValue;
					m_descriptionLen = len;
				}
				else
				{
					return -1;
				}
			}
			else
			{
				m_type = TYPE_REQUEST;
				m_cmd = pValue;
				m_cmdLen = len;

				if((len = getNextWord(pTemp, &pValue)) > 0)
				{
					pTemp = pValue+len; 
					m_resourceName = pValue;
					m_resourceNameLen = len;
				}
				else
				{
					return -1;
				}
				if((len = getNextWord(pTemp, &pValue, '\r')) > 0)
				{
					pTemp = pValue+len; 
					m_version = pValue;
					m_versionLen = len;
				}
				else
				{
					return -1;
				}
			}
			m_pCurPos = pTemp; // m_pCurPos 指向 第一个头域地址
			m_pHeadField = pTemp; // 头域起始地址
		}
	}
	catch(...)
	{
		return -1;
	}
	return 0;
}

/**
 * @Function: CGVAPPackageParser::getNextSection
 * 
 * @Description: 解析头域字段
 * @Param:
 *    -(out) char **pName: 指向域名的起始地址
 *    -(out) char **pValue: 指向值的起始地址
 * @Return: 
 *    -int:  < 0 解析错误，=0 已经达到结尾，>0 解析成功，还有后续字段
 * @Notice:
*/
int CGVAPPackageParser::getNextSection(char **pName, int &nameLen, char **pValue, int &valueLen)
{
	char *pTemp = m_pCurPos;
	char *pTempValue = NULL;
	int len = 0;
	
	if(pTemp == NULL) 
	{
		return -1;
	}
	//取名称
	if((len = getNextWord(pTemp, &pTempValue, ':')) > 0)
	{
		
		*pName = pTempValue;
		//去掉名字和冒号之间的空格
		while(len > 1 && *(pTempValue + len - 1) == 0x20) len--; 
		nameLen = len;
		
		pTemp = pTempValue + len;
		//取值
		if((len = getNextWord(pTemp, &pTempValue, '\r')) >= 0)
		{
			pTemp = pTempValue + len;
			*pValue = pTempValue;
			valueLen = len;
		}
		m_pCurPos = pTemp;
		return 1;
	}
	else if(len == 0)
	{
		return 0;
	}

	return -1;
}
/**
 * @Function: CGVAPPackageParser::getSectionByName
 * 
 * @Description: 获取指头域的值
 * @Param:
 *    -(in) char *pName: 头域名称
 *    -(out) char **pValue: 指向头域起始地址的指针
 *    -(in) int &valueLen: 值的长度
 * @Return: 
 *    -int: > 0 值的长度， = 0， 该域为空， < 0 不包含该域
 * @Notice: 传入的 pName 必须全部为小写字母，否则会找不到
*/
int CGVAPPackageParser::getSectionByName(const char *pName, char **pValue, int &valueLen)
{
	int len = 0;
	valueLen = 0;
	if(m_pHeadField == NULL  || pName == NULL)
	{
		return -1;
	}
	int nNameLen = strlen(pName);
	if(nNameLen <= 0)
	{
		return -1;
	}
	//char pSecName[256] = {0};
	//sprintf(pSecName, "%s:", pName);
	char *pTemp = m_pHeadField;

	do
	{
		pTemp = strcasestr(pTemp, pName);
		// 找到后判断是否以冒号结束, 头域必须以冒号结束
	//	if(pTemp == NULL || *(pTemp+nNameLen) == ':'/* || *(pTemp+nNameLen) == 0x20*/)
		if(pTemp == NULL || (*(pTemp-1) == '\n' && (*(pTemp+nNameLen) == ':'/* || *(pTemp+nNameLen) == 0x20*/)))
		{
			break;
		}	
		else
		{
			pTemp += nNameLen; // 跳过不完全符合的名字
		}

	}while(1);

	char *pTempValue = NULL;
	if(pTemp != NULL)
	{
		//获取名字的长度
		//if((len = getNextWord(pTemp, &pTempValue, ':')) > 0)
		{ 
			pTemp += nNameLen;
			if((len = getNextWord(pTemp, &pTempValue, '\r')) > 0)
			{
				*pValue = pTempValue;
				 valueLen = len;
				 return valueLen;
			}
			return 0; 
		}
	}
	return -1;
}
 int CGVAPPackageParser::getContentLength()
 {
	 return getIntegerSectionWithDefault(m_pHeadField, "content-length", 0);
 }
 int CGVAPPackageParser::getIntegerSectionWithDefault(const char *pName, int nDefault)
 {
	 //转换成小写
	/* for(int i=0; pName[i] != 0; i++)
	 {
		 if(pName[i] > 'A' || pName[i] < 'Z')
		 {
			pName[i]  += 32;
		 }
	 }
	 */
	 return getIntegerSectionWithDefault(m_pHeadField, pName, nDefault);
 }
/*static*/
int CGVAPPackageParser::getContentLength(char *buf, int bufLen)
{
	return getIntegerSectionWithDefault(buf, "content-length", 0);
}

/*static*/
int  CGVAPPackageParser::getIntegerSectionWithDefault(char *buf, const char *pName, int nDefault)
{
	int value = nDefault;
	int len = 0;
		//检查包是否完整
	if(buf == NULL || strstr(buf, "\r\n\r\n") == NULL || pName == NULL)
	{
		return value;
	}
	int nNameLen = strlen(pName);
	if(nNameLen <= 0)
	{
		return value;
	}
	char *pTemp = buf;
	do
	{
		pTemp = strcasestr(pTemp, pName);
		// 找到后判断是否以冒号结束, 头域名称必须以冒号结束
		if(pTemp == NULL || (*(pTemp-1) == '\n' && (*(pTemp+nNameLen) == ':'/* || *(pTemp+nNameLen) == 0x20*/)))
		{
			break;
		}	
		else
		{
			pTemp += nNameLen; // 跳过不完全符合的名字
		}

	}while(1);
	char *pTempValue = NULL;
	if(pTemp != NULL)
	{
		//获取名字的长度
	//	if((len = getNextWord(pTemp, &pTempValue, ':')) > 0)
		{ 
			pTemp = pTemp + nNameLen; //跳到值的开头
			if((len = getNextWord(pTemp, &pTempValue, '\r')) > 0)
			{
				sscanf(pTempValue, "%d", &value);
			}
		}
	}
	return value;
}
