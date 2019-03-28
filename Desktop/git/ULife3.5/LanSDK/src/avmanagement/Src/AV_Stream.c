// GVAPPlayer.cpp
#include "AV_Stream.h"
#include "Tlib_Cmddefine.h"
#include "Tlib_ProtocolAX.h"
#include "QuickSocket.h"
// #include "QueueBuf.h"
#include "ThreadUtil.h"
#include "DebugPrint.h"

#include <stdio.h>
#include <string.h>
#include <time.h>

#ifndef WIN32
#include <unistd.h>
#endif

#define QUERY_SERVER_PORT     5551
#define TRANS_SERVER_PORT     5552
#define PTZ_SCALE_REQ 14
#define  MAXFRM_SIZE  100*1000	//100K

typedef struct
{
	unsigned int nIFrame;
	unsigned int nAVType;		//1 means video,2 means audio
	unsigned int dwSize;		//audio or video data size
	unsigned int dwFrameRate;	//video frame rate or audio samplingRate
	unsigned int dwTimeStamp;
	unsigned int gs_video_cap;	//video's capability
	unsigned int gs_reserved; 
}StDataInfo;


//////////////////////////////////////////////////////////////////////////
static void SendScaleCmd(SAVStream* pstream,int nX, int nY);
static THREADRETURN ThreadDataRecv(void* lpParam);
static THREADRETURN ThreadDataRecvPush(void* lpParam);
static THREADRETURN ThreadDataPushKeepAlive(void* lpParam);

static void AddVideoFrame(SAVStream* pstream,unsigned char *pszBuf,stFrameHeader *pFrameHeader);
static void AddAudioFrame(SAVStream* pstream,unsigned char *pszBuf,stFrameHeader *pFrameHeader);

static void  StopConnect(SAVStream* pstream);

static int KeepAlive(SAVStream* pstream,int bPush);
static int KeepAliveStream(SAVStream* pstream, int bPush,int *bKeep);
static int KeepAlivePush(SAVStream* pstream, int bPush,int *bKeep);
static int RecvDataAndProcess(SAVStream* pstream,int dwDataType);
static int RecvDataAndProcessPush(SAVStream* pstream,int dwDataType);
static int sendCmd(SAVStream* pstream,TlibFieldAx *plibfield,int dwCmdDest,int bPush);
static void  sendDataREQ(SAVStream* pstream,int dwType,int bStart) ;
static int SendDataEx(SAVStream* pstream);

static int  ConnectToServer(SAVStream* pstream);
static int DisConnect(SAVStream* pstream,int bStop);
static int DoVerifyDevice(SAVStream* pstream ,int bPush);
static int EnablePush(SAVStream* pstream);
static int DoPlayDevice(SAVStream* pstream);//,const char* username,const char* password, const char* szdev) ;
static void DoDomeCtrl(SAVStream* pstream,int nCmdID) ;
static int  DoDealWithACK(SAVStream* pstream,const char* lpAckString, int bPush) ;
static void USSleep(int timeoutms);

//////////////////////////////////////////////////////////////////////////

SAVStream* AV_Create()
{
	SAVStream* pstream = (SAVStream*)malloc(sizeof(SAVStream));
	if (pstream != NULL)
	{
		memset(pstream,0,sizeof(SAVStream));
		pstream->m_bToLogin  = 0;
		pstream->m_nSockTrans   = -1 ;
		pstream->m_nSockTransPush   = -1 ;
		pstream->m_bEndWork     = 0 ;
		pstream->m_channelid = -1;
		pstream->m_recvedlen = 0;
		pstream->m_needrecvlen = 14;
		memset(pstream->m_sendbuf,0,sizeof(pstream->m_sendbuf));
		pstream->m_sendedlen = 0;
		pstream->m_needsendlen = 0;
		pstream->m_videoHd = 0;

		pstream->m_pszProtoBuf = (char*)malloc(MAXFRM_SIZE);

// 		pstream->m_pBufVideoPlay = NULL;
// 		pstream->m_pBufVideoPlay = (AVFrameData*)malloc(sizeof(AVFrameData));
// 		pstream->m_pBufVideoPlay->pszBuf = (char*)malloc(MAXFRM_SIZE);

// 		pstream->m_pBufAudioPlay = (AVFrameData*)malloc(sizeof(AVFrameData));
// 		pstream->m_pBufAudioPlay->pszBuf = (char*)malloc(0x10000);

		pstream->bReCnntFlag = 0;
		pstream->m_bDiscardFrame = 0;
		pstream->m_keepalivetime = 25;
		pstream->m_timecount = 0;
		pstream->m_keepalivetimePush = 5;
		pstream->m_timecountPush = 0;

		pstream->m_bSendStreamType = 1;
		pstream->m_nVideoFrameRate = 0;
		pstream->m_thdatarecv = THREAD_HANDLENULL;
		pstream->m_thdatarecvpush = THREAD_HANDLENULL;
		pstream->m_thdatarecvpushKeepAlive = THREAD_HANDLENULL;
		memset(pstream->m_ipaddr,0,sizeof(pstream->m_ipaddr));
		memset(pstream->m_password,0,sizeof(pstream->m_password));
		memset(pstream->m_strdev,0,sizeof(pstream->m_strdev));
		memset(pstream->m_username,0,sizeof(pstream->m_username));
// 		pstream->m_bufVidQueue = QueueBuf_Create();
// 		pstream->m_bufAudQueue = QueueBuf_Create();
		pstream->m_isstart = 0;
		pstream->m_isaudioopen = 0;
		pstream->m_isvideoopen = 0;
		pstream->m_datacallback = NULL;
		pstream->m_msgcallback = NULL;
		return pstream;
	}
	return NULL;
}

