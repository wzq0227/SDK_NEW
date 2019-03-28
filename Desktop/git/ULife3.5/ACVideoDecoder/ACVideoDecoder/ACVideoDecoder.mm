//
//  ACVideoDecoder.m
//  ACVideoDecoder
//
//  Created by zhuochuncai on 19/1/17.
//  Copyright © 2017年 zhuochuncai. All rights reserved.
//

#import "ACVideoDecoder.h"
#import "AVPlayer.h"



//播放通知Key
static NSString *const PlayStatusNotification = @"PlayStatusNotification";
static NSString *const ConvertMP4Notification = @"ConvertMP4Notification";

FrameCallbackBlock g_decodedDataCallback[100]={};
RecordCallbackFunc g_recordCallback = NULL;

FrameCallbackBlock cloud_decodedDataCallback[100]={};
RecordCallbackFunc cloud_recordCallback = NULL;

static ACVideoDecoder *aSelf;
static ACSeekVideoDecoder *seekSelf;
static ACCloudVideoDecoder *cloudSelf;


@implementation ACVideoDecoder

- (void)initVideoDecoderWithDataCallBack:(FrameCallbackBlock)frameCallback {
    aSelf = self;
    AV_Init(0,NULL);
    _nPort = AV_GetPort();
    if ( _nPort >= 0) {
        g_decodedDataCallback[_nPort] = frameCallback;
    }
    AV_Play(_nPort, 0, (void *)DecCallBack, 0);
}

- (void)ac_putFrameWithPort:(int)port Buffer:(unsigned char *)buf length:(int)len {
    long ReturnValue = AV_PutFrame(_nPort, buf, len);
    if (ReturnValue == -20) {
        //缓存满了 发通知 类型是15
        NSDictionary *notifyData = @{@"nPort" : [NSNumber numberWithLong:0],
                                     @"eventRec" : [NSNumber numberWithInt:15],
                                     @"lData" : [NSNumber numberWithLong:0],
                                     @"lUserParam" : [NSNumber numberWithLong:0],
                                     @"Decode" : aSelf,
                                     };
        [[NSNotificationCenter defaultCenter] postNotificationName:PlayStatusNotification object:nil userInfo:notifyData];
    }
}


- (bool)ac_captureWithPort:(int)port filePath:(NSString *)filePath {
    return AV_Capture(_nPort, [filePath UTF8String])==AVErrSuccess;
}


