//
//  SmartLinkModel.h
//  QQI
//
//  Created by goscam_sz on 17/5/12.
//  Copyright © 2017年 yuanx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AddDeviceStyleModel.h"

@interface SmartLinkModel : NSObject

@property (nonatomic,assign) SmartConnectStyle smartStyle;

@property (nonatomic,copy)   NSString *devUid;

@property (nonatomic,copy)   NSString *wifiName;

@property (nonatomic,copy)   NSString *wifiPassword;

@end
