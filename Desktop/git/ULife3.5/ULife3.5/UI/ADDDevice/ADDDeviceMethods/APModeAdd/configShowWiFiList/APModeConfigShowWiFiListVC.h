//
//  APModeConfigShowWiFiListVC.h
//  ULife3.5
//
//  Created by Goscam on 2017/9/25.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "lan_sdk.h"

@interface APModeConfigShowWiFiListVC : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *configNetworkLabel;

@property (weak, nonatomic) IBOutlet UITextField *wifiSSIDTxt;

@property (weak, nonatomic) IBOutlet UITextField *passwordTxt;

@property (weak, nonatomic) IBOutlet UIButton *hideOrShowPWDBtn;

@property (weak, nonatomic) IBOutlet UILabel *chooseNetworkLabel;

@property (weak, nonatomic) IBOutlet UITableView *wifiListTableView;

@property(nonatomic,assign)SWifiInfo wifiListInfo;

@end
