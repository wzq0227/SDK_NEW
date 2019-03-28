//
//  THCapture.h
//  ScreenCaptureViewTest
//
//  Created by wayne li on 11-8-24.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface GDCapture : NSObject{
    //video writing
	AVAssetWriter *videoWriter;
	AVAssetWriterInput *videoWriterInput;
	AVAssetWriterInputPixelBufferAdaptor *avAdaptor;
    
    //recording state
	BOOL           _recording;     //正在录制中
    BOOL           _writing;       //正在将帧写入文件
    BOOL           _startFlag;
	NSDate         *startedAt;     //录制的开始时间
    CGContextRef   context;        //绘制layer的context
    NSTimer        *timer;         //按帧率写屏的定时器
	
	BOOL			_isBusy;		//当次录像或合成在进行.不能进行下一次录像.
    
	BOOL			_audioIsOn;

    id _target;     //代理
	SEL _callback;
	
}


-(void)setRecordTarget:(id)target callback:(SEL)callback;

//开始录制
- (BOOL)startRecordingWithAudioEnabled:(BOOL)enabled andSavePhoto:(BOOL)isSavePhoto width:(int)width height:(int)height andPath:(NSString *)Path;
//结束录制
- (void)stopRecording;

-(void)videoAndAudioSynthetic:(id)target callback:(SEL)callback andSavePhoto:(BOOL)isSavePhoto andPath:(NSString *)Path;
//录制每一帧
- (void)drawFrame:(CGImageRef)image;

@end

