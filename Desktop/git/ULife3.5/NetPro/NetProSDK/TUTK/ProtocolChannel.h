#ifndef _PROTOCOL_CHANNEL_H_
#define _PROTOCOL_CHANNEL_H_


#include "TalkChannel.h"
#include <stdio.h>
#include <vector>
#include <map>
#include <string>
//#include "IOTCAPIs.h"
//#include "AVAPIs.h"
//#include "AVFRAMEINFO.h"
//#include "AVIOCTRLDEFs.h"

using namespace std;

#if (defined _WIN32) || (defined _WIN64)
#include "../NetProSDKAPI.h"
#pragma comment(lib, "./TUTK/libs/windows/AVAPIs")
#pragma comment(lib, "./TUTK/libs/windows/IOTCAPIs")
#pragma comment(lib, "./TUTK/libs/windows/P2PTunnelAPIs")
#pragma comment(lib, "./TUTK/libs/windows/RDTAPIs")
#else
#include "NetProSDKAPI.h"
#endif
#include "AVCommon.h"
#include "JLogWriter.h"
#include "JLThreadCtrl.h"

#define  PRO_CHN_DEFAULT_CHANNEL		0
#define  PRO_CHN_DOWNLOAD_CHANNEL		3
#define  PRO_CHN_DOWNLOAD_RECV_SIZE		20*1024
#define  PRO_CHN_DOWNLOAD_PKT_SIZE		2*1024
#define  PRO_CHN_MAX_BUF_SIZE			500*1024
#define  PRO_CHN_MAX_HEAD_SIZE_RECV		64				
#define  PRO_CHN_MAX_RECV_CRTL_SIZE		1024

#define  PRO_CHN_DOWNLOAD_FLAG			-10
#define  PRO_CHN_LOSTPKT_NUM			1024

#define MAX_LOGIN_PARAM_LEN				64
#define MAX_TALKFILEPATH_LEN			255
#define MAX_TUTK_CHANNEL				66

#define MAX_TUTK_RECVFRAME_TIMESPAN		10



enum eCrtlRet
{
	RET_DEVCAP1 = 101,		// 返回第一版能力集
	RET_DEVCAP2,			// 返回第二版能力集
	RET_DEVCAP3,			// 返回第三版能力集
};

typedef map<int, string>	mTaskMap;
typedef map<int, string>::iterator	mTaskIterator;

class CProtocolChannel
{
public:
	CProtocolChannel(int nIndex);
	CProtocolChannel(int nDevIndex, int nChn, const char* pUID, const char* pUser, const char* pPwd,  int nConnType, EventCallBack eventCB, long lUserParam, int nSessionID, int nConnID, int nTimeOut);
	virtual ~CProtocolChannel();

	long ConnDev( const char* pUID, const char* pUser, const char* pPwd, int nTimeOut,  int nConnType, EventCallBack eventCB, long lUserParam, int nIsStartRecv = 0);
	long CloseDev();
	long GetDevChnNum();					// 获取设备通道数
	long CreateStreamChn(int nStreamChn);
	long CheckDev();
	long SetCheckConnTimeinterval(int nMillisecond);
	long OpenStream(int nChannel, char* pPassword, eNetStreamType eType, long lTimeSeconds, long lTimeZone, StreamCallBack streamCB, long lUserParam);
	long CloseStream(int nChannel, eNetStreamType eType);
	long PasueRecvStream( int nChannel, int nPasueFlag);
	long SetParam(int nChannel, eNetProParam eParam, void* lData, int nDataSize, int nTypeTemp = -1);
	long GetParam(int nChannel, eNetProParam eParam, void* lData, int nDataSize);
	long RecDownload(int nChannel, const char* pFileName, char *pSrcFileName);
	long TalkSendFile(int nChannel, const char *pFileName, int nIsPlay);
	long SetStream(int nChannel, eNetVideoStreamType eLevel);
	long StopDownload(int nChannel);
	long DelRec(int nChannel, const char *pFileName);
	long TalkStart(int nChannel);
	long TalkSend(int nChannel, const char* pData, DWORD dwSize);
	long TalkStop(int nChannel);



