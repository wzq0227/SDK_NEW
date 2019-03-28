//
//  GDVideoPlayer.m
//  GDVideoPlayer
//
//  Created by admin on 15/9/1.
//  Copyright (c) 2015年 goscamtest. All rights reserved.

#include <stdlib.h>

#import "GDVideoPlayer.h"
#import "GDPlayerView.h"

#import "GDVideoDecoder.h"
#import "GDCapture.h"

#import "GDAudioDecoder.h"
#include "GDVoiceRecorder.h"
#import "GDVideoStateInfo.h"
#import "KKSimpleAUPlayer.h"
#import "parser.h"
#import "AQAudioRecorder.h"
#import <../../../ULife3.5/NetPro/NetProSDK/common/GosFrameHeadDef.h>

#define VIDEO @"video.H264"


@interface GDVideoPlayer() <GDVideoDecoderDelegate,GDVoiceDelegate>
{
    
    GDCapture* _capture;            // 录制视频
    GDAudioDecoder* _audioDecoder;
    GDVoiceRecorder *_voiceRecorder;
    
//    CParser *_parser;
    CGSize _videoImageSize;
    BOOL _waitForKeyFrame;
    
    BOOL  _iFrame;
    int _lastTimeStamp;
    int _framNO;
    int _frameRate;
    
    int _audioFrameNO;
    bool _isAutoRunning;
    unsigned int _reserve;
    BOOL  _isVoceRecorderStatus;
    BOOL _isRecording;
    int  _StreamValue;
    
    NSString *recoderPath;
    NSString *videoPath;
    NSString *_deviceID;
}

@property (assign, nonatomic)  int audioFrameType;

@property(nonatomic,assign)BOOL isDoubleScale;
@property(nonatomic,strong)GDPlayerView* playerView;
//@property(nonatomic,strong)GDVideoDecoder *decoder;
@property(nonatomic,strong)BlockResultError blockResult;
@property(nonatomic,strong)RecordResultBlock recordBlock;

@property(nonatomic,strong) AQAudioRecorder *aqAudioRecorder;
@property (strong, nonatomic)  NSFileHandle *g711FileHandle;
@property (strong, nonatomic)  NSString *g711TalkFilePath;
@end

@implementation GDVideoPlayer

+(GDVideoPlayer*)sharedInstance
{
    static GDVideoPlayer *_sharedMyClass = nil;
    static dispatch_once_t token;
    if(_sharedMyClass == nil)
    {
        dispatch_once(&token,^{
            _sharedMyClass = [[GDVideoPlayer alloc] init];}
                      );
    }
    return _sharedMyClass;
}

-(id)init
{
    if (self = [super init])
    {
        _blockResult = nil;
        _waitForKeyFrame = YES;
        _lastTimeStamp = 0;
        _framNO = 0;
        _audioFrameType = -1;
        _audioFrameNO = 0;
        _frameRate = 0;
        _reserve = 0;
        _isRecording = NO;
        _isAutoRunning = 0;
        _StreamValue = -1;
        _isVoceRecorderStatus = NO;
        _capture = nil;
        _playerView = nil;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(GetVoiceSendDataNotification:)
                                                     name:VoiceSendDataNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(gotPlayerNotification:)
                                                     name:GDPlayerNotification
                                                   object:nil];
        //[self addHardKeyVolumeListener];
    }
    return self;
}


#pragma mark -- 获取文件大小
- (long long) fileSizeAtPath:(NSString*) filePath
{
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath])
    {
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}

- (NSFileHandle *)g711FileHandle{
    if (!_g711FileHandle) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.g711TalkFilePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:self.g711TalkFilePath error:nil];
        }
        bool result = [[NSFileManager defaultManager] createFileAtPath:self.g711TalkFilePath contents:nil attributes:nil];
        NSLog(@"+++++++++++++++++create g711 file at path____________________________: %d",result);
        _g711FileHandle = [NSFileHandle fileHandleForWritingAtPath:self.g711TalkFilePath];
    }
    return _g711FileHandle;
}

