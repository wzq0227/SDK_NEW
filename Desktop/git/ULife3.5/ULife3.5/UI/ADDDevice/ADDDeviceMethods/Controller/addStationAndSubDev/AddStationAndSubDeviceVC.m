//
//  AddStationAndSubDeviceVC.m
//  ULife3.5
//
//  Created by Goscam on 2018/3/20.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "AddStationAndSubDeviceVC.h"
#import "APDoorbellChooseDevNameVC.h"
#import "AddDeviceNameSubDeviceVC.h"
#import "Masonry.h"
#import "QRCodeReaderViewController.h"
#import "ParseQRResult.h"
#import "CBSCommand.h"
#import "SaveDataModel.h"
#import "NetSDK.h"
#import "APDoorbellNoVoiceTipVC.h"

#import "DeviceManagement.h"
#import "PopUpTableViewManager.h"

#import "AddWiFiStationViewController.h"

#import <AVFoundation/AVFoundation.h>

@interface AddStationAndSubDevCell:UITableViewCell

@property (strong, nonatomic)  UIImageView *cellImage;

@property (strong, nonatomic)  UILabel *cellTitle;

@end

@implementation AddStationAndSubDevCell
-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _cellImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        _cellImage.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_cellImage];
        
        _cellTitle = [[UILabel alloc] initWithFrame:CGRectMake(60, 0, 100, 30)];
        [self addSubview:_cellTitle];
    }
    return self;
}
@end

@interface AddStationAndSubDeviceVC ()
<UITableViewDelegate,UITableViewDataSource, QRCodeReaderDelegate, ParseQRResultDelegate>


@property (strong, nonatomic)  PopUpTableViewManager *popupTableManager;

@property (strong, nonatomic)  NSMutableArray <PopupTableCellModel*>*devicesArray;

@property (strong, nonatomic)  NSString *destDevId;

@property (nonatomic, assign)  NSInteger stationCount;

@property (nonatomic, assign)  DeviceTypeEnum devType;

@property (strong, nonatomic)  QRCodeReaderViewController *reader;
@property (assign, nonatomic) SmartConnectStyle smartStyle; //smart 方式
@property (strong, nonatomic)  NSString *devID;
@property (nonatomic,assign) GosDeviceType devtype;
@property (assign, nonatomic)  QRCodeGenerateStyle qrCodeType;
@property (assign, nonatomic) BOOL supportForceUnbind; //smart 方式
@property (strong, nonatomic)  NSString *deviceName;
@end

@implementation AddStationAndSubDeviceVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self configUI];
}


- (void)configUI{
    self.title=DPLocalizedString(@"ADDDevice");

    [self configTableView];
}

