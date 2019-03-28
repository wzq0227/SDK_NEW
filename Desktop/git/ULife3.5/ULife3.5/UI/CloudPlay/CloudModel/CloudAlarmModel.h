//
//  CloudAlarmModel.h
//  TestAli
//
//  Created by AnDong on 2017/10/13.
//  Copyright © 2017年 AnDong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CloudAlarmModel : NSObject<
NSCopying,
NSMutableCopying
>

@property (nonatomic,copy)NSString *eventDesc;
@property (nonatomic,assign)int eventType;
@property (nonatomic,assign)long long timeStamp;
//@property (nonatomic,assign)long long endTime;
//@property (nonatomic,assign)long long startTime;
//@property (nonatomic,assign)int dateLife;
//相对于今天的准确stamp 这个用于计算自己赋值
@property (nonatomic,assign)long long accuracyTimeStamp;

@end
