//
//  GDVoiceRecorder.h
//  GDVideoPlayer
//
//  Created by admin on 15/9/7.
//  Copyright (c) 2015年 goscamtest. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GDVoiceDelegate <NSObject>
@end

@interface GDVoiceRecorder : NSObject

@property(nonatomic,weak)id<GDVoiceDelegate> delegage;
@property(nonatomic,assign)BOOL isCmdSuceess;
-(void)StartRecoder;
-(void)StopRecoder;

@property (assign, nonatomic)  BOOL encodedToAACDirectly;

@end
