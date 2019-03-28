///********************************************************************************************
//*** Copyright (c) 2007, anpson,Inc.
//*** File name  : Player.h
//*** Module     :  
//*** Author     : 
//*** Version    : 1.0
//*** Created On : 2007.03.17
//*** Description:
//***            
//*** Modification histroy:
//*********************************************************************************************/
//#ifndef _PARSER_H_
//#define _PARSER_H_
//
//#define MAX_TS        0xffffffff
//#define MAX_FRAMENUM 0xffffffff
//
//#define FRAME_MAX_DRIFT        30
//
///* Audio/Video Frame Header Info */
//typedef struct _FRAMEINFO
//{
//    unsigned short codec_id;    //音视频编解码器类型
//    unsigned char flags;        //帧类型，I帧/P帧/B帧
//    unsigned char cam_index;    //摄像头序号，暂时没用到该变量
//    unsigned char onlineNum;    //当前在线会话数
//    unsigned int  nByteNum;     // 帧长,不包含帧头
//    unsigned char reserve1[1];    //保留位，暂时没用到该变量
//    unsigned int reserve2;        //视频质量参数，0：高清，1：标清
//    unsigned int timestamp;        //帧时间戳    
//}FRAMEINFO_t;
//
///* CODEC ID */
//typedef enum 
//{
//    MEDIA_CODEC_UNKNOWN            = 0x00,
//    MEDIA_CODEC_VIDEO_MPEG4        = 0x4C,
//    MEDIA_CODEC_VIDEO_H263        = 0x4D,
//    MEDIA_CODEC_VIDEO_H264        = 0x4E,
//    MEDIA_CODEC_VIDEO_MJPEG        = 0x4F,
//    
//    MEDIA_CODEC_AUDIO_AAC       = 0x88,   // 2014-07-02 add AAC audio codec definition
//    MEDIA_CODEC_AUDIO_G711U     = 0x89,   //g711 u-law
//    MEDIA_CODEC_AUDIO_G711A     = 0x8A,   //g711 a-law    
//    MEDIA_CODEC_AUDIO_ADPCM     = 0X8B,
//    MEDIA_CODEC_AUDIO_PCM        = 0x8C,
//    MEDIA_CODEC_AUDIO_SPEEX        = 0x8D,
//    MEDIA_CODEC_AUDIO_MP3        = 0x8E,
//    MEDIA_CODEC_AUDIO_G726      = 0x8F,
//
//}ENUM_CODECID;
//
///* FRAME Flag */
//typedef enum 
//{
//    IPC_FRAME_FLAG_PBFRAME    = 0x00,    // A/V P/B frame..
//    IPC_FRAME_FLAG_IFRAME    = 0x01,    // A/V I frame.
//    IPC_FRAME_FLAG_MD        = 0x02,    // For motion detection.
//    IPC_FRAME_FLAG_IO        = 0x03,    // For Alarm IO detection.
//}ENUM_FRAMEFLAG;
//
////数据帧标志
//#define ANC_FRAME_FLAG_VP         0x0b    //视频的P帧
//#define ANC_FRAME_FLAG_VI         0x0e    //视频的I帧
//#define ANC_FRAME_FLAG_A         0x0d    //音频帧
//#define ANC_FRAME_FLAG_REC_A     0x0a    //录像音频帧
//
//
//
//    // Stream type:
//#define ANC_STREAM_UNKNOWN            0
//#define ANC_STREAM_MPEG4                1
//#define ANC_STREAM_H264                2
//#define ANC_STREAM_ANCPT                3
//#define ANC_STREAM_NEW                4
//#define ANC_STREAM_HB                    5
//#define ANC_STREAM_AUDIO                6
//#define ANC_STREAM_PS                          7
//#define ANC_STREAM_ANCSTD                    8
//#define ANC_STREAM_ASF                      9
//#define ANC_STREAM_HIK                10
//
////音频压缩类型
//typedef enum 
//{
//     ANC_AUDIO_PCM_ULAW = 0x01,
//    ANC_AUDIO_G722 =     0x02,
//     ANC_AUDIO_PCM_ALAW = 0x03,
//     ANC_AUDIO_AAC =      0x04,
//     ANC_AUDIO_G726 =     0x05,
//     ANC_AUDIO_ADPCM =    0x06     
//    
//}ANC_AUDIO_COMPRESS_TYPE;
//
////编码模式列表
//typedef enum 
//{
//    ANC_CAPTURE_COMP_DIVX_MPEG4=0x01,
//    ANC_CAPTURE_COMP_H264=0x02,
//    ANC_CAPTURE_COMP_MPEG2=0x03,
//    ANC_CAPTURE_COMP_MPEG1=0x04,
//    ANC_CAPTURE_COMP_H263=    0x05,
//    ANC_CAPTURE_COMP_MJPG=    0x06,
//    ANC_CAPTURE_COMP_FCC_MPEG4=0x07,
//    ANC_CAPTURE_COMP_MS_MPEG4=    0x08,
//    ANC_CAPTURE_COMP_HIK=    0x09    
//}ANC_CAPTURE_COMP;
//
//#define ANC_MAGIC_FLAG        0x4567
//#define ANC_MAX_FRAME_LEN    0x24000
//
////帧包大小
//typedef enum _ANC_FRAME_PACKET_SIZE
//{
//    ANC_FRAME_HEAD_SIZE = 24,
//    ANC_NET_PACKET_HEAD_SIZE = 24,
//    ANC_NET_PACKET_DATA_SIZE = 1000,
//    ANC_NET_PACKET_MAX_SIZE = ANC_NET_PACKET_HEAD_SIZE + ANC_NET_PACKET_DATA_SIZE
//        
//}ANC_FRAME_PACKET_SIZE;
//
////包头结构
//typedef struct _ANC_NET_PACKET_HEAD
//{
//    unsigned int        nNetFlag;
//    unsigned int          nFrameFlag;    //bit0~bit7: nFrameType ; bit8~bit15: nFrameRate;  bit16~bit23: nCodecType
//    unsigned int        nFrameNo;
//    unsigned int        nPakcetNo;
//    unsigned int        nPakcetCount;
//    unsigned int        nBufferSize;    
//}ANC_NET_PACKET_HEAD;
//
//#define FRAME_NUM_DISPLAY    10
//#define FRAME_NUM_STORE        20
//
//#define ERR_INVALID_DATA                        -1
//#define ERR_NOT_FRM_HEAD                        -2
//#define ERR_FRM_NOT_END                            -3
//#define ERR_GETFRM_ERR                            -4
//#define ERR_NOT_OPEN                            -5
//#define ERR_ALREADY_OPENED                        -6
//#define ERR_MEM_ALLOC_FAIL                        -7
//#define ERR_NULL_DATA                            -8
//#define ERR_GETFRM_MORE                            1
//
//typedef struct{
//    unsigned char  bUsed;
//    unsigned int nFrameNo;        //The No of frame
//    unsigned int nFrameType;     //I Frame , P  Frame or Aduio
//    unsigned int nFrameLength;   //The length of this frame
//    unsigned int nRecvSize;        //Have received size
//    unsigned int nTimestamp;        //The time stamp for the frame start
//    unsigned char* pbuf;            //The buf address for frame data
//}FrameInfo;
//
//
//    // Frame Type and SubType
//#define ANC_FRAME_TYPE_UNKNOWN        0
//#define ANC_FRAME_TYPE_VIDEO        1
//#define ANC_FRAME_TYPE_AUDIO        2
//#define ANC_FRAME_TYPE_DATA            3
//
//#define ANC_FRAME_TYPE_VIDEO_I_FRAME    0
//#define ANC_FRAME_TYPE_VIDEO_P_FRAME    1
//#define ANC_FRAME_TYPE_VIDEO_B_FRAME    2
//#define ANC_FRAME_TYPE_VIDEO_S_FRAME    3
//#define ANC_FRAME_TYPE_AUDIO_REC           4
//#define ANC_FRAME_TYPE_AUDIO_LIVE          5
//#define ANC_FRAME_TYPE_DATA_TEXT        6
//#define ANC_FRAME_TYPE_DATA_INTL         7
//
//typedef struct ANC_FRAME_INFO_S
//{
//    unsigned char* pHeader;  //包含头的数据指针
//    unsigned char* pContent; //真正数据的偏移
//    unsigned int nLength; //数据长度(包括头部)
//    unsigned int nFrameLength; //数据长度.
//    
//    unsigned int nType; // VIDEO, AUDIO, DATA
//    unsigned int nSubType; // I-FRAME, P-FRAME, etc.
//    
//    unsigned int nEncodeType; // MPEG4/H264, PCM, MSADPCM, etc.
//    // 只有I帧才有的数据
//    unsigned int nYear;
//    unsigned int nMonth;
//    unsigned int nDay;
//    unsigned int nHour;
//    unsigned int nMinute;
//    unsigned int nSecond;
//    unsigned int nTimeStamp;
//    
//    unsigned int  nFrameRate;    //帧率
//    unsigned int              nWidth;  //图象宽度
//    unsigned int              nHeight; //图象高度
//    unsigned int nRequence; //序列号
//    // 音频才有的数据
//    unsigned int nChannels;
//    unsigned int nBitsPerSample;
//    unsigned int nSamplesPerSecond;
//    
//    unsigned int nParam1;        // 扩展用
//    unsigned int nParam2;        // 扩展用
//    
//} ANC_FRAME_INFO;
//
//typedef void * PARSERHANDLE;
//
//typedef unsigned int (* ANC_SP_CALLBACK)(PARSERHANDLE hHandle, unsigned int msg, unsigned int dwParam1, unsigned int dwParam2, unsigned int dwUserData);
//
//class CParser 
//{
//public:
//    CParser(ANC_SP_CALLBACK sp_cb,unsigned long nUser, bool bSort=false);
//    virtual~ CParser();
//
//    //Get One Frame from Buffer
//    int GetFrame(unsigned char* pBuf,unsigned int Len);
//    ANC_FRAME_INFO* ParseFrame();
//    int Reset();
//    int Open(bool bAllowAudioFirst);
//    int Close();
//    
//protected:
//    
//    int IsValidData(unsigned char* buf);
//    int IsValidData_Sort(unsigned char* buf);    
//    bool IsFrameEnd(unsigned char* buf);
//    int GetDataLen(unsigned char* buf);
//        int GetFrame_NSort(unsigned char* pBuf,unsigned int Len);
//        int GetFrame_Sort(unsigned char* pBuf,unsigned int Len);
//    int ParseFrame_NSort();
//    int ParseFrame_Sort();
//    void ObsoleteFrame_Sort(int nFrameNumBefore);    
//    int getOldestFrameIndex();    
//    int GetDisplayFrameIndex();
//    int GetFrameInfo(unsigned char* pBuf, int nSize);
//
//    ANC_SP_CALLBACK m_sp_cb;
//    unsigned long m_nUser;
//    ///////////////////////
//
//protected:
//    int m_expPacketNo;
//    int m_expFrameNo;
//    int m_gotFrameHead;
//    int m_gotFrameTail;
//
//    unsigned char* m_FrameData;
//    unsigned int m_FrameLen;
//
//    bool m_bAllowAudioFirst;
//    bool m_bOpened;        
//    bool m_bfirstFrm;
//    bool m_bSort;
//
//    //For store frame data
//    unsigned int m_LastFrameNum;    
//    FrameInfo m_FrameBuf[FRAME_NUM_STORE];
//
//    ANC_FRAME_INFO   frame_info;
//};
//
//PARSERHANDLE ANC_SP_Init(ANC_SP_CALLBACK msg_cb, unsigned long nUser, bool bAllowAudioFirst,bool bSort);
//
//int ANC_SP_Free(PARSERHANDLE hHandle);
//
//int ANC_SP_InputData(PARSERHANDLE hHandle, unsigned char *byData, unsigned int dwLength);
//
//ANC_FRAME_INFO *ANC_SP_GetNextFrame(PARSERHANDLE hHandle);
//
//ANC_FRAME_INFO *ANC_SP_GetNextKeyFrame(PARSERHANDLE hHandle);
//
//void ANC_SP_Reset(PARSERHANDLE hHandle, int nFlag);
//
//#endif
//
