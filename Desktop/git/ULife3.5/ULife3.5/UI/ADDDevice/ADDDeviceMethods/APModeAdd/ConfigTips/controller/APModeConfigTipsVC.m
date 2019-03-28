//
//  APModeConfigTipsVC.m
//  ULife3.5
//
//  Created by Goscam on 2017/9/25.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "APModeConfigTipsVC.h"
#import "Header.h"
#import "APModeConfigPreconnectVC.h"
#import "SmartLink.h"
#import "ConfigurationWiFiViewController.h"

@interface APModeConfigTipsVC ()

@end

@implementation APModeConfigTipsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self configUI];
}

- (void)configUI{
    [self configNavigationBar];
    
    [self configLabels];
    [self configButtons];
    [self configView];
}

- (void)configNavigationBar{
    self.title = DPLocalizedString(@"APAdd_APMode");
}

- (void)configLabels{
    self.pressSetBtnTipsLabel.text = DPLocalizedString(@"APAdd_pressSetBtnTips");
    self.chooseWiFiTipsLabel.text = DPLocalizedString(@"APAdd_chooseWiFiTips");
}

- (void)configButtons{
    self.nextBtn.backgroundColor = myColor;
    self.nextBtn.layer.cornerRadius = 20;
    self.nextBtn.clipsToBounds = YES;
    
    [self.nextBtn setTitleColor:[UIColor whiteColor] forState:0];
    [self.nextBtn setTitle:DPLocalizedString(@"ADDDevice_Next") forState:0];
    [self.nextBtn addTarget:self action:@selector(nextBtnAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)configView{
    self.view.backgroundColor = BACKCOLOR(238,238,238,1);;
}


- (void)nextBtnAction:(id)sender{

    APModeConfigPreconnectVC *vc = [[APModeConfigPreconnectVC alloc] init];
    vc.devModel = self.devModel;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
