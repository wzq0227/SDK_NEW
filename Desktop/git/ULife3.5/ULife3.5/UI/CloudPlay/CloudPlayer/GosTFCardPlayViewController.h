//
//  GosTFCardPlayViewController.h
//  ULife3.5
//
//  Created by AnDong on 2019/1/2.
//  Copyright © 2019年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NetAPISet.h"
#import "DeviceDataModel.h"
#import "PushMessageModel.h"
@class GosTFCardViewController;

@interface GosTFCardPlayViewController : UIViewController

//子设备通道号
@property (nonatomic, assign)  int channel;

/** 设备TUTK平台UID */
@property (nonatomic, copy) NSString *deviceId;

/** 设备名称 */
@property (nonatomic, copy) NSString *deviceName;

/** 设备Model */
@property (nonatomic, strong)DeviceDataModel *deviceModel;

@property (assign, nonatomic)  NSTimeInterval alarmMsgTime;

@property (nonatomic, assign) __block long long startTime;
@property (nonatomic, assign) __block long long endTime;
@property (nonatomic, copy) NSString *saveFileName;

@property (nonatomic, strong) PushMessageModel *pushMsgModel;
@property (nonatomic, assign) NSTimeInterval pushTime;

@property (nonatomic, weak) GosTFCardViewController *targetVC;

-(void)getLiveStreamData;

//剪切视频方法
- (void)convertMP4WithStartValue:(NSInteger)startValue totalValue:(NSInteger)totalValue fileName:(NSString *)fileName;

@end
