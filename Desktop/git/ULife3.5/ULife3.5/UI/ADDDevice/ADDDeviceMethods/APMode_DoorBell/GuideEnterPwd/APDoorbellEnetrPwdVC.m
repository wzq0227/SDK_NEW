//
//  APDoorbellEnetrPwdVC.m
//  ULife3.5
//
//  Created by Goscam on 2017/12/5.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "APDoorbellEnetrPwdVC.h"
#import "ConfigurationWiFiViewController.h"

@interface APDoorbellEnetrPwdVC ()
{
    
}
//@property (strong, nonatomic)  NSString *

@end

@implementation APDoorbellEnetrPwdVC

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configUI];
}


- (void)configUI{
    NSString *titleStr = DPLocalizedString(@"APDoorbell_EnterPwd");
    self.enterPwdTitleLabel.text = [titleStr stringByReplacingOccurrencesOfString:@"%@" withString:_addDevInfo.devWifiName];
    self.checkPwdTipLabel.text = DPLocalizedString(@"APDoorbell_CheckPwd");
    [self.nextBtn setTitle:DPLocalizedString(@"ADDDevice_Next") forState:UIControlStateNormal];
    
    [self.nextBtn addTarget:self action:@selector(nextBtnAction:) forControlEvents: UIControlEventTouchUpInside];
}

- (void)nextBtnAction:(id)sender{
    
    if (_pwdTextField.text.length <8) {
        //少于8位
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"WiFi_length")];
        return;
    }
    
    if (_pwdTextField.text.length >64) {
        //大于64位
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"WiFi_Max_length")];
        return;
    }
    
    if (!_addDevInfo) {
        _addDevInfo = [InfoForAddingDevice new];
    }
    
    _addDevInfo.addDeviceMode                    = AddDeviceByAPDoorbell;
    _addDevInfo.devWifiPassWord                  = self.pwdTextField.text;
    _addDevInfo.devName                          = @"Camera";
    _addDevInfo.deviceType                       = GosDeviceIPC;
    
    ConfigurationWiFiViewController *vc = [ConfigurationWiFiViewController new];
    vc.addDevInfo  = self.addDevInfo;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
