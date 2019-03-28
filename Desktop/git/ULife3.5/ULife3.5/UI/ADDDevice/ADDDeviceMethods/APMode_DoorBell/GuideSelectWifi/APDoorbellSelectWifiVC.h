//
//  APDoorbellSelectWifiVC.h
//  ULife3.5
//
//  Created by Goscam on 2017/12/5.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InfoForAddingDevice.h"

@interface APDoorbellSelectWifiVC : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *ssidTxt;

@property (weak, nonatomic) IBOutlet UITextField *pwdTxt;

@property (weak, nonatomic) IBOutlet UIButton *hideOrShowPwdBtn;


@property (weak, nonatomic) IBOutlet UILabel *chooseWiFiLabel;

@property (weak, nonatomic) IBOutlet UILabel *unsupport5GWifiLabel;

@property (weak, nonatomic) IBOutlet UITableView *wifiListTableView;


@property (strong, nonatomic)  InfoForAddingDevice *addDevInfo;


@end
