#include "ProtocolChannel.h"

// #include <winsock2.h>
//
// #pragma comment(lib,"ws2_32.lib")
CProtocolChannel::CProtocolChannel(int nIndex)
{
    InitChannel(nIndex);
    
}

CProtocolChannel::CProtocolChannel(int nDevIndex, int nChn, const char* pUID, const char* pUser, const char* pPwd, int nConnType, EventCallBack eventCB, long lUserParam, int nSessionID, int nConnID, int nTimeOut)
{
    InitChannel(nDevIndex);
    m_nDevChn			= nChn;
    m_eventCB			= eventCB;
    m_lUserParam		= lUserParam;
    m_nSessionID		= nSessionID;
    m_nConnID			= nConnID;
    m_nTimeOut			= nTimeOut;
    m_nProjectType		= nConnType;

	
    
    memcpy(m_strID, pUID, strlen(pUID));
    memcpy(m_strUser, pUser, strlen(pUser));
    memcpy(m_strPwd, pPwd, strlen(pPwd));
}


CProtocolChannel::~CProtocolChannel()
{
     CloseDownLoadChannel();
    if(m_pWriteH264)
    {
        fclose(m_pWriteH264);
        m_pWriteH264 = NULL;
    }
    CloseDev();
    m_mutexRunTask.CloseMutex();
    m_mutexRecvFrame.CloseMutex();
    m_mutexDownLoad.CloseMutex();
}

void CProtocolChannel::InitChannel(int nIndex)
{
    m_nCurIndex				= nIndex;
    m_nSessionID			= -1;
    m_nChannel				= -1;
    m_nDownLoadChannel		= -1;
    m_nConnID				= -1;
    m_nFrameHeadFlag		= -1;
    m_nCreateRecPlayChnParam= -1;
    m_nDevChn				= 0;
	m_nTalkChn				= 0;
    m_streamCB				= NULL;
    m_lStreamParam			= NULL;
    m_eventCB				= NULL;
    m_lUserParam			= NULL;
    m_pDownLoadFile			= NULL;
    m_pWriteH264			= NULL;
    m_nTimeOut				= 0;
    m_nOpenStreamFlag		= 0;
	m_nPaseRecvStreamThread = 0;
    m_nCheckThreadRunFlag	= 0;
    m_dwLastRecvVideoFrameTime = 0;
    m_nOpenAudioStreamFlag		= 0;
    m_nUdpLastRecv			= 0;
    m_nStartDownLoadFlag	= PRO_CHN_DOWNLOAD_FLAG;
    m_dwStartRecvTime		= 0;
    m_nNextDownLoadPacket	= 0;
    m_nReSendFlag			= 0;
    m_nReSendCount			= 0;
    m_nLastDownLoadProcess	= -1;
    m_nReSendTime			= -1;
    m_nUdpLostPktCont		= 0;
    m_nUdpDLTotalPkt		= 0;
    m_nTalkRunFlag			= 0;
    m_dwLastConnTime		= 0;
    m_nRecvFirstIFrameFlag	= 0;
    m_nSendCtrlFlag			= 0;
    m_dwLastCBStreamTime	= 0;
    m_nDownLoadFileLength   = 0;
    m_nCheckTimeinterval	= 15000;
    m_nNVRNum				= 0;
    m_nProjectType			= 0;
	m_nPlayAudioFile		 = 0;
    m_nLightFlag			= -1;
    m_nRecvFirstSDFrame		= 1;
    m_nUdpWriteFileLen = 0;
    
    for(int i = 0; i< MAX_TUTK_CHANNEL; i++)
        m_nNVRChannel[i] = 0;
    
    memset(m_strID, 0, MAX_LOGIN_PARAM_LEN);
    memset(m_strUser, 0, MAX_LOGIN_PARAM_LEN);
    memset(m_strPwd, 0, MAX_LOGIN_PARAM_LEN);
    memset(m_strTalkFile, 0, MAX_TALKFILEPATH_LEN);
    
    strcpy_s(m_tcRecv.m_szName,J_DGB_NAME_LEN,"m_tcRecv");
    m_tcRecv.SetOwner(this);
    m_tcRecv.SetParam(this);
    
    strcpy_s(m_tcConn.m_szName,J_DGB_NAME_LEN,"m_tcConn");
    m_tcConn.SetOwner(this);
    m_tcConn.SetParam(this);
    
    strcpy_s(m_tcDownLoad.m_szName,J_DGB_NAME_LEN,"m_tcDownLoad");
    m_tcDownLoad.SetOwner(this);
    m_tcDownLoad.SetParam(this);
    
    strcpy_s(m_tcTalkSendFile.m_szName,J_DGB_NAME_LEN,"m_tcTalkSendFile");
    m_tcTalkSendFile.SetOwner(this);
    m_tcTalkSendFile.SetParam(this);
    
    strcpy_s(m_tcCheck.m_szName,J_DGB_NAME_LEN,"m_tcCheck");
    m_tcCheck.SetOwner(this);
    m_tcCheck.SetParam(this);
    
    
    strcpy_s(m_tcRecvStream.m_szName,J_DGB_NAME_LEN,"m_tcRecvStream");
    m_tcRecvStream.SetOwner(this);
    m_tcRecvStream.SetParam(this);
    
    strcpy_s(m_tcRunTask.m_szName,J_DGB_NAME_LEN,"m_tcRunTask");
    m_tcRunTask.SetOwner(this);
    m_tcRunTask.SetParam(this);
    
    m_mutexRunTask.CreateMutex();
    m_mutexRecvFrame.CreateMutex();
    m_mutexDownLoad.CreateMutex();

	memset(&m_sStartRecReq, 0, sizeof(m_sStartRecReq));
    
    //m_pWriteH264 = fopen("D:\\tutkH2641.h264", "wb");
}

long CProtocolChannel::CreateStreamChn(int nStreamChn)
{
    int			nResend		= -1;
    
    //m_nChannel = avClientStart(m_nConnID, m_strUser, m_strPwd, m_nTimeOut, &nResend, nStreamChn);
    m_nChannel = avClientStart2(m_nConnID, m_strUser, m_strPwd, m_nTimeOut, NULL, nStreamChn, &nResend);
    if( m_nChannel < 0 )
    {
        JTRACE("CProtocolChannel::CreateStreamChn  avClientStart2 error %d\r\n", m_nChannel);
        return NetProErr_CreateCHN;
    }
    
    return NetProErr_Success;
}

long CProtocolChannel::ConnDev(const char* pUID, const char* pUser, const char* pPwd, int nTimeOut,  int nConnType, EventCallBack eventCB, long lUserParam, int nIsStartRecv)
{
    
    if(m_nChannel >= 0 )
    {
        return NetProErr_Success;
    }
    
    if(!eventCB) return NetProErr_Param;
    
	m_talkChannel.m_eventCB		= eventCB;
	m_talkChannel.m_lUserParam	= lUserParam;
    
    m_eventCB		= eventCB;
    m_lUserParam	= lUserParam;
    
    memcpy(m_strID, pUID, strlen(pUID));
    memcpy(m_strUser, pUser, strlen(pUser));
    memcpy(m_strPwd, pPwd, strlen(pPwd));
    m_nProjectType	= nConnType;
    m_nTimeOut	= nTimeOut;
    
    // 	m_dwLastConnTime = JGetTickCount();
    // 	m_tcCheck.StartThread(RunCheckThread);
	
    m_tcConn.StartThread(RunConnThread);
    return NetProErr_Success;
}
int CProtocolChannel::ConnAction()
{
    //m_mutexRecvFrame.Lock();
    int			nResend		= -1;
    
    m_nSessionID = IOTC_Get_SessionID();
    if( m_nSessionID < 0 )
    {
        if(m_eventCB)
            m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_CONN_ERR, NetProErr_Conn, NULL, m_lUserParam);
        //m_mutexRecvFrame.Unlock();
        return -101;
    }
    
	m_dwLastConnTime = JGetTickCount();
	m_tcCheck.StartThread(RunCheckThread);
    m_nConnID = IOTC_Connect_ByUID_Parallel(m_strID/*m_pUID*/, m_nSessionID);
    JTRACE("---------------------------------m_nConnID = %d\r\n", m_nConnID);
    m_tcCheck.StopThread(true);
    if( m_nConnID < 0 )
    {
        IOTC_Session_Close(m_nSessionID);
        m_nSessionID = -1;
        if(m_eventCB)
		{
			if(IOTC_ER_DEVICE_EXCEED_MAX_SESSION == m_nConnID)
			{
				m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_CONN_ERR, NetProErr_TUTKMaxConn, NULL, m_lUserParam);
			}
			else
			{
				m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_CONN_ERR, NetProErr_Conn, NULL, m_lUserParam);
			}
		}
        //m_mutexRecvFrame.Unlock();
        return -102;
    }
    
    JTRACE("avClientStart2 begin............m_nChannel = %d\r\n", m_nChannel);
    m_nChannel = avClientStart2(m_nConnID, m_strUser, m_strPwd, m_nTimeOut, NULL, PRO_CHN_DEFAULT_CHANNEL, &nResend);
    JTRACE("avClientStart2 end............%d\r\n", nResend);
    if( m_nChannel < 0 )
    {
        IOTC_Connect_Stop_BySID(m_nSessionID);
        IOTC_Session_Close(m_nSessionID);
        m_nSessionID = -1;
        m_nConnID = -1;
        
        if(m_eventCB)
        {
            m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_CONN_ERR, NetProErr_Conn, NULL, m_lUserParam);
            JTRACE("login error [IOTC_Connect_ByUID_Parallel]********************************\r\n");
        }
        else
        {
            JTRACE("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$\r\n");
        }
        //m_mutexRecvFrame.Unlock();
        return NetProErr_Conn;
    }
    if(m_eventCB)
        m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_CONN_SUCCESS, NetProErr_Success, NULL, m_lUserParam);
    
    
    //m_mutexRecvFrame.Unlock();
    m_dwLastConnTime = JGetTickCount();
    
    m_tcRunTask.StartThread(RunTaskThread);
    m_tcRecv.StartThread(RunRecvThread);
    
    return NetProErr_Success;
}
fJThRet CProtocolChannel::RunCheckThread(void* pParam)
{
    int					iIsRun				= 0;
    CJLThreadCtrl*		pThreadCtrl			= NULL;
    CProtocolChannel*	pChannel			= NULL;
    
    pThreadCtrl	= (CJLThreadCtrl*)pParam;
    if ( pThreadCtrl==NULL )
    {
        return 0;
    }
    pChannel	= (CProtocolChannel *)pThreadCtrl->GetOwner();
    if ( pChannel == NULL )
    {
        pThreadCtrl->SetThreadState(THREAD_STATE_STOP);		// ‘À––◊¥Ã¨
        return 0;
    }
    
    iIsRun	= 1;
    pChannel->m_nCheckThreadRunFlag = 1;
    while(iIsRun)
    {
        if ( pThreadCtrl->GetNextAction() == THREAD_STATE_STOP )
        {
            iIsRun = 0;										// ≤ª‘Ÿ‘À–�?
            break;
        }
        
        if(pChannel->CheckAction())
        {
            iIsRun = 0;
            break;
        }
        
        JSleep(5);
    }
    pChannel->m_nCheckThreadRunFlag = 0;
    JTRACE("RunCheckThread exit****************%d\r\n", pChannel->m_nCurIndex);
    pThreadCtrl->NotifyStop();
    iIsRun = 0;
    return 0;
}
int CProtocolChannel::CheckAction()
{
    int nTimeOut = 0;
    int	nCount	 = 0;
    nTimeOut = (int)(JGetTickCount() - m_dwLastConnTime);
    if(m_nChannel < 0 && nTimeOut >= 6000)
    {
        m_dwLastConnTime = JGetTickCount();
        JTRACE("IOTC_Connect_Stop_BySID begin****************%d\r\n", m_nCurIndex);
        IOTC_Connect_Stop_BySID(m_nSessionID);
        JTRACE("IOTC_Connect_Stop_BySID end****************%d\r\n", m_nCurIndex);
        return 1;
    }
    
    if(m_nChannel >= 0 )    // ªÒ»°ªÚ…Ë÷√≤Œ ˝≥¨ ±
    {
        while(nCount < 150 && !m_nSendCtrlFlag)
        {
            nCount ++;
            JSleep(20);
        }
        
        if(!m_nSendCtrlFlag)
        {
            avSendIOCtrlExit(m_nChannel);
            m_nSendCtrlFlag = 1;
            JTRACE("avSendIOCtrlExit stop openStream**************************************\r\n");
            return 1;
        }
        
        m_nSendCtrlFlag = 0;
        return 1;
    }
    return 0;
}

fJThRet CProtocolChannel::RunConnThread(void* pParam)
{
    int					iIsRun				= 0;
    CJLThreadCtrl*		pThreadCtrl			= NULL;
    CProtocolChannel*	pChannel			= NULL;
    
    pThreadCtrl	= (CJLThreadCtrl*)pParam;
    if ( pThreadCtrl==NULL )
    {
        return 0;
    }
    pChannel	= (CProtocolChannel *)pThreadCtrl->GetOwner();
    if ( pChannel == NULL )
    {
        pThreadCtrl->SetThreadState(THREAD_STATE_STOP);		// ‘À––◊¥Ã¨
        return 0;
    }
    JTRACE("start conn dev..............\r\n");
    
    pChannel->m_mutexRecvFrame.Lock();
    pChannel->ConnAction();
    pChannel->m_mutexRecvFrame.Unlock();
    JTRACE("************************************************%d\r\n", pChannel->m_nCurIndex);
    pThreadCtrl->NotifyStop();
    iIsRun = 0;
    JTRACE("RunConnThread exit..............%d\r\n", pChannel->m_nCurIndex);
    return 0;
}



long CProtocolChannel::CloseDev()
{
	m_mutexRunTask.Lock();
	m_TaskMap.clear();
	m_mutexRunTask.Unlock();
    m_tcRunTask.StopThread(true);
    m_tcRecv.StopThread(true);
    m_tcDownLoad.StopThread(true);
    m_mutexRecvFrame.Lock();
    if( m_nChannel >= 0 )
    {
        avClientStop(m_nChannel);
        m_nChannel = -1;
    }
    if(m_nDevChn == 0)
    {
        if( m_nSessionID >= 0 )
        {
            IOTC_Connect_Stop_BySID(m_nSessionID);
            IOTC_Session_Close(m_nSessionID);
            m_nConnID = -1;
            m_nSessionID = -1;
            
        }
    }
    
    m_mutexRecvFrame.Unlock();
    return NetProErr_Success;
}

