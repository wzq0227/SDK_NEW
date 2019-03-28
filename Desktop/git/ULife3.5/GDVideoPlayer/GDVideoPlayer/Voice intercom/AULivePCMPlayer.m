//
//  AULivePCMPlayer.m
//  用AudioUnit播放实时PCM
//
//  Created by Goscam on 2017/11/25.
//  Copyright © 2017年 goscamtest. All rights reserved.
//

#import "AULivePCMPlayer.h"
#import <AVFoundation/AVFoundation.h>


#define QUEUE_BUFFER_SIZE 4   //队列缓冲个数
#define AUDIO_BUFFER_SIZE 640 //数据区大小
#define MAX_BUFFER_SIZE 8000 //

@interface AULivePCMPlayer(){
    
    
    NSCondition *mAudioLock;
    AudioQueueRef mAudioPlayer;
    AudioQueueBufferRef mAudioBufferRef[QUEUE_BUFFER_SIZE];
    void *mPCMData;
    int mDataLen;
}

@property (assign, nonatomic)  float sampleRate;
@end


@implementation AULivePCMPlayer

-(BOOL)start{
    
    mPCMData = malloc(MAX_BUFFER_SIZE);
    mAudioLock = [[NSCondition alloc]init];
    int rate=8000;
    int bit=16;
    int channel=1;
    AudioStreamBasicDescription streamFormat;
    streamFormat = (AudioStreamBasicDescription) {
        .mSampleRate = rate,
        .mFormatID = kAudioFormatLinearPCM,
        .mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
        .mFramesPerPacket = 1,
        .mBitsPerChannel = bit,
        .mChannelsPerFrame = channel,
        .mBytesPerFrame = bit/8*channel,
        .mBytesPerPacket = bit/8*channel,
    };
    
    AudioQueueNewOutput(&streamFormat, sAudioQueueOutputCallback, (__bridge void *)(self), nil, nil, 0, &mAudioPlayer);
    
    for(int i=0;i<QUEUE_BUFFER_SIZE;i++)
    {
        
        AudioQueueAllocateBuffer(mAudioPlayer, AUDIO_BUFFER_SIZE, &mAudioBufferRef[i]);
        memset(mAudioBufferRef[i]->mAudioData, 0, AUDIO_BUFFER_SIZE);
        mAudioBufferRef[i]->mAudioDataByteSize = AUDIO_BUFFER_SIZE;
        AudioQueueEnqueueBuffer(mAudioPlayer, mAudioBufferRef[i], 0, NULL);
    }
    
    AudioQueueSetParameter(mAudioPlayer, kAudioQueueParam_Volume, 1.0);
    AudioQueueStart(mAudioPlayer, NULL);
    return YES;
}

-(void)play:(NSData *)data{
    [mAudioLock lock];
    int len = (int)[data length];
    if (len > 0 && len + mDataLen < MAX_BUFFER_SIZE && mPCMData) {
        memcpy(mPCMData+mDataLen, [data bytes],[data length]);
        mDataLen += [data length];
    }
    [mAudioLock unlock];
}


-(void)stop{
    
    if (mAudioPlayer!=nil) {
        AudioQueueStop(mAudioPlayer, YES);
        AudioQueueReset(mAudioPlayer);
    }
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        AudioQueueFreeBuffer(mAudioPlayer, mAudioBufferRef[i]);
    }
    
    if (mPCMData) {
        free(mPCMData);
    }
    mPCMData = nil;
    mAudioPlayer = nil;
    mAudioLock = nil;
    
}

-(void)handlerOutputAudioQueue:(AudioQueueRef)inAQ inBuffer:(AudioQueueBufferRef)inBuffer
{
    BOOL isFull = NO;
    if( mDataLen >=  AUDIO_BUFFER_SIZE && mPCMData)
    {
        [mAudioLock lock];
        memcpy(inBuffer->mAudioData, mPCMData, AUDIO_BUFFER_SIZE);
        mDataLen -= AUDIO_BUFFER_SIZE;
        memmove(mPCMData, mPCMData+AUDIO_BUFFER_SIZE, mDataLen);
        [mAudioLock unlock];
        isFull = YES;
    }
    
    if (!isFull) {
        memset(inBuffer->mAudioData, 0, AUDIO_BUFFER_SIZE);
    }
    
    inBuffer->mAudioDataByteSize = AUDIO_BUFFER_SIZE;
    AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    
}


static void sAudioQueueOutputCallback (
                                       void *                  inUserData,
                                       AudioQueueRef           inAQ,
                                       AudioQueueBufferRef     inBuffer) {
    
    
    AULivePCMPlayer *player = (__bridge AULivePCMPlayer *)(inUserData);
    [player handlerOutputAudioQueue:inAQ inBuffer:inBuffer];
    
}

- (id)init{
    self = [super init];
    return self;
}

-(void)addNewData:(NSData*)buf len:(int)len
{
    [self play:buf];
}



- (void)startPlayPCM{
    [self start];
}



- (void)stopPlayPCM{
    [self stop];
}

@end