- (NSString *)g711TalkFilePath{
    if (!_g711TalkFilePath) {
        _g711TalkFilePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: talkFileG711];
    }
    return _g711TalkFilePath;
}

- (void)appendG711FileWithPCMData:(NSData*)pcmData{
    
    unsigned char *pOutBuffer;
    int outLen = 0;
    NSData *g711OutData = nil;
    [_decoder encodePCM2G711AWithSample:8000 channel:1 inputBuf:(unsigned  char *)pcmData.bytes inputLen:(int)pcmData.length outBuf:&pOutBuffer outLen: &outLen];
    
    if (pOutBuffer!=NULL) {
        g711OutData = [NSData dataWithBytes:pOutBuffer length:outLen];
        [self.g711FileHandle writeData:g711OutData];
        free(pOutBuffer);
    }
}

#pragma mark -- 对讲录音完成 准备发送对讲语音
-(void)GetVoiceSendDataNotification:(NSNotification*)notification
{
     NSDictionary* info = notification.userInfo;
     BOOL flag =  [[info objectForKey:VoiceSendDataStatus]boolValue];
    NSString *filePath = [info objectForKey:VoiceSendDataFilePath];
    _isVoceRecorderStatus = flag;
  
    if ([self.delegate respondsToSelector:@selector(SendVoiceRecoderData:andFilePath:)])
    {
        [self.delegate SendVoiceRecoderData:_isVoceRecorderStatus
                                andFilePath:filePath];
    }
}


#pragma mark -- 初始化 playerView
-(void)initWithViewAndDelegate:(UIView *)playerView
                      Delegate:(id<GDVideoPlayerDelegate>)delegate
                   andDeviceID:(NSString *)deviceID
            andWithdoubleScale:(BOOL )isdoubleScale;
{
   // NSLog(@"initWithViewAndDelegate");
    if (_voiceRecorder == nil)
    {
        _voiceRecorder = [[GDVoiceRecorder alloc]init];
        _voiceRecorder.delegage = self;
    }
    
    if (_decoder == nil)
    {
        self.decoder = [[GDVideoDecoder alloc] initWithDeviceID:deviceID];
    }
    
    _isDoubleScale = isdoubleScale;
    _deviceID = deviceID;
    _videoImageSize.width = 0.0f;
    _videoImageSize.height = 0.0f;
    _delegate = delegate;
    
    [self setPlayerView:playerView];
}


#pragma mark -- 初始化 NVR playerView
-(void)initWithViewAndDelegate:(UIView *)playerView
                      Delegate:(id<GDVideoPlayerDelegate>)delegate
                   andDeviceID:(NSString *)deviceID
            andWithdoubleScale:(BOOL )isdoubleScale
               nvrPositionType:(PositionType)nvrPositionType
{
    if (_voiceRecorder == nil)
    {
        _voiceRecorder = [[GDVoiceRecorder alloc]init];
        _voiceRecorder.delegage = self;
    }
    
    if (_decoder == nil)
    {
        self.decoder = [[GDVideoDecoder alloc] initWithDeviceID:deviceID];
        self.decoder.isNvrDevice = YES;
        self.decoder.nvrPositionType = nvrPositionType;
    }
    
    _isDoubleScale = isdoubleScale;
    _deviceID = deviceID;
    _videoImageSize.width = 0.0f;
    _videoImageSize.height = 0.0f;
    _delegate = delegate;
//    _audioPlayer = nil;// _audioDecoder = nil;
    
    [self setPlayerView:playerView];
    
    [_decoder startDecodeWithBuffer];
}


- (void)setCoverPath:(NSString *)coverPath
{
    if (!coverPath || 0 >= coverPath.length)
    {
        return;
    }
    _coverPath = nil;
    _coverPath = [coverPath copy];
    self.decoder.coverPath = _coverPath;
}


- (void)addHardKeyVolumeListener
{
    AudioSessionInitialize(NULL, NULL, NULL, NULL);
    AudioSessionSetActive(true);
    AudioSessionAddPropertyListener(kAudioSessionProperty_CurrentHardwareOutputVolume ,                                                     volumeListenerCallback,      (__bridge void *)(self));
}

