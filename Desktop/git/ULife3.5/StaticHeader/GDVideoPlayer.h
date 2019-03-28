//
//  GDVideoPlayer.h
//  GDVideoPlayer
//
//  Created by admin on 15/9/1.
//  Copyright (c) 2015年 goscamtest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MediaHeader.h"
#import "GDPlayerView.h"
#import "GDVideoDecoder.h"

/**
 *  返回提示
 *
 *  @param result result < 0,命令请求或者发送失败,result=0,命令请求或者发送成功
 *  @param error  返回错误信息
 */
typedef void(^BlockResultError)(int result,NSError *error);
typedef void(^RecordResultBlock)(int result,int count,NSError *error);


@protocol GDVideoPlayerDelegate <NSObject>
/**
 * 获取对话语音的状态,如果为True,表示可以发送对讲语音解码数据了,当对讲完成后,进行解码会调用这个方法
 *
 *  @param state    表示对讲完成状态，state为YES,表示对讲语音解码成功，state,表示对讲语音解码失败
 *  @param filePath 传入对讲语音的文件
 */
-(void)SendVoiceRecoderData:(BOOL)state
                andFilePath:(NSString *)filePath;



/**
 *  录像返回结果
 *
 *  @param videoPath   返回录像的文件路径
 *  @param error       如果拍照失败，返回错误值，否认为NULL
 *  @param contextInfo <#contextInfo description#>
 */
- (void)video:(NSString *)videoPath
didFinishSavingWithError:(NSError *)error
  contextInfo:(void *)contextInfo;



/**
 *  拍照返回结果,保存到自定义到路径
 *
 *  @param imagePath   返回拍照的文件路径
 *  @param error       如果拍照失败，返回错误值，否认为NULL;
 *  @param contextInfo <#contextInfo description#>
 */
- (void)image:(NSString *)imagePath
didFinishSavingWithError:(NSError *)error
  contextInfo:(void *)contextInfo;


/**
 *  拍照保存到相册
 *
 *  @param image       <#image description#>
 *  @param error       <#error description#>
 *  @param contextInfo <#contextInfo description#>
 */
- (void)SavePhotoImage:(UIImage *)image
didFinishSavingWithError:(NSError *)error
           contextInfo:(void *)contextInfo;
@required


@end;





@interface GDVideoPlayer : NSObject 
{
   
}

@property(nonatomic,weak)id<GDVideoPlayerDelegate>delegate;

/** 最后一帧封面图片保存路径 */
@property (nonatomic, copy) NSString *coverPath;

@property(nonatomic,strong)GDVideoDecoder *decoder;


+ (GDVideoPlayer *)sharedInstance;



/**
 * //传入一个view和delegate
 *
 *  @param playerView 传入一个view,view中不能嵌套子类的其他控件,因为一开始就要对视频的view进行removeFromSuperview操作
 *  @param delegate   关联一个代理
 */
-(void)initWithViewAndDelegate:(UIView *)playerView
                      Delegate:(id<GDVideoPlayerDelegate>)delegate
                   andDeviceID:(NSString *)deviceID
            andWithdoubleScale:(BOOL )isdoubleScale;

// NVR 设备使用
-(void)initWithViewAndDelegate:(UIView *)playerView
                      Delegate:(id<GDVideoPlayerDelegate>)delegate
                   andDeviceID:(NSString *)deviceID
            andWithdoubleScale:(BOOL )isdoubleScale
               nvrPositionType:(PositionType)nvrPositionType;

/**
 *  停止所有的视频音频语音对讲功能
 *
 *  @return true 成功
 */
- (BOOL)stopPlay;


- (void)startDecode;

/**
 *  屏幕切换时调用
 *
 *  @param view 播放的视频view
 */
-(void)setPlayerView:(UIView*)view;



/**
 *  屏幕切换时调用
 *
 *  调整屏幕View的Frame
 */
- (void)resizePlayViewFrame:(CGRect)playViewFrame;

-(void)nvrUpdatePlayerViewSize:(CGSize)playViewSize;


-(bool)resumeDecode;

-(bool)pauseDecode;


/**
 *  获取视频播放数据
 *
 *  @param buffer    缓冲区
 *  @param len       缓冲区大小
 *  @param ts        时间间隔
 *  @param framNO    视频编码
 *  @param frameRate 视频波特兰
 *  @param iFrame    视频I帧
 *
 *  @return true
 */
- (BOOL)AddVideoFrame:(unsigned char *)buffer
                  len:(int)len
                   ts:(int)ts
               framNo:(unsigned int)framNO
            frameRate: (int)frameRate
               iFrame:(BOOL) iFrame
         andDeviceUid:(NSString *)UID;

/**
 *  获取音频数据
 *
 *  @param buffer 缓冲区
 *  @param len    缓冲区长度
 *  @param frameType 音频帧类型 AAC/G711
 *
 *  @return true
 */
-(BOOL)AddAudioFrame:(Byte *)buffer
                 len:(int)len
           frameType:(int)frameType;

/**
 *
 * 进行对讲操作要实现三个方法
 * 1.startRecord
 * 2.stopRecord
*  3.SendVoiceRecoderData，获取对讲语音的解码成功或者失败状态以及对讲语音文件路径包；
 */

/**
 *  开始对讲功能
 *
 *  @return
 */
-(BOOL)startRecord;

/**
 *  停止对讲功能
 *
 *  @return 
 */
-(BOOL)stopRecord;

/**
 *  开始音频操作
 */
-(void)startVoice;

/**
 *  结束音频操作
 */
-(void)stopVoice;

/**
 *  拍照
 *
 *  @return YES
 */
//-(BOOL)screenshot:(NSString *)path andBlockRequst:(BlockResultError)block;

/**
 *  拍照
 *
 *  @param savePhoto 是否保存到相册，YES表示保持相册，不需要输入路径，NO,表示保存到path中
 *  @param path      如果保存到相册，不需要输入，否则需要输入保存陆军
 *  @param block     返回结果
 *
 *  @return <#return value description#>
 */
-(BOOL)screenshot:(BOOL)isSavePhoto
          andPath:(NSString *)path
   andBlockRequst:(BlockResultError)block;



/**
 *  开始录像,
 *  @param enabled 如果为YES,表示声音和图像都有，如果为NO,表示只有图片,没有声音，默然为NO
 *  @return YES
 */
-(BOOL)recordStartWithAudioEnabled:(BOOL)enabled
                      andSavePhoto:(BOOL)isSavePhoto
                           andPath:(NSString *)path
                    andBlockRequst:(RecordResultBlock)block;

/*!
 @method
 @abstract 结束录像
 @discussion
 @param enabled 是否同时录制音频. (目前还未实现)
 @result BOOL 如果录像未开始则返回NO. 否则返回YES.
 */
-(BOOL)recordStop;

- (void) render: (KxVideoFrame *) frame;

- (void)initOpenAL;

- (void)openAudioWithBuffer:(unsigned char *)pBuffer length:(int)pLength;

@end
