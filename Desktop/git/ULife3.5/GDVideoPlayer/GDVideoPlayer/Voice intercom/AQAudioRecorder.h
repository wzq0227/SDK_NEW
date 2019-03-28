//
//  AQAudioRecorder.h
//  GDVideoPlayer
//
//  Created by Goscam on 2017/10/26.
//  Copyright © 2017年 goscamtest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef void(^AQAudioCallback)(NSData *pcmData);
typedef void(^RecordingResult)(int result);

@interface AQAudioRecorder : NSObject

-(void)processAudioBuffer:(AudioQueueBufferRef)audioBuffer withQueue:(AudioQueueRef)audioQueue;

-(void)startRecordingWithAudioCallback:(AQAudioCallback)callback;

-(void)stopRecordingWithResult:(RecordingResult)result;
@end
