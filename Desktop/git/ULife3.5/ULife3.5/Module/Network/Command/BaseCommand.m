//
//  BaseCommand.m
//  ULife2
//
//  Created by zhuochuncai on 6/4/17.
//  Copyright © 2017年 zhuochuncai. All rights reserved.
//

#import "BaseCommand.h"
#import <objc/runtime.h>

@implementation BaseCommand
-(NSDictionary *)requestCMDData{
    return [self yy_modelToJSONObject];
}
-(void)modelSetWithDictionary:(NSDictionary*)dict{
    NSMutableDictionary *data = [dict mutableCopy];
    [data removeObjectForKey:@"CMDType"];
    [self yy_modelSetWithDictionary:data];
}

- (id)copyWithZone:(NSZone *)zone{
    id baseCMD = [[[self class] allocWithZone:zone] init];
    //BaseCommand
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    for (int i=0; i<count; i++) {
        objc_property_t property = properties[i];
        NSString *key = [NSString stringWithUTF8String:property_getName(property) ];
        [baseCMD setValue:[self valueForKey:key] forKey:key];
    }
    free(properties);
    return baseCMD;
}

@end


@implementation CMD_DevInfo
@end
@implementation CMD_GetDevInfoReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_DEVINFO_REQ;
    }
    return self;
}
@end
@implementation CMD_GetDevInfoResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_DEVINFO_RESP;
    }
    return self;
}
@end


//子设备信息
@implementation CMD_SubDevInfo
@end
@implementation CMD_GetSubDevInfoReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_SUB_DEVICE_INFO_REQ ;
    }
    return self;
}
@end
@implementation CMD_GetSubDevInfoResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_SUB_DEVICE_INFO_RESP;
    }
    return self;
}
@end



@implementation CMD_DevAbility
@end
@implementation CMD_GetDevAbilityReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_DEVICE_ABILITY_REQ;
    }
    return self;
}
@end
@implementation CMD_GetDevAbilityResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_DEVICE_ABILITY_RESP;
    }
    return self;
}
@end


@implementation CMD_GetAllParamReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_ALL_PARAM_REQ;
    }
    return self;
}
@end
@implementation CMD_GetAllParamResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_ALL_PARAM_RESP;
    }
    return self;
}
@end


@implementation CMD_SetVideoModeReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SET_VIDEOMODE_REQ;
    }
    return self;
}
@end
@implementation CMD_SetVideoModeResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SET_VIDEOMODE_RESP;
    }
    return self;
}
@end



@implementation CMD_SetPirDetectReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SET_PIRDETECT_REQ;
    }
    return self;
}
@end
@implementation CMD_SetPirDetectResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SET_PIRDETECT_RESP;
    }
    return self;
}
@end
@implementation CMD_GetPirDetectReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_PIRDETECT_REQ;
    }
    return self;
}
@end
@implementation CMD_GetPirDetectResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_PIRDETECT_RESP;
    }
    return self;
}

@end

@implementation CMD_SetChannelPirDetectReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SET_CHANNEL_PIRDETECT_REQ;
    }
    return self;
}
@end
@implementation CMD_SetChannelPirDetectResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SET_CHANNEL_PIRDETECT_RESP;
    }
    return self;
}
@end


@implementation CMD_GetChannelPirDetectReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_CHANNEL_PIRDETECT_REQ;
    }
    return self;
}
@end
@implementation CMD_GetChannelPirDetectResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_CHANNEL_PIRDETECT_RESP;
    }
    return self;
}
@end




@implementation CMD_MotionDetect
@end

@implementation CMD_SetMotionDetectReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SETMOTIONDETECT_REQ;
        self.un_mode = 1;
        self.un_submode = 3;
    }
    return self;
}
@end
@implementation CMD_SetMotionDetectResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SETMOTIONDETECT_RESP;
    }
    return self;
}
@end



@implementation CMD_GetMotionDetectReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GETMOTIONDETECT_REQ;
    }
    return self;
}
@end
@implementation CMD_GetMotionDetectResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GETMOTIONDETECT_RESP;
    }
    return self;
}
@end


@implementation CMD_SetManualRecordReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_MANUAL_RECORD_REQ;
    }
    return self;
}
@end
@implementation CMD_SetManualRecordResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_MANUAL_RECORD_RESP;
    }
    return self;
}
@end


@implementation CMD_AudioAlarm
@end
@implementation CMD_SetAudioAlarmReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SET_AUDIO_ALARM_REQ;
    }
    return self;
}
@end
@implementation CMD_SetAudioAlarmResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SET_AUDIO_ALARM_RESP;
    }
    return self;
}
@end

@implementation CMD_GetAudioAlarmReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_AUDIO_ALARM_REQ;
    }
    return self;
}
@end
@implementation CMD_GetAudioAlarmResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_AUDIO_ALARM_RESP;
    }
    return self;
}
@end



@implementation CMD_SDCardInfo
@end
@implementation CMD_GetSDCardInfoReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_STORAGE_INFO_REQ;
    }
    return self;
}
@end

@implementation CMD_GetSDCardInfoResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_STORAGE_INFO_RESP;
    }
    return self;
}
@end


