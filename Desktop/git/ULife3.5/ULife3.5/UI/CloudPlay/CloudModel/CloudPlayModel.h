//
//  CloudPlayModel.h
//  ULife3.5
//
//  Created by AnDong on 2017/10/20.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CloudPlayModel : NSObject

@property (nonatomic,assign)long long startTime;
@property (nonatomic,assign)long long endTime;
@property (nonatomic,assign)int dateLife;


@property (nonatomic,copy)NSString *bucket;
@property (nonatomic,copy)NSString *key;

//相对于今天的准确stamp 这个用于计算自己赋值
@property (nonatomic,assign)long long accuracyfirstStamp;
@property (nonatomic,assign)long long accuracylastStamp;
@property (nonatomic,assign)int alarmType;

@end
