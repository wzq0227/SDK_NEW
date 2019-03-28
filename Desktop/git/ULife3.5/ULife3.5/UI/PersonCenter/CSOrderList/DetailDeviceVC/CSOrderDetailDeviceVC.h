//
//  CSOrderDetailDeviceVC.h
//  ULife3.5
//
//  Created by Goscam on 2018/4/23.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSOrderDeviceListCellModel.h"
#import "DeviceDataModel.h"

@interface CSOrderDetailDeviceVC : UIViewController

@property (strong, nonatomic)  NSString *deviceId;

@property (assign, nonatomic)  CSOrderStatus status;

@property (strong, nonatomic)  CSOrderDeviceListCellModel *csOrderModel;

@property (strong, nonatomic)  DeviceDataModel *devDataModel;


@end
