//
//  GDVideoStateInfo.m
//  GDVideoPlayer
//
//  Created by goscam on 16/3/2.
//  Copyright © 2016年 goscamtest. All rights reserved.
//

#import "GDVideoStateInfo.h"

NSString *VoiceSendDataNotification = @"VoiceSendDataNotification";
NSString *VoiceSendDataStatus = @"VoiceSendDataStatus";
NSString *VoiceSendDataFilePath = @"VoiceSendDataFilePath";

NSString *VolumeNotification = @"VolumeNotification";
NSString *GDPlayerInfoKeyFrameWidth =  @"height";   // 视频播放 view 的宽
NSString *GDPlayerInfoKeyFrameHeight =  @"width";   // 视频播放 view 的高
NSString *GDPlayerNotification = @"GDPlayerNotification";      // 通知视频播放 view 的大小
NSString *GDPlayerSizeNotifcation = @"GDPlayerSizeNotification";
NSString *AudioFile = @"audio.aac";
NSString *AudioFilePCM = @"audio.pcm";
NSString *DspFilePCM = @"dsp.pcm";
NSString *talkFile = @"interfacetalk_tmp.aac";
NSString *talkFileG711 = @"interfacetalk_tmp.711";
NSString *talkFilePCM = @"interfacetalk.caf";

NSString *VideoFile =@"output.mp4";
NSString *g_postFileName = @"audio_speex_processed.pcm";
NSString *g_preFileName = @"audio_aac_decoded.pcm";

float g_volce= 50.0f;
float EPSINON = 0.00001;