void AV_Destroy(SAVStream* pstream)
{
	if(pstream == NULL)
		return;
	//close connection
	StopConnect(pstream);

	//wait for thread exit
	while (pstream->m_thdatarecv)
	{
		printf("wait for data thread exit!\n");
		USSleep(100);
	}

	while (pstream->m_thdatarecvpush)
	{
		printf("wait for push thread exit!\n");
		USSleep(100);
	}

	while (pstream->m_thdatarecvpushKeepAlive)
	{
		USSleep(100);	
	}

	//free buffers
	if(pstream->m_pszProtoBuf != NULL)
	{
		free(pstream->m_pszProtoBuf);
		pstream->m_pszProtoBuf = NULL;
	}
// 	if(pstream->m_pBufVideoPlay->pszBuf != NULL)
// 	{
// 		free(pstream->m_pBufVideoPlay->pszBuf);
// 		pstream->m_pBufVideoPlay->pszBuf = NULL;
// 	}
// 	if(pstream->m_pBufVideoPlay != NULL)
// 	{
// 		free(pstream->m_pBufVideoPlay);
// 		pstream->m_pBufVideoPlay = NULL;
// 	}
// 	if(pstream->m_pBufAudioPlay->pszBuf != NULL)
// 	{
// 		free(pstream->m_pBufAudioPlay->pszBuf);
// 		pstream->m_pBufAudioPlay->pszBuf = NULL;
// 	}
// 	if(pstream->m_pBufAudioPlay != NULL)
// 	{
// 		free(pstream->m_pBufAudioPlay);
// 		pstream->m_pBufAudioPlay = NULL;
// 	}
// 	QueueBuf_Destroy(pstream->m_bufVidQueue);
// 	pstream->m_bufVidQueue = NULL;
// 	QueueBuf_Destroy(pstream->m_bufAudQueue);
// 	pstream->m_bufAudQueue = NULL;
}



int AV_Start( SAVStream* pstream)
{
	if (pstream == NULL)
	{
		return -1;
	}

	if (AV_IsStart(pstream))
	{
		return 0;
	}

	if(CON_SUCCESS == ConnectToServer(pstream))
	{
		pstream->m_isstart = 1;
		return 0;
	}
	else
		return -1;
}

int AV_CreateVideo(SAVStream* pstream)
{
	if(pstream == NULL)
		return 0;
	return DoPlayDevice(pstream);
	return 1;
}

int AV_OpenVideo(SAVStream* pstream)
{
	//DoPlayDevice(pstream);
	if(pstream->m_bToLogin)
		sendDataREQ(pstream,1,1);
	pstream->m_isvideoopen = 1;
	return 1;
}

int AV_CloseVideo(SAVStream* pstream)
{
	//StopConnect(pstream);
	pstream->m_isvideoopen = 0;
	sendDataREQ(pstream,1,0);
	return 1;
}

int AV_OpenAudio(SAVStream* pstream)
{
	if(pstream->m_bToLogin)
		sendDataREQ(pstream,2,1);
	pstream->m_isaudioopen = 1;
	return 1;
}

int AV_CloseAudio(SAVStream* pstream)
{
	pstream->m_isaudioopen = 0;
	sendDataREQ(pstream,2,0);
	return 1;
}

int AV_IsStart(SAVStream* pstream)
{
	return pstream->m_isstart;
}

int AV_IsVideoOpen(SAVStream* pstream)
{
	return pstream->m_isvideoopen;
}

int AV_IsAudioOpen(SAVStream* pstream)
{
	return pstream->m_isaudioopen;
}

// unsigned char* AV_GetOneFrame(SAVStream* pstream,int type,int *framelen)
// {
// 	if (STREAM_TYPE_VIDEO == type)
// 	{
// 		if (QueueBuf_GetBuf(pstream->m_bufVidQueue,pstream->m_pBufVideoPlay))
// 		{
// 			*framelen = pstream->m_pBufVideoPlay->fheader.dwSize;
// 			return pstream->m_pBufVideoPlay->pszBuf;
// 		}
// 		else
// 		{
// 			*framelen = 0;
// 			return NULL;
// 		}
// 	}
// 	else if (STREAM_TYPE_AUDIO == type)
// 	{
// 		if (QueueBuf_GetBuf(pstream->m_bufAudQueue,pstream->m_pBufAudioPlay))
// 		{
// 			*framelen = pstream->m_pBufAudioPlay->fheader.dwSize;
// 			return pstream->m_pBufAudioPlay->pszBuf;
// 		}
// 		else
// 		{
// 			*framelen = 0;
// 			return NULL;
// 		}
// 	}
// 	else
// 	{
// 		*framelen = 0;
// 		return NULL;
// 	}
// }

/////////////////////////////////////////////////////////////
void StopConnect(SAVStream* pstream) 
{
	pstream->m_bEndWork = 1 ;
	pstream->bReCnntFlag = 0;

	if(pstream->m_nSockTrans != -1)
	{
		sendDataREQ(pstream,0,0);
		DisConnect(pstream,1);
// 		StopSocket(pstream->m_nSockTrans);
// 		pstream->m_nSockTrans = -1 ;
	}

// 	QueueBuf_Empty(pstream->m_bufVidQueue);
// 	QueueBuf_Empty(pstream->m_bufAudQueue);

	pstream->m_isvideoopen = 0;
}

static int KeepAliveStream(SAVStream* pstream, int bPush,int *bKeep)
{
	time_t tm;
	time(&tm);
	if (pstream->m_nSockTrans == -1)
	{
		return -1;
	}

	if(pstream->m_timecount != 0)
	{
		*bKeep = (long)tm - pstream->m_timecount  > pstream->m_keepalivetime;
		if(*bKeep)
			pstream->m_timecount = tm;
	}
	else
	{
		pstream->m_timecount = tm;
	}
	if(*bKeep)	//pstream->m_dwRecvErrTime <= 0 && pstream->m_timecount++ > pstream->m_keepalivetime*1000
	{
		pstream->m_timecount = 0;
		KeepAlive(pstream,0);
		*bKeep = 0;
	}
	return 0;
}

static int KeepAlivePush(SAVStream* pstream, int bPush,int *bKeep)
{
	time_t tm;
	time(&tm);
	if (pstream->m_nSockTransPush == -1)
	{
		return -1;
	}

	if(pstream->m_timecountPush != 0)
	{
		*bKeep = (long)tm - pstream->m_timecountPush  > pstream->m_keepalivetimePush;
		if(*bKeep)
			pstream->m_timecountPush = tm;
	}
	else
	{
		pstream->m_timecountPush = tm;
	}
	if(*bKeep)	//pstream->m_dwRecvErrTime <= 0 && pstream->m_timecount++ > pstream->m_keepalivetime*1000
	{
		pstream->m_timecountPush = 0;
		KeepAlive(pstream,1);
		*bKeep = 0;
	}
	return 0;
}

