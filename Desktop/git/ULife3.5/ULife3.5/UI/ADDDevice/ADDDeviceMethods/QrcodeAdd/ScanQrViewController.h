//
//  ScanQrViewController.h
//  goscamapp
//
//  Created by goscam_sz on 17/4/26.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//  MyDeviceIdTextField  MyDeviceName

#import <UIKit/UIKit.h>

@interface ScanQrViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *MyDeviceIdTextField;

@property (strong, nonatomic) IBOutlet UITextField *MyDeviceName;

@property (strong, nonatomic) IBOutlet UIView *idView;

@property (strong, nonatomic) IBOutlet UIView *deviceView;

@property (strong, nonatomic) IBOutlet UIButton *nextBtn;

@property (strong, nonatomic) IBOutlet UIImageView *showImage;


//@property (nonatomic,assign) int  smartflag;   //连接方式

@property (nonatomic,copy) NSString * devWifiPassWord;  //wifi密码

@property (nonatomic,copy) NSString * devWifiName;      //wifi名称

@end
