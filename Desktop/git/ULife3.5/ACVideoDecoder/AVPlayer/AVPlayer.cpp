#include "AVPlayPort.h"

#if (defined _WIN32) || (defined _WIN64)
#include "sound/AudioCtl.h"
#else
#include "AVPlayer.h"
#include "AVCommon.h"

#endif


static CAVPlayPort*		g_avPlayPort[MAX_DEC_CHANNEL] = {0};	
static int				g_nInitFlag = 0;
static CAVEncoder		g_encoderPort;
#if (defined _WIN32) || (defined _WIN64)

static CAudioCtl		g_AudioCtl;

BOOL APIENTRY DllMain( HANDLE hModule, DWORD  ul_reason_for_call, LPVOID lpReserved )
{
	switch (ul_reason_for_call)
	{
	case DLL_PROCESS_ATTACH:
	case DLL_THREAD_ATTACH:
	case DLL_THREAD_DETACH:
	case DLL_PROCESS_DETACH:
		break;
	}

	return TRUE;
}

#endif



long AV_Init(int nEnableLog, const char* pLogPath)
{
	if( g_nInitFlag > 0)
		return AVErrSuccess;

#if (defined _WIN32) || (defined _WIN64)
	g_AudioCtl.Sount_Init();
#endif

	if(nEnableLog)
	{
		if(pLogPath)
		{
			JCreateDirectory(pLogPath);
			CJLogWriter::s_jlog.Init(pLogPath,"AVDecLog",".txt",JLOG_DEF_FILE_LEN);
		}
		else
		{
			JCreateDirectory("./Log/");
			CJLogWriter::s_jlog.Init(".\\Log\\","AVDecLog",".txt",JLOG_DEF_FILE_LEN);
		}
		g_nInitFlag = 1;
	}
	else
	{
		g_nInitFlag = 2;
	}
	

	

	return AVErrSuccess;
}

long AV_UnInit()
{
	if( g_nInitFlag < 1)
	{
		return AVErrUnInit;
	}

	if(g_nInitFlag == 1)
	{
		CJLogWriter::s_jlog.Close();
	}

	g_nInitFlag = 0;
	
	return AVErrSuccess;
}


long AV_GetPort()
{
	int i;
	if( g_nInitFlag < 1)
	{
		return AVErrUnInit;
	}
	DbgStrOut("AV_GetPort start\r\n");
	for( i = 0; i < MAX_DEC_CHANNEL; i++ )
	{
		if( NULL == g_avPlayPort[i] )
		{
			g_avPlayPort[i] = new CAVPlayPort(i);
			if( NULL == g_avPlayPort[i] )
			{
				return AVErrGetPort;
			}
			JTRACE("AV_GetPort().....%d..................\r\n",i);
			DbgStrOut("AV_GetPort end %d\r\n", i);
			return i;
		}
	}

	DbgStrOut("AV_GetPort err%d\r\n");
	return AVErrPort;
}

long AV_FreePort(long nPort)
{
	JTRACE("AV_FreePort().....%d..................\r\n",nPort);
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}
	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}

	SAFE_DELETE( g_avPlayPort[nPort] );

	return AVErrSuccess;
}

long AV_PutFrame(long nPort, unsigned char *buf, int nLen)
{
	
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}
	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}

	return g_avPlayPort[nPort]->PutFrame( buf, nLen );
}

long AV_SetVolume(long nPort, int nEnable, int nValue)
{
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}
	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}

	return g_avPlayPort[nPort]->SetVolume( nEnable,  nValue);
}
long AV_SetDecType(long nPort, int nDecType)
{
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}
	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}

	return g_avPlayPort[nPort]->SetDecType( nDecType );
}

long AV_SetBuffSize(long nPort, int nType,  int nBuffCount, int nBuffSize)
{
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}
	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}

	return g_avPlayPort[nPort]->SetBuffSize( nType, nBuffCount, nBuffSize );
}

long AV_Play(long nPort, long lPlayWnd, void * decodeCB, long lUserParam)
{
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}
	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}
#if (defined _WIN32) || (defined _WIN64)
	return g_avPlayPort[nPort]->Play( lPlayWnd, decodeCB, lUserParam, (long)&g_AudioCtl );
#endif
	return g_avPlayPort[nPort]->Play( lPlayWnd, decodeCB, lUserParam, NULL );

}

long AV_Stop(long nPort)
{
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}
	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}

	return g_avPlayPort[nPort]->Stop();
}


AVPLAYER_API long AV_Capture(long nPort, const char *pFileName)
{
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}
	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}
	return g_avPlayPort[nPort]->Capture(pFileName);
}

AVPLAYER_API long AV_SetFileName(long nPort, int nType, const char *pFileName, void* recCB, long lUserParam)
{
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}
	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}
	return g_avPlayPort[nPort]->SetFileName(nType, pFileName, recCB, lUserParam);
}

