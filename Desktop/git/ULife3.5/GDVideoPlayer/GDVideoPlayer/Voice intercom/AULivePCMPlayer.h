//
//  AULivePCMPlayer.h
//  GDVideoPlayer
//
//  Created by Goscam on 2017/11/25.
//  Copyright © 2017年 goscamtest. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AULivePCMPlayer : NSObject


-(BOOL)start;
-(void)play:(NSData *)data;
-(void)stop;



/** 开发播放音频 */
- (void)startPlayPCM;


/** 停止播放音频 */
- (void)stopPlayPCM;

//继续播放音频
- (void)continuePlayPCM;

- (void)destroyPlayer;


/**
 添加数据

 @param buf 内容
 @param len 长度
 */
-(void)addNewData:(NSData*)buf len:(int)len;

@end
