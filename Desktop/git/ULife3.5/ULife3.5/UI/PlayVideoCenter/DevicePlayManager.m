//
//  SmartModel.m
//  QQI
//
//  Created by goscam on 16/3/1.
//  Copyright © 2016年 yuanx. All rights reserved.
//


#import "DevicePlayManager.h"
#import "NSArray+SNFoundation.h"
#import "TMCacheExtend.h"
#import "UserDB.h"

@implementation DevicePlayModel

@end

@interface DevicePlayManager ()
@end

@implementation DevicePlayManager
+(DevicePlayManager *)sharedInstance
{
    static DevicePlayManager *_sharedMyClass = nil;
    static dispatch_once_t token;
    if(_sharedMyClass == nil)
    {
        dispatch_once(&token,^{
            _sharedMyClass = [[DevicePlayManager alloc] init];}
                      );
    }
    return _sharedMyClass;
}

//-(NSMutableArray *)getDeviceList
//{
//   return [[UserDB sharedInstance]selectDevicePlayModel];
//}

-(instancetype)init
{
    if (self = [super init]) {
//        NSMutableArray *array = [[UserDB sharedInstance]selectDevicePlayModel];
    }
    return self;
}

//-(BOOL)addDevicePlayModel:(NSString *)UID and:(int)position
//{
//    if (UID == nil) {
//        return NO;
//    }
//    NSLog(@"addDevicePlayModel UID = %@",UID);
//    DevicePlayModel *model = [[DevicePlayModel alloc]init];
//    model.position = position;
//    model.UID = UID;
//    model.videoQualityState = 0;
//    if ([[UserDB sharedInstance]insertDevicePlayModel:model]) {
//    }
//    else
//    {
//        return NO;
//    }
//    return YES;
//}




//-(BOOL)removeDevicePlayModel:(NSString *)UID
//{
//    if (UID == nil) {
//        return NO;
//    }
//    
//    if([[UserDB sharedInstance]deleteDevicePlay:UID])
//    {
//        
//    }
//    return YES;
//}



@end