AVPLAYER_API long AV_EncodeAACStart(DWORD nSample, int nChannel, ENCCallBack encCB, long lUserParam)
{
	return g_encoderPort.EncodeAACStart(nSample, nChannel, encCB, lUserParam);
}
AVPLAYER_API long AV_EncodeAACPutBuf(unsigned  char *pInData, int nInLen)
{
	return g_encoderPort.EncodeAACPutBuf(pInData, nInLen);
}
AVPLAYER_API long AV_EncodeAACStop()
{
	return g_encoderPort.EncodeAACStop();
}

long AV_EncodePCM2G711A(DWORD nSample, int nChannel, unsigned  char *pInData, int nInLen, unsigned  char **pOutData, int *nOutLen)
{

	return g_encoderPort.EncodePCM2G711A( nSample, nChannel, pInData, nInLen, pOutData, nOutLen );
}

AVPLAYER_API long AV_DeleteData(char *pData)
{
	SAFE_DELETE(pData);
	return 0;
}

long AV_SetRecParam(long nPort, int nWidth, int nHeight, int nFrameRate,  int nAACChannel)
{
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}

	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}

	return g_avPlayPort[nPort]->SetRecParam( nWidth, nHeight, nFrameRate, nAACChannel );
}

long AV_StartRec(long nPort, const char *pFileName, void* recCB, long lUserParam)
{
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}

	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}

	return g_avPlayPort[nPort]->StartRec( pFileName, recCB, lUserParam );
}


long AV_StopRec(long nPort)
{
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}
	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}

	return g_avPlayPort[nPort]->StopRec();
}


DWORD AV_GetRecTime(long nPort)
{
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}
	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}

	return g_avPlayPort[nPort]->GetRecTime();
}


long AV_SetRecTime(long nPort, DWORD dwRecTime)
{
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}
	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}

	return g_avPlayPort[nPort]->SetRecTime(dwRecTime);
}

AVPLAYER_API long AV_SetH264FileRecParam(long nPort, int nIsRec, const char *pMp4FileName, int nStartTime, int nTotalTime)
{
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}
	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}

	return g_avPlayPort[nPort]->SetH264FileRecParam(nIsRec, pMp4FileName, nStartTime, nTotalTime);
}

AVPLAYER_API long AV_AddH264File(long nPort, const char *pFileName, int nFileNameLen)
{
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}
	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}

	return g_avPlayPort[nPort]->AddH264File(pFileName, nFileNameLen);
}

AVPLAYER_API long AV_StartDecH264File(long nPort, const char *pFileName,  int nIsRand, void* playRecCB, long lUserParam)
{
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}
	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}

	return g_avPlayPort[nPort]->DecH264File(pFileName, nIsRand, playRecCB, lUserParam);
}

AVPLAYER_API long AV_StopDecH264File(long nPort)
{
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}
	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}

	return g_avPlayPort[nPort]->StopDecH264File();
}

long AV_OpenRecFile(long nPort, const char *pFileName, DWORD* dwDuration, DWORD* dwFrameRate, void* playRecCB, long lUserParam)
{
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}
	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}
	return g_avPlayPort[nPort]->OpenRecFile(pFileName, dwDuration, dwFrameRate, playRecCB, lUserParam);
}


long AV_CloseRecFile(long nPort)
{
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}
	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}
	return g_avPlayPort[nPort]->CloseRecFile();
}


// nPause = 1 暂停， nPause = 0 恢复播放
long AV_RecPause(long nPort, int nPause)
{
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}
	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}
	return g_avPlayPort[nPort]->RecPause(nPause);
}

// 设置播放速度 nSpeed -4 到 + 4 之间 即慢16倍速 到 快16倍速, 0 正常播放速度
long AV_RecSetSpeed(long nPort, long nSpeed)
{
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}
	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}
	return g_avPlayPort[nPort]->RecSetSpeed(nSpeed);
}

// 获取播放速度
long AV_RecGetSpeed(long nPort)
{
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}
	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}
	return g_avPlayPort[nPort]->RecGetSpeed();
}

// 移动到指定时间播放
long AV_RecSeek(long nPort, DWORD dwTime, const char* pFileName)
{
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}
	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}
	return g_avPlayPort[nPort]->RecSeek(dwTime, pFileName);
}

#if (defined _WIN32) || (defined _WIN64)
long AV_StartPickAudio(DWORD nSamples, PickAudioCallBack fcb, long lUserParam)
{
	return g_AudioCtl.StartPickAudio(nSamples, fcb, lUserParam);
}

long AV_StopPickAudio()
{
	return g_AudioCtl.StopPickAudio();
}


long AV_EnableAudio(long nPort, int nEnable)
{
	if( nPort < 0 || nPort >= MAX_DEC_CHANNEL )
	{
		return AVErrParam;
	}
	if( NULL == g_avPlayPort[nPort] )
	{
		return AVErrPort;
	}

	return g_avPlayPort[nPort]->m_decoderPort.EnableAudio(nEnable);
}
#endif