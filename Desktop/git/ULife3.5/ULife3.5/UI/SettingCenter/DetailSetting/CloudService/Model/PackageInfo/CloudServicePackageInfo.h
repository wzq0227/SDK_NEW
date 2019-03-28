//
//  CloudServicePackageInfo.h
//  ULife3.5
//
//  Created by Goscam on 2017/9/26.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CloudServicePackageInfo : NSObject

typedef NS_ENUM(NSInteger,PackageType){
    PackageTypeDays3_Monthly = 0,
    PackageTypeDays7_Monthly,
    PackageTypeDays30_Monthly,
    PackageTypeDays3_Annual,
    PackageTypeDays7_Annual,
    PackageTypeDays30_Annual
};

typedef NS_ENUM(NSUInteger, PackageState) {
    PackageStateInUse,
    PackageStateUnused,
    PackageStateExpired,
};


typedef NS_ENUM(NSUInteger, PackageValidTime) {
    PackageValidTimeAMonth=0,
    PackageValidTimeAYear=1,
};

typedef NS_ENUM(NSUInteger, StorageDays) {
    StorageDays3 ,
    StorageDays7 ,
    StorageDays30 ,
};

/**
 套餐天数
 */
@property (assign, nonatomic)  NSInteger storageDays;


/**
 套餐包有效时间
 */
@property (assign, nonatomic)  PackageValidTime  packageValidTime;


/**
 套餐数量
 */
@property (assign, nonatomic)  NSInteger  packageCount;


/**
 套餐单价
 */
@property (assign, nonatomic)  CGFloat  packagePrice;

/**
 套餐单价
 */
@property (assign, nonatomic)  CGFloat  packageTotalPrice;

+ (NSString*)packageNameWithPackageType:(PackageType)type;
@end
