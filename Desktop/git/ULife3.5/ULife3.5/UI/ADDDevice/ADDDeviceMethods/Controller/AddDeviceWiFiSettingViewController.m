//
//  AddDeviceWiFiSettingViewController.m
//  ULife3.5
//
//  Created by AnDong on 2018/8/22.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "AddDeviceWiFiSettingViewController.h"
#import "QRCodeReaderViewController.h"
#import "ParseQRResult.h"
#import "CBSCommand.h"
#import "SaveDataModel.h"
#import "NetSDK.h"
#import "DeviceManagement.h"
#import "APDoorbellGoToSettingsVC.h"

#import <SystemConfiguration/CaptiveNetwork.h>
#import <AVFoundation/AVFoundation.h>
#import "JumpWiFiTipsView.h"

@interface AddDeviceWiFiSettingViewController () <UITextFieldDelegate, QRCodeReaderDelegate> {
    NSString *currentWiFiName;
}

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextField *ssidTextField;
@property (weak, nonatomic) IBOutlet UIButton *changeWiFiBtn;
@property (weak, nonatomic) IBOutlet UITextField *pwdTextField;
@property (weak, nonatomic) IBOutlet UILabel *alertLabel;
@property (weak, nonatomic) IBOutlet UIButton *nextBtn;


@property (strong, nonatomic)  QRCodeReaderViewController *reader;
@property (assign, nonatomic) SmartConnectStyle smartStyle; //smart 方式
@property (strong, nonatomic)  NSString *devID;
@property (nonatomic,assign) GosDeviceType devtype;
@property (assign, nonatomic)  QRCodeGenerateStyle qrCodeType;
@property (assign, nonatomic) BOOL supportForceUnbind; //smart 方式

@end

@implementation AddDeviceWiFiSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    currentWiFiName = [self getWifiName];
    self.ssidTextField.text = currentWiFiName;
    
    [self update5GTipsAndNextBtnWithSSID:self.ssidTextField.text pwd:self.pwdTextField.text];
    
//    NSLog(@"%s currentWiFi: %@; contain5G: %@", __PRETTY_FUNCTION__, currentWiFiName, [currentWiFiName hasSuffix:@"5G"]?@"YES":@"NO");
//    if (!currentWiFiName) {
//        [self updateNextBtnUI:NO];
//        return;
//    }
//
//    if ([currentWiFiName hasSuffix:@"5G"])
//        [self updateNextBtnUI:NO];
//    else
//        [self updateNextBtnUI:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)configureUI {
    self.navigationItem.title = @"WiFi";
    self.label.text = DPLocalizedString(@"AddDeviceWiFiSettingViewControllerTopAlert");
    
    self.ssidTextField.placeholder = @"WiFi SSID";
    self.pwdTextField.placeholder = @"Password";
    self.ssidTextField.delegate = self;
    self.pwdTextField.delegate = self;
    
    [self.changeWiFiBtn setTitle:DPLocalizedString(@"ChangeNetwork") forState:UIControlStateNormal];
    [self.changeWiFiBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.changeWiFiBtn addTarget:self action:@selector(changeWiFiBtnDidClick) forControlEvents:UIControlEventTouchUpInside];
    
    [self.nextBtn setTitle:DPLocalizedString(@"Setting_NextStep") forState:UIControlStateNormal];
    [self.nextBtn addTarget:self action:@selector(nextBtnDidClick) forControlEvents:UIControlEventTouchUpInside];
    
    self.alertLabel.text = DPLocalizedString(@"WiFi_SSID_PWD");
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewEndEditing)];
    [self.view addGestureRecognizer:tap];
}

- (void)changeWiFiBtnDidClick {
//    NSURL *url = [NSURL URLWithString:@"App-Prefs:root=WIFI"];
//    if ([[UIApplication sharedApplication]canOpenURL:url]) {
//        [[UIApplication sharedApplication]openURL:url];
//    }
    [self.view endEditing:YES];
    // 弹框提示设置WiFi
    [JumpWiFiTipsViewControl showTip];
}

