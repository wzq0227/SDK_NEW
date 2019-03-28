//
//  GradualBrightness.m
//  GradualBrightnessExample
//
//  Created by shenyuanluo on 2017/12/7.
//  Copyright © 2017年 shenyuanluo All rights reserved.
//

#import "GradualBrightness.h"

/** 亮度变换步幅 */
#define GRADUAL_STRIDE  0.005f

static CGFloat defaultBrightness;
static NSOperationQueue *changeBrightnessQueue;


@implementation GradualBrightness


+ (void)initialize
{
//    NSNotificationCenter *notifiCenter = [NSNotificationCenter defaultCenter];
//    [notifiCenter addObserver:self
//                     selector:@selector(sySaveDefaultBrightness)
//                         name:UIScreenBrightnessDidChangeNotification
//                       object:nil];
}


#pragma mark -- 保存默认亮度值
+ (void)sySaveDefaultBrightness
{
    defaultBrightness = [UIScreen mainScreen].brightness;
    NSLog(@"保存默认亮度: %f", defaultBrightness);
}


#pragma mark -- 逐步设置亮度
+ (void)syConfigBrightness:(CGFloat)value
{
    NSLog(@"变更亮度: %f", value);
    if (!changeBrightnessQueue)
    {
        changeBrightnessQueue = [[NSOperationQueue alloc] init];
        changeBrightnessQueue.maxConcurrentOperationCount = 1;
    }
    [changeBrightnessQueue cancelAllOperations];
    
    CGFloat brightness = [UIScreen mainScreen].brightness;
    CGFloat stride = GRADUAL_STRIDE * ((value > brightness) ? 1 : -1);
    NSInteger times = fabs((value - brightness) / GRADUAL_STRIDE);
    for (NSInteger i = 1; i <= times; i++)
    {
        [changeBrightnessQueue addOperationWithBlock:^{
            
            [NSThread sleepForTimeInterval:1 / 180.0];
            [UIScreen mainScreen].brightness = brightness + i * stride;
        }];
    }
}


#pragma mark -- 逐步恢复亮度
+ (void)syResumeBrightness
{
    NSLog(@"恢复默认亮度");
    [self syConfigBrightness:defaultBrightness];
}

@end
