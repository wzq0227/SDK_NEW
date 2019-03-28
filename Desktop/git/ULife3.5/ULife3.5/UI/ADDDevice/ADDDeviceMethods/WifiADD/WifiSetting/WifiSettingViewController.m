//
//  WifiSettingViewController.m
//  goscamapp
//
//  Created by goscam_sz on 17/4/26.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//
#import <SystemConfiguration/CaptiveNetwork.h>
#import "WifiSettingViewController.h"
#import "ConfigurationWiFiViewController.h"
#import "Header.h"
#import "WifiAddDeviceViewController.h"
#import "ScanGuideViewController.h"
#import "JumpWiFiTipsView.h"

#define font 14
@interface WifiSettingViewController ()<UITextViewDelegate,UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UIButton *jumpToSysWifiButton;

@property (strong, nonatomic) IBOutlet UITextField *WifiNameTextField;

@property (strong, nonatomic) IBOutlet UITextField *PassWordTextField;

@property (strong, nonatomic) IBOutlet UIImageView *WifiNameImageView;

@property (strong, nonatomic) IBOutlet UIImageView *PassWordImageView;

@property (strong, nonatomic) IBOutlet UIButton *nextBtn;

@property (nonatomic,assign)  BOOL isSecretPwd;

@property (assign, nonatomic) BOOL isSelect;

@property (strong, nonatomic) IBOutlet UILabel *ShowLabel;

@end

@implementation WifiSettingViewController

-(NSString*)getCurSSID
{
    NSArray* ifs = (__bridge NSArray *)(CNCopySupportedInterfaces());
    id info = nil;
    for (NSString *ifnam in ifs)
    {
        //        info = (__bridge NSArray*)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info && [info count])
        {
            break;
        }
    }
    if (info)
    {
        return [info objectForKey:@"SSID"];
    }
    else
    {
        return nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    _WifiNameTextField.text = [self getCurSSID];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.title=DPLocalizedString(@"WiFi_setting");
    self.PassWordTextField.secureTextEntry=YES;
    self.WifiNameTextField.delegate=self;
    self.PassWordTextField.delegate=self;
    self.WifiNameTextField.userInteractionEnabled = NO;
    self.PassWordTextField.returnKeyType = UIReturnKeyDone;
    self.ShowLabel.text = DPLocalizedString(@"WiFi_SSID_PWD");
    self.nextBtn.layer.cornerRadius=20;
    [self.nextBtn setTitle:DPLocalizedString(@"WiFi_sure") forState:UIControlStateNormal];
    [self.nextBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.nextBtn setBackgroundColor:myColor];
    [self protocolIsSelect:self.isSelect];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeWifi)
                                                 name:CHANGE_WIFI_BACK
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [SVProgressHUD dismiss];
}

- (void)changeWifi
{
    _WifiNameTextField.text = [self getCurSSID];
}

#pragma mark  百富文
- (void)protocolIsSelect:(BOOL)select {
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:DPLocalizedString(@"WiFi_tip")];
    
    [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14] range:NSMakeRange(0, attributedString.length)];
    [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:17] range:[[attributedString string] rangeOfString:DPLocalizedString(@"WiFi_action_change")]];
    
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, attributedString.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName value:myColor range:[[attributedString string] rangeOfString:DPLocalizedString(@"WiFi_action_change")]];
    
    [_jumpToSysWifiButton.titleLabel setNumberOfLines:0 ];
    [_jumpToSysWifiButton addTarget:self action:@selector(jumpToSysWiFiSetting) forControlEvents:UIControlEventTouchUpInside];
    [_jumpToSysWifiButton setAttributedTitle:attributedString forState:UIControlStateNormal];
}

//  实现文字点击效果
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if ([[URL scheme] isEqualToString:@"jianhang"]) {
        NSLog(@"建行支付---------------");
        
        [self jumpToSysWiFiSetting];
        return NO;
    } else if ([[URL scheme] isEqualToString:@"checkbox"]) {
        self.isSelect = !self.isSelect;
        [self protocolIsSelect:self.isSelect];
        return NO;
    }
    return YES;
}

- (void)jumpToSysWiFiSetting{
//    NSURL *url;
//    if (IOS_VERSION_11) {
//        url =  [NSURL URLWithString:@"App-Prefs:root=WIFI"];
//    }
//    else{
//        url = [NSURL URLWithString:@"App-Prefs:root=WIFI"];
//    }
//    if ([[UIApplication sharedApplication]canOpenURL:url]) {
//        [[UIApplication sharedApplication]openURL:url];
//    }
    // 弹框提示设置WiFi
    [JumpWiFiTipsViewControl showTip];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark  获取当前连接的wifi名称
- (IBAction)getWifiName:(id)sender {
    
    self.WifiNameTextField.text=[self getCurSSID];
}

#pragma mark 下一步
- (IBAction)nextAction:(id)sender {
    if (self.WifiNameTextField.text.length!=0 && self.PassWordTextField.text.length!=0) {
        
        if (_PassWordTextField.text.length <8) {
            //少于8位
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"WiFi_length")];
            return;
        }
        
        if (_PassWordTextField.text.length >64) {
            //大于64位
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"WiFi_Max_length")];
            return;
        }
        

        ScanGuideViewController *guideVC = [[ScanGuideViewController alloc]init];
        guideVC.dataModel = self.devModel;
        guideVC.addMethodType = ADDMethodsTypeWifi;
        guideVC.wifiPWD     = self.PassWordTextField.text;;
        guideVC.wifiStr = self.WifiNameTextField.text;
        [self.navigationController pushViewController:guideVC animated:NO];

    }
    else{
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"WiFi_null")];
        return;
    }
}

- (IBAction)secureTextEntry:(id)sender {
    
    _isSecretPwd=!_isSecretPwd;
    if (_isSecretPwd) {
        self.PassWordTextField.secureTextEntry=NO;
    }
    else{
        self.PassWordTextField.secureTextEntry=YES;
    }
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
