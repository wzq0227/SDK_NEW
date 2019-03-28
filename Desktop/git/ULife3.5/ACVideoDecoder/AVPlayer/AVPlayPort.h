#ifndef AVPLAYPORT_H_
#define AVPLAYPORT_H_


#include "AVBufferCtrl.h"
#include "AVBuffer.h"
#include "AVCommon.h"
#include "AVPlayer.h"
#include "AVDecoder.h"
#include "AVEncoder.h"


#define		AAC_ADTS_HEADER			7
#define		MAX_REC_FILELEN			256
#define		MAX_IFRAME_POS_COUNT	255

typedef enum
{
	ePlayStream			= 0,			// 视频流
	ePlayFile,							// MP4文件
	ePlayH264File,						// H264文件
}ePlayType;

typedef enum
{
	eNMLPlayStatusStop		= 0,		// 停止
	eNMLPlayStatusRun		= 1,		// 运行
	eNMLPlayStatusIdle		= 2,		// 闲置
}eNMLPlayStatus;



// BMP文件头
#if (defined _WIN32) || (defined _WIN64)
#else
typedef struct tagBITMAPFILEHEADER
{
	WORD	bfType;
	DWORD	bfSize;
	WORD	bfReserved1;
	WORD	bfReserved2;
	DWORD	bfOffBits;
} BITMAPFILEHEADER, LPBITMAPFILEHEADER, *PBITMAPFILEHEADER;
typedef struct tagBITMAPINFOHEADER
{
	DWORD	biSize;
	LONG	biWidth;
	LONG	biHeight;
	WORD	biPlanes;
	WORD	biBitCount;
	DWORD	biCompression;
	DWORD	biSizeImage;
	LONG	biXPelsPerMeter;
	LONG	biYPelsPerMeter;
	DWORD	biClrUsed;
	DWORD	biClrImportant;
} BITMAPINFOHEADER, *LPBITMAPINFOHEADER, *PBITMAPINFOHEADER;
typedef struct tagRGBQUAD {
	BYTE    rgbBlue;
	BYTE    rgbGreen;
	BYTE    rgbRed;
	BYTE    rgbReserved;
} RGBQUAD,* LPRGBQUAD;
typedef struct tagBITMAPINFO {
	BITMAPINFOHEADER    bmiHeader;
	RGBQUAD             bmiColors[1];
} BITMAPINFO, *LPBITMAPINFO, *PBITMAPINFO;

#define BI_RGB        0L
#define BI_RLE8       1L
#define BI_RLE4       2L
#define BI_BITFIELDS  3L
#endif


class CAVPlayPort
{

public:
	CAVPlayPort();
	virtual ~CAVPlayPort();

	CAVPlayPort(int nPort);

	int PutFrame(unsigned char *buf, int nLen);
	int Play(long lPlayWnd, void * fCB, long lUserparam, long lMianHandle);
	int SetVolume(int nEnable, int nValue);
	int	SetDecType(int nType);
	int	SetBuffSize(int nType, int nBuffCount, int nBuffSize);
	int	Stop();
	int	StartRec(LPCTSTR lpszPath, void* recCB, long lUserParam);
	int	StopRec();
	int Capture(const char *pFileName);
	int SetFileName(int nType, const char *pFileName, void* recCB, long lUserParam);
	int OpenRecFile(const char *pFileName, DWORD* dwDuration, DWORD* dwFrameRate, void* playRecCB, long lUserParam);
	int CloseRecFile();
	int RecPause(int nPause);
	int RecSetSpeed(long nSpeed);
	long RecGetSpeed();
	int RecSeek(DWORD dwTime, const char* pFileName);
	int	SetRecParam(int nWidth, int nHeight, int nFrameRate, int nAACChannel);
	
	DWORD GetRecTime();
	long SetRecTime(DWORD dwRecTime);

	long SetH264FileRecParam(int nIsRec, const char *pMp4FileName, int nStartTime, int nTotalTime);
	long DecH264File(const char *pFileName,  int nIsRand, void* playRecCB, long lUserParam);
	long StopDecH264File();
	long AddH264File(const char *pFileName, int nFileNameLen);
	
	//typedef long (__stdcall* WriteRecCallBack)(unsigned char* pBuf,  DWORD dwSize, void* pUserParam);

	//static long __stdcall WriteRec_CallBack(unsigned char* pBuf, DWORD dwSize, void *pUserParam);

	static fJThRet RunDecThread(void* pParam);

	static fJThRet RunDecFileThread(void* pParam);

	static fJThRet RunRecThread(void* pParam);

