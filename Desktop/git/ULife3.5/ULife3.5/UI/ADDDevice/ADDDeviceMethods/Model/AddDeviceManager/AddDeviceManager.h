//
//  AddDeviceManager.h
//  ULife3.5
//
//  Created by Goscam on 2018/5/18.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DeviceDataModel.h"


typedef NS_ENUM(NSUInteger, ShareDevToOthersResult) {
    ShareDevToOthersResult_Suc,
    ShareDevToOthersResult_UserNotExist,
    ShareDevToOthersResult_Failed,
};

typedef void(^ShareToOthersBlock)(ShareDevToOthersResult result);

@interface AddDeviceManager : NSObject


+ (void)shareDevice:(DeviceDataModel*)devModel
           toOthers:(NSString*)userName
             result:(ShareToOthersBlock)shareResultBlock;

@end
