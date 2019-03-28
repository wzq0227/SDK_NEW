//
//  PlayVideoViewController.h
//  goscamapp
//
//  Created by shenyuanluo on 2017/4/27.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NetAPISet.h"
#import "DeviceDataModel.h"
#import "DeviceDataModel.h"


@interface PlayVideoViewController : UIViewController

/** 设备TUTK平台UID */
@property (nonatomic, copy) NSString *deviceId;

/** 设备名称 */
@property (nonatomic, copy) NSString *deviceName;

/** 设备Model */
@property (nonatomic, strong)DeviceDataModel *deviceModel;

-(void)getLiveStreamData;


@end
