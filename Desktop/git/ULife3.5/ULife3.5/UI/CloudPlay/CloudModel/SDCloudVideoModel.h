//
//  SDCloudVideoModel.h
//  ULife3.5
//
//  Created by AnDong on 2018/1/5.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SDCloudVideoModel : NSObject

//相对于今天的准确stamp 这个用于计算自己赋值
@property (nonatomic,assign)long long accuracyfirstStamp;
@property (nonatomic,assign)long long accuracylastStamp;

@property (nonatomic,assign)long long AT;
@property (nonatomic,assign)long long E;
@property (nonatomic,assign)long long S;
/// type 0 1 分别表示普通录像与报警录像
@property (nonatomic, assign) int type;
/// 开始显示时间 00:00:00 由S计算得出
@property (nonatomic, copy) NSString *startTime;
/// 设备名
@property (nonatomic, copy) NSString *deviceName;

/// 占位图
@property (nonatomic, copy) UIImage *placeholderImage;
/// 是否正在编辑
@property (nonatomic, assign, getter=isEditing) BOOL editing;
/// 是否被选择
@property (nonatomic, assign, getter=isSelected) BOOL selected;

@end
