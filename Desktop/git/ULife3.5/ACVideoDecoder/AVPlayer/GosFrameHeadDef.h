/*
	��˹����֡ͷ����

	1. ������֡ͷ				StDataInfo

	2. TUTK�ɰ�֡ͷ				FRAMEINFO_t

	3. TUTK�°�_Ulife3.0֡ͷ	gos_frame_head
*/
#ifndef _GOS_FRAMEHEADDEF_H_
#define _GOS_FRAMEHEADDEF_H_

// ������֡ͷ���� begin
typedef struct
{
	unsigned int	nIFrame;	// 1,yes;	2,no
	unsigned int	nAVType;	// 1,video;	2,audio
	unsigned int	dwSize;		// audio or video data size
	unsigned int	gs_frameRate_samplingRate;	// video frame rate or audio samplingRate
	unsigned int	lTMStamp;
	unsigned int	gs_video_cap;				// video's capability
	unsigned int	gs_reserved; 
}StDataInfo;
// ������֡ͷ���� end

// TUTK�ɰ�֡ͷ���� begin
/* CODEC ID */
typedef enum 
{
	MEDIA_CODEC_UNKNOWN			= 0x00,
	MEDIA_CODEC_VIDEO_MPEG4		= 0x4C,
	MEDIA_CODEC_VIDEO_H263		= 0x4D,
	MEDIA_CODEC_VIDEO_H264		= 0x4E,
	MEDIA_CODEC_VIDEO_MJPEG		= 0x4F,

	MEDIA_CODEC_AUDIO_AAC       = 0x88,   // 2014-07-02 add AAC audio codec definition
	MEDIA_CODEC_AUDIO_G711U     = 0x89,   //g711 u-law
	MEDIA_CODEC_AUDIO_G711A     = 0x8A,   //g711 a-law	
	MEDIA_CODEC_AUDIO_ADPCM     = 0X8B,
	MEDIA_CODEC_AUDIO_PCM		= 0x8C,
	MEDIA_CODEC_AUDIO_SPEEX		= 0x8D,
	MEDIA_CODEC_AUDIO_MP3		= 0x8E,
	MEDIA_CODEC_AUDIO_G726      = 0x8F,

}ENUM_CODECID;

typedef struct _FRAMEINFO1
{
	unsigned short codec_id; // ��������MEDIA_CODEC_VIDEO_H264 for video.
	unsigned char flags;		
	unsigned char cam_index;
	unsigned char onlineNum;
	unsigned int nByteNum;
	unsigned char reserve1[1];
	unsigned int	reserve2;
	unsigned int timestamp;
}FRAMEINFO_t;
// TUTK�ɰ�֡ͷ���� begin


// TUTK�°�_Ulife3.0 ֡ͷ���� begin
typedef struct _gos_special_data
{
	int			nLightFlag;		// �ƿ���(�ŵ�)
	int			reserved[24];		
}gos_special_data;

typedef enum _gos_frame_type
{
	gos_unknown_frame	= 0,		// δ֪֡
	gos_video_i_frame,				// I ֡
	gos_video_p_frame,				// P ֡
	gos_video_b_frame,				// B ֡
	gos_video_rec_i_frame,			//¼��I֡
	gos_video_rec_p_frame,			//¼��P֡
	gos_video_rec_b_frame,			//¼��B֡
	gos_video_rec_end_frame,		//¼����ɽ������(��������)
	gos_video_cut_i_frame,			//����¼��I֡
	gos_video_cut_p_frame,			//����¼��P֡
	gos_video_cut_b_frame,			//����¼��B֡
	gos_video_cut_end_frame,		//����¼�����(��������)
	gos_video_preview_i_frame,		//Ԥ��ͼ

	gos_video_rec_start_frame,		// ��ʼ������ʱ�����������ݣ�
	gos_video_end_frame,	

	gos_audio_frame   = 50,			// ��Ƶ֡
	gos_rec_audio_frame   = 51, 	// ������Ƶ֡
	gos_cut_audio_frame   = 52, 	// ������Ƶ֡

	gos_special_frame = 100,		// ����֡	gos_special_data	

} gos_frame_type_t;

typedef enum _gos_codec_type
{
	gos_codec_unknown = 0,

	gos_video_codec_start = 10,
	gos_video_H264_AAC,
	gos_video_H264_G711A,
	gos_video_H265,
	gos_video_MPEG4,
	gos_video_MJPEG,
	gos_video_codec_end,

	gos_audio_codec_start = 50,
	gos_audio_AAC,
	gos_audio_G711A,
	gos_audio_G711U,
	gos_audio_codec_end,

} gos_codec_type_t;

typedef struct _gos_frame_head
{
	unsigned int	nFrameNo;			// ֡��
	unsigned int	nFrameType;			// ֡����	gos_frame_type_t
	unsigned int	nCodeType;			// �������� gos_codec_type_t
	unsigned int	nFrameRate;			// ��Ƶ֡�ʣ���Ƶ������
	unsigned int	nTimestamp;			// ʱ���
	unsigned short	sWidth;				// ��Ƶ��
	unsigned short	sHeight;			// ��Ƶ��
	unsigned int	reserved;			// Ԥ��
	unsigned int	nDataSize;			// data���ݳ���
	char			data[0];
}gos_frame_head;

// TUTK�°�_Ulife3.0 ֡ͷ���� end



#endif