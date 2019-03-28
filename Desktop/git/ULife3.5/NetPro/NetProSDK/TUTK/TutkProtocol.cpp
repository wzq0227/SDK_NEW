#include "TutkProtocol.h"


CTutkProtocol::CTutkProtocol() : CNetProCommon()
{
	for(int i = 0; i < MAX_CONN_CHANNEL; i++)
	{
		m_pMainCtrl[i]	= NULL;
	}

	m_mutexGetChannel.CreateMutex();
}


CTutkProtocol::~CTutkProtocol()
{
	m_mutexGetChannel.CloseMutex();
}


long CTutkProtocol::Init()
{
	int nRet = -1;
	nRet = IOTC_Initialize2(0);
	if(nRet < 0) return NetProErr_Init;
	nRet = avInitialize(MAX_CONN_CHANNEL);
	if(nRet < 0) return NetProErr_Init;
	IOTC_Setup_LANConnection_Timeout(500);
	IOTC_Setup_P2PConnection_Timeout(500);
	
	return NetProErr_Success;
}

long CTutkProtocol::UnInit()
{
	avDeInitialize();
	IOTC_DeInitialize();
	return NetProErr_Success;
}
int	 CTutkProtocol::GetFreeChannel()
{
	m_mutexGetChannel.Lock();
	for( int i = 0; i < MAX_CONN_CHANNEL; i++ )
	{
		if( NULL == m_pMainCtrl[i] )
		{
			m_pMainCtrl[i] = new CTutkMainCtrl(i);
			if(m_pMainCtrl[i])
			{
				m_mutexGetChannel.Unlock();
				return i;
			}
			else
			{
				m_mutexGetChannel.Unlock();
				return -1;
			}
		}
	}
	m_mutexGetChannel.Unlock();
	return -1;
}

long CTutkProtocol::ConnDev(const char* pUID, const char* pUser, const char* pPwd, int nTimeOut, int nConnType, EventCallBack eventCB, long lUserParam)
{
	int			lHandle = -1;
	int			nRet	= -1;

	lHandle = GetFreeChannel();

	if( lHandle < 0 ) return NetProErr_GetChannel;

	nRet = m_pMainCtrl[lHandle]->ConnDev(pUID, pUser, pPwd, nTimeOut, nConnType, eventCB, lUserParam);

	if(nRet != NetProErr_Success ) 
	{
		SAFE_DELETE(m_pMainCtrl[lHandle]);
		return -1;//nRet;
	}

	return lHandle;
}

long CTutkProtocol::CloseDev(long lConnHandle)
{
	m_mutexGetChannel.Lock();
	SAFE_DELETE(m_pMainCtrl[lConnHandle]);
	m_mutexGetChannel.Unlock();
	return 0;
}

long	CTutkProtocol::GetDevChnNum(long lConnHandle)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if( !m_pMainCtrl[lConnHandle]) return NetProErr_GetChannel;
	return m_pMainCtrl[lConnHandle]->GetDevChnNum();

}

long	CTutkProtocol::CreateDevChn(long lConnHandle, int nNum)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if( !m_pMainCtrl[lConnHandle]) return NetProErr_GetChannel;

	return m_pMainCtrl[lConnHandle]->CreateDevChnNum(nNum);

}

long CTutkProtocol::SetCheckConnTimeinterval(long lConnHandle, int nMillisecond)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if( !m_pMainCtrl[lConnHandle]) return NetProErr_GetChannel;

	return m_pMainCtrl[lConnHandle]->SetCheckConnTimeinterval(nMillisecond);

	return 0;
}

long	CTutkProtocol::CheckDevConn(long lConnHandle)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if( !m_pMainCtrl[lConnHandle]) return NetProErr_GetChannel;

	return m_pMainCtrl[lConnHandle]->CheckDev();

	return 0;
}

long	CTutkProtocol::ConnServer(char* pServerAddr, int nPort, int nUseTcp, EventCallBack eventCB, long lUserParam)
{
	return 0;
}

long	CTutkProtocol::SetTransportProType(eNetProTransportProType eProType, char* pServerAddr)
{
	return 0;
}

long	CTutkProtocol::CloseServer()
{
	return 0;
}

long CTutkProtocol::OpenStream(long lHandle, int nChannel, char* pPassword, eNetStreamType eType, long lTimeSeconds, long lTimeZone, StreamCallBack streamCB, long lUserParam)
{
	if( lHandle < 0 ) return NetProErr_GetChannel;

	if( !m_pMainCtrl[lHandle]) return NetProErr_GetChannel;

	return m_pMainCtrl[lHandle]->OpenStream(nChannel, pPassword, eType, lTimeSeconds, lTimeZone, streamCB, lUserParam);

}

