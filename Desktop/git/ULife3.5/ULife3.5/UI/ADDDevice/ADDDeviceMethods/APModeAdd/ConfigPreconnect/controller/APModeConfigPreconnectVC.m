//
//  APModeConfigPreconnectVC.m
//  ULife3.5
//
//  Created by Goscam on 2017/9/25.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "APModeConfigPreconnectVC.h"
#import "ConfigurationWiFiViewController.h"
#import "Header.h"
#import "NetSDK.h"
#import "NetAPISet.h"
#import "CommonlyUsedFounctions.h"
#import "LanSDK.h"
#import "JumpWiFiTipsView.h"

@interface APModeConfigPreconnectVC ()<UITextViewDelegate,UIAlertViewDelegate>
@property (strong, nonatomic)  UITableViewCell *showAPNameCell;

@property(assign,nonatomic) SWifiInfo  wifiListInfo;

@property (strong, nonatomic)  LanSDK *lanSDK;

@property(nonatomic,assign)BOOL pwdExposured;   //deafault No

/**
 正在连接设备，搜索标志
 */
@property (assign, nonatomic)  BOOL isSearching;

@property (strong, nonatomic)  NSTimer *waitingForConnectingToAPWifi;


/**
 设备AP模式下发出的SSID名称 360默认是C-Smart_AP
 */
@property (strong, nonatomic)  NSString *devSSIDNameInAPMode;

@end

@implementation APModeConfigPreconnectVC

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
    self.devSSIDNameInAPMode = self.devModel.smartStyle==SmartConnect16? @"RouterSet-": @"C-Smart_AP";
}

- (void)configNavigationBar{
    self.title = DPLocalizedString(@"APAdd_APMode");
}




- (void)addActions{
    _lanSDK = [LanSDK sharedLanSDKInstance];
    self.isSearching = NO;
    
    _passwordTxt.secureTextEntry = YES;
    
    [_hideOrShowPWDBtn addTarget:self action:@selector(hideOrShowPwdBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_nextBtn addTarget:self action:@selector(nextBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    NSString *curSSID = [CommonlyUsedFounctions getCurSSID];
    if (curSSID.length > 0 && ![curSSID containsString:_devSSIDNameInAPMode]) {
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
    if (curSSID.length > 0 && ![curSSID containsString:_devSSIDNameInAPMode]) {
        _wifiSSIDTxt.text =  curSSID;
    };
}


- (void)nextBtnClicked:(id)sender{
//    [SVProgressHUD showWithStatus:@"Loading..."];
    if (_passwordTxt.text.length<=0 || _wifiSSIDTxt.text <= 0){
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"WiFi_null")];
    }
    else if (_passwordTxt.text.length <8 ){
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"WiFi_length")];
    }
    else if([_wifiSSIDTxt.text containsString:_devSSIDNameInAPMode]){
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"APAdd_SSIDNameError")];
    }else{

        NSString *curWiFi = [CommonlyUsedFounctions getCurSSID];
        if ([curWiFi containsString:_devSSIDNameInAPMode]) {
            
            self.nextBtn.userInteractionEnabled = NO;
            [SVProgressHUD showWithStatus:@"Loading..."];
            [self connectToDevice];
        }else{
            [self showAlertWithMsg:[ DPLocalizedString(@"APAdd_chooseNetworkTips_CSmartAP") stringByReplacingOccurrencesOfString:@"C-Smart_AP" withString:self.devSSIDNameInAPMode]];
//            if (!_waitingForConnectingToAPWifi) {
//                _waitingForConnectingToAPWifi = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(waitingForAPWifiFunc:) userInfo:nil repeats:YES];
//            }
        }
    }
}

- (void)showAlertWithMsg:(NSString *)msg{
    UIAlertView *msgAlert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:self cancelButtonTitle:DPLocalizedString(@"Title_Confirm") otherButtonTitles:nil, nil];
    msgAlert.delegate = self;
    [msgAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    [self jumpToSysWiFiSetting ];
}

