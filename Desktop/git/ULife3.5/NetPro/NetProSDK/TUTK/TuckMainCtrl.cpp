#include "TuckMainCtrl.h"


CTutkMainCtrl::CTutkMainCtrl(int nIndex)
{
	m_pLoginChn = new CProtocolChannel(nIndex);
	m_pLoginChn->m_nCurIndex	= nIndex;
	m_nDevChnNum			= 0;
	m_nCreateRecChannelFlag = 0;

	for(int i = 0; i < MAX_TUTK_CHANNEL; i++)
	{
		m_protocolChn[i]	= NULL;
		memset(m_strRecFileName[i], 0, sizeof(m_strRecFileName[i]));
	}

	memset(m_strRecFile, 0, sizeof(m_strRecFile));
	m_protocolChn[0] = m_pLoginChn;


	strcpy_s(m_tcCreateRecChn.m_szName,J_DGB_NAME_LEN,"m_tcCreateRecChn");
	m_tcCreateRecChn.SetOwner(this);							
	m_tcCreateRecChn.SetParam(this);

	m_mutexLock.CreateMutex();
}

CTutkMainCtrl::~CTutkMainCtrl()
{
	CloseDev();
	SAFE_DELETE(m_pLoginChn);
	m_mutexLock.CloseMutex();
}

long CTutkMainCtrl::ConnDev( const char* pUID, const char* pUser, const char* pPwd, int nTimeOut, int nConnType, EventCallBack eventCB, long lUserParam )
{
	return m_pLoginChn->ConnDev(pUID, pUser, pPwd, nTimeOut, nConnType, eventCB, lUserParam);
}

long CTutkMainCtrl::CloseDev()
{
	for(int i = 1 ; i< MAX_TUTK_CHANNEL; i++)
	{
		SAFE_DELETE(m_protocolChn[i]);
	}
	return m_pLoginChn->CloseDev();
}

long CTutkMainCtrl::GetDevChnNum()
{
	return m_pLoginChn->GetDevChnNum();
}

long CTutkMainCtrl::CreateRecPlayChn(void* pData, int nDataLen)
{
	int			nRet		= -1;
	SMsgAVIoctrlPlayRecord playRec;	

	//if(m_nCreateRecChannelFlag) return NetProErr_CreateRecPlyChnING;

	memset(&playRec, 0, sizeof(playRec));
	playRec.command = AVIOCTRL_RECORD_PLAY_START;
	memcpy(playRec.fileName, pData, nDataLen);
	memcpy(m_strRecFile, pData, nDataLen);
	
	//nRet = m_pLoginChn->SendCtrl(0, IOTYPE_USER_IPCAM_RECORD_PLAYCONTROL, (const char *)pData, nDataLen);
	m_nCreateRecChannelFlag = 1;
	nRet =  m_pLoginChn->SetParam(0, NETPRO_EVENT_CONN_SUCCESS, (char *)&playRec, sizeof(playRec) ,IOTYPE_USER_IPCAM_RECORD_PLAYCONTROL);
	if(nRet != NetProErr_Success ) 
	{
		m_nCreateRecChannelFlag = 0;
		return nRet;
	}

	//m_tcCreateRecChn.StartThread(RunCreateRecChnActionThread);
	return 0;
}
long CTutkMainCtrl::DeleteRecPlayChn(int nChn)
{
	RecStreamCtrl(nChn, NETPRO_RECSTREAM_PAUSE, 0, AVIOCTRL_RECORD_PLAY_STOP);
	SAFE_DELETE(m_protocolChn[nChn]);
	return 0;
}

long CTutkMainCtrl::RecStreamCtrl(int nChn, eNetRecCtrlType eCtrlType, long lData, int eCtrlType2)
{
	int			nRet		= -1;
	int			nCommand	= -1;
	SMsgAVIoctrlPlayRecord playRec;	

	switch(eCtrlType)
	{
		case NETPRO_RECSTREAM_PAUSE:
			nCommand = AVIOCTRL_RECORD_PLAY_PAUSE;
			break;
		case NETPRO_RECSTREAM_RESUME:
			nCommand = AVIOCTRL_RECORD_PLAY_RESUME;
			break;
		case NETPRO_RECSTREAM_SEEK:
			nCommand = AVIOCTRL_RECORD_PLAY_SEEKTIME;
			break;
		case NETPRO_RECSTREAM_STOP:
			nCommand = AVIOCTRL_RECORD_PLAY_STOP;
			break;
		default:
			return NetProErr_CtrlRecStream;
	}

	if(eCtrlType2 != -1) nCommand = eCtrlType2;

	memset(&playRec, 0, sizeof(playRec));
	playRec.command = nCommand;
	playRec.Param	= lData;
	memcpy(playRec.fileName,m_strRecFile, strlen(m_strRecFile));

	//nRet = m_pLoginChn->SendCtrl(0, IOTYPE_USER_IPCAM_RECORD_PLAYCONTROL, (const char *)pData, nDataLen);
	nRet =  m_pLoginChn->SetParam(0, NETPRO_EVENT_CONN_SUCCESS, (char *)&playRec, sizeof(playRec) ,IOTYPE_USER_IPCAM_RECORD_PLAYCONTROL);
	if(nRet != NetProErr_Success ) return nRet;

	return 0;
}


