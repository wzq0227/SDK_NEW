//
//  UiSetting.m
//  QQI
//
//  Created by goscam on 16/3/11.
//  Copyright © 2016年 yuanx. All rights reserved.
//

#import "UISettingManagement.h"
#import "NSArray+SNFoundation.h"
#import "TMCacheExtend.h"
#import <objc/runtime.h>

//@property(nonatomic,copy)NSString *UID;
//@property(nonatomic,assign)BOOL pir_flag;
//@property(nonatomic,assign)BOOL ptz_flag;
//@property(nonatomic,assign)BOOL mic_flag;
//@property(nonatomic,assign)BOOL speakr_flag;
//@property(nonatomic,assign)BOOL temperature_flag;

@implementation UISettingModel




- (id)initModelWithAbilityCmd:(CMD_GetDevAbilityResp *)devAbility UID:(NSString*)UID{
    self = [super init];
    if (self) {
        self.ability_id                   = UID;
        self.ability_pir                  = devAbility.c_pir_flag;
        self.ability_pir_distance         = devAbility.c_pir_distance_flag;
        self.ability_ptz                  = devAbility.c_ptz_flag;
        self.ability_mic                  = devAbility.c_mic_flag;
        self.ability_speakr               = devAbility.c_speaker_flag;
        self.ability_motion_detection     = devAbility.c_motion_detection_flag;
        self.ability_device_type          = devAbility.c_device_type;
        self.ability_resolution_0         = devAbility.un_resolution_0_flag;
        self.ability_resolution_1         = devAbility.un_resolution_1_flag;
        self.ability_resolution_2         = devAbility.un_resolution_2_flag;
        self.ability_encrypted_ic         = devAbility.c_encrypted_ic_flag;
        self.ability_sd                   = devAbility.c_sd_flag;
        self.ability_temperature          = devAbility.c_temperature_flag;
        self.ability_timezone             = devAbility.c_timezone_flag;
        self.ability_night_vison          = devAbility.c_night_vison_flag;
        self.ability_ethernet             = devAbility.ethernet_flag;
        self.ability_smart_connect        = devAbility.c_smart_connect_flag;

        self.ability_light_flag           = devAbility.c_light_flag;
        self.ability_voice_detection_flag = devAbility.c_audio_alarm_detection_flag;
        self.ability_babyMusic            = devAbility.align1;

        self.ability_led_sw_flag          = devAbility.c_led_sw_flag;
        self.ability_camera_sw_flag       = devAbility.c_camera_sw_flag;
        self.ability_camera_mic_sw_flag   = devAbility.c_camera_mic_sw_flag;

        self.ability_netlink_signal_flag  = devAbility.c_netlink_signal_flag;
        self.ability_battery_level_flag   = devAbility.c_battery_level_flag;
        self.ability_stream_passwd_flag   = devAbility.c_stream_passwd_flag;
        self.ability_c_Alexa_Skills_Kit_flag = devAbility.c_Alexa_Skills_Kit_flag;
        
        self.ability_doorbell_led = devAbility.c_doorbell_led;
        self.ability_doorbell_ring = devAbility.c_doorbell_ring;
        
        self.ability_full_duplex_flag = devAbility.c_full_duplex_flag;
    }
    return self;
}



- (void)encodeWithCoder:(NSCoder *)aCoder
{
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    for (int i=0; i<count; i++) {
        objc_property_t property = properties[i];
        NSString *key = [NSString stringWithUTF8String:property_getName(property) ];
        [aCoder encodeObject:[self valueForKey:key] forKey:key];
    }
    free(properties);
    
//    [aCoder encodeObject:self.ability_id forKey:@"ability_id"];
//    [aCoder encodeBool:self.ability_pir forKey:@"ability_pir"];
//    [aCoder encodeBool:self.ability_ptz forKey:@"ability_ptz"];
//    [aCoder encodeBool:self.ability_mic forKey:@"ability_mic"];
//    [aCoder encodeBool:self.ability_speakr forKey:@"ability_speakr"];
//    [aCoder encodeBool:self.ability_motion_detection forKey:@"motion_detection"];
//
//    [aCoder encodeBool:self.ability_device_type forKey:@"device_type"];
//    [aCoder encodeBool:self.ability_resolution_0 forKey:@"resolution_0"];
//    [aCoder encodeBool:self.ability_resolution_1 forKey:@"resolution_1"];
//    [aCoder encodeBool:self.ability_resolution_2 forKey:@"resolution_2"];
//    [aCoder encodeBool:self.ability_encrypted_ic forKey:@"encrypted_ic"];
//    [aCoder encodeBool:self.ability_sd forKey:@"sd"];
//    [aCoder encodeBool:self.ability_temperature forKey:@"temperature"];
//    [aCoder encodeBool:self.ability_timezone forKey:@"timezone"];
//    [aCoder encodeBool:self.ability_night_vison forKey:@"night_vison"];
//    [aCoder encodeBool:self.ability_ethernet forKey:@"ethernet"];
//    [aCoder encodeBool:self.ability_smart_connect forKey:@"smart_connect"];
//
//    [aCoder encodeBool:self.ability_light_flag forKey:@"light"];
//    [aCoder encodeBool:self.ability_voice_detection_flag forKey:@"voice_detection"];
//    [aCoder encodeInteger:self.ability_babyMusic forKey:@"babyMusic"];
//
//    [aCoder encodeBool:self.ability_led_sw_flag forKey:@"led_sw_flag"];
//    [aCoder encodeBool:self.ability_camera_sw_flag forKey:@"camera_sw_flag"];
//    [aCoder encodeBool:self.ability_camera_mic_sw_flag forKey:@"camera_mic_sw_flag"];
//
//    [aCoder encodeBool:self.ability_netlink_signal_flag forKey:@"netlink_signal_flag"];
//    [aCoder encodeBool:self.ability_battery_level_flag forKey:@"battery_level_flag"];
    
}



- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        unsigned int count;
        objc_property_t *properties = class_copyPropertyList([self class], &count);
        for (int i=0; i<count; i++) {
            objc_property_t property = properties[i];
            NSString *key = [NSString stringWithUTF8String:property_getName(property) ];
            [self setValue:[coder decodeObjectForKey:key] forKey:key];
        }
        free(properties);
        
//        self.ability_id = [coder decodeObjectForKey:@"ability_id"];
//        self.ability_pir = [coder decodeBoolForKey:@"ability_pir"];
//        self.ability_ptz = [coder decodeBoolForKey:@"ability_ptz"];
//        self.ability_mic = [coder decodeBoolForKey:@"ability_mic"];
//        self.ability_speakr = [coder decodeBoolForKey:@"ability_speakr"];
//        self.ability_motion_detection = [coder decodeBoolForKey:@"motion_detection"];
//
//
//        self.ability_device_type  = [coder decodeBoolForKey:@"device_type"];
//        self.ability_resolution_0 = [coder decodeBoolForKey:@"resolution_0"];
//        self.ability_resolution_1 = [coder decodeBoolForKey:@"resolution_1"];
//        self.ability_resolution_2 = [coder decodeBoolForKey:@"resolution_2"];
//        self.ability_encrypted_ic = [coder decodeBoolForKey:@"encrypted_ic"];
//        self.ability_sd = [coder decodeBoolForKey:@"sd"];
//        self.ability_temperature = [coder decodeBoolForKey:@"temperature"];
//        self.ability_timezone = [coder decodeBoolForKey:@"timezone"];
//        self.ability_night_vison = [coder decodeBoolForKey:@"night_vison"];
//        self.ability_ethernet = [coder decodeBoolForKey:@"ethernet"];
//        self.ability_smart_connect = [coder decodeBoolForKey:@"smart_connect"];
//
//        self.ability_light_flag = [coder decodeBoolForKey:@"light"];
//        self.ability_voice_detection_flag = [coder decodeBoolForKey:@"voice_detection"];
//        self.ability_babyMusic = [coder decodeIntegerForKey:@"babyMusic"];
//
//        self.ability_led_sw_flag = [coder decodeBoolForKey:@"led_sw_flag"];
//        self.ability_camera_sw_flag = [coder decodeBoolForKey:@"camera_sw_flag"];
//        self.ability_camera_mic_sw_flag = [coder decodeBoolForKey:@"camera_mic_sw_flag"];
//
//        self.ability_netlink_signal_flag = [coder decodeBoolForKey:@"netlink_signal_flag"];
//        self.ability_battery_level_flag = [coder decodeBoolForKey:@"battery_level_flag"];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    UISettingModel *model = [[[self class] allocWithZone:zone] init];
    
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    for (int i=0; i<count; i++) {
        objc_property_t property = properties[i];
        NSString *key = [NSString stringWithUTF8String:property_getName(property) ];
        [model setValue:[self valueForKey:key] forKey:key];
    }
    free(properties);
    
