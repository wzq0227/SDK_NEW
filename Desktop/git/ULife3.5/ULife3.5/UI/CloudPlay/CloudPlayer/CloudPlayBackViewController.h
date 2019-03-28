//
//  CloudPlayBackViewController.h
//  ULife3.5
//
//  Created by AnDong on 2018/3/17.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NetAPISet.h"
#import "DeviceDataModel.h"

@interface CloudPlayBackViewController : UIViewController

/** 设备TUTK平台UID */
@property (nonatomic, copy) NSString *deviceId;

/** 设备名称 */
@property (nonatomic, copy) NSString *deviceName;

/** 设备Model */
@property (nonatomic, strong)DeviceDataModel *deviceModel;

@property (assign, nonatomic)  NSTimeInterval alarmMsgTime;

/** 剪切视频方法 */
- (void)convertMP4WithStartValue:(NSInteger)startValue totalValue:(NSInteger)totalValue fileName:(NSString *)fileName;

@end
