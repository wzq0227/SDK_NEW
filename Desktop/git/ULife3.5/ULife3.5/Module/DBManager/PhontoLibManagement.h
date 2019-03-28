//
//  PhontoLibManagement.h
//  WiFi
//
//  Created by shenyuanluo on 2017/6/17.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

typedef void(^GetMediaBlock)(PHFetchResult *fetchResult);

@interface PhontoLibManagement : NSObject

+ (instancetype)shareManager;


/**
 保存图片/视频到相册（二者传其一值）

 @param image 图片
 @param videoPath 视频路径
 */
- (void)saveImage:(NSString *)imagePath
            video:(NSString *)videoPath;


/**
 获取自定义相册的媒体资源

 @param mediaBlock 媒体资源回调 Block（根据 ‘mediaType’ 区分是类型）
 */
- (void)getCustomAlbumMedia:(GetMediaBlock)mediaBlock;

@end
