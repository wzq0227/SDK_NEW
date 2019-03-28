//
//  CSOrderDeviceListCellModel.h
//  ULife3.5
//
//  Created by Goscam on 2018/4/23.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 设备云存储状态
 - CSOrderStatusInUse: 在使用
 - CSOrderStatusUnpurchased: 未开通
 - CSOrderStatusExpired: 已过期
 - CSOrderStatusUnbind: 已解绑
 */
typedef NS_ENUM(NSUInteger, CSOrderStatus) {
    CSOrderStatusInUse,
    CSOrderStatusUnpurchased,
    CSOrderStatusExpired,
    CSOrderStatusUnbind,
};


@interface CSOrderDeviceListCellModel : NSObject
{}

@property (assign, nonatomic)  CSOrderStatus orderStatus;

@property (strong, nonatomic)  NSString *imagePath;

@property (strong, nonatomic)  NSString *devId;

@property (strong, nonatomic)  NSString *devName;

@property (strong, nonatomic)  NSString *packageType;

@property (strong, nonatomic)  NSString *validTime;

@end
