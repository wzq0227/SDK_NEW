/******************************************************************************

                  ∞Ê»®À˘”– (C), 2012-2022, mr.liubing@gmail.com

 ******************************************************************************
  Œƒ º˛ √˚   : FFMuxing.c
  ∞Ê ±æ ∫≈   : ≥ı∏Â
  ◊˜    ’ﬂ   : mr.iubing
  …˙≥…»’∆⁄   : 2014ƒÍ4‘¬30»’
  ◊ÓΩ¸–ﬁ∏ƒ   :
  π¶ƒ‹√Ë ˆ   : support .mp4 .ts ..flv
  –ﬁ∏ƒ¿˙ ∑   :
  1.»’    ∆⁄   : 2014ƒÍ4‘¬30»’
    ◊˜    ’ﬂ   : mr.iubing
    –ﬁ∏ƒƒ⁄»›   : ¥¥Ω®Œƒº˛

******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <libavformat/avformat.h>
#include <libavutil/avutil.h>
#include <libavutil/timestamp.h>
#include "libavutil/pixdesc.h"
//#define FFMUXING_DEBUG

static int64_t gVideoPts = 0;
static int64_t gAudioPts = -1600;

#ifdef FFMUXING_DEBUG
static void log_packet(const AVFormatContext *fmt_ctx, const AVPacket *pkt)
{
    AVRational *time_base = &fmt_ctx->streams[pkt->stream_index]->time_base;
    Dbg_Trace(GOS_LOG_DEBUG, "pts:%s pts_time:%s dts:%s dts_time:%s duration:%s duration_time:%s stream_index:%d\n",
           av_ts2str(pkt->pts), av_ts2timestr(pkt->pts, time_base),
           av_ts2str(pkt->dts), av_ts2timestr(pkt->dts, time_base),
           av_ts2str(pkt->duration), av_ts2timestr(pkt->duration, time_base),
           pkt->stream_index);
}
#endif

/* Add an output stream. */
static AVStream *add_stream(AVFormatContext *oc, AVCodec **codec,
                            enum AVCodecID codec_id, unsigned int streamNumber)
{
    AVCodecContext *c;
    AVStream *st;

    /* find the encoder */
    *codec = avcodec_find_encoder(codec_id);
    if (!(*codec)) 
    {
//        Dbg_Trace(GOS_LOG_ERR,  "Could not find encoder for '%s'\n",
//        avcodec_get_name(codec_id));
        return NULL;
    }

    st = avformat_new_stream(oc, *codec);
    if (!st) 
    {
//        Dbg_Trace(GOS_LOG_ERR,  "Could not allocate stream\n");
        return NULL;
    }
    st->id = oc->nb_streams-1;
    c = st->codec;

    switch ((*codec)->type) 
    {
        case AVMEDIA_TYPE_AUDIO:
            c->sample_fmt  = (*codec)->sample_fmts ? (*codec)->sample_fmts[0] : AV_SAMPLE_FMT_FLTP;
            c->bit_rate    = 44100;
            c->sample_rate = 16000;
            c->channels    = 2;
            break;

        case AVMEDIA_TYPE_VIDEO:
            c->codec_id = codec_id;

            /* Resolution must be a multiple of two. */
//            c->width    = stVEncCtrl[streamNumber].Width; //0 1280*70 1 640*480 宽：1280  高：720 
//            c->height   = stVEncCtrl[streamNumber].Height;
//
//            c->bit_rate = stVEncCtrl[streamNumber].Bitrate << 10; //128
//            /* timebase: This is the fundamental unit of time (in seconds) in terms
//            * of which frame timestamps are represented. For fixed-fps content,
//            * timebase should be 1/framerate and timestamp increments should be
//            * identical to 1. */
//            c->time_base.den = stVEncCtrl[streamNumber].FrameRate;//8
//            c->time_base.num = 1;
//            c->gop_size      = 25; /* emit one intra frame every twelve frames at most */
//            c->pix_fmt       = PIX_FMT_YUV420P;
//            c->profile       = FF_PROFILE_H264_MAIN;
            if (c->codec_id == AV_CODEC_ID_MPEG2VIDEO)
            {
                /* just for testing, we also add B frames */
                c->max_b_frames = 2;
            }
            if (c->codec_id == AV_CODEC_ID_MPEG1VIDEO) 
            {
                /* Needed to avoid using macroblocks in which some coeffs overflow.
                * This does not happen with normal video, it just happens here as
                * the motion of the chroma plane does not match the luma plane. */
                c->mb_decision = 2;
            }
            break;

        default:
            break;
    }

