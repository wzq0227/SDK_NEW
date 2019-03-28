//
//  FFMPEG.m
//  Ulife
//
//  Created by Yuan Xue on 12-9-14.
//  Copyright (c) 2012年 Goscam. All rights reserved.
//

#import "GDFfmpeg.h"
#import "GDVideoStateInfo.h"

//static AVStream *add_audio_stream(AVFormatContext *oc, enum CodecID codec_id)
//{
//    AVCodecContext *c;
//    AVStream *st;
//	
//    st = av_new_stream(oc, 1);
//    if (!st) {
//        fprintf(stderr, "Could not alloc stream\n");
//        return NULL;
//    }
//	
//    c = st->codec;            //该视频/音频流的AVCodecContext
//    c->codec_id = codec_id;   //采用的解码器AVCodec（H.264,MPEG2...）
//    c->codec_type = AVMEDIA_TYPE_AUDIO; //编解码器的类型（视频，音频...）
//	
//    /* put sample parameters */
//    c->sample_fmt = AV_SAMPLE_FMT_S16;
//    c->bit_rate = 32000;  //平均比特率
//    c->sample_rate = 8000;  //采样率（音频）
//    c->channels = 1; //声道数（音频）
//	
//    // some formats want stream headers to be separate
//    if(oc->oformat->flags & AVFMT_GLOBALHEADER)
//        c->flags |= CODEC_FLAG_GLOBAL_HEADER;
//
//    return st;
//}
//
//static void open_audio(AVFormatContext *oc, AVStream *st)
//{
//    AVCodecContext *c;
//    AVCodec *codec;
//	
//    c = st->codec;
//	
//    /* find the audio encoder */
//    codec = avcodec_find_encoder(c->codec_id);
//    if (!codec) {
//        fprintf(stderr, "codec not found\n");
//        return;
//    }
//	
//    if (avcodec_open(c, codec) < 0) {
//        printf("could not open codec\n");
//        return;
//    }
//	
//    /* init signal generator */
//    t = 0;
//    tincr = 2 * M_PI * 110.0 / c->sample_rate;
//    /* increment frequency by 110 Hz per second */
//    tincr2 = 2 * M_PI * 110.0 / c->sample_rate / c->sample_rate;
//	
//    audio_outbuf_size = 10000;
//    audio_outbuf = av_malloc(audio_outbuf_size);
//	
//    if (c->frame_size <= 1) {
//        audio_input_frame_size = audio_outbuf_size / c->channels;
//        switch(st->codec->codec_id) {
//			case CODEC_ID_PCM_S16LE:
//			case CODEC_ID_PCM_S16BE:
//			case CODEC_ID_PCM_U16LE:
//			case CODEC_ID_PCM_U16BE:
//				audio_input_frame_size >>= 1;
//				break;
//			default:
//				break;
//        }
//    } else {
//        audio_input_frame_size = c->frame_size;
//    }
//    
//	//++printf("c->frame_size=%d, audio_input_frame_size=%d\n",c->frame_size,audio_input_frame_size);	
//    samples = audio_input_frame_size * 2 * c->channels;
//	
//}
//
//
//static void close_audio(AVFormatContext *oc, AVStream *st)
//{
//    avcodec_close(st->codec);
//    if(samples)av_free(samples);
//	if(audio_outbuf) av_free(audio_outbuf);
//}

@interface GDFfmpeg ()
{
   
}
@end

@implementation GDFfmpeg
+(GDFfmpeg *)sharedInstance
{
    static GDFfmpeg *gdFfmpeg = nil;
    static dispatch_once_t token;
    if(gdFfmpeg == nil)
    {
        dispatch_once(&token,^{
            gdFfmpeg = [[GDFfmpeg alloc] init];}
                      );
    }
    return gdFfmpeg;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initFFMPEG];
    }
    return self;
}

//-(void)initFFMPEG
//{
//    NSLog(@"initFFMPEG");
// 
//    //++	AVFormatContext *oc;
//    //++	AVStream *audio_st = NULL;
//    // Register all formats and codecs
//    //注册所有容器格式和CODEC
//    av_register_all();
//    av_init_packet(&packet);
//    
//    // Find the decoder for the 264 & aac
//    // 查找对应的解码器,查找h264解码器
//    pCodec=avcodec_find_decoder(CODEC_ID_H264);
//    if(pCodec==NULL){
//        NSLog(@"FFmpeng init eror");
//        return;
//    }
//    
//    //创建AVFormatContext结构体
//    self->pCodecCtx = avcodec_alloc_context();
//    
//    // 打开编解码器,使用给定的AVCodec初始化AVCodecContext
//    if(avcodec_open(self->pCodecCtx, pCodec) < 0)
//    {
//        NSLog(@"FFmpeng init eror");
//        return;
//    }
//    
//    // Allocate video frame
//    //为解码帧分配内存
//    pFrame = avcodec_alloc_frame();
//    NSLog(@"video init success");
//    
//    ///////////////////////////////////////////////////////////////
//    audio_st = NULL;
//    formatContext = NULL;
//    //[self audioInit:fmt];
//    return;
//}
//
//-(void)audioInit
//{
//    AVOutputFormat *fmt;
//    const char *filename = {"goscam.aac"};
//    
//    //返回一个已经注册的最合适的输出格式
//    fmt = av_guess_format(NULL, filename, NULL);
//    if (!fmt)
//    {
//        printf("av_guess_format error, Could not deduce output format from file extension.\n");
//        NSLog(@"audio inint error");
//        return;
//    }
//
//    //AVFormatContext的初始化函数
//    formatContext = avformat_alloc_context();
//    if (!formatContext){
//        printf("Memory error\n");
//        return;
//    }
//    formatContext->oformat = fmt;
//    
//    
//#warning - memory leak
//    //内存泄露
//    if (fmt->audio_codec != CODEC_ID_NONE) {
//        audio_st = add_audio_stream(formatContext, fmt->audio_codec);
//    }
//    if (audio_st)
//        open_audio(formatContext, audio_st);
//    
//    pCodecAAcCtx = NULL;
//    pCodecAAcCtx = audio_st->codec;
//    if(pCodecAAcCtx == NULL)
//    {
//        printf("audio init failed!!!!\n");
//    }
//    else
//    {
//        printf("audio init success!!!!\n");
//    }
//}
//
//
//-(void) releaseFFMPEG
//{
//    //av_free(pFrame);
//    if (audio_st)
//        close_audio(formatContext, audio_st);
//    
//    // Close the codec h264 & aac
//    if (self->pCodecCtx)
//    {
//        avcodec_close(self->pCodecCtx);
//        av_free(self->pCodecCtx);
//        self->pCodecCtx = NULL;
//    }
//    
//    if (formatContext)
//    {
//        av_free(formatContext);
//        formatContext = NULL;
//    }
//    
//    // Free the YUV frame
//    if (pFrame) {
//        avcodec_free_frame(&pFrame);
//        pFrame = NULL;
//    }
//
//    //sws_freeContext(img_convert_ctx);
//     // Free RGB picture
////     avpicture_free(&(picture));
//     av_free_packet(&packet);
//    NSLog(@"releaseFFMPEG");
//}

-(void)dealloc
{
}
@end





