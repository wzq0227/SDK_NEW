//
//  DeviceUpdateManager.h
//  ULife3.5
//
//  Created by Goscam on 2018/4/4.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^DevUpdateResultBlock)(BOOL updateSuccessfully);

typedef void(^DevUpdateStateBlock)(BOOL needToUpdate);

@interface DeviceUpdateManager : NSObject

@property (strong, nonatomic)  NSString *deviceId;

@property (assign, nonatomic)  BOOL isWiFiDoorBell;

- (void)queryDeviceUpdateState:(DevUpdateStateBlock)updateStateBlock;

- (void)userFinishUpdatingCallback:(DevUpdateResultBlock)resultBlock;

@end
