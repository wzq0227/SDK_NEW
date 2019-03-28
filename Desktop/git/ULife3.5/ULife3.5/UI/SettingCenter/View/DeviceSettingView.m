//
//  DeviceSettingView.m
//  goscamapp
//
//  Created by goscam_sz on 17/5/6.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "DeviceSettingView.h"
#import "settingCell.h"
#import "Header.h"
#import "Masonry.h"
#import "BaseCommand.h"
#import "NetSDK.h"

@interface DeviceSettingView()
    

@property (nonatomic,strong) UITableViewCell      *deleteDeviceCell;
@property (nonatomic,strong) UILabel              *deleteDeviceLabel;
@property (nonatomic,copy  ) SelectRowBlock       selectRowBlock;
@property (nonatomic,strong) deleteDeviceBlock    deleteDevBlock;
@property (nonatomic,strong) UnbindSubDeviceBlock unbindSubDevBlock;

@property (nonatomic,strong) CMD_GetAllParamResp  *getAllParamResp;
@property(nonatomic,strong)  NetSDK               *netSDK;
@end

@implementation DeviceSettingView
settingMode * settingModel;

- (void) didSelectRowCallback:(SelectRowBlock)block{
    _selectRowBlock = block;
}

- (void) deleteDeviceCallback:(deleteDeviceBlock)block{
    _deleteDevBlock = block;
}

- (void)unbindSubDeviceCallback: (UnbindSubDeviceBlock)block{
    _unbindSubDevBlock = block;
}



-(void)awakeFromNib
{
    [super awakeFromNib];

    settingModel = [[settingMode alloc]init];
    
    _netSDK = [NetSDK sharedInstance];
    
    [self.myDeviceTableView registerNib:[UINib nibWithNibName:@"settingCell" bundle:nil] forCellReuseIdentifier:@"cell"];
    self.myDeviceTableView.delegate=self;
    self.myDeviceTableView.dataSource=self;
}

- (void)refreshTableViewWithModel:(UISettingModel*)devAbilityModel{
    
    settingModel.shareByFriend = _model.DeviceOwner == GosDeviceShare;
    settingModel.devModel      = _model;
    settingModel.dataStorageTime = self.dataStorageTime;
    [settingModel refreshUIWithModel:devAbilityModel];
    [self.myDeviceTableView reloadData];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return settingModel.data.count+1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowsCount = 0;
    if (section == settingModel.data.count ) {
        rowsCount = 1;
    }
    else{
        rowsCount = [settingModel.data[section] count];
    }
    return rowsCount;
}

-(UITableViewCell *)deleteDeviceCell{
    if (!_deleteDeviceCell) {
        _deleteDeviceCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"deleteDeviceCell"];
        _deleteDeviceCell.separatorInset = UIEdgeInsetsMake(0, 0, 0, _deleteDeviceCell.bounds.size.width);
        [_deleteDeviceCell addSubview:self.deleteDeviceLabel];
        [_deleteDeviceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_deleteDeviceCell);
        }];
    }
    return _deleteDeviceCell;
}

- (UILabel*)deleteDeviceLabel{
    
    if (!_deleteDeviceLabel) {
        _deleteDeviceLabel = [[UILabel alloc]initWithFrame: CGRectMake(0, 14,120, 30) ];
        _deleteDeviceLabel.font          = [UIFont fontWithName:@"PingFangSC-Regular" size:17];
        _deleteDeviceLabel.textAlignment = NSTextAlignmentCenter;
        _deleteDeviceLabel.textColor     = [UIColor redColor];
        _deleteDeviceLabel.text          = DPLocalizedString(@"Setting_DeleteDevice");
    }
    return _deleteDeviceLabel;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == settingModel.data.count) {
       return self.deleteDeviceCell;
    }
    
    dataModel *model = settingModel.data[indexPath.section][indexPath.row];
    model.deviceId = self.model.DeviceId;
    
    settingCell * cell =[tableView dequeueReusableCellWithIdentifier:@"cell" ];
    

    if (model.deviceSettingType == DeviceSettingCloudService) {
        model.dataStorageTime = self.dataStorageTime;
    }
    
    [cell refreshUIWithModel: model];
    if (self.getAllParamResp) {
        switch (model.deviceSettingType) {
                
            case DeviceSettingDBBellRemindSetting:
            {
                cell.settingSwitch.on = _getAllParamResp.doorbell_ring;
                break;
            }
            case DeviceSettingDBLedRemindSetting:
            {
                cell.settingSwitch.on = _getAllParamResp.doorbell_led;
                break;
            }
                
            case DeviceSettingCameraSwitch:
            {
                cell.settingSwitch.on = _getAllParamResp.device_switch;
                break;
            }
            case DeviceSettingMotionDetection:
            {
                cell.settingSwitch.on = _getAllParamResp.motion_detect_switch;
                break;
            }
            case DeviceSettingVoiceDetection:
            {
                cell.settingSwitch.on = _getAllParamResp.audio_alarm_switch;
                break;
            }
            case DeviceSettingPIRDetection:
            {
                cell.settingSwitch.on = _getAllParamResp.pir_detect_switch;
                break;
            }
            case DeviceSettingBatteryLevel:
            {
                NSLog(@"____________________getAllParamResp.battery_level:%d",_getAllParamResp.battery_level);
                if (_getAllParamResp.battery_level<=0) {
                    _getAllParamResp.battery_level =0;
                }
                cell.detailImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"batteryLevel_%d",_getAllParamResp.battery_level/25]];
                break;
            }

            case DeviceSettingCameraMicrophone:
            {
                cell.settingSwitch.on = _getAllParamResp.device_mic_switch != 0;
                break;
            }
            case DeviceSettingCellularDataAutoPause:
                //
                break;
            case DeviceSettingManualRecord:
            {
                cell.settingSwitch.on = _getAllParamResp.un_manual_record_switch != 0;
                break;
            }
            case DeviceSettingStatusIndicator:
            {
                cell.settingSwitch.on = _getAllParamResp.device_led_switch != 0;
                break;
            }
            case DeviceSettingRotateSemicircle:
            {
                cell.settingSwitch.on = _getAllParamResp.mode != 0;
                break;
            }
            default:
                break;
        }
    }
    
    [cell.settingSwitch addTarget:self action:@selector(switchClicked:) forControlEvents:UIControlEventValueChanged];
    return cell;
}

