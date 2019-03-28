//
//  GradualBrightness.h
//  GradualBrightnessExample
//
//  Created by shenyuanluo on 2017/12/7.
//  Copyright © 2017年 shenyuanluo All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GradualBrightness : NSObject

/**
 保存默认亮度
 */
+ (void)sySaveDefaultBrightness;


/**
 逐步设置亮度
 
 @param brightness 目标亮度值
 */
+ (void)syConfigBrightness:(CGFloat)brightness;


/**
 逐步恢复亮度
 */
+ (void)syResumeBrightness;

@end
