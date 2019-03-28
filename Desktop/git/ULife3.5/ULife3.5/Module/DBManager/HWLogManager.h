//
//  HWLogManager.h
//  EChannel
//
//  Created by AnDong on 16/12/14.
//  Copyright © 2016年 HuaWei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HWLogManager : NSObject

/**
 记录日志，这是个简单日志系统自动上传日志
 */
- (void)logMessage:(NSString *)logMsg;

+ (instancetype) manager;

@end