//    model.ability_id = [self.ability_id copy];
//    model.ability_pir = self.ability_pir;
//    model.ability_ptz = self.ability_ptz;
//    model.ability_mic = self.ability_mic;
//    model.ability_speakr = self.ability_speakr;
//    model.ability_motion_detection = self.ability_motion_detection;
//
//    model.ability_device_type  = self.ability_device_type ;
//    model.ability_resolution_0 = self.ability_resolution_0;
//    model.ability_resolution_1 = self.ability_resolution_1;
//    model.ability_resolution_2 = self.ability_resolution_2;
//    model.ability_encrypted_ic = self.ability_encrypted_ic ;
//    model.ability_sd  = self.ability_sd ;
//    model.ability_temperature  = self.ability_temperature ;
//    model.ability_timezone  = self.ability_timezone ;
//    model.ability_night_vison = self.ability_night_vison;
//    model.ability_ethernet  = self.ability_ethernet ;
//    model.ability_smart_connect = self.ability_smart_connect;
//
//    model.ability_light_flag           = self.ability_light_flag;
//    model.ability_voice_detection_flag = self.ability_voice_detection_flag;
//    model.ability_babyMusic            = self.ability_babyMusic;
//    model.ability_led_sw_flag              = self.ability_led_sw_flag;
//    model.ability_camera_sw_flag        = self.ability_camera_sw_flag;
//    model.ability_camera_mic_sw_flag    = self.ability_camera_mic_sw_flag;
//
//    model.ability_netlink_signal_flag        = self.ability_netlink_signal_flag;
//    model.ability_battery_level_flag    = self.ability_battery_level_flag;
    return model;
}
@end

@implementation UiSettingObject
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    NSData *listData = [NSKeyedArchiver archivedDataWithRootObject:self.itemList];
    [aCoder encodeObject:listData forKey:@"list"];
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        NSData *listData = [coder decodeObjectForKey:@"list"];
        self.itemList = [NSKeyedUnarchiver unarchiveObjectWithData:listData];
    }
    return self;
}

//深拷贝
-(id) mutableCopyWithZone : (NSZone *) zone
{
    UiSettingObject *dto = [[UiSettingObject allocWithZone : zone] init];
    dto.itemList = [self.itemList trueDeepMutableCopy];
    return dto;
}

- (id)copyWithZone:(NSZone *)zone{
    UiSettingObject *dto = [[[self class] allocWithZone:zone] init];
    dto.itemList = [self.itemList trueDeepMutableCopy];
    return dto;
}
@end

@interface UISettingManagement ()
@property(nonatomic,strong)UiSettingObject *uiSettingObject;
@end
@implementation UISettingManagement

+(UISettingManagement *)sharedInstance
{
    static UISettingManagement *_sharedMyClass = nil;
    static dispatch_once_t token;
    if(_sharedMyClass == nil)
    {
        dispatch_once(&token,^{
            _sharedMyClass = [[UISettingManagement alloc] init];}
                      );
    }
    return _sharedMyClass;
}

-(instancetype)init
{
    if (self = [super init])
    {
        UiSettingObject *settingObjce = [[TMCache TemporaryCache] objectForKey:@"UiSettingCache"];
        if (settingObjce != nil) {
            self.uiSettingObject = settingObjce;
        }
        else
        {
            self.uiSettingObject = [[UiSettingObject alloc]init];
            self.uiSettingObject.itemList = [[NSMutableArray alloc]init];
        }
    }
    return self;
}

-(void)addSettingModel:(UISettingModel *)SettingModel
{
    if (SettingModel == nil) {
        return;
    }
    
    if ([self.uiSettingObject.itemList count] > 0)
    {
        BOOL Flag = NO;
        for (int i = 0; i < [self.uiSettingObject.itemList count]; i++) {
            UISettingModel *model = _uiSettingObject.itemList[i];
            if ([model.ability_id isEqualToString:SettingModel.ability_id]) {
                Flag = YES;
            }
        }
        
        if (!Flag) {
            [self.uiSettingObject.itemList addObject:SettingModel];
            [self saveData];
        }
    }
    else
    {
        [self.uiSettingObject.itemList addObject:SettingModel];
        [self saveData];
    }
}

-(UISettingModel *)getSettingModel:(NSString *)UID
{
    if (UID == nil) {
        return nil;
    }
    
    UISettingModel *SettingModel = nil;
    if ([self.uiSettingObject.itemList count] > 0) {
        for (int i = 0; i < [self.uiSettingObject.itemList count]; i++) {
            UISettingModel *model = _uiSettingObject.itemList[i];
            if ([model.ability_id isEqualToString:UID]) {
                SettingModel = model;
                break;
            }
        }
    }
    return SettingModel;
}


-(void)removeSettingModel:(NSString *)UID
{
    if (UID == nil) {
        return;
    }
    
    if ([self.uiSettingObject.itemList count] > 0)
    {
        for (int i = 0; i < [self.uiSettingObject.itemList count]; i++) {
            UISettingModel *model = _uiSettingObject.itemList[i];
            if ([model.ability_id isEqualToString:UID]) {
                [self.uiSettingObject.itemList removeObject:model];
                [self saveData];
                return;
            }
        }
    }
}

-(void)saveData
{
    if (_uiSettingObject != nil) {
        [[TMCache TemporaryCache] setObject:self.uiSettingObject forKey:@"UiSettingCache"];
    }
}
@end
