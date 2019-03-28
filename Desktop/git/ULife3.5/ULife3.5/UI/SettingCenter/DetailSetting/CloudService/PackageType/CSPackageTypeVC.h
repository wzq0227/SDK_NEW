//
//  CSPackageTypeVC.h
//  ULife3.5
//
//  Created by Goscam on 2018/3/14.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"

@interface CSPackageTypeVC : UIViewController

@property (strong, nonatomic)  NSString *deviceId;

@property (strong, nonatomic)  DeviceDataModel *deviceModel;
@end
