/******************************************************************
*@file GVAPProtocal.h
*@brief
*	GVAP协议的C语言接口
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
  //type:包的类型，1-表示request 2-表示response
DLL_GVAP_PROTOCAL_EXPORTS GVAP_Builder*  createPackage(char *cmdLine, int type);
DLL_GVAP_PROTOCAL_EXPORTS void releasePackage(GVAP_Builder* header);
DLL_GVAP_PROTOCAL_EXPORTS int  addSection(GVAP_Builder* header, char *name, int nameLen, char *value, int valueLen);
DLL_GVAP_PROTOCAL_EXPORTS int  addIntegerSection(GVAP_Builder* header, char *name, int nameLen, int value);
DLL_GVAP_PROTOCAL_EXPORTS char *getHeaderBuffer(GVAP_Builder* header);
DLL_GVAP_PROTOCAL_EXPORTS int	  getHeaderLen(GVAP_Builder* header);

///////////////////////////////packge Parser  ////////////////
DLL_GVAP_PROTOCAL_EXPORTS GVAP_Parser* parsePackage(char *buffer, int bufLen);
DLL_GVAP_PROTOCAL_EXPORTS void releaseParser(GVAP_Parser* parser);

 // Get方法
 // 所有的get通过指针返回所需要的值，值的长度由相应的Len参数带出
 // 返回值与值的Len相等，如果值小于0表示没有相应的域或解析出错，等于0表示有相应的域但是值为空
 // 大于0表示所要获取参数的长度
DLL_GVAP_PROTOCAL_EXPORTS int getType(GVAP_Parser* parser);
DLL_GVAP_PROTOCAL_EXPORTS int	getStatusCode(GVAP_Parser* parser);
DLL_GVAP_PROTOCAL_EXPORTS int	getCommand(GVAP_Parser* parser, char **pCmd, int *cmdLen);
DLL_GVAP_PROTOCAL_EXPORTS int	getResourceName(GVAP_Parser* parser, char **pResource, int *resourceLen);
DLL_GVAP_PROTOCAL_EXPORTS int getStatusDescription(GVAP_Parser* parser, char **pDescription, int *discriptionLen);
DLL_GVAP_PROTOCAL_EXPORTS int getVersion(GVAP_Parser* parser, char **pVersion, int *versionLen);
DLL_GVAP_PROTOCAL_EXPORTS int	getSectionByName(GVAP_Parser* parser, const char *pName, char **pValue, int *valueLen);
DLL_GVAP_PROTOCAL_EXPORTS int getIntegerSectionWithDefault(GVAP_Parser* parser, const char *pName, int nDefault);

// 大于等于0表示还有后续的值需要解析，小于等于0表示解析结束或者失败
DLL_GVAP_PROTOCAL_EXPORTS int	  getNextSection(GVAP_Parser* parser, char **pName, int *nameLen, char **pValue, int *valueLen);
DLL_GVAP_PROTOCAL_EXPORTS char* getBuffer(GVAP_Parser* parser);
DLL_GVAP_PROTOCAL_EXPORTS int   getBufferLen(GVAP_Parser* parser);
DLL_GVAP_PROTOCAL_EXPORTS int   getContentLength(GVAP_Parser* parser);
DLL_GVAP_PROTOCAL_EXPORTS int   getContentLengthFromBuffer(char *buf, int bufLen);

#ifdef __cplusplus
}// extern "C"
#endif
#endif //_GVAPPROTOCAL_H__
