//
//  GOSOpenGLESVCViewController.h
//  360
//
//  Created by zhuochuncai on 18/7/17.
//  Copyright © 2017年 Gospell. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "GOSPanoramaPlayer.h"
#import "GOSAudioRecorder.h"
#import "MediaManager.h"


/**
 初始化安装模式
 - InitialModeHorizontal: 吊装
 - InitialModeVertical: 侧装
 */
typedef NS_ENUM(NSUInteger, InitialMode) {
    InitialModeHorizontal = -1,
    InitialModeVertical = 5,
};

@protocol AudioRecorderDelegate <NSObject>

-(void)SendVoiceRecoderData:(BOOL)state andFilePath:(NSString *)filePath;

@end

/**
 录像回调

 @param result 开启录像结果 0 成功
 @param count 录像持续时间 >=0
 */
typedef void(^RecordCallbackBlock)(int result, int count);


/**
 截屏回调

 @param result 0 截屏并保持到手机成功
 */
typedef void(^SnapshotResultBlock)(int result);


@interface GOSOpenGLESVCViewController : GLKViewController

@property(nonatomic,strong)GOSPanoramaPlayer *player;


/**
 初始化模式：吊装，侧装；默认吊装
 */
@property (assign, nonatomic)  InitialMode initialMode;

/**
 是否开启巡航
 */
@property (assign, nonatomic)  int autoRotSig;


/** 最后一帧封面图片保存路径 */
@property (nonatomic, copy) NSString *coverPath;

/** 拍照图片保存路径 */
@property (nonatomic, copy) NSString *snapshotPath;

/** 录像视频保存路径 */
@property (nonatomic, copy) NSString *recordPath;

/**
 显示模式
 */
@property (assign, nonatomic)  int clickSig;
@property(nonatomic,strong)NSString *deviceId;

@property(nonatomic,strong)  NSData *yuvData;

@property(nonatomic,strong)NSMutableArray<NSData*> *bufferQueue;

@property (weak, nonatomic) id <AudioRecorderDelegate>audioDelegate;

-(void)AddAudioFrame:(Byte *)buffer
                 len:(int)len
              framNo:(unsigned int)framNO
            isIframe:(bool)iFrame
           timeStamp:(unsigned long long)ts;

-(void)AddVideoFrame:(unsigned char *)pContentBuffer
                 len:(int)len
                  ts:(int)ts
              framNo:(unsigned int)framNO
           frameRate:(int)frameRate
              iFrame:(BOOL) iFrame
        andDeviceUid:(NSString *)UID;

- (void)configPlayerWidth:(CGFloat)width height:(CGFloat)height;

- (void)updatePlayerViewFrame:(CGRect)frame;

- (void)startToDecH264FileWithPort:(NSInteger)port filePath:(NSString*)filePath;

- (void)stopDecH264File;

- (void)startRecordingWithStoragePath:(NSString*)filePath result:(RecordCallbackBlock)block;

- (void)stopRecording;

- (void)snapshotWithStoragePath:(NSString*)filePath result:(SnapshotResultBlock)block;

- (void)stopPlay;


/**
 开启对讲并开始录音
 */
- (void)startAudioRecording;


/**
 停止录音并发送对讲
 */
-(void)stopAudioRecording;

/**
 开启实时音频
 */
- (void)openLiveAudio;


/**
 关闭实时音频
 */
- (void)closeLiveAudio;
@end