- (void)configTableView{
    self.addDevTableView.delegate = self;
    self.addDevTableView.dataSource = self;
    self.addDevTableView.scrollEnabled = NO;
    [self.addDevTableView registerClass:[AddStationAndSubDevCell class] forCellReuseIdentifier:@"AddStationAndSubDevCell"];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    AddStationAndSubDevCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddStationAndSubDevCell"];
  
    if (!cell) {
        cell = [[AddStationAndSubDevCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AddDevTableViewCell"];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    cell.separatorInset = UIEdgeInsetsZero;
    
    [cell.cellImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(cell).offset(20);
        make.centerY.equalTo(cell);
        make.width.mas_equalTo(33);
    }];
    
    //(indexPath.row==2?5:(2-indexPath.row))
    [cell.cellTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(cell.cellImage.mas_trailing).offset(10+5);
        make.centerY.equalTo(cell);
    }];
    
    switch (indexPath.row) {
        case 0:
        {
            cell.cellTitle.text = DPLocalizedString(@"addDev_wifiStation");
            cell.cellImage.image = [UIImage imageNamed:@"addDev_station"];
            break;
        }
        case 1:
        {
            cell.cellTitle.text = DPLocalizedString(@"addDev_wirelessCamera");
            cell.cellImage.image = [UIImage imageNamed:@"addDev_wirelessCamera"];
            break;
        }
        case 2:
        {
            cell.cellTitle.text = DPLocalizedString(@"addDev_doorbell");
            cell.cellImage.image = [UIImage imageNamed:@"addDev_doorbell"];
            break;
        }

        default:
            break;
    }

    return cell;
}



#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    DeviceTypeEnum devType = indexPath.row;
    
    _devType = devType;
    switch (devType) {
        case DeviceTypeEnumStation:
        {
//            APDoorbellChooseDevNameVC *vc = [APDoorbellChooseDevNameVC new];
//            vc.isDevListEmpty = _isDevListEmpty;
//            [self.navigationController pushViewController:vc animated:YES];
//            [self requestCameraAuthorizationStatus];
            
            AddWiFiStationViewController *vc = [[AddWiFiStationViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            
            break;
        }
        case DeviceTypeEnumWirelessCamera:
        case DeviceTypeEnumDoorbell:
        {
            if (self.stationCount==1) {
                
                [self pushAddSubDevVC];
            }
            else if (self.stationCount==0){
                [self showAddStationFirstAlert];
            }else{
                [self showSelectStationView];
            }
            break;
        }
//        {
//            break;
//        }
        default:
            break;
    }
}

- (void)pushAddSubDevVC{
    AddDeviceNameSubDeviceVC *vc = [AddDeviceNameSubDeviceVC new];
    vc.devModel = _devModel;
    vc.devType = _devType;
    vc.deviceId = _destDevId;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showAddStationFirstAlert{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:MLocalizedString(AddSubDev_AddStationFirst) delegate:self cancelButtonTitle:MLocalizedString(Title_Confirm) otherButtonTitles:nil, nil];
    [alert show];
}
- (void)showAddStationSubdevOutOfLimit {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:MLocalizedString(Title_Confirm) message:MLocalizedString(AddSubDev_OutOfLimit) delegate:self cancelButtonTitle:MLocalizedString(Setting_Cancel) otherButtonTitles:nil];
    [alert show];
}

//检查是否有多个中继,过滤分享设备，及four_channel_flag==0的
- (NSInteger)stationCount{
    NSInteger count = self.devicesArray.count;
    if (count == 1) {
        for (DeviceDataModel *devModel in [[DeviceManagement sharedInstance]deviceListArray]) {
            if ([devModel.DeviceId isEqualToString: self.devicesArray[0].deviceId] ) {
                self.destDevId = devModel.DeviceId;
                self.devModel = devModel;
            }
        }
        
    }
    return  count;
}

- (void)showSelectStationView{
    if (!_popupTableManager) {
        __weak typeof(self) wSelf = self;
        _popupTableManager = [[PopUpTableViewManager alloc] initWithFrame:[UIScreen mainScreen].bounds ];
        [_popupTableManager selectCellCallback:^(NSInteger index) {
            BOOL isSubCountGreaterThanOrEqual4 = [wSelf judgeStationSubdevCountWithDevID:wSelf.devicesArray[index].deviceId limit:4];//wSelf.destDevId
            if (isSubCountGreaterThanOrEqual4) {
                // 子设备超过4个就不允许再添加，并提示
                [wSelf dismissTableView];
                
                [wSelf showAddStationSubdevOutOfLimit];
            } else {
            
                wSelf.destDevId = wSelf.devicesArray[index].deviceId;
                wSelf.devModel = [wSelf devModelFromDevID:wSelf.destDevId];
    //            NSString *destDevName = wSelf.devicesArray[index].deviceName;
                
                [wSelf dismissTableView];
                
                [wSelf pushAddSubDevVC];
            }
        }];
        
        [_popupTableManager exitSelectingCallback:^{
            [wSelf dismissTableView];
        }];
        
        _popupTableManager.devicesArray = self.devicesArray;
        _popupTableManager.tableHeaderStr = MLocalizedString(AddSubDev_SelectStation);
    }
    
    if (!_popupTableManager.superview) {
        [[UIApplication sharedApplication].keyWindow addSubview:_popupTableManager];
        //        [_popupTableManager mas_makeConstraints:^(MASConstraintMaker *make) {
        //            make.edges.equalTo(self.view);
        //        }];
    }
}
- (BOOL)judgeStationSubdevCountWithDevID:(NSString *)devID limit:(NSInteger)limit {
    for (DeviceDataModel *model in [[DeviceManagement sharedInstance] deviceListArray]) {
        if ([model.DeviceId isEqualToString:devID]) {
            // 判断子设备数量是否大于或等于limit
            return (model.SubDevice.count >= limit);
            
        }
    }
    // 没找到数据就默认子设备数量没有大于或等于limit
    return NO;
}
- (DeviceDataModel*)devModelFromDevID:(NSString*)devID{
    for (DeviceDataModel *model in [[DeviceManagement sharedInstance] deviceListArray]) {
        if ([model.DeviceId isEqualToString:devID]) {
            return model;
        }
    }
    return nil;
}

- (void)dismissTableView{
    
    [UIView transitionWithView:self.view duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        [_popupTableManager removeFromSuperview];
                    }
                    completion:^(BOOL finished) {
                        if (finished) {
                            _popupTableManager = nil;
                        }
                    }];
}

//getters
- (NSArray<PopupTableCellModel*>*)devicesArray{
    if (!_devicesArray) {
        _devicesArray = [NSMutableArray arrayWithCapacity:1 ];
        for (DeviceDataModel *model in [[DeviceManagement sharedInstance] deviceListArray]) {
            //分享设备暂时没有添加子设备权限
            if (model.DeviceOwner == GosDeviceShare /*|| model.devCapModel.four_channel_flag == 0*/) {
                continue;
            }
            PopupTableCellModel *cellModel = [PopupTableCellModel new];
            cellModel.deviceId = model.DeviceId;
            cellModel.deviceName = model.DeviceName;
            [_devicesArray addObject:cellModel];
        }
    }
    return _devicesArray;
}

// 取消门铃前门后门等类型选择界面 改为在此页面直接添加
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

- (void)setSupportForceUnbind:(BOOL)supportForceUnbind{
    _supportForceUnbind = supportForceUnbind;
    NSLog(@"============*********************setSupportForceUnbind:%d",supportForceUnbind);
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
        
        APDoorbellNoVoiceTipVC *vc = [APDoorbellNoVoiceTipVC new];
        vc.addDevInfo = _addDevInfo;
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
