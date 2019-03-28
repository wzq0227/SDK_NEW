/********************************************************
*@file   GVAPPackageHeader.h
*@brief  Header file for class CGVAPPackageHeader
*		    
*@date   2011-06-02 14:40:56
*
*@author  Eric Guo <guojl@goscam.com>
**********************************************************/

#ifndef _GVAPPACKAGEHEADER_H__
#define _GVAPPACKAGEHEADER_H__

#include "GVAP_Protocal.h"
#ifdef _USE_ACE_MESSAGE_BLOCK
#include "../../Server/ServerBase/src/MessageBlockPool.h"
#define DLL_EXPORTS 
#else
#ifdef _WIN32
#ifdef DLL_EXPORTS
#undef DLL_EXPORTS
#define DLL_EXPORTS _declspec(dllexport)
#else
#define DLL_EXPORTS _declspec(dllimport)
#endif
#else
#define DLL_EXPORTS 
#endif
#endif

#ifdef WIN32
char *strcasestr (const char *psz_big, const char *psz_little);
#endif


class  CGVAPPackageBuilder
{
public:
	/*
	构造函数, cmdLine:起始行， type:包的类型，1-表示request 2-表示response
	*/
	CGVAPPackageBuilder(const char *cmdLine, int type);
	CGVAPPackageBuilder(); //通用构造函数
	~CGVAPPackageBuilder();


	/*添加头域， name：头域名， value： 头域值*/
	int  addSection(const char *name, int nameLen, char *value, int valueLen);
	/*添加一个整数型的头域， name：头域名， value： 头域值*/
	int  addIntegerSection(const char *name, int nameLen, int value); 
	void reset();
#ifndef _USE_ACE_MESSAGE_BLOCK	
	/* 获取包的缓冲区指针 */
	char *getBuffer();
	int	  getDataLen();
#else
	/* 获取包的缓冲区指针 */
	ACE_Message_Block *getMessageBlock();
#endif
	/*设置头域*/
	int setHeader(const char *cmdLine, int type);
protected:
#ifndef _USE_ACE_MESSAGE_BLOCK	
	char *m_pBuffer;
	int	  m_bufferLen;
	int	  m_dataLen;
#else
	ACE_Message_Block *m_mb;
#endif
	void  setLen();
	int	  checkBuffer(int len);
};

class  CGVAPPackageParser
{
public:
	   CGVAPPackageParser();
	   ~CGVAPPackageParser();

	   int parse(char *buffer, int len);
/**
 * @Function: getType
 * 
 * @Description: 获取包头类型
 * @Param:
 *    - No Param 
 * @Return: 
 *    -int: 0-UNKNOWN 1-request 2-response
 * @Notice:
*/
	   int   getType(); // return request or response
	   int	 getStatusCode();


	   // Get方法
	   // 所有的get通过指针返回所需要的值，值的长度由相应的Len参数带出
	   // 返回值与值的Len相等，如果值小于0表示没有相应的域或解析出错，等于0表示有相应的域但是值为空
	   // 大于0表示所要获取参数的长度
	   int		getCommand(char **pCmd, int &cmdLen);
	   int		getResourceName(char **pResource, int &resourceLen);
	   int      getStatusDescription(char **pDescription, int &discriptionLen);
	   int      getVersion(char **pVersion, int &versionLen);
	   int		getSectionByName(const char *pName, char **pValue, int &valueLen);
	   int      getIntegerSectionWithDefault(const char *pName, int nDefault);

	   // 大于等于0表示还有后续的值需要解析，小于等于0表示解析结束或者失败
	   int		getNextSection(char **pName, int &nameLen, char **pValue, int &valueLen);


	   char*    getBuffer();
	   int      getBufferLen();
	   int      getContentLength();
	static int  getContentLength(char *buf, int bufLen);
protected:
	static int  getNextWord(char *src, char **pWord, char endChar = 0x20);
	static int  getIntegerSectionWithDefault(char *buf, const char *pName, int nDefault);
		int     parseCmdLine();
		int		m_type;
		char*   m_cmd;
		int		m_cmdLen;
		char*   m_resourceName;
		int		m_resourceNameLen;
		int		m_status;
		char*   m_description;
		int		m_descriptionLen;
		char*   m_version;
		int		m_versionLen;
	

private:
		char*   m_pBuffer;
		int     m_bufLen;
		char*   m_pHeadField; //头域开始
		char*   m_pCurPos;

};

#endif //_GVAPPACKAGEHEADER_H__