int KeepAlive(SAVStream* pstream, int bPush)
{
	TlibFieldAx *plibfield = Tlib_CreateFiled();
	if(plibfield == NULL)
		return 0;

	Tlib_SetCommand(plibfield,COMMAND_C_S_TRANSMIT_NULL) ;
	sendCmd(pstream,plibfield,1,bPush);
	Tlib_DestroyFiled(plibfield);

	return 0;
}
/////////////////
THREADRETURN ThreadDataPushKeepAlive(void* lpParam)
{
	SAVStream *pstream = (SAVStream *)lpParam ;
	int keepAlive = 1;

	if (pstream == NULL)
		return THREADRETURNVALUE ;

	while(1)
	{
		if(pstream->m_bEndWork)
			break;
	
		//心跳
		if((keepAlive%pstream->m_keepalivetimePush) == 0)
		{
			KeepAlive(pstream,1);
		}
		else
		{
			USSleep(1000);
		}
		keepAlive++;
	}

	StopSocket(pstream->m_nSockTransPush);

	pstream->m_thdatarecvpushKeepAlive = THREAD_HANDLENULL;

	return THREADRETURNVALUE;
}

THREADRETURN ThreadDataRecvPush(void* lpParam)
{
	SAVStream *pstream = (SAVStream *)lpParam ;
	int checkrlt = 0;
	int waitCounts = 0;
	int keepAlive = 0;

	if (pstream == NULL)
		return THREADRETURNVALUE ;

	while(1)
	{
		if(pstream->m_bEndWork)
			break;
		if (pstream->m_nSockTransPush == -1)
		{
			pstream->m_nSockTransPush = QuickConnectToTCP(pstream->m_port,pstream->m_ipaddr,10000);

			if (pstream->m_nSockTransPush == -1)
			{
				USSleep(1000);
				continue;
			}
			else
			{
				if(DoVerifyDevice(pstream,1) <= 0)
				{
					StopSocket(pstream->m_nSockTransPush);
					pstream->m_nSockTransPush = -1;
					continue;
				}
			
				if(EnablePush(pstream) <= 0)
				{
					StopSocket(pstream->m_nSockTransPush);
					pstream->m_nSockTransPush = -1;
					continue;
				}
			}

		}

		checkrlt = QuickCheckIsReadytoWriteorRead(pstream->m_nSockTransPush,1000,1);
		if (checkrlt == -1 )	//checkrlt == -1,error ; checkrlt == 0,timeout
		{
			StopSocket(pstream->m_nSockTransPush);
			pstream->m_nSockTransPush = -1;
		}
		else if (checkrlt == 1 || checkrlt == 3)	//checkrlt == 1,ready to read; checkrlt == 3,//ready to read and write
		{
		if(RecvDataAndProcessPush(pstream,1) == 0)
		{
			StopSocket(pstream->m_nSockTransPush);
			pstream->m_nSockTransPush = -1;
 			USSleep(1000);
			continue;
			}
		}
		KeepAlivePush(pstream,1,&keepAlive);
	}

	StopSocket(pstream->m_nSockTransPush);
	pstream->m_nSockTransPush = -1;

	pstream->m_thdatarecvpush = THREAD_HANDLENULL;

	return THREADRETURNVALUE;
}

THREADRETURN ThreadDataRecv(void* lpParam)
{
	SAVStream *pstream = (SAVStream *)lpParam ;
	int checkrlt = -1;
	int bkeepAlive = 0;
	int bKeepAlivePush = 0;
	time_t tm;
	int waitCounts = 0;

	pstream->m_bDiscardFrame = 1;

	if (pstream == NULL)
		return THREADRETURNVALUE ;


	pstream->m_dwRecvErrTime = 0;

	while(1)
	{
		int onlyRead = 0;
		if(pstream->m_bEndWork)
			break;
		if(pstream->m_sendedlen <= pstream->m_needsendlen)
			onlyRead = 1;
		//出现错误，重连
		if(pstream->m_dwRecvErrTime > 0 || pstream->m_nSockTrans == -1)
		{
			if (ConnectToServer(pstream) == CON_SUCCESS)
			{
				pstream->m_dwRecvErrTime = 0;
				pstream->bReCnntFlag = 0;

				DoVerifyDevice(pstream,0);

				//EnablePush(pstream);
			}
			else	
			{
				pstream->bReCnntFlag = 1;
				USSleep(5000);
			}
		}

// 		KeepAlivePush(pstream,1,&bKeepAlivePush);

		checkrlt = QuickCheckIsReadytoWriteorRead(pstream->m_nSockTrans,5000,onlyRead);
	
		if (checkrlt == -1 || checkrlt == 0)	//checkrlt == -1,error ; checkrlt == 0,timeout
		{
			waitCounts++;
  			if(
 				(checkrlt == -1) || 
				(pstream->m_bToLogin && (pstream->m_isvideoopen || pstream->m_isvideoopen)) ||
				waitCounts > 5
				)
			{
				DisConnect(pstream,0);
				waitCounts = 0;
				continue;
			}

			printf("QuickCheckIsReadytoWriteorRead checlrlt = %d\n",checkrlt);
		}
		else if (checkrlt == 1 || checkrlt == 3)	//checkrlt == 1,ready to read; checkrlt == 3,//ready to read and write
		{
			waitCounts = 0;
			if(RecvDataAndProcess(pstream,1) == 0)
			{
				if (ConnectToServer(pstream) == CON_SUCCESS)
				{
					pstream->m_dwRecvErrTime = 0;
					pstream->bReCnntFlag = 0;

					DoVerifyDevice(pstream,0);

					//EnablePush(pstream);
				}
				else	
				{
					pstream->bReCnntFlag = 1;
				}
				USSleep(1000);
			}
			else
			{
				//printf("recv data successful\n");
			}
		}
		else if (checkrlt == 2 || checkrlt == 3)	//checkrlt == 2 ,ready to write; checkrlt == 3,//ready to read and write
		{
			printf("111111111111 QuickCheckIsReadytoWriteorRead checlrlt = %d\n",checkrlt);
			waitCounts = 0;
			SendDataEx(pstream);
		}
		else
		{
			printf("22222222222222 QuickCheckIsReadytoWriteorRead checlrlt = %d\n",checkrlt);
			waitCounts = 0;
			//no this case;
		}

		//心跳
		KeepAliveStream(pstream,0,&bkeepAlive);
// 		time(&tm);
// 		if(pstream->m_timecount != 0)
// 		{
// 			bkeepAlive = (long)tm - pstream->m_timecount  > pstream->m_keepalivetime;
// 			bKeepAlivePush = (long)tm - pstream->m_timecount  > pstream->m_keepalivetime;
// 			if(bkeepAlive)
// 				pstream->m_timecount = tm;
// 		}
// 		else
// 		{
// 			pstream->m_timecount = tm;
// 		}
// 		if(bkeepAlive)	//pstream->m_dwRecvErrTime <= 0 && pstream->m_timecount++ > pstream->m_keepalivetime*1000
// 		{
// 			pstream->m_timecount = 0;
// 			KeepAlive(pstream,0);
// 			bkeepAlive = 0;
// 		}
	}

	pstream->m_thdatarecv = THREAD_HANDLENULL;

	DisConnect(pstream,1);

	return THREADRETURNVALUE;
}