//音量键回调函数：
void volumeListenerCallback (void *inUserData,
                             AudioSessionPropertyID inPropertyID,
                             UInt32 inPropertyValueSize,
                             const void *inPropertyValue)
{
    if (inPropertyID != kAudioSessionProperty_CurrentHardwareOutputVolume) return;
    Float32 value = *(Float32 *)inPropertyValue;
    g_volce = value * 100;
    NSLog(@"g_volce = %f",g_volce);
}

- (AQAudioRecorder*)aqAudioRecorder{
    if (!_aqAudioRecorder) {
        _aqAudioRecorder = [[AQAudioRecorder alloc] init];
    }
    return _aqAudioRecorder;
}

-(bool)resumeDecode{
    return [_decoder resumeDecode];
}

-(bool)pauseDecode{
    return [_decoder pauseDecode];
}

- (void)startDecode {
    
    [_decoder startDecodeWithBuffer];
}

/**
 对于设备端支持AAC音频的 直接调用(AVAudioRecorder)录成AAC之后在发送；
 对于设备端只支持G711的 调用(AudioQueue)先录制成PCM 再转码G711 再发送
 边录制，边转码，停止后再发送G711文件
*/
-(BOOL)startRecord
{
    _isAutoRunning = YES;
    if (_audioFrameType == gos_audio_AAC) {
        [_voiceRecorder StartRecoder];
    }else{
        __weak typeof(self) weakSelf = self;
        [self.aqAudioRecorder startRecordingWithAudioCallback:^(NSData *pcmData) {
            [weakSelf appendG711FileWithPCMData:pcmData];
        }];
    }
    return true;
}

-(BOOL)stopRecord
{
    _isAutoRunning = NO;
    if (_audioFrameType == gos_audio_AAC) {
        [_voiceRecorder StopRecoder];
    }else{
        __weak typeof(self) weakSelf = self;
        
        [_g711FileHandle closeFile];
        _g711FileHandle = nil;
        [self.aqAudioRecorder stopRecordingWithResult:^(int result) {
            if ([weakSelf.delegate respondsToSelector:@selector(SendVoiceRecoderData:andFilePath:)])
            {
                [weakSelf.delegate SendVoiceRecoderData:result == 0
                                        andFilePath:self.g711TalkFilePath];
            }
        }];
    }
    return true;
}

-(void)startVoice
{
    [_decoder startVoice];
}

-(void)stopVoice;
{
    [_decoder stopVoice];
}