@implementation CMD_FormatSDCardReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_FORMAT_STORAGE_REQ;
    }
    return self;
}
@end
@implementation CMD_FormatSDCardResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_FORMAT_STORAGE_RESP;
    }
    return self;
}
@end



@implementation CMD_TempAlarm
@end
@implementation CMD_GetTempAlarmReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_TEMPERATURE_REQ;
    }
    return self;
}
@end
@implementation CMD_GetTempAlarmResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_TEMPERATURE_RESP;
    }
    return self;
}
@end

@implementation CMD_SetTempAlarmReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SET_TEMPERATURE_REQ;
    }
    return self;
}
@end
@implementation CMD_SetTempAlarmResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SET_TEMPERATURE_RESP;
    }
    return self;
}
@end


@implementation CMD_SetDevicePassword
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SETPASSWORD_REQ;
    }
    return self;
}
@end


@implementation CMD_SetBabyMusicReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SET_ALARM_RING_REQ;
    }
    return self;
}
@end

@implementation CMD_GetBabyMusicReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_ALARM_RING_REQ;
    }
    return self;
}
@end

@implementation CMD_openBabyMusicReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_PLAY_ALARM_RING_START;
    }
    return self;
}
@end

@implementation CMD_closeBabyMusicReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_PLAY_ALARM_RING_STOP;
    }
    return self;
}
@end

@implementation CMD_searchSDAlarmReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = 1922;
    }
    return self;
}
@end

@implementation CMD_searchSDVideoReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = 1920;
    }
    return self;
}
@end

@implementation CMD_WifiInfo
@end
@implementation CMD_SetWifiInfoReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SETWIFI_REQ;
    }
    return self;
}
@end
@implementation CMD_SetWifiInfoResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SETWIFI_RESP;
    }
    return self;
}
@end


@implementation CMD_NTPTimeParam
@end

@implementation CMD_GetNTPTimeParamReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_TIME_PARAM_REQ;
    }
    return self;
}
@end
@implementation CMD_GetNTPTimeParamResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_TIME_PARAM_RESP;
    }
    return self;
}
@end

@implementation CMD_SetNTPTimeParamReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SET_TIME_PARAM_REQ;
    }
    return self;
}
@end
@implementation CMD_SetNTPTimeParamResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SET_TIME_PARAM_RESP;
    }
    return self;
}
@end


@implementation CMD_SetPTZReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_PTZ_COMMAND;
    }
    return self;
}
@end
@implementation CMD_SetPTZResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_PTZ_COMMAND;
    }
    return self;
}
@end



@implementation CMD_RecordFile
@end
@implementation CMD_GetRecFileOneMonthReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_MONTH_EVENT_LIST_REQ;
    }
    return self;
}
@end
@implementation CMD_GetRecFileOneMonthResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_MONTH_EVENT_LIST_RESP;
    }
    return self;
}
@end



@implementation CMD_GetRecFileOneDayReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_DAY_EVENT_LIST_REQ;
    }
    return self;
}
@end
@implementation CMD_GetRecFileOneDayResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_DAY_EVENT_LIST_RESP;
    }
    return self;
}
@end



//录像文件
@implementation CMD_DownloadRecordFileReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_RECORDFILE_START_REQ;
    }
    return self;
}
@end
@implementation CMD_DownloadRecordFileResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_RECORDFILE_START_RESP;
    }
    return self;
}
@end



@implementation CMD_DeleteRecordFileReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_DEL_RECORDFILE_REQ;
    }
    return self;
}
@end
@implementation CMD_DeleteRecordFileResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_DEL_RECORDFILE_RESP;
    }
    return self;
}
@end


@implementation CMD_StopDownloadingRecFileReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_RECORDFILE_STOP_REQ;
    }
    return self;
}
@end
@implementation CMD_StopDownloadingRecFileResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_RECORDFILE_STOP_RESP;
    }
    return self;
}
@end


//CameraSwitch
@implementation CMD_CameraSwitch
@end

//CMD_GetCameraSwitchReq
@implementation CMD_GetCameraSwitchReq :BaseCommand
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_DEVICE_SWITCH_REQ;
    }
    return self;
}
@end
@implementation CMD_GetCameraSwitchResp : CMD_CameraSwitch
@end

@implementation CMD_SetCameraSwitchReq :CMD_CameraSwitch
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_DEVICE_SWITCH_REQ;
    }
    return self;
}
@end
@implementation CMD_SetCameraSwitchResp :BaseCommand
@end


//MIC
@implementation CMD_Device_Mic : BaseCommand
@end
@implementation CMD_SetDeviceMicSwitchReq :CMD_Device_Mic
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_DEVICE_MIC_SWITCH_REQ;
    }
    return self;
}
@end
@implementation CMD_SetDeviceMicSwitchResp :BaseCommand
@end


//LED
@implementation CMD_Device_Led : BaseCommand
@end

@implementation CMD_SetDeviceLedSwitchReq :CMD_Device_Led
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_DEVICE_LED_SWITCH_REQ;
    }
    return self;
}
@end
@implementation CMD_SetDeviceLedSwitchResp :BaseCommand
@end


