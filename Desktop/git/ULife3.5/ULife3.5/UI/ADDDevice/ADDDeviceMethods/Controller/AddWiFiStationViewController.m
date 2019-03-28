//
//  AddWiFiStationViewController.m
//  ULife3.5
//
//  Created by AnDong on 2018/8/22.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "AddWiFiStationViewController.h"
#import "AddDeviceTipViewController.h"
#import "AddDeviceWiFiSettingViewController.h"

@interface AddWiFiStationViewController ()

@end

@implementation AddWiFiStationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configUI];
}

- (void)configUI {
    
    self.navigationItem.title = DPLocalizedString(@"ADDDevice");
    self.view.backgroundColor = [UIColor whiteColor];
    
    int labelX = 20;
    int labelY = 44;
    int labelW = SCREEN_WIDTH-labelX*2;
    int labelH = 90;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(labelX, labelY, labelW, labelH)];
    label.font = [UIFont systemFontOfSize:14.0];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    label.numberOfLines = 0;
    label.text = DPLocalizedString(@"AddWiFiStationViewControllerLabelAlert");
    [self.view addSubview:label];
    
    int imageViewX = 90;
    int imageViewY = CGRectGetMaxY(label.frame)+40;
    int imageViewW = SCREEN_WIDTH-180;
    int imageViewH = 120;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(imageViewX, imageViewY, imageViewW, imageViewH)];
    //imageView.image = [UIImage imageNamed:@"AddWiFiStationVcImage"];
    imageView.image = [UIImage imageNamed:@"AddWiFiStationVcImageNoFinger"];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:imageView];
    
    int btnX = 0;
    int btnY = CGRectGetMaxY(imageView.frame)+70;
    int btnW = [UIScreen mainScreen].bounds.size.width;
    int btnH = 40;
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(btnX, btnY, btnW, btnH)];
    [btn setTitle:DPLocalizedString(@"AcousticAdd_notHeardVoiceTips") forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:14.0];
    btn.titleLabel.numberOfLines = 0;
    [btn addTarget:self action:@selector(donnotHearVoiceAlert) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    int nextBtnX = 20;
    int nextBtnY = CGRectGetMaxY(btn.frame)+10;
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

- (void)donnotHearVoiceAlert {
    AddDeviceTipViewController *vc = [[AddDeviceTipViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)nextBtnDidClick {
    AddDeviceWiFiSettingViewController *vc = [[AddDeviceWiFiSettingViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}
@end