//nDecType,解码后的数据类型 0 - YUV420, 1 - 32位的RGB, 2 - 24位的RGB
static long  DecCallBack(PSTDecFrameParam stDecParam, void *pUserParam)
{
    DecodedFrameParam *param = (DecodedFrameParam*)stDecParam;
    if (!stDecParam) {
        //        AV_StopDecH264File(aSelf.nPort);
        
        g_decodedDataCallback[aSelf.nPort](param);
        return 0;
    }
    if (stDecParam && g_decodedDataCallback[stDecParam->nPort]) {
        if (stDecParam->nDecType == 5) {
            //SD抓拍截图成功这时候回调截图 --发通知 类型是11
            NSDictionary *notifyData = @{@"nPort" : [NSNumber numberWithLong:0],
                                         @"eventRec" : [NSNumber numberWithInt:11],
                                         @"lData" : [NSNumber numberWithLong:0],
                                         @"lUserParam" : [NSNumber numberWithLong:0],
                                         @"Decode" : aSelf,
                                         };
            [[NSNotificationCenter defaultCenter] postNotificationName:PlayStatusNotification object:nil userInfo:notifyData];
        }
        
        if (stDecParam->nDecType == 6) {
            //SD剪切成功 --发通知 类型是13
            NSDictionary *notifyData = @{@"nPort" : [NSNumber numberWithLong:0],
                                         @"eventRec" : [NSNumber numberWithInt:13],
                                         @"lData" : [NSNumber numberWithLong:0],
                                         @"lUserParam" : [NSNumber numberWithLong:0],
                                         @"Decode" : aSelf,
                                         };
            [[NSNotificationCenter defaultCenter] postNotificationName:PlayStatusNotification object:nil userInfo:notifyData];
        }
        
        if (stDecParam->nDecType == 7) {
            //SD卡历史流播放完成 --发通知 类型是14
            NSDictionary *notifyData = @{@"nPort" : [NSNumber numberWithLong:0],
                                         @"eventRec" : [NSNumber numberWithInt:14],
                                         @"lData" : [NSNumber numberWithLong:0],
                                         @"lUserParam" : [NSNumber numberWithLong:0],
                                         @"Decode" : aSelf,
                                         };
            [[NSNotificationCenter defaultCenter] postNotificationName:PlayStatusNotification object:nil userInfo:notifyData];
        }
        
        if (stDecParam->nDecType == 8) {
            //缓存空了 发通知 类型是16
            NSDictionary *notifyData = @{@"nPort" : [NSNumber numberWithLong:0],
                                         @"eventRec" : [NSNumber numberWithInt:16],
                                         @"lData" : [NSNumber numberWithLong:0],
                                         @"lUserParam" : [NSNumber numberWithLong:0],
                                         @"Decode" : aSelf,
                                         };
            [[NSNotificationCenter defaultCenter] postNotificationName:PlayStatusNotification object:nil userInfo:notifyData];
        }
        
        if (stDecParam->nDecType == 10) {
            //历史流加载中 17
            NSDictionary *notifyData = @{@"nPort" : [NSNumber numberWithLong:0],
                                         @"eventRec" : [NSNumber numberWithInt:17],
                                         @"lData" : [NSNumber numberWithLong:0],
                                         @"lUserParam" : [NSNumber numberWithLong:0],
                                         @"Decode" : aSelf,
                                         };
            [[NSNotificationCenter defaultCenter] postNotificationName:PlayStatusNotification object:nil userInfo:notifyData];
        }
        
        
        if (stDecParam->nDecType == 11) {
            //历史流加载成功 18
            NSDictionary *notifyData = @{@"nPort" : [NSNumber numberWithLong:0],
                                         @"eventRec" : [NSNumber numberWithInt:18],
                                         @"lData" : [NSNumber numberWithLong:0],
                                         @"lUserParam" : [NSNumber numberWithLong:0],
                                         @"Decode" : aSelf,
                                         };
            [[NSNotificationCenter defaultCenter] postNotificationName:PlayStatusNotification object:nil userInfo:notifyData];
        }

        g_decodedDataCallback[stDecParam->nPort](param);
    }
    return 0;
}

- (void)ac_setBufferSize:(int)bufferSize nType:(int)nType{
    AV_SetBuffSize(_nPort, nType,bufferSize ,200 * 1024);
}

- (bool)ac_startDecode{
    if (_nPort < 0) {
        return false;
    }
    return  AV_Play(_nPort, 0, (void *)DecCallBack, 0);
}


//audioType 0是aac 1是g7111
- (bool)ac_startRecordWithPort:(NSInteger)port filePath:(NSString *)filePath audioType:(int)audioType callBack:(RecordCallbackFunc)callbackFunc {
    g_recordCallback = callbackFunc;
    return AV_StartRec(_nPort, [filePath UTF8String],(void *)recordCallback, 0)==AVErrSuccess;
}

static void  recordCallback(long nPort, AVRecEvent eventRec, long lData, long lUserParam){
    //开始转码格式为mp4回调
    NSLog(@"转码mp4回调--------%d",eventRec);
    if (g_recordCallback) {
        g_recordCallback((AVRecordEvent)eventRec, lData);
    }
}

- (void)ac_startDecH264FileWithPort:(NSInteger)port isRandom:(int)isRandom filePath:(NSString*)path{
    AV_StartDecH264File(_nPort, path.UTF8String,isRandom,(void *)playCallback,0);
}

- (void)ac_captureMP4WithOrgFileName:(NSString *)orgFileName destinaFileName:(NSString *)destinaFileName startTime:(int)startTime totalTime:(int)totalTime{
    //设置参数
    long currentPort = AV_GetPort();
    AV_SetH264FileRecParam(currentPort,1 , destinaFileName.UTF8String, startTime, totalTime);
    AV_StartDecH264File(currentPort, orgFileName.UTF8String, 0, (void *)capturePlayCallBack, 0);
}