long CProtocolChannel::SetCheckConnTimeinterval(int nMillisecond)
{
    m_nCheckTimeinterval = nMillisecond;
    
    return 0;
}

long CProtocolChannel::CheckDev()
{
    int nRet = -1;
    
    st_SInfo sInfo;
    memset(&sInfo, 0, sizeof(sInfo));
    
    nRet = IOTC_Session_Check( m_nSessionID, &sInfo );
    
    return nRet;
    
}

fJThRet CProtocolChannel::RunRecvThread(void* pParam)
{
    int					iIsRun				= 0;
    CJLThreadCtrl*		pThreadCtrl			= NULL;
    CProtocolChannel*	pChannel			= NULL;
    
    pThreadCtrl	= (CJLThreadCtrl*)pParam;
    if ( pThreadCtrl==NULL )
    {
        return 0;
    }
    pChannel	= (CProtocolChannel *)pThreadCtrl->GetOwner();
    if ( pChannel == NULL )
    {
        pThreadCtrl->SetThreadState(THREAD_STATE_STOP);		// ‘À––◊¥Ã¨
        return 0;
    }
    
    iIsRun	= 1;
    while(iIsRun)
    {
        if ( pThreadCtrl->GetNextAction() == THREAD_STATE_STOP )
        {
            iIsRun = 0;										// ≤ª‘Ÿ‘À–�?
            break;
        }
        if(pChannel)
			 pChannel->RecvAction();
        //JSleep(6);
    }
    
    pThreadCtrl->NotifyStop();
    iIsRun = 0;
    
    JTRACE("RunRecvThread exit ******************\r\n");
    return 0;
}


fJThRet CProtocolChannel::RunRecvStreamThread(void* pParam)
{
    int					iIsRun				= 0;
    CJLThreadCtrl*		pThreadCtrl			= NULL;
    CProtocolChannel*	pChannel			= NULL;
    
    pThreadCtrl	= (CJLThreadCtrl*)pParam;
    if ( pThreadCtrl==NULL )
    {
        return 0;
    }
    pChannel	= (CProtocolChannel *)pThreadCtrl->GetOwner();
    if ( pChannel == NULL )
    {
        pThreadCtrl->SetThreadState(THREAD_STATE_STOP);		// ‘À––◊¥Ã¨
        return 0;
    }
    
    iIsRun	= 1;
    while(iIsRun)
    {
        if ( pThreadCtrl->GetNextAction() == THREAD_STATE_STOP )
        {
            iIsRun = 0;										// ≤ª‘Ÿ‘À–�?
            break;
        }
        
        pChannel->m_mutexRecvFrame.Lock();
        pChannel->RecvStream();
        pChannel->m_mutexRecvFrame.Unlock();
        
        JSleep(6);
    }
    
    pThreadCtrl->NotifyStop();
    iIsRun = 0;
    
    JTRACE("RunRecvStreamThread exit ******************\r\n");
    return 0;
}



int CProtocolChannel::RecvAction()
{
    
    if( 1 == m_nOpenStreamFlag )
    {
        //m_mutexRecvFrame.Lock();
        //RecvStream();
        //m_mutexRecvFrame.Unlock();
    }
    
    RecvCtrl();
    
    CheckDevConnState();
    
    return 0;
}
void CProtocolChannel::CheckDevConnState()
{
    int nTime = 0;
    nTime = (int)(JGetTickCount() - m_dwLastConnTime);
    if( nTime >= m_nCheckTimeinterval )
    {
        if(CheckDev() != 0 )
        {
            m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_LOSTCONNECTION, 0, NULL, m_lUserParam);
            JTRACE("CProtocolChannel::RecvAction lost connect###########################\r\n");
        }
        m_dwLastConnTime = JGetTickCount();
    }
}

int	CProtocolChannel::RecvCtrl()
{
    unsigned int	nType	= -1;
    int				nRet	= -1;
    char*			pData	= NULL;
    
    pData = new char[PRO_CHN_MAX_RECV_CRTL_SIZE];
    
    //DWORD dwRecvStart = JGetTickCount();
    nRet = avRecvIOCtrl(m_nChannel, &nType, pData, PRO_CHN_MAX_RECV_CRTL_SIZE, 10);
    //JTRACE("avRecvIOCtrl use time = %d\r\n", (int)(JGetTickCount()- dwRecvStart));
    if(nRet >= 0 )
    {
        DealWithCMD(nType,  pData);
    }
	else
	{
		JSleep(5);
	}
    
    SAFE_DELETE(pData);
    
    return 0;
}

int	CProtocolChannel::GetSpecialStreamData(char *pData)
{
    if(m_nProjectType != 1) return 0;
    
    if(m_nFrameHeadFlag == 1)
    {
        FRAMEINFO_t*		pFrameHead		= (FRAMEINFO_t *)pData;
        if(m_nLightFlag != (pFrameHead->reserve1[0] & 0x01))
        {
            m_nLightFlag = (pFrameHead->reserve1[0] & 0x01);
            
            m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_GET_LIGHTSTATE, m_nLightFlag, NULL, m_lUserParam);
            
        }
		return 0;
    }
    else
    {
        gos_frame_head*		pNewFrameHead	= (gos_frame_head *)pData;
        if(pNewFrameHead->nFrameType == gos_special_frame)
        {
            gos_special_data* pSpecialData = (gos_special_data *)(pData+sizeof(gos_frame_head));
            if(m_nLightFlag != pSpecialData->nLightFlag)
            {
                m_nLightFlag = pSpecialData->nLightFlag;
                
                m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_GET_LIGHTSTATE, m_nLightFlag, NULL, m_lUserParam);
            }
			return 1;
        }
        
    }
    
    return 0;
}

int CProtocolChannel::RecvStream()
{
    
    int				nRecvLen				= 0;
    int				nHeadLen				= 0;
    int				nActualFrameSize		= 0;
    int				nExpectedFrameSize		= 0;
    int				nActualFrameInfoSize	= 0;
    unsigned int	nFrameIdx				= 0;
    int				nIsIFrame				= 0;
    int				nFrameRate				= 0;
    int				nSleepTime				= 0;
	int				nIsSleep				= 1;
    DWORD			dwLastRecvVideoTime		= 0;
    DWORD			dwLastRecvVideoIndex	= 0;
    char*			pBuf					= NULL;
    char*			pHead					= NULL;
    FRAMEINFO_t*	pFrameHead				= NULL;
    gos_frame_head*	pNewFrameHead			= NULL;
    gos_frame_head	gosFrameHead;

	if(m_nOpenStreamFlag == 2)
	{
		if(m_nPaseRecvStreamThread == 1) 
		{
			//JTRACE("pasue recv stream************************************************************************\r\n");
			return  0;
		}
	}
    nHeadLen = sizeof(gos_frame_head);
    pBuf	= new char[PRO_CHN_MAX_BUF_SIZE];
    pHead	= new char[PRO_CHN_MAX_HEAD_SIZE_RECV];
    
    if(pBuf && pHead)
    {
       // DWORD dwRecvStart = JGetTickCount();
        nRecvLen = avRecvFrameData2(m_nChannel, (pBuf+nHeadLen), PRO_CHN_MAX_BUF_SIZE-nHeadLen, &nActualFrameSize, &nExpectedFrameSize, pHead, PRO_CHN_MAX_HEAD_SIZE_RECV, &nActualFrameInfoSize, &nFrameIdx);
        //JTRACE("avRecvFrameData2 use time = %d\r\n", (int)(JGetTickCount() - dwRecvStart));
		//JSleep(100);
#if 0
		if(nRecvLen > 0 && m_streamCB)
		{
			  pNewFrameHead = (gos_frame_head*)pHead;
			  if(pNewFrameHead->nFrameType < gos_audio_frame)
			  {
				  //if((int)(JGetTickCount() - m_dwLastCBStreamTime) > 500)
					  JTRACE("nFrameRate = %d, nFrameIndex = %d, nFrameType = %d, nTimestamp = %d, nLen = %d, time = %d*********\r\n", pNewFrameHead->nFrameRate, pNewFrameHead->nFrameNo, pNewFrameHead->nFrameType, pNewFrameHead->nTimestamp, nRecvLen, (int)(JGetTickCount() - m_dwLastCBStreamTime));
				  m_dwLastCBStreamTime = JGetTickCount();
			  }
		}
		SAFE_DELETE(pBuf);
		SAFE_DELETE(pHead);
		return NetProErr_Success;
#endif
        if(nRecvLen > 0 && m_streamCB)
        {
            dwLastRecvVideoIndex = m_dwLastRecvVideoFrameTime;
            dwLastRecvVideoTime = m_dwLastRecvVideoFrameTime;
            if( nActualFrameInfoSize == sizeof(FRAMEINFO_t))
            {
                m_nFrameHeadFlag = 1;  // æ…÷°Õ∑
                pFrameHead = (FRAMEINFO_t *)pHead;
                memset(&gosFrameHead, 0, sizeof(gosFrameHead));
                
                gosFrameHead.nFrameNo = nFrameIdx;
                nIsIFrame = pFrameHead->flags;
                gosFrameHead.nCodeType	= gos_video_H264_AAC;
                nFrameRate = gosFrameHead.nFrameRate = (pFrameHead->reserve1[0] & 0x3F) >> 1;;
                m_dwLastRecvVideoFrameTime = gosFrameHead.nTimestamp	= pFrameHead->timestamp;
				gosFrameHead.nDataSize	= nRecvLen;
                
                if(pFrameHead->flags == 1)
                    gosFrameHead.nFrameType = gos_video_i_frame;
                else
                    gosFrameHead.nFrameType = gos_video_p_frame;
                
                memcpy(pBuf, &gosFrameHead, nHeadLen);
                
                GetSpecialStreamData(pHead);
            }
            else
            {
                pNewFrameHead = (gos_frame_head*)pHead;

				if(m_pWriteH264)
					fwrite(pBuf+nHeadLen,  1, nRecvLen,  m_pWriteH264);

				if(pNewFrameHead->nDataSize != nRecvLen )
				{
					JTRACE("#######################################################%d_%d\r\n", pNewFrameHead->nDataSize, nRecvLen);
				}

				JTRACE("nFrameRate = %d, nFrameIndex = %d, nFrameType = %d, nTimestamp = %d, nLen = %d*********\r\n", pNewFrameHead->nFrameRate, pNewFrameHead->nFrameNo, pNewFrameHead->nFrameType, pNewFrameHead->nTimestamp, nRecvLen);

				if(pNewFrameHead->nFrameType == gos_video_rec_start_frame) m_nRecvFirstSDFrame = 1;

				if(m_nRecvFirstSDFrame == 0  && pNewFrameHead->nFrameType != gos_video_preview_i_frame)
				{
					SAFE_DELETE(pBuf);
					SAFE_DELETE(pHead);
					return NetProErr_Success;
				}

                if(pNewFrameHead->nFrameType == gos_video_i_frame || pNewFrameHead->nFrameType == gos_video_rec_i_frame )
                    nIsIFrame = 1;
				
				
                memcpy(pBuf, pHead, nHeadLen);
                nFrameRate = pNewFrameHead->nFrameRate;
               // m_dwLastRecvVideoFrameTime = pNewFrameHead->nFrameNo;
				if(GetSpecialStreamData(pBuf))
				{
					SAFE_DELETE(pBuf);
					SAFE_DELETE(pHead);
					return NetProErr_Success;
				} 
				
				if(pNewFrameHead->nFrameType > gos_video_b_frame && pNewFrameHead->nFrameType < gos_video_end_frame )
				{
					//JTRACE("nFrameRate = %d, nFrameIndex = %d, nFrameType = %d, nTimestamp = %d, nLen = %d*********\r\n", pNewFrameHead->nFrameRate, pNewFrameHead->nFrameNo, pNewFrameHead->nFrameType, pNewFrameHead->nTimestamp, nRecvLen);
					m_streamCB( m_nCurIndex, m_nDevChn, (unsigned char *)pBuf, nRecvLen+nHeadLen, m_lStreamParam );				
					nIsSleep = 0;
				}
				else if(pNewFrameHead->nFrameType == gos_rec_audio_frame || pNewFrameHead->nFrameType == gos_cut_audio_frame)
				{
					m_streamCB( m_nCurIndex, m_nDevChn, (unsigned char *)pBuf, nRecvLen+nHeadLen, m_lStreamParam );
					nIsSleep = 0;
				}
				else
				{
					dwLastRecvVideoIndex = m_dwLastRecvVideoFrameTime;
					dwLastRecvVideoTime = m_dwLastRecvVideoFrameTime;
					m_dwLastRecvVideoFrameTime = pNewFrameHead->nFrameNo;
				}

				 m_nFrameHeadFlag = 0;
            }
            
            
            if( m_nRecvFirstIFrameFlag == 0 && nIsIFrame)
                m_nRecvFirstIFrameFlag =nIsIFrame;
            
            if(/*m_nRecvFirstIFrameFlag &&*/ nIsSleep)
            {
                if(m_nFrameHeadFlag == 1)
                {
                    if(m_nVideoStreamTimeSpan < 1 || m_nVideoStreamTimeSpan > 130 )
                    {
                        
                        m_nVideoStreamTimeSpan = (int)(m_dwLastRecvVideoFrameTime - dwLastRecvVideoTime);
                        
                        JTRACE("m_nVideoStreamTimeSpan = %d\r\n", m_nVideoStreamTimeSpan);
                    }
                    
                    if(m_dwLastCBStreamTime > 0 && nFrameRate > 0 && dwLastRecvVideoTime > 0 && m_nVideoStreamTimeSpan > 0 && m_nVideoStreamTimeSpan < 130)
                    {
                        if((int)(m_dwLastRecvVideoFrameTime - dwLastRecvVideoTime) <= (m_nVideoStreamTimeSpan+MAX_TUTK_RECVFRAME_TIMESPAN))
                        {
                            nSleepTime = (1000 / nFrameRate) - (int)(JGetTickCount()- m_dwLastCBStreamTime);
                           
							nSleepTime = nSleepTime / 3 * 2 ;
                            if(nSleepTime > (1000/nFrameRate) || nSleepTime < 0) nSleepTime = 0;
                            JSleep(nSleepTime);
                            //JTRACE("nSleepTime = %d\r\n", nSleepTime);
                        }
                    }
                }
                else
                {
                    if( m_dwLastCBStreamTime > 0 && nFrameRate > 0)
                    {
                        //JTRACE("dwLastRecvVideoTime = %d, m_dwLastRecvVideoFrameTime = %d\r\n", dwLastRecvVideoTime, m_dwLastRecvVideoFrameTime);
                        if((int)(m_dwLastRecvVideoFrameTime - dwLastRecvVideoTime) == 1)
                        {
                            nSleepTime = (1000 / nFrameRate) - (int)(JGetTickCount()- m_dwLastCBStreamTime);
							//JTRACE("nSleepTime = %d, %d\r\n", nSleepTime, (int)(JGetTickCount()- m_dwLastCBStreamTime));
                            if(nSleepTime > (1000/nFrameRate+20) || nSleepTime < 0) nSleepTime = 0;
							//if(nIsSleep != 2)
								nSleepTime = nSleepTime / 3 * 2 ;
                            JSleep(nSleepTime);
                          //  JTRACE("nSleepTime = %d, %d\r\n", nSleepTime, (int)(m_dwLastRecvVideoFrameTime - dwLastRecvVideoTime));
                        }
                        else
                        {
						//	JTRACE("\r\n\r\n===================================================================================\r\n\r\n");
                            //JTRACE("LOST FRAME: no sleep %d\r\n", (int)(m_dwLastRecvVideoFrameTime - dwLastRecvVideoTime));
                        }
                        
                    }
                }
                
                
                //JTRACE("call back time = %d\r\n", (int)(JGetTickCount()-m_dwLastCBStreamTime));
                m_streamCB( m_nCurIndex, m_nDevChn, (unsigned char *)pBuf, nRecvLen+nHeadLen, m_lStreamParam );
                if(nIsSleep != 2)
				{
					m_dwLastCBStreamTime = JGetTickCount();
				}
				else
				{
					if(pNewFrameHead->nFrameType > gos_video_b_frame && pNewFrameHead->nFrameType <= gos_video_rec_end_frame )	
						m_dwLastCBStreamTime = JGetTickCount();
				}
            }
            
        }
        
        if(!m_nOpenAudioStreamFlag)
        {
            SAFE_DELETE(pBuf);
            SAFE_DELETE(pHead);
            return NetProErr_Success;
        }
        
        memset(pBuf, 0, PRO_CHN_MAX_BUF_SIZE);
        memset(pHead, 0, PRO_CHN_MAX_HEAD_SIZE_RECV);
        nRecvLen = avRecvAudioData(m_nChannel, (pBuf+nHeadLen), PRO_CHN_MAX_BUF_SIZE, pHead, PRO_CHN_MAX_HEAD_SIZE_RECV, &nFrameIdx);
        if(nRecvLen > 0 && m_streamCB && m_nFrameHeadFlag >= 0)
        {
            if(m_nFrameHeadFlag == 1)
            {
                GetSpecialStreamData(pHead);
                pFrameHead = (FRAMEINFO_t*)pHead;
                
                memset(&gosFrameHead, 0, sizeof(gosFrameHead));
                
                gosFrameHead.nFrameNo = nFrameIdx;
                gosFrameHead.nFrameType = gos_audio_frame;
                gosFrameHead.nCodeType	= gos_audio_AAC;
                gosFrameHead.nFrameRate = 16000;
                gosFrameHead.nTimestamp	= pFrameHead->timestamp;
                gosFrameHead.nDataSize	= nRecvLen;
                
                memcpy(pBuf, &gosFrameHead, nHeadLen);
            }
            else
            {
                pNewFrameHead = (gos_frame_head *)pHead;
                memcpy(pBuf, pHead, nHeadLen);
                if(GetSpecialStreamData(pBuf))
				{
					SAFE_DELETE(pBuf);
					SAFE_DELETE(pHead);
					return NetProErr_Success;
				}
				// JTRACE("nFrameRate = %d, nFrameIndex = %d, nFrameType = %d, nTimestamp = %d, nLen = %d\r\n", pNewFrameHead->nFrameRate, pNewFrameHead->nFrameNo, pNewFrameHead->nFrameType, pNewFrameHead->nTimestamp, nRecvLen);
            }
            
            //if(m_nRecvFirstIFrameFlag)
                m_streamCB( m_nCurIndex, m_nDevChn, (unsigned char *)pBuf, nRecvLen+nHeadLen, m_lStreamParam );
        }
        
    }
    
    SAFE_DELETE(pBuf);
    SAFE_DELETE(pHead);
    return NetProErr_Success;
}