#pragma mark -- 设置解码器的 playerView（屏幕切换时调用）
-(void)setPlayerView:(UIView*)view
{
    if (_decoder == nil)
    {
        return;
    }
    if (view == nil)
    {
        [_decoder setView:nil];
        if (_playerView.superview)
        {
            [_playerView removeFromSuperview];
        }
        return;
    }
    
    if ( _playerView == nil)
    {
        if (view.frame.size.width == 0) {
           _playerView = [[GDPlayerView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        }
        else{
            _playerView = [[GDPlayerView alloc] initWithFrame:CGRectMake(0, 0, view.frame.size.width, view.frame.size.height)];
        }
        _playerView.backgroundColor = [UIColor clearColor];
        _playerView.isdoubleScale = _isDoubleScale;
//        _playerView.contentMode   = UIViewContentModeScaleAspectFill;
        NSLog(@"setPlayer_View frame = %@",NSStringFromCGRect(_playerView.frame));
        [view insertSubview:_playerView atIndex:0];
    }
    else
    {
        for (UIView *subView in view.subviews)
        {
            if (subView == _playerView)
            {
                
                //如果是全屏
//                if (view.frame.size.height == [[UIScreen mainScreen] bounds].size.height) {
//                    _playerView.frame = CGRectMake(0, 0, view.frame.size.height, view.frame.size.width);
//                    break;
//                }
                
                _playerView.frame = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height);
                break;
            }
        }
        [_playerView configViewSize];
    }
    [_decoder setView:_playerView];
    NSLog(@"视图显示设置成功");
}

- (void)resizePlayViewFrame:(CGRect)playViewFrame{
    if (_decoder == nil)
    {
        return;
    }
    
    if (_playerView)
    {
        _playerView.frame = playViewFrame;
        [_playerView configViewSize];
    }
    [_decoder setView:_playerView];
    // NSLog(@"视图显示设置成功");
}


-(void)nvrUpdatePlayerViewSize:(CGSize)playViewSize
{
    if (_decoder == nil)
    {
        return;
    }
    
    CGRect frame = CGRectMake(0, 0, playViewSize.width, playViewSize.height);
    _playerView.frame = frame;
    NSLog(@"更新 playView frame = %@", NSStringFromCGRect(_playerView.frame));
    [_playerView configViewSize];
    [_decoder setView:_playerView];
}


#pragma mark --- 接从网络获取的视频流时间，丢给解码器解码播放
-(BOOL)AddVideoFrame:(unsigned char *)pContentBuffer
                 len:(int)len
                  ts:(int)ts
              framNo:(unsigned int)framNO
           frameRate:(int)frameRate
              iFrame:(BOOL) iFrame
        andDeviceUid:(NSString *)UID
{
    if ([_deviceID isEqualToString:UID])
    {
        
        //防止gdvideoplayer释放导致的崩溃
        if (!self || ![self isKindOfClass:[GDVideoPlayer class]]) {
            return true;
        }
        
        //防止videoDecoder野指针的崩溃
        if (![self.decoder isKindOfClass:[GDVideoDecoder class]]) {
            return true;
        }
        
        [self.decoder AddVideoFrame:pContentBuffer
                                    len:len
                                     ts:ts
                                 framNo:framNO
                              frameRate:frameRate
                                 iFrame:iFrame
                                 andUid:UID];
    }
    return true;
}

-(void)dealloc
{
    NSLog(@" ______GDVideoPlayer_dealloc_____");
}

-(void)releasePlayer
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:VoiceSendDataNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
     
                                                    name:GDPlayerNotification object:nil];
}


#pragma mark -- 将从网络获取的音频数据丢给音频播放器播放
-(BOOL)AddAudioFrame:(Byte *)buffer
                 len:(int)len
           frameType:(int)frameType
{
    if (_audioFrameType == -1) {
        _audioFrameType = frameType;
        [_voiceRecorder setEncodedToAACDirectly:frameType ==gos_audio_AAC];
    }
    [_decoder decodeAudioFrameWithBuffer:buffer length:len frameType:frameType];
    return true;
}



#pragma mark -- 停止所有的视频音频语音对讲功能
-(BOOL)stopPlay
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self setPlayerView:nil];
        if (_playerView){
            _playerView = nil;
        }
    });
    
    
    _delegate =nil;
    // 取消录制
    if (_capture)
    {
        [_capture setRecordTarget:nil callback:nil];
        [_capture stopRecording];

        _capture = nil;
    }
    
    if (_voiceRecorder)
    {
        [_voiceRecorder StopRecoder];

        _voiceRecorder = nil;
    }
    
    [self releasePlayer];
    
   
    
    if (self.decoder)
    {
        [self.decoder setScreenshotTarget:nil selector:nil];
        [self.decoder stopDecode];
        self.decoder = nil;
    }
    
    NSLog(@"stopPlay_inGDVideoPlayer");
    return true;
}

