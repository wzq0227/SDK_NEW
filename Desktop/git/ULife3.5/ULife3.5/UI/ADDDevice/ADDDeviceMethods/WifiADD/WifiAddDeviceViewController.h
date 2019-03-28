//
//  WifiAddDeviceViewController.h
//  goscamapp
//
//  Created by goscam_sz on 17/4/21.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InfoForAddingDevice.h"

@interface WifiAddDeviceViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *MyDeviceIdTextField;

@property (strong, nonatomic) IBOutlet UITextField *MyDeviceName;

@property (strong, nonatomic) IBOutlet UIView *IdView;

@property (strong, nonatomic) IBOutlet UIView *DeviceNameView;

@property (strong, nonatomic) IBOutlet UIButton *nextBtn;

@property (strong, nonatomic) IBOutlet UIImageView *showImageView;


@property (nonatomic,copy) NSString * devWifiPassWord;  //wifi密码

@property (nonatomic,copy) NSString * devWifiName;      //wifi名称

@property (strong, nonatomic)  InfoForAddingDevice *addDevInfo;

@end
