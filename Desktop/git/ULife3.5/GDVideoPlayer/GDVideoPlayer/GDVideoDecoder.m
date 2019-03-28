//
//  AVdataDecoder.m
//  U-life Player
//
//  Created by Yuan Xue on 12-8-7.
//  Copyright (c) 2012年 Goscam. All rights reserved.
//
#include <sys/time.h>
#include <time.h>
#import "GDVideoDecoder.h"
#import "GDDeviceIcon.h"
#import "GDVideoStateInfo.h"
#import "GDCapture.h"

#import "GDPlayerView.h"



#import "PCMPlayer.h"
#import "OpenALPlayer.h"
#import <../../ACVideoDecoder/ACVideoDecoder/ACVideoDecoder.h>
#import <../../../ULife3.5/NetPro/NetProSDK/common/GosFrameHeadDef.h>

typedef int       byte4_8;

typedef struct
{
    byte4_8	nIFrame;	// 1,yes;	2,no
    byte4_8	nAVType;	// 1,video;	2,audio
    byte4_8	dwSize;		// audio or video data size
    byte4_8	gs_frameRate_samplingRate;	// video frame rate or audio samplingRate
    byte4_8	lTMStamp;
    byte4_8	gs_video_cap;				// video's capability
    byte4_8	gs_reserved;
}FrameDataInfo;

@interface GDVideoDecoder()

@property(nonatomic,strong)ACVideoDecoder *acVideoDecoder;
//@property(nonatomic,strong)AULivePCMPlayer *pcmPlayer;


@property(nonatomic,strong)KxVideoFrameYUV *frame;
@property(nonatomic,copy)RecordBlock recordBlock;

@property(nonatomic,strong)GDPlayerView* playerView;
@property(nonatomic,assign)int cur_height,cur_width,ininState;

@property(nonatomic,assign)long nPort, startTime,endTime;;
@property(nonatomic,assign)bool hasReadIFrame;

@property (assign, nonatomic)  gos_codec_type_t audioFrameType;
@end

@implementation GDVideoDecoder
{
    BlockResult _block;
    NSString *_imagePath;
    BOOL _isSavePhoto;
    NSString *_videoPath;
    
    BOOL  _iFrame;
    int _lastTimeStamp;     // 上一帧获取的时间
    int _framNO;
    int _frameRate;
    
    GDCapture *_capture;
    float oneFrameCostTs; //每次帧率
    long lastFrameDecodeCost;   // 上一帧解码耗时
    long total_Dec_cost;    // 总共解码耗时
    long toatl_dec_count;   // 总共解码数量
    BOOL _waitForKeyFrame;
    
    NSString *recordFilePath;
}

GDVideoDecoder *aSelf;


+(GDVideoDecoder *)sharedInstance
{
    static GDVideoDecoder *decoder = nil;
    static dispatch_once_t token;
    if(decoder == nil)
    {
        dispatch_once(&token,^{
            decoder = [[GDVideoDecoder alloc] init];}
                      );
    }
    return decoder;
}