long CTutkProtocol::CloseStream(long lHandle, int nChannel, eNetStreamType eType)
{
	if( lHandle < 0 ) return NetProErr_GetChannel;

	if( !m_pMainCtrl[lHandle]) return NetProErr_GetChannel;

	return m_pMainCtrl[lHandle]->CloseStream( nChannel, eType );
}

long	CTutkProtocol::PasueRecvStream( long lConnHandle,int nChannel, int nPasueFlag)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;
	
	if( !m_pMainCtrl[lConnHandle]) return NetProErr_GetChannel;

	return m_pMainCtrl[lConnHandle]->PasueRecvStream( nChannel, nPasueFlag);
}

long	CTutkProtocol::SetParam(long lConnHandle, int nChannel, eNetProParam eParam, void* lData, int nDataSize)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if( !m_pMainCtrl[lConnHandle]) return NetProErr_GetChannel;

	return m_pMainCtrl[lConnHandle]->SetParam(nChannel, eParam, lData, nDataSize);
}

long	CTutkProtocol::GetParam(long lConnHandle, int nChannel, eNetProParam eParam, void* lData, int nDataSize)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if( !m_pMainCtrl[lConnHandle]) return NetProErr_GetChannel;

	return m_pMainCtrl[lConnHandle]->GetParam( nChannel, eParam, lData, nDataSize);
}

long	CTutkProtocol::RecDownload(long lConnHandle, int nChannel, const char* pFileName, char *pSrcFileName)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if( !m_pMainCtrl[lConnHandle]) return NetProErr_GetChannel;

	return m_pMainCtrl[lConnHandle]->RecDownload( nChannel, pFileName, pSrcFileName);
}

long	CTutkProtocol::TalkSendFile(long lConnHandle, int nChannel, const char *pFileName, int nIsPlay)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if( !m_pMainCtrl[lConnHandle]) return NetProErr_GetChannel;

	return m_pMainCtrl[lConnHandle]->TalkSendFile( nChannel, pFileName, nIsPlay);
}

long	CTutkProtocol::SetStream(long lConnHandle, int nChannel, eNetVideoStreamType eLevel)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if( !m_pMainCtrl[lConnHandle]) return NetProErr_GetChannel;

	return m_pMainCtrl[lConnHandle]->SetStream( nChannel, eLevel);
}
long	CTutkProtocol::StopDownload(long lConnHandle, int nChannel)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if( !m_pMainCtrl[lConnHandle]) return NetProErr_GetChannel;

	return m_pMainCtrl[lConnHandle]->StopDownload( nChannel);
}
long	CTutkProtocol::DelRec(long lConnHandle, int nChannel, const char *pFileName)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if( !m_pMainCtrl[lConnHandle]) return NetProErr_GetChannel;

	return m_pMainCtrl[lConnHandle]->DelRec( nChannel, pFileName);
}

long	CTutkProtocol::TalkStart(long lConnHandle, int nChannel)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if( !m_pMainCtrl[lConnHandle]) return NetProErr_GetChannel;

	return m_pMainCtrl[lConnHandle]->TalkStart( nChannel);
}	

long	CTutkProtocol::TalkSend(long lConnHandle, int nChannel, const char* pData, DWORD dwSize)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if( !m_pMainCtrl[lConnHandle]) return NetProErr_GetChannel;

	return m_pMainCtrl[lConnHandle]->TalkSend( nChannel, pData, dwSize);
}

long	CTutkProtocol::TalkStop(long lConnHandle, int nChannel)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if( !m_pMainCtrl[lConnHandle]) return NetProErr_GetChannel;

	return m_pMainCtrl[lConnHandle]->TalkStop( nChannel);
}

long	CTutkProtocol::CreateRecPlayChn(long lConnHandle, const char *pData, int nDataLen)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if( !m_pMainCtrl[lConnHandle]) return NetProErr_GetChannel;

	return m_pMainCtrl[lConnHandle]->CreateRecPlayChn( (void *)pData, nDataLen);
}

long CTutkProtocol::DeleteRecPlayChn(long lConnHandle, int nChn)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if( !m_pMainCtrl[lConnHandle]) return NetProErr_GetChannel;

	return m_pMainCtrl[lConnHandle]->DeleteRecPlayChn( nChn);
}

long CTutkProtocol::RecStreamCtrl(long lConnHandle, int nChn, eNetRecCtrlType eCtrlType, long lData)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if( !m_pMainCtrl[lConnHandle]) return NetProErr_GetChannel;

	return m_pMainCtrl[lConnHandle]->RecStreamCtrl( nChn, eCtrlType, lData);
}