int CTutkMainCtrl::CreateRecChnAction()
{
	int nCount		 = 0;
	int nRet	     = -1;
	int nCreateChannelParam;

	while( nCount < 6 && m_pLoginChn->m_nCreateRecPlayChnParam < 0 )
	{
		nCount ++;
		JSleep(500);
	}

	if( m_pLoginChn->m_nCreateRecPlayChnParam < 0)
	{
		m_pLoginChn->m_eventCB(m_pLoginChn->m_nCurIndex, m_pLoginChn->m_nDevChn, NETPRO_EVENT_CREATE_REC_PLAYCHN, NetProErr_CreateRecPlyChn, NULL, m_pLoginChn->m_lUserParam);
	}

	nCreateChannelParam = m_pLoginChn->m_nCreateRecPlayChnParam;
	m_pLoginChn->m_nCreateRecPlayChnParam = -1;

	for(int i = 0; i < MAX_TUTK_CHANNEL; i++)
	{
		if(m_protocolChn[i] == NULL)
		{
			m_protocolChn[i] = new CProtocolChannel(m_pLoginChn->m_nCurIndex, i, 
				m_pLoginChn->m_strID,
				m_pLoginChn->m_strUser, 
				m_pLoginChn->m_strPwd, 
				m_pLoginChn->m_nProjectType,
				m_pLoginChn->m_eventCB, 
				m_pLoginChn->m_lUserParam, 
				m_pLoginChn->m_nSessionID, 
				m_pLoginChn->m_nConnID,
				m_pLoginChn->m_nTimeOut);

			if(m_protocolChn[i]) 
			{
				nRet = m_protocolChn[i]->CreateStreamChn(nCreateChannelParam);
				if( nRet != NetProErr_Success )
				{
					SAFE_DELETE(m_protocolChn[i]);
					m_pLoginChn->m_eventCB(m_pLoginChn->m_nCurIndex, m_pLoginChn->m_nDevChn, NETPRO_EVENT_CREATE_REC_PLAYCHN, NetProErr_CreateRecPlyChn, NULL, m_pLoginChn->m_lUserParam);
					return 0;
				}
				memcpy(m_strRecFileName[i], m_strRecFile, strlen(m_strRecFile));
				m_pLoginChn->m_eventCB(m_pLoginChn->m_nCurIndex, m_pLoginChn->m_nDevChn, NETPRO_EVENT_CREATE_REC_PLAYCHN, i, NULL, m_pLoginChn->m_lUserParam);
				return 0;
			}
			
		}
	}

	m_pLoginChn->m_eventCB(m_pLoginChn->m_nCurIndex, m_pLoginChn->m_nDevChn, NETPRO_EVENT_CREATE_REC_PLAYCHN, NetProErr_NoFreeChannel, NULL, m_pLoginChn->m_lUserParam);

	return 0;
}

fJThRet CTutkMainCtrl::RunCreateRecChnActionThread(void* pParam)
{
	CJLThreadCtrl*		pThreadCtrl			= NULL;	
	CTutkMainCtrl*	pChannel			= NULL;	
	int					iIsRun				= 1;
	pThreadCtrl	= (CJLThreadCtrl*)pParam;
	if ( pThreadCtrl==NULL )
	{
		return 0;
	}
	pChannel	= (CTutkMainCtrl *)pThreadCtrl->GetOwner();
	if ( pChannel == NULL )
	{
		pThreadCtrl->SetThreadState(THREAD_STATE_STOP);	
		return 0;
	}

// 	while(iIsRun)
// 	{
// 		if ( pThreadCtrl->GetNextAction() == THREAD_STATE_STOP )
// 		{
// 			iIsRun = 0;
// 			break;
// 		}
		pChannel->m_mutexLock.Lock();
		pChannel->CreateRecChnAction();
		pChannel->m_mutexLock.Unlock();
		pChannel->m_nCreateRecChannelFlag = 0;
//	}

	pThreadCtrl->NotifyStop();

	JTRACE("RunCreateRecChnActionThread exit.......\r\n");
	return 0;
}


long CTutkMainCtrl::CreateDevChnNum(int nNum)
{
	int				nRet		= -1;
	int				nCount		= 1;
	if(m_pLoginChn->m_nChannel < 0)				return NetProErr_NoConn;

	if(m_pLoginChn->m_nNVRNum < 1) return NetProErr_UnKnowCHNNun;

	if(nNum > m_pLoginChn->m_nNVRNum)	return NetProErr_Param;

	
	for(int i = 1; i < nNum; i++)
	{
		m_protocolChn[i] = new CProtocolChannel(m_pLoginChn->m_nCurIndex, i, 
			m_pLoginChn->m_strID,
			m_pLoginChn->m_strUser, 
			m_pLoginChn->m_strPwd, 
			m_pLoginChn->m_nProjectType,
			m_pLoginChn->m_eventCB, 
			m_pLoginChn->m_lUserParam, 
			m_pLoginChn->m_nSessionID, 
			m_pLoginChn->m_nConnID,
			m_pLoginChn->m_nTimeOut);

		if(m_protocolChn[i]) 
		{
			nRet = m_protocolChn[i]->CreateStreamChn(m_pLoginChn->m_nNVRChannel[i]);
			if( nRet != NetProErr_Success )
			{
				SAFE_DELETE(m_protocolChn[i]);
			}
			else
			{
				++ nCount;
			}
		}
	}
	return nCount;
}

