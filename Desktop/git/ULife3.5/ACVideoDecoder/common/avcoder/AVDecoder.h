#ifndef _AVDECODER_H_
#define _AVDECODER_H_


#include "AVRecord.h"
#include "G711Decoder.h"
#include "faad.h"


#if (defined _WIN32) || (defined _WIN64)
#include "draw/DirectDraw.h"
#include "sound/AudioCtl.h"
#else
#define MAKEWORD(a, b)      ((WORD)(((BYTE)(a)) | ((WORD)((BYTE)(b))) << 8))
#define MAKELONG(a, b)      ((LONG)(((WORD)(a)) | ((DWORD)((WORD)(b))) << 16))
#define LOWORD(l)           ((WORD)(l))
#define HIWORD(l)           ((WORD)(((DWORD)(l) >> 16) & 0xFFFF))
#define LOBYTE(w)           ((BYTE)(w))
#define HIBYTE(w)           ((BYTE)(((WORD)(w) >> 8) & 0xFF))

#endif


#define MAX_AUDIO_OUT_LEN		19200

class CAVDecoder
{
public:
	CAVDecoder();
	virtual ~CAVDecoder();

	typedef long (__stdcall* ShowCallBack)(int nType, unsigned char *pBuf, int nLen, void *pUserParam);//nType 1 video ,2 audio
	static long __stdcall ShowCB(int nType, unsigned char *pBuf, int nLen, void *pUserParam);

	long	Init();
	long	UnInit();
	long	VideoDec( unsigned char *pBuf, int nLen , int nFrameNo = 0);
//    long    HardDecode_iOS(AVCodecContext* avctx,AVFrame *picture,int *got_picture_ptr,const AVPacket *avpkt);
    
	long	VideoDec2Picture( unsigned char *pBuf, int nLen);
	long	AudioDec( unsigned char *pBuf, int nLen ,int nSampleRate);
	long	G711ADec( unsigned char *pBuf, int nLen ,int nSampleRate);
	long	G711ADec( unsigned char *pBuf, int nLen ,char **pPcmBuf, int *nPcmLen);
	long	AudioDec2( unsigned char *pBuf, int nLen );
	void	SetCurPort(int nPort);
	long	AACDecDecode( void* pOutBuf,CHAR* pInputBuf,unsigned long inLen ,int nSampleRate);
	void	SetMainCtl(long lMainHandle);
	int		GetRGB32Data(unsigned char** pOutBuf);
	int		Save2JPEG(const char* pFilePath);
	void	RaiseVolume(char* buf, int size, int uRepeat, double vol);
	int		CutFrameSuccess(int nValue);


#if (defined _WIN32) || (defined _WIN64)
	int		EnableAudio(int nEnable, int nSample);
	
#endif
	

public:
	DECCallBack			m_decCB;
	ShowCallBack		m_showCB;
	long				m_lUserParam;
	int					m_nCurPort;
	int					m_nDecTypeCB ;
	int					m_nPlayMode;  // 1. 流畅优先， 2.实时优先
	AVPixelFormat		m_eAvPixFormat;
	long				m_lShowWnd;
	CAVRecord			m_avRecord;
	unsigned char*		m_pDecBuff;
	DWORD				m_dwLastPlaySound;
	int					m_nIsEnableAudio;
	FILE*				m_pWritDecFile;


	int					m_nEnable;
	int					m_nValue;
	char*				m_pPicturePath;
	

#if (defined _WIN32) || (defined _WIN64)
	// 显示begin
	CDirectDraw			m_directDraw;
	// 显示end
	CJDSound			m_sound;
	CAudioCtl*			m_pAudioCtl;
#endif

private:
	
	CG711Decoder		m_g711Dec;
	AVCodecContext*		m_pCodecContext;	
	AVFrame*			m_pAVFrame;
	//AVFrame*			m_pCapFrame;
	AVCodec*			m_pAVCodec;					// 解码器
	SwsContext*			m_pSwsContext;					
	
	unsigned char*		m_pOutAudioBuf;
	int					m_nDecBuffLen;
	int					m_nDecFlag;
	CMutexLock			m_hMutexCodec;				// 对象锁
	
	bool				m_bInitAACDec;

	DWORD				m_dwLastCallBackTime;		// 上次回调流时间
	char*				m_pPcmData;
	int					m_nPcmLen;
	// faad解码AAC begin
	NeAACDecHandle		m_hAac;
	NeAACDecConfigurationPtr m_pAacConf;
	NeAACDecFrameInfo m_aacFrameInfo;
	// faad解码AAC end
	
	
};

#endif
