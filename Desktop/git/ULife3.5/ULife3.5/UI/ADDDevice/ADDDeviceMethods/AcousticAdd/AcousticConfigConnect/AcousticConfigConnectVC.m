//
//  AcousticConfigConnectVC.m
//  ULife3.5
//
//  Created by Goscam on 2017/10/11.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "AcousticConfigConnectVC.h"
#import "CommonlyUsedFounctions.h"
#import "Header.h"
#import "ConfigurationWiFiViewController.h"
#import "AcousticConfigTipsVC.h"
#import "JumpWiFiTipsView.h"



@interface AcousticConfigConnectVC ()<UITextViewDelegate>

@property(nonatomic,assign)BOOL pwdExposured;   //deafault No

@property (assign, nonatomic)  int curFrequency;

@end


@implementation AcousticConfigConnectVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self configUI];
    
    [self configModel];
    
    [self addActions];
}




- (void)configUI{
    [self configNavigationBar];
    
    [self configButtons];
    
    [self configView];
}

- (void)configModel{
    _curFrequency = 12000;
}



- (void)addActions{
    
    _passwordTxt.secureTextEntry = YES;
    
    [_hideOrShowPWDBtn addTarget:self action:@selector(hideOrShowPwdBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_configBtn addTarget:self action:@selector(configBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    NSString *curSSID = [CommonlyUsedFounctions getCurSSID];
    if (curSSID.length > 0) {
        _wifiSSIDTxt.text =  curSSID;
    };
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeWifi)
                                                 name:CHANGE_WIFI_BACK
                                               object:nil];
}

- (void)changeWifi
{
    NSString *curSSID = [CommonlyUsedFounctions getCurSSID];
    if (curSSID.length > 0 ) {
        _wifiSSIDTxt.text =  curSSID;
    };
}


- (void)configNavigationBar{
    self.title = DPLocalizedString(@"AcousticAdd_navBarTitle");
    [self configBackBtn];
}

- (void)configBackBtn{
    UIImage *image = [UIImage imageNamed:@"addev_back"];
    EnlargeClickButton *button = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 70, 40);
    button.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 50);
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self
               action:@selector(backToPrevieousVC:)
     forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    leftBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
}

- (void)backToPrevieousVC:(id)sender{
    if ([SVProgressHUD isVisible]) {
        [SVProgressHUD dismiss];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    for (UIViewController *controller in self.navigationController.viewControllers) {
        if ([controller isKindOfClass:[AcousticConfigTipsVC class]]) {
            [self.navigationController popToViewController:controller animated:NO];
            break;
        }
    }
}


- (void)configBtnClicked:(id)sender{
    
    NSString *ssidtext = [_wifiSSIDTxt text];
    NSString *pwdText = [_passwordTxt text];
    NSString *curSSID = [CommonlyUsedFounctions getCurSSID];
    if (!curSSID || curSSID.length ==0) {
        [self showAlertWithMsg:DPLocalizedString(@"AcousticAdd_connectToWiFiFirst")];
        return;
    }
    if ([ssidtext length] == 0 || [pwdText length] == 0) {
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"WiFi_null")];
        return;
    }else if (pwdText.length <8 ){
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"WiFi_length")];
        return;
    }
    
    _addDevInfo.addDeviceMode                    = AddDeviceByVoice;
    _addDevInfo.devWifiName                      = self.wifiSSIDTxt.text;
    _addDevInfo.devWifiPassWord                  = self.passwordTxt.text;
    _addDevInfo.devId                            = self.devModel.DeviceId;
    _addDevInfo.devName                          = self.devModel.DeviceName;
    _addDevInfo.deviceType                       = self.devModel.DeviceType;
    
    ConfigurationWiFiViewController *vc = [ConfigurationWiFiViewController new];
   
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)hideOrShowPwdBtnClicked:(id )sender{
    _pwdExposured = !_pwdExposured;
    _passwordTxt.secureTextEntry = !_pwdExposured;
    if (_pwdExposured) {
        [self.hideOrShowPWDBtn setBackgroundImage:[UIImage imageNamed:@"showPassword"] forState:UIControlStateNormal];
    }
    else{
        [self.hideOrShowPWDBtn setBackgroundImage:[UIImage imageNamed:@"unshowPassword"] forState:UIControlStateNormal];
    }
}