long CTutkMainCtrl::CheckDev()
{
	return m_pLoginChn->CheckDev();
}

long CTutkMainCtrl::SetCheckConnTimeinterval(int nMillisecond)
{
	return m_pLoginChn->SetCheckConnTimeinterval(nMillisecond);
}

long CTutkMainCtrl::OpenStream(int nChannel, char* pPassword, eNetStreamType eType, long lTimeSeconds, long lTimeZone, StreamCallBack streamCB, long lUserParam)
{
	if(nChannel > MAX_TUTK_CHANNEL || nChannel < 0 ) return NetProErr_Param;
	
	if(!m_protocolChn[nChannel])	
		return m_protocolChn[0]->OpenStream(nChannel, pPassword, eType, lTimeSeconds, lTimeZone, streamCB, lUserParam);
//NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->OpenStream(nChannel, pPassword, eType, lTimeSeconds, lTimeZone, streamCB, lUserParam);

}

long CTutkMainCtrl::CloseStream(int nChannel, eNetStreamType eType)
{

	if(nChannel > MAX_TUTK_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])	
		return m_protocolChn[0]->CloseStream(nChannel, eType);//NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->CloseStream(nChannel, eType);

	return NetProErr_Success;
}


long CTutkMainCtrl::PasueRecvStream( int nChannel, int nPasueFlag)
{
	
	if(nChannel > MAX_TUTK_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])	return NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->PasueRecvStream(nChannel, nPasueFlag);

	return NetProErr_Success;
}
long CTutkMainCtrl::SetParam(int nChannel, eNetProParam eParam, void* lData, int nDataSize)
{
	if(nChannel > MAX_TUTK_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])	return NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->SetParam(nChannel, eParam, lData, nDataSize);

	return NetProErr_Success;
}

long CTutkMainCtrl::GetParam(int nChannel, eNetProParam eParam, void* lData, int nDataSize)
{
	if(nChannel > MAX_TUTK_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])	return NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->GetParam(nChannel, eParam, lData, nDataSize);

	return NetProErr_Success;
}

long CTutkMainCtrl::RecDownload(int nChannel, const char* pFileName, char *pSrcFileName)
{
	if(nChannel > MAX_TUTK_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])	
		return m_protocolChn[0]->RecDownload(nChannel, pFileName, pSrcFileName);//NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->RecDownload(nChannel, pFileName, pSrcFileName);

	return NetProErr_Success;
}

long CTutkMainCtrl::TalkSendFile(int nChannel, const char *pFileName, int nIsPlay)
{
	if(nChannel > MAX_TUTK_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])
		return m_protocolChn[0]->TalkSendFile(nChannel, pFileName, nIsPlay);//NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->TalkSendFile(nChannel, pFileName, nIsPlay);

	return NetProErr_Success;
}

long CTutkMainCtrl::SetStream(int nChannel, eNetVideoStreamType eLevel)
{
	if(nChannel > MAX_TUTK_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])
		return m_protocolChn[0]->SetStream(nChannel, eLevel);//NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->SetStream(nChannel, eLevel);

	return NetProErr_Success;
}

long CTutkMainCtrl::StopDownload(int nChannel)
{
	if(nChannel > MAX_TUTK_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])	return NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->StopDownload(nChannel);

	return NetProErr_Success;
}

long CTutkMainCtrl::DelRec(int nChannel, const char *pFileName)
{
	if(nChannel > MAX_TUTK_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])	return NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->DelRec(nChannel, pFileName);

	return NetProErr_Success;
}

long CTutkMainCtrl::TalkStart(int nChannel)
{
	if(nChannel > MAX_TUTK_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])	
		return m_protocolChn[0]->TalkStart(nChannel);//NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->TalkStart(nChannel);

	return NetProErr_Success;
}

long CTutkMainCtrl::TalkSend(int nChannel, const char* pData, DWORD dwSize)
{
	if(nChannel > MAX_TUTK_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])	
		return m_protocolChn[0]->TalkSend(nChannel, pData, dwSize);//NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->TalkSend(nChannel, pData, dwSize);

	return NetProErr_Success;
}

long CTutkMainCtrl::TalkStop(int nChannel)
{
	if(nChannel > MAX_TUTK_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])
		return m_protocolChn[0]->TalkStop(nChannel);//NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->TalkStop(nChannel);

	return NetProErr_Success;
}
