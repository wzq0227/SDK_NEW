//
//  CloudVideoModel.h
//  TestAli
//
//  Created by AnDong on 2017/10/13.
//  Copyright © 2017年 AnDong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CloudVideoModel : NSObject<
NSCopying,
NSMutableCopying
>

//@property (nonatomic,copy)NSString *bucket;
//@property (nonatomic,copy)NSString *deviceId;
//@property (nonatomic,assign)long long firstStamp;
//@property (nonatomic,copy)NSString *id;
//@property (nonatomic,assign)long long lastStamp;
//@property (nonatomic,copy)NSString *playKey;
//@property (nonatomic,copy)NSString *rtmpKey;

@property (nonatomic,assign)long long startTime;
@property (nonatomic,assign)long long endTime;

//相对于今天的准确stamp 这个用于计算自己赋值
@property (nonatomic,assign)long long accuracyfirstStamp;
@property (nonatomic,assign)long long accuracylastStamp;

@property (nonatomic,assign)int alarmType;
@property (nonatomic,assign)int dateLife;

@end
