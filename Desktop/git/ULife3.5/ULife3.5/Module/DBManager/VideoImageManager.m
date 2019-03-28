//
//  VideoImageManager.m
//  ULife3.5
//
//  Created by 广东省深圳市 on 2017/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "VideoImageManager.h"
#import "GDDeviceIcon.h"
#import "MediaManager.h"

@implementation VideoImageManager

+ (instancetype)manager{
    return [[self alloc]init];
}

- (UIImage *)getImageWithDeviceID:(NSString *)deviceID{
    deviceID = [deviceID substringFromIndex:8];
    
    UIImage *coverImage = [[MediaManager shareManager] coverWithDevId:deviceID
                                                             fileName:nil
                                                           deviceType:GosDeviceIPC
                                                             position:PositionMain];
//    UIImage *image;
//    [GDDeviceIcon selectImage:&image byDevId:deviceID];
    return coverImage;
}

@end