-(id)initWithDeviceID:(NSString *)deviceId
{
    self = [super init];
    if (self)
    {
        _deviceId = deviceId;
        self.audioFrameType = gos_unknown_frame;
        
        _ininState = 0;
        _waitForKeyFrame = YES;
        _lock = [[NSLock alloc] init];
        
        _acVideoDecoder = [[ACVideoDecoder alloc]init];
        aSelf = self;
        __weak typeof(self) weakSelf = self;
        [_acVideoDecoder initVideoDecoderWithDataCallBack:^(PDecodedFrameParam frameParam) {
            if ( frameParam->lpBuf == NULL)
            {
                return;
            }
//            NSLog(@"ADStart----------------");
            if (frameParam->nDecType == 4 && aSelf.audioFrameType == gos_audio_G711A) {//PCM

//
//                [aSelf.audioPlayer playWith: (char*)pOutBuffer andBufferLen: length];

//                [aSelf.pcmPlayer play:[NSData dataWithBytes:frameParam->lpBuf length:frameParam->lSize]];
                if (!aSelf.full_duplex_flag) {
                    [aSelf.pcmPlayer addNewData:[NSData dataWithBytes:frameParam->lpBuf length:frameParam->lSize] len:frameParam->lSize];
                }else{
                    if ([aSelf.agcDelegate respondsToSelector:@selector(agcDataWithPcmData:)]) {
                        NSData *data = [aSelf.agcDelegate agcDataWithPcmData:[NSData dataWithBytes:frameParam->lpBuf length:frameParam->lSize]];
                        [aSelf.pcmPlayer addNewData:data len: (int)data.length];
                    }
                }

            }
            else if ( frameParam->nDecType == 0 ) {//YUV
                
                @autoreleasepool {
                    
                    if (!weakSelf.frame) {
                        weakSelf.frame = [[KxVideoFrameYUV alloc]init];
                    }else{
                        weakSelf.frame.luma = weakSelf.frame.chromaB = weakSelf.frame.chromaR = nil;
                        //                weakSelf.frame.rgb = nil;
                    }
                    weakSelf.frame.width = weakSelf.cur_width = frameParam->lWidth;
                    weakSelf.frame.height = weakSelf.cur_height = frameParam->lHeight;
                    
                    long imageSize = frameParam->lWidth * frameParam->lHeight;
                    
                    weakSelf.frame.luma = [NSData dataWithBytes:frameParam->lpBuf length: imageSize];
                    weakSelf.frame.chromaB = [NSData dataWithBytes:frameParam->lpBuf+(int)imageSize length:imageSize/4];
                    weakSelf.frame.chromaR = [NSData dataWithBytes:frameParam->lpBuf+(int)(imageSize*5/4) length:imageSize/4];
                    
                    //                    NSLog(@"================= weakSelf = %p", weakSelf);
                    if (weakSelf.playerView)
                    {
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (weakSelf.ininState == 0)
                            {
                                if (weakSelf.playerView)
                                {
                                    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
                                    [dict setObject:[NSNumber numberWithInt:weakSelf.cur_width]
                                             forKey:GDPlayerInfoKeyFrameWidth];
                                    [dict setObject:[NSNumber numberWithInt:weakSelf.cur_height]
                                             forKey:GDPlayerInfoKeyFrameHeight];
                                    [[NSNotificationCenter defaultCenter] postNotificationName:GDPlayerNotification
                                                                                        object:nil
                                                                                      userInfo:dict];
                                    
                                    [weakSelf.playerView setupView:weakSelf.cur_width setHeight:weakSelf.cur_height];
                                    [weakSelf.playerView playViewSetup]; //startView;
                                }
                                weakSelf.ininState = 1;
                            }
                            if (weakSelf.playerView)
                            {
                                [weakSelf.playerView render:weakSelf.frame];
                            }
//                            
//                            NSLog(@"ADEnd----------------");
                        });
                    }
                }
            }
        }];
        

    }
    return self;
}

static long  DecCallBackFunc(PDecodedFrameParam frameParam )
{
    return 0;
}

-(void)dealloc
{
    [self releaseDecoder];
    _lock = nil;
    
    NSLog(@"______________GDVideoDecoder_dealloc_________");
}

-(void)releaseDecoder
{
    _capture = nil;
    self.deviceId = nil;
    _imgDataForScreenshot = nil;
}

#pragma mark -- 解码开始.
-(void)startDecodeWithBuffer
{
    _threadStarted = YES;
    _block = nil;
    //    _capture = nil;
    _imgDataForScreenshot = nil;
    _recordWaitForIframe = YES;
}


-(void)setView:(GDPlayerView*)view
{
    _playerView = nil;
    _playerView = view;
}

-(bool)resumeDecode{
    return [_acVideoDecoder ac_startDecodeWithCallBack:DecCallBackFunc];
}

-(bool)pauseDecode{
    return [_acVideoDecoder ac_stopDecode];
}
// 解码结束
-(void)stopDecode
{
    [_audioPlayer pause];
    _audioPlayer = nil;
    
    _ininState = 0;
    
    [self saveDeviceScreenshot];
    
    if (_pcmPlayer) {
        [_pcmPlayer stopPlayPCM];
        _pcmPlayer = nil;
    }
   
    
    _threadStarted = NO;
    _hasReadIFrame = NO;
    
    [_acVideoDecoder ac_uninit];
    if (aSelf) {
        NSLog(@"============ stopDecode aSelf = nil");
        aSelf = nil;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (_playerView.superview) {
            [_playerView removeFromSuperview];
            _playerView = nil;
        }
    });
}


#pragma mark -- 丢给 FFMPEG 播放
-(void)decodeAndShow:(Byte*) buf
              length:(int)len
        andTimeStamp:(unsigned long)ulTime
           frameRate:(int)frameRate
              iFrame:(BOOL)iFrame
{
//    if(iFrame){
//        NSLog(@"===================, nIFrame=%d, dwSize=%d  timeStamp:%d ______Video", iFrame,len,ulTime);
//    }
    
//    if (iFrame) {
//        NSLog(@"Waiting for AD3AD3AD3AD3AD3AD3");
//    }
    if (_playerView == nil)
    {
        return;
    }
//    if (iFrame) {
//        NSLog(@"Waiting for AD4AD4AD4AD4AD4AD4");
//    }
    [self av_putFrameWithPort:_nPort buffer:buf length:len];
    
    return;
}