- (void)refreshTableView{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.myDeviceTableView reloadData];
    });
}

- (void)refreshTableViewWithResp:(CMD_GetAllParamResp *)getAllParamResp{
    NSLog(@"refreshTableViewWithResp:%@ %d",getAllParamResp,getAllParamResp.pir_detect_sensitivity);
    self.getAllParamResp = getAllParamResp;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.myDeviceTableView reloadData];
    });
}

- (void)showManualRecordOpResultWithResult:(int)result{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (result!=0) {
            NSString *errorInfo = [NSString stringWithFormat:@"未知错误:%d",result];
            switch (result) {
                case 1:
                    errorInfo = DPLocalizedString(@"Operation_Failed");
                    break;
                case 2:
                    errorInfo = DPLocalizedString(@"RecordSettingError_NoSDCard");
                    break;
                case 3:
                    errorInfo = DPLocalizedString(@"RecordSettingError_SDCardError");
                    break;
                case 4:
                    errorInfo = DPLocalizedString(@"RecordSettingError_StorageInsufficient");
                    break;
                case 5:
                    errorInfo = DPLocalizedString(@"RecordSettingError_Recording");
                    break;
                case 6:
                    errorInfo = DPLocalizedString(@"RecordSettingError_OperateTooFrequently");
                    break;
                default:
                    break;
            }
            [SVProgressHUD showErrorWithStatus:errorInfo];
        }else{
            [SVProgressHUD dismiss];
        }
        [self.myDeviceTableView reloadData];
    });
}

- (void)showOperationResultWithResult:(int)result{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (result!=0) {
            if(result == -2005){
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Play_Ipc_unonline")];
            }else{
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
            }
        }else{
            [SVProgressHUD dismiss];
        }
        [self.myDeviceTableView reloadData];
    });
}

