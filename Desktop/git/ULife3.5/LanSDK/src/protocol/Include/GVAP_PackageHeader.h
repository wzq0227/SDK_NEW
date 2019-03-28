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
	���캯��, cmdLine:��ʼ�У� type:�������ͣ�1-��ʾrequest 2-��ʾresponse
	*/
	CGVAPPackageBuilder(const char *cmdLine, int type);
	CGVAPPackageBuilder(); //ͨ�ù��캯��
	~CGVAPPackageBuilder();


	/*����ͷ�� name��ͷ������ value�� ͷ��ֵ*/
	int  addSection(const char *name, int nameLen, char *value, int valueLen);
	/*����һ�������͵�ͷ�� name��ͷ������ value�� ͷ��ֵ*/
	int  addIntegerSection(const char *name, int nameLen, int value); 
	void reset();
#ifndef _USE_ACE_MESSAGE_BLOCK	
	/* ��ȡ���Ļ�����ָ�� */
	char *getBuffer();
	int	  getDataLen();
#else
	/* ��ȡ���Ļ�����ָ�� */
	ACE_Message_Block *getMessageBlock();
#endif
	/*����ͷ��*/
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
 * @Description: ��ȡ��ͷ����
 * @Param:
 *    - No Param 
 * @Return: 
 *    -int: 0-UNKNOWN 1-request 2-response
 * @Notice:
*/
	   int   getType(); // return request or response
	   int	 getStatusCode();


	   // Get����
	   // ���е�getͨ��ָ�뷵������Ҫ��ֵ��ֵ�ĳ�������Ӧ��Len��������
	   // ����ֵ��ֵ��Len��ȣ����ֵС��0��ʾû����Ӧ������������������0��ʾ����Ӧ������ֵΪ��
	   // ����0��ʾ��Ҫ��ȡ�����ĳ���
	   int		getCommand(char **pCmd, int &cmdLen);
	   int		getResourceName(char **pResource, int &resourceLen);
	   int      getStatusDescription(char **pDescription, int &discriptionLen);
	   int      getVersion(char **pVersion, int &versionLen);
	   int		getSectionByName(const char *pName, char **pValue, int &valueLen);
	   int      getIntegerSectionWithDefault(const char *pName, int nDefault);

	   // ���ڵ���0��ʾ���к�����ֵ��Ҫ������С�ڵ���0��ʾ������������ʧ��
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
		char*   m_pHeadField; //ͷ��ʼ
		char*   m_pCurPos;

};

#endif //_GVAPPACKAGEHEADER_H__