long CProtocolChannel::OpenStream(int nChannel, char* pPassword, eNetStreamType eType, long lTimeSeconds, long lTimeZone, StreamCallBack streamCB, long lUserParam)
{
    int nRet		= 0;
    SMsgAVIoctrlAVStream	sAVStream = {0};

	if( m_streamCB == NULL)
	{
		m_streamCB		= streamCB;
		m_lStreamParam	= lUserParam;
	}

	if(eType == NETPRO_STREAM_REC)
	{
		//m_nOpenAudioStreamFlag = 1;
		if(!m_nOpenStreamFlag)
			m_tcRecvStream.StartThread(RunRecvStreamThread);

		m_nOpenStreamFlag = 2;
		m_nPaseRecvStreamThread = 0;
		return 0;
	}
    sAVStream.channel	  = nChannel;
    sAVStream.reserved[0] = lTimeSeconds;
    sAVStream.reserved[1] = lTimeZone;
	memset(sAVStream.password, '\0', sizeof(sAVStream.password));

	if(pPassword)
	{
		memcpy(sAVStream.password, pPassword, strlen(pPassword));
	}
    m_nFrameHeadFlag	  = -1;
    m_nVideoStreamTimeSpan = 0;
    m_dwLastRecvVideoFrameTime = 0;
    m_nLightFlag			= -1;
    
    if( m_nChannel < 0 ) return NetProErr_NoConn;
    

	DWORD dw = JGetTickCount();
	avClientCleanBuf(m_nChannel);
	JTRACE("avClientCleanBuf ---------------------%d\r\n", (int)(JGetTickCount() - dw));

  
    
    if(eType == NETPRO_STREAM_VIDEO || eType == NETPRO_STREAM_ALL)
    {
        m_nRecvFirstSDFrame = 1;
        m_nSendCtrlFlag = 0;
        m_tcCheck.StartThread(RunCheckThread);
        nRet = avSendIOCtrl(m_nChannel, IOTYPE_USER_IPCAM_START, (char*)&sAVStream, sizeof(SMsgAVIoctrlAVStream));
        if(m_nSendCtrlFlag)
        {
            return NetProErr_OpenStream;
        }
        m_nSendCtrlFlag = 1;
        if(nRet != AV_ER_NoERROR)
        {
            //m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_OPENSTREAM_RET, NetProErr_OPENVIDEO, NULL, m_lUserParam);
            return NetProErr_OpenStream;
        }
#if 1
        while(1)
        {
            //JTRACE("m_nCheckThreadRunFlag = %d======================\r\n", m_nCheckThreadRunFlag);
            if(!m_nCheckThreadRunFlag) break;
            JSleep(5);
        }
#endif
        
        m_dwLastCBStreamTime = 0;
        if(!m_nOpenStreamFlag)
            m_tcRecvStream.StartThread(RunRecvStreamThread);
        
        m_nOpenStreamFlag = 1;
    }
    
    if(eType == NETPRO_STREAM_AUDIO || eType == NETPRO_STREAM_ALL)
    {
        m_nSendCtrlFlag = 0;
        JTRACE("RunCheckThread second*********\r\n");
        m_tcCheck.StartThread(RunCheckThread);
        
        nRet = avSendIOCtrl(m_nChannel, IOTYPE_USER_IPCAM_AUDIOSTART, (char*)&sAVStream, sizeof(SMsgAVIoctrlAVStream));
        if(m_nSendCtrlFlag)
        {
            return NetProErr_OpenStream;
        }
        m_nSendCtrlFlag = 1;
        if(nRet != AV_ER_NoERROR)
        {
            //m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_OPENSTREAM_RET, NetProErr_OPENAUDIO, NULL, m_lUserParam);
            return NetProErr_OpenStream;
        }
       // while(m_nCheckThreadRunFlag);
        while(1)
        {
            //JTRACE("m_nCheckThreadRunFlag = %d======================\r\n", m_nCheckThreadRunFlag);
            if(!m_nCheckThreadRunFlag) break;
            JSleep(5);
        }

        m_nOpenAudioStreamFlag = 1;
    }
    
    
    //m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_OPENSTREAM_RET, NetProErr_Success, NULL, m_lUserParam);
    
    //m_tcRecvStream.StartThread(RunRecvStreamThread);
    return NetProErr_Success;
}

long CProtocolChannel::PasueRecvStream( int nChannel, int nPasueFlag)
{
	if(m_nOpenStreamFlag != 2) return NetProErr_Success;

	if(m_nPaseRecvStreamThread == nPasueFlag) return NetProErr_Success;

	m_nPaseRecvStreamThread = nPasueFlag;
	
	 return NetProErr_Success;
}

long CProtocolChannel::CloseStream(int nChannel, eNetStreamType eType)
{
    //m_mutexRecvFrame.Lock();
    int nRet		= 0;
	SMsgAVIoctrlAVStream	sAVStream = {0};
	sAVStream.channel	  = nChannel;
    if( m_nChannel < 0 ) return NetProErr_NoConn;


	if(eType == NETPRO_STREAM_REC)
	{
		m_nPaseRecvStreamThread = 0;
		 m_tcRecvStream.StopThread(true);
		 m_nOpenStreamFlag = 0;
		 
			/* m_nSendCtrlFlag = 0;
		 m_tcCheck.StartThread(RunCheckThread);
		 nRet = avSendIOCtrl(m_nChannel, IOTYPE_USER_IPCAM_STOP_PLAY_RECORD_REQ, NULL, 0);
		 if(m_nSendCtrlFlag)
			{
				return NetProErr_CloseStream;
			}
		 m_nSendCtrlFlag = 1;
		 if(nRet != AV_ER_NoERROR)
			{
				return NetProErr_CloseStream;
			}
		 //while(m_nCheckThreadRunFlag);
		 while(1)
			{
				//JTRACE("m_nCheckThreadRunFlag = %d======================\r\n", m_nCheckThreadRunFlag);
				if(!m_nCheckThreadRunFlag) break;
				JSleep(5);
			}*/
		 return 0;
	}
    
	if(eType == NETPRO_STREAM_VIDEO || eType == NETPRO_STREAM_ALL)
	{
		m_nRecvFirstIFrameFlag = 0;
		m_nVideoStreamTimeSpan = 0;
		m_dwLastRecvVideoFrameTime = 0;
		if(!m_nOpenStreamFlag) return NetProErr_Success;
		m_tcRecvStream.StopThread(true);
		m_streamCB		= NULL;
		m_lStreamParam	= NULL;
		m_nOpenStreamFlag = 0;

		m_nSendCtrlFlag = 0;
		m_tcCheck.StartThread(RunCheckThread);
		nRet = avSendIOCtrl(m_nChannel, IOTYPE_USER_IPCAM_STOP, (char*)&sAVStream, sizeof(SMsgAVIoctrlAVStream));
		if(m_nSendCtrlFlag)
		{
			return NetProErr_CloseStream;
		}
		m_nSendCtrlFlag = 1;
		if(nRet != AV_ER_NoERROR)
		{
			return NetProErr_CloseStream;
		}
		//while(m_nCheckThreadRunFlag);
		while(1)
		{
			//JTRACE("m_nCheckThreadRunFlag = %d======================\r\n", m_nCheckThreadRunFlag);
			if(!m_nCheckThreadRunFlag) break;
			JSleep(5);
		}

	}

    if(m_nOpenAudioStreamFlag)
    {
        if(eType == NETPRO_STREAM_AUDIO || eType == NETPRO_STREAM_ALL)
        {
            m_nSendCtrlFlag = 0;
            m_tcCheck.StartThread(RunCheckThread);
            nRet = avSendIOCtrl(m_nChannel, IOTYPE_USER_IPCAM_AUDIOSTOP, (char*)&sAVStream, sizeof(SMsgAVIoctrlAVStream));
            if(m_nSendCtrlFlag)
            {
                return NetProErr_OpenStream;
            }
            m_nSendCtrlFlag = 1;
            if(nRet != AV_ER_NoERROR)
            {
                return NetProErr_CloseStream;
            }
           // while(m_nCheckThreadRunFlag);
            while(1)
            {
                //JTRACE("m_nCheckThreadRunFlag = %d======================\r\n", m_nCheckThreadRunFlag);
                if(!m_nCheckThreadRunFlag) break;
                JSleep(5);
            }

            m_nOpenAudioStreamFlag = 0;
        }
    }
    
    //	m_mutexRecvFrame.Unlock();
    return NetProErr_Success;
}

long CProtocolChannel::RecDownload(int nChannel, const char* pFileName, char *pSrcFileName)
{
    int nRet = -1;
    
    m_sStartRecReq.channel = nChannel;
    sprintf(m_sStartRecReq.filename, "%s", pSrcFileName);
    
    //strcpy(m_sStartRecReq.filename, pSrcFileName);
    m_nNextDownLoadPacket	 = 0;
    m_nUdpLastRecv			 = 0;
    m_nReSendFlag			 = 0;
    m_nLastDownLoadProcess	 = -1;
    m_nReSendTime			 = -1;
    m_nReSendCount			 = 0;
    m_nUdpLostPktCont		 = 0;
    m_nUdpDLTotalPkt		 = 0;
    m_dwStartRecvTime		 = 0;
    
    m_nVectorLost.clear();
    
    
    if( m_nChannel < 0 ) return NetProErr_NoConn;
    
    if(m_nDownLoadChannel >= 0 ) return NetProErr_DOWNLOADING;
    
    if(m_pDownLoadFile)
    {
        fclose(m_pDownLoadFile);
        m_pDownLoadFile = NULL;
    }
    
    m_nDownLoadFileLength = 0;
    m_pDownLoadFile = fopen(pFileName, "wb");
    
    if(!m_pDownLoadFile) return NetProErr_OPENFILE;
    
    memset(&m_sInfo, 0, sizeof(m_sInfo));
    nRet = IOTC_Session_Check( m_nSessionID, &m_sInfo );
    
    if(nRet != 0 ) return NetProErr_GETMODE;
    
    m_tcDownLoad.StartThread(RunDownLoadRecThread);
    
    m_nUdpWriteFileLen = 0;
    
    return NetProErr_Success;
}

