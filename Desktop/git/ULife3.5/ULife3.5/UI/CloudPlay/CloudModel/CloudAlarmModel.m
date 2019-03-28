//
//  CloudAlarmModel.m
//  TestAli
//
//  Created by AnDong on 2017/10/13.
//  Copyright © 2017年 AnDong. All rights reserved.
//

#import "CloudAlarmModel.h"

@implementation CloudAlarmModel

- (id)copyWithZone:(NSZone *)zone
{
    CloudAlarmModel *alarmModel  = [[[self class] allocWithZone:zone] init];
    alarmModel.eventDesc = self.eventDesc;
    alarmModel.timeStamp = self.timeStamp;
    alarmModel.accuracyTimeStamp = self.accuracyTimeStamp;
    return alarmModel;
}


- (id)mutableCopyWithZone:(NSZone *)zone
{
    CloudAlarmModel *alarmModel  = [[[self class] allocWithZone:zone] init];
    alarmModel.eventDesc = self.eventDesc;
    alarmModel.timeStamp = self.timeStamp;
    alarmModel.accuracyTimeStamp = self.accuracyTimeStamp;
    return alarmModel;
}

@end