void AddVideoFrame(SAVStream* pstream,unsigned char *pszBuf,stFrameHeader *pFrameHeader)
{
	//注意，ulifedefineds.h中的SFrameHeader结构体与stFrameHeader必须相同
	if(pstream->m_datacallback)
	{
		//pr_debug("current nIframe = %d,avtype = %d,dwsize = %d,framerate = %d,timestamp = %d,video cap = %d,reserved = %d\n",
// 			pFrameHeader->nIFrame,pFrameHeader->nAVType,pFrameHeader->dwSize,pFrameHeader->dwFrameRate,pFrameHeader->dwTimeStamp,pFrameHeader->gs_video_cap,pFrameHeader->gs_reserved);
		pstream->m_datacallback(pstream->m_channelid,pFrameHeader,pszBuf,pFrameHeader->dwSize,pstream->popt);
	}
	return;
	//
// 	AVFrameData *pFrame = NULL;
// 	if ((pstream == NULL) || pFrameHeader->dwSize==0)
// 		return ;
// 	
// 	pFrame = (AVFrameData *)calloc(1,sizeof(AVFrameData));
// 	pFrame->pszBuf  = (unsigned char*)calloc(1,pFrameHeader->dwSize);
// 	memcpy(&pFrame->fheader,pFrameHeader,sizeof(stFrameHeader));
// 	memcpy(pFrame->pszBuf,pszBuf,pFrameHeader->dwSize);
// 	
// 	pstream->m_nVideoFrameRate =  pFrameHeader->dwFrameRate;
// 
// 	if(!pstream->m_bDiscardFrame)
// 	{
// 		if(!QueueBuf_AddBuf(pstream->m_bufVidQueue,pFrame))
// 		{
// 			free(pFrame->pszBuf);
// 			free(pFrame);
// 			pstream->m_bDiscardFrame = 1;
// 		}
// 	}
// 	else	// AddBuf is not OK
// 	{
// 		if(pFrame->fheader.nIFrame&0xff)
// 		{
// 			if(QueueBuf_AddBuf(pstream->m_bufVidQueue,pFrame))
// 			{
// 				pstream->m_bDiscardFrame = 0;
// 				return;
// 			}
// 		}
// 		free(pFrame->pszBuf);
// 		free(pFrame);
// 	}
}

void AddAudioFrame(SAVStream* pstream,unsigned char *pszBuf,stFrameHeader *pFrameHeader)
{
	//注意，ulifedefineds.h中的SFrameHeader结构体与stFrameHeader必须相同
	if(pstream->m_datacallback)
		pstream->m_datacallback(pstream->m_channelid,pFrameHeader,pszBuf,pFrameHeader->dwSize,pstream->popt);
	return;

// 	AVFrameData *pFrame = NULL;
// 	if (pFrameHeader->dwSize==0) return ;
// 	
// 	pFrame = (AVFrameData *)calloc(1,sizeof(AVFrameData)) ;
// 	pFrame->pszBuf  = (unsigned char*)calloc(1,pFrameHeader->dwSize);
// 	memcpy(&pFrame->fheader,pFrameHeader,sizeof(stFrameHeader));
// 	memcpy(pFrame->pszBuf,pszBuf,pFrameHeader->dwSize);
// 	
// 	if(!QueueBuf_AddBuf(pstream->m_bufAudQueue,pFrame))
// 	{
// 		free(pFrame->pszBuf);
// 		free(pFrame);
// 	}
}

int sendCmd(SAVStream* pstream,TlibFieldAx *plibfield,int dwCmdDest,int bPush)
{
	int sWorkSock;
	int nsendlen = 0;

	if(bPush)
		sWorkSock = pstream->m_nSockTransPush;
	else
		sWorkSock = pstream->m_nSockTrans;


	if(sWorkSock == -1 ||  plibfield == NULL || ((pstream->m_needsendlen > sizeof(pstream->m_sendbuf) && (!bPush))) )
		return 0;

	Tlib_DoBuildString(plibfield) ;

	if(bPush)
	{
		return ForceSend(sWorkSock,plibfield->szpCmdBuf,plibfield->dwBufLen,10000,0,NULL);
	}

	if (pstream->m_needsendlen + plibfield->dwBufLen > sizeof(pstream->m_sendbuf))
	{
		return 0;
	}

	memcpy(pstream->m_sendbuf+pstream->m_sendedlen,plibfield->szpCmdBuf,plibfield->dwBufLen);
	pstream->m_needsendlen += plibfield->dwBufLen;

	nsendlen = QuickWrite(sWorkSock,pstream->m_sendbuf+pstream->m_sendedlen,pstream->m_needsendlen-pstream->m_sendedlen) ;

	if (nsendlen == pstream->m_needsendlen-pstream->m_sendedlen)
	{
		pstream->m_needsendlen = 0;
		pstream->m_sendedlen = 0;
	}
	else 	if (nsendlen > 0)
	{
		pstream->m_sendedlen += nsendlen;
	}

	return nsendlen;
}

