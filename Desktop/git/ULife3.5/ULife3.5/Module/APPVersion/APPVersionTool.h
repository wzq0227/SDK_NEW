//
//  APPVersionTool.h
//  ULife3.5
//
//  Created by 广东省深圳市 on 2017/8/4.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APPVersionTool : NSObject

/**
 检测版本
 */
- (void)checkVersion;


/**
 单例类
 */
+(instancetype)shareInstance;

@end