//夜视

@implementation CMD_Device_Night : BaseCommand
@end

@implementation CMD_SetDeviceNightSwitchReq :CMD_Device_Night
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_DEVICE_SET_NIGHT_SWITCH_REQ;
    }
    return self;
}
@end
@implementation CMD_SetDeviceNightSwitchResp :BaseCommand
@end

@implementation CMD_GetDeviceNightSwitchReq :BaseCommand
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_DEVICE_GET_NIGHT_SWITCH_REQ;
    }
    return self;
}
@end
@implementation CMD_GetDeviceNightSwitchResp :CMD_Device_Night
@end



@implementation CMD_Device_NTSC_PAL : BaseCommand
@end

@implementation CMD_SetDevice_NTSC_PALReq :CMD_Device_NTSC_PAL
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_DEVICE_NTSC_PAL_REQ;
    }
    return self;
}
@end
@implementation CMD_SetDevice_NTSC_PALResp :BaseCommand
@end


@implementation CMD_LightDuration
@end

@implementation CMD_SetLightDurationReq :CMD_LightDuration
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SET_LIGHT_TIMING_INFO_REQ;
    }
    return self;
}
@end;
@implementation CMD_GetLightDurationReq : BaseCommand
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_LIGHT_TIMING_INFO_REQ;
    }
    return self;
}
@end

@implementation CMD_GetLightDurationResp : CMD_LightDuration
@end


@implementation CMD_LightSwitch : BaseCommand
@end

@implementation CMD_SetLightSwitchReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SET_LIGHT_REQ;
    }
    return self;
}
@end
@implementation CMD_SetLightSwitchResp :BaseCommand
@end


@implementation CMD_PlayAlarmRingReq :BaseCommand
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_PLAY_ALARM_RING_START;
    }
    return self;
}
@end
@implementation CMD_PlayAlarmRingResp :BaseCommand
@end


@implementation CMD_GetBatteryLevelReq :BaseCommand
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_BATTERY_LEVEL_REQ;
    }
    return self;
}
@end
@implementation CMD_GetBatteryLevelResp :BaseCommand
@end


@implementation CMD_GetNetLinkSignalLevelReq :BaseCommand
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_NETLINKSIGNAL_REQ;
    }
    return self;
}
@end
@implementation CMD_GetNetLinkSignalLevelResp :BaseCommand
@end


@implementation CMD_GetDoorbellCameraStatusReq :BaseCommand
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_CAMEREA_STATUS_REQ;
    }
    return self;
}
@end
@implementation CMD_GetDoorbellCameraStatusResp :BaseCommand
@end


@implementation CMD_SSIDInfo:NSObject
@end
@implementation CMD_GetDeviceSSIDListReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_DEVICE_SEARCH_SSID_REQ;
    }
    return self;
}
@end

@implementation CMD_GetDeviceSSIDListResp
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_DEVICE_SEARCH_SSID_RESP;
    }
    return self;
}
@end



@implementation CMD_UpdateDeviceReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SET_UPDATE_REQ;
    }
    return self;
}
@end
@implementation CMD_UpdateDeviceResp
@end

//CMD_CancelUpdateDeviceReq
@implementation CMD_CancelUpdateDeviceReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SET_CANCEL_UPDATE_REQ;
    }
    return self;
}
@end
@implementation CMD_CancelUpdateDeviceResp
@end


@implementation CMD_DeleteSubDeviceReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_DELETE_CAMEREA_PAIR_REQ;
    }
    return self;
}
@end
@implementation CMD_DeleteSubDeviceResp
@end



@implementation CMD_SetDBLedRemindReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SET_DOORBELL_LED_REMIND_REQ;
    }
    return self;
}
@end
@implementation CMD_SetDBLedRemindResp
@end



@implementation CMD_SetDBBellRemindReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SET_DOORBELL_RING_REMIND_REQ;
    }
    return self;
}
@end
@implementation CMD_SetDBBellRemindResp
@end

//
@implementation CMD_NotifyAddSubDevSuccessfullyReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_ADD_SUB_DEVICE_SUCCESSFUL_MSG;
    }
    return self;
}
@end
@implementation CMD_NotifyAddSubDevSuccessfullyResp
@end


@implementation CMD_NotifyDeleteSubDevReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_DELETE_SUB_DEVICE_SUCCESSFUL_MSG;
    }
    return self;
}
@end
@implementation CMD_NotifyDeleteSubDevResp
@end


@implementation CMD_GetDBBellVolumeReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_GET_GATEWAY_VOLUME_REQ;
    }
    return self;
}
@end
@implementation CMD_GetDBBellVolumeResp
@end


@implementation CMD_SetDBBellVolumeReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_SET_GATEWAY_VOLUME_REQ;
    }
    return self;
}
@end
@implementation CMD_SetDBBellVolumeResp
@end



@implementation CMD_DeleteTFFileReq
- (id)init{
    self = [super init];
    if (self) {
        self.CMDType = IOTYPE_USER_IPCAM_DEVICE_DELETE_RECORDFILE_REQ;
    }
    return self;
}
@end
@implementation CMD_DeleteTFFileResp

@end
