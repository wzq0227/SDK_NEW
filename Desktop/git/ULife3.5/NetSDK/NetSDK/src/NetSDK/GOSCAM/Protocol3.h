#ifndef _PROTOCO3_H_
#define _PROTOCO3_H_

#include <map>
#include <list>

enum
{
	e_protocol3_msg_type_req = 1,
	e_protocol3_msg_type_resp = 2,
	e_protocol3_msg_type_notify = 3,
};
enum
{
	e_protocol3_proto_type_json = 1,
};

#define Proto3ClientPrivHeadLen 16  //私有协议头的
#define Proto3ClientPrivDataMinLen 1  //每个私有包中数据的最小长度,取决于协议规定
#define Proto3ClientPrivDataMaxLen 65535  //每个私有包中数据的最大长度
#define PROTO3_MAGIC_STRING "gsmp"
#define PROTO3_MAGIC_SIZE 4

class Protocol3Header
{
public:
	Protocol3Header();
	~Protocol3Header();
	bool BuildHeader(int msgSerial,unsigned short int bodylen,unsigned char msgtype = e_protocol3_msg_type_resp,unsigned char prototype = e_protocol3_proto_type_json);
	bool ParseHeader(char* msg,int msglen);

	char* GetHeader() { return m_HeadBuf; }
	int GetHeaderLen() { return Proto3ClientPrivHeadLen; }

	void SetMsgSerial(int msgSerial);
	int GetMsgSerial();

	void SetBodyLen(unsigned short int len);
	unsigned short int GetBodyLen();

	void SetMsgType(unsigned char type);
	unsigned char GetMsgType();

	void SetProtoType(unsigned char type);
	unsigned char GetProtoType();

	void PrintLog();
private:
// 	int m_magic; //0x67736d70
// 	int m_msgSerial; //消息序列号，确保消息唯一性 取值范围:1~0xFFFFFFFF
// 	unsigned short int m_bodylen; //消息体长度 取值范围:1~65535
// 	unsigned char m_bodytype; //协议类型 1->json,2~其它; 取值范围:1~255
// 	unsigned char m_msgtype; //消息类型 1->请求,2->应答,3->通知; 取值范围:1~255
// 	int m_reseved;//保留字段
	//消息头总共16字节: 魔术符(Magic) + 消息序列号(serial) + 消息体长度(length) + 协议类型(protocoltype) + 消息体类型(msgtype) + 保留字段(reserved)
	//使用网络字节序
	//字段名称		长度				取值范围					描述
	//Magic			4					0x67736d70				消息分隔符
	//Serial				4					1～0xFFFFFFFF			确保消息唯一性
	//length			2					1～65536					消息体长度
	//protocoltype	1					1～255						1->json,...
	//msgtype		1					1~255						1->请求, 2->应答, 3->通知
	//reserved		4					无								保留字段，扩展用
	char m_HeadBuf[Proto3ClientPrivHeadLen];
};

class Protocol3Body
{
public:
	Protocol3Body();
	Protocol3Body(const Protocol3Body& other);
	Protocol3Body & operator = (const Protocol3Body & other);
	~Protocol3Body();
	

	bool NewBody(char* msg,int msglen);
	char* GetBody() { return m_pbody; }
	int GetBodyLen() { return m_bodylen; }
	void PrintLog();
protected:
private:
	char *m_pbody;
	int m_bodylen;
};

class Protocol3
{
public:
	Protocol3() { }
	~Protocol3() { }
	void PrintLog(bool bParse,bool bPrint = true);
	Protocol3Header header;
	Protocol3Body body;
};

class HandleProtocol3
{
public:
	HandleProtocol3();
	~HandleProtocol3();
	bool IsNoDataLeftWhenParseMessage() { 
		if((int)m_tempParseList.size() > 0) 
			return false;
		else
			return true;
	}
	int GetCountParseMessage() { return (int)m_msglistParsed.size(); }
	char *GetOneParseMessage();
	bool GetOneBuildMessage(unsigned char** pdst,int &len);
	bool SetMsgSerial(unsigned int serial);
	int Parse(char* msg,int msglen);
	int Build(char* msg,int msglen,unsigned char msgtype = e_protocol3_msg_type_req);

	void SetPrintLog(bool bprint) { m_bPrint = bprint; }
protected:
	int ParseOnce(char* msg,int msglen,bool bNewCopy = true,bool bNeedFreeMsg = false);
	bool BuildOneMessageFromParselist(Protocol3 *proto);
	void Add2TempParse(char* msg,int msglen,bool bNewCopy = true);
	bool ReMallocOneMsg(int len);
private:
	std::map<int,Protocol3*> m_listBuild;
	unsigned int m_serial;//	1~0xFFFFFFFF
	typedef struct 
	{
		char* pdata;
		int datalen;
	}TmpParse;
	std::map<int,TmpParse> m_tempParseList;
	char *m_oneMsg;
	std::list<char*> m_msglistParsed;
	bool m_bPrint;
};

#endif //_PROTOCO3_H_