-(BOOL)screenshot:(BOOL)isSavePhoto andPath:(NSString *)path andBlockRequst:(BlockResultError)block
{
        if (_blockResult != nil) {
            _blockResult = nil;
        }
        _blockResult = block;
        if (_decoder){
            if (isSavePhoto) {
                [_decoder setScreenshotTarget:_delegate selector:@selector(SavePhotoImage:didFinishSavingWithError:contextInfo:)];
            }
            else
            {
                if (path == nil) {
                    NSLog(@"path is null");
                    NSError* error = [[NSError alloc] initWithDomain:@"path is NULL" code:-1 userInfo:nil];
                    _blockResult(-1,error);
                    return NO;
                }
                [_decoder setScreenshotTarget:_delegate selector:@selector(image:didFinishSavingWithError:contextInfo:)];
            }
            
             BOOL flag = [_decoder saveScreenshot:path andSavePhoto:isSavePhoto];
            if (_blockResult)
            {
                _blockResult(0,nil);
            }
             return flag;
        }
        else{
            NSError* error = [[NSError alloc] initWithDomain:@"VideoDecoder is NULL" code:-1 userInfo:nil];
            _blockResult(-1,error);
            return NO;
        }
}


-(void)saveRecord:(BOOL)isSavePhoto andPath:(NSString *)path{
    if (_capture == nil)
    {
        _capture = [[GDCapture alloc] init];
    }
    [_capture videoAndAudioSynthetic:_delegate callback:@selector(video:didFinishSavingWithError:contextInfo:) andSavePhoto:isSavePhoto andPath:path];
    return;
}

//录像
-(BOOL)recordStartWithAudioEnabled:(BOOL)enabled andSavePhoto:(BOOL)isSavePhoto andPath:(NSString *)path andBlockRequst:(RecordResultBlock)block
{
    
    _recordBlock = block;
    if (_decoder && !_isRecording)
    {
        if (!isSavePhoto) {
            if (path == nil) {
                NSLog(@"path is null");
                NSError* error = [[NSError alloc] initWithDomain:@"path is NULL" code:-1 userInfo:nil];
                _recordBlock(-1,0,error);
                return NO;
            }
        }
        
        if (_videoImageSize.width < 1 || _videoImageSize.height < 0) {
            NSError* error = [[NSError alloc] initWithDomain:@"get data is Fail" code:-1 userInfo:nil];
            _recordBlock(-1,0,error);
            return NO;
        }
        
        _decoder.recordPath = path;
        //开始录像
        [_decoder setRecordCallbackTarget:_delegate selector:@selector(video:didFinishSavingWithError:contextInfo:)];
        __weak typeof(self) weakSelf = self;
        _isRecording = [_decoder startRecordWithResultBlock:^(int result, int count) {
            weakSelf.recordBlock(result,count,nil);
        }];
        //录像开启失败，则置recording标志为NO

        return _isRecording;
    }
    else
    {
        NSError* error = [[NSError alloc] initWithDomain:@"VideoDecoder is NULL" code:-1 userInfo:nil];
        if (_blockResult)
        {
            _blockResult(-1,error);
        }
        
        return NO;
    }
}

-(BOOL)recordStop
{
    if (_isRecording == YES)
    {
        _isRecording = NO;
        NSLog(@"录像结束");
        
        [_decoder stopRecord];
        //结束录像
        [_capture stopRecording];

        _capture = nil;
        return YES;
    }
    else
    {
        return NO;
    }
}


#pragma mark -- 通知视频播放 view 的大小
-(void)gotPlayerNotification:(NSNotification*)notification
{
    NSDictionary* info = notification.userInfo;
    if ([info objectForKey:GDPlayerInfoKeyFrameWidth])
    {
        _videoImageSize.width = [[info objectForKey:GDPlayerInfoKeyFrameWidth] intValue];
    }
    if ([info objectForKey:GDPlayerInfoKeyFrameHeight])
    {
        _videoImageSize.height = [[info objectForKey:GDPlayerInfoKeyFrameHeight] intValue];
        
    }
}

- (void)initOpenAL{
//    [self.decoder.pcmPlayer1 initOpenAL];
}

- (void)render:(KxVideoFrame *)frame{
    if ([self.playerView isKindOfClass:[GDPlayerView class]]) {
        [self.playerView render:frame];
    }
}

- (void)openAudioWithBuffer:(unsigned char *)pBuffer length:(int)pLength{
    [self.decoder.pcmPlayer addNewData:[NSData dataWithBytes:pBuffer length:pLength]  len:pLength];
}

@end

