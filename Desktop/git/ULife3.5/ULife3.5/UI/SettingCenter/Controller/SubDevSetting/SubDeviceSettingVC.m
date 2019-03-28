//
//  SubDeviceSettingVC.m
//  ULife3.5
//
//  Created by Goscam on 2018/3/26.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "SubDeviceSettingVC.h"
#import "SubDevMotionDetectSettingVC.h"
#import "SubDevPirSetting_5100.h"

#import "DeviceNameSettingViewController.h"
#import "NetSDK.h"
#import "CBSCommand.h"
#import "BaseCommand.h"
#import "UserDB.h"


#define MCellIdentifier (@"")

// night vision
typedef NS_ENUM(NSInteger, DHNightVisionOption) {
    DHNightVisionOptionON,
    DHNightVisionOptionOFF,
    DHNightVisionOptionAuto
};

@interface SubDeviceSettingVC ()
<UITableViewDelegate,UITableViewDataSource>
{
    
}

@property (nonatomic, strong)  __block CMD_GetSubDevInfoResp *getSubDevInfoResp;

@property (strong, nonatomic)  UITableView *tableView;

@property (strong, nonatomic)  UIImageView *batteryImgView;
@property (strong, nonatomic) UILabel *batteryLabel;
@property (nonatomic, strong) UISwitch *motionSwitch;

@property (nonatomic, strong) PopUpTableViewManager2 *popupTableManager;
@property(nonatomic,strong)__block CMD_Device_Night *devNightVersionData;
@property (nonatomic, strong) __block CMD_GetPirDetectResp *pirDetectData;
@end

@implementation SubDeviceSettingVC

- (void)viewDidLoad {
    [super viewDidLoad];
 
    [self configView];
    
    [self loadRequest];
}

#pragma mark - Model
- (void)loadRequest{
    
    [SVProgressHUD showWithStatus:@"Loading..."];
    dispatch_group_t reqGroup = dispatch_group_create();
    dispatch_queue_t reqQueue = dispatch_queue_create("reqCommand", DISPATCH_QUEUE_CONCURRENT);
    // 标记任务完成进度
    dispatch_group_enter(reqGroup);
    dispatch_group_enter(reqGroup);
    dispatch_group_enter(reqGroup);
    // 指令反馈结果
    __block int subDevInfoRet = -1;
    __block int nightVisionRet = -1;
    
    __weak typeof(self) weakself = self;
    dispatch_group_async(reqGroup, reqQueue, ^{
        __strong typeof(weakself) strongSelf = weakself;
        
        CMD_GetSubDevInfoReq *req            = [CMD_GetSubDevInfoReq new];
        req.channel                          = _subDevInfo.ChanNum;
        NSDictionary      *reqData           = [req requestCMDData];
        
        
        [[NetSDK sharedInstance] net_sendBypassRequestWithUID:_devModel.DeviceId requestData:reqData timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
            
            subDevInfoRet = result;
            if (result == 0 )
            {
                
                strongSelf.getSubDevInfoResp         = [CMD_GetSubDevInfoResp yy_modelWithDictionary:dict];
                dispatch_async_on_main_queue(^{
                    [strongSelf.tableView reloadData];
                });
                
            }
            dispatch_group_leave(reqGroup);
            
        }];
    });
    dispatch_group_async(reqGroup, reqQueue, ^{
        __strong typeof(weakself) strongSelf = weakself;
        CMD_GetDeviceNightSwitchReq *req = [CMD_GetDeviceNightSwitchReq new];
        req.channel = _subDevInfo.ChanNum;
        
        [[NetSDK sharedInstance] net_sendBypassRequestWithUID:_devModel.DeviceId requestData:[req requestCMDData] timeout:5000 responseBlock:^(int result, NSDictionary *dict) {
            nightVisionRet = result;
            
            if (result == 0) {
                strongSelf.devNightVersionData = [CMD_GetDeviceNightSwitchResp yy_modelWithDictionary:dict];
                dispatch_async_on_main_queue(^{
                    [strongSelf.tableView reloadData];
                });
            }
            dispatch_group_leave(reqGroup);
        }];
    });
    // 获取pir开关——5100才有用
    dispatch_group_async(reqGroup, reqQueue, ^{
        __strong typeof(weakself) strongSelf = weakself;
        CMD_GetPirDetectReq *req = [CMD_GetPirDetectReq new];
        req.channel = _subDevInfo.ChanNum;
        
        [[NetSDK sharedInstance] net_sendBypassRequestWithUID:_devModel.DeviceId requestData:[req requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
            
            if (result == 0 ) {
                strongSelf.pirDetectData = [CMD_GetPirDetectResp yy_modelWithDictionary:dict];
                
                dispatch_async_on_main_queue(^{
                    [strongSelf.tableView reloadData];
                });
            }
            dispatch_group_leave(reqGroup);
        }];
    });
    dispatch_group_notify(reqGroup, reqQueue, ^{
        int ret = (nightVisionRet==0&&subDevInfoRet==0)?0:1;// 只要结果不是0都表示错误
       [GOSUIManager showGetOperationResult:ret];
    });
}


