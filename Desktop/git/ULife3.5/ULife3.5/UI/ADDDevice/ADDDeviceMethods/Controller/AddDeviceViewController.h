//
//  AddDeviceViewController.h
//  goscamapp
//
//  Created by goscam_sz on 17/4/21.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MediaHeader.h"
#import "AddDeviceStyleModel.h"
#import "DeviceDataModel.h"

@interface AddDeviceViewController : UIViewController
@property (strong, nonatomic) IBOutlet UITableView *myTableView;

@property (weak, nonatomic) IBOutlet UIImageView *addev_advertisingImageView;

@property (weak, nonatomic) IBOutlet UILabel *waitForAcousticAddVoiceTipLabel;


/** 门铃声波添加提示 顶部约束 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topMarginToTableViewOfLabel;

@property (nonatomic,copy) NSMutableArray * arr;

@property (nonatomic,copy) NSMutableArray * ImageArr;

//@property(nonatomic,strong) NSString *deviceID;
//
//@property(nonatomic,strong) NSString *devName;
//
//@property (nonatomic,assign) GosDeviceType devtype;
//
//@property (assign, nonatomic) SmartConnectStyle smartStyle;

@property (strong, nonatomic)  DeviceDataModel *devModel;

/**
 扫描二维码得到的设备类型
 */
@property (assign, nonatomic)  DeviceQRType devQRType;

@end