int RecvDataAndProcessPush(SAVStream* pstream,int dwDataType)
{
	int sWorkSock = pstream->m_nSockTransPush;
	int rlt = 0;
	char pRecv[2048] = {0};
	int  nDataLen = 0 ;

	rlt = recv(sWorkSock,pRecv,14,0);

	if (rlt == 14)
	{
		int scanrlt = sscanf(pRecv+8,"%06X",&nDataLen);
		if(nDataLen>2048 || nDataLen<0 || scanrlt < 1 || nDataLen == 0)
		{
			pr_debug("need to recv len is too long or other param error,ndata len = %d!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n",nDataLen);
			return 0;
		}
		rlt = recv(sWorkSock,pRecv+14,nDataLen,0);
		if(rlt == -1)
			return 0;
		if(rlt == nDataLen)
			rlt = DoDealWithACK(pstream,pRecv,1) ;
		else
			rlt = 0;
	}
	else if (rlt == 0)
	{
		return 1;
	}
	else
	{
#ifdef WIN32
		int l = WSAGetLastError();
#endif
		rlt = 0;
	}
	return rlt;
}

int RecvDataAndProcess(SAVStream* pstream,int dwDataType)
{
	int sWorkSock = pstream->m_nSockTrans;
	int rlt = 0;

	do 
	{
			if(sWorkSock == -1)
				break;

			if(pstream->m_needrecvlen == 14 && pstream->m_recvedlen == 0)
			{
				//读取14个字节的头，从头中获取后面需要获取多少字节长度的数据
				int recvlen = QuickRead(sWorkSock,pstream->m_pszProtoBuf+pstream->m_recvedlen,pstream->m_needrecvlen - pstream->m_recvedlen);
				//printf("recv header: pstream->m_recvedlen = %d,current recvlen = %d\n",pstream->m_recvedlen,recvlen);
				if (recvlen == -1)
					break;
				else
					pstream->m_recvedlen += recvlen;
				
				//如果一次获取头成功
				if (pstream->m_recvedlen == 14)
				{
					//获取后续需要读取的数据长度nDataLen
					int  nDataLen = 0 ;
					int scanrlt = sscanf(pstream->m_pszProtoBuf+8,"%06X",&nDataLen);
					if(nDataLen>=0x4ffff || nDataLen<0 || scanrlt < 1 || nDataLen == 0)
						break;
					
					//计算一次完整数据，总共需要接收的数据长度 pstream->m_needrecvlen
					pstream->m_needrecvlen += nDataLen;
					//printf("recv header success : nDatalen = %d,recvedlen = %d,total need recv len = %d\n",nDataLen,pstream->m_recvedlen,pstream->m_needrecvlen);
					nDataLen = QuickRead(sWorkSock,pstream->m_pszProtoBuf+pstream->m_recvedlen,pstream->m_needrecvlen - pstream->m_recvedlen);
					//printf("current recv len = %d\n",nDataLen);
					//如果一次获取成功剩余长度nDataLen的数据
					if( nDataLen ==  pstream->m_needrecvlen - pstream->m_recvedlen)
					{
						pstream->m_pszProtoBuf[pstream->m_needrecvlen] = 0 ;
						//printf("0 complete recv data ,len = %d,nDataLen = %d\n",pstream->m_needrecvlen,nDataLen);
						DoDealWithACK(pstream,pstream->m_pszProtoBuf,0) ;
						rlt = 2;
						break;
					}
					else if (nDataLen == -1)
					{
						break;
					}
					else	//一次没有读取完剩余长度的数据，计算已读数据
					{
						pstream->m_recvedlen += nDataLen;
					}
				}
				else
				{
					//头没有读取完成，此时需要读取的长度pstream->m_needrecvlen = 14,等待下次读取头完成
				}
			}
			else if(pstream->m_needrecvlen > 14)	//表示读取头完成,已经通过计算得到了单次完整数据的长度
			{
				int nrecvlen = QuickRead(sWorkSock,pstream->m_pszProtoBuf+pstream->m_recvedlen,pstream->m_needrecvlen - pstream->m_recvedlen);
				
				//printf("current recv len = %d\n",nrecvlen);
				if (nrecvlen == -1)
					break;
				else
					pstream->m_recvedlen += nrecvlen;
				
				if( pstream->m_needrecvlen ==  pstream->m_recvedlen)	//单次所有数据已经读取完成
				{
					pstream->m_pszProtoBuf[pstream->m_needrecvlen] = 0 ;
					//printf("1 complete recv data ,len = %d,nDataLen = %d\n",pstream->m_needrecvlen,nrecvlen);
					DoDealWithACK(pstream,pstream->m_pszProtoBuf,0) ;
					rlt = 2;
					break;
				}
			}
			else //pstream->m_needrecvlen < 14属于异常情况
			{
				rlt = 0;
				break;
			}

			rlt = 1;
	} while (0);

	if (rlt == 0 || rlt == 2)
	{
		pstream->m_needrecvlen = 14;
		pstream->m_recvedlen = 0;
	}

	if (rlt == 0)
	{
		pstream->m_dwRecvErrTime++;
	}

	return rlt;
}

// FILE* g_testfile = NULL;

