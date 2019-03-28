//
//  RmRecorder.h
//  RingtonesManager
//
//  Created by yuanx on 14-2-14.
//  Copyright (c) 2014年 yuanx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef void(^BlockSuccess)(BOOL flag);

@interface RmRecorder : NSObject<AVAudioRecorderDelegate>
@property(nonatomic,copy)BlockSuccess blockSuccess;
@property(nonatomic, readonly)BOOL isRecording;
@property(nonatomic,readonly)BOOL   isSuccess;
@property(nonatomic, assign)id delegate;


/**
 是否直接编码为AAC,默认是，否则还会转为G711
 */
@property (assign, nonatomic)  BOOL encodedToAACDirectly;

-(BOOL)recordStartAtPath:(NSString*)path overwriteIfNeeded:(BOOL)overwrite error:(NSError**)error BlockSuccess:(BlockSuccess)blockSucess;
-(void)recordStop;
//-(void)showVoiceHudInView:(UIView*)view;
-(void)removeVoiceHud;
@end



@protocol RmRecorderDelegate <NSObject>
-(void)onRmRecorderDelegate:(RmRecorder*)rmRecoder curTime:(double)curTime;

@end