static void capturePlayCallBack(long nPort, AVRecEvent eventRec, long lData, long lUserParam){
    if (eventRec == AVRetPlayRecRecordFinish) {
        //录制结束
        NSLog(@"录制完成，结束录制-------------------");
        AV_StopDecH264File(nPort);
    }
}

static void playCallback(long nPort, AVRecEvent eventRec, long lData, long lUserParam){
    if( eventRec == AVRetPlayRecFinish ){
        AV_StopDecH264File(aSelf.nPort);
        g_decodedDataCallback[aSelf.nPort](nil);
        return ;
    }
}

- (void)ac_sendSDCardCommandWithType:(SDCommandType)type destinaFileName:(NSString *)destinaFileName callBack:(RecordCallbackFunc)callbackFunc{
    int commandType;
    commandType = type;
    AV_SetFileName(_nPort, commandType, destinaFileName.UTF8String, (void*)SDRecordCallBackFunc, 0);
}

static void SDRecordCallBackFunc(long nPort, AVRecEvent eventRec, long lData, long lUserParam){
    //回调了播放时间
    if (eventRec == AVRetPlayRecTime) {
        //SD卡播放进度回调 设置时间类型是12
        NSDictionary *notifyData = @{@"nPort" : [NSNumber numberWithLong:0],
                                     @"eventRec" : [NSNumber numberWithInt:12],
                                     @"lData" : [NSNumber numberWithLong:lData],
                                     @"lUserParam" : [NSNumber numberWithLong:0],
                                     @"Decode" : aSelf,
                                     };
        [[NSNotificationCenter defaultCenter] postNotificationName:PlayStatusNotification object:nil userInfo:notifyData];
    }
    
    //    NSLog(@"111111");
}



- (void)ac_stopDecH264FileWithPort:(NSInteger)port{
    AV_StopDecH264File(port);
    AV_FreePort(port);
}

- (bool)ac_stopRecord {
    return AV_StopRec(_nPort)==AVErrSuccess;
}

- (bool)ac_stopDecode{
    return AV_Stop(_nPort)==AVErrSuccess;
}

- (bool)ac_stopDecodeH264{
    bool issuccess = AV_StopDecH264File(_nPort)==AVErrSuccess;
    AV_FreePort(_nPort);
    return issuccess;
}

- (bool)ac_startDecodeWithCallBack:(DecodedFrameCallback)frameCallback {
    return 0;
}

- (void)ac_encodePCM2G711AWithSample:(int)sample
                             channel:(int)channel
                            inputBuf:(unsigned  char *)pInData
                            inputLen:(int)nInLen
                              outBuf:(unsigned  char **)pOutData
                              outLen:(int *)nOutLen{
    AV_EncodePCM2G711A( sample, channel, pInData,  nInLen, pOutData, nOutLen);
}


- (void)seekToTime:(int)seekTime photoPath:(NSString *)photoPath{
    if (photoPath) {
        AV_RecSeek(_nPort, seekTime, photoPath.UTF8String);
    }
    else{
        AV_RecSeek(_nPort, seekTime, nullptr);
    }
}

- (void)ac_uninit {
    AV_Stop(_nPort);
    AV_FreePort(_nPort);
}

-(void)ac_setDecodedDataTypeWithPort:(NSInteger)port type:(DecodedDataType)type {
    
    AV_SetDecType(_nPort, type);
}

@end




@implementation ACSeekVideoDecoder

- (instancetype)init{
    if (self = [super init]) {
        _nPort = -1;
        AV_Init(0, NULL);
    }
    return self;
}

- (void)initVideoDecoderWithDataCallBack:(FrameCallbackBlock)frameCallback {
    seekSelf = self;
    _nPort = AV_GetPort();
    if ( _nPort >= 0) {
    }
    AV_Play(_nPort, 0, (void *)SeekDecCallBack, 0);
}

static long  SeekDecCallBack(PSTDecFrameParam stDecParam, void *pUserParam)
{
    //    DecodedFrameParam *param = (DecodedFrameParam*)stDecParam;
    //    if (!stDecParam) {
    //        AV_StopDecH264File(aSelf.nPort);
    //        g_decodedDataCallback[aSelf.nPort](param);
    //        return 0;
    //    }
    //    if (stDecParam && g_decodedDataCallback[stDecParam->nPort]) {
    //        g_decodedDataCallback[stDecParam->nPort](param);
    //    }
    return 0;
}


