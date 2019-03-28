//
//  GDVideoHead.m
//  GDVideoPlayer
//
//  Created by admin on 15/9/4.
//  Copyright (c) 2015年 goscamtest. All rights reserved.
//

#import "GDVideoHead.h"

@implementation GDVideoHead
+(GDVideoHead *)initDataModel:(NSData *)data
                          len:(int)len
                           ts:(int)ts
                       framNo:(unsigned int)framNO
                    frameRate:(int)frameRate
                       iFrame:(BOOL)iFrame
{
    GDVideoHead *head = [[GDVideoHead alloc]init];
    head.data = data;
    head.lenNumber = [[NSNumber alloc]initWithInt:len];
    head.tsNumber= [[NSNumber alloc]initWithInt:ts];
    head.framNONumber = [[NSNumber alloc]initWithInt:framNO];
    head.frameRateNumber = [[NSNumber alloc]initWithInt:frameRate];
    head.iFrameNumber = [[NSNumber alloc]initWithBool:iFrame];
    return head;
}
@end




@implementation GDAudioHead
+(GDAudioHead *)initAudioDataModel:(NSData *)data
                               len:(int)len
                            framNo:(unsigned int)framNO
{
    GDAudioHead *audiohead = [[GDAudioHead alloc]init];
    audiohead.data = data;
    audiohead.lenNumber = [[NSNumber alloc]initWithInt:len];
    audiohead.framNONumber = [[NSNumber alloc]initWithInt:framNO];
    return audiohead;
}
@end