int	CProtocolChannel::ConnDownLoadChannel(int nCallBackFlag, int nDownLoadType)
{
    int				nCount				= 0;
    int				nResend				= 0;
    int				nRet				= 0;
    
    
    m_nStartDownLoadFlag = PRO_CHN_DOWNLOAD_FLAG;
    
    nRet = avSendIOCtrl(m_nChannel, IOTYPE_USER_IPCAM_GET_RECORDFILE_STOP_REQ, NULL, 0);
    
    if(nRet != 0) return NetProErr_GETPARAM;
    
    m_sStartRecReq.reserved[0] = nDownLoadType;  //UDPœ¬‘ÿ£�?0∆’Õ®∑Ω Ω¥Úø™œ¬‘ÿ£�?1 ÷ÿ¡¨∑Ω �?
    
    nRet = avSendIOCtrl(m_nChannel, IOTYPE_USER_IPCAM_GET_RECORDFILE_START_REQ, (const char*)&m_sStartRecReq, sizeof(SMsgAVIoctrlGetRecordFileStartReq));
    
    if(nRet != 0) return NetProErr_GETPARAM;
    
    while(nCount < 10)
    {
        if(m_nStartDownLoadFlag > PRO_CHN_DOWNLOAD_FLAG)
            break;
        nCount++;
        JSleep(400);
    }
    
    
    if(m_nStartDownLoadFlag == PRO_CHN_DOWNLOAD_FLAG)  // ≥¨ �?
    {
        if(!nCallBackFlag)
            m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOAD_RET, NetProErr_DOWNLOADTimeOut, NULL, m_lUserParam);
        return -1;
    }
    else if(m_nStartDownLoadFlag < 0 ) //  ß∞�?
    {
        if(!nCallBackFlag)
            m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOAD_RET, NetProErr_DOWNLOADERR, m_nStartDownLoadFlag, m_lUserParam);
        return -1;
    }
    CloseDownLoadChannel();
    
    m_nDownLoadChannel = avClientStart2(m_nConnID, m_strUser, m_strPwd, m_nTimeOut, NULL, PRO_CHN_DOWNLOAD_CHANNEL, &nResend);
    if( m_nDownLoadChannel < 0)
    {
        if(!nCallBackFlag)
            m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOAD_RET, NetProErr_DOWNLOADERR, NULL, m_lUserParam);
        return -2;
    }
    
    return 0;
}
int CProtocolChannel::CloseDownLoadChannel()
{
    if( m_nDownLoadChannel >= 0 )
    {
        avClientStop(m_nDownLoadChannel);
        m_nDownLoadChannel = -1;
    }
    return 0;
}

void	CProtocolChannel::CloseDownLoad()
{
    CloseDownLoadChannel();
    
    if(m_pDownLoadFile)
    {
        fflush(m_pDownLoadFile);
        fclose(m_pDownLoadFile);
        m_pDownLoadFile = NULL;
    }
    m_nStartDownLoadFlag = PRO_CHN_DOWNLOAD_FLAG;
    m_dwStartRecvTime = 0;
}
fJThRet CProtocolChannel::RunGetPictureThread(void* pParam)
{
	CJLThreadCtrl*		pThreadCtrl			= NULL;
	CProtocolChannel*	pChannel			= NULL;
	int				iIsRun				= 0;
	int				nRet				= 0;
	RSMsgAVIoctrlRetransmissionReq sSend	= {0};

	pThreadCtrl	= (CJLThreadCtrl*)pParam;
	if ( pThreadCtrl==NULL )
	{
		return 0;
	}
	pChannel	= (CProtocolChannel *)pThreadCtrl->GetOwner();
	if ( pChannel == NULL )
	{
		pThreadCtrl->SetThreadState(THREAD_STATE_STOP);		// ‘À––◊¥Ã¨
		return 0;
	}

	iIsRun	= 1;
	while(iIsRun)
	{
		if ( pThreadCtrl->GetNextAction() == THREAD_STATE_STOP )
		{
			iIsRun = 0;										// ≤ª‘Ÿ‘À–�?
			break;
		}
	
		nRet = pChannel->GetPictureAction();
		if(nRet > 0)
		{
			iIsRun = 0;	
			break;
		}
		
		JSleep(5);
	}

	pThreadCtrl->NotifyStop();
	iIsRun = 0;
	JTRACE("RunGetPictureThread exit **********************\r\n");

	return 0;
}


fJThRet CProtocolChannel::RunDownLoadRecThread(void* pParam)
{
    CJLThreadCtrl*		pThreadCtrl			= NULL;
    CProtocolChannel*	pChannel			= NULL;
    int				iIsRun				= 0;
    int				nRet				= 0;
    RSMsgAVIoctrlRetransmissionReq sSend	= {0};
    
    pThreadCtrl	= (CJLThreadCtrl*)pParam;
    if ( pThreadCtrl==NULL )
    {
        return 0;
    }
    pChannel	= (CProtocolChannel *)pThreadCtrl->GetOwner();
    if ( pChannel == NULL )
    {
        pThreadCtrl->SetThreadState(THREAD_STATE_STOP);		// ‘À––◊¥Ã¨
        return 0;
    }
    pChannel->m_mutexDownLoad.Lock();
    if(pChannel->ConnDownLoadChannel() != 0 )
    {
        pChannel->m_mutexDownLoad.Unlock();
        pThreadCtrl->NotifyStop();
        JTRACE("RunDownLoadRecThread ConnDownLoadChannel exit **********************\r\n");
        return 0;
    }
    pChannel->m_mutexDownLoad.Unlock();
    
#if 0
    sSend.curr_num = 0;
    sSend.channel = pChannel->m_nDownLoadChannel;
    sSend.nextNum_flag = 1;
    
    // ºÃ–¯«Î«�?
    nRet = avSendIOCtrl(pChannel->m_nChannel, IOTYPE_USER_IPCAM_RETRANSMISSION_REQ , (const char*)&sSend, sizeof(RSMsgAVIoctrlRetransmissionReq));
    if(nRet != 0) return 0;
#endif
    
    iIsRun	= 1;
    while(iIsRun)
    {
        if ( pThreadCtrl->GetNextAction() == THREAD_STATE_STOP )
        {
            iIsRun = 0;										// ≤ª‘Ÿ‘À–�?
            break;
        }
        // ¥¶¿Ìœ¬‘ÿ∂Ø◊�?
        pChannel->m_mutexDownLoad.Lock();
        nRet = pChannel->DownLoadAction();
        if(nRet > 0 )
        {
            pChannel->CloseDownLoad();
            if(nRet == 1 ) pChannel->m_eventCB(pChannel->m_nCurIndex, pChannel->m_nDevChn, NETPRO_EVENT_REC_DOWNLOAD_SUCCESS, 100, NULL, pChannel->m_lUserParam); //œ¬‘ÿÕÍ≥�?
            iIsRun = 0;
            JTRACE("*********************************************** %d", pChannel->m_nUdpWriteFileLen);
            pChannel->m_mutexDownLoad.Unlock();// ≤ª‘Ÿ‘À–�?
            break;
        }
        pChannel->m_mutexDownLoad.Unlock();
        JSleep(2);
    }
    
    pThreadCtrl->NotifyStop();
    iIsRun = 0;
    JTRACE("RunDownLoadRecThread exit **********************\r\n");
    
    return 0;
}

int	CProtocolChannel::GetPictureAction()
{		
	 int			nRet					= 0;
	 int			nRecvLen				= 0;
	 char*			pBuf					= NULL;
	 char*			pHead					= NULL;
	 int			nHeadLen				= 0;
	 unsigned int	nFrameIdx				= 0;
	 nHeadLen		=  sizeof(gos_frame_head);

	 pBuf	= new char[PRO_CHN_MAX_BUF_SIZE];
	 pHead	= new char[nHeadLen/*PRO_CHN_MAX_HEAD_SIZE*/];

	 JTRACE("recv picture frame...........................\r\n");
	 nRecvLen = avRecvFrameData(m_nDownLoadChannel, pBuf+nHeadLen, PRO_CHN_MAX_BUF_SIZE -nHeadLen, pHead, nHeadLen, &nFrameIdx);
	 if(nRecvLen > 0)
	 {
		 memcpy(pBuf, pHead, nHeadLen);

		 if(m_streamCB)
			 m_streamCB( m_nCurIndex, m_nDevChn, (unsigned char *)pBuf, nRecvLen+nHeadLen, m_lStreamParam );

		 gos_frame_head* pHead = (gos_frame_head *)pBuf;
		 nRet = 1;
		JTRACE("return picture frame===============================================================\r\n");
		CloseDownLoadChannel();
	 }
	
	 SAFE_DELETE(pBuf);
	 SAFE_DELETE(pHead);
	 return  nRet;
}
int	CProtocolChannel::DownLoadAction()
{
    int				nRecvLen				= 0;
    int				nActualFrameSize		= 0;
    int				nExpectedFrameSize		= 0;
    int				nActualFrameInfoSize	= 0;
    unsigned int	nFrameIdx				= 0;
    char*			pBuf					= NULL;
    char*			pHead					= NULL;
    int				nHeadLen				= 0;
    int				nRet					= 0;
    int				nCount					= 0;
    int				nConnFlag				= -1;
    RSMsgAVIoctrlRetransmissionReq sSend	= {0};
    
    if(m_sInfo.Mode == 0 ) nHeadLen = sizeof(P2P_FILE_PACKET_BUFFER);
    else if(m_sInfo.Mode == 1) nHeadLen = sizeof(FILE_PACKET_HEAD);
    else if(m_sInfo.Mode == 2) nHeadLen = sizeof(LAN_FILE_PACKET_BUFFER);
    else return 0;
    
    pBuf	= new char[PRO_CHN_DOWNLOAD_RECV_SIZE];
    pHead	= new char[nHeadLen/*PRO_CHN_MAX_HEAD_SIZE*/];
    
    if(pBuf && pHead)
    {
        if(m_dwStartRecvTime == 0)
        {
            m_dwStartRecvTime = JGetTickCount();
        }
        //		nRecvLen = avRecvFrameData2(m_nDownLoadChannel, (pBuf), PRO_CHN_DOWNLOAD_RECV_SIZE, &nActualFrameSize, &nExpectedFrameSize, pHead, nHeadLen, &nActualFrameInfoSize, &nFrameIdx);
        
        nRecvLen = avRecvFrameData(m_nDownLoadChannel, pBuf, PRO_CHN_DOWNLOAD_PKT_SIZE, pHead, nHeadLen, &nFrameIdx);
        
        if(nRecvLen > 0 )
        {
            if(m_nStartDownLoadFlag == 1) //TCP
            {
                nRet = TCP_DownLoadRec(pBuf, pHead, nRecvLen);
            }
            else/* if(m_nStartDownLoadFlag == 0 || m_nStartDownLoadFlag == 2)	*/// UDP
            {
                nRet = UDP_DownLoadRec(pBuf, pHead, nRecvLen);
            }
            
            SAFE_DELETE(pBuf);
            SAFE_DELETE(pHead);
            if(nRet == 1 ) return nRet;
        }
        
        if((int)(JGetTickCount() - m_dwStartRecvTime) >= (3*1000) )
        {
            if(m_nStartDownLoadFlag == 1)  // TCP œ¬‘ÿ≥¨ ±
            {
                // Ω” ’≥¨ ± ÷ÿ¡¨3¥Œ£¨»˝¥Œ ß∞‹–Ë÷ÿ–¬œ¬‘�?
                
                do
                {
                    nConnFlag = ConnDownLoadChannel(1, 0);
                    nCount ++;
                    
                } while (nCount < 3 && nConnFlag != 0);
                
                if( nConnFlag != 0 )
                {
                    m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOAD_RET, NetProErr_DOWNLOADERR, NULL, m_lUserParam);
                    return 1;
                }
                
                sSend.curr_num = m_nNextDownLoadPacket;
                sSend.channel = m_nDownLoadChannel;
                sSend.nextNum_flag = 1;
                JTRACE("TCP download timeout£¨resend %d ******* \r\n", m_nNextDownLoadPacket);
                // ºÃ–¯«Î«�?
                nRet = avSendIOCtrl(m_nChannel, IOTYPE_USER_IPCAM_RETRANSMISSION_REQ , (const char*)&sSend, sizeof(RSMsgAVIoctrlRetransmissionReq));
                //JSleep(10);
                //if(nRet != 0 ) return 0;
            }
            else
            {
                if(m_nUdpDLTotalPkt == 0)
                {
                    SAFE_DELETE(pBuf);
                    SAFE_DELETE(pHead);
                    JTRACE("error recv packet count = 0++++++++++++++++++++++++++++++++++++++++\r\n");
                    m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOAD_RET, NetProErr_DOWNLOADINGERR, NULL, m_lUserParam); //≥¨ ± ß∞�?
                    return 1;
                }
                if(m_nReSendTime == -1)
                {
                    int nLostPacketNum = 0;
                    nLostPacketNum = m_nUdpDLTotalPkt - m_nUdpLastRecv;
                    //char strBuf[PRO_CHN_DOWNLOAD_PKT_SIZE] = {0};
                    if(nLostPacketNum > 0 ) // ”–∂™∞¸
                    {
                        for(int i = 0; i < (nLostPacketNum ); i++)
                        {
                            m_nVectorLost.push_back(m_nUdpLastRecv+1+i);
                            JTRACE("LOST PKT %d\r\n", m_nUdpLastRecv+1+i);
                            
                            if(i == (nLostPacketNum -1 )) break;
                            
                            //fwrite(strBuf, 1, PRO_CHN_DOWNLOAD_PKT_SIZE, m_pDownLoadFile);
                        }
                        //fseek(m_pDownLoadFile, (nLostPacketNum-1)*1024*2, SEEK_CUR);
                        
                    }
                    
                }
                ++ m_nReSendTime;
                int nReSendFlag = 2;
                if(m_nStartDownLoadFlag != 2) nReSendFlag = 20;
                
                if(m_nVectorLost.size() > 0 )
                {
                    if(m_nReSendTime < nReSendFlag)
                    {
                        ReGetUDPDownloadPkt();
                        nRet =  0;
                    }
                    else
                    {
                        if(m_nStartDownLoadFlag == 2)
                        {
                            do
                            {
                                nConnFlag = ConnDownLoadChannel(1, 1);
                                nCount ++;
                                
                            } while (nCount < 3 && nConnFlag != 0);
                            
                            if( nConnFlag != 0 )
                            {
                                m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOAD_RET, NetProErr_DOWNLOADERR, NULL, m_lUserParam);
                                SAFE_DELETE(pBuf);
                                SAFE_DELETE(pHead);
                                return 1;
                            }
                            m_nReSendTime = 0;
                            ReGetUDPDownloadPkt();
                        }
                        else
                        {
                            JTRACE("UDP DownLoad REC err.......\r\n");
                            m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOAD_RET, NetProErr_DOWNLOADERR, NULL, m_lUserParam); //≥¨ ± ß∞�?
                            nRet = 1;
                        }
                        
                        
                    }
                }
                
                m_dwStartRecvTime = 0;
                SAFE_DELETE(pBuf);
                SAFE_DELETE(pHead);
                return nRet;
            }
            
            m_dwStartRecvTime = 0;
        }
    }
    
    SAFE_DELETE(pBuf);
    SAFE_DELETE(pHead);
    
    return 0;
}

