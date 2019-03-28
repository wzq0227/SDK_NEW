//
//  ACVideoDecoder.h
//  ACVideoDecoder
//
//  Created by zhuochuncai on 19/1/17.
//  Copyright © 2017年 zhuochuncai. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef struct DecodedFrameParam
{
    int                nPort;                    // Ω‚¬ÎÕ®µ¿∫≈
    int                nDecType;                // Ω‚¬Î∫Ûµƒ ˝æ›¿‡–Õ 0 - YUV420, 1 - 32ŒªµƒRGB, 2 - 24ŒªµƒRGB, 3 - 16ŒªµƒRGB(565), 4 “Ù∆µPCM.À´…˘µ¿16Œª,32K
    unsigned char*    lpBuf;                    // Ω‚¬Î∫Ûµƒ ˝æ›
    int                lSize;                    // Ω‚¬Î∫Û ˝æ›≥§
    int                lWidth;                    //  ”∆µøÌ
    int                lHeight;                //  ”∆µ∏ﬂ
    int                nSampleRate;            // “Ù∆µ≤…—˘¬
    int                nAudioChannels;            // “Ù∆µÕ®µ¿ ˝
    
} *PDecodedFrameParam;

typedef NS_ENUM(NSUInteger, DecodedDataType) {
    DecodedDataTypeYUV,
    DecodedDataTypeRGB32,
    DecodedDataTypeRGB24,
    DecodedDataTypeRGB16,
};

typedef NS_ENUM(NSUInteger,AVRecordEvent) {
    
    AVRecordEventOpenSuccess        = 0,
    AVRecordEventOpenErr            = 1,
    AVRecordEventRetTime            = 2,
    AVRecordEventTimeEnd            = 3,
    AVRetPlayRecordTime
};

typedef void(^FrameCallbackBlock)(PDecodedFrameParam frameParam);
typedef long(*DecodedFrameCallback)(PDecodedFrameParam frameParam);
typedef long(*RecordCallbackFunc)(AVRecordEvent eventRec, long lData);


@interface ACVideoDecoder : NSObject

@property(nonatomic,assign)NSInteger nPort;

- (void)initVideoDecoderWithDataCallBack:(FrameCallbackBlock)frameCallback;

- (void)ac_putFrameWithPort:(int)port Buffer:(unsigned char *)buf length:(int)len;

- (bool)ac_captureWithPort:(int)port filePath:(NSString*)filePath;

- (bool)ac_startRecordWithPort:(NSInteger)port filePath:(NSString *)filePath audioType:(int)audioType callBack:(RecordCallbackFunc)callbackFunc;

- (bool)ac_stopRecord;

- (bool)ac_stopDecode;

- (bool)ac_stopDecodeH264;

- (bool)ac_startDecodeWithCallBack:(DecodedFrameCallback)frameCallback;

- (void)ac_uninit;

- (void)ac_setDecodedDataTypeWithPort:(NSInteger)port type:(DecodedDataType)type;


- (void)ac_encodePCM2G711AWithSample:(int)sample
                             channel:(int)channel
                            inputBuf:(unsigned  char *)pInData
                            inputLen:(int)nInLen
                              outBuf:(unsigned  char **)pOutData
                              outLen:(int *)nOutLen;

- (void)ac_startDecH264FileWithPort:(NSInteger)port isRandom:(int)isRandom filePath:(NSString*)path;

- (void)ac_stopDecH264FileWithPort:(NSInteger)port;

//播放进度控制--快进到指定时间
//如果传了图片路径的话会截取一张图
- (void)seekToTime:(int)seekTime photoPath:(NSString *)photoPath;

//裸流数据裁剪成mp4
- (void)ac_captureMP4WithOrgFileName:(NSString *)orgFileName destinaFileName:(NSString *)destinaFileName startTime:(int)startTime totalTime:(int)totalTime;

@end

//云存储seekVideoDecoder
@interface ACSeekVideoDecoder : NSObject

@property(nonatomic,assign)NSInteger nPort;

- (void)initVideoDecoderWithDataCallBack:(FrameCallbackBlock)frameCallback;

- (void)ac_putFrameWithPort:(int)port Buffer:(unsigned char *)buf length:(int)len;

- (bool)ac_captureWithPort:(int)port filePath:(NSString*)filePath;

- (bool)ac_startRecordWithPort:(NSInteger)port filePath:(NSString *)filePath audioType:(int)audioType callBack:(RecordCallbackFunc)callbackFunc;

- (bool)ac_stopRecord;

- (bool)ac_stopDecode;

- (bool)ac_startDecodeWithCallBack:(DecodedFrameCallback)frameCallback;

- (void)ac_uninit;

- (void)ac_setDecodedDataTypeWithPort:(NSInteger)port type:(DecodedDataType)type;


- (void)ac_encodePCM2G711AWithSample:(int)sample
                             channel:(int)channel
                            inputBuf:(unsigned  char *)pInData
                            inputLen:(int)nInLen
                              outBuf:(unsigned  char **)pOutData
                              outLen:(int *)nOutLen;

- (void)ac_startDecH264FileWithPort:(NSInteger)port filePath:(NSString*)path;

- (void)ac_stopDecH264FileWithPort:(NSInteger)port;

//播放进度控制--快进到指定时间
//如果传了图片路径的话会截取一张图
- (void)seekToTime:(int)seekTime photoPath:(NSString *)photoPath;

//裸流数据裁剪成mp4
- (void)ac_captureMP4WithOrgFileName:(NSString *)orgFileName destinaFileName:(NSString *)destinaFileName startTime:(int)startTime totalTime:(int)totalTime;

@end

//云存储播放decoder
@interface ACCloudVideoDecoder : NSObject

@property(nonatomic,assign)NSInteger nPort;

- (void)initVideoDecoderWithDataCallBack:(FrameCallbackBlock)frameCallback;

- (void)ac_putFrameWithPort:(int)port Buffer:(unsigned char *)buf length:(int)len;

- (bool)ac_captureWithPort:(int)port filePath:(NSString*)filePath;

- (bool)ac_stopDecode;

- (void)ac_uninit;

- (void)ac_setDecodedDataTypeWithPort:(NSInteger)port type:(DecodedDataType)type;


- (void)ac_startDecH264FileWithPort:(NSInteger)port filePath:(NSString*)path;

- (void)ac_stopDecH264FileWithPort:(NSInteger)port;

- (void)ac_stopPort;

- (void)ac_pause:(BOOL)isPause;

//播放进度控制--快进到指定时间
//如果传了图片路径的话会截取一张图
- (void)seekToTime:(int)seekTime photoPath:(NSString *)photoPath;

@end


//裁剪的Decoder
@interface ACCaptureVideoDecoder : NSObject

@property(nonatomic,assign)NSInteger nPort;

- (void)initVideoDecoderWithDataCallBack:(FrameCallbackBlock)frameCallback;

- (void)ac_uninit;

//裸流数据裁剪成mp4
- (void)ac_captureMP4WithOrgFileName:(NSString *)orgFileName destinaFileName:(NSString *)destinaFileName startTime:(int)startTime totalTime:(int)totalTime;

@end

