//
//  SDCloudAlarmModel.h
//  ULife3.5
//
//  Created by AnDong on 2018/1/5.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SDCloudAlarmModel : NSObject



//相对于今天的准确stamp 这个用于计算自己赋值
@property (nonatomic,assign)long long accuracyfirstStamp;
@property (nonatomic,assign)long long accuracylastStamp;

@property (nonatomic,assign)long long AT;
@property (nonatomic,assign)long long E;
@property (nonatomic,assign)long long S;

@end
