#ifndef	_AV_ENCODER_H_
#define _AV_ENCODER_H_

#include "../AVPlayer/AVPlayer.h"
#include "../AVPlayer/AVCommon.h"
#include "faac.h"

#include "G711Decoder.h"

#define MAX_RECV_PCMBUF_SIZE	100*1024

class CAVEncoder
{
public:
	CAVEncoder();
	virtual ~CAVEncoder();

public:
	int	EncodePCM2G711A(DWORD nSample, int nChannel, unsigned char *pInData, int nInLen, unsigned char **pOutData, int *nOutLen);
	int	EncodePCM2AAC(DWORD nSample, int nChannel, unsigned char *pInData, int nInLen, unsigned char **pOutData, int *nOutLen);
	int EncodeAACStart(DWORD nSample, int nChannel, ENCCallBack encCB, long lUserParam);
	int EncodeAACPutBuf(unsigned  char *pInData, int nInLen);
	int EncodeAACStop();

protected:
	int EncodeInit(DWORD nSample, int nChannel);
	int EncodeUnInit();

	
private:
	CMutexLock			m_hMutexEncode;				// ¶ÔÏóËø
// 	AVCodec*			m_pAACEncoder;
// 	AVFrame*			m_pSrcFrame;
// 	AVCodecContext*		m_pAACCxt;
	int					m_nInitFlag;
	unsigned long		m_nInputSamples;
	unsigned long		m_nMaxOutputBytes;
	unsigned char*		m_pPcmBuff;
	unsigned char*		m_pTempBuff;
	unsigned char*		m_pRecvBuf;
	unsigned long		m_nTempLen;
	int					m_nRecvSuccess;
	int					m_nHasRecvLen;
	faacEncHandle		m_hAACHandle;
	DWORD				m_nOldSample;
	int					m_nOldChannel;
	ENCCallBack			m_encCallBack;
	long				m_lUserParam;
	CG711Decoder		m_g711Dec;
};


#endif