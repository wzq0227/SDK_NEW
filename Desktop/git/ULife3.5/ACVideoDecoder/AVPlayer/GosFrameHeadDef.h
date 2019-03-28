/*
	高斯贝尔帧头定义

	1. 局域网帧头				StDataInfo

	2. TUTK旧版帧头				FRAMEINFO_t

	3. TUTK新版_Ulife3.0帧头	gos_frame_head
*/
#ifndef _GOS_FRAMEHEADDEF_H_
#define _GOS_FRAMEHEADDEF_H_

// 局域网帧头定义 begin
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
// 局域网帧头定义 end

// TUTK旧版帧头定义 begin
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
	unsigned short codec_id; // 编码类型MEDIA_CODEC_VIDEO_H264 for video.
	unsigned char flags;		
	unsigned char cam_index;
	unsigned char onlineNum;
	unsigned int nByteNum;
	unsigned char reserve1[1];
	unsigned int	reserve2;
	unsigned int timestamp;
}FRAMEINFO_t;
// TUTK旧版帧头定义 begin


// TUTK新版_Ulife3.0 帧头定义 begin
typedef struct _gos_special_data
{
	int			nLightFlag;		// 灯开关(门灯)
	int			reserved[24];		
}gos_special_data;

typedef enum _gos_frame_type
{
	gos_unknown_frame	= 0,		// 未知帧
	gos_video_i_frame,				// I 帧
	gos_video_p_frame,				// P 帧
	gos_video_b_frame,				// B 帧
	gos_video_rec_i_frame,			//录像I帧
	gos_video_rec_p_frame,			//录像P帧
	gos_video_rec_b_frame,			//录像B帧
	gos_video_rec_end_frame,		//录像完成接收完成(不带数据)
	gos_video_cut_i_frame,			//剪接录像I帧
	gos_video_cut_p_frame,			//剪接录像P帧
	gos_video_cut_b_frame,			//剪接录像B帧
	gos_video_cut_end_frame,		//剪接录像完成(不带数据)
	gos_video_preview_i_frame,		//预览图

	gos_video_rec_start_frame,		// 开始播放历时流（不带数据）
	gos_video_end_frame,	

	gos_audio_frame   = 50,			// 音频帧
	gos_rec_audio_frame   = 51, 	// 剪接音频帧
	gos_cut_audio_frame   = 52, 	// 剪接音频帧

	gos_special_frame = 100,		// 特殊帧	gos_special_data	

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
	unsigned int	nFrameNo;			// 帧号
	unsigned int	nFrameType;			// 帧类型	gos_frame_type_t
	unsigned int	nCodeType;			// 编码类型 gos_codec_type_t
	unsigned int	nFrameRate;			// 视频帧率，音频采样率
	unsigned int	nTimestamp;			// 时间戳
	unsigned short	sWidth;				// 视频宽
	unsigned short	sHeight;			// 视频高
	unsigned int	reserved;			// 预留
	unsigned int	nDataSize;			// data数据长度
	char			data[0];
}gos_frame_head;

// TUTK新版_Ulife3.0 帧头定义 end



#endif