#pragma mark -- 拍照
-(void)updateScreenshotData
{
    //拍照
    if (_threadStarted)
    {

        _imgDataForScreenshot = nil;
        
        NSString *filePath = nil;
        [GDDeviceIcon getImagePath:&filePath forImg: [_deviceId stringByAppendingString:_subDevId?:@""]];
        
        long capResult =  [_acVideoDecoder ac_captureWithPort:0 filePath:self.coverPath ? self.coverPath : filePath];
        
        if ( capResult ) {
            
            _imgDataForScreenshot = [[NSData alloc]initWithContentsOfFile:filePath];
            NSLog(@"updateScreenshotData_Capture_succeeded");
			// 发送更新封面通知
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateScrrenShot"
                                                                object:nil];
        }else{
            NSLog(@"updateScreenshotData_Capture_failed");
        }
    }
    else
    {
        NSLog(@"_threadStarted = %d",_threadStarted);
    }
    
}


#pragma mark -- 拍照
-(BOOL)saveScreenshot:(NSString *)Path
         andSavePhoto:(BOOL)isSavePhoto
{
    if (_threadStarted) {
        
        [_lock lock];
        
        NSString *filePath = nil;
        [GDDeviceIcon getImagePath:&filePath forImg:_deviceId];
        
        self.snapshotPath = Path;
        long capResult =  [_acVideoDecoder ac_captureWithPort:0 filePath:self.snapshotPath ? self.snapshotPath : filePath];
        if (!capResult)
        {
            NSError* error = [[NSError alloc] initWithDomain:@"get data fail" code:-1 userInfo:nil];
            [_screenshotTarget performSelector:_screenshotSelector withObject:_imagePath withObject:error];
            [_lock unlock];
            return NO;
        }
        _imagePath = Path;
        _isSavePhoto = isSavePhoto;
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipLast;
        
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:self.snapshotPath ? self.snapshotPath : filePath];
        if(_isSavePhoto)
        {
            UIImageWriteToSavedPhotosAlbum(image, _screenshotTarget, _screenshotSelector, nil);
        }
        else
        {
            NSData *dataObj = UIImagePNGRepresentation(image);
            BOOL result = [dataObj writeToFile:_imagePath atomically:YES];
            NSError *error = [[NSError alloc] initWithDomain:@"filed save fail"
                                                        code:-1
                                                    userInfo:nil];
            if ([_screenshotTarget respondsToSelector:_screenshotSelector])
            {
                [_screenshotTarget performSelector:_screenshotSelector
                                        withObject:_imagePath
                                        withObject:result ? nil : error];
            }
        }
        [_lock unlock];
    }
    else
    {
        NSError* error = [[NSError alloc] initWithDomain:@"get data fail" code:-1 userInfo:nil];
        [_screenshotTarget performSelector:_screenshotSelector withObject:_imagePath withObject:error];
    }
    return YES;
}


-(void)postAction:(SEL)action toTarget:(id)target withError:(NSError*)err
{
    [target performSelector:action withObject:err withObject:nil];
}

-(void)setScreenshotTarget:(id)target selector:(SEL)selector
{
    _screenshotTarget = target;
    _screenshotSelector = selector;
}

-(void)setRecordCallbackTarget:(id)target selector:(SEL)selector {
    _recCallbackTarget = target;
    _recCallbackSelector = selector;
}

-(void)saveDeviceScreenshot
{
    if (self.deviceId == nil)
    {
        return;
    }
    //此处代码在同一时刻只能有一个线程执行.
    
//   [GDDeviceIcon saveImage:image andDevId:self.deviceId];
    
    [self updateScreenshotData];
}

- (void)startVoice {
    
    if (!_pcmPlayer && self.audioFrameType==gos_audio_G711A) {
        _pcmPlayer = [[AULivePCMPlayer alloc]init];
        [_pcmPlayer startPlayPCM];
    }
    
    if (_audioPlayer == nil && self.audioFrameType!=gos_audio_G711A) { //
        _audioPlayer = [[KKSimpleAUPlayer alloc]init];
        [_audioPlayer play];
//        if (self.audioFrameType==gos_audio_G711A) {
//            [self.acVideoDecoder ac_encodeAACStartWithSample:8000 channel:1 callback:encodeAACCallbackFunc userParam:0];
//        }
    }
}

