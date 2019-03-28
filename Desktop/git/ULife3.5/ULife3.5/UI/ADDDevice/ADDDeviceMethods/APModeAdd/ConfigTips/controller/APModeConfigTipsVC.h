//
//  APModeConfigTipsVC.h
//  ULife3.5
//
//  Created by Goscam on 2017/9/25.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"

@interface APModeConfigTipsVC : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *pressSetBtnTipsLabel;

@property (weak, nonatomic) IBOutlet UILabel *chooseWiFiTipsLabel;

@property (weak, nonatomic) IBOutlet UIButton *nextBtn;

@property (strong, nonatomic)  DeviceDataModel *devModel;

//@property (strong, nonatomic)  NSString *deviceID;
//
//@property (strong, nonatomic)  NSString *deviceName;
//
//@property (assign, nonatomic) SmartConnectStyle smartStyle;
@end
