//
//  ScanTwoViewController.h
//  UI——update
//
//  Created by goscam_sz on 16/6/30.
//  Copyright © 2016年 goscam_sz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ScanThreeViewController.h"
#import "AddDeviceStyleModel.h"

@interface ScanTwoViewController : UIViewController


@property(nonatomic,strong) NSString *wifiStr;
@property(nonatomic,strong) NSString *wifiPWD;
@property(nonatomic,strong) NSString *deviceID;
@property(nonatomic,strong) NSString *devName;
@property (nonatomic,assign) GosDeviceType deviceType;  //设备类型

@property(nonatomic,assign)scanType scanType;
@end
