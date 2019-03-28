//
//  settingMode.m
//  goscamapp
//
//  Created by goscam_sz on 17/5/8.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "settingMode.h"

@implementation dataModel

-(NSArray *)DevSettingCellTitleNames{
    if (!_DevSettingCellTitleNames) {
        _DevSettingCellTitleNames = @[
                                      @"Alexa",@"LightDuration",@"BabyMusic", @"LedRemind",@"BellRemind",
                                      @"MotionDetection",@"VoiceDetection",@"PIRDetection",@"BatteryLevel",@"TempAlarmSetting",
                                      @"TalkingMode",@"CameraSwitch",@"CameraMicrophone",@"CellularDataAutoPause",@"CloudService",
                                      @"ManualRecord",@"PhotoAlbum",
                                      @"StatusIndicator",@"RotateSemicircle",@"NightVersion",
                                      @"ShareWithFriends",
                                      @"TimeCheck",@"WiFiSetting",@"DeviceInfo",@"UnbindSubDevice"];
    }
    return _DevSettingCellTitleNames;
}

-(dataModel *)initDataModelWithDeviceSettingType:(DeviceSettingType)type{
    self = [super init];
    if (self) {
     
        self.deviceSettingType = type;
        if (type < self.DevSettingCellTitleNames.count) {
            self.name = [@"Setting_" stringByAppendingString: self.DevSettingCellTitleNames[type]];
            self.image = self.name;
        }
    }
    return self;
}


@end



@implementation settingMode

-(instancetype)init
{
    self=[super init];
    if (self) {
//        [self refreshDataWithModel:devAbilityModel];
    }
    return self;
}

- (void)refreshUIWithModel:(UISettingModel*)devAbilityModel{
    [self refreshDataWithModel:devAbilityModel];
}


- (NSMutableArray *)groupNames{
    if (!_groupNames) {
        _groupNames = [NSMutableArray arrayWithCapacity:7];
        [_groupNames addObject:@"Custom"];
        [_groupNames addObject:@"Camera"];
        [_groupNames addObject:@"NormalAction"];
        [_groupNames addObject:@"CloudService"];
        [_groupNames addObject:@"ManualRecord"];
        [_groupNames addObject:@"Hardware"];
        [_groupNames addObject:@"Share"];
        [_groupNames addObject:@"DetailInfo"];

//     "Setting_Group_Camera" = "Camera";
    }
    return _groupNames;
}

