#ifndef	_P2P_DOWNLOAD_H_
#define	_P2P_DOWNLOAD_H_

#include "P2pCommon.h"
#include "AVBufferCtrl.h"
#include <vector>
using namespace std;


#define  PRO_CHN_DOWNLOAD_PKT_SIZE		3*1024

class CP2pDownLoad : CP2pCommon
{
public:
	CP2pDownLoad();
	virtual	~CP2pDownLoad();


	int ConnDownLoadChannel(int nDownLoadType = 0);
	int CloseDownLoadChannel();
	int	RecDownload(p2p_transport* pTransPort, const char* pFileName, char *pSrcFileName, char *pUID, int nIndex, EventCallBack eventCB, long lUserParam);
	int CloseDownLoad();
	int StopDownload();



	static void  on_connect_result(void *transport, void* user_data, int status);
	static void  on_disconnect(void *transport, void* user_data, int status);
	static void  on_recv(void *transport, void *user_data, char* data, int len);
	static void  on_device_disconnect(void *transport, void *user_data);


	static fJThRet RunDownLoadRecThread(void* pParam);
	int	DownLoadAction();

public:

	int					m_nConnDownLoadFlag;
	CAVBufferCtrl		m_avbuffCtrl;
	EventCallBack		m_eventCB;
	long				m_lUserParam;
	char				m_strServerAddr[64];
	int					m_nServerPort;
	char				m_strID[64];
	int					m_nIsTcpTransPond;
protected:
	void ReGetUDPDownloadPkt();
	int UDP_DownLoadRec(char* pBuf, int nRecvLen);

protected:

	char				m_strDownLoadFile[P2P_DOWNLOAD_MAX_FILE_LEN];
	char				m_strUID[P2P_DOWNLOAD_MAX_FILE_LEN];
	SMsgAVIoctrlGetRecordFileStartReq	m_sStartRecReq;
	void*				m_pTcpHandle;
	p2p_transport*		m_pTransPort;
	FILE*				m_pDownLoadFile;
	int					m_nDownLoadChannel;
	int					m_nDevIndex;
	int					m_nDevChn;
	CJLThreadCtrl		m_tcDownLoad;

	vector<int>			m_nVectorLost;
	vector<int>::iterator	m_iterator;	

	DWORD				m_dwStartRecvTime;
	int					m_nUdpDLTotalPkt;
	int					m_nDownLoadFileLength;
	int					m_nReSendFlag;
	int					m_nReSendCount;
	int					m_nUdpWriteFileLen;
	int					m_nLastDownLoadProcess;
	int					m_nUdpLastRecv;
	int					m_nUdpLostPktCont;
	int					m_nNextDownLoadPacket;
	int					m_nReSendTime;
	
};

#endif