int DoDealWithACK(SAVStream* pstream,const char* lpAckString, int bPush)
{
	TlibFieldAx *plibfield = NULL;
	Field *pLg=NULL;
	int bOk = 0;

	if(pstream->m_bEndWork)
		return 0;

	plibfield = Tlib_CreateFiled();
	if(plibfield == NULL)
		return 0;

	//printf("%s\n",(char *)lpAckString);
	Tlib_DoDecodeString(plibfield,(char *)lpAckString);


	pLg= Tlib_GetFieldInfoByName(plibfield,"Ret") ;
	if ( pLg != NULL)
	{
#ifdef WIN32
		bOk = stricmp((char*)pLg->pszFieldContent,"1") == 0;
#else
		bOk = strcasecmp((char*)pLg->pszFieldContent,"1") == 0;
#endif
		if ( !bOk )
		{
			pLg = Tlib_GetFieldInfoByName(plibfield,"ErrorInfo") ;
// 			if (pLg != NULL)
// 				TRACE("@@@@@ ErrorInfo:%s\n",pLg->pszFieldContent) ;
			pLg = NULL ;
			pLg = Tlib_GetFieldInfoByName(plibfield,"Command_Param");
			if((pLg != NULL) && strcmp(pLg->pszFieldContent,"5054") == 0)	//开启关闭推送
			{
				EnablePush(pstream);
			}
		}
	}

	if (!bOk)
	{
		Tlib_DestroyFiled(plibfield);
		return 0;
	}

	switch(plibfield->dwCommand)
	{
	case COMMAND_S_C_TRANSMIT_ACK:
		{
			pLg = Tlib_GetFieldInfoByName(plibfield,"Command_Param");
			if((pLg != NULL) && pLg->pszFieldContent && (pLg->dwFieldContentLen > 0))
			{
				char pMsg[2048] = {0};
				if(strcmp(pLg->pszFieldContent,"3203") == 0)	//获取温度
				{
					pLg = Tlib_GetFieldInfoByName(plibfield,"TaRHValue");
					if((pLg != NULL) && pLg->pszFieldContent && (pLg->dwFieldContentLen > 0))
					{
						long int  localTime = 0;
						char pContent[256] = {0};
						strcpy(pContent,pLg->pszFieldContent);
						memset(pMsg,0,sizeof(pMsg));
						sprintf(pMsg,"{\"Temperature\":\"%s\"}",pLg->pszFieldContent);
						pstream->m_msgcallback(pstream->m_channelid,AVM_MSG_NORMAL,AVM_SUMMSG_TEMP,(unsigned char*)pMsg,strlen(pMsg),pstream->popt);
//						sscanf((char*)pLg->pszFieldContent, "%ld@%lf@%lf", &localTime, &m_nTempture, &m_nHumidity);
//						::PostMessage(m_hReport,WM_TEMSTATUS,0,0);
					}
				}
				else if (strcmp(pLg->pszFieldContent,"5054") == 0) //开启/关闭推送
				{
					
				}
				else if (strcmp(pLg->pszFieldContent,"5027") == 0) //PIR报警
				{
					pstream->m_msgcallback(pstream->m_channelid,AVM_MSG_NORMAL,AVM_SUMMSG_PIR,NULL,0,pstream->popt);
				}
				else if (strcmp(pLg->pszFieldContent,"5052") == 0) //报警推送
				{
					static SPushInfo s_pushInfo = {0};
					pLg = Tlib_GetFieldInfoByName(plibfield,"Type");				
					if((pLg != NULL) && pLg->pszFieldContent && (pLg->dwFieldContentLen > 0))
					{
						memset(pMsg,0,sizeof(pMsg));
						s_pushInfo.type = atoi(pLg->pszFieldContent);
						pr_debug("recv push alarm, type = %d\n",s_pushInfo.type);
						if (s_pushInfo.type == 2)
						{
							//Temperature,属性值:一个温度值
							//TemperatureAlarmType :0->低温报警  1->高温报警
							// ValueType: 0->摄氏温度  1->华氏温度
							pLg = Tlib_GetFieldInfoByName(plibfield,"Temperature");
							if((pLg != NULL) && pLg->pszFieldContent && (pLg->dwFieldContentLen > 0))
							{
 								memset(s_pushInfo.temperature,0,sizeof(s_pushInfo.temperature));
 								strcpy(s_pushInfo.temperature,pLg->pszFieldContent);
							}

							pLg = Tlib_GetFieldInfoByName(plibfield,"TemperatureAlarmType");
							if((pLg != NULL) && pLg->pszFieldContent && (pLg->dwFieldContentLen > 0))
							{
								s_pushInfo.temperatureAlarmType = atoi(pLg->pszFieldContent);
							}
							pLg = Tlib_GetFieldInfoByName(plibfield,"ValueType");
							if((pLg != NULL) && pLg->pszFieldContent && (pLg->dwFieldContentLen > 0))
							{
								s_pushInfo.tempType = atoi(pLg->pszFieldContent);
							}

							sprintf(pMsg,"{\"Type\":%d,\"Temperature\":\"%s\",\"TemperatureAlarmType\":%d,\"ValueType\":%d}",
								s_pushInfo.type,s_pushInfo.temperature,s_pushInfo.temperatureAlarmType,s_pushInfo.tempType);
						}
						else
						{
							sprintf(pMsg,"{\"Type\":%d,\"Temperature\":\"0\"}",s_pushInfo.type);
						}
						pstream->m_msgcallback(pstream->m_channelid,AVM_MSG_NORMAL,AVM_SUMMSG_PUSH,(unsigned char*)pMsg,strlen(pMsg),pstream->popt);	
					}
				}
			}
		}
		break;

	case COMMAND_S_C_TRANSMIT_LOGIN_ACK:
		{
			if(!bPush && ((pstream->bReCnntFlag == 1) || (pstream->m_bToLogin == 0)))
			{//sendDataREQ(pstream,1,1);
				pstream->m_bToLogin = 1;
				if(pstream->m_isvideoopen)
					AV_OpenVideo(pstream);
				if(pstream->m_isaudioopen)
					AV_OpenAudio(pstream);
			}
		}
		break;

	case COMMAND_S_C_TRANSMIT_DATA_ACK:
		{
			if (bPush)
			{
				printf("\n\n\n**********************************\n\n\n");
			}
			pLg = Tlib_GetFieldInfoByName(plibfield,"Data");
			if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
			{
				int   nReadLen  = 0 ;
				int   nFrameSize = 0 ;
				int   nHeadSize = sizeof(StDataInfo) ;
				int   nTotalLen = pLg->dwFieldContentLen-nHeadSize ;
				unsigned char *pData     = (unsigned char *)pLg->pszFieldContent;

				while(nReadLen<nTotalLen)
				{
					StDataInfo *pInfo = (StDataInfo *)pData;
					pInfo->nAVType = ntohl(pInfo->nAVType);
					pInfo->nIFrame = ntohl(pInfo->nIFrame);
					pInfo->dwSize  = ntohl(pInfo->dwSize);
					nFrameSize     = pInfo->dwSize;
					pInfo->dwFrameRate = ntohl(pInfo->dwFrameRate);
					pInfo->gs_video_cap = ntohl(pInfo->gs_video_cap);
					pInfo->gs_reserved = ntohl(pInfo->gs_reserved);
					pInfo->dwTimeStamp = ntohl(pInfo->dwTimeStamp);
					if (pInfo->dwFrameRate == 0)
						pInfo->dwFrameRate = 5;

					if((nFrameSize<0 || nFrameSize>nTotalLen)||
						(pInfo->nAVType!=1&&pInfo->nAVType!=2)||
						((pInfo->nIFrame&0xff)!=1&&(pInfo->nIFrame&0xff)!=0))
					{
						pstream->m_dwRecvErrTime++;
						break;
					}

					if (pInfo->nAVType == 1)
					{
						stFrameHeader pHeader = {0};
						if (pInfo->dwFrameRate == 0)
							pInfo->dwFrameRate = 5;
						pHeader.nIFrame = pInfo->nIFrame;
						pHeader.dwFrameRate = pInfo->dwFrameRate;
						pHeader.dwSize = pInfo->dwSize;
						pHeader.dwTimeStamp = pInfo->dwTimeStamp;
						pHeader.gs_reserved = pInfo->gs_reserved;
						pHeader.gs_video_cap = pInfo->gs_video_cap;
						pHeader.nAVType = pInfo->nAVType;
// 						printf("AddVideoFrame nIframe = %d,avtype = %d,dwsize = %d,framerate = %d,timestamp = %d,video cap = %d,reserved = %d\n",
// 							pHeader.nIFrame,pHeader.nAVType,pHeader.dwSize,pHeader.dwFrameRate,pHeader.dwTimeStamp,pHeader.gs_video_cap,pHeader.gs_reserved);

						AddVideoFrame(pstream,pData+nHeadSize,&pHeader);
					}
					else if (pInfo->nAVType == 2)
					{
						stFrameHeader pHeader = {0};
						if(pInfo->dwFrameRate < 8000)// 8K sampleRate
							pInfo->dwFrameRate=8000;

						pHeader.nIFrame = pInfo->nIFrame;
						pHeader.dwFrameRate = pInfo->dwFrameRate;
						pHeader.dwSize = pInfo->dwSize;
						pHeader.dwTimeStamp = pInfo->dwTimeStamp;
						pHeader.gs_reserved = pInfo->gs_reserved;
						pHeader.gs_video_cap = pInfo->gs_video_cap;
						pHeader.nAVType = pInfo->nAVType;

						AddAudioFrame(pstream,pData+nHeadSize,&pHeader);
					}

					pData    += (nFrameSize+nHeadSize) ;
					nReadLen += (nFrameSize+nHeadSize) ;
				}
// 				if (g_testfile == NULL)
// 				{
// #ifdef WIN32
// 					g_testfile = fopen("c:\\test.h264","wb+");
// #else
// 					g_testfile = fopen("/sdcard/test.h264","wb+");
// #endif
// 				}
// 				if (g_testfile)
// 				{
// 					fwrite(pLg->pszFieldContent,pLg->dwFieldContentLen,1,g_testfile);
// 				}
			}
		}
		break;
	}

	Tlib_DestroyFiled(plibfield);
	return 1;
}

