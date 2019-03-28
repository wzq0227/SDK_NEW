//
//  PushDevSetingStateModel.m
//  ULife3.5
//
//  Created by 李子爽 on 2018/1/10.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "PushDevSetingStateModel.h"

@implementation PushDevSetingStateModel

-(instancetype)initWithDict:(NSDictionary *)dict
{
    self= [super init];
    if (self) {
        self.DeviceId = dict[@"DeviceId"];
        self.Status = [dict[@"PushFlag"] intValue];
        NSLog(@"%@======= %d======",self.DeviceId ,self.Status);
    }
    return self;
}

@end
