//
//  PreScanQrCodeViewController.h
//  ULife3.5
//
//  Created by Goscam on 2017/10/9.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "ViewController.h"

@interface PreScanQrCodeViewController : ViewController

@property (strong, nonatomic) IBOutlet UITextField *MyDeviceIdTextField;

@property (strong, nonatomic) IBOutlet UITextField *MyDeviceName;

@property (strong, nonatomic) IBOutlet UIView *idView;

@property (strong, nonatomic) IBOutlet UIView *deviceView;

@property (strong, nonatomic) IBOutlet UIButton *nextBtn;

@property (strong, nonatomic) IBOutlet UIImageView *showImage;

@end
