//
//  KKSimplePlayer.h
//  GDVideoPlayer
//
//  Created by goscam on 16/3/15.
//  Copyright © 2016年 goscamtest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface KKSimpleAUPlayer : NSObject
- (void)play;
- (void)pause;
-(void)playWith:(char*)audioBuffer andBufferLen:(int)len;
@property (readonly, nonatomic) CFArrayRef iPodEQPresetsArray;
- (void)selectEQPreset:(NSInteger)value;
@end
