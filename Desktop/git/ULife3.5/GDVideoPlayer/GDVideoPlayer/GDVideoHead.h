//
//  GDVideoHead.h
//  GDVideoPlayer
//
//  Created by admin on 15/9/4.
//  Copyright (c) 2015年 goscamtest. All rights reserved.
//

//framNo:(unsigned int)framNO frameRate:(int)frameRate iFrame:(BOOL) iFrame
#import <Foundation/Foundation.h>

// 视频帧头 Model
@interface GDVideoHead : NSObject

@property(readwrite,nonatomic,strong)NSData *data;
@property(readwrite,nonatomic,strong)NSNumber *lenNumber;
@property(readwrite,nonatomic,strong)NSNumber *tsNumber;
@property(readwrite,nonatomic,strong)NSNumber *framNONumber;
@property(readwrite,nonatomic,strong)NSNumber *frameRateNumber;
@property(readwrite,nonatomic,strong)NSNumber *iFrameNumber;

+(GDVideoHead *)initDataModel:(NSData *)data
                          len:(int)len
                           ts:(int)ts
                       framNo:(unsigned int)framNO
                    frameRate:(int)frameRate
                       iFrame:(BOOL)iFrame;
@end



// 音频帧头 Model
@interface GDAudioHead : NSObject

@property(readwrite,nonatomic,strong)NSData *data;
@property(readwrite,nonatomic,strong)NSNumber *lenNumber;
@property(readwrite,nonatomic,strong)NSNumber *framNONumber;


+(GDAudioHead *)initAudioDataModel:(NSData *)data
                               len:(int)len
                            framNo:(unsigned int)framNO;
@end
