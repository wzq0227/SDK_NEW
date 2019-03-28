// GVAPPlayer.h
#if !defined(_GVAPPLAYER_H_)
#define _GVAPPLAYER_H_

#ifdef __cplusplus
extern "C" {
#endif

// #include "QueueBuf.h"
#include "ThreadUtil.h"
#include "UlifeDefines.h"

#define STREAM_TYPE_VIDEO	0X0001
#define STREAM_TYPE_AUDIO 0X0002

	typedef struct
	{
		int type;		// 1:video; 100:audio
		int nIFrame;
		int height;
		int length;
		int framerate;	// 25
		int dwTimeStamp;
	}FrameHead;

	enum
	{
		CON_SERVER_ERROR=0,
		CON_SUCCESS,
		CON_PWD_ERROR,
		CON_CAM_OFFLINE,
		CON_CAM_MISS
	};

	typedef struct _sgvapstream 
	{
		char	m_ipaddr[20];
		int m_port;
		THREAD_HANDLE m_thdatarecv;
		THREAD_HANDLE m_thdatarecvpush;
		THREAD_HANDLE m_thdatarecvpushKeepAlive;
		char			m_username[64];
		char			m_password[64];
		char			m_strdev[128];
// 		CQueueBuf		*m_bufVidQueue;
// 		CQueueBuf		*m_bufAudQueue;

		int	m_bToLogin;

// 		AVFrameData	*m_pBufVideoPlay;
// 		AVFrameData	*m_pBufAudioPlay;

		int		m_bDiscardFrame;
		int		m_dwRecvErrTime;

		int    m_bEndWork ;

		int  m_nSockTrans ;
		int  m_nSockTransPush ;

		char   *m_pszProtoBuf ;
		int	m_recvedlen;
		int	m_needrecvlen;

		int bReCnntFlag;
		int m_bSendStreamType;
		int  m_nVideoFrameRate;
		int m_keepalivetime;
		long m_timecount;
		long m_timecountPush;
		int m_keepalivetimePush;
		int m_isstart;
		int m_isvideoopen;
		int m_isaudioopen;
		int m_channelid;
		void* popt;

		char m_sendbuf[2048];
		int m_sendedlen;
		int m_needsendlen;
		int m_videoHd;

		AvDataCallback m_datacallback;
		MsgCallback m_msgcallback;
	}SAVStream;

	SAVStream* AV_Create();
	void AV_Destroy(SAVStream* pstream);
	int AV_Start(SAVStream* pstream);
	int AV_CreateVideo(SAVStream* pstream);
	int AV_OpenVideo(SAVStream* pstream);
	int AV_CloseVideo(SAVStream* pstream);
	int AV_OpenAudio(SAVStream* pstream);
	int AV_CloseAudio(SAVStream* pstream);
	int AV_IsStart(SAVStream* pstream);
	int AV_IsVideoOpen(SAVStream* pstream);
	int AV_IsAudioOpen(SAVStream* pstream);
	int AV_SwitchHdBd(SAVStream* pstream,int hd);
// 	unsigned char* AV_GetOneFrame(SAVStream* pstream,int type,int *framelen);

#ifdef __cplusplus
}
#endif

#endif //_GVAPPLAYER_H_
