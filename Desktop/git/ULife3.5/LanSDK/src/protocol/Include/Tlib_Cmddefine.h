#ifndef __COMMAND_DEFINE_HH__
#define __COMMAND_DEFINE_HH__

/// 服务端与客户端协议-查询命令
#define COMMAND_C_S_QUERY_LOGIN_REQ		0x1001
#define COMMAND_S_C_QUERY_LOGIN_ACK		0x1002
#define COMMAND_C_S_QUERY_INFO_REQ		0x1003
#define COMMAND_S_C_QUERY_INFO_ACK		0x1004
#define COMMAND_C_S_QUERY_NULL	    	0x1005

#define COMMAND_C_S_TRANSMIT_LOGIN_REQ		0x2001
#define COMMAND_S_C_TRANSMIT_LOGIN_ACK		0x2002
#define COMMAND_C_S_TRANSMIT_NULL	   	    0x2003
#define COMMAND_C_S_TRANSMIT_DATAINFO_REQ	0x6
#define COMMAND_S_C_TRANSMIT_DATAINFO_ACK	0x7
#define COMMAND_C_S_TRANSMIT_DATA_REQ		0x8
#define COMMAND_S_C_TRANSMIT_DATA_ACK		0x9
#define COMMAND_C_S_TRANSMIT_REQ			0x10
#define COMMAND_S_C_TRANSMIT_ACK			0x11


#endif	//__COMMAND_DEFINE_HH__