//
//  VideoImageManager.h
//  ULife3.5
//
//  Created by 广东省深圳市 on 2017/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoImageManager : NSObject

+ (instancetype)manager;


/**
    获取视频最后一帧图片
 */
- (UIImage *)getImageWithDeviceID:(NSString *)deviceID;

@end