- (void)applicationDidBecomeActive {
    currentWiFiName = [self getWifiName];
    self.ssidTextField.text = currentWiFiName;
    
    [self update5GTipsAndNextBtnWithSSID:self.ssidTextField.text pwd:self.pwdTextField.text];
    
//    if (!currentWiFiName) {
//        [self updateNextBtnUI:NO];
//        return;
//    }
//    NSLog(@"daniel: currentWIFIName:%@     hasSuffix:%@", currentWiFiName, [currentWiFiName hasSuffix:@"5G"]?@"YES":@"NO");
//    if ([currentWiFiName hasSuffix:@"5G"])
//        [self updateNextBtnUI:NO];
//    else
//        [self updateNextBtnUI:YES];
}

- (void)viewEndEditing {
    [self.view endEditing:YES];
}

- (void)nextBtnDidClick {
    [self requestCameraAuthorizationStatus];
}

- (NSString *) getWifiName {
    NSString *wifiName = nil;
    CFArrayRef wifiInterfaces = CNCopySupportedInterfaces();
    if (!wifiInterfaces)
        return @"";
    
    NSArray *interfaces = (__bridge NSArray *)wifiInterfaces;
    for (NSString *interfaceName in interfaces) {
        CFDictionaryRef dictRef = CNCopyCurrentNetworkInfo((__bridge CFStringRef)(interfaceName));
        if (dictRef) {
            NSDictionary *networkInfo = (__bridge NSDictionary *)dictRef;
            wifiName = [networkInfo objectForKey:(__bridge NSString *)kCNNetworkInfoKeySSID];
            
            CFRelease(dictRef);
        }
    }
    
    CFRelease(wifiInterfaces);
    return wifiName;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    // 更新5G提示、NextBtn的状态
    [self update5GTipsAndNextBtnWithSSID:self.ssidTextField.text pwd:self.pwdTextField.text];

//    if ([self.ssidTextField.text isEqualToString:currentWiFiName]) {
//        [self updateNextBtnUI:YES];
//    } else {
//        [self updateNextBtnUI:NO];
//    }
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == _ssidTextField) {
        [_ssidTextField resignFirstResponder];
        [_pwdTextField becomeFirstResponder];
    } else if (textField == _pwdTextField) {
        [_pwdTextField endEditing:YES];
    }
    return NO;
}
- (void)update5GTipsAndNextBtnWithSSID:(NSString *)ssid pwd:(NSString *)pwd {
    [self update5GTipsWithSSID:ssid];
    [self updateNextBtnWithPWD:pwd];
}
- (void)update5GTipsWithSSID:(NSString *)ssid {
    self.label.hidden = ![ssid hasSuffix:@"5G"];
}
- (void)updateNextBtnWithPWD:(NSString *)pwd {
    BOOL show = (pwd.length >= 8);// 验证密码是否超过8位
    self.nextBtn.userInteractionEnabled = show;
    self.nextBtn.backgroundColor = show ? myColor : [UIColor colorWithRed:115/255.0 green:202/255.0 blue:215/255.0 alpha:1.0];
}
//- (void)updateNextBtnUI:(BOOL)show {
//    self.nextBtn.userInteractionEnabled = show;
//    self.nextBtn.backgroundColor = show ? myColor : [UIColor colorWithRed:115/255.0 green:202/255.0 blue:215/255.0 alpha:1.0];
//    self.label.hidden = show;
//}

- (void)requestCameraAuthorizationStatus{
    
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    
    if (authStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!granted) {
                    [self showCameraForbiddenAlert];
                }else{
                    [self gotoParseQrCode ];
                }
            });
        }];
    }else if (authStatus==AVAuthorizationStatusDenied || authStatus == AVAuthorizationStatusRestricted){
        [self showCameraForbiddenAlert];
    }else{
        [self gotoParseQrCode ];
    }
}