#pragma mark - UI
- (void)configView{
    
    [self configNaviBar];
    
    [self configTableView];
    
}

- (void)configNaviBar{
    self.title = DPLocalizedString(@"Setting_DeviceInfo");
    self.view.backgroundColor = mCustomBgColor;
}


- (void)configTableView{
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    //    [self.tableView registerNib:[UINib nibWithNibName:MCellIdentifier bundle:nil] forCellReuseIdentifier:MCellIdentifier];
}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    switch (section) {
        case 0:
            return 1;
        case 1:
            return 3;
        case 2:
            return 2;
        case 3:
            return 1;
    }
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 4;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = nil;

    if (indexPath.section ==2 || (indexPath.section == 1 && indexPath.row == 2)) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"CellLbl_Lbl"];
    }else{
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellImg_Lbl_Img"];
    }
    
    switch (indexPath.section) {
        case 0:
        {
            cell.textLabel.text = _subDevInfo.ChanName;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case 1:
        {
            
            if (indexPath.row == 0) {// Motion dection
                
                if ([self validateDeviceIs5100]) {
                    // 5100处理
                    cell.textLabel.text = DPLocalizedString(@"Setting_PIRDetection");
                    cell.imageView.image = [UIImage imageNamed:@"Setting_PIRDetection"];
                    [cell addSubview:self.motionSwitch];
                    self.motionSwitch.on = self.pirDetectData.un_switch;
                    [self.motionSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.centerY.equalTo(cell.mas_centerY);
                        make.trailing.equalTo(cell).offset(-15);
                    }];
                } else {
                    cell.textLabel.text = DPLocalizedString(@"Setting_MotionDetection");
                    cell.imageView.image = [UIImage imageNamed:@"Setting_MotionDetection"];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }
            } else if (indexPath.row == 1) {// Battery
                
                cell.textLabel.text = DPLocalizedString(@"Setting_BatteryLevel");
                cell.imageView.image = [UIImage imageNamed:@"Setting_BatteryLevel"];
                // 百分比图片
                self.batteryImgView.image = [UIImage imageNamed:[NSString stringWithFormat:@"batteryLevel_%d",self.getSubDevInfoResp.battery_level/25]];
                // 百分比
                self.batteryLabel = [[UILabel alloc] init];
                self.batteryLabel.text = [NSString stringWithFormat:@"%d%%", self.getSubDevInfoResp.battery_level];
                self.batteryLabel.textAlignment = NSTextAlignmentRight;
                [cell addSubview:self.batteryImgView];
                [cell addSubview:self.batteryLabel];
                [self.batteryImgView mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.centerY.equalTo(cell);
                    make.width.mas_equalTo(57);
                    make.height.mas_equalTo(25);
                    make.trailing.equalTo(cell).offset(-15);
                }];
                [self.batteryLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.centerY.equalTo(cell);
                    make.width.mas_equalTo(100);
                    make.height.mas_equalTo(25);
                    make.right.equalTo(self.batteryImgView.mas_left).offset(-10);
                }];
                
            } else if (indexPath.row == 2) {// Night Vision
                cell.textLabel.text = DPLocalizedString(@"Setting_NightVersion");
                cell.imageView.image = [UIImage imageNamed:@"Setting_NightVersion"];
                if (self.devNightVersionData) {
                    cell.detailTextLabel.text = [self displayNightVisionWithCMD:self.devNightVersionData];
                }
                cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            break;
        }
        case 2:
        {
            if (indexPath.row == 0) {
//                cell.textLabel.text = DPLocalizedString(@"DevInfo_DevModelNum");
//                cell.detailTextLabel.text = _getSubDevInfoResp.a_type;
                cell.textLabel.text = DPLocalizedString(@"firmware_version");
                cell.detailTextLabel.text = _getSubDevInfoResp.a_hardware_version;
            }else{
                cell.textLabel.text = DPLocalizedString(@"software_version");
                cell.detailTextLabel.text = _getSubDevInfoResp.a_software_version;
            }
            break;
        }
        case 3:
        {
            cell.textLabel.text = DPLocalizedString(@"Setting_DeleteDevice");
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.textColor = [UIColor redColor];
            break;
        }
        default:
            break;
    }
    
    cell.selectionStyle = (indexPath.section==2||(indexPath.section==1&&indexPath.row==1))?UITableViewCellSelectionStyleNone:UITableViewCellSelectionStyleDefault;
    
    return cell;
}

