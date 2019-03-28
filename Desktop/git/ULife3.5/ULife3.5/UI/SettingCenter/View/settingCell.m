//
//  settingCell.m
//  goscamapp
//
//  Created by goscam_sz on 17/5/6.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "settingCell.h"

@interface settingCell()
{
    
}

@end

@implementation settingCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)refreshUIWithModel:(dataModel *)model
{
    _nameLabel.text = DPLocalizedString(model.name);
    _iconImageView.image = [UIImage imageNamed:model.name];
    self.detailLabel.hidden = [self hideDetailLabelWithModel:model];
    self.detailImageView.hidden = model.deviceSettingType!=DeviceSettingBatteryLevel;

    self.detailLabel.text   = [self detailLabelStringWithModel:model];
    self.detailLabel.font = [UIFont systemFontOfSize:SCREEN_WIDTH<328?12:14 ];
    
    self.settingArrow.hidden = ![self hasNextPageArrowWithType:model.deviceSettingType];
    self.settingSwitch.hidden = (model.deviceSettingType==DeviceSettingBatteryLevel || model.deviceSettingType == DeviceSettingDBBellRemindSetting) ? YES : !self.settingArrow.hidden;
    
    self.selectionStyle = self.settingSwitch.hidden? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
    self.model = model;
}

- (BOOL)hideDetailLabelWithModel:(dataModel *)model{
    BOOL showDetailLabel = false;
    switch (model.deviceSettingType) {
       
        case DeviceSettingTalkingMode:
        case DeviceSettingCloudService:
            showDetailLabel = true;
            break;
            
        default:
        {
            showDetailLabel = false;
            break;
        }
    }
    return !showDetailLabel;
}

- (NSString *)detailLabelStringWithModel:(dataModel *)model{
    if (model.deviceSettingType == DeviceSettingCloudService) {
        return [self csStatusStringWithDataStorageDays:model.dataStorageTime];
    }else if (model.deviceSettingType == DeviceSettingTalkingMode){
        
        NSString *talkingModeStr = [mUserDefaults stringForKey:[@"TalkingMode_" stringByAppendingString:model.deviceId] ]?:@"FullDuplex";

        NSString *talkingStr = [NSString stringWithFormat:@"Setting_TalkingMode_%@",talkingModeStr];

        return DPLocalizedString(talkingStr);
    }
    return nil;
}


- (NSString *)csStatusStringWithDataStorageDays:(int)days{
    NSString *str = DPLocalizedString(@"Setting_Detail_OrderNow");
    if (days != 0) {
        str = [NSString stringWithFormat:@"%d%@",days,DPLocalizedString(@"CS_PackageType_Days")];
    }
    return str;
}

- (BOOL)hasNextPageArrowWithType:(DeviceSettingType)type{
    BOOL hasNextPage = NO;
    switch (type) {
        case DeviceSettingLightDuration:
            
        case DeviceSettingTalkingMode:
            
        case DeviceSettingPhotoAlbum:
        case DeviceSettingVoiceDetection:
        case DeviceSettingMotionDetection:
        case DeviceSettingTempAlarmSetting:
            
        case DeviceSettingCloudService:
        case DeviceSettingNightVersion:
        case DeviceSettingShareWithFriends:
            
        case DeviceSettingTimeCheck:
        case DeviceSettingWiFiSetting:
        case DeviceSettingDeviceInfo:
        case DeviceSettingBabyMusic:
        case DeviceSettingAlexa:
        case DeviceSettingDBBellRemindSetting:
            hasNextPage = YES;
            break;
            
        default:
            hasNextPage = NO;
            break;
    }
    return hasNextPage;
}

@end
