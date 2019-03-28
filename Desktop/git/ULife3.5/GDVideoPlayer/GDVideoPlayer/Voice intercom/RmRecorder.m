//
//  RmRecorder.m
//  RingtonesManager
//
//  Created by yuanx on 14-2-14.
//  Copyright (c) 2014年 yuanx. All rights reserved.
//

#import "RmRecorder.h"
#import <UIKit/UIKit.h>

@interface RmRecorder()
{
    NSString* _recordPath;
    AVAudioRecorder* _audioRecorder;
    NSTimer* _meterUpdateTimer;
}
@end

@implementation RmRecorder
@synthesize isRecording = _isRecording;

-(id)init
{
    if (self = [super init])
    {
        _isSuccess = NO;
        _isRecording = NO;
        _encodedToAACDirectly = YES;
    }
    return self;
}


-(void)setProximityMonitorListenerEnabled:(BOOL)enabled
{
    if (enabled)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sensorStateChange:)
                                                     name:@"UIDeviceProximityStateDidChangeNotification"
                                                   object:nil];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

-(void)setProximityMonitorEnabled:(BOOL)enabled;
{
    [[UIDevice currentDevice] setProximityMonitoringEnabled:enabled];
}

-(void)sensorStateChange:(NSNotificationCenter *)notification;
{
    //如果此时手机靠近面部放在耳朵旁，那么声音将通过听筒输出，并将屏幕变暗（省电啊）
    if ([[UIDevice currentDevice] proximityState] == YES)
    {
        NSLog(@"Device is close to user");
    }
    else
    {
        NSLog(@"Device is not close to user");
    }
}

#pragma mark -
-(BOOL)enableAudioSession
{
    NSError* err = nil;
//    [self setProximityMonitorListenerEnabled:YES];
//    [self setProximityMonitorEnabled:YES];
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];
    if(err)
    {
        NSLog(@"audioSession: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        return NO;
    }
    return [audioSession setActive:YES error:&err];
}

-(BOOL)recordStartAtPath:(NSString*)path overwriteIfNeeded:(BOOL)overwrite error:(NSError**)error BlockSuccess:(BlockSuccess)blockSucess
{
    _blockSuccess = blockSucess;
    if (_isRecording)
    {
        *error = [[NSError alloc] initWithDomain:@"busy." code:-1 userInfo:nil];
        return NO;
    }
    
    //路径是否合法
    if (path == nil)
    {
        *error = [[NSError alloc] initWithDomain:@"Path can't be nil." code:-2 userInfo:nil];
        return NO;
    }
    
    //该路径的文件是否已存在
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]){
        if (overwrite){
            //若存在, 删除是否成功
            NSError* err;
            if (![fileManager removeItemAtPath:path error:&err]){
                *error = [[NSError alloc] initWithDomain:err.domain code:err.code userInfo:nil];
                return NO;
            }
        }
        else
        {
            *error = [[NSError alloc] initWithDomain:@"File already exsits." code:-3 userInfo:nil];
            return NO;
        }
    }
    
    //创建文件
    if (![fileManager createFileAtPath:path contents:nil attributes:nil])
    {
        *error = [[NSError alloc] initWithDomain:@"Create a file error." code:-4 userInfo:nil];
        return NO;
    }
    _recordPath = path;
    
    //录音开始
    [self startRecord];
    *error = nil;
    return YES;
}

-(NSError*)startRecord
{
    _isRecording = YES;
    NSError* error = nil;
    
    [self enableAudioSession];
    NSMutableDictionary * recordSetting = [NSMutableDictionary dictionary];

    if (!_encodedToAACDirectly) {
        [recordSetting setValue:[NSNumber numberWithInt: kAudioFormatLinearPCM] forKey:AVFormatIDKey];
        [recordSetting setValue:[NSNumber numberWithFloat: 8000.0] forKey:AVSampleRateKey]; //8000 44100.0

//        [recordSetting setObject:[NSNumber numberWithFloat: 16] forKey:AVLinearPCMBitDepthKey];
        [recordSetting setValue:[NSNumber numberWithFloat: 1] forKey:AVNumberOfChannelsKey];
        [recordSetting setValue:[NSNumber numberWithFloat: AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
    }else{
        [recordSetting setValue :[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
        
        [recordSetting setValue:[NSNumber numberWithFloat: 16000.0] forKey:AVSampleRateKey];
        [recordSetting setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
        [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    }

    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:_recordPath] settings:recordSetting error:&error];
    _audioRecorder.meteringEnabled = YES;
    _audioRecorder.delegate = self;
    NSLog(@"error: %@", error);
    if (error){
        NSError *specificErr = [NSError errorWithDomain:NSOSStatusErrorDomain
                                             code:error.code
                                         userInfo:nil];
        NSLog(@"specificErr: %@", [specificErr description]);
        return error;
    }
    
    //开始录音
    if (_audioRecorder){
        if(![_audioRecorder prepareToRecord]){
            NSLog(@"prepareToRecord failed");
        }
        else{
            _meterUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateRecorderMeter) userInfo:nil repeats:YES];
            [_audioRecorder record];
        }
    }
    return nil;
}

-(void)recordStop
{
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

-(void)updateRecorderMeter
{
    if (_audioRecorder)
    {
        [_audioRecorder updateMeters];
    }
    float peakPower = [_audioRecorder averagePowerForChannel:0];
    double ALPHA = 0.02;
    double peakPowerForChannel = pow(10, (ALPHA * peakPower));
    
//    if (_eq.superview)
//    {
//        [_eq showVoice:peakPowerForChannel];
//    }
//    NSLog(@" _audioRecorder.currentTime:\t%f", _audioRecorder.currentTime);
//    if ([_delegate respondsToSelector:@selector(onRmRecorderDelegate:curTime:)])
//    {
//        [_delegate onRmRecorderDelegate:self curTime:_audioRecorder.currentTime];
//    }
}

//MARK: - AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    _isSuccess = flag;
    NSLog(@"audioRecorderDidFinishRecording");
    _blockSuccess(_isSuccess);
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    _isSuccess = NO;
    _blockSuccess(_isSuccess);
}
@end