- (NSString *)displayNightVisionWithCMD:(CMD_Device_Night *)cmd {
    if (cmd.un_auto && !cmd.un_day_night) {
        return MLocalizedString(Setting_NightVersionAuto);
    } else if (!cmd.un_auto && cmd.un_day_night) {
        return MLocalizedString(Setting_NightVersionON);
    } else {
        return MLocalizedString(Setting_NightVersionOFF);
    }
    
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
//    if (indexPath.row == 0) {
        switch (indexPath.section) {
            case 0:
            {
                __weak typeof(self) weakSelf = self;
                DeviceNameSettingViewController *vc = [[DeviceNameSettingViewController alloc] init];
                [vc didChangeDevNameCallback:^(NSString *name) {
                    [weakSelf sendChangeDevNameRequestWithName:name];
                } ];
                vc.subDevName = _subDevInfo.ChanName;
                vc.model = _devModel;
                [self.navigationController pushViewController:vc animated:YES];
               
                break;
            }
            case 1:
            {
                if(indexPath.row == 0 ){// motion or pirDetect
                    // 非5100才跳转，5100项是switch，只响应switch点击
                    if (![self validateDeviceIs5100]) {
                    
                        SubDevMotionDetectSettingVC *pirSettingVC = [SubDevMotionDetectSettingVC new];
                        pirSettingVC.devModel = _devModel;
                        pirSettingVC.channel = _subDevInfo.ChanNum;
                        
                        //                SubDevPirSetting_5100 *pirSettingVC = [SubDevPirSetting_5100 new];
                        
                        //                pirSettingVC.pirDistanceSettingEnabled = 0;
                        [self.navigationController pushViewController:pirSettingVC animated:YES];
                    }
                } else if (indexPath.row == 2) {// night vision
                    [self showNightVisionOption];
                }
               
                break;
            }
            case 3:
            {
                [self unbindSubDevice];
                break;
            }
            default:
                break;
        }
//    }
}
/// 判断设备是5100
- (BOOL)validateDeviceIs5100 {
    return [self.getSubDevInfoResp.a_type isEqualToString:@"GS_T5100"];
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
- (void)showNightVisionOption {
    if (!_popupTableManager) {
        __weak typeof(self) wSelf = self;
        _popupTableManager = [[PopUpTableViewManager2 alloc] initWithFrame:[UIScreen mainScreen].bounds ];

        [_popupTableManager selectCellCallback:^(NSInteger index) {
            
            [wSelf dismissTableView];
            // 注意此处的index已经优化为传送给_popupTableManager数据中的devID了
            [wSelf setupNightVisionCommand:index];
        }];

        [_popupTableManager exitSelectingCallback:^{
            [wSelf dismissTableView];
        }];

        _popupTableManager.devicesArray = [self nightVisionOptionArray];
        _popupTableManager.tableHeaderStr = MLocalizedString(AddSubDev_SelectStation);
    }

    if (!_popupTableManager.superview) {
        [[UIApplication sharedApplication].keyWindow addSubview:_popupTableManager];
    }

}
/// 获取红外光侦测的开关
- (void)getPirSwitchStatusCommand {
    CMD_GetPirDetectReq *req = [CMD_GetPirDetectReq new];
    req.channel = _subDevInfo.ChanNum;
    NSDictionary *reqData = [req requestCMDData];
    __weak typeof(self) weakSelf = self;
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:_devModel.DeviceId requestData:reqData timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (result == 0 ) {
            strongSelf.pirDetectData = [CMD_GetPirDetectResp yy_modelWithDictionary:dict];
            
            dispatch_async_on_main_queue(^{
                [strongSelf.tableView reloadData];
            });
        }
        
        [GOSUIManager showGetOperationResult:result];
    }];
}
/// 设置红外侦测的开关
- (void)setupPirSwitchStatusCommand:(BOOL)on {
    CMD_SetPirDetectReq *req = [CMD_SetPirDetectReq new];
    req.un_switch = on;
    req.un_sensitivity = 5;
    NSDictionary *reqData = [req requestCMDData];
    [SVProgressHUD showWithStatus:DPLocalizedString(@"loading")];
    
    __weak typeof(self) weakSelf = self;
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:_devModel.DeviceId requestData:reqData timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.pirDetectData.un_switch = on;
        [strongSelf dealWithOperationResultWithResult:result];
        
        
//          [GOSUIManager showSetOperationResult:result];
    }];
}
- (void)setupNightVisionCommand:(DHNightVisionOption)option {
    [SVProgressHUD showWithStatus:DPLocalizedString(@"loading")];
    CMD_SetDeviceNightSwitchReq *req = [CMD_SetDeviceNightSwitchReq new];
    req.channel = _subDevInfo.ChanNum;
    switch (option) {
        case DHNightVisionOptionON:
            req.un_day_night = YES;
            req.un_auto = NO;
            break;
        case DHNightVisionOptionOFF:
            req.un_day_night = NO;
            req.un_auto = NO;
            break;
        case DHNightVisionOptionAuto:
            req.un_day_night = NO;
            req.un_auto = YES;
            break;
        default:
            break;
    }
    
    NSDictionary *reqData = [req requestCMDData];
    
    __weak typeof(self) weakSelf = self;
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:_devModel.DeviceId requestData:reqData timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (result == 0 ) {
            
            if (!strongSelf.devNightVersionData) {
                strongSelf.devNightVersionData = [CMD_Device_Night new];
            }
            strongSelf.devNightVersionData.un_auto = req.un_auto;
            strongSelf.devNightVersionData.un_day_night = req.un_day_night;
            
            dispatch_async_on_main_queue(^{
                [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Operation_Succeeded")];
                [strongSelf.tableView reloadData];
            });
        }else{
            dispatch_async_on_main_queue(^{
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
            });
        }
//        [GOSUIManager showGetOperationResult:result];
    }];
}
// 如果需要使用自定义的NightVersion选项列表，就打开以下代码
- (NSArray *)nightVisionOptionArray {
    return @[
             [self popModelWithDevName:MLocalizedString(Setting_NightVersionON) devID:DHNightVisionOptionON],
             [self popModelWithDevName:MLocalizedString(Setting_NightVersionOFF) devID:DHNightVisionOptionOFF],
             [self popModelWithDevName:MLocalizedString(Setting_NightVersionAuto) devID:DHNightVisionOptionAuto]
             ];
}
- (PopupTableCellModel2 *)popModelWithDevName:(NSString *)devName devID:(DHNightVisionOption)devID {
    PopupTableCellModel2 *model = [[PopupTableCellModel2 alloc] init];
    model.deviceName = devName;
    model.deviceId = devID;
    return model;
}
- (void)unbindSubDevice{
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showWithStatus:@"Loading..."];
    });
    
    CBS_DeleteSubDevRequest *req     = [CBS_DeleteSubDevRequest new];
    BodyDeleteSubDevRequest *body = [BodyDeleteSubDevRequest new];
    body.SubId                    = _subDevInfo.SubId;
    body.DeviceId = _devModel.DeviceId;
    
    __weak typeof(self) weakSelf = self;
    [[NetSDK sharedInstance] net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (result == 0) {
            [strongSelf removePushMsgs];
            [strongSelf notifyDeleteSubDev];
        }else{
            [strongSelf dealWithOperationResultWithResult:result];
        }
    }];
}

