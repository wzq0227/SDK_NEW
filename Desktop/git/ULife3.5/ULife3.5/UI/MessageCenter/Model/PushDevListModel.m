//
//  PushDevListModel.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/13.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "PushDevListModel.h"

@implementation PushDevModel

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        self.deviceId = [aDecoder decodeObjectForKey:@"deviceId"];
        self.isRegistry = [[aDecoder decodeObjectForKey:@"isRegistry"] boolValue];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.deviceId forKey:@"deviceId"];
    [aCoder encodeObject:[NSNumber numberWithBool:self.isRegistry] forKey:@"isRegistry"];
}


- (id)copyWithZone:(NSZone *)zone
{
    PushDevModel *pushDevModel = [[[self class] allocWithZone:zone] init];
    pushDevModel.deviceId      = [self.deviceId copy];
    pushDevModel.isRegistry    = self.isRegistry;
    
    return pushDevModel;
}


- (id)mutableCopyWithZone:(NSZone *)zone
{
    PushDevModel *pushDevModel = [[[self class] allocWithZone:zone] init];
    pushDevModel.deviceId      = [self.deviceId mutableCopy];
    pushDevModel.isRegistry    = self.isRegistry;
    
    return pushDevModel;
}

@end

@implementation PushDevListModel

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        self.pushToken = [aDecoder decodeObjectForKey:@"pushToken"];
        self.deviceArray = [aDecoder decodeObjectForKey:@"deviceArray"];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.pushToken forKey:@"pushToken"];
    [aCoder encodeObject:self.deviceArray forKey:@"deviceArray"];
}


- (id)copyWithZone:(NSZone *)zone
{
    PushDevListModel *pushDevListModel = [[[self class] allocWithZone:zone] init];
    pushDevListModel.pushToken      = [self.pushToken copy];
    pushDevListModel.deviceArray    = self.deviceArray;
    
    return pushDevListModel;
}


- (id)mutableCopyWithZone:(NSZone *)zone
{
    PushDevListModel *pushDevListModel = [[[self class] allocWithZone:zone] init];
    pushDevListModel.pushToken      = [self.pushToken mutableCopy];
    pushDevListModel.deviceArray    = self.deviceArray;
    
    return pushDevListModel;
}

@end