- (void)showCameraForbiddenAlert{
    NSString *bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    NSString *tipStr = [MLocalizedString(Privacy_Camera_Forbidden_Tip) stringByReplacingOccurrencesOfString:@"%@" withString:bundleName];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:DPLocalizedString(@"Privacy_Camera_Forbidden_Title") message:tipStr delegate:self cancelButtonTitle:DPLocalizedString(@"Setting_Cancel") otherButtonTitles:MLocalizedString(Setting_Setting),nil];
    [alert show];
}

- (void)gotoParseQrCode{
    if ([self initCodeReader]) {
        
        if ([QRCodeReader supportsMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]]) {
            
            [self.navigationController pushViewController:self.reader animated:NO];
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:DPLocalizedString(@"ADDDevice_Error") message:DPLocalizedString(@"ADDDevice_Reader_not_supported_by_the_current_device") delegate:nil cancelButtonTitle:DPLocalizedString(@"ADDDevice_OK") otherButtonTitles:nil];
            [alert show];
        }
    }else{
        [self showCameraForbiddenAlert];
    }
}

-(BOOL)initCodeReader
{
    if (self.reader == nil) {
        self.reader = [QRCodeReaderViewController new];
        self.reader.delegate = self;
    }
    return YES;
}

#pragma mark 解析二维码
- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result
{
    if ([ParseQRResult shareQRParser].delegate != self ) {//
        
        [ParseQRResult shareQRParser].delegate = self;
        [[ParseQRResult shareQRParser] parseWithQRString:result
                                           addDeviceType:AddDeviceByAll];
    }
    return;
}

#pragma mark -- 二维码解析 delegate
-(void)parseQRResult:(QRParseResultModel *)qrModel{
    
    BOOL isSuccess      = qrModel.parseSuccessfully;
    BOOL isHaveEthernet = qrModel.hasEthernet;
    
    _smartStyle         = qrModel.smartConStyle;
    self.devID          = qrModel.deviceId;
    self.devtype        = qrModel.deviceType;
    self.qrCodeType     = qrModel.qrCodeType;
    self.supportForceUnbind = qrModel.supportForceUnbnid;
    
    
    if (!_addDevInfo) {
        _addDevInfo = [InfoForAddingDevice new];
    }
    
    _addDevInfo.devId      = self.devID;
    _addDevInfo.smartStyle = qrModel.smartConStyle;
    _addDevInfo.deviceType = qrModel.deviceType;
    _qrCodeType            = qrModel.qrCodeType;
    _addDevInfo.supportForceUnbind = qrModel.supportForceUnbnid;
    
    [ParseQRResult shareQRParser].delegate = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UINavigationController *nav = self.navigationController;
        if ([nav.topViewController isKindOfClass:[QRCodeReaderViewController class]] ) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    });
    
    if (NO == isSuccess)
    {
        NSLog(@"WiFi 添加扫码失败：deviceId = %@, deviceType = %ld", _devID, (long)_devtype);
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_sqr_erro")];
    }
    else
    {
        
        if (GosDeviceNVR == _devtype)
        {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"showNvrAddStyleMsg")];
            return ;
        }
        
        
        
        if (_qrCodeType == QRCodeGenerateByShare) { //
            //如果是好友分享，直接添加，由APP生成不做判断
            [self AddSharefindDevciceState:_devID];
        }
        else{
            
            if ( SmartConnect16 == _smartStyle||
                SmartConnect15 == _smartStyle||
                SmartConnect14 == _smartStyle)
            {
                NSLog(@" 添加扫码成功：deviceId = %@, deviceType = %ld", _devID, (long)_devtype);
                
                
                [SVProgressHUD showWithStatus:DPLocalizedString(@"Loading")];
                
                [self findDevciceState:_devID];//@"A9996100BJ4XF655ZV35RWFF111A"
            }
            else
            {
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_sqr_erro")];
            }
        }
    }
}

