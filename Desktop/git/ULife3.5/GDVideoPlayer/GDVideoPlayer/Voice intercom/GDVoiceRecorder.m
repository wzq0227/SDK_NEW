//
//  GDVoiceRecorder.m
//  GDVideoPlayer
//
//  Created by admin on 15/9/7.
//  Copyright (c) 2015年 goscamtest. All rights reserved.
//

#import "GDVoiceRecorder.h"
#import "RmRecorder.h"
#import "GDVideoStateInfo.h"
//#import "GDVideoPlayer.h"

@interface GDVoiceRecorder()
{
    RmRecorder * _recorder;
}
@property(nonatomic,copy)NSString *recoderPath;
@end

@implementation GDVoiceRecorder
-(id)init
{
    if(self = [super init])
    {
        self.recoderPath = [NSTemporaryDirectory() stringByAppendingPathComponent:talkFile];
        _encodedToAACDirectly = YES;
        _recorder = [[RmRecorder alloc] init];
        _recorder.delegate = self;
        self.isCmdSuceess = NO;
        [self addObserver:self forKeyPath:@"isCmdSuceess" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

-(void)dealloc
{
    [self removeObserver:self forKeyPath:@"isCmdSuceess"];

    NSLog(@"_________GDVoiceRecorder_______ dealloc ");
}

-(void)recordStartDecoding
{
    _recoderPath = [NSTemporaryDirectory() stringByAppendingPathComponent:_encodedToAACDirectly?talkFile:talkFilePCM];
    if ([[NSFileManager defaultManager] fileExistsAtPath:_recoderPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:_recoderPath error:nil];
    }
    
    NSError* err = nil;
    if ([_recorder isRecording])
    {
        return;
    }
    [_recorder setEncodedToAACDirectly:_encodedToAACDirectly];
    if(![_recorder recordStartAtPath:self.recoderPath overwriteIfNeeded:YES error:&err BlockSuccess:^(BOOL flag)
    {
        if (flag)
        {
            NSLog(@"解码成功");
        }
        else
        {
            NSLog(@"解码错误");
        }
        NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
        
        [dict setObject: [[NSNumber alloc]initWithBool:flag]
                 forKey:VoiceSendDataStatus];
        [dict setObject:self.recoderPath
                 forKey:VoiceSendDataFilePath];
        
        // 通知对讲语音
        [[NSNotificationCenter defaultCenter] postNotificationName:VoiceSendDataNotification
                                                            object:self
                                                          userInfo:dict];
    }])
    {
        NSLog(@"err: %@", err);
    }
}

-(void)StartRecoder
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self recordStartDecoding];
    });
//    [self performSelector:@selector(recordStartDecoding) withObject:nil afterDelay:0];
}

-(void)StopRecoder
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(recordStartDecoding) object:nil];
    [_recorder recordStop];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"isCmdSuceess"]) {
        NSLog(@"isCmdSuceess = %@", [change valueForKey:NSKeyValueChangeNewKey]);
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
@end
