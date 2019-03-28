//
//  AcousticConfigTipsVC.h
//  ULife3.5
//
//  Created by Goscam on 2017/10/11.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"

@interface AcousticConfigTipsVC : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *turnUpSpeakerToMaxTipsLabel;

@property (weak, nonatomic) IBOutlet UILabel *clickNextAfterVoiceTipsLabel;

@property (weak, nonatomic) IBOutlet UIButton *nextBtn;

@property (weak, nonatomic) IBOutlet UIButton *showStartAcousticAddTipsBtn;

@property (strong, nonatomic)  DeviceDataModel *devModel;

@end
