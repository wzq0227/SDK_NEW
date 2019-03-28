//
//  NvrPlaybackListModel.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/21.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "NvrPlaybackListModel.h"

@implementation NvrPlaybackListModel

- (id)copyWithZone:(NSZone *)zone
{
    NvrPlaybackListModel *listModel = [[NvrPlaybackListModel allocWithZone:zone] init];
    
    listModel.deviceId    = [self.deviceId copy];
    listModel.fileName    = [self.fileName copy];
    listModel.startTime   = [self.startTime copy];
    listModel.endTime     = [self.endTime copy];
    listModel.length      = self.length;
    listModel.frames      = self.frames;
    listModel.channelMask = self.channelMask;
    listModel.recordType  = self.recordType;
    
    return listModel;
}



- (id)mutableCopyWithZone:(NSZone *)zone
{
    NvrPlaybackListModel *listModel = [[NvrPlaybackListModel allocWithZone:zone] init];
    
    listModel.deviceId    = [self.deviceId mutableCopy];
    listModel.fileName    = [self.fileName mutableCopy];
    listModel.startTime   = [self.startTime mutableCopy];
    listModel.endTime     = [self.endTime mutableCopy];
    listModel.length      = self.length;
    listModel.frames      = self.frames;
    listModel.channelMask = self.channelMask;
    listModel.recordType  = self.recordType;
    
    return listModel;
}

@end
