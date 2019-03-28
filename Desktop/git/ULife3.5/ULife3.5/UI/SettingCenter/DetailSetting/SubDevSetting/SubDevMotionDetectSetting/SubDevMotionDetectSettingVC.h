//
//  SubDevMotionDetectSettingVC.h
//  ULife3.5
//
//  Created by Goscam on 2018/3/22.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"


@interface SubDevMotionDetectSettingVC : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *dragSliderTipLabel;

@property (weak, nonatomic) IBOutlet UIView *sliderValuesContainerView;


@property (weak, nonatomic) IBOutlet UILabel *motionDetectDescriptionLabel;


@property (weak, nonatomic) IBOutlet UIButton *saveSettingsBtn;


@property (assign, nonatomic)  BOOL pirDistanceSettingEnabled;

@property (strong, nonatomic)  DeviceDataModel *devModel;

@property (assign, nonatomic)  int channel;

@end