-(void)AddSharefindDevciceState:(NSString*)UID
{
    
    __weak typeof(self) weakSelf = self;
    
    CBS_QueryBindRequest *req = [CBS_QueryBindRequest new];
    BodyQueryBindRequest *body = [BodyQueryBindRequest new];
    body.DeviceId = UID;
    body.UserName = [SaveDataModel getUserName];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [[NetSDK sharedInstance] net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:5000 responseBlock:^(int result, NSDictionary *dict) {
            
            if(result == -10095){
                dispatch_async(dispatch_get_main_queue(),^{
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_Device_Not_Exist")];
                });
            }
            else if (result !=0) {
                dispatch_async(dispatch_get_main_queue(),^{
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
                });
            }
            else {
                
                NSString * ret = dict[@"Body"][@"BindStatus"];
                
                switch (ret.integerValue)
                {
                        
                    case 0:   // 未绑定IROUTER_DEVICE_BIND_NOEXIST
                    {
                        
                        dispatch_async(dispatch_get_main_queue(),^{
                            
                            [SVProgressHUD dismiss];
                            //                            weakSelf.MyDeviceIdTextField.text=UID;
                            [weakSelf addFriendShareNext:nil];
                        });
                    }
                        break;
                        
                    case 1:    // 已被本账号以拥有方式绑定 IROUTER_DEVICE_BIND_DUPLICATED
                    {
                        dispatch_async(dispatch_get_main_queue(),^{
                            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_we_bind")];
                            //                            weakSelf.MyDeviceIdTextField.text=@"";
                        });
                    }
                        break;
                    case 2:    // 已被本账号以分享方式绑定
                    {
                        dispatch_async(dispatch_get_main_queue(),^{
                            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_Already_Added")];
                            //                            weakSelf.MyDeviceIdTextField.text=@"";
                        });
                    }
                        break;
                        
                    case 3:     // 被其他账号绑定 IROUTER_DEVICE_BIND_INUSE
                    {
                        dispatch_async(dispatch_get_main_queue(),^{
                            
                            [SVProgressHUD dismiss];
                            //                            weakSelf.MyDeviceIdTextField.text=UID;
                            [weakSelf addFriendShareNext:nil];
                        });
                    }
                        break;
                    default:
                        dispatch_async(dispatch_get_main_queue(),^{
                            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
                        });
                        break;
                }
            }
        }];
    });
}

- (void)addFriendShareNext:(id)sender {
    
    NSString *password = @"goscam123";
    CBS_BindRequest *req = [CBS_BindRequest new];
    BodyBindRequest *body = [BodyBindRequest new];
    body.DeviceId = self.devID;
    body.DeviceName = @"";
    body.DeviceType = self.devtype;
    body.DeviceOwner = 0;
    body.AreaId  = @"000001";
    body.StreamUser = @"admin";
    body.UserName = [SaveDataModel getUserName];
    body.StreamPassword = password;
    [SVProgressHUD showWithStatus:@"loading....."];
    
    if ([body.DeviceId hasPrefix:@"A"]) {
        
        if ( isENVersionNew) {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"DeviceSupportEN")];
            //            self.MyDeviceIdTextField.text = @"";
            //中文版
            return;
        }
        
    }
    else if ([body.DeviceId hasPrefix:@"Z"]){
        //英文版
        if (! isENVersionNew) {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"DeviceSupportCN")];
            //            self.MyDeviceIdTextField.text = @"";
            //中文版
            return;
        }
    }
    else{
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"DeviceSupportNO")];
        //        self.MyDeviceIdTextField.text = @"";
        //不支持
        return;
    }
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [[NetSDK sharedInstance] net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:10000 responseBlock:^(int result, NSDictionary *dict) {
            
            if (result == 0) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSNotification *notification =[NSNotification notificationWithName:REFRESH_DEV_LIST_NOTIFY object:nil];
                    [[NSNotificationCenter defaultCenter] postNotification:notification];
                    
                    
                    [UIView animateWithDuration:0.1 animations:^{
                        [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Configure_success")];
                    } completion:^(BOOL finished) {
                        [self.navigationController popViewControllerAnimated:NO];
                    }];
                });
            }
            else if (result == -10095)
            {
                dispatch_async(dispatch_get_main_queue(),^{
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_Device_Not_Exist")];
                });
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(),^{
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
                });
            }
        }];
    });
}

