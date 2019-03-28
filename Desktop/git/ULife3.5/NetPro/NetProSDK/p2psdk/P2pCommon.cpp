#include "P2pCommon.h"


CP2pCommon::CP2pCommon()
{
	
}

CP2pCommon::~CP2pCommon()
{

}


int CP2pCommon::avSendIOCtrl(p2p_transport *transport,int connection_id, unsigned int nIOCtrlType, const char *cabIOCtrlData, int nIOCtrlDataSize, int nFlag, void* pHandle)
{
	int			nRet		= -1;
	int			nError		= -1;
	P2pHead		head		= {0};

	//if(!transport || connection_id < 0) return NetProErr_NoConnChn;

	char* pData = new char[sizeof(P2pHead) + nIOCtrlDataSize+1];
	memset(pData, '\0', sizeof(P2pHead) + nIOCtrlDataSize+1);
	head.magicNo = 0x67736d80;
	head.dataLen = nIOCtrlDataSize;
	head.proType = 2;
	head.msgType = 1;
	head.msgChildType = nIOCtrlType;

	memcpy(pData, (char *)&head, sizeof(P2pHead));
	memcpy(pData+sizeof(P2pHead), cabIOCtrlData, nIOCtrlDataSize);
	
	if(nFlag)
	{	
		if(pHandle)
		{
			nRet = gss_client_av_send(pHandle,  pData, sizeof(P2pHead) + nIOCtrlDataSize, P2P_SEND_BLOCK);
		}
		
	}
	else
	{
		nRet = p2p_transport_send(transport, connection_id, pData, sizeof(P2pHead) + nIOCtrlDataSize, P2P_SEND_BLOCK, &nError);
		if(nRet > 0) return 0;
	}

	return nRet;

}