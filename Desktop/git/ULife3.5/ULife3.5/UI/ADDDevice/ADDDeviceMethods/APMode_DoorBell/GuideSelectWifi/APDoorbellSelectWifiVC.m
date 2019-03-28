//
//  APDoorbellSelectWifiVC.m
//  ULife3.5
//
//  Created by Goscam on 2017/12/5.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "APDoorbellSelectWifiVC.h"
#import "LanSDK.h"
#import "Masonry.h"
#import "APDoorbellEnetrPwdVC.h"
#import "ConfigurationWiFiViewController.h"
#import "AddDeviceBindedViewController.h"

@interface APDoorbellSelectWifiVC ()
<
UITableViewDelegate,
UITableViewDataSource,
UIAlertViewDelegate
>
{
    
}

@property (assign, nonatomic)  BOOL hasShownResetDevAlert;

@property(assign,nonatomic) SWifiInfo  wifiListInfo;

@property (strong, nonatomic)  NSString *ssidName;

@property (strong, nonatomic)  NSString *pwdStr;

@property (strong, nonatomic)  UIAlertController * alertController;

@property (nonatomic, strong)  UITextField *pwdTextField;

@end

const static NSString *kCellIdentifier = @"APDoorbellSelectWifiCell";

@implementation APDoorbellSelectWifiVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self configUI];
    
    [self getSSIDList];
}

- (void)configUI{
    
    [self configTableView];

    [self configView];
    
//    [self configNavigationItem];
}

- (void)configNavigationItem{
    
    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    saveBtn.frame     = CGRectMake(0, 0, 60, 40);
    [saveBtn setTitle:DPLocalizedString(@"Title_Save") forState:0];
    [saveBtn addTarget:self action:@selector(saveBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:saveBtn];
}

- (void)configView{
 
    self.view.backgroundColor = mCustomBgColor;
    self.unsupport5GWifiLabel.text = DPLocalizedString(@"APDoorbell_5GWiFiUnsupported_Tip");
    self.title = DPLocalizedString(@"WiFi_Configuration");
}

//- (void)hideOrShowPwdBtnAction:(id)sender{
//    self.pwdTxt.secureTextEntry = !self.pwdTxt.isSecureTextEntry;
//    [self.hideOrShowPwdBtn setBackgroundImage:[UIImage imageNamed:self.pwdTxt.isSecureTextEntry?@"showPassword.png":@"unshowPassword.png"] forState:UIControlStateNormal];
//}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
//    [self showAlertWithName:@"test1"];
}

//- (void)showAlertWithName:(NSString*)name{
//    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: DPLocalizedString(@"WiFi_setting")
//                                                                              message: nil
//                                                                       preferredStyle:UIAlertControllerStyleAlert];
//    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
//        textField.text = name;
//        textField.userInteractionEnabled = NO;
//        //        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
//    }];
//    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
//        textField.placeholder = DPLocalizedString(@"iRouter_password");
//        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
//        [textField becomeFirstResponder];
//        //        textField.secureTextEntry = YES;
//    }];
//
//
//
//    [alertController addAction:[UIAlertAction actionWithTitle:DPLocalizedString(@"Setting_Cancel") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//    }]];
//    __weak typeof(self) weakSelf = self;
//
//    [alertController addAction:[UIAlertAction actionWithTitle:DPLocalizedString(@"Setting_Setting") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//        NSArray * textfields = alertController.textFields;
//
//        UITextField * namefield = textfields[0];
//        UITextField * passwordfiled = textfields[1];
//        NSLog(@"%@:%@",namefield.text,passwordfiled.text);
//        [weakSelf setSSIDTxt:name PwdTxt:passwordfiled.text];
//    }]];
//    [self presentViewController:alertController animated:YES completion:nil];
//}




- (void)showAlertWithName1:(NSString*)name{
    
    NSString *titleName = [DPLocalizedString(@"APDoorbell_EnterPwd") stringByReplacingOccurrencesOfString:@"%@" withString:name];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:titleName message:nil delegate:self cancelButtonTitle:DPLocalizedString(@"WiFi_sure") otherButtonTitles:DPLocalizedString(@"Setting_Cancel"), nil];
    
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    _pwdTextField = [alertView textFieldAtIndex:0];
    _pwdTextField.placeholder = DPLocalizedString(@"iRouter_password");
    
    [alertView show];
}


- (void)setSSIDAndPwd{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.pwdStr = self.pwdTextField.text;
        [self saveBtnClicked:nil];
    });
}