void CProtocolChannel::ReGetUDPDownloadPkt()
{
    SMsgAVIoctrlFileRetransportReq	udpLostReq;
    memset(&udpLostReq, 0, sizeof(udpLostReq));
    
    if(m_nUdpLostPktCont == 0)
    {
        m_nUdpLostPktCont = m_nVectorLost.size();
        JTRACE("total lost = %d==========================================================\r\n", m_nUdpLostPktCont);
    }
    //∂™∞¸÷ÿ–¬«Î«�?
    if(m_nVectorLost.size() > 255)
    {
        for(int i = 0; i < 255; i++)
            udpLostReq.loss_packet_no[i] = m_nVectorLost[i];
        
        udpLostReq.total_num = 255;
    }
    else
    {
        for(int i = 0; i < m_nVectorLost.size(); i++)
            udpLostReq.loss_packet_no[i] = m_nVectorLost[i];
        
        udpLostReq.total_num = m_nVectorLost.size();
    }
    
    udpLostReq.channel = 0;
    udpLostReq.loss_flag = 1;
    m_nReSendFlag = 1;
    JTRACE("resend time = %d..............................\r\n", m_nReSendTime);
    avSendIOCtrl(m_nChannel/*m_nDownLoadChannel*/,IOTYPE_USER_IPCAM_FILE_RESEND_REQ, (char *)&udpLostReq,sizeof(udpLostReq));
}

int CProtocolChannel::UDP_DownLoadRec(char* pBuf, char* pHead, int nRecvLen)
{
    int				nRet					= 0;
    int				nDownLoadProcess		= 0;
    unsigned int	nCurPacket				= 0;
    int				nLostPacketNum			= 0;
    //char			strBuf[1024*10]			= {0};
    
    m_dwStartRecvTime = JGetTickCount();
    
    if(m_sInfo.Mode == 0 )
    {
        P2P_FILE_PACKET_BUFFER *pPHead = (P2P_FILE_PACKET_BUFFER *)pHead;
        nCurPacket = pPHead->file_head.curr_packet_no;
        if(m_nUdpDLTotalPkt < 1)
            m_nUdpDLTotalPkt = pPHead->file_head.total_packet_num;
        if(m_nDownLoadFileLength == 0)
        {
            m_nDownLoadFileLength = pPHead->file_head.total_file_length;
            m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOAD_RET, (long)m_nDownLoadFileLength, NULL, m_lUserParam);
        }
    }
    else if(m_sInfo.Mode == 1)
    {
        FILE_PACKET_HEAD *pPHead = (FILE_PACKET_HEAD *)pHead;
        nCurPacket = pPHead->curr_packet_no;
        if(m_nUdpDLTotalPkt < 1)
            m_nUdpDLTotalPkt = pPHead->total_packet_num;
        if(m_nDownLoadFileLength == 0)
        {
            m_nDownLoadFileLength = pPHead->total_file_length;
            m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOAD_RET, (long)m_nDownLoadFileLength, NULL, m_lUserParam);
        }
    }
    else if(m_sInfo.Mode == 2)
    {
        LAN_FILE_PACKET_BUFFER *pPHead = (LAN_FILE_PACKET_BUFFER *)pHead;
        nCurPacket = pPHead->file_head.curr_packet_no;
        if(m_nUdpDLTotalPkt < 1)
            m_nUdpDLTotalPkt = pPHead->file_head.total_packet_num;
        if(m_nDownLoadFileLength == 0)
        {
            m_nDownLoadFileLength = pPHead->file_head.total_file_length;
            m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOAD_RET, (long)m_nDownLoadFileLength, NULL, m_lUserParam);
        }
    }
    else
    {
        return 0;
    }
    
    if(nRecvLen != 2048)
    {
        JTRACE("kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk  nRecvLen = %d\r\n", nRecvLen);
    }
    
    if(nCurPacket == 0 ) return 0;
    
    JTRACE("nRecvLen = %d, nCurPacket = %d**********************************\r\n", nRecvLen, nCurPacket);
    if(m_nReSendFlag)
    {
        
        
        for(m_iterator=m_nVectorLost.begin(); m_iterator != m_nVectorLost.end();)
        {
            if(*m_iterator == nCurPacket)
            {
                ++ m_nReSendCount;
                
                
                fseek(m_pDownLoadFile, (nCurPacket-1)*(PRO_CHN_DOWNLOAD_PKT_SIZE), SEEK_SET);
                fwrite(pBuf, 1, nRecvLen, m_pDownLoadFile);
                m_nUdpWriteFileLen += nRecvLen;
                JTRACE("ReSend PKT %d, nTotalPacket %d\r\n", nCurPacket, m_nUdpDLTotalPkt);
                
                if(m_nUdpDLTotalPkt > 0)
                    nDownLoadProcess = 100*(m_nUdpDLTotalPkt + m_nReSendCount - m_nUdpLostPktCont) / m_nUdpDLTotalPkt;
                
                if(m_nLastDownLoadProcess != nDownLoadProcess)
                    m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOADING,nDownLoadProcess /*(nDownLoadProcess > 95) ? 95:nDownLoadProcess*/, NULL, m_lUserParam); //∑µªÿœ¬‘ÿΩ¯∂»
                
                m_nLastDownLoadProcess = nDownLoadProcess;
                m_iterator = m_nVectorLost.erase(m_iterator);
                break;
            }
            ++ m_iterator;
        }
        
        if(m_nReSendCount == m_nUdpLostPktCont) //∂™∞�?£¨÷ÿ¥´ÕÍ≥�? œ¬‘ÿ≥…π¶
        {
            JTRACE("resend success......\r\n");
            m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOADING, 100, NULL, m_lUserParam);
            //m_eventCB(m_nCurIndex, NETPRO_EVENT_REC_DOWNLOAD_SUCCESS, 100, NULL, m_lUserParam); //œ¬‘ÿÕÍ≥�?
            return 1;
        }
        return 0;
    }
    
    //JTRACE("curr_num = %d, nTotalPacket = %d, nRecvLen = %d\r\n", nCurPacket, nTotalPacket, nRecvLen);
    
    nLostPacketNum =  nCurPacket - m_nUdpLastRecv;
    
    if(nLostPacketNum > 1 ) // ”–∂™∞¸
    {
        for(int i = 0; i < (nLostPacketNum -1 ); i++)
        {
            m_nVectorLost.push_back(m_nUdpLastRecv+1+i);
            JTRACE("LOST PKT %d\r\n", m_nUdpLastRecv+1+i);
            //fwrite(strBuf, 1, nRecvLen, m_pDownLoadFile);
        }
        
    }
    
    
    if(nCurPacket < m_nUdpLastRecv)
    {
        JTRACE("ErrorErrorErrorErrorErrorErrorErrorErrorErrorErrorErrorErrorErrorErrorErrorErrorErrorErrorError\r\n");
    }
    
    fseek(m_pDownLoadFile, (nCurPacket-1)*(PRO_CHN_DOWNLOAD_PKT_SIZE), SEEK_SET); //nRecvLen
    fwrite(pBuf, 1, nRecvLen, m_pDownLoadFile);
    m_nUdpWriteFileLen += nRecvLen;
    
    if(m_nUdpDLTotalPkt > 0)
        nDownLoadProcess = 100*(nCurPacket - m_nVectorLost.size()) / m_nUdpDLTotalPkt;
    
    if(m_nLastDownLoadProcess != nDownLoadProcess)
        m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOADING,nDownLoadProcess /*(nDownLoadProcess > 95) ? 95:nDownLoadProcess*/, NULL, m_lUserParam); //∑µªÿœ¬‘ÿΩ¯∂»
    
    m_nLastDownLoadProcess = nDownLoadProcess;
    
    m_nUdpLastRecv = nCurPacket;
    
    if(nCurPacket == m_nUdpDLTotalPkt)
    {
        if(m_nVectorLost.size() == 0 ) // Œ¥∂™∞�?œ¬‘ÿÕÍ≥�?
        {
            m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOADING, 100, NULL, m_lUserParam);
            //m_eventCB(m_nCurIndex, NETPRO_EVENT_REC_DOWNLOAD_SUCCESS, 100, NULL, m_lUserParam);
            return 1;  //œ¬‘ÿÕÍ≥�?
        }
        
    }
    
    return 0;
}


int CProtocolChannel::TCP_DownLoadRec(char* pBuf, char* pHead, int nRecvLen)
{
    int				nRet					= 0;
    int				nDownLoadProcess		= 0;
    int				nTotalPacket			= 0;
    RSMsgAVIoctrlRetransmissionReq sSend	= {0};
    
    m_dwStartRecvTime = JGetTickCount();
    
    if(m_sInfo.Mode == 0 )
    {
        P2P_FILE_PACKET_BUFFER *pPHead = (P2P_FILE_PACKET_BUFFER *)pHead;
        sSend.curr_num = pPHead->file_head.curr_packet_no;
        nTotalPacket = pPHead->file_head.total_packet_num;
        
        if(m_nDownLoadFileLength == 0)
        {
            m_nDownLoadFileLength = pPHead->file_head.total_file_length;
            m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOAD_RET, (long)m_nDownLoadFileLength, NULL, m_lUserParam);
        }
    }
    else if(m_sInfo.Mode == 1)
    {
        FILE_PACKET_HEAD *pPHead = (FILE_PACKET_HEAD *)pHead;
        sSend.curr_num = pPHead->curr_packet_no;
        nTotalPacket = pPHead->total_packet_num;
        
        if(m_nDownLoadFileLength == 0)
        {
            m_nDownLoadFileLength = pPHead->total_file_length;
            m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOAD_RET, (long)m_nDownLoadFileLength, NULL, m_lUserParam);
        }
    }
    else if(m_sInfo.Mode == 2)
    {
        LAN_FILE_PACKET_BUFFER *pPHead = (LAN_FILE_PACKET_BUFFER *)pHead;
        sSend.curr_num = pPHead->file_head.curr_packet_no;
        nTotalPacket = pPHead->file_head.total_packet_num;
        
        if(m_nDownLoadFileLength == 0)
        {
            m_nDownLoadFileLength = pPHead->file_head.total_file_length;
            m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOAD_RET, (long)m_nDownLoadFileLength, NULL, m_lUserParam);
        }
    }
    else
    {
        return 0;
    }
#if 1
    if(m_nNextDownLoadPacket > 0)  //–£—È «∑Ò¡¨–¯∞¸
    {
        if(sSend.curr_num != (m_nNextDownLoadPacket+1))
        {
            JTRACE("lost err packet %d...............\r\n",sSend.curr_num);
            //JTRACE("sSend.curr_num = %d, m_nNextDownLoadPacket = %d\r\n",sSend.curr_num, m_nNextDownLoadPacket);
            // 			sSend.curr_num =  (m_nNextDownLoadPacket -1);
            // 			sSend.channel = m_nDownLoadChannel;
            // 			sSend.nextNum_flag = 1;
            // 			avSendIOCtrl(m_nChannel, IOTYPE_USER_IPCAM_RETRANSMISSION_REQ , (const char*)&sSend, sizeof(RSMsgAVIoctrlRetransmissionReq));
            return 0;
        }
    }
#endif
    if(m_pDownLoadFile)
        fwrite(pBuf, 1, nRecvLen, m_pDownLoadFile);
    
    
    if( sSend.curr_num == nTotalPacket )
    {
        JTRACE("curr_num = %d, nTotalPacket = %d\r\n", sSend.curr_num, nTotalPacket);
        m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOADING, 100, NULL, m_lUserParam); //∑µªÿœ¬‘ÿΩ¯∂»
        //m_eventCB(m_nCurIndex, NETPRO_EVENT_REC_DOWNLOAD_SUCCESS, 100, NULL, m_lUserParam);
        return 1;//œ¬‘ÿÕÍ≥�?
    }
    
    nDownLoadProcess = 100*(sSend.curr_num) / nTotalPacket;
    if(m_nLastDownLoadProcess != nDownLoadProcess)
        m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOADING, nDownLoadProcess, NULL, m_lUserParam); //∑µªÿœ¬‘ÿΩ¯∂»
    
    m_nLastDownLoadProcess = nDownLoadProcess;
    JTRACE("curr_num = %d, nTotalPacket = %d, nDownLoadProcess = %d, nextpkt= %d\r\n", sSend.curr_num, nTotalPacket, nDownLoadProcess, sSend.curr_num);
    
    //sSend.curr_num += 1;  //Ω” ’“ª∞¸∫Û«Î«Ûœ¬“ª∞¸
    sSend.channel = m_nDownLoadChannel;
    sSend.nextNum_flag = 1;
    m_nNextDownLoadPacket = sSend.curr_num  ;
    nRet = avSendIOCtrl(m_nChannel, IOTYPE_USER_IPCAM_RETRANSMISSION_REQ , (const char*)&sSend, sizeof(RSMsgAVIoctrlRetransmissionReq));
    if(nRet != 0)
    {
        return 0;
    }
    return 0;
}