int ConnectToServer(SAVStream* pstream) 
{
	int dwConError = CON_SERVER_ERROR ;

	if(pstream->m_bEndWork == 1)
		return CON_SUCCESS;
//	pstream->m_bEndWork = 0 ;

// 	if(pstream->m_nSockTrans != -1)
// 	{
		DisConnect(pstream,0);
// 		StopSocket(pstream->m_nSockTrans) ;
// 		pstream->m_nSockTrans = -1 ;
//	}
	
	pstream->m_nSockTrans = QuickConnectToTCPNonBlock(pstream->m_port,pstream->m_ipaddr,10000);

	if(pstream->m_nSockTrans != -1)
	{
		dwConError = CON_SUCCESS;
	}

	return dwConError;
}

static int DisConnect(SAVStream* pstream,int bStop)
{
	if (pstream)
	{
		StopSocket(pstream->m_nSockTrans) ;
		pstream->m_nSockTrans = -1 ;
		pstream->m_needsendlen = 0;
		pstream->m_sendedlen = 0;
		pstream->m_bToLogin = 0;
		pstream->m_recvedlen = 0;
		pstream->m_needrecvlen = 14;
		if (!bStop)
		{
			pstream->bReCnntFlag = 1;
		}
		return 0;
	}
	else
	{
		return -1;
	}
}

int DoPlayDevice(SAVStream* pstream)//,const char* username,const char* password, const char* szdev)
{	
	int bRet = 0;
// 	strcpy(pstream->m_username,username);
// 	strcpy(pstream->m_password,password);
// 	strcpy(pstream->m_strdev,szdev);

	if (pstream->m_nSockTrans == -1)
	{
		if(ConnectToServer(pstream) == CON_SUCCESS)
		{
			bRet = 1;
			pstream->bReCnntFlag = 0;
		}else
		{
			pstream->bReCnntFlag = 1;
		}
	}
	else
	{
		bRet = 1;
	}

	DoVerifyDevice(pstream,0);

	if(pstream->m_thdatarecv == THREAD_HANDLENULL)
		pstream->m_thdatarecv = thread_create_normal(ThreadDataRecv,pstream);

//       if(pstream->m_thdatarecvpush == THREAD_HANDLENULL)
//           pstream->m_thdatarecvpush = thread_create_normal(ThreadDataRecvPush,pstream);
   
 	//if(pstream->m_thdatarecvpushKeepAlive == THREAD_HANDLENULL)
 	//	pstream->m_thdatarecvpushKeepAlive = thread_create_normal(ThreadDataPushKeepAlive,pstream);
// 	EnablePush(pstream);

// 	if(!RecvDataAndProcess(pstream,1))
// 	{
// 		/*		m_bEndWork = 1 ;*/
// 
// 		WS_close(pstream->m_nSockTrans);
// 		pstream->m_nSockTrans = -1 ;
// 	}
// 	else
// 	{
// 		pstream->m_bToLogin = 1;
// 		bRet = 1;
// 	}


// 	sendDataREQ(pstream,1,1);

// 	if(bRet == 1)
		//pstream->m_isvideoopen = 1;

	return bRet;
}

