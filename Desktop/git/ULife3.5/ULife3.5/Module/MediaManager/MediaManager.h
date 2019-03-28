//
//  MediaManager.h
//  MediaManager
//
//  Created by shenyuanluo on 2017/7/20.
//  Copyright © 2017年 goscam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MediaHeader.h"


@interface MediaFileModel : NSObject

/** 文件创建日期（格式：yyyy/MM/dd） */
@property (nonatomic, copy) NSString *createDate;

/** 文件创建时间（格式：HH:mm:ss） */
@property (nonatomic, copy) NSString *createTime;

/** 媒体文件名称 */
@property (nonatomic, copy) NSString *fileName;

/** 视频文件大小 */
@property (nonatomic, assign) unsigned long long fileSize;

/** 媒体文件路径 */
@property (nonatomic, copy) NSString *filePath;

/** 是否被选择（用于删除时） */
@property (nonatomic, assign, getter=isSelected) BOOL selected;


@end


@interface MediaManager : NSObject

+ (instancetype)shareManager;


/**
 获取媒体文件保存路径

 @param deviceId 设备 ID (暂用 TUTK 平台 ID)
 @param fileName 文件名，为空则使用默认名字（最后一帧图片：Cover；拍照：时间戳（yyyyMMddHHmmss）；录像：时间戳（yyyyMMddHHmmss））
 @param mediaType 文件类型，参见‘MediaType’
 @param deviceType 设备类型，参见‘DeviceType’
 @param position 画面位置，参见‘PositionType’
 @return 沙盒绝对路径
 */
- (NSString *)mediaPathWithDevId:(NSString *)deviceId
                        fileName:(NSString *)fileName
                       mediaType:(GosMediaType)mediaType
                      deviceType:(GosDeviceType)deviceType
                        position:(PositionType)position;


/**
 获取视频最后一帧图片

 @param deviceId 设备 ID (暂用 TUTK 平台 ID)
 @param fileName 文件名，为空则使用默认名字（最后一帧图片：Cover）
 @param deviceType 设备类型，参见‘DeviceType’
 @param position 画面位置，参见‘PositionType’
 @return 图片实例
 */
- (UIImage *)coverWithDevId:(NSString *)deviceId
                   fileName:(NSString *)fileName
                 deviceType:(GosDeviceType)deviceType
                   position:(PositionType)position;

/**
 获取媒体文件列表

 @param deviceId 设备 ID (暂用 TUTK 平台 ID)
 @param mediaType 媒体文件类型，参见‘MediaType’
 @param deviceType 设备类型，参见‘DeviceType’
 @param position 画面位置，参见‘PositionType’
 @return 文件列表
 */
- (NSMutableArray <MediaFileModel *>*)mediaArrayWithDevId:(NSString *)deviceId
                                                mediaType:(GosMediaType)mediaType
                                               deviceType:(GosDeviceType)deviceType
                                                 position:(PositionType)position;



@end