	static fJThRet RunRecvThread(void* pParam);
	static fJThRet RunRecvStreamThread(void* pParam);
	static fJThRet RunConnThread(void* pParam);
	static fJThRet RunCheckThread(void* pParam);
	static fJThRet RunDownLoadRecThread(void* pParam);
	static fJThRet RunGetPictureThread(void* pParam);
	static fJThRet RunTalkSendFileThread(void* pParam);
	static fJThRet RunTaskThread(void* pParam);
	int RunTaskAction();
	int CheckAction();
	int RecvAction();
	int ConnAction();
	int	DownLoadAction();
	int	GetPictureAction();
	int TalkSendFileAction();
	int SendCtrl(int nAVChannelID, unsigned int nIOCtrlType, const char *cabIOCtrlData, int nIOCtrlDataSize);
protected:
	int	RecvStream();
	int	RecvCtrl();
	int	GetSpecialStreamData(char *pData);
	int GetTutkParamType(eNetProParam eParam, int nTutkType = -1);
	int DealWithCMD(int nType, char *pData); 
	int	ConnDownLoadChannel(int nCallBackFlag = 0, int nDownLoadType = 0);
	int CloseDownLoadChannel();
	int TCP_DownLoadRec(char* pBuf, char* pHead, int nRecvLen);
	int UDP_DownLoadRec(char* pBuf, char* pHead, int nRecvLen);
	

	void ReGetUDPDownloadPkt();
	void CloseDownLoad();
	void CheckDevConnState();
	void InitChannel(int nIndex);
	
public:
	EventCallBack	m_eventCB;
	long			m_lUserParam;

	StreamCallBack	m_streamCB;
	long			m_lStreamParam;

	int				m_nOpenStreamFlag;  // 当做开启接收线程标志
	int				m_nOpenAudioStreamFlag;
	st_SInfo		m_sInfo;
	char			m_strID[MAX_LOGIN_PARAM_LEN];
	char			m_strUser[MAX_LOGIN_PARAM_LEN];
	char			m_strPwd[MAX_LOGIN_PARAM_LEN];
	char			m_strTalkFile[MAX_TALKFILEPATH_LEN];
	
	int				m_nCreateRecPlayChnParam;
	int				m_nRecvFirstIFrameFlag;
	int				m_nTimeOut;
	int				m_nStartDownLoadFlag;	//开始下载录像标志
	int				m_nDownLoadChannel;		// 下载通道
	int				m_nNextDownLoadPacket;	// 当前下载包
	unsigned int	m_nUdpLastRecv;			// 
	int				m_nReSendFlag;		
	int				m_nReSendCount;			// 已接受UDP重传的包数
	int				m_nReSendTime;			// 发送UDP重传命令次数
	int				m_nUdpLostPktCont;		// UDP 丢包总数
	int				m_nUdpDLTotalPkt;
	int				m_nLastDownLoadProcess;
	int				m_nPlayAudioFile;
	int				m_nTalkRunFlag;			// 对讲任务标志 1 开始对讲  2 发送AAC文件
	DWORD			m_dwLastConnTime;		// 连接时IOTC_Connect_ByUID_Parallel接口超时
	int				m_nProjectType;			// 项目类型
	DWORD			m_dwLastCBStreamTime;
	unsigned int	m_nDownLoadFileLength;	// 录像文件长度
	unsigned int	m_nUdpWriteFileLen;
	
	FILE*			m_pDownLoadFile;
	CMutexLock		m_mutexRecvFrame;
	CMutexLock		m_mutexDownLoad;
	CMutexLock		m_mutexRunTask;
	
protected:
	CTalkChannel	m_talkChannel;

	int				m_nRecvFirstSDFrame;
	int				m_nLightFlag;
	int				m_nFrameHeadFlag;			// 0 FRAMEINFO_t1  1 gos_frame_head
	int				m_nSendCtrlFlag;
	int				m_nCheckThreadRunFlag;
	int				m_nVideoStreamTimeSpan;
	int				m_nPaseRecvStreamThread;

	DWORD			m_dwLastRecvVideoFrameTime;

	vector<int>		m_nVectorLost;
	vector<int>::iterator	m_iterator;	

	FILE*			m_pWriteH264;
	mTaskMap		m_TaskMap;
	mTaskIterator	m_TaskIterator;
	

public:
	int				m_nCurIndex;
	int				m_nSessionID;
	int				m_nConnID;
	int				m_nChannel;
	int				m_nCheckTimeinterval;
	int				m_nDevChn;
	int				m_nTalkChn;

	CJLThreadCtrl	m_tcRunTask;
	CJLThreadCtrl	m_tcCheck;
	CJLThreadCtrl	m_tcRecv;
	CJLThreadCtrl	m_tcRecvStream;
	CJLThreadCtrl	m_tcConn;
	CJLThreadCtrl	m_tcDownLoad;
	CJLThreadCtrl	m_tcTalkSendFile;


	int				m_nNVRNum;
	int				m_nNVRChannel[MAX_TUTK_CHANNEL];
	// 下载录像
	DWORD			m_dwStartRecvTime;
	SMsgAVIoctrlGetRecordFileStartReq	m_sStartRecReq;
	

};

#endif