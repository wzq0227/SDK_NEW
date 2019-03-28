//
//  APModeConfigPreconnectVC.h
//  ULife3.5
//
//  Created by Goscam on 2017/9/25.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"
#import "InfoForAddingDevice.h"

@interface APModeConfigPreconnectVC : UIViewController


@property (weak, nonatomic) IBOutlet UITextField *wifiSSIDTxt;

@property (weak, nonatomic) IBOutlet UITextField *passwordTxt;

@property (weak, nonatomic) IBOutlet UIButton *hideOrShowPWDBtn;

@property (weak, nonatomic) IBOutlet UILabel *chooseNetworkLabel;


@property (weak, nonatomic) IBOutlet UIButton *nextBtn;


@property (weak, nonatomic) IBOutlet UIButton *jumpToSysWifiButton;

@property (strong, nonatomic)  DeviceDataModel *devModel;

@property (strong, nonatomic)  InfoForAddingDevice *addDevInfo;


@end