- (void)switchClicked:(id)sender{
    UISwitch *cellSwitch = (UISwitch*)sender;
    settingCell *cell = (settingCell*)(cellSwitch.superview.superview);
    int state = cellSwitch.on;
    __weak typeof(self) weakSelf = self;
    [SVProgressHUD showWithStatus:@"Loading..."];
    
    switch (cell.model.deviceSettingType) {
            
        case DeviceSettingDBBellRemindSetting:
        {
            CMD_SetDBBellRemindReq *reqCmd = [CMD_SetDBBellRemindReq new];
            reqCmd.doorbell_ring = state;
            [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[reqCmd requestCMDData] timeout:10000 responseBlock:^(int result, NSDictionary *dict) {
                if (result == 0) {
                    weakSelf.getAllParamResp.doorbell_ring = reqCmd.doorbell_ring;
                }
                [weakSelf showOperationResultWithResult:result];
            }];
            break;
        }
        case DeviceSettingDBLedRemindSetting:
        {
            CMD_SetDBLedRemindReq *reqCmd = [CMD_SetDBLedRemindReq new];
            reqCmd.doorbell_led = state;
            [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[reqCmd requestCMDData] timeout:10000 responseBlock:^(int result, NSDictionary *dict) {
                if (result == 0) {
                    weakSelf.getAllParamResp.doorbell_led = reqCmd.doorbell_led;
                }
                [weakSelf showOperationResultWithResult:result];
            }];
            break;
        }
            
            
        case DeviceSettingCameraSwitch:
        {
            CMD_SetCameraSwitchReq *reqCmd = [[CMD_SetCameraSwitchReq alloc] init];
            reqCmd.device_switch = state;
            [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[reqCmd requestCMDData] timeout:10000 responseBlock:^(int result, NSDictionary *dict) {
                if (result == 0) {
                    weakSelf.getAllParamResp.device_switch = reqCmd.device_switch;
                }
                [weakSelf showOperationResultWithResult:result];
            }];
            break;
        }
            
        case DeviceSettingMotionDetection:
        {
            CMD_SetMotionDetectReq *reqCmd = [[CMD_SetMotionDetectReq alloc] init];
            reqCmd.c_switch = state;
            [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[reqCmd requestCMDData] timeout:10000 responseBlock:^(int result, NSDictionary *dict) {
                if (result == 0) {
                    weakSelf.getAllParamResp.motion_detect_switch = reqCmd.c_switch;
                }
                [weakSelf showOperationResultWithResult:result];
            }];
            
            break;
        }
        case DeviceSettingVoiceDetection:
        {
            CMD_SetAudioAlarmReq *reqCmd = [[CMD_SetAudioAlarmReq alloc] init];
            reqCmd.un_switch = state;
            [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[reqCmd requestCMDData] timeout:10000 responseBlock:^(int result, NSDictionary *dict) {
                if (result == 0) {
                    weakSelf.getAllParamResp.audio_alarm_switch = reqCmd.un_switch;
                }
                [weakSelf showOperationResultWithResult:result];
            }];
            
            break;
        }
            
        case DeviceSettingPIRDetection:
        {
            CMD_SetPirDetectReq *reqCmd = [[CMD_SetPirDetectReq alloc] init];
            reqCmd.un_switch = state;
            [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[reqCmd requestCMDData] timeout:15000 responseBlock:^(int result, NSDictionary *dict) {
                if (result == 0) {
                    weakSelf.getAllParamResp.pir_detect_switch = reqCmd.un_switch;
                }
                [weakSelf showOperationResultWithResult:result];
            }];
            
            break;
        }
        case DeviceSettingCameraMicrophone:
        {
            CMD_SetDeviceMicSwitchReq *reqCmd = [[CMD_SetDeviceMicSwitchReq alloc] init];
            reqCmd.device_mic_switch = state;
            [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[reqCmd requestCMDData] timeout:10000 responseBlock:^(int result, NSDictionary *dict) {
                if (result == 0) {
                    weakSelf.getAllParamResp.device_mic_switch = reqCmd.device_mic_switch;
                }
                [weakSelf showOperationResultWithResult:result];
            }];
            
            break;
        }
        case DeviceSettingCellularDataAutoPause:
        {
//            CMD_SetCameraSwitchReq *reqCmd = [[CMD_SetCameraSwitchReq alloc] init];
//            reqCmd.device_switch = state;
//            [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[reqCmd requestCMDData] timeout:10000 responseBlock:^(int result, NSDictionary *dict) {
                [weakSelf showOperationResultWithResult:0];
//            }];
            
            break;
        }
        case DeviceSettingManualRecord:
        {
            CMD_SetManualRecordReq *reqCmd = [[CMD_SetManualRecordReq alloc] init];
            reqCmd.manual_record_switch = state;
            [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[reqCmd requestCMDData] timeout:10000 responseBlock:^(int result, NSDictionary *dict) {
                if (result == 0) {
                    weakSelf.getAllParamResp.un_manual_record_switch = reqCmd.manual_record_switch;
                }
                [weakSelf showManualRecordOpResultWithResult:result];
            }];
            
            break;
        }
        case DeviceSettingStatusIndicator:
        {
            CMD_SetDeviceLedSwitchReq *reqCmd = [[CMD_SetDeviceLedSwitchReq alloc] init];
            reqCmd.device_led_switch = state;
            [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[reqCmd requestCMDData] timeout:10000 responseBlock:^(int result, NSDictionary *dict) {
                if (result == 0) {
                    weakSelf.getAllParamResp.device_led_switch = reqCmd.device_led_switch;
                }
                [weakSelf showOperationResultWithResult:result];
            }];
            
            break;
        }
        case DeviceSettingRotateSemicircle:
        {
            CMD_SetVideoModeReq *reqCmd = [[CMD_SetVideoModeReq alloc] init];
            reqCmd.mode = state?3:0;
            [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[reqCmd requestCMDData] timeout:10000 responseBlock:^(int result, NSDictionary *dict) {
                if (result == 0) {
                    weakSelf.getAllParamResp.mode = reqCmd.mode;
                }
                [weakSelf showOperationResultWithResult:result];
            }];
            
            break;
        }
        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    if (indexPath.section == settingModel.data.count) {
        
        if (_deleteDevBlock) {
            _deleteDevBlock();
        }
        return;
    }
    
    dataModel *model = settingModel.data[indexPath.section][indexPath.row];
    if (_selectRowBlock) {
        _selectRowBlock(model.deviceSettingType);
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
    if (section == settingModel.groupNames.count) {
        return nil;
    }
    UIView * view =[[UIView alloc]initWithFrame:CGRectMake(0, 0,SCREEN_WIDTH, 44)];
    UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(10, 10, SCREEN_WIDTH, 30)];
    label.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13];
    if (section < settingModel.groupNames.count) {
        label.text = DPLocalizedString( [@"Setting_Group_" stringByAppendingString:settingModel.groupNames[section] ] );
    }
    label.textColor=[UIColor blackColor];
    [view addSubview:label];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section == settingModel.data.count ?50:25;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return section == settingModel.data.count ? 66: 1.0f;
}

@end
