//
//  GOSDeviceShareListVC.h
//  ULife3.5
//
//  Created by Goscam on 2018/5/18.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"

@interface GOSDeviceShareListVC : UIViewController

@property (strong, nonatomic)  NSString *devId;

@property (strong, nonatomic)  DeviceDataModel *devModel;

@end
