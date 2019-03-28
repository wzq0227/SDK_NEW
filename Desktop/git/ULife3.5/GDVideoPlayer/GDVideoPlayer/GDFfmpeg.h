//
//  FFMPEG.h
//  Ulife
//
//  Created by Yuan Xue on 12-9-14.
//  Copyright (c) 2012年 Goscam. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GDFfmpeg : NSObject
{
//    @public
//        AVCodecContext *pCodecCtx;
//        AVCodecContext *pCodecAAcCtx;
//        struct SwsContext  *img_convert_ctx;
//        AVFormatContext *formatContext;
//    
//        //存储每一个视频/音频流信息的结构体
//        AVStream *audio_st;
//    
//        //存储编解码器信息的结构体 主要的几个变量
//        AVCodec            *pCodec;
//    
//       //存储压缩编码数据相关信息的结构体
//        AVPacket           packet;
//    
//        AVPicture          picture;
//        //AVFrame结构体一般用于存储原始数据（即非压缩数据，例如对视频来说是YUV，RGB，对音频来说是PCM），此外还包含了一些相关的信息
//        AVFrame            *pFrame;
}
+ (GDFfmpeg *)sharedInstance;
-(void) initFFMPEG;
-(void) releaseFFMPEG;
@end

//static AVStream *add_audio_stream(AVFormatContext *oc, enum CodecID codec_id);
//static void open_audio(AVFormatContext *oc, AVStream *st);







