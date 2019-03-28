

#include "gos-processing.h"
#include "stdio.h"
#include "stdlib.h"
#include "string.h"

#define AAC_SPEEX_PROCESS_ENABLED
#define DSP_BUFFER_FRAME_SIZE 0

/****************************************************************************************************
 * SPEEX FIELDS
 ****************************************************************************************************/
/** SPEEX 预处理结构体 */
static SpeexPreprocessState *dsp_st=NULL;
/** SPEEX_AUDIO_PRE_PROCESS 对应的文件对象 */
static FILE *dsp_preprocess=NULL;
/** SPEEX_AUDIO_POST_PROCESS 对应的文件对象 */
static FILE *dsp_postprocess=NULL;
/** SPEEX 处理的次数 */
//static int speex_buffer_count = 0;
/** SPEEX 是否启用(主开关) */
#ifdef AAC_SPEEX_PROCESS_ENABLED
static int dsp_enabled = 1;
#else
static int dsp_enabled = 0;
#endif
/** SPEEX 是否已经初始化*/
static int dsp_inited = 0;
/** (已废弃, 使用SPEEX_PROCESS_FRAME_SIZE)可设置的SPEEX每次处理的帧长 */
//static int speex_frame_size = 12 * 1024;
static int dsp_frame_size = DSP_BUFFER_FRAME_SIZE;
/** SPEEX 处理的音频的采样率 */
static int dsp_sample_rate = 16000;
/** 保存PCM到文件的开关, 用于比较SPEEX处理前后的音频数据的差异 */
static int dsp_save_files = 0;

static int nFramesPacketState = 0;
static char *g_preFileName = NULL;
static char *g_postFileName = NULL;


/**
 * Common info struct used for storing info between calls.
 */
typedef struct DspCtrl {
    
    /*##############################################
     * 以下字段为Speex.get||set字段. 与Java.衔接.<br>
     * 保留各字段方便C这边操作<br>
     ##############################################*/
    
    /**
     * Can't set power spectrum<br>
     * Get power spectrum (int32[] of squared values)<br>
     */
    int* psd;
    
    /**
     * Can't set noise estimate<br>
     * Get noise estimate (int32[] of squared values)<br>
     */
    int* noisePsd;
    
    /**
     *
     */
    float agcLevel; //8000 16000 24000
    
    /**
     * 余响等级
     */
    float dereverbLevel;
    
    /**
     * 余响衰减
     */
    float dereverbDecay;
    
    /**
     * 降噪
     */
    int denoise;//0 关闭 1 开启
    /**
     * 自动增益
     */
    int agc; //0关闭 1开启
    
    /**
     * Set maximal gain increase in dB/second (int32)
     */
    int agcIncrement;
    
    /**
     * Set maximal gain decrease in dB/second (int32)
     */
    int agcDecrement;
    
    /**
     * Set maximal gain in dB (int32)
     */
    int agcMaxGain;
    
    /**
     * Can't set loudness<br>
     * Get current loudness<br>
     */
    int agcLoudness;
    
    /**
     * Can't set gain <br>
     * Get current gain (int32 percent)<br>
     */
    int agcGain;
    
    /** Set preprocessor Automatic Gain Control level (int32) */
    int agcTarget;
    
    /**
     * 声音活动侦测
     */
    int vad;//0 关闭 1 开启
    
    /**
     * Can't set speech probability<br>
     * Probability last frame was speech<br>
     * Get speech probability in last frame (int32).<br>
     */
    int prob;
    
    /**
     * Set probability required for the VAD to go from silence to voice
     */
    int probStart;
    
    /**
     * Set probability required for the VAD to stay in the voice state
     * (integer percent)
     */
    int probContinue;
    
    /**
     * de:降低/减少<br>
     * reverb:余响<br>
     */
    int dereverb;
    
    /**
     * Set maximum attenuation of the noise in dB (negative number)
     */
    int noiseSuppress;
    
    //		/**
    //		 * Set the corresponding echo canceller state so that residual echo
    //		 * suppression can be performed (NULL for no residual echo suppression)
    //		 */
    //		public int echoState;
    
    /**
     * Set maximum attenuation of the residual echo in dB (negative number)
     */
    int echoSuppress;
    /**
     * Set maximum attenuation of the residual echo in dB when near end is
     * active (negative number)
     */
    int echoSuppressActive;
    
    /**
     * Can't set spectrum size <br>
     * Number of points in the power spectrum<br>
     * Get spectrum size for power spectrum (int32)<br>
     * {@link #psdSize} = {@link #noisePsdSize}
     */
    int psdSize;
    
    /**
     * Can't set noise size <br>
     * Number of points in the power spectrum<br>
     * Get spectrum size for noise estimate (int32)<br>
     * {@link #psdSize} = {@link #noisePsdSize}
     */
    int noisePsdSize;
} DspCtrl;