- (bool)ac_captureWithPort:(int)port filePath:(NSString *)filePath {
    return AV_Capture(_nPort, [filePath UTF8String])==AVErrSuccess;
}

- (void)ac_startDecH264FileWithPort:(NSInteger)port filePath:(NSString*)path{
    AV_StartDecH264File(_nPort, path.UTF8String,0,(void *)playSeekCallback,0);
}

static void playSeekCallback(long nPort, AVRecEvent eventRec, long lData, long lUserParam){
    if (!seekSelf) {
        return;
    }
    
    NSDictionary *notifyData = @{@"nPort" : [NSNumber numberWithLong:nPort],
                                 @"eventRec" : [NSNumber numberWithInt:eventRec],
                                 @"lData" : [NSNumber numberWithLong:lData],
                                 @"lUserParam" : [NSNumber numberWithLong:lUserParam],
                                 @"Decode" : seekSelf,
                                 };
    [[NSNotificationCenter defaultCenter] postNotificationName:PlayStatusNotification object:nil userInfo:notifyData];
}

- (void)ac_stopDecH264FileWithPort:(NSInteger)port{
    AV_StopDecH264File(port);
    AV_Stop(port);
    AV_FreePort(port);
    _nPort = -1;
}

- (bool)ac_stopRecord {
    return AV_StopRec(_nPort)==AVErrSuccess;
}

- (bool)ac_stopDecode{
    if (_nPort >= 0) {
        AV_StopDecH264File(_nPort);
        AV_Stop(_nPort);
        AV_FreePort(_nPort);
        _nPort = -1;
        return AV_Stop(_nPort)==AVErrSuccess;
    }
    else{
        return false;
    }
    
}


- (void)seekToTime:(int)seekTime photoPath:(NSString *)photoPath{
    if (photoPath) {
        AV_RecSeek(_nPort, seekTime, photoPath.UTF8String);
    }
    else{
        AV_RecSeek(_nPort, seekTime, nullptr);
    }
}

- (void)ac_uninit {
    AV_Stop(_nPort);
    AV_FreePort(_nPort);
    AV_Stop(_nPort);
    _nPort = -1;
}


@end

@implementation ACCloudVideoDecoder


- (instancetype)init{
    if (self = [super init]) {
        _nPort = -1;
    }
    return self;
}

- (void)initVideoDecoderWithDataCallBack:(FrameCallbackBlock)frameCallback {
    cloudSelf = self;
    AV_Init(0, NULL);
    _nPort = AV_GetPort();
    if ( _nPort >= 0) {
        cloud_decodedDataCallback[_nPort] = frameCallback;
    }
    AV_Play(_nPort, 0, (void *)CloudDecCallBack, 0);
}

- (void)ac_putFrameWithPort:(int)port Buffer:(unsigned char *)buf length:(int)len {
    AV_PutFrame(_nPort, buf, len);
}


- (bool)ac_captureWithPort:(int)port filePath:(NSString *)filePath {
    return AV_Capture(_nPort, [filePath UTF8String])==AVErrSuccess;
}


//nDecType,解码后的数据类型 0 - YUV420, 1 - 32位的RGB, 2 - 24位的RGB
static long  CloudDecCallBack(PSTDecFrameParam stDecParam, void *pUserParam)
{
    DecodedFrameParam *param = (DecodedFrameParam*)stDecParam;
    if (!stDecParam) {
        cloud_decodedDataCallback[cloudSelf.nPort](param);
        return 0;
    }
    if (stDecParam && cloud_decodedDataCallback[stDecParam->nPort]) {
        cloud_decodedDataCallback[stDecParam->nPort](param);
    }
    return 0;
}


- (void)ac_startDecH264FileWithPort:(NSInteger)port filePath:(NSString*)path{
    AV_StartDecH264File(_nPort, path.UTF8String,0,(void *)cloudSeekCallback,0);
}