- (void)removePushMsgs{
    [[UserDB sharedInstance] removePushMsgsOfSubDevice:_subDevInfo.SubId inDevice:_devModel.DeviceId];
}

//通知中继删除子设备，失败不管
- (void)notifyDeleteSubDev{
    CMD_NotifyDeleteSubDevReq *req = [CMD_NotifyDeleteSubDevReq new];
    req.channel = _subDevInfo.ChanNum;
    
    NSDictionary *reqData = [req requestCMDData];
    
    __weak typeof(self) weakSelf = self;
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:_devModel.DeviceId requestData:reqData timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        dispatch_async_on_main_queue(^{
            
            NSNotification *notification =[NSNotification notificationWithName:REFRESH_DEV_LIST_NOTIFY object:nil];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
            
            [weakSelf.navigationController popViewControllerAnimated:YES];
        });
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    int secHeaderH = 0;
    switch (section) {
        case 0:
        {
            secHeaderH =  30;
            break;
        }
        case 1:
        {
            secHeaderH =  5;
            break;
        }
        case 2:
        {
            secHeaderH =  20;
            break;
        }
        case 3:
        {
            secHeaderH =  60;
            break;
        }
        default:
            break;
    }
    return secHeaderH;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 1;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    
    switch (section) {
        case 0:
            return DPLocalizedString(@"DevInfo_DevName");
        case 1:
            return @" ";
        case 2:
            return DPLocalizedString(@"DevInfo_CameraVersion");// DevInfo_CameraInfo
        case 3:
            return @" ";
    }
    return @"";
}

