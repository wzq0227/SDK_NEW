//
//  WiFiSettingConnectWiFiVC.h
//  ULife3.5
//
//  Created by zhuochuncai on 13/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"

@interface WiFiSettingConnectWiFiVC : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *ssidTxtField;

@property (weak, nonatomic) IBOutlet UITextField *pwdTxtField;

@property (weak, nonatomic) IBOutlet UIButton *nextBtn;



@property (weak, nonatomic) IBOutlet UILabel *pressSetBtnLabel;

@property (weak, nonatomic) IBOutlet UILabel *confirmConnectedLabel;

@property (weak, nonatomic) IBOutlet UILabel *devMoveToRouterLabel;

@property (weak, nonatomic) IBOutlet UIButton *hideOrShowPwdBtn;


@property(nonatomic,strong)DeviceDataModel *model;
@end
