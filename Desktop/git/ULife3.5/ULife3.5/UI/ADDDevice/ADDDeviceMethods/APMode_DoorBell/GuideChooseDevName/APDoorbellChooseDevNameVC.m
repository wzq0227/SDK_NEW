//
//  APDoorbellChooseDevNameVC.m
//  ULife3.5
//
//  Created by Goscam on 2017/12/5.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "APDoorbellChooseDevNameVC.h"

#import "NoDeviceToAddGuide.h"
#import "QRCodeReaderViewController.h"
#import "ParseQRResult.h"
#import "SaveDataModel.h"
#import "NetSDK.h"
#import "APDoorbellGoToSettingsVC.h"
#import "AddDeviceStyleModel.h"
#import "CBSCommand.h"
#import "APDoorbellSetDevNameView.h"
#import "Masonry.h"
#import "APDoorbellNoVoiceTipVC.h"
#import "NSTimer+YYAdd.h"

#import "DeviceManagement.h"

@interface APDoorbellChooseDevNameVC ()
<
UITableViewDelegate,
UITableViewDataSource,
QRCodeReaderDelegate,
ParseQRResultDelegate,
UITextFieldDelegate
>
{
    
}

#pragma mark - APDoorbell_属性
@property (strong, nonatomic)  NoDeviceToAddGuide *addDeviceGuideView;

@property (strong, nonatomic)  QRCodeReaderViewController *reader;

@property (assign, nonatomic)  QRCodeGenerateStyle qrCodeType;

@property (assign, nonatomic) SmartConnectStyle smartStyle; //smart 方式

@property (assign, nonatomic) BOOL supportForceUnbind; //smart 方式

@property (nonatomic,assign) GosDeviceType devtype;

@property (strong, nonatomic)  NSString *devID;

@property (strong, nonatomic)  NSString *deviceName;

@property (strong, nonatomic)  NSArray *defaultDevName;

@property (strong, nonatomic)  APDoorbellSetDevNameView *deviceNameView;

@property(nonatomic,strong)UIView             *bgViewForDevNameView;

@property (strong, nonatomic)  NSTimer *waitParsingTimer;

@property (assign, nonatomic)  NSInteger waitParsingCnt;

@end

@implementation APDoorbellChooseDevNameVC

- (NSArray *)defaultDevName{
    if (!_defaultDevName) {
        _defaultDevName = @[@"APDoorbell_DefaultDevName_FrontDoor",@"APDoorbell_DefaultDevName_BackDoor",@"APDoorbell_DefaultDevName_Office",@"APDoorbell_DefaultDevName_Other"];
    }
    return _defaultDevName;
}

