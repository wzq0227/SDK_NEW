//
//  WiFiSettingConnectWiFiVC.m
//  ULife3.5
//
//  Created by zhuochuncai on 13/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "WiFiSettingConnectWiFiVC.h"
#import "ScanTwoViewController.h"
#import <SystemConfiguration/CaptiveNetwork.h>

@interface WiFiSettingConnectWiFiVC ()<UITextFieldDelegate>
@property(nonatomic,assign)BOOL pwdExposured;   //deafault No
@end

@implementation WiFiSettingConnectWiFiVC

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configUI];
}

- (void)configUI{
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.title = DPLocalizedString(@"Setting_WiFiConnect");
    self.view.backgroundColor = BACKCOLOR(238,238,238,1);
    
    _ssidTxtField.borderStyle = UITextBorderStyleRoundedRect;
    _pwdTxtField.borderStyle = UITextBorderStyleRoundedRect;
    
    _ssidTxtField.userInteractionEnabled = NO;
    _pwdTxtField.secureTextEntry = YES;

    _nextBtn.enabled = NO;
    [_nextBtn setTitle:DPLocalizedString(@"Setting_NextStep") forState:0];
    [_nextBtn addTarget:self action:@selector(nextBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [_hideOrShowPwdBtn addTarget:self action:@selector(hideOrShowPwdBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([[self getDeviceSSID] isKindOfClass:[NSString class]]) {
        _ssidTxtField.text =    [self getDeviceSSID];
    };
    _ssidTxtField.delegate = self;
    _pwdTxtField.delegate = self;
    
    [self configForTranslation];
}

- (void)hideOrShowPwdBtnClicked:(id )sender{
    _pwdExposured = !_pwdExposured;
    _pwdTxtField.secureTextEntry = !_pwdExposured;
    if (_pwdExposured) {
        [self.hideOrShowPwdBtn setBackgroundImage:[UIImage imageNamed:@"showPassword"] forState:UIControlStateNormal];
    }
    else{
        [self.hideOrShowPwdBtn setBackgroundImage:[UIImage imageNamed:@"unshowPassword"] forState:UIControlStateNormal];
    }
}

- (void)configForTranslation{
    
    self.pressSetBtnLabel.text = DPLocalizedString(@"ADDDevice_Set");
    self.confirmConnectedLabel.text = DPLocalizedString(@"WiFiSetting_PhoneConnectedToWiFi");
    self.devMoveToRouterLabel.text = DPLocalizedString(@"WiFiSetting_CameraCloseToRouter");
}


-(void)nextBtnClicked:(id)sender{
    
    
    if (_pwdTxtField.text.length > 64) {
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"WiFi_Max_length")];
        return;
    }
    
    ScanTwoViewController * view = [[ScanTwoViewController alloc]init];
    view.wifiPWD                 = _pwdTxtField.text;
    view.wifiStr                 = _ssidTxtField.text;
    view.deviceID                = _model.DeviceId;
    view.devName                 = _model.DeviceName;
    view.scanType = scanTypeWiFiSetting;
    
    [self.navigationController pushViewController:view animated:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    _nextBtn.userInteractionEnabled = _ssidTxtField.text.length >0 && _pwdTxtField.text.length>=8;
    _nextBtn.enabled = _ssidTxtField.text.length >0 && _pwdTxtField.text.length>=8;

}

- (void)textValueChanged:(id)sender{
}

- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (NSString *) getDeviceSSID
{
    NSArray *ifs = (__bridge id)CNCopySupportedInterfaces();
    
    id info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info && [info count]) {
            break;
        }
    }
    NSDictionary *dctySSID = (NSDictionary *)info;
    NSString *ssid = [dctySSID objectForKey:@"SSID"];
    
    return ssid;
    
}

@end
