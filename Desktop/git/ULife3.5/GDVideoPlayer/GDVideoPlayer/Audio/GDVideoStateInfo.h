//
//  GDVideoStateInfo.h
//  GDVideoPlayer
//
//  Created by goscam on 16/3/2.
//  Copyright © 2016年 goscamtest. All rights reserved.
//

#import <Foundation/Foundation.h>

extern float t ;
extern int16_t *samples;

extern float g_volce ;
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#define INBUF_SIZE 102400 //max one encoded framesize in bytes
#define INBUF_CNT 3 //max frame list count

#define RGB_BUFFER_SIZE (1280*720*4)

extern float EPSINON;

extern NSString *VoiceSendDataNotification;
extern NSString *VoiceSendDataStatus;
extern NSString *VoiceSendDataFilePath;

extern NSString *VolumeNotification;
extern NSString *GDPlayerInfoKeyFrameWidth;
extern NSString *GDPlayerInfoKeyFrameHeight;
extern NSString *GDPlayerNotification;
extern NSString *GDPlayerSizeNotifcation;

extern NSString *DspFilePCM;
extern NSString *AudioFile;
extern NSString *talkFile;
extern NSString *talkFileG711;
extern NSString *talkFilePCM;

extern NSString *VideoFile;
extern NSString *AudioFilePCM;
extern NSString *g_postFileName;
extern NSString *g_preFileName;