-(void)refreshDataWithModel:(UISettingModel *)devAbilityModel
{
    NSLog(@"refreshDataWithModel__pir_ability:%d",devAbilityModel.ability_pir);
    
    dataModel * md =[[dataModel alloc]init];

    NSMutableArray * customGroup = [NSMutableArray arrayWithCapacity:1];

    NSMutableArray * cameraSwitchGroup = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray * normalActionGroup = [NSMutableArray arrayWithCapacity:4];
    NSMutableArray * cloudServiceGroup = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray * manualRecordGroup = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray * hardwareGroup = [NSMutableArray arrayWithCapacity:3];
    NSMutableArray * friendShareGroup = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray * detailInfoGroup = [NSMutableArray arrayWithCapacity:2];
        
    for (int i =0 ; i< md.DevSettingCellTitleNames.count; i++) {
        dataModel *model = [[dataModel alloc] initDataModelWithDeviceSettingType:i ];
        
        switch (model.deviceSettingType) {
                
            case DeviceSettingAlexa:{
                if (!devAbilityModel.ability_c_Alexa_Skills_Kit_flag) {
                    break;
                }
                [customGroup addObject:model];
                break;
                
            }
                
            case DeviceSettingLightDuration:
            {
                if (!devAbilityModel.ability_light_flag) {
                    break;
                }
                [customGroup addObject:model];
                break;
            }
                
            case DeviceSettingBabyMusic:{
                if (!devAbilityModel.ability_babyMusic) {
                    break;
                }
                [customGroup addObject:model];
                break;
            
            }

            case DeviceSettingDBBellRemindSetting:
            {
                if (!devAbilityModel.ability_doorbell_ring) {
                    break;
                }
                [customGroup addObject:model];
                break;
            }
                
            case DeviceSettingDBLedRemindSetting:
            {
                if (!devAbilityModel.ability_doorbell_led) {
                    break;
                }
                [customGroup addObject:model];
                break;
            }
                
                
            case DeviceSettingTalkingMode:
            {
                //!devAbilityModel.ability_full_duplex_flag 改成用服务端获取的capModel判断
                bool isFullDuplexReady = true;
                if ( devAbilityModel.capModel.full_duplex_flag != 2 || !isFullDuplexReady) {
                    break;
                }
                [cameraSwitchGroup addObject:model];
                break;
            }
                
            case DeviceSettingCameraSwitch:
            {
                if (!devAbilityModel.ability_camera_sw_flag) {
                    break;
                }
                [cameraSwitchGroup addObject:model];
                break;
            }
            case DeviceSettingCameraMicrophone:
//            case DeviceSettingCellularDataAutoPause:
                if (!devAbilityModel.ability_camera_mic_sw_flag) {
                    break;
                }
                [cameraSwitchGroup addObject:model];
                break;
                
#pragma mark <灵敏度设置>
            case DeviceSettingMotionDetection:
            {
                if (!devAbilityModel.ability_motion_detection) {
                    break;
                }
                [normalActionGroup addObject:model];
                break;

            }
            case DeviceSettingVoiceDetection:
            {
                if (!devAbilityModel.ability_voice_detection_flag) {
                    break;
                }
                [normalActionGroup addObject:model];
                break;
            }
            case DeviceSettingPIRDetection:
            {
                // PIR开关 不在线隐藏
                if (!devAbilityModel.ability_pir || self.devModel.devCapModel.four_channel_flag==1 || self.devModel.Status != GosDeviceStatusOnLine) {
                    break;
                }
                [normalActionGroup addObject:model];
                break;
            }
                
            case  DeviceSettingBatteryLevel:
            {// 电池电量 不在线隐藏
                if (!devAbilityModel.ability_battery_level_flag || self.devModel.devCapModel.four_channel_flag==1 || self.devModel.Status != GosDeviceStatusOnLine) {
                    break;
                }
                [normalActionGroup addObject:model];
                break;
            }

            case DeviceSettingTempAlarmSetting:
            {
                if (!devAbilityModel.ability_temperature) {
                    break;
                }
                [normalActionGroup addObject:model];
                break;
            }
            
                
            case DeviceSettingCloudService:
                model.dataStorageTime = self.dataStorageTime;
                [cloudServiceGroup addObject:model];
                break;
                
                
            case DeviceSettingPhotoAlbum:
            {
                [manualRecordGroup addObject:model];
                break;
            }
            case DeviceSettingManualRecord:
            {
                //手动录像 没有SD卡槽则不支持录像,不在线隐藏
                if (_shareByFriend || self.devModel.Status != GosDeviceStatusOnLine ||
                    devAbilityModel.ability_sd == 0 || [self isWiFiDoorBell]) {
                    break;
                }
                [manualRecordGroup addObject:model];
                break;
            }
                
            case DeviceSettingStatusIndicator:
            {
                if (!devAbilityModel.ability_led_sw_flag) {
                    break;
                }
                [hardwareGroup addObject:model];
                break;
            }
            case DeviceSettingRotateSemicircle:
            {
                //设备离线 隐藏 旋转图像180度，TF卡手动录像 摄像头时间校验
                if (self.devModel.Status != GosDeviceStatusOnLine || [self isWiFiDoorBell]) {
                    break;
                }
                [hardwareGroup addObject:model];
                break;
            }
            case DeviceSettingNightVersion:
            {
                if (!devAbilityModel.ability_night_vison) {
                    break;
                }
                [hardwareGroup addObject:model];
                break;
            }
                
                
            case DeviceSettingShareWithFriends:
                [friendShareGroup addObject:model];
                break;
                
            case DeviceSettingTimeCheck:
            {
                if (_shareByFriend || self.devModel.Status != GosDeviceStatusOnLine) { //好友分享无设置权限
                    break;
                }
                [detailInfoGroup addObject:model];
                break;
            }
            case DeviceSettingWiFiSetting:
            {
                if (_shareByFriend) { //好友分享无设置权限
                    break;
                }
                [detailInfoGroup addObject:model];
                break;
            }
            case DeviceSettingDeviceInfo:
            {
                if (_shareByFriend) { //好友分享无设置权限
                    break;
                }
                [detailInfoGroup addObject:model];
                break;
            }
                
            case DeviceSettingUnbindSubDevice:
            {
                if (_shareByFriend || isUnbindDeviceUIReady==0) { //好友分享无设置权限
                    break;
                }
                [detailInfoGroup addObject:model];
                break;
            }
                
            default:
                break;
        }
    }

    if (self.shareByFriend == 0) {
        if (customGroup.count >0 ) {
            [self.data addObject:customGroup];
        }
        
        if (normalActionGroup.count >0 ) {
            [self.data addObject:normalActionGroup];
        }
        
        if (cameraSwitchGroup.count >0 ) {
            [self.data addObject:cameraSwitchGroup];
        }
        
        if (manualRecordGroup.count >0 ) {
            [self.data addObject:manualRecordGroup];
        }
        
        if (isCloudServiceReady) {
            [self.data addObject:cloudServiceGroup];
        }
        
        if (hardwareGroup.count >0 ) {
            [self.data addObject:hardwareGroup];
        }
        
        if (friendShareGroup.count >0 ) {
            [self.data addObject:friendShareGroup];
        }
        
        
        
        if (detailInfoGroup.count >0 ) {
            [self.data addObject:detailInfoGroup];
        }
    }else{
        
        if (cameraSwitchGroup.count > 0 ) {
            [self.data addObject: cameraSwitchGroup];
        }
        
        if (manualRecordGroup.count >0 ) {
            
            [self.data addObject:manualRecordGroup];
        }
        
        if (detailInfoGroup.count >0 ) {
            [self.data addObject:detailInfoGroup];
        }
        
    }
}

- (BOOL)isWiFiDoorBell{
    GosDetailedDeviceType detailType = [DeviceDataModel detailedDeviceTypeWithString:[self.devModel.DeviceId substringWithRange:NSMakeRange(3, 2)]];
    return detailType==GosDetailedDeviceType_T5100ZJ || detailType == GosDetailedDeviceType_T5200HCA;
}

-(NSMutableArray *)data
{
    if (_data==nil) {
        _data=[[NSMutableArray alloc]init];
    }
    return _data;
}

@end
