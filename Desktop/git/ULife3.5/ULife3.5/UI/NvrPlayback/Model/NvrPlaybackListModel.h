//
//  NvrPlaybackListModel.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/21.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NvrPlaybackListModel : NSObject  < NSCopying, NSMutableCopying >

/** 设备 ID */
@property (nonatomic, copy) NSString *deviceId;

/** 文件名（路径） */
@property (nonatomic, copy) NSString *fileName;

/** 文件起始时间(yyyy-MM-dd HH:mm:ss) */
@property (nonatomic, copy) NSString *startTime;

/** 文件结束时间(yyyy-MM-dd HH:mm:ss) */
@property (nonatomic, copy) NSString *endTime;

/** 文件总时长：毫秒 */
@property (nonatomic, assign) uint32_t length;

/** 文件总帧数 */
@property (nonatomic, assign) uint32_t frames;

/** 频道 */
@property (nonatomic, assign) uint16_t channelMask;

/** 文件类型 */
@property (nonatomic, assign) uint16_t recordType;

@end
