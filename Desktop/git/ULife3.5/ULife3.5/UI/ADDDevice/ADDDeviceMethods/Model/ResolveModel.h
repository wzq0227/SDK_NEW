//
//  ResolveModel.h
//  goscamapp
//
//  Created by goscam_sz on 17/5/12.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "qrcode_tools.h"

#import "AddDeviceStyleModel.h"

typedef enum {
    WifiAdd   = 0 ,
    ScanQrAdd = 1 ,
    WiringAdd = 2 ,
    FriendAdd = 3 ,
} smartLinkState;


@interface ResolveModel : NSObject
{
}



- (instancetype)initWithResolveString:(NSString *)str;

- (int)getSmartFlag;

@property (nonatomic,assign)DeviceQRType   devtype;

- (NSString *)getDevUid:(smartLinkState)state;
@end
