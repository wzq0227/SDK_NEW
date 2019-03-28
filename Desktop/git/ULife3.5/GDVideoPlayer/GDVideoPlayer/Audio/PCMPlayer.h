//
//  PCMPlayer.h
//  GDVideoPlayer
//
//  Created by zhuochuncai on 12/1/17.
//  Copyright © 2017年 goscamtest. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <OpenAL/al.h>
#import <OpenAL/alc.h>

@interface PCMPlayer : UIViewController
{
    ALCcontext *m_Context;      //context for audio player
    ALCdevice  *m_Device;
    ALuint      m_sourceID;
    
    NSCondition *m_DecodeLock;
}

- (BOOL)initOpenAL;

- (void)playSound;

- (void)stopSound;

- (void)openAudioWithBuffer:(unsigned char *)pBuffer length:(int)pLength;

- (void)clearOpenAL;


@end
