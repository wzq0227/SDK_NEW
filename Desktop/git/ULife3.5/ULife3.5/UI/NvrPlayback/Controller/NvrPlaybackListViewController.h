//
//  NvrPlaybackListViewController.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/21.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"


@interface NvrPlaybackListViewController : UIViewController

/** 搜索的 NVR 设备 ID*/
@property (nonatomic, copy) NSString *nvrDeviceId;

/** 搜索的日期 */
@property (nonatomic, copy) NSString *searchDate;

/** 搜索的起始时间 */
@property (nonatomic, copy) NSString *startTime;

/** 搜索的结束时间*/
@property (nonatomic, copy) NSString *endTime;

/* 搜索的类型 */
@property (nonatomic, assign) uint32_t videoType;

/* 搜索的频道 */
@property (nonatomic, assign) uint32_t channelMask;

/** 设备数据模型 */
@property (nonatomic, strong) DeviceDataModel *devDataModel;

@end
