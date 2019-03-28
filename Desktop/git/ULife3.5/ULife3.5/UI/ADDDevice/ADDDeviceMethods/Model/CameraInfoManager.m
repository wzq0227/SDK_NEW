//
//  CameraInfoManager.m
//  QQI
//
//  Created by goscam on 16/3/15.
//  Copyright © 2016年 yuanx. All rights reserved.
//

#import "CameraInfoManager.h"

//typedef void(^BlockDeviceInfoResult)(int result,NSString *serial_id,NSString *macaddr,NSString *soft_ver,NSString *firm_ver,NSString *model_num,NSString *Wifi);

//typedef void (^BlockDeviceControlStateResult)(int result,unsigned int  alarm_control_enable,unsigned int  motion_alarm_enable,unsigned int  video_mode, unsigned int  video_quality,unsigned int  alarm_ring_no);

@implementation CameraInfoManager
- (id)copyWithZone:(NSZone *)zone{
    CameraInfoManager *model = [[[self class] allocWithZone:zone] init];
    model.device_id = [self.device_id copy];
    model.macaddr = [self.macaddr copy];
    model.soft_ver = [self.soft_ver copy];
    model.firm_ver = [self.firm_ver copy];
    model.model_num = [self.model_num copy];
    model.Wifi = [self.Wifi copy];
    model.video_mirror_mode = self.video_mirror_mode;
    model.manual_record_switch = self.manual_record_switch;
    model.motion_detect_sensitivity = self.motion_detect_sensitivity;
    model.pir_detect_switch = self.pir_detect_switch;
    model.video_quality = self.video_quality;
    return model;
}
@end
