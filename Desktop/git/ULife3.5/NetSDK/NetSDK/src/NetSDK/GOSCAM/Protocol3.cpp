#include "Protocol3.h"
#include "JLSocketDef.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


const int g_magic = 0x67736d70; //

Protocol3Header::Protocol3Header()
{
	memset(m_HeadBuf,0,sizeof(m_HeadBuf));
}

Protocol3Header::~Protocol3Header()
{
	
}

bool Protocol3Header::BuildHeader( int msgSerial,unsigned short int bodylen,unsigned char msgtype,unsigned char prototype)
{
		//memcpy(m_HeadBuf,MAGIC_STRING,MAGIC_SIZE);
		*((int*)m_HeadBuf) = htonl(g_magic);
		SetMsgSerial(msgSerial);
		SetBodyLen(bodylen);
		SetProtoType(prototype);
		SetMsgType(msgtype);
// 		*((int*)(m_HeadBuf+4)) = htonl(msgSerial);
// 		*((unsigned short int*)(m_HeadBuf+8)) = htons(bodylen);
// 		*(m_HeadBuf+10) = prototype;
// 		*(m_HeadBuf+11) = msgtype;
		*((int*)(m_HeadBuf+12)) = 0;
		return true;
}

bool Protocol3Header::ParseHeader( char* msg,int msglen )
{
	if (msglen >= Proto3ClientPrivHeadLen)
	{
		memcpy(m_HeadBuf,msg,Proto3ClientPrivHeadLen);
		int tempMagic = ntohl(*((int*)m_HeadBuf));
// 		if (strcmp(magic,MAGIC_STRING) == 0)
		if(tempMagic == g_magic)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	else
	{
		return false;
	}
}

void Protocol3Header::SetMsgSerial( int msgSerial )
{
	*((int*)(m_HeadBuf+4)) = htonl(msgSerial);
}

void Protocol3Header::SetBodyLen( unsigned short int len )
{
	*((unsigned short int*)(m_HeadBuf+8)) = htons(len);
}

void Protocol3Header::SetProtoType( unsigned char type )
{
	*(m_HeadBuf+10) = type;
}

void Protocol3Header::SetMsgType( unsigned char type )
{
	*(m_HeadBuf+11) = type;
}

int Protocol3Header::GetMsgSerial()
{
	//*((int*)(m_HeadBuf+4)) = htonl(msgSerial);
	return ntohl(*((int*)(m_HeadBuf+4)));
}

unsigned short int Protocol3Header::GetBodyLen()
{
	//*((unsigned short int*)(m_HeadBuf+8)) = htons(len);
	return ntohs(*((unsigned short int*)(m_HeadBuf+8)));
}

unsigned char Protocol3Header::GetProtoType()
{
	//*(m_HeadBuf+10) = prototype;
	return *((unsigned char*)(m_HeadBuf+10));
}

unsigned char Protocol3Header::GetMsgType()
{
	//*(m_HeadBuf+11) = msgtype;
	return *((unsigned char*)(m_HeadBuf+11));
}

void Protocol3Header::PrintLog()
{
	printf("serial = %d, msgtype = %d, prototype = %d,bodylen = %d,",GetMsgSerial(),GetMsgType(),GetProtoType(),GetBodyLen());
}

Protocol3Body::Protocol3Body()
{
	m_pbody = NULL;
	m_bodylen = 0;
}

Protocol3Body::Protocol3Body( const Protocol3Body& other )
{
	if(other.m_pbody != NULL && other.m_bodylen > 0)
	{
		m_bodylen = other.m_bodylen;
		if (m_pbody != NULL)
		{
			free(m_pbody);
			m_pbody = NULL;
		}
		if(m_pbody == NULL)
		{
			m_pbody = (char*)malloc(m_bodylen);
			if (m_pbody)
			{
				memcpy(m_pbody,other.m_pbody,other.m_bodylen);
			}
		}
	}
	else
	{
		m_bodylen = 0;
		m_pbody = NULL;
	}
}

Protocol3Body & Protocol3Body::operator=( const Protocol3Body & other )
{
	if (this == &other)
	{
		return *this;
	}

	if(other.m_pbody != NULL && other.m_bodylen > 0)
	{
		m_bodylen = other.m_bodylen;
		if (m_pbody != NULL)
		{
			free(m_pbody);
			m_pbody = NULL;
		}
		if(m_pbody == NULL)
		{
			m_pbody = (char*)malloc(m_bodylen);
			if (m_pbody)
			{
				memcpy(m_pbody,other.m_pbody,other.m_bodylen);
			}
		}
	}
	else
	{
		//理论上不应该出现m_pbody != null && m_bodylen <= 0的情况
		m_bodylen = 0;
		m_pbody = NULL;
	}

	return *this;
}

Protocol3Body::~Protocol3Body()
{
	m_bodylen = 0;
	if (m_pbody)
	{
		free(m_pbody);
		m_pbody = NULL;
	}
}

bool Protocol3Body::NewBody( char* msg,int msglen )
{
	if (msg == NULL || msglen <= 0)
	{
		
		return false;
	}
	if (m_pbody)
	{
		free(m_pbody);
		m_pbody  = NULL;
	}
	if (m_pbody == NULL)
	{
		m_pbody = (char*)malloc(msglen);
		if (m_pbody == NULL)
		{
			
			return false;
		}
		memcpy(m_pbody,msg,msglen);
		m_bodylen = msglen;
	}
	return true;
}

void Protocol3Body::PrintLog()
{
	printf("body = ");
	for (int i = 0; i < GetBodyLen(); i++)
	{
		printf("%c",*(GetBody()+i));
	}
	printf("\n\n\n");
}

int HandleProtocol3::Parse( char* msg,int msglen )
{
	if (!(msg != NULL && msglen > 0))
	{
		return -1;
	}
	printf("start parse, recv msg len = %d\n",msglen);

	int rlt = 0;
	Protocol3 proto;
	if(m_tempParseList.size() > 0)
	{
		//如果待解析队列里面有数据，先拷贝所有队列里面的数据到一块内存
		int totallen = 0;
		std::map<int,TmpParse>::iterator it = m_tempParseList.begin();
		for ( ; it != m_tempParseList.end(); it++)
		{
			totallen += it->second.datalen;
		}
		TmpParse temp = {0};
		if(msglen > 0)
		{
			totallen += msglen;
		}
		temp.datalen = totallen;
		temp.pdata = (char*)malloc(totallen);
		if (temp.pdata == NULL)
		{
			rlt = 2;
		}
		else
		{
			int copylen = 0;
			it = m_tempParseList.begin();
			for ( ; it != m_tempParseList.end(); it++)
			{
				memcpy(temp.pdata+copylen,it->second.pdata,it->second.datalen);
				copylen += it->second.datalen;
				free(it->second.pdata);
				it->second.pdata = NULL;
			}
			if(msglen > 0 && msg)
				memcpy(temp.pdata+copylen,msg,msglen);
			m_tempParseList.clear();
			rlt = ParseOnce(temp.pdata,temp.datalen,false,true);
		}
	}
	else
	{
		if(msg)
			rlt = ParseOnce(msg,msglen);
		else
			rlt = -1;
	}

	if (rlt == 0)
	{
		do 
		{
			if(m_oneMsg)
			{
				m_msglistParsed.push_back(m_oneMsg);
				m_oneMsg = NULL;
			}

			rlt = Parse(NULL,0);
		} while (!rlt);
		rlt = 0;
	}

	return rlt;
}

int HandleProtocol3::Build( char* msg,int msglen ,unsigned char msgtype)
{
 	if ((msg != NULL && msglen > Proto3ClientPrivDataMinLen && msglen <= Proto3ClientPrivDataMaxLen) || 
		(msg == NULL && msglen == 0 && msglen == Proto3ClientPrivDataMinLen))
 	{
		Protocol3 *proto = new Protocol3();
		if (proto == NULL)
		{
			return -1;
		}
		if (m_serial == 0)
		{
			m_serial = 1;
		}
		proto->header.BuildHeader(m_serial,msglen,msgtype);
		if(msg)
		{
			proto->body.NewBody(msg,msglen);
		}
		m_listBuild.insert(std::map<int,Protocol3*>::value_type(m_serial,proto));
		proto->PrintLog(false,m_bPrint);
		m_serial++;
		return 0;
 	}
	else 
	{
		return -1;
	}
}

HandleProtocol3::HandleProtocol3()
{
	m_serial = 1;
	m_oneMsg = NULL;
	m_bPrint = false;
}

HandleProtocol3::~HandleProtocol3()
{
	if (m_oneMsg != NULL)
	{
		free(m_oneMsg);
		m_oneMsg = NULL;
	}
	if ((int)m_msglistParsed.size() > 0)
	{
		int len = (int)m_msglistParsed.size();
		for (int i = 0; i < len; i++)
		{
			char* tempmsg = m_msglistParsed.front();
			m_msglistParsed.pop_front();
			free(tempmsg);
			tempmsg = NULL;
		}
	}

	std::map<int,Protocol3*>::iterator it = m_listBuild.begin();
	for( ; it != m_listBuild.end(); )
	{
		Protocol3* proto = it->second;
		delete proto;
		proto = NULL;
		m_listBuild.erase(it++);
	}
}

void HandleProtocol3::Add2TempParse( char* msg,int msglen ,bool bNewCopy)
{
	if(msglen > 0 && msg != NULL)
	{
		TmpParse temp = {0};
		if (bNewCopy)
		{
			temp.datalen = msglen;
			temp.pdata = (char*)malloc(msglen);
			if (temp.pdata == NULL)
			{
				//异常
			}
			else
			{
				memcpy(temp.pdata,msg,msglen);
				int index = m_tempParseList.size();
				m_tempParseList.insert(std::map<int,TmpParse>::value_type(index,temp));
			}
		}
		else
		{
			temp.pdata = msg;
			temp.datalen = msglen;
			int index = m_tempParseList.size();
			m_tempParseList.insert(std::map<int,TmpParse>::value_type(index,temp));
		}
	}

}

int HandleProtocol3::ParseOnce( char* msg,int msglen ,bool bNewCopy,bool bNeedFreeMsg)
{
	if (msg == NULL || msglen <= 0)
	{
		if (bNeedFreeMsg && msg)
		{
			free(msg);
		}
		return -1;
	}
	int rlt = 0;
	Protocol3 proto;
	if(proto.header.ParseHeader(msg,msglen))
	{
		//解析头正确
		if (proto.header.GetBodyLen() + proto.header.GetHeaderLen() > msglen)
		{
			//如果不够一条数据,加入待解析队列
			Add2TempParse(msg,msglen,bNewCopy);
			rlt = 1;
		}
		else
		{
			//够一条数据,不确定是否是一个完整的指令
			if(proto.body.NewBody(msg + proto.header.GetHeaderLen(),proto.header.GetBodyLen()))
			{
				//构建一条完整的指令
				if (BuildOneMessageFromParselist(&proto))
				{
					//是一条完整的指令
					rlt = 0;

					if (proto.header.GetBodyLen() + proto.header.GetHeaderLen() < msglen)
					{
						//如果多于一条数据，将多余的部分加到待解析队列
						Add2TempParse(msg+proto.header.GetBodyLen() + proto.header.GetHeaderLen(),msglen-proto.header.GetBodyLen() - proto.header.GetHeaderLen());
					}

					proto.PrintLog(true,m_bPrint);
				}
				else
				{
					//不是一条完整的指令,加入待构建队列(在函数BuildOneMessageFromParselist内完成)
					rlt = 3;

					if (proto.header.GetBodyLen() + proto.header.GetHeaderLen() < msglen)
					{
						//如果多于一条数据，将多余的部分加到待解析队列
						rlt = ParseOnce(msg+proto.header.GetBodyLen() + proto.header.GetHeaderLen(),msglen-proto.header.GetBodyLen() - proto.header.GetHeaderLen());

					}
				}
			}
			else
			{
				//异常情况
				rlt = 2;
			}

			if (bNeedFreeMsg && msg)
			{
				free(msg);
			}
		}
	}
	else
	{
		//如果头解析不对，加入待解析队列
		Add2TempParse(msg,msglen,bNewCopy);
		rlt = 1;
	}
	return rlt;
}

bool HandleProtocol3::GetOneBuildMessage(unsigned char** pdst,int &len )
{
	if (pdst == NULL || *pdst != NULL)
	{
		return false;
	}
	len = 0;
	std::map<int,Protocol3*>::iterator it = m_listBuild.begin();
	if ( it != m_listBuild.end())
	{
		len = it->second->header.GetHeaderLen()+ it->second->body.GetBodyLen();
		*pdst = (unsigned char*)malloc(len);
		if (*pdst == NULL)
		{
			return false;
		}
		memcpy(*pdst,it->second->header.GetHeader(),it->second->header.GetHeaderLen());
		int copylen = it->second->header.GetHeaderLen();
		if(it->second->body.GetBody())
		{
			memcpy(*pdst + copylen,it->second->body.GetBody(),it->second->body.GetBodyLen());
		}

		Protocol3* proto = it->second;
		delete proto;
		proto = NULL;
		m_listBuild.erase(it++);
		return true;
	}
	else
	{
		return false;
	}
}

bool HandleProtocol3::SetMsgSerial( unsigned int serial )
{
	m_serial = serial;
	return true;
}

bool HandleProtocol3::BuildOneMessageFromParselist( Protocol3 *proto )
{
	if (proto == NULL)
	{
		return false;
	}
	if(ReMallocOneMsg(proto->body.GetBodyLen() + 1))
	{
		//malloc 失败
		memcpy(m_oneMsg,proto->body.GetBody(),proto->body.GetBodyLen());
		m_oneMsg[proto->body.GetBodyLen()] = '\0';
		return true;
	}
	else
	{
		return false;
	}
}

bool HandleProtocol3::ReMallocOneMsg(int len)
{
	if (m_oneMsg != NULL)
	{
		free(m_oneMsg);
		m_oneMsg = NULL;
	}
	if (m_oneMsg == NULL)
	{
		m_oneMsg = (char*)malloc(len);
		if (m_oneMsg != NULL)
		{
			return true;
		}
	}
	return false;
}

char * HandleProtocol3::GetOneParseMessage()
{
	if ((int)m_msglistParsed.size() > 0)
	{
		char* temp = m_msglistParsed.front();
		m_msglistParsed.pop_front();
		return temp;
	}
	else
	{
		return NULL;
	}
}

void Protocol3::PrintLog(bool bParse,bool bPrint)
{
	if(!bPrint)
		return;
	if(bParse)
	{
		printf("parse proto3: --------------->\n");
	}
	else
	{
		printf("build proto3: --------------->\n");
	}
	header.PrintLog();
	body.PrintLog();
}