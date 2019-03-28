//
//  WringConfigureViewController.h
//  ULife3.5
//
//  Created by goscam_sz on 2017/6/8.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddDeviceStyleModel.h"
#import "MediaHeader.h"

@interface WringConfigureViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIButton *nextTbn;

@property (strong, nonatomic) IBOutlet UILabel *tiltleLabel;

@property (nonatomic,strong) NSString * deviceID;

@property (nonatomic,strong) NSString * deviceName;

@property (nonatomic,assign) GosDeviceType deviceType;  //设备类型

@end
