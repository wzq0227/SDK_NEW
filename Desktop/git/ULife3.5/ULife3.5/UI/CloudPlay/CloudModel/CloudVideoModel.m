//
//  CloudVideoModel.m
//  TestAli
//
//  Created by AnDong on 2017/10/13.
//  Copyright © 2017年 AnDong. All rights reserved.
//

#import "CloudVideoModel.h"

@implementation CloudVideoModel

- (id)copyWithZone:(NSZone *)zone
{
    CloudVideoModel *videoModel  = [[[self class] allocWithZone:zone] init];
    videoModel.startTime = self.startTime;
    videoModel.endTime = self.endTime;
//    videoModel.bucket = self.bucket;
//    videoModel.deviceId = self.deviceId;
//    videoModel.id = self.id;
//    videoModel.firstStamp = self.firstStamp;
//    videoModel.lastStamp = self.lastStamp;
//    videoModel.rtmpKey = self.rtmpKey;
//    videoModel.lastStamp = self.lastStamp;
    videoModel.accuracylastStamp = self.accuracylastStamp;
    videoModel.accuracyfirstStamp = self.accuracyfirstStamp;
    return videoModel;
}


- (id)mutableCopyWithZone:(NSZone *)zone
{
    CloudVideoModel *videoModel  = [[[self class] allocWithZone:zone] init];
    videoModel.startTime = self.startTime;
    videoModel.endTime = self.endTime;
//    videoModel.bucket = self.bucket;
//    videoModel.deviceId = self.deviceId;
//    videoModel.id = self.id;
//    videoModel.firstStamp = self.firstStamp;
//    videoModel.lastStamp = self.lastStamp;
//    videoModel.rtmpKey = self.rtmpKey;
//    videoModel.lastStamp = self.lastStamp;
    videoModel.accuracylastStamp = self.accuracylastStamp;
    videoModel.accuracyfirstStamp = self.accuracyfirstStamp;
    return videoModel;
}

@end
