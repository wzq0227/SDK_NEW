//
//  PushDevSetingStateModel.h
//  ULife3.5
//
//  Created by 李子爽 on 2018/1/10.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PushDevSetingStateModel : NSObject

@property (nonatomic,strong) NSString *DeviceId;

@property (nonatomic,assign) int Status;

-(instancetype)initWithDict:(NSDictionary *)dict;

@end
