//
//  PushMessageModel.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/7.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "PushMessageModel.h"

@implementation PushMessageModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _subChannel = -1;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    PushMessageModel *apnsMsgModel = [[[self class] allocWithZone:zone] init];
    apnsMsgModel.serialNum         = self.serialNum;
    apnsMsgModel.email             = [self.email copy];
    apnsMsgModel.deviceId          = [self.deviceId copy];
    apnsMsgModel.deviceName        = [self.deviceName copy];
    apnsMsgModel.pushUrl           = [self.pushUrl copy];
    apnsMsgModel.pushTime          = [self.pushTime copy];
    apnsMsgModel.apnsMsgReadState  = self.apnsMsgReadState;
    apnsMsgModel.apnsMsgType       = self.apnsMsgType;
    apnsMsgModel.isShowDelete      = self.isShowDelete;
    apnsMsgModel.isSelectDelete    = self.isSelectDelete;
    
    apnsMsgModel.subChannel        = self.subChannel;
    apnsMsgModel.subDeviceID       = self.subDeviceID;
    return apnsMsgModel;
}


- (id)mutableCopyWithZone:(NSZone *)zone
{
    PushMessageModel *apnsMsgModel = [[[self class] allocWithZone:zone] init];
    apnsMsgModel.serialNum         = self.serialNum;
    apnsMsgModel.email             = [self.email mutableCopy];
    apnsMsgModel.deviceId          = [self.deviceId mutableCopy];
    apnsMsgModel.deviceName        = [self.deviceName mutableCopy];
    apnsMsgModel.pushUrl           = [self.pushUrl mutableCopy];
    apnsMsgModel.pushTime          = [self.pushTime mutableCopy];
    apnsMsgModel.apnsMsgReadState  = self.apnsMsgReadState;
    apnsMsgModel.apnsMsgType       = self.apnsMsgType;
    apnsMsgModel.isShowDelete      = self.isShowDelete;
    apnsMsgModel.isSelectDelete    = self.isSelectDelete;
    
    apnsMsgModel.subChannel        = self.subChannel;
    apnsMsgModel.subDeviceID       = self.subDeviceID;
    return apnsMsgModel;
}



@end