long CProtocolChannel::StopDownload(int nChannel)
{
    int nRet		= 0;
    if( m_nChannel < 0 ) return NetProErr_NoConn;
    
    m_tcDownLoad.StopThread(true);
    
    CloseDownLoad();
    
    return 0;
}


#if 0
int CProtocolChannel::TalkSendFileAction()
{
    int		nSendFileChannel	= -1;
    int		nServerChannel		= -1;
    int		nRet				= -1;
    FILE*	pSendFile			= NULL;
    int		nReadLen			= 0;
    int		nCount				= 0;
    char	strRead[PRO_CHN_MAX_RECV_TALKFILE_SIZE]		= {0};
    FRAMEINFO_t	frameinfo		= {0};
    SMsgAVIoctrlAVStream	avStream = {0};
    memset(&m_sInfo, 0, sizeof(m_sInfo));
#if 0
    nRet = IOTC_Session_Check( m_nSessionID, &m_sInfo );
    if(nRet != 0 )
    {
        JTRACE("TalkSendFileAction   IOTC_Session_Check error\r\n");
        return -1;
    }
    
    nSendFileChannel = IOTC_Session_Get_Free_Channel(m_nConnID);
    if(nSendFileChannel < 0)
    {
        //m_eventCB(m_nCurIndex, );
        JTRACE("TalkSendFileAction   IOTC_Session_Get_Free_Channel error\r\n");
        return -1;
    }
    
    
    avStream.channel = nSendFileChannel;
    m_nTalkRespFlag = 0;
    //ø™∆Ù∂‘Ω≤
    nRet = avSendIOCtrl(m_nChannel, IOTYPE_USER_IPCAM_SPEAKERSTART, (char *)&avStream, sizeof(SMsgAVIoctrlAVStream));
    if(nRet != 0 )
    {
        IOTC_Session_Channel_OFF(m_nConnID, nSendFileChannel);
        JTRACE("TalkSendFileAction   start talk error\r\n");
        return -1;
    }
    
    
    while(m_nTalkRespFlag == 0 && nCount < 10)
    {
        nCount ++ ;
        JSleep(300);
    }
    
    if(m_nTalkRespFlag == 0)
    {
        IOTC_Session_Channel_OFF(m_nConnID, nSendFileChannel);
        JTRACE("TalkSendFileAction   m_nTalkRespFlag \r\n");
        return -1;
    }
    
    //int nReSend = 0;
    //JTRACE("m_nConnID2 = %d\r\n", m_nConnID);
    nServerChannel = avServStart(m_nConnID, NULL, NULL, 5, 0, nSendFileChannel);
    //nServerChannel = avServStart2(m_nConnID, NULL, 5, 0, nSendFileChannel);
    //nServerChannel = avServStart3(m_nConnID, NULL, 5, 0, nSendFileChannel, &nReSend);
    if( nServerChannel < 0 )
    {
        avSendIOCtrl(m_nChannel, IOTYPE_USER_IPCAM_SPEAKERSTOP, (char *)&avStream, sizeof(SMsgAVIoctrlAVStream));
        IOTC_Session_Channel_OFF(m_nConnID, nSendFileChannel);
        JTRACE("TalkSendFileAction   avServStart error %d\r\n", nServerChannel);
        return -1;
    }
#endif
    
    
    
    pSendFile = fopen(m_strTalkFile, "rb");
    if(NULL == pSendFile )
    {
        avSendIOCtrl(m_nChannel, IOTYPE_USER_IPCAM_SPEAKERSTOP, (char *)&avStream, sizeof(SMsgAVIoctrlAVStream));
        IOTC_Session_Channel_OFF(m_nConnID, nSendFileChannel);
        avServStop(nServerChannel);
        JTRACE("open talk file error\r\n");
        return -1;
    }
    
    frameinfo.codec_id = MEDIA_CODEC_AUDIO_AAC;
    frameinfo.flags = AUDIO_SAMPLE_16K << 2;//(AUDIO_SAMPLE_8K << 2) | (AUDIO_DATABITS_16 << 1) | AUDIO_CHANNEL_MONO;
    //frameinfo.cam_index = nSendFileChannel/*m_nChannel*/;
    frameinfo.onlineNum = 0;
    fseek(pSendFile,0L,SEEK_END);
    frameinfo.nByteNum = ftell(pSendFile);
    frameinfo.reserve2 = ftell(pSendFile);
    fseek(pSendFile,0L,SEEK_SET);
    
    do
    {
        
        memset(strRead, 0, PRO_CHN_MAX_RECV_TALKFILE_SIZE);
        nReadLen = fread(strRead, 1, PRO_CHN_MAX_RECV_TALKFILE_SIZE, pSendFile);
        if( nReadLen > 0 )
        {
            
            frameinfo.timestamp = JGetTickCount();
            
            nRet = avSendAudioData(nServerChannel, strRead, nReadLen, (void*)&frameinfo, sizeof(frameinfo));
            if(nRet != 0 )
                JTRACE("avSendAudioData err %d\r\n", nRet);
            else
                JTRACE("avSendAudioData success %d\r\n", nReadLen);
            
            JSleep(1000/16);
        }
        
    } while (nReadLen > 0);
    
    fclose(pSendFile);
    pSendFile = NULL;
    
    
    nRet = avSendIOCtrl(m_nChannel, IOTYPE_USER_IPCAM_SPEAKERSTOP, (char *)&avStream, sizeof(SMsgAVIoctrlAVStream));
    if(nRet != 0 )
    {
        IOTC_Session_Channel_OFF(m_nConnID, nSendFileChannel);
        JTRACE("TalkSendFileAction   stop talk error\r\n");
        return -1;
    }
    
    IOTC_Session_Channel_OFF(m_nConnID, nSendFileChannel);
    avServStop(nServerChannel);
    avServExit(m_nConnID, nServerChannel);
    
    return 0;
}
#endif

long CProtocolChannel::TalkSendFile(int nChannel, const char *pFileName, int nIsPlay)
{
    //if(!m_talkChannel.CheckTalk()) return NetProErr_TALKERR;
    
    
    if(!pFileName)
    {
        return NetProErr_TALKERR;
    }
    m_mutexDownLoad.Lock();
    memset(m_strTalkFile, 0, MAX_TALKFILEPATH_LEN);
    memcpy(m_strTalkFile, pFileName, strlen(pFileName));
	m_nPlayAudioFile = nIsPlay;
    m_nTalkRunFlag	 = 2;
    m_mutexDownLoad.Unlock();
    return NetProErr_Success;
}

fJThRet CProtocolChannel::RunTalkSendFileThread(void* pParam)
{
    CJLThreadCtrl*		pThreadCtrl			= NULL;
    CProtocolChannel*	pChannel			= NULL;
    int					iIsRun				= 1;
    pThreadCtrl	= (CJLThreadCtrl*)pParam;
    if ( pThreadCtrl==NULL )
    {
        return 0;
    }
    pChannel	= (CProtocolChannel *)pThreadCtrl->GetOwner();
    if ( pChannel == NULL )
    {
        pThreadCtrl->SetThreadState(THREAD_STATE_STOP);
        return 0;
    }
    
    while(iIsRun)
    {
        if ( pThreadCtrl->GetNextAction() == THREAD_STATE_STOP )
        {
            iIsRun = 0;
            break;
        }
        pChannel->m_mutexDownLoad.Lock();
        pChannel->TalkSendFileAction();
        pChannel->m_mutexDownLoad.Unlock();
        JSleep(5);
    }
    
    pThreadCtrl->NotifyStop();
    
    JTRACE("RunTalkSendFileThread exit.......");
    return 0;
}
int CProtocolChannel::TalkSendFileAction()
{
    int		nRet				= -1;
    
    if(m_nTalkRunFlag == 1)  // ø™ º∂‘Ω≤
    {
        m_nTalkRunFlag = 0;
        nRet = m_talkChannel.StartTalk(m_nCurIndex, m_nTalkChn, m_nChannel, m_nConnID, m_nSessionID);
        if(nRet < 0 )
        {
            m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_TALK, NetProErr_OPENTALKERR, NULL, m_lUserParam);
            return -1;
        }
        
        m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_TALK, NetProErr_Success, NULL, m_lUserParam);
        
    }
    
    if(m_nTalkRunFlag == 2)  // ∑¢ÀÕAAC Œƒº˛
    {
        m_nTalkRunFlag = 0;
        nRet = m_talkChannel.StartTalk(m_nCurIndex, m_nTalkChn, m_nChannel, m_nConnID, m_nSessionID);
        if(nRet < 0 )
        {
            m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_TALK, NetProErr_OPENTALKERR, NULL, m_lUserParam);
            return -1;
        }
        nRet = m_talkChannel.SendAACfile(m_strTalkFile, m_nPlayAudioFile);
        if(nRet < 0 )
        {
            m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_TALK, NetProErr_TALKERR, NULL, m_lUserParam);
            return -1;
        }
        
        m_talkChannel.StopTalk(m_nChannel, m_nConnID);
        m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_TALK_SENDFILE_SUCCESS, NetProErr_Success, NULL, m_lUserParam);
        
    }
    
    return 0;
}


long CProtocolChannel::TalkStart(int nChannel)
{
    //if( m_nChannel < 0 ) return NetProErr_NoConn;
    m_mutexDownLoad.Lock();
    m_nTalkRunFlag	 = 1;
	m_nTalkChn = nChannel;
    m_mutexDownLoad.Unlock();
    m_tcTalkSendFile.StartThread(RunTalkSendFileThread);
    return 0;
}

long CProtocolChannel::TalkSend(int nChannel, const char* pData, DWORD dwSize)
{
    if(!m_talkChannel.CheckTalk()) return NetProErr_TALKERR;
    
    return m_talkChannel.SendAACData( pData, dwSize );
}

long CProtocolChannel::TalkStop(int nChannel)
{
    JTRACE("stop talk start ************************\r\n");
    
    m_tcTalkSendFile.StopThread(TRUE);
    
    m_talkChannel.StopTalk(m_nChannel, m_nConnID);
    
    JTRACE("stop talk end************************\r\n");
    return 0;
}


long CProtocolChannel::SetStream(int nChannel, eNetVideoStreamType eType)
{
    int nRet		= 0;//
    SMsgAVIoctrlSetStreamCtrlReq setStream = {0};
    
    if( m_nChannel < 0 ) return NetProErr_NoConn;
    
    setStream.channel = nChannel;
    setStream.quality = AVIOCTRL_QUALITY_MAX;
    switch(eType)
    {
        case NETPRO_STREAM_HD:
        {
            setStream.quality = AVIOCTRL_QUALITY_UNKNOWN;
            break;
        }
        case NETPRO_STREAM_SD:
        {
            setStream.quality = AVIOCTRL_QUALITY_MAX;
            break;
        }
    }
    
    m_mutexRunTask.Lock();
    string str((const char *)&setStream, sizeof(SMsgAVIoctrlSetStreamCtrlReq));
    m_TaskMap.insert(pair<int, string>(IOTYPE_USER_IPCAM_SETSTREAMCTRL_REQ, str));
    m_mutexRunTask.Unlock();
    
    //nRet = SendCtrl(m_nChannel, IOTYPE_USER_IPCAM_SETSTREAMCTRL_REQ, (const char*)&setStream, sizeof(setStream));
    
    //if(nRet != 0) return NetProErr_SETPARAM;
    
    return NetProErr_Success;
}



long CProtocolChannel::DelRec(int nChannel, const char *pFileName)
{
    int nRet		= 0;
    SMsgAVIoctrlDelRecordFileReq sReq = {0};
    
    if( m_nChannel < 0 ) return NetProErr_NoConn;
    
    strcpy(sReq.filename, pFileName);
    
    nRet = avSendIOCtrl(m_nChannel, IOTYPE_USER_IPCAM_DEL_RECORDFILE_REQ, (const char*)&sReq, sizeof(sReq));
    
    if(nRet != 0) return NetProErr_SETPARAM;
    
    return NetProErr_Success;
}

long CProtocolChannel::GetDevChnNum()
{
    int	nRet		= -1;
    if( m_nChannel < 0 ) return NetProErr_NoConn;
    
    nRet = avSendIOCtrl(m_nChannel, IOTYPE_USER_IPCAM_GETSUPPORTSTREAM_REQ, NULL, 0);
    
    if(nRet != 0) return NetProErr_SETPARAM;
    
    return NetProErr_Success;
}

int CProtocolChannel::SendCtrl(int nAVChannelID, unsigned int nIOCtrlType, const char *cabIOCtrlData, int nIOCtrlDataSize)
{
    int nRet		= -1;
    if( m_nChannel < 0 ) return NetProErr_NoConn;
    
    
    //m_nSendCtrlFlag = 0;
    
    //m_tcCheck.StartThread(RunCheckThread);
	if(nIOCtrlType == IOTYPE_USER_IPCAM_PLAY_RECORD_REQ)
	{
		SMsgAVIoctrlPlayRecordReq *pReq = (SMsgAVIoctrlPlayRecordReq *)cabIOCtrlData;
		if(pReq->type != 0)
		{
			//DWORD dd = JGetTickCount();
			if(pReq->type == 1)
			{
				m_nRecvFirstSDFrame = 0;
			}
			avClientCleanBuf(m_nChannel);
			//JTRACE("-------------------------%d\r\n", (int)(JGetTickCount() -dd));
		}
		else
		{
			// CloseDownLoadChannel();
		}
	}
    
    nRet = avSendIOCtrl(m_nChannel, nIOCtrlType, cabIOCtrlData, nIOCtrlDataSize);
    //if(m_nSendCtrlFlag)
    //{
    //	return NetProErr_SETPARAM;
    //}
    //m_nSendCtrlFlag = 1;
    
    if(nRet != 0) return NetProErr_SETPARAM;
    
    return NetProErr_Success;
}


