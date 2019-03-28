//
//  APDoorbellGoToSettingsVC.h
//  ULife3.5
//
//  Created by Goscam on 2017/12/5.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InfoForAddingDevice.h"

@interface APDoorbellGoToSettingsVC : UIViewController

@property (strong, nonatomic)  NSString *deviceID;

@property (strong, nonatomic)  NSString *deviceName;

@property (strong, nonatomic)  InfoForAddingDevice *addDevInfo;

@property (nonatomic, copy) NSString *ssid;
@property (nonatomic, copy) NSString *password;

@end