//MARK: - Net
- (void)requestSubDevInfo{
    
    CMD_GetSubDevInfoReq *req            = [CMD_GetSubDevInfoReq new];
    req.channel                          = _subDevInfo.ChanNum;
    NSDictionary      *reqData           = [req requestCMDData];

    __weak typeof(self) weakSelf         = self;
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:_devModel.DeviceId requestData:reqData timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSLog(@"daniel: ret:%d, dict:%@", result, dict);
        if (result == 0 )
        {
            
            strongSelf.getSubDevInfoResp         = [CMD_GetSubDevInfoResp yy_modelWithDictionary:dict];
            dispatch_async_on_main_queue(^{
                [strongSelf.tableView reloadData];
            });
            
        }
        [GOSUIManager showGetOperationResult:result];
        
    }];
}
- (void)requestNightVisionInfo {
    
    CMD_GetDeviceNightSwitchReq *req = [CMD_GetDeviceNightSwitchReq new];
    req.channel = _subDevInfo.ChanNum;
    __weak typeof(self) weakSelf = self;
    
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:_devModel.DeviceId requestData:[req requestCMDData] timeout:5000 responseBlock:^(int result, NSDictionary *dict) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (result == 0) {
            strongSelf.devNightVersionData = [CMD_GetDeviceNightSwitchResp yy_modelWithDictionary:dict];
            dispatch_async_on_main_queue(^{
                [strongSelf.tableView reloadData];
            });
        }
        [GOSUIManager showGetOperationResult:result];
    }];
    
    
}
- (void)motionSwitchValueDidChanged:(UISwitch *)sender {
    [self setupPirSwitchStatusCommand:sender.on];
}
#pragma mark - Lazily Load
- (UIImageView *)batteryImgView{
    if (!_batteryImgView) {
        _batteryImgView = [UIImageView new];
        _batteryImgView.image = [UIImage imageNamed:@"batteryLevel_4"];
    }
    return _batteryImgView;
}
- (UISwitch *)motionSwitch {
    if (!_motionSwitch) {
        _motionSwitch = [[UISwitch alloc] init];
        [_motionSwitch addTarget:self action:@selector(motionSwitchValueDidChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _motionSwitch;
}
//MARK - Net_devModel
- (void)sendChangeDevNameRequestWithName:(NSString*)name{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:YES];
        [SVProgressHUD showWithStatus:@"Loading..."];
    });
    CBS_ModifyChanNameRequest *req = [CBS_ModifyChanNameRequest new];
    BodyModifyChanNameRequest *body = [BodyModifyChanNameRequest new];
    body.ChanNum = _subDevInfo.ChanNum;
    body.ChanName = name;
    body.DeviceId = _devModel.DeviceId;

    __weak typeof(self) weakSelf = self;
    [[NetSDK sharedInstance] net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            weakSelf.subDevInfo.ChanName = name;
        }
        [weakSelf dealWithOperationResultWithResult:result];
    }];
}

- (void)dealWithOperationResultWithResult:(int)result{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (result!=0) {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
        }else{
            [self.tableView reloadData];
            [SVProgressHUD dismiss];
        }
    });
}
@end






#import "SYDeviceInfo.h"


#define kCellIdentifier (@"PopUpTableCellIdentifier")

