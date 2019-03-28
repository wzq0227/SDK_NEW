//
//  WiringViewController.h
//  goscamapp
//
//  Created by goscam_sz on 17/4/26.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"

@interface WiringViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *MyDeviceIdTextField;

@property (strong, nonatomic) IBOutlet UITextField *MyDeviceName;

@property (strong, nonatomic) IBOutlet UIView *idView;

@property (strong, nonatomic) IBOutlet UIView *deviceView;

@property (strong, nonatomic) IBOutlet UIButton *nextBtn;

@property (weak, nonatomic) IBOutlet UILabel *tipsLabel;

@property (strong, nonatomic) IBOutlet UILabel *deviceName;

@property (strong, nonatomic) IBOutlet UIImageView *showimageview;

@property (strong, nonatomic)  DeviceDataModel *devModel;

@end
