/******************************************************************
*@file GVAPProtocal.h
*@brief
*	GVAPЭ���C���Խӿ�
*@Versin 1.0
*
*@date 2011-6-3 16:47:41
*
*@author Eric Guo <guojl@goscam.com>
*******************************************************************/
#ifndef _GVAPPROTOCAL_H__
#define _GVAPPROTOCAL_H__
#ifdef WIN32
#ifdef DLL_GVAP_PROTOCAL_EXPORTS
#undef DLL_GVAP_PROTOCAL_EXPORTS
#define DLL_GVAP_PROTOCAL_EXPORTS _declspec(dllexport)
#else
#define DLL_GVAP_PROTOCAL_EXPORTS _declspec(dllimport)
#endif
#else
#define DLL_GVAP_PROTOCAL_EXPORTS
#endif

#ifdef __cplusplus
extern "C"{
#endif

#define GVAP_VERSION  "gvap/1.0"
#define GVAP_VERSION_LEN  8

#define	TYPE_UNKNOWN   0
#define TYPE_REQUEST   1
#define TYPE_RESPONSE  2


#define GVAP_TRYING			"100 trying"
#define GVAP_OK				"200 OK"
#define GVAP_REDIRECT		"302 Redirect"
#define GVAP_BAD_REQUEST	"400 Bad Request"
#define GVAP_UNAUTHORIZED	"401 Unauthorized"
#define GVAP_FOBBIDDEN		"403 Forbidden"
#define GVAP_NOT_FOUND		"404 Not Found"
#define GVAP_INVALID_USER	"405 Invalid User"
#define GVAP_INVALID_PASSWORD "406 Invalid Password"
#define GVAP_INVALID_DEV	 "407 Invalid Device ID"
#define GVAP_INVALID_CONTEXT "408 Invalid Context"
#define GVAP_NAME_INUSE		"409 Username In Use"
#define GVAP_RE_LOGIN		"410 Already Login"
#define GVAP_INTERNAL_ERROR "500 Internal Server Error"
#define GVAP_NOT_IMPLEMENTED "501 Not Implemented"

#define	GVAP_NOTIFY_DEV_STATUS	 "notify dev-status"


typedef   void GVAP_Builder;
typedef   void GVAP_Parser;


//////////////////////////////// packge builder /////////////
  //type:�������ͣ�1-��ʾrequest 2-��ʾresponse
DLL_GVAP_PROTOCAL_EXPORTS GVAP_Builder*  createPackage(char *cmdLine, int type);
DLL_GVAP_PROTOCAL_EXPORTS void releasePackage(GVAP_Builder* header);
DLL_GVAP_PROTOCAL_EXPORTS int  addSection(GVAP_Builder* header, char *name, int nameLen, char *value, int valueLen);
DLL_GVAP_PROTOCAL_EXPORTS int  addIntegerSection(GVAP_Builder* header, char *name, int nameLen, int value);
DLL_GVAP_PROTOCAL_EXPORTS char *getHeaderBuffer(GVAP_Builder* header);
DLL_GVAP_PROTOCAL_EXPORTS int	  getHeaderLen(GVAP_Builder* header);

///////////////////////////////packge Parser  ////////////////
DLL_GVAP_PROTOCAL_EXPORTS GVAP_Parser* parsePackage(char *buffer, int bufLen);
DLL_GVAP_PROTOCAL_EXPORTS void releaseParser(GVAP_Parser* parser);

 // Get����
 // ���е�getͨ��ָ�뷵������Ҫ��ֵ��ֵ�ĳ�������Ӧ��Len��������
 // ����ֵ��ֵ��Len��ȣ����ֵС��0��ʾû����Ӧ������������������0��ʾ����Ӧ������ֵΪ��
 // ����0��ʾ��Ҫ��ȡ�����ĳ���
DLL_GVAP_PROTOCAL_EXPORTS int getType(GVAP_Parser* parser);
DLL_GVAP_PROTOCAL_EXPORTS int	getStatusCode(GVAP_Parser* parser);
DLL_GVAP_PROTOCAL_EXPORTS int	getCommand(GVAP_Parser* parser, char **pCmd, int *cmdLen);
DLL_GVAP_PROTOCAL_EXPORTS int	getResourceName(GVAP_Parser* parser, char **pResource, int *resourceLen);
DLL_GVAP_PROTOCAL_EXPORTS int getStatusDescription(GVAP_Parser* parser, char **pDescription, int *discriptionLen);
DLL_GVAP_PROTOCAL_EXPORTS int getVersion(GVAP_Parser* parser, char **pVersion, int *versionLen);
DLL_GVAP_PROTOCAL_EXPORTS int	getSectionByName(GVAP_Parser* parser, const char *pName, char **pValue, int *valueLen);
DLL_GVAP_PROTOCAL_EXPORTS int getIntegerSectionWithDefault(GVAP_Parser* parser, const char *pName, int nDefault);

// ���ڵ���0��ʾ���к�����ֵ��Ҫ������С�ڵ���0��ʾ������������ʧ��
DLL_GVAP_PROTOCAL_EXPORTS int	  getNextSection(GVAP_Parser* parser, char **pName, int *nameLen, char **pValue, int *valueLen);
DLL_GVAP_PROTOCAL_EXPORTS char* getBuffer(GVAP_Parser* parser);
DLL_GVAP_PROTOCAL_EXPORTS int   getBufferLen(GVAP_Parser* parser);
DLL_GVAP_PROTOCAL_EXPORTS int   getContentLength(GVAP_Parser* parser);
DLL_GVAP_PROTOCAL_EXPORTS int   getContentLengthFromBuffer(char *buf, int bufLen);

#ifdef __cplusplus
}// extern "C"
#endif
#endif //_GVAPPROTOCAL_H__