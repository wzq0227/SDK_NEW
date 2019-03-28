//
//  VideoBuffer.m
//  U5800YCameraViewer
//
//  Created by Lasia on 12-10-25.
//  Copyright (c) 2012年 yuanx. All rights reserved.
//

#import "GDVideoBuffer.h"
#import "GDVideoHead.h"
/*
 循环存取, 存到有数据的位置先释放再存.
 为保证不会释放正在使用的内存, 要求写指针必须小于读指针2个位置.
 缓冲区大小也相应的大于2.
*/

@implementation GDVideoBuffer
{
    BOOL _isRegistChangeQualityNoti;
    BOOL _isChangeVideoQuality;
}


+(GDVideoBuffer *)sharedInstance
{
    static GDVideoBuffer *videoBuffer = nil;
    static dispatch_once_t token;
    if(videoBuffer == nil)
    {
        dispatch_once(&token,^{
            videoBuffer = [[GDVideoBuffer alloc] init];}
                      );
    }
    return videoBuffer;
}

#pragma mark -
-(id)init
{
    if (self = [super init])
    {
        _isRegistChangeQualityNoti = NO;
        _isChangeVideoQuality = NO;
        
        _nMaxLen = 1000;
        stopState = YES;
        if (_lock == nil)
        {
            _lock = [[NSLock alloc] init];
        }
        _dataArray = [[NSMutableArray alloc] init];
        _queue = dispatch_queue_create("ulife.videobuffer.queue", DISPATCH_QUEUE_SERIAL);
        //_audioqueue = dispatch_queue_create("ulife.videobuffer.audioqueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"changeVideoQualityNoti"
                                                  object:nil];
    _isRegistChangeQualityNoti = NO;
    _isChangeVideoQuality = NO;
    if (_queue)
    {
        _queue = nil;
    }
    NSLog(@"GDVideoBuffer dealloc");
}

-(void)setMaxLength:(int)maxLen
{
//    if (maxLen > 30)
//    {
//        maxLen = 30;
//    }
//    if (maxLen < 3)
//    {
//        maxLen = 3;
//    }
//    _nMaxLen = maxLen * 2;
}

-(int)getBufferLen
{
    if (_nMaxLen == 0)
    {
        return 0;
    }
    return _nMaxLen/2;
}


- (void)changeVideoQuality
{
    _isChangeVideoQuality = YES;
}
#pragma mark -- 将帧数据添加到缓存中
-(BOOL)addNewData:(Byte*)buf
              len:(int)len
               ts:(int)ts
           framNo:(int)framNO
        frameRate:(int)frameRate
           iFrame:(BOOL) iFrame
           andUID:(NSString *)UID
{
    if (![self.deviceId isEqualToString:UID])
    {
        return NO;
    }
    
    __block BOOL ret = NO;
    
    if (_queue == nil)
    {
        return NO;
    }
    
    
    
    
    
    
    if (NO == _isRegistChangeQualityNoti)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(changeVideoQuality)
                                                     name:@"changeVideoQualityNoti"
                                                   object:nil];
        _isRegistChangeQualityNoti = YES;
    }
    
    
    if (YES == _isChangeVideoQuality)
    {
        if (NO == iFrame)
        {
            NSLog(@"++++++++++++++++ 切换码流，丢掉 P 帧 ！++++++++++++++++");
            return NO;
        }
        else
        {
            NSLog(@"++++++++++++++++ 切换码流，遇到 I 帧 重新接收 ！++++++++++++++++");
            _isChangeVideoQuality = NO;
        }
    }
    
    if (stopState)
    {
        dispatch_sync(_queue, ^
        {
            @synchronized(self)
            {
                if ([_dataArray count] < _nMaxLen)
                {
                    @autoreleasepool
                    {
                        NSData* data = [[NSData alloc] initWithBytes:buf
                                                              length:len];
                        
                        GDVideoHead *head = [GDVideoHead initDataModel:data
                                                                   len:len
                                                                    ts:ts
                                                                framNo:framNO
                                                             frameRate:frameRate
                                                                iFrame:iFrame];
                        [_dataArray addObject:head];
                        ret = YES;
                    }
                }
                else
                {
                    NSLog(@"缓冲区已满,count = %@,UID = %d",UID,[_dataArray count]);
                    usleep(1000);
                }
            }
        });
    }
    
    return ret;
}


#pragma mark -- 从缓存中读取帧数据
- (BOOL)getData:(Byte **)buf
           len:(int *)len
            ts:(int *)ts
        framNo:(int *)framNO
     frameRate:(int *)frameRate
        iFrame:(BOOL*) iFrame    // frameRate: 帧率
{
    if (_queue == nil)
    {
        return NO;
    }
    
    __block BOOL ret = NO;
     if (stopState)
     {
        if (_queue)
        {
            dispatch_sync(_queue, ^
            {
                @synchronized(self)
                {
                    // 被锁住的代码
                    if ([_dataArray count] > 0)
                    {
                        @autoreleasepool
                        {
                            GDVideoHead *head = [_dataArray objectAtIndex:0];
                            if (head)
                            {
                                int length = (int)[head.data length];
                                *len = length;
                                *buf = malloc(length);
                                memcpy(*buf, [head.data bytes], length);
                                *ts = [head.tsNumber intValue];
                                *framNO = [head.framNONumber intValue];
                                *frameRate = [head.frameRateNumber intValue];
                                *iFrame = [head.iFrameNumber boolValue];
                                [_dataArray removeObjectAtIndex:0];

                                head = nil;
                                ret = YES;
                            }
                            else
                            {
                                *len = -1;
                                *buf = nil;
                                ret = NO;
                            }
                        }
                    }
                    else
                    {
//                        NSLog(@"Video buffer have no data!");
                        ret = NO;
                        usleep(1000);
                    }
                }
            });
        }
    }
    
    return ret;
}


#pragma mark -- 清空缓存
-(void)clearBuffer
{
    stopState = NO;
    _deviceId = nil;
    @synchronized(self)
    {
        NSLog(@"clearBuffer--1");
        if ([_dataArray count] > 0)
        {
            // 被锁住的代码
            dispatch_async(_queue, ^
            {
                NSLog(@"clearBuffer--2,[_dataArray count] = %d",[_dataArray count]);
                if ([_dataArray count] > 0)
                {
                    for (int i = 0; i < [_dataArray count]; i++)
                    {
                        @autoreleasepool
                        {
                            GDVideoHead *head = [_dataArray objectAtIndex:i];

                            head = nil;
                        }
                    }
                    [_dataArray removeAllObjects];
                    NSLog(@"clearBuffer--3");
                }
            });
        }
        else
        {
            NSLog(@"Video buffer have no data, not clear !");
        }
    }
}

@end
