//
//  CloudServicePaymentTypeVC.h
//  ULife3.5
//
//  Created by Goscam on 2017/9/13.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CloudServicePackageInfo.h"
#import "DeviceDataModel.h"
#import "WXApi.h"
#import "CSNetworkLib.h"

@interface CloudServicePaymentTypeVC : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *priceTableView;


@property (weak, nonatomic) IBOutlet UITableView *paymentTypeTableView;

@property (strong, nonatomic)  CSPackageInfo *packageInfo;

@property (assign, nonatomic)  int  packageCount;

@property (assign, nonatomic)  PackageValidTime packageValidTime;
/**
 套餐名：3天云存储单月包
 */
@property (strong, nonatomic)  NSString *packageName;

@property (strong, nonatomic)  NSString *deviceId;

@property (strong, nonatomic)  DeviceDataModel *deviceModel;

+ (instancetype)sharedInstance;

@end
