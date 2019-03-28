//
//  DeviceDataModel.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/6.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "DeviceDataModel.h"
#import <objc/runtime.h>

@implementation NvrCovertImage

- (id)copyWithZone:(NSZone *)zone
{
    NvrCovertImage *nvrCovert  = [[[self class] allocWithZone:zone] init];
    nvrCovert.topLeftImage     = self.topLeftImage;
    nvrCovert.topRightImage    = self.topRightImage;
    nvrCovert.bottomLeftImage  = self.bottomLeftImage;
    nvrCovert.bottomRightImage = self.bottomRightImage;
    
    return nvrCovert;
}


- (id)mutableCopyWithZone:(NSZone *)zone
{
    NvrCovertImage *nvrCovert  = [[[self class] allocWithZone:zone] init];
    nvrCovert.topLeftImage     = self.topLeftImage;
    nvrCovert.topRightImage    = self.topRightImage;
    nvrCovert.bottomLeftImage  = self.bottomLeftImage;
    nvrCovert.bottomRightImage = self.bottomRightImage;
    
    return nvrCovert;
}

@end


@implementation SubDevInfoModel
- (NSString*)devAndSubDevID{
    if (!_devAndSubDevID) {
        _devAndSubDevID = [[_DeviceId substringFromIndex:8] stringByAppendingString:_SubId?:@""];
    }
    return _devAndSubDevID;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    SubDevInfoModel *model = [[[self class] allocWithZone:zone] init];

    unsigned int count;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    for (int i=0; i<count; i++) {
        objc_property_t property = properties[i];
        NSString *key = [NSString stringWithUTF8String:property_getName(property) ];
        [model setValue:[self valueForKey:key] forKey:key];
    }
    free(properties);
    return model;
}

- (id)mutableCopyWithZone:(nullable NSZone *)zone
{
    SubDevInfoModel *model = [[[self class] allocWithZone:zone] init];
    
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    for (int i=0; i<count; i++) {
        objc_property_t property = properties[i];
        NSString *key = [NSString stringWithUTF8String:property_getName(property) ];
        [model setValue:[self valueForKey:key] forKey:key];
    }
    free(properties);
    return model;
}

@end

@implementation StationInfoModel
@end

@implementation DeviceCapModel

- (id)mutableCopyWithZone:(nullable NSZone *)zone
{
    DeviceCapModel *model = [[[self class] allocWithZone:zone] init];
    
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    for (int i=0; i<count; i++) {
        objc_property_t property = properties[i];
        NSString *key = [NSString stringWithUTF8String:property_getName(property) ];
        [model setValue:[self valueForKey:key] forKey:key];
    }
    free(properties);
    return model;
}

- (id)copyWithZone:(NSZone *)zone{
    DeviceCapModel *devCap = [DeviceCapModel allocWithZone:zone];
    unsigned int pCnt;
    objc_property_t *properties = class_copyPropertyList([self class], &pCnt);
    for (int i=0; i<pCnt; i++) {
        NSString *keyName = @( property_getName(properties[i]) );
        [devCap setValue:[self valueForKey:keyName] forKey:keyName];
    }
    return devCap;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super init])
    {
        unsigned int pCnt;
        objc_property_t *properties = class_copyPropertyList([self class], &pCnt);
        for (int i=0; i<pCnt; i++) {
            NSString *keyName = @( property_getName(properties[i]) );
            [self setValue:[aDecoder decodeObjectForKey:keyName] forKey:keyName];
        }
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    unsigned int pCnt;
    objc_property_t *properties = class_copyPropertyList([self class], &pCnt);
    for (int i=0; i<pCnt; i++) {
        NSString *keyName = @( property_getName(properties[i]) );
        [aCoder encodeObject:[self valueForKey:keyName] forKey:keyName];
    }
}