- (APDoorbellSetDevNameView*)deviceNameView{
    if (!_deviceNameView) {
        _deviceNameView = [[[NSBundle mainBundle] loadNibNamed:@"APDoorbellSetDevNameView" owner:self options:nil] lastObject];
        [_deviceNameView.confirmBtn setTitle:DPLocalizedString(@"Qrcode_Title_Confirm") forState:UIControlStateNormal];
        [_deviceNameView.confirmBtn addTarget:self action:@selector(confirmBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        
        _deviceNameView.confirmBtn.titleLabel.textColor = UIColor.whiteColor;

        _deviceNameView.confirmBtn.backgroundColor = myColor;
        _deviceNameView.confirmBtn.userInteractionEnabled = NO;
        _deviceNameView.confirmBtn.alpha = 0.5;
        _deviceNameView.confirmBtn.layer.cornerRadius = 20;
        [_deviceNameView.nameDevTipLabel setText:DPLocalizedString(@"APDoorbell_NameDevice_Tip")];
        [_deviceNameView.devNameLabel setText:DPLocalizedString(@"APDoorbell_DeviceName_Tip")];
        
        _deviceNameView.devNameTxt.returnKeyType = UIReturnKeyDone;
        _deviceNameView.devNameTxt.delegate = self;
        _deviceNameView.layer.cornerRadius = 10;
    }
    return _deviceNameView;
}


- (void)viewWillAppear:(BOOL)animated{
    
    [self addNotifications];
}

- (void)viewWillDisappear:(BOOL)animated{
    
    [self removeNotifications];
//    [self StopWaitParsingTimer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configUI];
    
}



- (void)configUI{
    [self.view addSubview:self.addDeviceGuideView];
    [self.addDeviceGuideView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    self.view.backgroundColor = mCustomBgColor;
    self.title = DPLocalizedString(@"ADDDevice");
    
    [self configNavi];
}

- (void)configNavi{
    
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem itemWithFrame:CGRectMake(0, 0, 70, 40)
                                                                    target:self
                                                                    action:@selector(navBack:)
                                                                     image:[UIImage imageNamed:@"addev_back"]
                                                           imageEdgeInsets:UIEdgeInsetsMake(10, 0, 10, 50)];
}

- (void)navBack:(id)sender{

    [self.navigationController popViewControllerAnimated:YES];
//    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_DEV_LIST_NOTIFY object:nil];
}

- (void)addNotifications{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textValueChanged:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)removeNotifications{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)confirmBtnAction:(id)sender{

    dispatch_async(dispatch_get_main_queue(), ^{
        [_deviceNameView removeFromSuperview];
        [_bgViewForDevNameView removeFromSuperview];
        self.deviceName = _deviceNameView.devNameTxt.text;
        [self nextBtnAction:nil];
    });
}
- (void)textValueChanged:(id)sender{

    self.deviceNameView.confirmBtn.userInteractionEnabled = self.deviceNameView.devNameTxt.text.length > 0 ;
    _deviceNameView.confirmBtn.alpha =self.deviceNameView.confirmBtn.userInteractionEnabled ? 1: 0.5;

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    [_deviceNameView.devNameTxt resignFirstResponder];
    return YES;
}

-(NoDeviceToAddGuide*)addDeviceGuideView{
    if (!_addDeviceGuideView) {
        _addDeviceGuideView = [[[NSBundle mainBundle] loadNibNamed:@"NoDeviceToAddGuide" owner:self options:nil] lastObject];
        _addDeviceGuideView.noDeviceToAddTipLabel.text = DPLocalizedString(@"APDoorbell_NoDevice_Tips");
        
        _addDeviceGuideView.noDeviceToAddTipLabel.hidden = !_isDevListEmpty;
        
        _addDeviceGuideView.backgroundColor = mCustomBgColor;
        
        _addDeviceGuideView.deviceNameTableView.scrollEnabled = NO;
        _addDeviceGuideView.deviceNameTableView.dataSource = self;
        _addDeviceGuideView.deviceNameTableView.delegate = self;
        _addDeviceGuideView.deviceNameTableView.separatorColor = UIColor.clearColor;
        _addDeviceGuideView.deviceNameTableView.backgroundColor = mCustomBgColor;
    }
    return _addDeviceGuideView;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.defaultDevName.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, SCREEN_WIDTH);
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = mCustomBgColor;
    
    UIButton *btn = [self customButton];
    [btn setTitle: DPLocalizedString(self.defaultDevName[indexPath.row]) forState: UIControlStateNormal];
    [cell addSubview: btn];
    return cell;
}

- (UIButton*)customButton{
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(30, 0, SCREEN_WIDTH-60, 40)];
    btn.layer.cornerRadius = 20;
    btn.backgroundColor = myColor;
    btn.titleLabel.textAlignment = NSTextAlignmentCenter;
    btn.titleLabel.font = [UIFont systemFontOfSize:16];
    [btn.titleLabel setTextColor: UIColor.whiteColor];
    btn.userInteractionEnabled = NO;
    return btn;
}


#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 55;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0.1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == self.defaultDevName.count-1) {
        [self showDevNameView];
    }else{
        self.deviceName = DPLocalizedString(self.defaultDevName[indexPath.row]);
        [self nextBtnAction:nil];
    }
}

-  (void)showDevNameView{
    if (!_bgViewForDevNameView) {
        _bgViewForDevNameView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        _bgViewForDevNameView.backgroundColor = [UIColor blackColor];
        _bgViewForDevNameView.alpha = 0.5;
        [_bgViewForDevNameView addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapToDismissShowDevNameView:)] ];
    }
    [self addDevNameViewIntoKeyWindow];
}

- (void)tapToDismissShowDevNameView:(id)sender{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_deviceNameView removeFromSuperview];
        [_bgViewForDevNameView removeFromSuperview];
        
        _deviceNameView = nil;
        _bgViewForDevNameView = nil;
    });
}

- (void)addDevNameViewIntoKeyWindow{
    
    if (!self.deviceNameView.superview) {
        [[UIApplication sharedApplication].keyWindow addSubview:self.bgViewForDevNameView];
        [[UIApplication sharedApplication].keyWindow addSubview: self.deviceNameView];

        [self.deviceNameView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.bgViewForDevNameView);
            make.leading.equalTo(self.bgViewForDevNameView).offset(40);
            make.width.equalTo(self.deviceNameView.mas_height).multipliedBy(280/180.0);
        }];
    }
}

#pragma mark - 门铃添加没有设备提示

