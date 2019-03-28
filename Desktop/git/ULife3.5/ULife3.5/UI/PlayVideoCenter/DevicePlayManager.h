//
//  SmartModel.h
//  QQI
//
//  Created by goscam on 16/3/1.
//  Copyright © 2016年 yuanx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "NSArray+SNFoundation.h"
#import "TMCacheExtend.h"


@interface DevicePlayModel : NSObject<NSCopying,NSCoding,NSMutableCopying>
@property(nonatomic,assign)int position;
@property(nonatomic,copy)NSString *UID;
@property(nonatomic,assign)int videoQualityState;
@end

@interface DevicePlayManager : NSObject

+(DevicePlayManager *)sharedInstance;
//-(BOOL)addDevicePlayModel:(NSString *)UID and:(int)position;
//-(BOOL)removeDevicePlayModel:(NSString *)UID;
//-(NSMutableArray *)getDeviceList;
@end