static DspCtrl * dsp_ctrl = NULL;

/**
 * 保存SPEEX处理前的PCM数据
 */
void dsp_save_preporcess_samples(short* samples,
		int samples_size) {
	if (dsp_save_files) {
		// write pcm decoded by aac-decoder.
		// [input(aac)-->>aac_decoder(pcm)-->>dsp_preprocess]
		int pre_process_wrote = fwrite(samples, sizeof(short), samples_size,
				dsp_preprocess);
//		printf( "dsp-file: pcm pre process_wrote=%d", pre_process_wrote);
	}
}

/**
 * 保存SPEEX处理后的PCM数据
 */
void dsp_save_postprocess_samples(short* samples,
		int samples_size) {
	if (dsp_save_files) {
		// write pcm precessed by speex.
		// [input(aac)-->>aac_decoder(pcm)-->>speex(pcm)-->>dsp_postprocess]
		int post_process_wrote = fwrite(samples, sizeof(short), samples_size,
				dsp_postprocess);
//		printf( "dsp-file: pcm post process_wrote=%d", post_process_wrote);
	}
}

/**
 * 处理一包PCM数据(可能包含多帧).<br>
 * 这里做分组处理, 每组大小在speex_preprocess_state_init时已经设定<br>
 */
void goscam_dsp_process(short * samples, int sample_size)
{
	if (dsp_enabled && dsp_inited)
    {
		int i = 0;
		int vad = 0;
        int times = 2;
        int frameSize = sample_size / 2;
		for (; i < times; i++)
        {
            short *value = samples + i * frameSize;
            if (value != NULL)
            {
                vad += speex_preprocess_run(dsp_st,value);
            }
        }
//		printf( " preprocess run sample_size=%d, times=%d, vad=%d",
//				sample_size, times, vad);
	}
}


/** SPEEX 初始化: 默认frame_size= 320,sampling_rate = 16k.<br>
 * speex_preprocess_state_init的frame_size必须与speex_preprocess_run处理的buffer大小保持一致
 */
int goscam_dsp_start2(int mFramesPerPacket,int sample_rate)
{
//    if (dsp_inited) {
//        // printf( "goscam_dsp_start2 already inited, frame_size=%d, sample_rate=%d", frame_size,
//        // 				sample_rate);
//        return dsp_inited;
//    }
    // printf( "goscam_dsp_start2, frame_size=%d, sample_rate=%d", frame_size,
    // 						sample_rate);
    
    dsp_frame_size = mFramesPerPacket;
    
    // 进行SPEEX初始化
    if (dsp_st == NULL) {
            dsp_st = speex_preprocess_state_init(dsp_frame_size, sample_rate);
    }
    // printf(" INIT: frame_size=%d, sampling_rate=%d", frame_size, sample_rate);
    // 实际初始化结果
    dsp_inited = dsp_st == NULL ? 0 : 1;
    if (dsp_save_files)
    {
        // 如果需要保存处理前后的PCM数据, 这里打开文件
        dsp_preprocess = fopen(g_preFileName, "w");
        dsp_postprocess = fopen(g_postFileName, "w");
        // printf(" open file: %s, %s", DSP_AUDIO_PRE_PROCESS, DSP_AUDIO_POST_PROCESS);
    }
    
    // printf(" INIT ret=%d", dsp_inited);
//    dsp_ctrl = (DspCtrl*)malloc(sizeof(DspCtrl));
//    if(dsp_inited)
//        get_dsp_flags(dsp_st, dsp_ctrl);
   // print_dsp_flags(dsp_ctrl);
    return dsp_inited;
}