long  encodeAACCallbackFunc(unsigned char* lpBuf, long lSize, long lUserParam){
    
    if (aSelf.audioPlayer) {
        [aSelf.audioPlayer playWith: (char*)lpBuf andBufferLen:(int)lSize];
    }
    return 0;
}


- (void)stopVoice {
    
    if (_pcmPlayer && self.audioFrameType==gos_audio_G711A ) {

        [_pcmPlayer stopPlayPCM];
        _pcmPlayer = nil;
    }
    
    if (_audioPlayer != nil && self.audioFrameType!=gos_audio_G711A) {//
        [_audioPlayer pause];
        _audioPlayer = nil;
//        if (self.audioFrameType==gos_audio_G711A) {
//            [self.acVideoDecoder ac_encodeAACStop];
//        }
    }
}


#pragma mark -

-(long)getEndTime
{
    struct timeval tvEnd;
    
    gettimeofday(&tvEnd, NULL); // 获取当前世界
    
    long end = ((long)tvEnd.tv_sec) * 1000 + (long)tvEnd.tv_usec/1000;
    
    //    gettimeofday (&tvStart,NULL);
    //    long long tStart = (long long)1000000*tvStart.tv_sec+tvStart.tv_usec;
    //	NSLog(@"当前时间:  %lld", tStart);
    return end;
}

-(long)getStartTime
{
    struct timeval tvStart;
    
    gettimeofday(&tvStart, NULL);
    
    long start = ((long)tvStart.tv_sec) * 1000 + (long)tvStart.tv_usec/1000;
    
    //    gettimeofday (&tvStart,NULL);
    //    long long tStart = (long long)1000000*tvStart.tv_sec+tvStart.tv_usec;
    //	NSLog(@"当前时间:  %lld", tStart);
    return start;
}






#pragma mark - snapshot
- (bool)startRecordWithResultBlock:(RecordBlock)block {
    
    _recordBlock = block;
    recordFilePath = self.recordPath;// [self recordFileTempPath];
    int audioType;
    if(aSelf.audioFrameType == gos_audio_G711A){
        audioType = 1;
    }
    else{
        audioType = 0;
    }
    
    //0是AAC 1是G711
    NSString *recPath = self.recordPath ? self.recordPath : recordFilePath;
    bool recordRet = [_acVideoDecoder ac_startRecordWithPort:0
                                                    filePath:recPath
                                                   audioType:audioType
                                                    callBack:RecordCallBackFunc];
    NSLog(@"录像结果：%d", recordRet);
    
    return recordRet;
}

- (bool)startRecord {
    
    //ac_startRecordWithPort
    recordFilePath = [self recordFileTempPath];
    int audioType;
    if(aSelf.audioFrameType == gos_audio_G711A){
        audioType = 1;
    }
    else{
        audioType = 0;
    }
    return [_acVideoDecoder ac_startRecordWithPort:0 filePath:recordFilePath audioType:audioType callBack:RecordCallBackFunc];
}

static long  RecordCallBackFunc( AVRecordEvent eventRec, long lData)
{
    // 根据 eventRec 做对应处理
    // 返回录像状态，当前录像时长、播放时长
    if (aSelf.recordBlock) {
        
        if (eventRec == AVRecordEventRetTime) {
            aSelf.recordBlock(0,lData);
        }else if (eventRec == AVRecordEventOpenSuccess){
            aSelf.recordBlock(0,0);
        }else if (eventRec == AVRecordEventOpenErr){
            aSelf.recordBlock(-1,lData);
        }else if (eventRec == AVRecordEventTimeEnd){
            aSelf.recordBlock(-1,lData);
        }
    }
    
    
    NSLog(@"RecordCallBackFunc______%d lData:%d ",eventRec, lData);
    return 1;
}

-(void)stopRecord
{
    _capture = nil;
    bool result = [_acVideoDecoder ac_stopRecord];
    
    
    
    NSLog(@"stopRec___________________:%d - recordFilePath: %@  recordPath:%@",result, recordFilePath, _recordPath);
//    NSString *truePath = self.recordPath ? self.recordPath : recordFilePath;
    if(result && [[NSFileManager defaultManager] fileExistsAtPath:recordFilePath]){
        
        //判断录像必须大于80kb
        long long fileSize = [self fileSizeAtPath:recordFilePath];
        if (fileSize < 0.08 * 1024 * 1024) {
            //小于80kb的不保存 删除
            [[NSFileManager defaultManager] removeItemAtPath:recordFilePath error:nil];
            return;
        }
        
        
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(recordFilePath))
        {
            NSLog(@"完成了,   保存文件至相册: %@", recordFilePath);
//            UISaveVideoAtPathToSavedPhotosAlbum(recordFilePath, _recCallbackTarget, _recCallbackSelector, nil);
            UISaveVideoAtPathToSavedPhotosAlbum(recordFilePath, nil, nil, nil);
            [_recCallbackTarget performSelector:_recCallbackSelector withObject:nil];
        }
        else if ([_recCallbackTarget respondsToSelector:_recCallbackSelector])
        {
            NSLog(@"完成了, 保存失败");
            NSError* err = [[NSError alloc] initWithDomain:@"failed to save." code:-1 userInfo:nil];
            [_recCallbackTarget performSelector:_recCallbackSelector withObject:err];
            //        [weakSelf postAction:action toTarget:target withObject:nil withError:err];
        }
    }else{
        NSLog(@"file______not_________exist________");
    }
}

