#ifndef _GOSCAM_DEF_H_
#define _GOSCAM_DEF_H_


#define GOS_PKT_DATA_LEN	65535
/*
typedef struct _GosProHead
{
	int				magicNo;				// 魔术字 0x67736d70
	int				serialNo;				// 消息序列号
	int				dataLen;				// 消息体长度，不包含消息头
	short			proType;				// 协议类型 1-json, 2-其他
	char			totalPkt;				// 总包数
	char			curPktNo;				// 当前包序号
	char			res[4];					// 预留

}GosProHead;
*/

typedef struct _GosProHead
{
	int				magicNo;				// 魔术字 0x67736d70
	int				serialNo;				// 消息序列号
	short			dataLen;				// 消息体长度，不包含消息头
	char			proType;				// 协议类型 1-json, 2-其他
	char			msgType;				// 消息类型 1-请求， 2-应答， 3-通知
	char			res[4];					// 预留

}GosProHead;

#endif