int goscam_dsp_start(int sample_rate,char *preFileName,char *postFileName) {
	// printf( "goscam_dsp_start, sample_rate=%d",
	// 				sample_rate);
    nFramesPacketState = 0;
    g_preFileName = preFileName;
    g_postFileName = postFileName;
    dsp_sample_rate = sample_rate;
	return 0;
}

int goscam_dsp_nFramesPacket(int mFramesPerPacket)
{
    int value = 0;
    if (g_preFileName != NULL && g_preFileName != NULL) {
        if ( mFramesPerPacket != dsp_frame_size) {
            if (mFramesPerPacket != dsp_frame_size-1) {
                dsp_frame_size = mFramesPerPacket;
                value  = goscam_dsp_start2(mFramesPerPacket,dsp_sample_rate);
            }
        }
    }
    return value;
}

int goscam_dsp_handle(short* samples, int samples_size, int sample_rate) {
//	printf(" goscam_dsp_handle samples_size=%d", samples_size);
	if(dsp_enabled) {
		if (!dsp_inited) {
			goscam_dsp_start(dsp_sample_rate,g_preFileName,g_postFileName);
		}
		// 将AAC解码得到PCM保存到文件
		dsp_save_preporcess_samples(samples, samples_size);
		//
		goscam_dsp_process(samples, samples_size);
		// 将SPEEX处理后的PCM数据保存到文件
		dsp_save_postprocess_samples(samples, samples_size);
	}
    return 0;
}

/**
 * 释放Speex
 */
void goscam_dsp_stop()
{
	if (dsp_inited) {
		// release something...
	}
	if (dsp_save_files) {
		fclose(dsp_preprocess);
		fclose(dsp_postprocess);
	}
    
	if (dsp_st != NULL)
    {
		// printf( "dsp_st destroy!");
		speex_preprocess_state_destroy(dsp_st);
        dsp_st = NULL;
	}
    dsp_frame_size = 0;
	dsp_inited = 0;
	//	dsp_enabled = 0;
}

