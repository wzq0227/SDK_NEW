//
//  AcousticConfigConnectVC.h
//  ULife3.5
//
//  Created by Goscam on 2017/10/11.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InfoForAddingDevice.h"


#import "DeviceDataModel.h"
#import "EnlargeClickButton.h"

@interface AcousticConfigConnectVC : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *wifiSSIDTxt;

@property (weak, nonatomic) IBOutlet UITextField *passwordTxt;

@property (weak, nonatomic) IBOutlet UIButton *hideOrShowPWDBtn;

@property (weak, nonatomic) IBOutlet UILabel *frequencyLabel;

@property (weak, nonatomic) IBOutlet UIButton *configBtn;

@property (weak, nonatomic) IBOutlet EnlargeClickButton *btn12KHz;

@property (weak, nonatomic) IBOutlet EnlargeClickButton *Btn1KHz;

@property (weak, nonatomic) IBOutlet UIButton *jumpToSysWifiBtn;

@property (strong, nonatomic)  DeviceDataModel *devModel;

@property (strong, nonatomic)  InfoForAddingDevice *addDevInfo;

@end
