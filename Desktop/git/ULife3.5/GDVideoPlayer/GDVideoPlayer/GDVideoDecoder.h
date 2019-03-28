//
//  AVdataDecoder.h
//  U-life Player
//
//  Created by Yuan Xue on 12-8-7.
//  Copyright (c) 2012年 Goscam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "KKSimpleAUPlayer.h"
#import "MediaHeader.h"
#import "PCMPlayer.h"
#import "../../ACVideoDecoder/ACVideoDecoder/ACVideoDecoder.h"
#import "AULivePCMPlayer.h"

//#import "DeviceDataModel.h"



typedef void(^BlockResult)();
typedef void(^RecordBlock)(int result, int count);

@protocol  GDVideoDecoderDelegate<NSObject>

@required

-(void)GetVedioHeadAndts:(int)ts
                  framNo:(unsigned int)framNO
               frameRate:(int)frameRate
                  iFrame:(BOOL) iFrame;
@end


@protocol AGCProcessDelegate<NSObject>

@required
/* 全双工 pcm agc处理 */
-(NSData*)agcDataWithPcmData:(NSData*)data;
@end


@class WriteTxt;
@class GDPlayerView;

@interface GDVideoDecoder : NSObject
{
    NSThread* _popThread;
    __block BOOL _threadStarted;
    unsigned long m_lastFrameTimeStamp;
    long long m_lastFrameShowTime;
    long long m_timeInterval;
    
    long long m_lastTime;
    
    WriteTxt* f_writer;
    
    BOOL _recordWaitForIframe;
    int _nFps;
    
    id _screenshotTarget;
    SEL _screenshotSelector;
    
    id _recCallbackTarget;
    SEL _recCallbackSelector;
    
    NSLock* _lock;
    
    BOOL _getDataLoopIsBreak;
    dispatch_queue_t _queueReadBufferAndDecode;
    
    int _nScreenshotWidth, _nScreenshotHeight;
    NSData *_imgDataForScreenshot;
    
    int tsLast;
    int tsCurrent;
    
    int tsStart;
    int tsEnd;
}

-(id)initWithDeviceID:(NSString *)deviceId;


+(GDVideoDecoder *)sharedInstance;

@property (nonatomic, assign)  BOOL  full_duplex_flag;

@property (nonatomic, strong)  NSString * subDevId;

@property(nonatomic, retain)NSString* deviceId;
/** 最后一帧封面图片保存路径 */
@property (nonatomic, copy) NSString *coverPath;

/** 拍照图片保存路径 */
@property (nonatomic, copy) NSString *snapshotPath;

/** 录像视频保存路径 */
@property (nonatomic, copy) NSString *recordPath;

@property(nonatomic,strong)AULivePCMPlayer *pcmPlayer;

@property (nonatomic, assign) PositionType nvrPositionType;
@property (nonatomic, assign) BOOL isNvrDevice;
@property (nonatomic,weak) id<GDVideoDecoderDelegate> delegate;

@property (nonatomic, weak) id<AGCProcessDelegate>agcDelegate;

@property(nonatomic, strong)KKSimpleAUPlayer *audioPlayer;
-(void)setView:(GDPlayerView*)view;


// 解码开始.
-(void)startDecodeWithBuffer;


// 解码结束
-(void)stopDecode;


-(void)releaseDecoder;


-(void)setScreenshotTarget:(id)target selector:(SEL)selector;

-(void)setRecordCallbackTarget:(id)target selector:(SEL)selector;

// 拍照
-(BOOL)saveScreenshot:(NSString *)Path andSavePhoto:(BOOL)isSavePhoto;

// 录像

- (bool)startRecordWithResultBlock:(RecordBlock)block;

- (void)initlizeAudioFrameTypeToG711;

-(void)stopRecord;


-(void)configViewSize;


-(CGSize)getVideoSize;

- (void)startVoice;

- (void)stopVoice;

-(bool)resumeDecode;

-(bool)pauseDecode;

// 把接收到的视频帧数据添加到 videoBuffer 中
-(BOOL)AddVideoFrame:(unsigned char *)pContentBuffer
                 len:(int)len
                  ts:(int)ts
              framNo:(unsigned int)framNO
           frameRate:(int)frameRate
              iFrame:(BOOL) iFrame
              andUid:(NSString *)UID;

- (void)decodeAudioFrameWithBuffer:(unsigned char *)pBuf length:(int)len frameType:(int)frameType;

- (void)encodePCM2G711AWithSample:(int)sample
                          channel:(int)channel
                         inputBuf:(unsigned  char *)pInData
                         inputLen:(int)nInLen
                           outBuf:(unsigned  char **)pOutData
                           outLen:(int *)nOutLen;

//发送SD回放的请求
- (void)sendSDCardCommandWithType:(int)type destinaFileName:(NSString *)destinaFileName callBack:(RecordCallbackFunc)callbackFunc;

- (void)stopAcDecode;

- (void)startAcDecode;

- (void)ac_setBufferSize:(int)bufferSize nType:(int)nType;


@end