//void goscam_dsp_set_int(int type, int value) {
//    dsp_st->loudness = 1e-15;
//    dsp_st->agc_gain = 10;//1, 10
//    dsp_st->max_gain = 100;//30, 60
//    dsp_st->max_increase_step = exp(0.11513f * 12.*st->frame_size / st->sampling_rate);//12
//    dsp_st->max_decrease_step = exp(-0.11513f * 40.*st->frame_size / st->sampling_rate);
//    dsp_st->prev_loudness = 1;
//    dsp_st->init_max = 10;//1, 10
//}
//
//void print_dsp_flags(DspCtrl * ctrl) {
//    printf("print_dsp_flags: BEGIN===================================");
//    printf("dsp_enabled=%d", dsp_enabled);
//    printf("dsp_inited=%d", dsp_inited);
//    printf("dsp_save_files=%d", dsp_save_files);
//    printf("print_dsp_flags: denoise=%d", ctrl->denoise);
//    printf("print_dsp_flags: vad=%d", ctrl->vad);
//    printf("print_dsp_flags: agc=%d", ctrl->agc);
//    printf("print_dsp_flags: agcLevel=%f", ctrl->agcLevel);
//    printf("print_dsp_flags: agcIncrement=%d", ctrl->agcIncrement);
//    printf("print_dsp_flags: agcDecrement=%d", ctrl->agcDecrement);
//    printf("print_dsp_flags: agcMaxGain=%d", ctrl->agcMaxGain);
//    printf("print_dsp_flags: agcLoudness=%d", ctrl->agcLoudness);
//    printf("print_dsp_flags: agcGain=%d", ctrl->agcGain);
//    printf("print_dsp_flags: agcTarget=%d", ctrl->agcTarget);
//    printf("print_dsp_flags: dereverb=%d", ctrl->dereverb);
//    printf("print_dsp_flags: dereverbLevel=%f", ctrl->dereverbLevel);
//    printf("print_dsp_flags: dereverbDecay=%f", ctrl->dereverbDecay);
//    printf("print_dsp_flags: prob=%d", ctrl->prob);
//    printf("print_dsp_flags: probStart=%d", ctrl->probStart);
//    printf("print_dsp_flags: probContinue=%d", ctrl->probContinue);
//    printf("print_dsp_flags: echoSuppress=%d", ctrl->echoSuppress);
//    printf("print_dsp_flags: echoSuppressActive=%d", ctrl->echoSuppressActive);
//    printf("print_dsp_flags: noiseSuppress=%d", ctrl->noiseSuppress);
//    printf("print_dsp_flags: psdSize=%d", ctrl->psdSize);
//    printf("print_dsp_flags: noisePsdSize=%d", ctrl->noisePsdSize);
//    printf("print_dsp_flags: END=====================================");
//}
//
//void set_dsp_flags(SpeexPreprocessState * st, DspCtrl* ctrl) {
//    if(st == NULL || ctrl == NULL) {
//        printf("get_dsp_flags faild !!!");
//        return;
//    }
//    (st, SPEEX_PREPROCESS_SET_DENOISE, &ctrl->denoise);
//    (st, SPEEX_PREPROCESS_SET_AGC, &ctrl->agc);
//    (st, SPEEX_PREPROCESS_SET_VAD, &ctrl->vad);
//    (st, SPEEX_PREPROCESS_SET_AGC_LEVEL, &ctrl->agcLevel);
//    (st, SPEEX_PREPROCESS_SET_DEREVERB, &ctrl->dereverb);
//    (st, SPEEX_PREPROCESS_SET_DEREVERB_LEVEL, &ctrl->dereverbLevel);
//    (st, SPEEX_PREPROCESS_SET_DEREVERB_DECAY, &ctrl->dereverbDecay);
//    (st, SPEEX_PREPROCESS_SET_PROB_START, &ctrl->probStart);
//    (st, SPEEX_PREPROCESS_SET_PROB_CONTINUE, &ctrl->probContinue);
//    (st, SPEEX_PREPROCESS_SET_NOISE_SUPPRESS, &ctrl->noiseSuppress);
//    (st, SPEEX_PREPROCESS_SET_ECHO_SUPPRESS, &ctrl->echoSuppress);
//    (st, SPEEX_PREPROCESS_SET_ECHO_SUPPRESS_ACTIVE, &ctrl->echoSuppressActive);
//    /**echo state*/
//    //	(st, SPEEX_PREPROCESS_SET_ECHO_STATE, &(SpeexEchoState*));
//    (st, SPEEX_PREPROCESS_SET_AGC_INCREMENT, &ctrl->agcIncrement);
//    (st, SPEEX_PREPROCESS_SET_AGC_DECREMENT, &ctrl->agcDecrement);
//    (st, SPEEX_PREPROCESS_SET_AGC_MAX_GAIN, &ctrl->agcMaxGain);
//    //	(st, SPEEX_PREPROCESS_GET_AGC_LOUDNESS, &ctrl->agcLoudness);//!!!SET.
//    //	(st, SPEEX_PREPROCESS_GET_AGC_GAIN, &ctrl->agcGain);//!!!SET.
//    //	(st, SPEEX_PREPROCESS_GET_PSD_SIZE, &ctrl->psdSize);//!!!SET.
//    //	if(ctrl->psd) {
//    //		free(ctrl->psd);
//    //		ctrl->psd = NULL;
//    //	}
//    //	ctrl->psd = (int*)malloc(sizeof(int) * ctrl->psdSize);
//    //	(st, SPEEX_PREPROCESS_GET_PSD, &ctrl->psd);//!!!SET.
//    //	(st, SPEEX_PREPROCESS_GET_NOISE_PSD_SIZE, &ctrl->noisePsdSize);//!!!SET.
//    //	if(ctrl->noisePsd) {
//    //		free(ctrl->noisePsd);
//    //		ctrl->noisePsd = NULL;
//    //	}
//    //	ctrl->noisePsd = (int*)malloc(sizeof(int) * ctrl->noisePsdSize);
//    //	(st, SPEEX_PREPROCESS_GET_NOISE_PSD, &ctrl->noisePsd);//!!!SET.
//    //	(st, SPEEX_PREPROCESS_GET_PROB, &ctrl->prob);//!!!SET.
//    
//    printf("set_dsp_flags done");
//   // print_dsp_flags(ctrl);
//}