#pragma mark 从CBS查询设备是否被绑定
-(void)findDevciceState:(NSString*)UID
{
    __weak typeof(self) weakSelf = self;
    CBS_QueryBindRequest *req = [CBS_QueryBindRequest new];
    BodyQueryBindRequest *body = [BodyQueryBindRequest new];
    body.DeviceId = UID;
    body.UserName = [SaveDataModel getUserName];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [[NetSDK sharedInstance] net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:7000 responseBlock:^(int result, NSDictionary *dict) {
            if (result !=0) {
                dispatch_async(dispatch_get_main_queue(),^{
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
                });
            }
            else if ([dict[@"MessageType"]isEqualToString:@"QueryDeviceBindResponse"]) {
                NSString * ret = dict[@"Body"][@"BindStatus"];
                switch (ret.integerValue)
                {
                    case 0:   // 未绑定IROUTER_DEVICE_BIND_NOEXIST
                    {
                        dispatch_async(dispatch_get_main_queue(),^{
                            
                            if ([UID hasPrefix:@"A"]) {
                                
                                if ( isENVersionNew) {
                                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"DeviceSupportEN")];
                                    //中文版
                                    return;
                                }
                                
                            }
                            else if ([UID hasPrefix:@"Z"]){
                                //英文版
                                if (! isENVersionNew) {
                                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"DeviceSupportCN")];
                                    //中文版
                                    return;
                                }
                            }
                            else{
                                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"DeviceSupportNO")];
                                //不支持
                                return;
                            }
                            
                            [SVProgressHUD dismiss];
                            [weakSelf gotoSetupWifiGuideVC];
                            //                            weakSelf.MyDeviceIdTextField.text=UID;
                            
                        });
                    }
                        break;
                        
                    case 1:    // 已被本账号以拥有方式绑定 IROUTER_DEVICE_BIND_DUPLICATED
                    {
                        dispatch_async(dispatch_get_main_queue(),^{
                            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_we_bind")];
                            //                            [weakSelf gotoSetupWifiGuideVC];
                            //                        [weakSelf.navigationController popViewControllerAnimated:YES];
                        });
                    }
                        break;
                        
                    case 3:     // 被其他账号绑定 IROUTER_DEVICE_BIND_INUSE
                    {
                        
                        dispatch_async(dispatch_get_main_queue(),^{
                            
                            if (!weakSelf.supportForceUnbind) {
                                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_other_bind")];
                            }else{
                                [SVProgressHUD dismiss];
                                weakSelf.addDevInfo.addedByOthers = YES;
                                [weakSelf gotoSetupWifiGuideVC];
                            }
                        });
                    }
                        break;
                        
                    default:
                        dispatch_async(dispatch_get_main_queue(),^{
                            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
                        });
                        break;
                }
            }
        }];
    });
}

- (void)gotoSetupWifiGuideVC{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        _addDevInfo.devName = [self getDeviceName];
        
        APDoorbellGoToSettingsVC *vc = [[APDoorbellGoToSettingsVC alloc] init];
        vc.addDevInfo = _addDevInfo;
        vc.ssid = self.ssidTextField.text;
        vc.password = self.pwdTextField.text;
        [self.navigationController pushViewController:vc animated:YES];
    });
}

- (NSString *)getDeviceName {
    NSString *str = DPLocalizedString(@"addDev_wifiStation");
    int hasDevice = 0;
    for (DeviceDataModel *model in
         [[DeviceManagement sharedInstance] deviceListArray]) {
        if ([model.DeviceName rangeOfString:str].location != NSNotFound)
            hasDevice++;
    }
    if (hasDevice == 0)
        return str;
    else
        return [NSString stringWithFormat:@"%@ : %@", str, [NSString stringWithFormat:@"(%d)", hasDevice]];
}
@end
