//
//  SubDevPirSetting_5100.m
//  ULife3.5
//
//  Created by Goscam on 2018/5/9.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "SubDevPirSetting_5100.h"
#import "PIRSliderView.h"

@interface SubDevPirSetting_5100 ()
{
    
}

@property (weak, nonatomic) IBOutlet UILabel *pirValueSettingTitleLabel;

@property (weak, nonatomic) IBOutlet UIView *pirValueSettingContainer;

@property (weak, nonatomic) IBOutlet UILabel *pirValueSettingTipLabel;

@property (weak, nonatomic) IBOutlet UIButton *saveSettingsBtn;


@property (strong, nonatomic)  PIRSliderView *pirValueSettingSlider;

@property (strong, nonatomic)  NSArray<NSString *>*pirValueTitlesArray;

@end

@implementation SubDevPirSetting_5100

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
 
    [self configUI];
}

- (void)configUI{
    [self configSlider];
    
    [self configLabel];
    
    [self configBtns];
}


- (void)configLabel{
    
    //
    self.title = DPLocalizedString(@"Setting_MotionDetection");
    
    self.pirValueSettingTitleLabel.text = MLocalizedString(SubDevSetting_MD_ValueSetting_Title);
    
    self.pirValueSettingTipLabel.text = MLocalizedString(SubDevSetting_MD_Tip_SetProperValue);
    self.pirValueSettingTipLabel.numberOfLines = 4;
    self.pirValueSettingTipLabel.font = [UIFont systemFontOfSize:13];
    self.pirValueSettingTipLabel.adjustsFontSizeToFitWidth = YES;
    
}

- (void)configSlider{
    
    //PIR Value Setting
    [self.pirValueSettingContainer addSubview:self.pirValueSettingSlider];
    self.pirValueSettingSlider.titlesArray = self.pirValueTitlesArray;
    
    [self.pirValueSettingSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.pirValueSettingContainer);
        make.leading.equalTo(self.pirValueSettingContainer).offset(0);
        make.height.equalTo(self.pirValueSettingContainer).multipliedBy(0.6);//
    }];
}

- (PIRSliderView*)pirValueSettingSlider{
    if (!_pirValueSettingSlider) {
        _pirValueSettingSlider = [[PIRSliderView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 50) ];
        
    }
    return _pirValueSettingSlider;
}


- (NSArray*)pirValueTitlesArray{
    if (!_pirValueTitlesArray) {
        _pirValueTitlesArray = @[MLocalizedString(SubDevSetting_MD_ValueSetting_Off),MLocalizedString(SubDevSetting_MD_ValueSetting_Low),MLocalizedString(SubDevSetting_MD_ValueSetting_Mid),
                                 MLocalizedString(SubDevSetting_MD_ValueSetting_High)];
    }
    return _pirValueTitlesArray;
}

- (void)configBtns{
    [self.saveSettingsBtn setTitle:DPLocalizedString(@"SubDevSetting_MD_SaveSettings") forState:0];
    self.saveSettingsBtn.layer.cornerRadius = 20;
    self.saveSettingsBtn.backgroundColor = myColor;
    [self.saveSettingsBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.saveSettingsBtn addTarget:self action:@selector(saveSettingsBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Event

- (void)saveSettingsBtnClicked:(id)sender{
    
}






@end