//void get_dsp_flags(SpeexPreprocessState * st, DspCtrl* ctrl) {
//    if(st == NULL || ctrl == NULL) {
//        printf("get_dsp_flags faild !!!");
//        return;
//    }
//    
//    (st, SPEEX_PREPROCESS_GET_DENOISE, &ctrl->denoise);
//    (st, SPEEX_PREPROCESS_GET_AGC, &ctrl->agc);
//    (st, SPEEX_PREPROCESS_GET_VAD, &ctrl->vad);
//    (st, SPEEX_PREPROCESS_GET_AGC_LEVEL, &ctrl->agcLevel);
//    (st, SPEEX_PREPROCESS_GET_DEREVERB, &ctrl->dereverb);
//    (st, SPEEX_PREPROCESS_GET_DEREVERB_LEVEL, &ctrl->dereverbLevel);
//    (st, SPEEX_PREPROCESS_GET_DEREVERB_DECAY, &ctrl->dereverbDecay);
//    (st, SPEEX_PREPROCESS_GET_PROB_START, &ctrl->probStart);
//    (st, SPEEX_PREPROCESS_GET_PROB_CONTINUE, &ctrl->probContinue);
//    (st, SPEEX_PREPROCESS_GET_NOISE_SUPPRESS, &ctrl->noiseSuppress);
//    (st, SPEEX_PREPROCESS_GET_ECHO_SUPPRESS, &ctrl->echoSuppress);
//    (st, SPEEX_PREPROCESS_GET_ECHO_SUPPRESS_ACTIVE, &ctrl->echoSuppressActive);
//    /**echo state*/
//    //	(st, SPEEX_PREPROCESS_GET_ECHO_STATE, SpeexEchoState*);
//    (st, SPEEX_PREPROCESS_GET_AGC_INCREMENT, &ctrl->agcIncrement);
//    (st, SPEEX_PREPROCESS_GET_AGC_DECREMENT, &ctrl->agcDecrement);
//    (st, SPEEX_PREPROCESS_GET_AGC_MAX_GAIN, &ctrl->agcMaxGain);
//    (st, SPEEX_PREPROCESS_GET_AGC_LOUDNESS, &ctrl->agcLoudness);//!!!SET.
//    (st, SPEEX_PREPROCESS_GET_AGC_GAIN, &ctrl->agcGain);//!!!SET.
//    (st, SPEEX_PREPROCESS_GET_PSD_SIZE, &ctrl->psdSize);//!!!SET.
//    //	if(ctrl->psd) {
//    //		free(ctrl->psd);
//    //		ctrl->psd = NULL;
//    //	}
//    //	ctrl->psd = (int*)malloc(sizeof(int) * ctrl->psdSize);
//    //	(st, SPEEX_PREPROCESS_GET_PSD, &ctrl->psd);//!!!SET.
//    (st, SPEEX_PREPROCESS_GET_NOISE_PSD_SIZE, &ctrl->noisePsdSize);//!!!SET.
//    //	if(ctrl->noisePsd) {
//    //		free(ctrl->noisePsd);
//    //		ctrl->noisePsd = NULL;
//    //	}
//    //	ctrl->noisePsd = (int*)malloc(sizeof(int) * ctrl->noisePsdSize);
//    //	(st, SPEEX_PREPROCESS_GET_NOISE_PSD, &ctrl->noisePsd);//!!!SET.
//    (st, SPEEX_PREPROCESS_GET_PROB, &ctrl->prob);//!!!SET.
//    
//    printf("get_dsp_flags done");
//   // print_dsp_flags(ctrl);
//}

//DspCtrl * getDspCtrl(){
//    return dsp_ctrl;
//}
//void processDspCtrl(){
//    set_dsp_flags(dsp_st, dsp_ctrl);
//}