- (void)saveBtnClicked:(id)sender{
    
    _addDevInfo.addDeviceMode                    = AddDeviceByAPDoorbell;
    _addDevInfo.devWifiName                      = self.ssidName;
    _addDevInfo.devWifiPassWord                  = self.pwdStr;
    _addDevInfo.deviceType                       = GosDeviceIPC;
    
    ConfigurationWiFiViewController *vc = [ConfigurationWiFiViewController new];
    vc.addDevInfo = self.addDevInfo;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)gotoNeedResetDeviceVC {
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        AddDeviceBindedViewController *vc = [[AddDeviceBindedViewController alloc] init];
        [weakself.navigationController pushViewController:vc animated:YES];
    });
}

bool foundDevice = NO;
- (void)getSSIDList{
    
    NSString * userName = @"admin";
    NSString * pwd = @"goscam123";
    NSString * devType = @""; //传空表示所有类型
    foundDevice = NO;
    [SVProgressHUD showWithStatus:@"Loading..."];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[LanSDK sharedLanSDKInstance] searchAndConnectDeviceWithUID:self.addDevInfo.devId userName:userName password:pwd timeout:120000 deviceType:devType wifiListBlock:^(int result, SWifiInfo wifiListInfo,BOOL devResetFlag) {
            if (result == 0) {
#pragma mark -test
                foundDevice = YES;
                
                weakSelf.wifiListInfo = wifiListInfo;
            }
            if (!devResetFlag && weakSelf.addDevInfo.addedByOthers ) { 
//                [weakSelf showToResetDevAlert];
                [self gotoNeedResetDeviceVC];
            }
#pragma mark -test2

            if (result == 1024) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"APDoorbell_FoundDevice") ];
                    [SVProgressHUD dismissWithDelay:2];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (!foundDevice) {
                            [SVProgressHUD showWithStatus:@"Loading"];
                        }
                    });
                });
            }else{
                [weakSelf dealWithGetOperationResult:result];
            }
        }];
    });
}

- (void)showToResetDevAlert{
    if (!_hasShownResetDevAlert) {
        _hasShownResetDevAlert = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlertWithMsg:DPLocalizedString(@"AddDev_ForceUnbind_NotReset")];
        });
    }
}

- (void)showAlertWithMsg:(NSString *)msg{
    UIAlertView *msgAlert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:self cancelButtonTitle:DPLocalizedString(@"AddDev_ForceUnbind_NotReset_IKnow") otherButtonTitles:nil, nil];
    msgAlert.delegate = self;
    [msgAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (!alertView.title) {
            [self.navigationController popViewControllerAnimated:YES];
        }else if (buttonIndex==0){
            [self setSSIDAndPwd];
        }
    });
}

- (void)dealWithGetOperationResult:(int)result{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (result == 0) {
            [SVProgressHUD dismiss];
            
            [self.wifiListTableView reloadData];
        }else{
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Get_data_failed") ];
        }
    });
    
}

- (void)configTableView {
    
    self.wifiListTableView.dataSource = self;
    self.wifiListTableView.delegate = self;
    self.wifiListTableView.backgroundColor = mCustomBgColor;
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.wifiListInfo.totalcount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    WifiInfoN info = self.wifiListInfo.plist[indexPath.row];
    
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(15, 10, 120, 30)];
    label.textAlignment = NSTextAlignmentLeft;
    label.font = [UIFont fontWithName:@"PingFangSC-Regular" size:17];
    label.text = [NSString stringWithUTF8String: info.wifiSsid ];
    
    [cell addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(cell);
        make.leading.equalTo(cell).offset(15);
    }];
    
    int level = ((info.signalLevel+10)/30)%4;
    
    NSLog(@"___________________________________level:%d",level);
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 10, 30, 30)];
    imageView.image        =  [UIImage imageNamed:[NSString stringWithFormat:@"WiFiSignal_Level_%d.png",level]];
    [cell addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(cell);
        make.trailing.equalTo(cell).offset(-15);
        make.height.mas_equalTo(15);
        make.width.equalTo(imageView.mas_height);
    }];
    
    return cell;
}


#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 1;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    WifiInfoN info = self.wifiListInfo.plist[indexPath.row];
    self.ssidName = [NSString stringWithUTF8String: info.wifiSsid];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self showAlertWithName1: self.ssidName ];
    });
    
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return nil;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    return nil;
}

- (BOOL)shouldAutorotate {
    return NO;
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;;
}

@end
