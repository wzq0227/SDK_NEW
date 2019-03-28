//
//  DeviceManagement.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/6.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "DeviceManagement.h"
#import "UserDB.h"
#import "DevPushManagement.h"



@interface DeviceManagement()

@property (nonatomic, strong)NSMutableArray <DeviceDataModel *> *deviceArray;
@property (nonatomic, strong) dispatch_queue_t dbOperationQueue;

@end


@implementation DeviceManagement

+(DeviceManagement *)sharedInstance
{
    static DeviceManagement *g_deviceManagement = nil;
    static dispatch_once_t token;
    if (g_deviceManagement == nil)
    {
        dispatch_once(&token,^{
            g_deviceManagement = [[DeviceManagement alloc] init];
        });
    }
    
    return g_deviceManagement;
}


- (instancetype)init
{
    if (self = [super init])
    {
        if (!self.deviceArray)
        {
            self.deviceArray = [NSMutableArray arrayWithCapacity:0];
        }
        if (!self.dbOperationQueue)
        {
            self.dbOperationQueue = dispatch_queue_create("deviceDBOperationQueue", DISPATCH_QUEUE_SERIAL);
        }
    }
    
    return self;
}


#pragma mark -- 增
- (BOOL)addDeviceModel:(DeviceDataModel *)deviceModel
{
    if (!deviceModel)
    {
        NSLog(@"无法添加设备数据 model， deviceModel = nil");
        return NO;
    }
    
    @synchronized(_deviceArray)
    {
        BOOL isExist = NO;
        if (0 < self.deviceArray.count)
        {
            @autoreleasepool
            {
                for (int i = 0; i < self.deviceArray.count; i++)
                {
                    DeviceDataModel *tempModel = self.deviceArray[i];
                    if ([tempModel.DeviceId isEqualToString:deviceModel.DeviceId])
                    {
                        isExist = YES;
                        break ;
                    }
                }
            }
        }
        
        if (NO == isExist)
        {
            [self.deviceArray addObject:deviceModel];
            [self insertDeviceModelToDB:deviceModel];   // 加入数据库
        }
    }
    return YES;
}


#pragma mark -- 删
- (BOOL)deleteDevcieModel:(DeviceDataModel *)deviceModel
{
    if (!deviceModel || 0 >= deviceModel.DeviceId.length)
    {
        NSLog(@"无法删除设备数据 model，deviceId = %@ deviceId.length = %lu", deviceModel, (unsigned long)deviceModel.DeviceId.length);
        
        return NO;
    }
    @synchronized(self.deviceArray)
    {
        @autoreleasepool
        {
            for (int i = 0; i < self.deviceArray.count; i++)
            {
                DeviceDataModel *tempModel = self.deviceArray[i];
                if ([tempModel.DeviceId isEqualToString:deviceModel.DeviceId])
                {
                    [self.deviceArray removeObjectAtIndex:i];
                    [self deleteDeviceModelFromDB:tempModel];     // 移除数据库数据
                    break;
                }
            }
        }
    }
    return YES;
}


#pragma mark -- 查
- (DeviceDataModel *)getDevcieModelWithDeviceId:(NSString *)deviceId
{
    if (!deviceId || 0 >= deviceId.length
        || 0 >= self.deviceArray.count)
    {
        NSLog(@"无法搜索设备数据 model，deviceId = %@ deviceId.length = %lu self.deviceArray.count = %lu", deviceId, (unsigned long)deviceId.length, (unsigned long)self.deviceArray.count);
        
        return nil;
    }
    @synchronized(_deviceArray)
    {
        @autoreleasepool
        {
            for (int i = 0; i < self.deviceArray.count; i++)
            {
                DeviceDataModel *tempModel = self.deviceArray[i];
//                if ([tempModel.DeviceId isEqualToString:deviceId])
                if (20 <= deviceId.length
                    && NSNotFound != [tempModel.DeviceId rangeOfString:deviceId].location)
                {
                    return tempModel;
                }
            }
        }
    }
    return nil;
}


#pragma mark -- 改
- (BOOL)updateDeviceModel:(DeviceDataModel *)deviceModel
{
    if (!deviceModel)
    {
        NSLog(@"无法更新设备数据 model， deviceModel = nil");
        return NO;
    }
    if (0 >= self.deviceArray.count)
    {
        NSLog(@"无法更新设备数据 model， self.deviceArray.count = 0");
        return NO;
    }
    @synchronized(_deviceArray)
    {
        @autoreleasepool
        {
            for (int i = 0; i < self.deviceArray.count; i++)
            {
                DeviceDataModel *tempModel = self.deviceArray[i];
                if ([tempModel.DeviceId isEqualToString:deviceModel.DeviceId])
                {
                    [self.deviceArray replaceObjectAtIndex:i
                                                withObject:deviceModel];
                    [self updateDevNameToDB:deviceModel];   // 更新数据库
                    return YES;
                }
            }
            return NO;
        }
    }
}

static int removedDevPushCount =0;
- (void)removeAllDevModelResult:(RemoveAllDevBlock)result
{
    removedDevPushCount = 0;
    if (self.deviceArray.count <= 0) {
        result(0);
        return;
    }
    for (NSInteger i = self.deviceArray.count-1; i >= 0 ; i--)
    {
        NSString *deviceId = self.deviceArray[i].DeviceId;
        [[DevPushManagement shareDevPushManager] deletePushWithDeviceId:deviceId
                                                            resultBlock:^(BOOL isSuccess)
         {
             if (NO == isSuccess)
             {
                 NSLog(@"移设备 deviceId = %@ ，移除推送失败！", deviceId);
                 result(-1);
             }
             else
             {
                 removedDevPushCount++;
                 NSLog(@"移设备 deviceId = %@ ，移除推送成功！", deviceId);
                 if (removedDevPushCount == self.deviceArray.count) {
                     [self.deviceArray removeAllObjects];
                     [[UserDB sharedInstance] removeAllDevice];
                     result(0);
                 }
             }
         }];
    }
}


- (NSMutableArray<DeviceDataModel *> *)deviceListArray
{
    return self.deviceArray;
}


#pragma mark - 数据库操作中心
#pragma mark -- 插入数据库
- (void)insertDeviceModelToDB:(DeviceDataModel *)deviceModel
{
    if (!deviceModel)
    {
        NSLog(@"无法插入新设备，deviceModel = nil ");
        return;
    }
    dispatch_async(self.dbOperationQueue, ^{
        
        [[UserDB sharedInstance] insertDeviceModel:deviceModel];
    });
}


#pragma mark -- 删除
- (void)deleteDeviceModelFromDB:(DeviceDataModel *)deviceModel
{
    if (!deviceModel)
    {
        NSLog(@"无法删除设备，deviceModel = nil ");
        return;
    }
    dispatch_async(self.dbOperationQueue, ^{
        
        [[UserDB sharedInstance] deleteDeviceModel:deviceModel];
    });
}


#pragma mark -- 修改昵称
- (void)updateDevNameToDB:(DeviceDataModel *)deviceModel
{
    if (!deviceModel)
    {
        NSLog(@"无法更新新设备昵称，deviceModel = nil ");
        return;
    }
    dispatch_async(self.dbOperationQueue, ^{
        
        [[UserDB sharedInstance] updataDeviceNikeName:deviceModel];
    });
}


@end