@interface PopUpTableViewManager2()
<UITableViewDataSource,UITableViewDelegate,UIGestureRecognizerDelegate>

@property (strong, nonatomic)  UITableView *tableView;

@property (strong, nonatomic)  SelectCellCallbackBlock selectCallback;

@property (strong, nonatomic)  ExitSelectingBlock exitBlock;

@property (nonatomic, strong) UIButton *cancelBtn;
@end

@implementation PopupTableCellModel2
@end

@implementation PopUpTableViewManager2

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configTableView];
        [self addEvents];
    }
    return self;
}

- (void)addEvents{
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(exitFunc:)];
    tapGes.delegate = self;
    [self addGestureRecognizer:tapGes];
}

//排除手势事件对TableView点击事件的干扰
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    
    NSLog(@"______________gestureRecognizer___________:%@",NSStringFromClass( [touch.view class] ));
    return ![NSStringFromClass( [touch.view class] ) isEqualToString:@"UITableViewCellContentView"];
    
    //    CGPoint touchP = [touch locationInView:self];
    //    CGFloat minX = SCREEN_WIDTH * 0.1;
    //    CGFloat maxX = SCREEN_WIDTH * 0.9;
    //    CGFloat minY = SCREEN_HEIGHT/2 - 22*(self.devicesArray.count+1);
    //    CGFloat maxY = SCREEN_HEIGHT/2 + 22*(self.devicesArray.count+1);
    //    return touchP.x < minX || touchP.y < minY || touchP.x > maxX || touchP.y > maxY;
}

- (void)exitFunc:(id)sender {
    !_exitBlock?:_exitBlock();
}
//- (void)exitFunc:(UITapGestureRecognizer*)tapGes{
//    !_exitBlock?:_exitBlock();
//}

- (void)exitSelectingCallback:(ExitSelectingBlock)exitCallback{
    _exitBlock = exitCallback;
}

- (void)selectCellCallback:(SelectCellCallbackBlock)aCallbackBlock{
    self.selectCallback = aCallbackBlock;
    
    //    [self configTableView];
}

- (void)setDevicesArray:(NSArray<PopupTableCellModel2 *> *)devicesArray{
    _devicesArray = devicesArray;
    
    [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        
        make.center.equalTo(self);
        make.width.equalTo(self).multipliedBy(0.8);
        make.height.mas_equalTo(44*(self.devicesArray.count+1)+1);
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)configTableView{
    
    self.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) style:UITableViewStylePlain];
    _tableView.separatorInset = UIEdgeInsetsZero;
    
    _tableView.delegate =self;
    _tableView.dataSource = self;
    _tableView.scrollEnabled = NO;
    [self addSubview: _tableView];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.center.equalTo(self);
        make.width.equalTo(self).multipliedBy(0.8);
        make.height.mas_equalTo(44*(self.devicesArray.count+1));
    }];
    
    _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _cancelBtn.layer.borderColor = [UIColor grayColor].CGColor;
    _cancelBtn.layer.borderWidth = .2;
    [_cancelBtn setTitle:DPLocalizedString(@"Setting_Cancel") forState:UIControlStateNormal];
    [_cancelBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_cancelBtn setBackgroundColor:[UIColor whiteColor]];
    [_cancelBtn addTarget:self action:@selector(exitFunc:) forControlEvents:UIControlEventTouchUpInside];
    _cancelBtn.frame = CGRectMake(0, 0, _tableView.width, 44);
    _tableView.tableFooterView = _cancelBtn;
    
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.devicesArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
    }
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
//    if (indexPath.row == 0) {
//        cell.selectionStyle = UITableViewCellSelectionStyleNone;
//        cell.textLabel.text = !_tableHeaderStr?DPLocalizedString(@"CSOrder_Transfer_Title"):_tableHeaderStr;
//        cell.textLabel.numberOfLines = 0;
//
//    }else{
        cell.textLabel.text = self.devicesArray[indexPath.row].deviceName;
//    }
    
    return cell;
}


- (void)setTableHeaderStr:(NSString *)tableHeaderStr{
    _tableHeaderStr = tableHeaderStr;
}





#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
//    if (indexPath.row==0) {
//        return;
//    }
    !_selectCallback?:_selectCallback((self.devicesArray[indexPath.row]).deviceId);
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0.01;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.01;
}



@end