    /* Some formats want stream headers to be separate. */
    if (oc->oformat->flags & AVFMT_GLOBALHEADER)
        c->flags |= CODEC_FLAG_GLOBAL_HEADER;

    return st;
}

int open_audio(AVFormatContext *oc, AVCodec *codec, AVStream *st)
{
    AVCodecContext *c;

    c = st->codec;

    /* open it */
    if (avcodec_open2(c, codec, NULL) < 0) 
    {
//        Dbg_Trace(GOS_LOG_ERR,  "could not open audio codec\n");
        return -1;
    }

    return 0;
}

int write_audio_frame(AVFormatContext *oc, AVStream *st,unsigned char *buf, int framesize, unsigned int timestamp)
{
    AVCodecContext *c;
    AVPacket pkt = { 0 }; // data and size must be 0;

    int ret;

    c = st->codec;
    av_init_packet(&pkt);

    if (framesize >0)
    {        	
        pkt.size         = framesize ;		

        pkt.flags |= AV_PKT_FLAG_KEY;
        pkt.stream_index = st->index;
        pkt.data         = buf ;

        pkt.dts = pkt.pts = gAudioPts;
        pkt.duration = av_rescale_q(16000, (AVRational){ 1, c->sample_rate }, c->time_base);
        
        gAudioPts+=1024;//768;
        
        pkt.pts = av_rescale_q_rnd(pkt.pts, c->time_base, st->time_base, AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX);
        pkt.dts = av_rescale_q_rnd(pkt.dts, c->time_base, st->time_base, AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX);
        pkt.duration = av_rescale_q(pkt.duration, c->time_base, st->time_base);
        #ifdef FFMUXING_DEBUG
        log_packet(oc, &pkt);
        #endif
        ret = av_interleaved_write_frame(oc, &pkt);
    }

    //  Write the compressed frame to the media file.    
    if (ret != 0) 
    {
//        Dbg_Trace(GOS_LOG_ERR,  "Error while writing audio frame:%d->%s\n", ret, av_err2str(ret));
        return -1;
    }
    
    return 0;
}


void close_audio(AVFormatContext *oc, AVStream *st)
{
    avcodec_close(st->codec);
}

int open_video(AVFormatContext *oc, AVCodec *codec, AVStream *st)
{
    AVCodecContext *c;

    c = st->codec;

    if(avcodec_open2(c, codec, NULL)<0)
    {
//        Dbg_Trace(GOS_LOG_ERR,  "could not open codec\n");
        return -1;
    }

    return 0;
}


int write_video_frame(AVFormatContext *oc, AVStream *st, unsigned char *decodedBuf, int frameSize, unsigned int timestamp, int frameType)
{
    int  ret;
    AVCodecContext *c;
    
    c = st->codec;

    /* If size is zero, it means the image was buffered. */

    if (frameSize > 0) 
    {
        AVPacket pkt;
        av_init_packet(&pkt);

        if (frameType)
            pkt.flags |= AV_PKT_FLAG_KEY;

        pkt.stream_index = st->index;
        pkt.data         = decodedBuf;
        pkt.size         = frameSize;

        c->coded_frame->pts++;

        pkt.pts = gVideoPts;
        pkt.dts = gVideoPts - 2;

        ++gVideoPts;
        
        pkt.pts = av_rescale_q_rnd(pkt.pts, c->time_base, st->time_base, AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX);
        pkt.dts = av_rescale_q_rnd(pkt.dts, c->time_base, st->time_base, AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX);
        pkt.duration = av_rescale_q(pkt.duration, c->time_base, st->time_base);
        #ifdef FFMUXING_DEBUG
        log_packet(oc, &pkt);
        #endif

        ret = av_interleaved_write_frame(oc, &pkt);

    }

    if (ret != 0) 
    {
//        Dbg_Trace(GOS_LOG_ERR,  "Error while writing video frame:%d->%s\n", ret, av_err2str(ret));
        return -1;
    }

    return 0;
}