static void cloudSeekCallback(long nPort, AVRecEvent eventRec, long lData, long lUserParam){
    if (!cloudSelf) {
        return;
    }
    NSDictionary *notifyData = @{@"nPort" : [NSNumber numberWithLong:nPort],
                                 @"eventRec" : [NSNumber numberWithInt:eventRec],
                                 @"lData" : [NSNumber numberWithLong:lData],
                                 @"lUserParam" : [NSNumber numberWithLong:lUserParam],
                                 @"Decode" : cloudSelf,
                                 };
    [[NSNotificationCenter defaultCenter] postNotificationName:PlayStatusNotification object:nil userInfo:notifyData];
}

- (void)ac_stopDecH264FileWithPort:(NSInteger)port{
    if (_nPort >= 0) {
        AV_StopDecH264File(port);
        AV_Stop(port);
        AV_FreePort(port);
        _nPort = -1;
    }
}


- (bool)ac_stopDecode{
    if (_nPort >= 0) {
        bool isSuc = AV_StopDecH264File(_nPort)==AVErrSuccess;
        AV_Stop(_nPort);
        AV_FreePort(_nPort);
        _nPort = -1;
        return  isSuc;
    }
    else{
        return false;
    }
}

- (void)ac_stopPort{
    AV_Stop(_nPort);
    AV_FreePort(_nPort);
    _nPort = -1;
    
}


- (void)seekToTime:(int)seekTime photoPath:(NSString *)photoPath{
    if (photoPath) {
        AV_RecSeek(_nPort, seekTime, photoPath.UTF8String);
    }
    else{
        AV_RecSeek(_nPort, seekTime, nullptr);
    }
}

- (void)ac_uninit {
    AV_Stop(_nPort);
    AV_FreePort(_nPort);
    _nPort = -1;
}

-(void)ac_setDecodedDataTypeWithPort:(NSInteger)port type:(DecodedDataType)type {
    AV_SetDecType(_nPort, type);
}

- (void)ac_pause:(BOOL)isPause{
    AV_RecPause(_nPort, isPause);
}

@end


@implementation ACCaptureVideoDecoder

- (void)initVideoDecoderWithDataCallBack:(FrameCallbackBlock)frameCallback {
    AV_Init(0,NULL);
    _nPort = AV_GetPort();
    if ( _nPort >= 0) {
    }
    AV_Play(_nPort, 0, (void *)CaptureDecCallBack, 0);
}


static long  CaptureDecCallBack(PSTDecFrameParam stDecParam, void *pUserParam)
{
    DecodedFrameParam *param = (DecodedFrameParam*)stDecParam;
    if (!stDecParam) {
        //        AV_StopDecH264File(aSelf.nPort);
        g_decodedDataCallback[aSelf.nPort](param);
        return 0;
    }
    if (stDecParam && g_decodedDataCallback[stDecParam->nPort]) {
        g_decodedDataCallback[stDecParam->nPort](param);
    }
    return 0;
}


- (void)ac_startDecH264FileWithPort:(NSInteger)port filePath:(NSString*)path{
    AV_StartDecH264File(_nPort, path.UTF8String,0,(void *)capturePlayCallback,0);
}

- (void)ac_captureMP4WithOrgFileName:(NSString *)orgFileName destinaFileName:(NSString *)destinaFileName startTime:(int)startTime totalTime:(int)totalTime{
    //设置参数
    AV_SetH264FileRecParam(_nPort,1 , destinaFileName.UTF8String, startTime, totalTime);
    AV_StartDecH264File(_nPort, orgFileName.UTF8String, 0, (void *)captureCompleteCallBack, 0);
}


static void capturePlayCallback(long nPort, AVRecEvent eventRec, long lData, long lUserParam){
}

static void captureCompleteCallBack(long nPort, AVRecEvent eventRec, long lData, long lUserParam){
    if (eventRec == AVRetPlayRecRecordFinish) {
        NSDictionary *notifyData = @{@"result":[NSNumber numberWithInt:1]
                                     };
        [[NSNotificationCenter defaultCenter] postNotificationName:ConvertMP4Notification object:nil userInfo:notifyData];
        //录制结束
        NSLog(@"录制完成，结束录制-------------------");
        AV_StopDecH264File(nPort);
        AV_Stop(nPort);
        AV_FreePort(nPort);
    }
}

- (void)ac_uninit {
    AV_Stop(_nPort);
    AV_FreePort(_nPort);
    _nPort = -1;
}

@end
