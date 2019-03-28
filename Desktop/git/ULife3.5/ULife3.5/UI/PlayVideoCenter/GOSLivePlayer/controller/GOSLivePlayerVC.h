//
//  GOSLivePlayerVC.h
//  ULife3.5
//
//  Created by Goscam on 2017/11/24.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NetAPISet.h"
#import "DeviceDataModel.h"

@interface GOSLivePlayerVC : UIViewController

/** 设备TUTK平台UID */
@property (nonatomic, copy) NSString *deviceId;

/** 设备名称 */
@property (nonatomic, copy) NSString *deviceName;

/** 设备Model */
@property (nonatomic, strong)DeviceDataModel *deviceModel;

-(void)getLiveStreamData;

//剪切视频方法
- (void)convertMP4WithStartValue:(NSInteger)startValue totalValue:(NSInteger)totalValue fileName:(NSString *)fileName;

@end
