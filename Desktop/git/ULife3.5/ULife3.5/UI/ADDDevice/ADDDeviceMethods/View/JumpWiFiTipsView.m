//
//  JumpWiFiTipsView.m
//  ULife3.5
//
//  Created by AnDong on 2018/9/18.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "JumpWiFiTipsView.h"
@interface JumpWiFiTipsViewControl ()
@property (nonatomic, strong) JumpWiFiTipsView *tipView;
@end
@implementation JumpWiFiTipsViewControl
- (instancetype)init {
    if (self = [super init]) {
        self.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        // 点击本身的响应
        [self addTarget:self action:@selector(removeTip) forControlEvents:UIControlEventTouchUpInside];
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.8];
        
        // 设置中间空白部位的内容
        CGFloat jumpTipsViewH = SCREEN_HEIGHT*0.7;
        CGFloat jumpTipsViewY = SCREEN_HEIGHT*0.15;
        CGFloat jumpTipsViewW = SCREEN_WIDTH*0.9;
        CGFloat jumpTipsViewX = SCREEN_WIDTH*0.05;
        __weak typeof(self) weakself = self;
        JumpWiFiTipsView *jumpTipsView = [[JumpWiFiTipsView alloc] init];
        jumpTipsView.frame = CGRectMake(jumpTipsViewX, jumpTipsViewY, jumpTipsViewW, jumpTipsViewH);
        jumpTipsView.layer.cornerRadius = 15;
        jumpTipsView.block = ^{
            if (weakself)
                [weakself removeTip];
        };
        self.tipView = jumpTipsView;
        [self addSubview:jumpTipsView];
        
        // 即将回到主界面时就消失
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeTip) name:UIApplicationWillResignActiveNotification object:nil];
        
    }
    return self;
}
- (void)removeTip {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeFromSuperview];
}
+ (void)showTip {
    [[UIApplication sharedApplication].keyWindow addSubview:[[JumpWiFiTipsViewControl alloc] init]];
   
}
@end


@interface JumpWiFiTipsView ()
@property (weak, nonatomic) IBOutlet UILabel *labelOne;
@property (weak, nonatomic) IBOutlet UIImageView *settingImageView;
@property (weak, nonatomic) IBOutlet UILabel *labelTwo;
@property (weak, nonatomic) IBOutlet UIImageView *settingWiFiImageView;
@property (weak, nonatomic) IBOutlet UIButton *finishBtn;
@end

@implementation JumpWiFiTipsView

-(instancetype)init {
    self = [super init];
    if (self) {
        self = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class])
                                              owner:nil options:nil] firstObject];
        
        _settingImageView.image = [UIImage imageNamed:@"APDoorbell_Tip_Settings"];
        _settingWiFiImageView.contentMode = UIViewContentModeScaleAspectFill;
        
        _settingWiFiImageView.image = [UIImage imageNamed:@"APDoorbell_Tip_ChooseAPWifi"];
        _settingWiFiImageView.contentMode = UIViewContentModeScaleAspectFill;
        
        _labelOne.text = DPLocalizedString(@"APDoorbell_LaunchSettings_Tip");
        _labelTwo.text = DPLocalizedString(@"APDoorbell_ChooseAPWifi_Tip");
        [_finishBtn setTitle:DPLocalizedString(@"Setting_Done") forState:UIControlStateNormal];
        [_finishBtn addTarget:self action:@selector(finishBtnDidClick) forControlEvents:UIControlEventTouchUpInside];
        _settingImageView.image = [UIImage imageNamed:@"wifi_setting_icon"];
        _settingWiFiImageView.image = [UIImage imageNamed:@"wifi_setting_preview"];
    }
    return self;
}

- (void)finishBtnDidClick {
    if (self.block)
        self.block();
}
@end
