//
//  VideoBuffer.h
//  U5800YCameraViewer
//
//  Created by Lasia on 12-10-25.
//  Copyright (c) 2012年 yuanx. All rights reserved.
//

#import <Foundation/Foundation.h>

#define VIDEO_BUFFER_MAX_SIZE		300  //大于2帧

@interface GDVideoBuffer : NSObject
{
	int nReadPoint;		//读指针指向的位置
	int nWritePoint;	//写指针指向的位置
	
	BOOL waitForIframe; // 等待 I 帧
	NSLock* _lock;
    int _nBufferLen;    // buffer 长度
    dispatch_queue_t _queue;    // 存/取 帧数据队列
    int _nMaxLen;       // 最多缓存帧数量
    NSMutableArray* _dataArray; // 存放帧（头）
    BOOL stopState;
}
@property(nonatomic,strong)NSString *deviceId;


+ (GDVideoBuffer *)sharedInstance;


-(void)setMaxLength:(int)maxLen;


-(BOOL)addNewData:(Byte*)buf
              len:(int)len
               ts:(int)ts
           framNo:(int)framNO
        frameRate:(int)frameRate
           iFrame:(BOOL)iFrame
           andUID:(NSString *)UID;


-(int)getBufferLen;


-(BOOL)getData:(Byte**)buf
           len:(int*)len
            ts:(int*)ts
        framNo:(int*)framNO
     frameRate:(int*)frameRate
        iFrame:(BOOL*) iFrame;


//-(BOOL)getData:(Byte**)buf len:(int*)len;


-(void)clearBuffer;


@end