long CProtocolChannel::SetParam(int nChannel, eNetProParam eParam, void* lData, int nDataSize, int nTypeTemp)
{
    int nType		= 0;
    
    nType = GetTutkParamType(eParam, nTypeTemp);
    
    if(nType < 0 )	return NetProErr_PARAMTYPE;
    
    if( m_nChannel < 0 ) return NetProErr_NoConn;
    m_mutexRunTask.Lock();
    string str((const char *)lData, nDataSize);
    m_TaskMap.insert(pair<int, string>(nType, str));
    m_mutexRunTask.Unlock();
    
    return 0;
    
    //return SendCtrl(m_nChannel, nType, (const char*)lData, nDataSize);
    
}

long CProtocolChannel::GetParam(int nChannel, eNetProParam eParam, void* lData, int nDataSize)
{
    int nType		= 0;
    int nRet		= -1;
    
    nType = GetTutkParamType(eParam);
    
    if(nType < 0 )	return NetProErr_PARAMTYPE;
    
    if( m_nChannel < 0 ) return NetProErr_NoConn;
    m_mutexRunTask.Lock();
    string str((const char *)lData, nDataSize);
    m_TaskMap.insert(pair<int, string>(nType, str));
    m_mutexRunTask.Unlock();
    
    return 0;
    //return SendCtrl(m_nChannel, nType, (const char*)lData, nDataSize);
}

int CProtocolChannel::GetTutkParamType(eNetProParam eParam, int nTutkType)
{
    int nType				= nTutkType;
    
    switch (eParam)
    {
        case NETPRO_PARAM_GET_DEVCAP:
            nType = IOTYPE_USER_IPCAM_GET_DEVICE_ABILITY_REQ;
            break;
        case NETPRO_PARAM_GET_DEVINFO:
            nType = IOTYPE_USER_IPCAM_GET_ALL_PARAM_REQ;
            break;
        case NETPRO_PARAM_GET_DEVPWD:
            nType = IOTYPE_USER_IPCAM_GET_AUTHENTICATION_REQ;
            break;
        case NETPRO_PARAM_SET_DEVPWD:
            nType = IOTYPE_USER_IPCAM_SET_AUTHENTICATION_REQ;
            break;
        case NETPRO_PARAM_PTZ:
            nType = IOTYPE_USER_IPCAM_PTZ_COMMAND;
            break;
        case NETPRO_PARAM_GET_STREAMQUALITY:
            nType = IOTYPE_USER_IPCAM_GETSTREAMCTRL_REQ;
            break;
        case NETPRO_PARAM_SET_REC:
            nType = IOTYPE_USER_IPCAM_MANUAL_RECORD_REQ;
            break;
        case NETPRO_PARAM_GET_VIDEOMODE:
            nType = IOTYPE_USER_IPCAM_GET_VIDEOMODE_REQ;
            break;
        case NETPRO_PARAM_SET_VIDEOMODE:
            nType = IOTYPE_USER_IPCAM_SET_VIDEOMODE_REQ;
            break;
        case NETPRO_PARAM_SET_MOTIONDETECT:
            nType = IOTYPE_USER_IPCAM_SETMOTIONDETECT_REQ;
            break;
        case NETPRO_PARAM_GET_MOTIONDETECT:
            nType = IOTYPE_USER_IPCAM_GETMOTIONDETECT_REQ;
            break;
        case NETPRO_PARAM_SET_PIRDETECT:
            nType = IOTYPE_USER_IPCAM_SET_PIRDETECT_REQ;
            break;
        case NETPRO_PARAM_GET_PIRDETECT:
            nType = IOTYPE_USER_IPCAM_GET_PIRDETECT_REQ;
            break;
        case NETPRO_PARAM_SET_ALARMCONTROL:
            nType = IOTYPE_USER_IPCAM_SET_ALARM_CONTROL_REQ;
            break;
        case NETPRO_PARAM_GET_ALARMCONTROL:
            nType = IOTYPE_USER_IPCAM_GET_ALARM_CONTROL_REQ;
            break;
        case NETPRO_PARAM_GET_RECMONTHLIST:
            nType = IOTYPE_USER_IPCAM_GET_MONTH_EVENT_LIST_REQ;
            break;
        case NETPRO_PARAM_GET_RECLIST:
            nType = IOTYPE_USER_IPCAM_GET_DAY_EVENT_LIST_REQ;
            break;
        case NETPRO_PARAM_GET_SDINFO:
            nType = IOTYPE_USER_IPCAM_GET_STORAGE_INFO_REQ;
            break;
        case NETPRO_PARAM_SET_SDFORMAT:
            nType = IOTYPE_USER_IPCAM_FORMAT_STORAGE_REQ;
            break;
        case NETPRO_PARAM_GET_WIFIINFO:
            nType = IOTYPE_USER_IPCAM_GETWIFI_REQ;
            break;
        case NETPRO_PARAM_SET_WIFIINFO:
            nType = IOTYPE_USER_IPCAM_SETWIFI_REQ;
            break;
        case NETPRO_PARAM_GET_TEMPERATURE:
            nType = IOTYPE_USER_IPCAM_GET_TEMPERATURE_REQ;
            break;
        case NETPRO_PARAM_SET_TEMPERATURE:
            nType = IOTYPE_USER_IPCAM_SET_TEMPERATURE_REQ;
            break;
        case NETPRO_PARAM_GET_TIMEINFO:
            nType = IOTYPE_USER_IPCAM_GET_TIME_PARAM_REQ;
            break;
        case NETPRO_PARAM_SET_TIMEINFO:
            nType = IOTYPE_USER_IPCAM_SET_TIME_PARAM_REQ;
            break;
        case NETPRO_PARAM_SET_AUDIOALARM:
            nType = IOTYPE_USER_IPCAM_SET_AUDIO_ALARM_REQ;
            break;
        case NETPRO_PARAM_SET_UPDATE:
            nType = IOTYPE_USER_IPCAM_SET_UPDATE_REQ;
            break;
        case NETPRO_PARAM_GET_NVR_REC:
            nType = IOTYPE_USER_NVR_RECORDLIST_REQ;
            break;
        case NETPRO_PARAM_SET_LIGHT:
            nType = IOTYPE_USER_IPCAM_SET_LIGHT_REQ;
            break;
        case NETPRO_PARAM_GET_LIGHTTIME:
            nType = IOTYPE_USER_IPCAM_GET_LIGHT_TIME_REQ;
            break;
        case NETPRO_PARAM_SET_LIGHTTIME:
            nType = IOTYPE_USER_IPCAM_SET_LIGHT_TIME_REQ;
            break;
        case NETPRO_PARAM_DEV_RESET:
            nType = IOTYPE_USER_IPCAM_RESET_REQ;
            break;
        case NETPRO_PARAM_SET_MOBILE_CLENT_TYPE:
            nType = IOTYPE_USER_IPCAM_SET_MOBILE_CLENT_TYPE_REQ;
            break;
		case NETPRO_PARAM_GET_CAMEREA_STATUS:
			nType = IOTYPE_USER_IPCAM_GET_CAMEREA_STATUS_REQ;
			break;
		case NETPRO_PARAM_SET_LOCAL_STORE_CFG:
			nType = IOTYPE_USER_IPCAM_PLAY_RECORD_REQ;
			break;
		case NETPRO_PARAM_SET_LOCAL_STORE_STOP:
			nType = IOTYPE_USER_IPCAM_STOP_PLAY_RECORD_REQ;
			break;
    }
    
    return nType;
}