- (void)waitingForAPWifiFunc:(id)sender{
    NSString *curWiFi = [CommonlyUsedFounctions getCurSSID];
    if ([curWiFi containsString:_devSSIDNameInAPMode]) {
        
        [_waitingForConnectingToAPWifi invalidate];
        _waitingForConnectingToAPWifi = nil;
        
        [self connectToDevice];
    }
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

    self.chooseNetworkLabel.text = DPLocalizedString(self.devModel.smartStyle==SmartConnect16?@"APAdd_chooseNetworkTips_RoutersetGW20":@"APAdd_chooseNetworkTips_CSmartAP");
}

//MARK:给TextView添加链接
- (void)setupTextView{
    
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
    if ([[URL scheme] isEqualToString:@"LinkURLScheme"]) {
        
        [self jumpToSysWiFiSetting];
        return NO;
    } else if ([[URL scheme] isEqualToString:@"checkbox"]) {
        return NO;
    }
    return YES;
}

- (void)jumpToSysWiFiSetting{
    NSURL *url;
//    if (IOS_VERSION_11) {
//        url =  [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//    }
//    else{
//        url = [NSURL URLWithString:@"App-Prefs:root=WIFI"];
////    }
//    if ([[UIApplication sharedApplication]canOpenURL:url]) {
//        [[UIApplication sharedApplication]openURL:url];
//    }
    // 弹框提示设置WiFi
    [JumpWiFiTipsViewControl showTip];
}

- (void)configButtons{
    self.nextBtn.backgroundColor = myColor;
    self.nextBtn.layer.cornerRadius = 20;
    self.nextBtn.clipsToBounds = YES;
    [self.nextBtn setTitleColor:[UIColor whiteColor] forState:0];
    [self.nextBtn setTitle:DPLocalizedString(@"ADDDevice_Next") forState:0];
}


//jumpToSysWifiButton
//TODO: 6FRAEF2S1D7TA7TV111A 88888888
- (void)connectToDevice{
    if (self.isSearching) {
        return;
    }
    self.isSearching = YES;
    
    NSString * UID = self.devModel.DeviceId; //substringWithRange:NSMakeRange(self.devModel.DeviceId.length-20, 20)
    NSString * userName = @"admin";
    NSString * pwd = @"goscam123";
    NSString * devType = @""; //传空表示所有类型
    
    __weak typeof(self) weakSelf = self;
    
    //FIXME: 搜索到设备之后把WiFi名称和密码传给设备
    NSString *wifiSSID = self.wifiSSIDTxt.text;
    NSString *password = self.passwordTxt.text;
    
    _addDevInfo.smartStyle      = self.devModel.smartStyle;
    _addDevInfo.devId           = self.devModel.DeviceId;
    _addDevInfo.deviceType      = self.devModel.DeviceType;
    _addDevInfo.devName         = self.devModel.DeviceName;
    _addDevInfo.devWifiName     = self.wifiSSIDTxt.text;
    _addDevInfo.devWifiPassWord = self.passwordTxt.text;
    _addDevInfo.addDeviceMode   = AddDeviceByAPMode;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [_lanSDK searchAndConnectDeviceWithUID:UID userName:userName password:pwd timeout:36000 deviceType:devType ssid:wifiSSID password:password resultBlock:^(int result, DeviceInfo *devInfo)
         {
            if (result == 0) {//设置WiFi成功跳转到下一个界面
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    ConfigurationWiFiViewController *vc = [ConfigurationWiFiViewController new];
                    
                    vc.addDevInfo = strongSelf.addDevInfo;
                    [strongSelf.navigationController pushViewController:vc animated:YES];
                });
            }else{
            }
            [strongSelf dealWithSearchResult:result];
        }];
    });

    
    
}

- (void)dealWithSearchResult:(int)result{
    self.isSearching = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.nextBtn.userInteractionEnabled = YES;
        if (result!=0) {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"localizied_293")];
        }else{
            [SVProgressHUD dismiss];
        }
    });
}


- (void)dealWithGetOperationResultWithResult:(int)result{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (result!=0) {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Get_data_failed")];
        }else{
            [SVProgressHUD dismiss];
        }
    });
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