void close_video(AVFormatContext *oc, AVStream *st)
{
    avcodec_close(st->codec);
}

AVOutputFormat *fmt = NULL;
AVFormatContext *oc = NULL;
AVStream *audio_st = NULL, *video_st = NULL;

int FFMux_Open(const char *filename, unsigned int streamNumber)
{
    AVCodec *audio_codec, *video_codec;
    int ret;
    /* Initialize libavcodec, and register all codecs and formats. */
    av_register_all();

    /* allocate the output media context */
    avformat_alloc_output_context2(&oc, NULL, NULL, filename);
    if (!oc) 
    {
//        Dbg_Trace(GOS_LOG_WARN, "Could not deduce output format from file extension: using MPEG.\n");
        avformat_alloc_output_context2(&oc, NULL, "mpeg", filename);
    }
    if (!oc)
        return -1;

    // «ø÷∆÷∏∂® 264 ±‡¬Î  
    oc->oformat->video_codec = AV_CODEC_ID_H264;
    oc->oformat->audio_codec = AV_CODEC_ID_AAC; 

    fmt = oc->oformat;

    /* Add the audio and video streams using the default format codecs
    * and initialize the codecs. */
    if (fmt->video_codec != AV_CODEC_ID_NONE)
        video_st = add_stream(oc, &video_codec, fmt->video_codec, streamNumber);
    if (fmt->audio_codec != AV_CODEC_ID_NONE)
        audio_st = add_stream(oc, &audio_codec, fmt->audio_codec, streamNumber);

    /* Now that all the parameters are set, we can open the audio and
    * video codecs and allocate the necessary encode buffers. */
    if (video_st)
        open_video(oc, video_codec, video_st);
    if (audio_st)
        open_audio(oc, audio_codec, audio_st);
    
    #ifdef FFMUXING_DEBUG
    av_dump_format(oc, 0, filename, 1);
    #endif

    /* open the output file, if needed */
    if (!(fmt->flags & AVFMT_NOFILE)) 
    {
        ret = avio_open(&oc->pb, filename, AVIO_FLAG_WRITE);
        if (ret < 0) 
        {
//            Dbg_Trace(GOS_LOG_ERR,  "Could not open '%s': %s\n", filename,
//            av_err2str(ret));
            goto OPEN_ERROR;
        }
    }

    /* Write the stream header, if any. */
    ret = avformat_write_header(oc, NULL);
    if (ret < 0) 
    {
//        Dbg_Trace(GOS_LOG_ERR,  "Error occurred when opening output file: %s\n",
//        av_err2str(ret));
        goto OPEN_ERROR;
    }
    gVideoPts = 0;
    gAudioPts = -1600;
    return 0;

    OPEN_ERROR:
        /* Close each codec. */
        if (video_st)
            close_video(oc, video_st);
        if (audio_st)
            close_audio(oc, audio_st);

        if (!(fmt->flags & AVFMT_NOFILE))
            /* Close the output file. */
            avio_close(oc->pb);

        /* free the stream */
        avformat_free_context(oc);

    return -1;
}

int FFMuxWriteVideoData(unsigned char *buf, int framesize, unsigned int timestamp, int frameType)
{
    return write_video_frame(oc, video_st, buf, framesize, timestamp, frameType);
}

int FFMuxWriteAudioData(unsigned char *buf, int framesize, unsigned int timestamp)
{
    return write_audio_frame(oc, audio_st, buf, framesize, timestamp);
}

int FFMuxGetRecordTime()
{
    return (video_st->pts.val * av_q2d(video_st->time_base));
}

void FFMux_Close()
{
    /* Write the trailer, if any. The trailer must be written before you
     * close the CodecContexts open when you wrote the header; otherwise
     * av_write_trailer() may try to use memory that was freed on
     * av_codec_close(). */
    av_write_trailer(oc);

    /* Close each codec. */
    if (video_st)
        close_video(oc, video_st);
    if (audio_st)
        close_audio(oc, audio_st);

    if (!(fmt->flags & AVFMT_NOFILE))
        /* Close the output file. */
        avio_close(oc->pb);

    /* free the stream */
    avformat_free_context(oc);
}

