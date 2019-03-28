//
//  AddDeviceTipViewController.m
//  ULife3.5
//
//  Created by AnDong on 2018/8/22.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "AddDeviceTipViewController.h"
#import "AddDeviceWiFiSettingViewController.h"
#import "UILabel+GosLayoutAdd.h"

@interface AddDeviceTipViewController ()

@end

@implementation AddDeviceTipViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configUI];
}

- (void)configUI {
    
    self.navigationItem.title = DPLocalizedString(@"ADDDevice");
    self.view.backgroundColor = [UIColor whiteColor];
    
    int labelX = 20;
    int labelY = 64;
    int labelW = SCREEN_WIDTH-labelX*2;
    int labelH = 60;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(labelX, labelY, labelW, labelH)];
    label.font = [UIFont systemFontOfSize:14.0];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    label.numberOfLines = 0;
    
    NSRange iconStringRange = [DPLocalizedString(@"AcousticAdd_longPressSignalBtn") rangeOfString:@"%@"];
    NSString *txtStr = [DPLocalizedString(@"AcousticAdd_longPressSignalBtn") stringByReplacingOccurrencesOfString:@"%@" withString:@""];
    
    label.text = txtStr;
    [label insertImage:[UIImage imageNamed:@"AcousticAdd_icon_signal"]
                                          atIndex:iconStringRange.location
                                           bounds:CGRectMake(0, -2, 15, 13)];
    
    //label.text = @"请长按WiFi键5s, 听到语音提示且红蓝灯同时闪烁时, 请点击下一步";
    [self.view addSubview:label];
    
    int imageViewX = 90;
    int imageViewY = CGRectGetMaxY(label.frame)+40;
    int imageViewW = SCREEN_WIDTH-180;
    int imageViewH = 120;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(imageViewX, imageViewY, imageViewW, imageViewH)];
    imageView.image = [UIImage imageNamed:@"AddWiFiStationVcImage"];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:imageView];
    
    int nextBtnX = 20;
    int nextBtnY = CGRectGetMaxY(imageView.frame)+100;
    int nextBtnW = SCREEN_WIDTH-2*nextBtnX;
    int nextBtnH = 40;
    UIButton *nextBtn = [[UIButton alloc] initWithFrame:CGRectMake(nextBtnX, nextBtnY, nextBtnW, nextBtnH)];
    nextBtn.backgroundColor = myColor;
    nextBtn.layer.cornerRadius = 20.0;
    nextBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    [nextBtn setTitle:DPLocalizedString(@"Setting_NextStep") forState:UIControlStateNormal];
    [nextBtn addTarget:self action:@selector(nextBtnDidClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:nextBtn];
}

- (void)nextBtnDidClick {
    AddDeviceWiFiSettingViewController *vc = [[AddDeviceWiFiSettingViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
