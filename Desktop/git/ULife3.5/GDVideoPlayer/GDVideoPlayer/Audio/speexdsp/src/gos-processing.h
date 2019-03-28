//
//  gos-processing.h
//  GDVideoPlayer
//
//  Created by goscam on 16/4/8.
//  Copyright © 2016年 goscamtest. All rights reserved.
//

#ifndef gos_processing_h
#define gos_processing_h
#import "speex_preprocess.h"

int goscam_dsp_start(int sample_rate,char *preFileName,char *postFileName);
int goscam_dsp_nFramesPacket(int nFramesPacket);
int goscam_dsp_handle(short* samples, int samples_size, int sample_rate);
void goscam_dsp_stop();
#endif /* gos_processing_h */
