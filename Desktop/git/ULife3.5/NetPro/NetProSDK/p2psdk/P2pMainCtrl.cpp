#include "P2pMainCtrl.h"


CP2PMainCtrl::CP2PMainCtrl(int nIndex)
{
	for(int i = 0; i < MAX_P2PDEV_CHANNEL; i++)
	{
		m_protocolChn[i]	= NULL;
	}

	m_pLoginChn = new CP2pChannel(nIndex, 0);

	m_protocolChn[0] = m_pLoginChn;
}


CP2PMainCtrl::~CP2PMainCtrl()
{
	CloseDev();
	SAFE_DELETE(m_pLoginChn);
}

long CP2PMainCtrl::ConnDev(const char* pUID, const char* pUser, const char* pPwd, int nTimeOut, int nConnType, EventCallBack eventCB, long lUserParam,  char *pServerAddr)
{
	return m_pLoginChn->ConnDev(pUID, pUser, pPwd, nTimeOut, nConnType, eventCB, lUserParam, pServerAddr);
}

long CP2PMainCtrl::CloseDev()
{
	for(int i = 1 ; i< MAX_P2PDEV_CHANNEL; i++)
	{
		SAFE_DELETE(m_protocolChn[i]);
	}
	return m_pLoginChn->CloseDev();
}

long CP2PMainCtrl::GetDevChnNum()
{
	return m_pLoginChn->GetDevChnNum();
}

long CP2PMainCtrl::CreateRecPlayChn(void* pData, int nDataLen)
{
	
	return 0;
}
long CP2PMainCtrl::DeleteRecPlayChn(int nChn)
{
	RecStreamCtrl(nChn, NETPRO_RECSTREAM_PAUSE, 0, AVIOCTRL_RECORD_PLAY_STOP);
	SAFE_DELETE(m_protocolChn[nChn]);
	return 0;
}

long CP2PMainCtrl::RecStreamCtrl(int nChn, eNetRecCtrlType eCtrlType, long lData, int eCtrlType2)
{

	return 0;
}




long CP2PMainCtrl::CreateDevChnNum(int nNum)
{
	
	return 0;
}

long CP2PMainCtrl::CheckDev()
{
	return m_pLoginChn->CheckDev();
}

long CP2PMainCtrl::SetCheckConnTimeinterval(int nMillisecond)
{
	return m_pLoginChn->SetCheckConnTimeinterval(nMillisecond);
}

long CP2PMainCtrl::OpenStream(int nChannel, char* pPassword, eNetStreamType eType, long lTimeSeconds, long lTimeZone, StreamCallBack streamCB, long lUserParam)
{
	if(nChannel > MAX_P2PDEV_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])	return NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->OpenStream(nChannel, pPassword, eType, lTimeSeconds, lTimeZone, streamCB, lUserParam);

}

long CP2PMainCtrl::CloseStream(int nChannel, eNetStreamType eType)
{

	if(nChannel > MAX_P2PDEV_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])	return NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->CloseStream(nChannel, eType);

	return NetProErr_Success;
}

long CP2PMainCtrl::PasueRecvStream(int nChannel, int nPasueFlag)
{
	if(nChannel > MAX_P2PDEV_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])	return NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->PasueRecvStream(nChannel, nPasueFlag);
}

long CP2PMainCtrl::SetParam(int nChannel, eNetProParam eParam, void* lData, int nDataSize)
{
	if(nChannel > MAX_P2PDEV_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])	return NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->SetParam(nChannel, eParam, lData, nDataSize);

	return NetProErr_Success;
}

long CP2PMainCtrl::GetParam(int nChannel, eNetProParam eParam, void* lData, int nDataSize)
{
	if(nChannel > MAX_P2PDEV_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])	return NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->GetParam(nChannel, eParam, lData, nDataSize);

	return NetProErr_Success;
}

long CP2PMainCtrl::RecDownload(int nChannel, const char* pFileName, char *pSrcFileName)
{
	if(nChannel > MAX_P2PDEV_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])	return NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->RecDownload(nChannel, pFileName, pSrcFileName);

	return NetProErr_Success;
}

long CP2PMainCtrl::TalkSendFile(int nChannel, const char *pFileName, int nIsPlay)
{
	if(nChannel > MAX_P2PDEV_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])	return NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->TalkSendFile(nChannel, pFileName, nIsPlay);

	return NetProErr_Success;
}

long CP2PMainCtrl::SetStream(int nChannel, eNetVideoStreamType eLevel)
{
	if(nChannel > MAX_P2PDEV_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])	return NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->SetStream(nChannel, eLevel);

	return NetProErr_Success;
}

long CP2PMainCtrl::StopDownload(int nChannel)
{
	if(nChannel > MAX_P2PDEV_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])	return NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->StopDownload(nChannel);

	return NetProErr_Success;
}

long CP2PMainCtrl::DelRec(int nChannel, const char *pFileName)
{
	if(nChannel > MAX_P2PDEV_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])	return NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->DelRec(nChannel, pFileName);

	return NetProErr_Success;
}

long CP2PMainCtrl::TalkStart(int nChannel)
{
	if(nChannel > MAX_P2PDEV_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])	return NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->TalkStart(nChannel);

	return NetProErr_Success;
}

long CP2PMainCtrl::TalkSend(int nChannel, const char* pData, DWORD dwSize)
{
	if(nChannel > MAX_P2PDEV_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])	return NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->TalkSend(nChannel, pData, dwSize);

	return NetProErr_Success;
}

long CP2PMainCtrl::TalkStop(int nChannel)
{
	if(nChannel > MAX_P2PDEV_CHANNEL || nChannel < 0 ) return NetProErr_Param;

	if(!m_protocolChn[nChannel])	return NetProErr_UseErrChn;

	return m_protocolChn[nChannel]->TalkStop(nChannel);

	return NetProErr_Success;
}