- (void)configView{
    UIColor *customGrayColor = BACKCOLOR(238,238,238,1);
    self.view.backgroundColor = customGrayColor;
    
    [self setupTextView];
    
    self.btn12KHz.hidden = YES;
    self.Btn1KHz.hidden = YES;
    self.frequencyLabel.hidden = YES;
    //    self.wifiSSIDTxt.layer.borderWidth = 1;
    //    self.wifiSSIDTxt.layer.borderColor = customGrayColor.CGColor;
    
    //    self.passwordTxt.layer.borderWidth = 1;
    //    self.passwordTxt.layer.borderColor = customGrayColor.CGColor;
    
    self.frequencyLabel.text = DPLocalizedString(@"AcousticAdd_frequency");
}

//MARK:给TextView添加链接
- (void)setupTextView{
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:DPLocalizedString(@"WiFi_tip")];

    [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14] range:NSMakeRange(0, attributedString.length)];
    [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:17] range:[[attributedString string] rangeOfString:DPLocalizedString(@"WiFi_action_change")]];
    
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, attributedString.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName value:myColor range:[[attributedString string] rangeOfString:DPLocalizedString(@"WiFi_action_change")]];
    
    [_jumpToSysWifiBtn.titleLabel setNumberOfLines:0 ];
    [_jumpToSysWifiBtn addTarget:self action:@selector(jumpToSystemWiFiSetting:) forControlEvents:UIControlEventTouchUpInside];
    [_jumpToSysWifiBtn setAttributedTitle:attributedString forState:UIControlStateNormal];
//
}

//  实现文字点击效果
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if ([[URL scheme] isEqualToString:@"LinkURLScheme"]) {
        [self jumpToSystemWiFiSetting:nil];
        return NO;
    } else if ([[URL scheme] isEqualToString:@"checkbox"]) {
        return NO;
    }
    return YES;
}

- (void)jumpToSystemWiFiSetting:(id)sender{
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

- (void)frequencyChanged:(id)sender{
    UIButton *btn = (UIButton*)sender;
    if (btn.tag==0) {
        [self.btn12KHz setBackgroundImage:[UIImage imageNamed:@"addDev_Voice_CirclePress"] forState:0];
        [self.Btn1KHz setBackgroundImage:[UIImage imageNamed:@"addDev_Voice_Circle"] forState:0];
    }else{
        [self.Btn1KHz setBackgroundImage:[UIImage imageNamed:@"addDev_Voice_CirclePress"] forState:0];
        [self.btn12KHz setBackgroundImage:[UIImage imageNamed:@"addDev_Voice_Circle"] forState:0];
    }
    _curFrequency = btn.tag==0 ? 12000 : 1000;
}

- (void)configButtons{
    self.configBtn.backgroundColor = myColor;
    self.configBtn.layer.cornerRadius = 20;
    self.configBtn.clipsToBounds = YES;
    [self.configBtn setTitleColor:[UIColor whiteColor] forState:0];
    [self.configBtn setTitle:DPLocalizedString(@"AcousticAdd_config") forState:0];
    
    [self.btn12KHz setTag:0];
    [self.btn12KHz addTarget:self action:@selector(frequencyChanged:) forControlEvents:UIControlEventTouchUpInside];
    [self.Btn1KHz setTag:1];
    [self.Btn1KHz addTarget:self action:@selector(frequencyChanged:) forControlEvents:UIControlEventTouchUpInside];

}



#pragma mark 配置成功去绑定
- (void) showRecogResult:(NSString *)_msg
{
    [SVProgressHUD dismiss];
    self.configBtn.userInteractionEnabled = YES;

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if ([self deviceConnectedToRouterWiFi:_msg]) {
        
        
    }else{
        UIAlertView *helloworldAlert = [[UIAlertView alloc] initWithTitle:nil message:_msg delegate:self cancelButtonTitle:DPLocalizedString(@"Title_Confirm") otherButtonTitles:nil, nil];
        [helloworldAlert show];
    }
}

- (void)showAlertWithMsg:(NSString *)msg{
    UIAlertView *msgAlert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:self cancelButtonTitle:DPLocalizedString(@"Title_Confirm") otherButtonTitles:nil, nil];
    msgAlert.delegate = self;
    [msgAlert show];
}

- (BOOL)deviceConnectedToRouterWiFi:(NSString *)msg{
    if (msg.length == 28 && [msg hasSuffix:@"111A"]) {
        return YES;
    }
    return NO;
}




@end