	static fJThRet RunReadH264Thread(void* pParam);

	static long __stdcall ENC_CallBack(unsigned char* lpBuf, long lSize, long lUserParam);

protected:
	bool	DecAction();									// 处理解码的动作
	bool	DecFileAction();
	bool	RecAction();
	int		ReadH264Action();
	int		PlayNextH264File();
	void	ReadH264Finish();
	void	CheckH264File(FILE* pFile);

	int		WriteRec(unsigned char* pBuf,  DWORD dwSize);
	int		CheckMp4VideoData(unsigned char *pBuf, int nLen);
	int		AddADTSHeader(int nSample, int nChannel, int nSrcLen, unsigned char *pOut);
	int		GetSampleIndex(int nSample);
	int		GetMp4Param(const char *pFilePath, DWORD* dwDuration, DWORD* dwFrameRate);
	int		Save2BMP(const char* pFilePath);
public:
	CAVDecoder		m_decoderPort;
	CAVEncoder		m_encoderPort;
	//CAVBufferCtrl	m_avbuffCtrl;
	CAVBuffer		m_avbuffer;
	CAVBufferCtrl	m_recbuffCtrl;
	int				m_nBuffCount;	// 实时流缓存个数
	int				m_nBuffSize;	// 实时流缓存大小
	int				m_nRecBuffCount;// 录像缓存个数
	int				m_nRecBuffSize; // 录像缓存个数
	

protected:
	int				m_nCurPort;
	int				m_nPlayStatus;
	int				m_nRecFlag;
	char			m_strRecFilePath[MAX_REC_FILELEN];
	char			m_strRecCapFile[MAX_REC_FILELEN];
	ePlayType		m_ePlayType;
	
	CMutexLock		m_mutexRec;						// 关闭锁
	CMutexLock		m_mutexStop;					// 关闭锁
	CJLThreadCtrl	m_tcDec;						// 解码线程
	CJLThreadCtrl	m_tcDecFile;					// 解码文件线程
	CJLThreadCtrl	m_tcRec;						// 录像线程

	CJLThreadCtrl	m_tcReadH264;					// 读H264文件线程
	//WriteRecCallBack m_writeRecCB;
	FILE*			m_pReadH264;
	int				m_nCheckFileFlag;
	int				m_nRandDecFile;
	int				m_nIFrameCount;
	long			m_nIFramePos[MAX_IFRAME_POS_COUNT];
	int				m_nAACChannel;
	int				m_nAACSample;
	double			m_dPlaySpeed;
	int				m_nPlaySpeed;
	int				m_nOpenRecFileFlag;
	DWORD			m_nRecFrameRate;
	DWORD			m_nRecDuration;
	DWORD			m_nPlayRecFrameCount;
	DWORD			m_nLastPlayRecTime;
	int				m_nFileDecOneTime;
	int				m_nFileDecAudioTime;
	int				m_nRecVideoStreamIndex;
	int				m_nRecAudioStreamIndex;
	RECCallBack		m_playRecCB;
	long			m_lPlayRecParam;
	unsigned char	m_recExtradata[MAX_REC_FILELEN];
	int				m_nRecExtradataLen;
	int				m_nNeedPlayAudio;
	int				m_nPlayFileType;  // 0. MP4. 1.私有格式录像文件
	FILE*			m_pTestFile;
	FILE*			m_pTestFileH264;
	unsigned int	m_unPlayH264StartTime;
	int				m_nLastPlay264Time;
	int				m_nSeekCaptureFlag;

	int				m_nIsH264RecFlag;
	int				m_nIsStartWriteMp4Flag;
	int				m_nH264StartRecTime;
	int				m_nH264TotalRecTime;
	DWORD			m_unWriteFrameCount;
	unsigned char *	m_pReadH264Data;
	int				m_nReadH264MaxDataLen;
	char*			m_pH264FileNameArray[MAX_IFRAME_POS_COUNT];
	int				m_nPlayFileArrayIndex;
	int				m_nAddFileIndex;
	char*			m_pLocalFileName;
	char*			m_pCaptureH264;
	int				m_nCaptureH264Len;
	int				m_nCutEndFlag;
	int				m_nIsDecFlag;
	int				m_nLoadingFlag;
	int				m_nPlayRecSuccessFlag;
	unsigned int	m_nPlayRecStreamTime;
	
	unsigned int	m_nDecFileFrameNo;
	unsigned int	m_dwRecvRecFrameNo;
	AVFormatContext* m_pReadFileCtx;
	AVBitStreamFilterContext* m_h264BStream;
	AVBitStreamFilterContext* m_aacBStream;

};
#endif