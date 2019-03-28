//
//  AcousticConfigTipsVC.m
//  ULife3.5
//
//  Created by Goscam on 2017/10/11.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "AcousticConfigTipsVC.h"
#import "AcousticConfigConnectVC.h"
#import "Header.h"
#import "AcousticAddGuideVC.h"
#import "UILabel+GosLayoutAdd.h"

@interface AcousticConfigTipsVC ()

@end

@implementation AcousticConfigTipsVC

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
    self.title = DPLocalizedString(@"AcousticAdd_navBarTitle");
}

- (void)configLabels{
    self.turnUpSpeakerToMaxTipsLabel.text = DPLocalizedString(@"AcousticAdd_turnUpSpeakerToMax");
    self.clickNextAfterVoiceTipsLabel.text = DPLocalizedString(@"AcousticAdd_clickNextAfterHearingVoice");
    if (!isENVersion) {
        [self.turnUpSpeakerToMaxTipsLabel setLinespacing:4];
    }
}

- (void)configButtons{
    self.nextBtn.backgroundColor = myColor;
    self.nextBtn.layer.cornerRadius = 20;
    self.nextBtn.clipsToBounds = YES;
    
    [self.nextBtn setTitleColor:[UIColor whiteColor] forState:0];
    [self.nextBtn setTitle:DPLocalizedString(@"AcousticAdd_haveHeardVoiceTip") forState:0];
    [self.nextBtn addTarget:self action:@selector(nextBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.showStartAcousticAddTipsBtn setTitle:DPLocalizedString(@"AcousticAdd_notHeardVoiceTips") forState:UIControlStateNormal];
    [self.showStartAcousticAddTipsBtn addTarget:self action:@selector(showStartAcousticAddGIFAnimation:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)showStartAcousticAddGIFAnimation:(id)sender{
    
    [self playGIFView];
}



- (void)playGIFView{
    
    AcousticAddGuideVC *aVC = [AcousticAddGuideVC new];
    
    [self.navigationController pushViewController: aVC animated: YES];

}

- (void)configView{
    self.view.backgroundColor = BACKCOLOR(238,238,238,1);;
}


- (void)nextBtnAction:(id)sender{
    
    AcousticConfigConnectVC *vc = [[AcousticConfigConnectVC alloc] init];
    vc.devModel = self.devModel;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