- (void)StartWaitParsingTimer{
    if (!_waitParsingTimer) {
        __weak typeof(self) weakSelf = self;
        _waitParsingTimer = [NSTimer yyscheduledTimerWithTimeInterval:1 block:^(NSTimer * _Nonnull timer) {
            weakSelf.waitParsingCnt++;
        } repeats:YES];
    }
}
- (void)StopWaitParsingTimer{
    if (_waitParsingTimer) {
        [_waitParsingTimer invalidate];
        _waitParsingTimer = nil;
    }
}

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

- (void)isParseSuccess:(BOOL)isSuccess
         smartConStyle:(SmartConnectStyle)smartConStyle
              deviceId:(NSString *)deviceId
            deviceType:(GosDeviceType)deviceType
            qrCodeType:(QRCodeGenerateStyle)qrCodeType
        isHaveEthernet:(BOOL)isHaveEthernet
     
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UINavigationController *nav = self.navigationController;
        if ([nav.topViewController isKindOfClass:[QRCodeReaderViewController class]] ) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    });
    
    if (NO == isSuccess)
    {
        NSLog(@"WiFi 添加扫码失败：deviceId = %@, deviceType = %ld", deviceId, (long)deviceType);
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_sqr_erro")];
    }
    else
    {
        
        if (GosDeviceNVR == deviceType)
        {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"showNvrAddStyleMsg")];
            return ;
        }
        
        _smartStyle   = smartConStyle;
        self.devID = deviceId;
        self.devtype = deviceType;
        self.qrCodeType = qrCodeType;
        
        if (qrCodeType == QRCodeGenerateByShare) { //
            //如果是好友分享，直接添加，由APP生成不做判断
            [self AddSharefindDevciceState:deviceId];
        }
        else{
            
            if ( SmartConnect16 == smartConStyle||
                SmartConnect15 == smartConStyle||
                SmartConnect14 == smartConStyle)
            {
                NSLog(@" 添加扫码成功：deviceId = %@, deviceType = %ld", deviceId, (long)deviceType);
                
               
                [SVProgressHUD showWithStatus:DPLocalizedString(@"Loading")];
                
                [self findDevciceState:deviceId];//@"A9996100BJ4XF655ZV35RWFF111A"
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

- (void)setSupportForceUnbind:(BOOL)supportForceUnbind{
    _supportForceUnbind = supportForceUnbind;
    NSLog(@"============*********************setSupportForceUnbind:%d",supportForceUnbind);
}

- (void)gotoSetupWifiGuideVC{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        _addDevInfo.devName = self.deviceName;
        
        APDoorbellNoVoiceTipVC *vc = [APDoorbellNoVoiceTipVC new];
        vc.addDevInfo = _addDevInfo;
        [self.navigationController pushViewController:vc animated:YES];
    });
}




#pragma mark 扫描“chancel”回调
- (void)readerDidCancel:(QRCodeReaderViewController *)reader
{
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)nextBtnAction:(id)sender{
    
    if ([self deviceNameExist:self.deviceName]) {
        [SVProgressHUD showInfoWithStatus:DPLocalizedString(@"ADDDevice_CameraNameDuplicated")];
        return;
    }
    
    [self requestCameraAuthorizationStatus];
    
}

- (BOOL) deviceNameExist:(NSString*)devName{
    BOOL devNameExist = NO;
    
    for (DeviceDataModel *model in
         [[DeviceManagement sharedInstance] deviceListArray]) {
        if ([model.DeviceName isEqualToString:devName]) {
            devNameExist = YES;
            break;
        }
    }
    return  devNameExist;
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

- (void)showCameraForbiddenAlert{
    NSString *bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    NSString *tipStr = [MLocalizedString(Privacy_Camera_Forbidden_Tip) stringByReplacingOccurrencesOfString:@"%@" withString:bundleName];
    
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:DPLocalizedString(@"Privacy_Camera_Forbidden_Title") message:tipStr delegate:self cancelButtonTitle:DPLocalizedString(@"Setting_Cancel") otherButtonTitles:MLocalizedString(Setting_Setting),nil];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:DPLocalizedString(@"Privacy_Camera_Forbidden_Title") message:tipStr delegate:self cancelButtonTitle:DPLocalizedString(@"Setting_Cancel") otherButtonTitles:nil,nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (buttonIndex == 1) {
        //App-Prefs:root=Camera
        //App-prefs:root=Privacy&path=Camera
//        NSURL *url = [NSURL URLWithString:@"App-prefs:root=com.xm.gosbell"];
//        NSURL *url1 = [NSURL URLWithString:@"App-prefs:root=com.xm.gosbell"];
//
//        if ([UIDevice systemVersion] >= 11.0 ) {
//            [[UIApplication sharedApplication]openURL:url1];
//        }else{
//            [[UIApplication sharedApplication]openURL:url];
//        }
    }
}

@end