void sendDataREQ(SAVStream* pstream,int dwType,int bStart)
{
	TlibFieldAx *plibfield = NULL;
	char *pType = "All";
	char *pCmmd = "Start";

	if (pstream == NULL)
	{
		return;
	}

	if(dwType == 1)
		pType = "Video";

	if(dwType == 2)
		pType = "Audio";

	if(!bStart)
		pCmmd = "Stop";

	plibfield = Tlib_CreateFiled();

	if(plibfield == NULL)
		return;
	
	Tlib_SetCommand(plibfield,COMMAND_C_S_TRANSMIT_DATA_REQ) ;
	Tlib_AddNewFiledVoid(plibfield,"Command",pCmmd,0,0);
	Tlib_AddNewFiledVoid(plibfield,"Type",pType,0,0);
	
	if(0) //G711条件判断
	{
		//G711
		Tlib_AddNewFiledVoid(plibfield,"StreamID","2",0,0);
	}
	else
	{
		if(dwType == 1)
		{
			if(pstream->m_videoHd == 1)
			{
				Tlib_AddNewFiledVoid(plibfield,"StreamID","0",0,0);
				pstream->m_bSendStreamType = 0;
			}
			else
			{
				Tlib_AddNewFiledVoid(plibfield,"StreamID","1",0,0);
				pstream->m_bSendStreamType = 0;
			}
		}
		else
		{
			Tlib_AddNewFiledVoid(plibfield,"StreamID","0",0,0);
			pstream->m_bSendStreamType = 0;
		}

		// 					Req.AddNewFiled("StreamID","1");
		// 					m_bSendStreamType = 1;
	}


	sendCmd(pstream,plibfield,1,0) ;

	Tlib_DestroyFiled(plibfield);
}

void DoDomeCtrl(SAVStream* pstream,int nCmdID)
{
	TlibFieldAx *plibfield = Tlib_CreateFiled();
	if(plibfield == NULL)
		return;

	Tlib_SetCommand(plibfield,COMMAND_C_S_TRANSMIT_REQ) ;

	if (nCmdID == 103)
	{
		if (!pstream->m_bSendStreamType)
		{
			if (pstream->m_nVideoFrameRate<=8)
			{
				Tlib_AddNewFiledVoid(plibfield,"AVQVal","Mid",0,0);

			}else if (pstream->m_nVideoFrameRate <=15)
			{
				Tlib_AddNewFiledVoid(plibfield,"AVQVal","Max",0,0);
			}else
			{
				Tlib_AddNewFiledVoid(plibfield,"AVQVal","Min",0,0);
			}

		}else
		{
			if (pstream->m_nVideoFrameRate<=3)
			{
				Tlib_AddNewFiledVoid(plibfield,"AVQVal","Mid",0,0);

			}else if (pstream->m_nVideoFrameRate <=5)
			{
				Tlib_AddNewFiledVoid(plibfield,"AVQVal","Max",0,0);

			}else
			{
				Tlib_AddNewFiledVoid(plibfield,"AVQVal","Min",0,0);
			}
		}
	}

	if (nCmdID>9)
	{
		Tlib_AddNewFiledInt(plibfield,"Command_Param",nCmdID,2,0);
	}
	else
	{
		Tlib_AddNewFiledInt(plibfield,"Command_Param",nCmdID,0,0);
	}

	sendCmd(pstream,plibfield,1,0) ;

	Tlib_DestroyFiled(plibfield);
}

void SendScaleCmd(SAVStream* pstream,int nX, int nY)
{
	TlibFieldAx *plibfield = Tlib_CreateFiled();
	if(plibfield == NULL)
		return;
	Tlib_SetCommand(plibfield,COMMAND_C_S_TRANSMIT_REQ) ;
	Tlib_AddNewFiledInt(plibfield,"Command_Param",PTZ_SCALE_REQ,0,0);
	Tlib_AddNewFiledInt(plibfield,"X_Axis",nX,0,0);
	Tlib_AddNewFiledInt(plibfield,"Y_Axis",nY,0,0);		
	sendCmd(pstream,plibfield,1,0);
	Tlib_DestroyFiled(plibfield);
}

int EnablePush(SAVStream* pstream)
{
	TlibFieldAx* plibfield = NULL;
	int nSendlen = 0;

	plibfield = Tlib_CreateFiled();
	if(plibfield == NULL)
		return 0;

	Tlib_SetCommand(plibfield,COMMAND_C_S_TRANSMIT_REQ);
	Tlib_AddNewFiledVoid(plibfield,"Command_Param","5053",0,0); //开启，关闭推送命令
	Tlib_AddNewFiledVoid(plibfield,"Enable","1",0,0);		
	Tlib_AddNewFiledVoid(plibfield,"Wait","1",0,0);
	nSendlen = sendCmd(pstream,plibfield,1,1);

	Tlib_DestroyFiled(plibfield);
	plibfield = NULL;

	return nSendlen;
}

int DoVerifyDevice(SAVStream* pstream ,int bPush )
{
	TlibFieldAx* plibfield = NULL;
	int nSendlen = 0;
	plibfield = Tlib_CreateFiled();
	if(plibfield == NULL)
		return 0;

	Tlib_SetCommand(plibfield,COMMAND_C_S_TRANSMIT_LOGIN_REQ);
	Tlib_AddNewFiledVoid(plibfield,"UserName",pstream->m_username,0,0);
	Tlib_AddNewFiledVoid(plibfield,"Password",pstream->m_password,0,0);		
	Tlib_AddNewFiledVoid(plibfield,"DeviceSerial",pstream->m_strdev,0,0);
	nSendlen = sendCmd(pstream,plibfield,1,bPush);

	Tlib_DestroyFiled(plibfield);
	plibfield = NULL;

	return nSendlen;
}

int SendDataEx( SAVStream* pstream )
{
	int nsendlen = 0;
	
	if(pstream->m_needsendlen <= 0)
		return 1;

	nsendlen = QuickWrite(pstream->m_nSockTrans,pstream->m_sendbuf+pstream->m_sendedlen,pstream->m_needsendlen-pstream->m_sendedlen) ;

	if (nsendlen > 0)
	{
		pstream->m_sendedlen += nsendlen;
		return 0;
	}
	else if (nsendlen == pstream->m_needsendlen-pstream->m_sendedlen)
	{
		pstream->m_needsendlen = 0;
		pstream->m_sendedlen = 0;
		return 1;
	}

	return -1;
}

int AV_SwitchHdBd( SAVStream* pstream,int hd )
{
	if(pstream)
	{
		pstream->m_videoHd = hd;
		if(AV_OpenVideo(pstream))
			return 0;
	}

	return -1;
}

void USSleep(int timeoutms)
{
#ifdef WIN32
	Sleep(timeoutms);
#else
	usleep(timeoutms*1000);
#endif
}