+ (instancetype)capWithString:(NSString*)capStr{
    DeviceCapModel *capModel = [DeviceCapModel new];
    
    unsigned int pCount = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &pCount);
    for (int i=0; i<pCount; i++) {

        NSString *pName =  @(property_getName( properties[i] ));
        
        if ( i < capStr.length) {
            [capModel setInteger: [[capStr substringWithRange:NSMakeRange(i, 1)] intValue]  forKey: pName];
        }else{
            [capModel setInteger: 0  forKey: pName];
        }
        
    }

    return capModel;
}

- (void)setInteger:(NSInteger)intValue forKey:(nonnull NSString *)defaultName{
    [self setValue:@(intValue) forKey:defaultName];
}

- (NSInteger)integerForKey:(NSString *)defaultName{
    return [[self valueForKey:defaultName] intValue];
}

@end


@implementation DeviceDataModel

+ (GosDetailedDeviceType)detailedDeviceTypeWithString:(NSString*)typeStr{
    int firstLetter = [DeviceDataModel convertToBase36NumberWithValue: [typeStr characterAtIndex:0]];
    int secondLetter = [DeviceDataModel convertToBase36NumberWithValue: [typeStr characterAtIndex:1]];
    
    GosDetailedDeviceType devType = firstLetter *36 + secondLetter;
    return devType;
}

+ (int)convertToBase36NumberWithValue:(int)value{
    if (value >= '0' && value<= '9') {
        return value-'0';
    }else if(value >= 'A' && value<= 'Z'){
        return value - 'A'+10;
    }else{
        return value;
    }
}

- (id)copyWithZone:(NSZone *)zone
{
    DeviceDataModel *devModel = [[[self class] allocWithZone:zone] init];
    devModel.DeviceId         = [self.DeviceId copy];
    devModel.DeviceName       = [self.DeviceName copy];
    devModel.StreamUser       = [self.StreamUser copy];
    devModel.StreamPassword   = [self.StreamPassword copy];
    devModel.AreaId           = [self.AreaId copy];
    devModel.DeviceType       = self.DeviceType;
    devModel.DeviceOwner      = self.DeviceOwner;
    devModel.Status           = self.Status;
    devModel.covertImage      = self.covertImage;
    devModel.nvrCovertImage   = [self.nvrCovertImage copyWithZone:zone];
    
    devModel.smartStyle       = self.smartStyle;
    devModel.devWifiPwd       = [self.devWifiPwd copy];
    devModel.devWifiName      = [self.devWifiName copy];
    
    devModel.SubDevice        = [self.SubDevice copy];
    devModel.selectedSubDevInfo = [self.selectedSubDevInfo copy];
    devModel.stationModel     = [self.stationModel copy];
    devModel.devCapModel      = [self.devCapModel copy];
    return devModel;
}


- (id)mutableCopyWithZone:(NSZone *)zone
{
    DeviceDataModel *devModel = [[[self class] allocWithZone:zone] init];
    devModel.DeviceId         = [self.DeviceId mutableCopy];
    devModel.DeviceName       = [self.DeviceName mutableCopy];
    devModel.StreamUser       = [self.StreamUser mutableCopy];
    devModel.StreamPassword   = [self.StreamPassword mutableCopy];
    devModel.AreaId           = [self.AreaId mutableCopy];
    devModel.DeviceType       = self.DeviceType;
    devModel.DeviceOwner      = self.DeviceOwner;
    devModel.Status           = self.Status;
    devModel.covertImage      = self.covertImage;
    devModel.nvrCovertImage   = [self.nvrCovertImage mutableCopyWithZone:zone];
    
    devModel.smartStyle       = self.smartStyle;
    devModel.devWifiPwd       = [self.devWifiPwd mutableCopy];
    devModel.devWifiName      = [self.devWifiName mutableCopy];
    
    devModel.SubDevice        = [self.SubDevice mutableCopy];
    devModel.selectedSubDevInfo = [self.selectedSubDevInfo mutableCopy];
    devModel.stationModel     = [self.stationModel mutableCopy];
    devModel.devCapModel      = [self.devCapModel mutableCopy];
    return devModel;
}

@end