-(long long) fileSizeAtPath:(NSString*)filePath{
    NSFileManager* manager =[NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil]fileSize];
    }
    return 0;
}


- (NSString *)recordFileTempPath{
    NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString *timeStr = [self getCurrentDate];
    NSString *createPath;
    createPath = [NSString stringWithFormat:@"%@/storeVideo/%@/%@.mp4",pathDocuments,self.deviceId,timeStr];
    return createPath;
}

#pragma mark -- 获取当前日期
- (NSString *)getCurrentDate
{
    NSDate *date =[NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *currentDate = [formatter stringFromDate:date];
    
    return currentDate;
}

- (void)encodePCM2G711AWithSample:(int)sample
                          channel:(int)channel
                         inputBuf:(unsigned  char *)pInData
                         inputLen:(int)nInLen
                           outBuf:(unsigned  char **)pOutData
                           outLen:(int *)nOutLen{
    [_acVideoDecoder ac_encodePCM2G711AWithSample:sample channel:channel inputBuf:pInData inputLen:nInLen outBuf:pOutData outLen:nOutLen];
}

- (void)decodeAudioFrameWithBuffer:(unsigned char *)pBuf length:(int)len frameType:(int)frameType
 {
    
    if (len%5==0) {
//        NSLog(@"===================, nIFrame=%d, dwSize=%d  timeStamp:%d ______Audio", iFrame,len,ts);
    }
     if (self.audioFrameType == gos_unknown_frame) {
         self.audioFrameType = (gos_codec_type_t)frameType;
     }
     
    [self av_putFrameWithPort:(int)_nPort buffer:pBuf length:len];
     if (self.audioFrameType == gos_audio_AAC) {
         [self.audioPlayer playWith:(char*)pBuf andBufferLen:len];
     }
}

#pragma mark -Debug
- (void)av_putFrameWithPort:(int)port buffer:(unsigned char *)buffer length:(int)len {
    [_lock lock];
    [_acVideoDecoder  ac_putFrameWithPort:0 Buffer:buffer length:len];
    [_lock unlock];
}

- (NSString *)filePathForTest{
    
    return [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)objectAtIndex:0] stringByAppendingPathComponent:@"liveStream.dat"];
}

#pragma mark -- 缓存视频帧数据到 videoBuffer 中
-(BOOL)AddVideoFrame:(unsigned char *)pContentBuffer
                 len:(int)len
                  ts:(int)ts
              framNo:(unsigned int)framNO
           frameRate:(int)frameRate
              iFrame:(BOOL) iFrame
              andUid:(NSString *)UID
{
    if(!_threadStarted){
        _threadStarted = YES;
    }
    if (iFrame) {
//        NSLog(@"ts = %d,fromNo = %d,iFrame = %d,len = %d",ts,framNO,iFrame,len);
        if (!_hasReadIFrame) {
            _hasReadIFrame = YES;
            [self startDecodeWithBuffer];
        }
    }
    
    [self decodeAndShow:pContentBuffer length:len andTimeStamp:ts frameRate:frameRate iFrame:iFrame];
    return true;
}
- (void)sendSDCardCommandWithType:(SDCommandType)type destinaFileName:(NSString *)destinaFileName callBack:(RecordCallbackFunc)callbackFunc{
    [self.acVideoDecoder ac_sendSDCardCommandWithType:type destinaFileName:destinaFileName callBack:nil];
}

- (void)stopAcDecode{
    [self.acVideoDecoder ac_stopDecode];
}

- (void)startAcDecode{
    [self.acVideoDecoder ac_startDecode];
}

- (void)ac_setBufferSize:(int)bufferSize nType:(int)nType{
    [self.acVideoDecoder ac_setBufferSize:bufferSize nType:nType];
}

- (void)initlizeAudioFrameTypeToG711{
    self.audioFrameType = gos_audio_G711A;
}


@end