int CProtocolChannel::DealWithCMD(int nType, char *pData)
{
    eNetProParam eType	= (eNetProParam)-1;
    int		nRet		= 0;
    int		nFlag		= 0;  //1 –Ë“™ªÿµ˜
    
    switch (nType)
    {
        case IOTYPE_USER_IPCAM_GET_DEVICE_ABILITY_RESP:  // ªÒ»°ƒ‹¡¶ºØ”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_GET_DEVCAP;
            nRet = RET_DEVCAP1;
            break;
        }
        case IOTYPE_USER_IPCAM_GET_DEVICE_ABILITY1_RESP:  // ªÒ»°ƒ‹¡¶º�?”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_GET_DEVCAP;
            nRet = RET_DEVCAP2;
            break;
        }
        case IOTYPE_USER_IPCAM_GET_DEVICE_ABILITY2_RESP:  // ªÒ»°ƒ‹¡¶º�?”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_GET_DEVCAP;
            nRet = RET_DEVCAP3;
            break;
        }
        case IOTYPE_USER_IPCAM_GET_ALL_PARAM_RESP:		// ªÒ»°…Ë±∏–≈œ¢”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_GET_DEVINFO;
            break;
        }
        case IOTYPE_USER_IPCAM_GET_AUTHENTICATION_RESP:		// ªÒ»°…Ë±∏√‹¬Î”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_GET_DEVPWD;
            break;
        }
        case IOTYPE_USER_IPCAM_SET_AUTHENTICATION_RESP:	 // …Ë÷√…Ë±∏√‹¬Î”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_SET_DEVPWD;
            SMsgAVIoctrlSetDeviceAuthenticationInfoResp	*sRet = (SMsgAVIoctrlSetDeviceAuthenticationInfoResp	*)pData;
            if(sRet)	nRet = sRet->result;
            else		nRet = NetProErr_SETPARAM;
            break;
        }
        case IOTYPE_USER_IPCAM_GETSTREAMCTRL_RESP:			// ªÒ»° ”∆µ÷ ¡ø”¶¥
        {
            //nFlag = 1;
            eType = NETPRO_PARAM_GET_STREAMQUALITY;
            eNetVideoStreamType	eStreamType;
            SMsgAVIoctrlSetStreamCtrlReq* sRet = (SMsgAVIoctrlSetStreamCtrlReq*)pData;
            
            if(sRet->quality == AVIOCTRL_QUALITY_UNKNOWN)
                eStreamType = NETPRO_STREAM_HD;
            else if(sRet->quality == AVIOCTRL_QUALITY_MAX)
                eStreamType = NETPRO_STREAM_SD;
            
            m_eventCB(m_nCurIndex, m_nDevChn, eType, nRet, (long)eStreamType, m_lUserParam);
            
            break;
        }
        case IOTYPE_USER_IPCAM_MANUAL_RECORD_RESP:			// …Ë÷√¬ºœÒ”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_SET_REC;
            SMsgAVIoctrlManualRecordResp *sRet = (SMsgAVIoctrlManualRecordResp *)pData;
            if(sRet)	nRet = sRet->result;
            else		nRet = NetProErr_SETPARAM;
            break;
        }
        case IOTYPE_USER_IPCAM_GET_VIDEOMODE_RESP:			// ªÒ»° ”∆µƒ£ Ω”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_GET_VIDEOMODE;
            break;
        }
        case IOTYPE_USER_IPCAM_SET_VIDEOMODE_RESP:			// …Ë÷√ ”∆µƒ£ Ω”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_SET_VIDEOMODE;
            SMsgAVIoctrlSetVideoModeResp *sRet = (SMsgAVIoctrlSetVideoModeResp *)pData;
            if(sRet)	nRet = sRet->result;
            else		nRet = NetProErr_SETPARAM;
            break;
        }
        case IOTYPE_USER_IPCAM_GETMOTIONDETECT_RESP:			// ªÒ»°“∆∂Ø’Ï≤‚≤Œ ˝”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_GET_MOTIONDETECT;
            break;
        }
        case IOTYPE_USER_IPCAM_SETMOTIONDETECT_RESP:			// …Ë÷√“∆∂Ø’Ï≤‚≤Œ ˝”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_SET_MOTIONDETECT;
            SMsgAVIoctrlSetMotionDetectResp *sRet = (SMsgAVIoctrlSetMotionDetectResp *)pData;
            if(sRet)	nRet = sRet->result;
            else		nRet = NetProErr_SETPARAM;
            break;
        }
        case IOTYPE_USER_IPCAM_GET_PIRDETECT_RESP:			// ªÒ»°∫ÏÕ‚’Ï≤‚≤Œ ˝”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_GET_PIRDETECT;
            break;
        }
        case IOTYPE_USER_IPCAM_SET_PIRDETECT_RESP:			// …Ë÷√∫ÏÕ‚’Ï≤‚≤Œ ˝”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_SET_PIRDETECT;
            SMsgAVIoctrlSetPirDetectResp *sRet = (SMsgAVIoctrlSetPirDetectResp *)pData;
            if(sRet)	nRet = sRet->result;
            else		nRet = NetProErr_SETPARAM;
            break;
        }
        case IOTYPE_USER_IPCAM_GET_ALARM_CONTROL_RESP:			// ªÒ»°“ªº¸≤º∑¿≤Œ ˝”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_GET_ALARMCONTROL;
            break;
        }
        case IOTYPE_USER_IPCAM_SET_ALARM_CONTROL_RESP:			// …Ë÷√“ªº¸≤º∑¿≤Œ ˝”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_SET_ALARMCONTROL;
            SMsgAVIoctrlSetAlarmControlResp *sRet = (SMsgAVIoctrlSetAlarmControlResp *)pData;
            if(sRet)	nRet = sRet->result;
            else		nRet = NetProErr_SETPARAM;
            break;
        }
        case IOTYPE_USER_IPCAM_GET_MONTH_EVENT_LIST_RESP:			// ªÒ»°¬ºœÒ ±º‰¡–±Ì”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_GET_RECMONTHLIST;
            break;
        }
        case IOTYPE_USER_IPCAM_GET_DAY_EVENT_LIST_RESP:			// ªÒ»°ƒ≥ÃÏ¬ºœÒ¡–±Ì”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_GET_RECLIST;
            break;
        }
        case IOTYPE_USER_IPCAM_GET_STORAGE_INFO_RESP:			// ªÒ»°SDø®–≈œ¢”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_GET_SDINFO;
            break;
        }
        case IOTYPE_USER_IPCAM_FORMAT_STORAGE_RESP:			// ∏Ò ΩªØSDø®”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_SET_SDFORMAT;
            SMsgAVIoctrlFormatStorageResp *sRet = (SMsgAVIoctrlFormatStorageResp *)pData;
            if(sRet)	nRet = sRet->result;
            else		nRet = NetProErr_SETPARAM;
            break;
        }
        case IOTYPE_USER_IPCAM_GETWIFI_RESP:			// ªÒ»°WIFI≤Œ ˝”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_GET_WIFIINFO;
            break;
        }
        case IOTYPE_USER_IPCAM_SETWIFI_RESP:			// …Ë÷√WIFI≤Œ ˝”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_SET_WIFIINFO;
            SMsgAVIoctrlFormatStorageResp *sRet = (SMsgAVIoctrlFormatStorageResp *)pData;
            if(sRet)	nRet = sRet->result;
            else		nRet = NetProErr_SETPARAM;
            break;
        }
        case IOTYPE_USER_IPCAM_GET_TEMPERATURE_RESP:			// ªÒ»°Œ¬∂»±®æØ≤Œ ˝”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_GET_TEMPERATURE;
            break;
        }
        case IOTYPE_USER_IPCAM_SET_TEMPERATURE_RESP:			// …Ë÷√Œ¬∂»±®æØ≤Œ ˝”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_SET_TEMPERATURE;
            SMsgAVIoctrlSetTemperatureAlarmParamResp *sRet = (SMsgAVIoctrlSetTemperatureAlarmParamResp *)pData;
            if(sRet)	nRet = sRet->result;
            else		nRet = NetProErr_SETPARAM;
            break;
        }
        case IOTYPE_USER_IPCAM_GET_TIME_PARAM_RESP:			// ªÒ»° ±º‰≤Œ ˝”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_GET_TIMEINFO;
            break;
        }
        case IOTYPE_USER_IPCAM_SET_TIME_PARAM_RESP:			// …Ë÷√ ±º‰≤Œ ˝”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_SET_TIMEINFO;
            SMsgAVIoctrlSetTimeParamResp *sRet = (SMsgAVIoctrlSetTimeParamResp *)pData;
            if(sRet)	nRet = sRet->result;
            else		nRet = NetProErr_SETPARAM;
            break;
        }
        case IOTYPE_USER_IPCAM_GET_RECORDFILE_START_RESP:			// ø™ ºœ¬‘ÿ¬ºœÒ”¶¥
        {
            SMsgAVIoctrlGetRecordFileStartResp *sRet = (SMsgAVIoctrlGetRecordFileStartResp *)pData;
            if(sRet)	nRet = sRet->result;
            else		nRet = NetProErr_SETPARAM;
            
            if(sRet->result >= 0)
            {
                m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOAD_RET, NetProErr_Success, NULL, m_lUserParam);
            }
            /*else
             {
             m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOAD_RET, NetProErr_DOWNLOADERR, NULL, m_lUserParam);
             }*/
            m_nStartDownLoadFlag = sRet->result;
            
            JTRACE("download rec type = %d===========================\r\n", m_nStartDownLoadFlag);
            
            break;
        }
        case IOTYPE_USER_IPCAM_GET_RECORDFILE_STOP_RESP:
        {
            SMsgAVIoctrlGetRecordFileStopResp *sRet = (SMsgAVIoctrlGetRecordFileStopResp *)pData;
            
            break;
        }
        case IOTYPE_USER_IPCAM_SPEAKERPROCESS_RESP:  //∂‘Ω≤”¶¥
        {
            m_talkChannel.m_nTalkRespFlag = 1;
            JTRACE("talk resp ===================\r\n");
            break;
        }
        case IOTYPE_USER_IPCAM_FILE_RESEND_RESP: //∂™∞¸÷ÿ¥�?
        {
            JTRACE("IOTYPE_USER_IPCAM_FILE_RESEND_RESP............\r\n");
            break;
        }
        case IOTYPE_USER_IPCAM_SETSTREAMCTRL_RESP: //¬Î¡˜«–ª�?
        {
            nFlag = 1;
            SMsgAVIoctrlSetStreamCtrlResp *sRet = (SMsgAVIoctrlSetStreamCtrlResp *)pData;
            eType = NETPRO_EVENT_SET_STREAM;
            if(sRet)	nRet = sRet->result;
            else		nRet = NetProErr_SETPARAM;
            
            m_mutexRecvFrame.Lock();
            if(sRet->result == 0)
            {
                m_nVideoStreamTimeSpan = 0;
                m_dwLastRecvVideoFrameTime = 0;
                m_nRecvFirstIFrameFlag = 0;
            }
            m_mutexRecvFrame.Unlock();
            break;
        }
        case IOTYPE_USER_IPCAM_DEL_RECORDFILE_RESP:
        {
            nFlag = 1;
            SMsgAVIoctrlDelRecordFileResp *sRet = (SMsgAVIoctrlDelRecordFileResp *)pData;
            eType = NETPRO_EVENT_DEL_REC;
            if(sRet)	nRet = sRet->result;
            else		nRet = NetProErr_SETPARAM;
            break;
        }
        case IOTYPE_USER_IPCAM_SET_AUDIO_ALARM_RESP:
        {
            nFlag = 1;
            //SMsgAVIoctrlSetAudioAlarmResp* sRet = (SMsgAVIoctrlSetAudioAlarmResp *)pData;
            eType = NETPRO_PARAM_SET_AUDIOALARM;
            nRet = 0;
            break;
        }
        case IOTYPE_USER_IPCAM_SEND_ANDROID_MOTION_ALARM:  // ∞≤◊ø±®æØ”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_GET_ANDROIDALARM;
            JTRACE("******************  alarm   *****************************\r\n");
            break;
        }
        case IOTYPE_USER_IPCAM_SET_UPDATE_RESP: // …Ë÷√…˝º∂”¶¥
        {
            nFlag = 1;
            //SMsgAVIoctrlSetAudioAlarmResp* sRet = (SMsgAVIoctrlSetAudioAlarmResp *)pData;
            
            SMsgAVIoctrlSetUpdateResp *sRet = (SMsgAVIoctrlSetUpdateResp *)pData;
            eType = NETPRO_PARAM_SET_UPDATE;
            
            if(sRet)	nRet = sRet->result;
            else		nRet = NetProErr_SETPARAM;
            break;
        }
        case IOTYPE_USER_IPCAM_GETSUPPORTSTREAM_RESP: // ªÒ»°Õ®µ¿”¶¥
        {
            
            SMsgAVIoctrlGetSupportStreamResp  *pRet = (SMsgAVIoctrlGetSupportStreamResp  *)pData;
            if(pRet)
            {
                m_nNVRNum = pRet->number;
                for(int i = 0; i < m_nNVRNum; i ++)
                {
                    m_nNVRChannel[i] = pRet->streams[i].channel;
                }
                m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_RET_DEVCHN_NUM, (long)m_nNVRNum, NULL, m_lUserParam);
            }
            
            break;
        }
        case IOTYPE_USER_IPCAM_RECORD_PLAYCONTROL_RESP: // ¬ºœÒøÿ÷∆”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_CTRLT_NVR_REC;
            SMsgAVIoctrlPlayRecordResp  *pRet = (SMsgAVIoctrlPlayRecordResp  *)pData;
            if(pRet)
            {
                if(pRet->command == AVIOCTRL_RECORD_PLAY_START)
                    m_nCreateRecPlayChnParam = pRet->result;
                
                nRet = pRet->result;
            }
            
            break;
        }
        case IOTYPE_USER_NVR_RECORDLIST_RESP: // ªÒ»° NVR ¬ºœÒ¡–±Ì¥Û–°”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_GET_NVR_REC;
            break;
        }
        case IOTYPE_USER_IPCAM_SET_LIGHT_RESP: // …Ë÷√µ∆ø™πÿ”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_SET_LIGHT;
            
            SMsgAVIoctrlSetLightResp *sRet = (SMsgAVIoctrlSetLightResp *)pData;
            if(sRet)	nRet = sRet->result;
            else		nRet = NetProErr_SETPARAM;
            break;
        }
        case IOTYPE_USER_IPCAM_GET_LIGHT_TIME_RESP: // ªÒ»°µ∆¡¡ ±º‰”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_GET_LIGHTTIME;
            break;
        }
        case IOTYPE_USER_IPCAM_SET_LIGHT_TIME_RESP: // …Ë÷√µ∆¡¡ ±º‰”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_SET_LIGHTTIME;
            
            SMsgAVIoctrlSetLightTimeResp *sRet = (SMsgAVIoctrlSetLightTimeResp *)pData;
            if(sRet)	nRet = sRet->result;
            else		nRet = NetProErr_SETPARAM;
            
            break;
        }
        case IOTYPE_USER_IPCAM_RESET_RESP: // ª÷∏¥≥ˆ≥ß…Ë÷√”¶¥
        {
            nFlag = 1;
            eType = NETPRO_PARAM_DEV_RESET;
            SMsgAVIoctrlResetResp *sRet = (SMsgAVIoctrlResetResp *)pData;
            if(sRet)	nRet = sRet->result;
            else		nRet = NetProErr_SETPARAM;
            break;
        }
        case IOTYPE_USER_IPCAM_SET_MOBILE_CLENT_TYPE_RESP: //∞≤◊ø ÷ª˙øÕªß∂À÷√Œª«Î«Û”£�
        {
            nFlag = 1;
            eType = NETPRO_PARAM_SET_MOBILE_CLENT_TYPE;
            SMsgAVIoctrlSetAndriodAlarmMsgResp *sRet = (SMsgAVIoctrlSetAndriodAlarmMsgResp *)pData;
            if(sRet)	nRet = sRet->result;
            else		nRet = NetProErr_SETPARAM;
            break;
        }
		case IOTYPE_USER_IPCAM_STARTRESP:
		{
			nFlag = 1;
			eType = NETPRO_EVENT_OPENSTREAM_RET;
			SMsgAVIoctrlAVStreamResp *sRet = (SMsgAVIoctrlAVStreamResp *)pData;
			if(sRet)
			{	if(sRet->result != 0)
					nRet = NetProErr_OpenStreamPwdErr;
				else
					nRet = sRet->result;
			}
			else
			{
				nRet = NetProErr_OpenStreamPwdErr;
			}
			break;
		}
		case IOTYPE_USER_IPCAM_GET_CAMEREA_STATUS_RESP: //��������״̬
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_CAMEREA_STATUS; //CAMEREA_STATUS
			break;
		}
		case IOTYPE_USER_IPCAM_PLAY_RECORD_RESP:
		{
				nFlag = 1;
				eType = NETPRO_PARAM_SET_LOCAL_STORE_CFG; //CAMEREA_STATUS
				SMsgAVIoctrlPlayPreviewResp *sRet = (SMsgAVIoctrlPlayPreviewResp *)pData;
				/*if(sRet->type == 0 && sRet->result == 0)
				{
					int nResend = 0;
					m_tcDownLoad.StopThread(true);
					CloseDownLoadChannel();
					JTRACE("avClientStart2 start...........................RunGetPictureThread \r\n");
					m_nDownLoadChannel = avClientStart2(m_nConnID, m_strUser, m_strPwd, m_nTimeOut, NULL, sRet->reserved[0], &nResend);
					if( m_nDownLoadChannel < 0)
					{
						m_nDownLoadChannel = avClientStart2(m_nConnID, m_strUser, m_strPwd, m_nTimeOut, NULL, sRet->reserved[0], &nResend);
						if( m_nDownLoadChannel < 0)
						{
							JTRACE("avClientStart2 error  %d...........................RunGetPictureThread \r\n", m_nDownLoadChannel);
							nRet =  NetProErr_SETPARAM;
						}
						else
						{
							nRet =  NetProErr_Success;
							JTRACE("avClientStart2 success...........................RunGetPictureThread \r\n");
							m_tcDownLoad.StartThread(RunGetPictureThread);
						}
					}
					else
					{
						nRet =  NetProErr_Success;
						JTRACE("avClientStart2 success...........................RunGetPictureThread \r\n");
						m_tcDownLoad.StartThread(RunGetPictureThread);
					}

					
				}*/
				nRet = sRet->result;
				break;
		}
		case IOTYPE_USER_IPCAM_STOP_PLAY_RECORD_RESP:
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_LOCAL_STORE_STOP; //CAMEREA_STATUS
			break;
		}

    }
    
    if(nFlag == 1)
        m_eventCB(m_nCurIndex, m_nDevChn, eType, nRet, (long)pData, m_lUserParam);
    
    return 0;
}


fJThRet CProtocolChannel::RunTaskThread(void* pParam)
{
    int					iIsRun				= 0;
    int					nRet				= 0;
    CJLThreadCtrl*		pThreadCtrl			= NULL;	
    CProtocolChannel*	pChannel			= NULL;	
    
    pThreadCtrl	= (CJLThreadCtrl*)pParam;
    if ( pThreadCtrl==NULL )
    {
        return 0;
    }
    pChannel	= (CProtocolChannel *)pThreadCtrl->GetOwner();
    if ( pChannel == NULL )
    {
        pThreadCtrl->SetThreadState(THREAD_STATE_STOP);		// ‘À––◊¥Ã¨
        return 0;
    }
    
    iIsRun	= 1;
    while(iIsRun)
    {
        if ( pThreadCtrl->GetNextAction() == THREAD_STATE_STOP )
        {
            iIsRun = 0;										// ≤ª‘Ÿ‘À–�?
            break;
        }
        
        nRet = pChannel->RunTaskAction();
        if(!nRet)
            JSleep(10);
    }
    
    pThreadCtrl->NotifyStop();
    iIsRun = 0;
    
    JTRACE("RunTaskThread exit ******************\r\n");
    return 0;
}


int CProtocolChannel::RunTaskAction()
{
    int			nType		= 0;
    int			nDataLen	= 0;
    int			nRet		= -1;
    
    
    if(m_TaskMap.size() <= 0) return 0;
    
    //	if(m_nSendCtrlFlag) return 0;
    
    m_TaskIterator = m_TaskMap.begin();
    
    nType = m_TaskIterator->first;
    
    nDataLen = m_TaskIterator->second.length();
    
    nRet = SendCtrl( 0, nType, m_TaskIterator->second.c_str(), nDataLen);
    m_mutexRunTask.Lock();
    m_TaskMap.erase(m_TaskIterator);
    m_mutexRunTask.Unlock();
    if(nRet != 0)
    {
        //  ß∞�?
    }
    
    return 1;
}
