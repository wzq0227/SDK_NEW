//
//  GOSAudioRecorder.m
//  ULife3.5
//
//  Created by Goscam on 2017/8/15.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "GOSAudioRecorder.h"
#import <AVFoundation/AVFoundation.h>

@interface GOSAudioRecorder ()<AVAudioRecorderDelegate>

@property (strong, nonatomic)  NSString *talkFileName;

@property (strong, nonatomic)  NSString *talkFilePath;

@property (strong, nonatomic)  AVAudioRecorder  *audioRecorder;

@property (strong, nonatomic)  NSMutableDictionary *recordSetting;

@property (assign, nonatomic)  BOOL isSuccess;

@property (assign, nonatomic)  BOOL isRecording;

@property (strong, nonatomic)  NSTimer* meterUpdateTimer;

@property (strong, nonatomic)  OperationResult startRecordingBlock;

@property (strong, nonatomic)  OperationResult stopRecordingBlock;

@end

@implementation GOSAudioRecorder

-(id)init{
    self = [super init];
    if (self){
        _isSuccess = NO;
        _isRecording = NO;
    }
    return self;
}

-(NSString*)talkFileName{
    if (!_talkFileName) {
        _talkFileName = @"intercomTalk_tmp.aac";
    }
    return _talkFileName;
}

-(NSString*)talkFilePath{
    if (!_talkFilePath) {
        _talkFilePath = [mDocumentPath stringByAppendingPathComponent:self.talkFileName];
    }
    return _talkFilePath;
}

- (AVAudioRecorder*)audioRecorder{
    if (!_audioRecorder) {
        NSURL *url = [NSURL URLWithString: self.talkFilePath];
        NSError *error;
        _audioRecorder = [[AVAudioRecorder alloc] initWithURL: url settings:self.recordSetting error:&error];
        if (error) {
            NSLog(@"AVAudioRecorder alloc______________error");
        }
    }
    return _audioRecorder;
}

-(BOOL)enableAudioSession
{
    NSError* err = nil;
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];
    if(err)
    {
        NSLog(@"audioSession: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        return NO;
    }
    return [audioSession setActive:YES error:&err];
}

- (NSMutableDictionary*)recordSetting{
    
    if (!_recordSetting) {
        _recordSetting = [NSMutableDictionary dictionary];
        [_recordSetting setValue :[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
        [_recordSetting setValue:[NSNumber numberWithFloat:16000.0] forKey:AVSampleRateKey];
        [_recordSetting setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
        [_recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    }
    return _recordSetting;
}


- (void)gos_startAudioRecorderResultCallback:(OperationResult)result{
    if ([mFileManager fileExistsAtPath: self.talkFilePath]) {
        [mFileManager removeItemAtPath: self.talkFilePath error:nil];
    }
    _isRecording = YES;
    
    [self enableAudioSession];
    
    BOOL opRet = NO;
    if (self.audioRecorder) {
        _audioRecorder.delegate = self;
    
        //开始录音
        if(![_audioRecorder prepareToRecord]){
            NSLog(@"prepareToRecord failed");
        }
        else{
            if (!_meterUpdateTimer) {
                _meterUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(updateRecorderMeter) userInfo:nil repeats:YES];
                _audioRecorder.meteringEnabled = YES;
                opRet = [_audioRecorder record];
            }
        }
    }
    result(opRet?0:-1,nil);
}

-(void)updateRecorderMeter
{
    if (_audioRecorder)
    {
        [_audioRecorder updateMeters];
    }
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    _isSuccess = flag;
    NSLog(@"audioRecorderDidFinishRecording_ret:%d",flag);
    if (_stopRecordingBlock) {
        _stopRecordingBlock(flag?0:-1, self.talkFilePath);
    }
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    _isSuccess = NO;
    NSLog(@"audioRecorderEncodeErrorDidOccur:%@",error.description);

    if (_stopRecordingBlock) {
        _stopRecordingBlock(!error?0:-1, self.talkFilePath);
    }
}


-(void)gos_stopAudioRecorderResultCallback:(OperationResult)result{
    
    _stopRecordingBlock = result;
    if (_isRecording){
        if ([_audioRecorder isRecording]){
            usleep(100);
            [_audioRecorder stop];
            AVAudioSession *audioSession = [AVAudioSession sharedInstance];
//            [audioSession setActive:NO error:nil];
        }
        
        if (_meterUpdateTimer && [_meterUpdateTimer isValid]){
            [_meterUpdateTimer invalidate];
            _meterUpdateTimer = nil;
        }
        _isRecording = NO;
        NSLog(@"recordStop");
    }
}

@end
