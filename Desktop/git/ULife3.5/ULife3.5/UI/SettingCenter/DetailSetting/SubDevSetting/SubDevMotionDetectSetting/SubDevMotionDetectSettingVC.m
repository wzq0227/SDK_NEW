//
//  SubDevMotionDetectSettingVC.m
//  ULife3.5
//
//  Created by Goscam on 2018/3/22.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "SubDevMotionDetectSettingVC.h"
#import "Masonry.h"
#import "SliderBgFenceView.h"
#import "NightVersionTableViewCell.h"
#import "PIRSliderView.h"

#import "BaseCommand.h"
#import "NetSDK.h"

#define MCellIdentifier (@"NightVersionTableViewCell")

@interface SubDevMotionDetectSettingVC ()<UITableViewDelegate,UITableViewDataSource,UIGestureRecognizerDelegate>
{
    
}

@property (nonatomic, strong)  UILongPressGestureRecognizer *gesRecog;

@property (nonatomic, strong) __block  CMD_GetChannelPirDetectResp * channelPirResp;

@property (nonatomic, strong)  CMD_GetChannelPirDetectResp * tempChannelPirSetting;


@property (strong, nonatomic)  UISlider *sliderForPirDistanceSetting;

@property (weak, nonatomic) IBOutlet SliderBgFenceView *sliderBgView;


@property (weak, nonatomic) IBOutlet UILabel *pirValueSettingTitleLabel;

@property (weak, nonatomic) IBOutlet UIView *pirValueSettingContainer;

@property (weak, nonatomic) IBOutlet UILabel *pirValueSettingTipLabel;

@property (weak, nonatomic) IBOutlet UITableView *mdSettingTableView;


@property (strong, nonatomic)  PIRSliderView *pirValueSettingSlider;


@property (strong, nonatomic)  NSArray<NSString *>*pirValueTitlesArray;

@property (nonatomic, strong)  UISwitch *alarmSwitch;

@end

@implementation SubDevMotionDetectSettingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self configView];
    
    [self addEvents];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self requestPirValue ];
}

#pragma mark - UI
- (void)configView{
    [self configSliderValuesLabel];
    
    [self configSlider];
    
    [self configTableView];
    
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
    
    self.dragSliderTipLabel.text = DPLocalizedString(@"SubDevSetting_MD_DragSliderTip");
    self.motionDetectDescriptionLabel.text = DPLocalizedString(@"SubDevSetting_MD_Description");
}

- (void)configBtns{
    [self.saveSettingsBtn setTitle:DPLocalizedString(@"SubDevSetting_MD_SaveSettings") forState:0];
    self.saveSettingsBtn.layer.cornerRadius = 20;
    self.saveSettingsBtn.backgroundColor = myColor;
    [self.saveSettingsBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.saveSettingsBtn addTarget:self action:@selector(saveSettingsBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)configTableView{
    self.mdSettingTableView.dataSource = self;
    self.mdSettingTableView.delegate = self;
    [self.mdSettingTableView registerNib:[UINib nibWithNibName:MCellIdentifier bundle:nil] forCellReuseIdentifier:MCellIdentifier];
    self.mdSettingTableView.scrollEnabled = NO;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NightVersionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MCellIdentifier forIndexPath:indexPath];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [cell.cellSwitch setOn:_channelPirResp.un_alarm_ring animated:NO];
    self.alarmSwitch = cell.cellSwitch;
    
//    [self enableAlarmSwitch:_sliderBgView.curPosition!=0];
    
    [cell.cellSwitch addTarget:self action:@selector(cellSwitchClicked:) forControlEvents:UIControlEventValueChanged];
    cell.titleLabel.text = DPLocalizedString(@"SubDevSetting_MD_IntruderAlarm");
    return cell;
}


#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 1;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return nil;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    return nil;
}

- (void)configSlider{
    
    //PIR Distance
    [self.view addSubview:self.sliderForPirDistanceSetting];
    [self.sliderForPirDistanceSetting mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.sliderBgView).mas_offset(-5);
        make.leading.equalTo(self.sliderBgView).offset(24);
        make.center.equalTo(self.sliderBgView);
    }];

    
    //PIR Value Setting
    [self.pirValueSettingContainer addSubview:self.pirValueSettingSlider];
    self.pirValueSettingSlider.titlesArray = self.pirValueTitlesArray;
    
    [self.pirValueSettingSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.pirValueSettingContainer);
        make.leading.equalTo(self.pirValueSettingContainer).offset(0);
        make.height.equalTo(self.pirValueSettingContainer).multipliedBy(0.6);//
    }];
    
    __weak typeof(self) wSelf = self;
    [self.pirValueSettingSlider sliderValueChangeCallback:^(int value) {
//        __strong typeof(wSelf) strongSelf = wSelf;
        NSLog(@"_______________pir_sensitivity:%d",value);
    }];
}

- (void)enableAlarmSwitch:(BOOL)enable{
    self.alarmSwitch.userInteractionEnabled = enable;
    self.alarmSwitch.alpha = enable ? 1 : 0.5 ;
}


- (void)configSliderValuesLabel{

    
    CGFloat itemSpacing = (SCREEN_WIDTH-64)/5;

    for (int i=0; i<6; i++) {
        if (i == 1)
            continue;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = [NSString stringWithFormat:@"%d%@",(i*5),(i==0?@"":@"ft")];
        [self.sliderValuesContainerView addSubview:label];
        
        //equalTo(@(32+i*itemSpacing))
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(40);
            make.height.mas_equalTo(10);
            make.centerX.equalTo(self.sliderValuesContainerView.mas_leading).offset(32+i*itemSpacing);
            make.centerY.equalTo(self.sliderValuesContainerView.mas_centerY);
        }];
    }
    [self.sliderValuesContainerView setNeedsDisplay];
    [self.sliderValuesContainerView layoutIfNeeded];
}

- (PIRSliderView*)pirValueSettingSlider{
    if (!_pirValueSettingSlider) {
        _pirValueSettingSlider = [[PIRSliderView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 50) ];
        
    }
    return _pirValueSettingSlider;
}


- (NSArray*)pirValueTitlesArray{
    if (!_pirValueTitlesArray) {
        //MLocalizedString(SubDevSetting_MD_ValueSetting_Off),
        _pirValueTitlesArray = @[MLocalizedString(SubDevSetting_MD_ValueSetting_Low),MLocalizedString(SubDevSetting_MD_ValueSetting_Mid),
                                 MLocalizedString(SubDevSetting_MD_ValueSetting_High)];
    }
    return _pirValueTitlesArray;
}

- (UISlider *)sliderForPirDistanceSetting{
    if (!_sliderForPirDistanceSetting) {
        _sliderForPirDistanceSetting = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 30)];
        [_sliderForPirDistanceSetting setThumbImage:[UIImage imageNamed:@"SubDev_MDSetting_Slider_thumb"] forState:UIControlStateNormal];
        [_sliderForPirDistanceSetting addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        _sliderForPirDistanceSetting.minimumTrackTintColor = [UIColor clearColor];
        _sliderForPirDistanceSetting.maximumTrackTintColor = [UIColor clearColor];
        _sliderForPirDistanceSetting.continuous = NO;
    }
    return _sliderForPirDistanceSetting;
}

#pragma mark - Net
- (void)requestPirValue{
    
    [SVProgressHUD showWithStatus:@"Loading..."];

    CMD_GetChannelPirDetectReq *req = [CMD_GetChannelPirDetectReq new];
    req.channel = _channel;
    NSDictionary *reqData = [req requestCMDData];
    
    __weak typeof(self) weakSelf = self;
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:_devModel.DeviceId requestData:reqData timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (result == 0 ) {
            strongSelf.channelPirResp = [CMD_GetChannelPirDetectResp yy_modelWithDictionary:dict];
            strongSelf.tempChannelPirSetting = [CMD_GetChannelPirDetectResp yy_modelWithDictionary:dict];
            dispatch_async_on_main_queue(^{
                int roundSensitivity = strongSelf.channelPirResp.un_sensitivity/5 * 5;
                [strongSelf.sliderForPirDistanceSetting setValue: roundSensitivity/25.0 animated:YES];
                [strongSelf.pirValueSettingSlider.sliderForPirValueSetting setValue:(strongSelf.channelPirResp.un_delay-1)/2.0 animated:YES];
                
                [strongSelf.mdSettingTableView reloadData];
            });
        }else{
            //
        }
        [GOSUIManager showGetOperationResult:result];
    }];
}

//SubDevInfoModel
- (void)setPirValue{
    
    [SVProgressHUD showWithStatus:@"Loading..."];

    BOOL isPirOn = _tempChannelPirSetting.un_delay!=0 && _tempChannelPirSetting.un_sensitivity != 0;
    
    CMD_SetChannelPirDetectReq *req = [CMD_SetChannelPirDetectReq new];
    req.un_delay = _tempChannelPirSetting.un_delay;
    req.un_switch = _tempChannelPirSetting.un_switch = isPirOn;
    req.un_alarm_ring = _tempChannelPirSetting.un_alarm_ring;
    req.un_sensitivity = _tempChannelPirSetting.un_sensitivity;
    req.channel = _channel;

    NSDictionary *reqData = [req requestCMDData];
    
    __weak typeof(self) weakSelf = self;
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:_devModel.DeviceId requestData:reqData timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (result == 0 ) {
            dispatch_async_on_main_queue(^{
                [strongSelf.navigationController popViewControllerAnimated:YES];
            });
        }else{
            
            [strongSelf.tempChannelPirSetting yy_modelSetWithDictionary:[strongSelf.channelPirResp yy_modelToJSONObject]];
            dispatch_async_on_main_queue(^{
                [strongSelf.mdSettingTableView reloadData];
                
                int roundSensitivity = strongSelf.channelPirResp.un_sensitivity/5 * 5;

                [strongSelf.sliderForPirDistanceSetting setValue:roundSensitivity/25.0 animated:YES];
                [strongSelf.pirValueSettingSlider.sliderForPirValueSetting setValue:(strongSelf.channelPirResp.un_delay-1)/2.0 animated:YES];
            });
        }
        [GOSUIManager showSetOperationResult:result];
    }];
}

#pragma mark - Event

- (void)addEvents{
    
    [self addGesture];
    
    [self.sliderForPirDistanceSetting addTarget:self action:@selector(sliderTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self.sliderForPirDistanceSetting addTarget:self action:@selector(sliderTouchUp:) forControlEvents:UIControlEventTouchUpInside];

}

- (void)addGesture{
    _gesRecog = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesFunc:)];
    _gesRecog.minimumPressDuration = 0;
    [self.sliderForPirDistanceSetting addGestureRecognizer:_gesRecog];
    
    _gesRecog.delegate = self;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    
    //
    if ( [NSStringFromClass(touch.view.class) isEqualToString:@"UISlider"] ) {
        return YES;
    }
    return NO;
}



- (void)tapGesFunc:(UITapGestureRecognizer*)tapGes{
    
    CGPoint touchP = [tapGes locationInView:self.sliderForPirDistanceSetting];
    int subTitlesCount = 6; //0,5,10...25;
    
    NSLog(@"touch__________________________x:%5.3f",touchP.x);
    int sections = (subTitlesCount -1)*2; //转换后的选择区间数等于原区间数的两倍
    int selectPostion = (int)( touchP.x / self.sliderForPirDistanceSetting.width *sections);
    
    for (int i=1; i< sections; i+=2) {
        if (selectPostion < i) {
            if (selectPostion == 1 || selectPostion == 2)
                break;
                
            [_sliderForPirDistanceSetting setValue:(i-1)*1.0/(sections) animated:NO];
            break;
        }
    }
    
    if (selectPostion >= sections - 1) {
        [_sliderForPirDistanceSetting setValue:(1.0) animated:NO];
    }
    
    if (selectPostion != 1 && selectPostion != 2)
        _sliderBgView.curPosition = (selectPostion+1)/2;
    
    
    NSLog(@"PirDistanceSetting_selectPostion:%d ",_sliderBgView.curPosition);
    
    [_sliderBgView  setNeedsDisplay];
    [_sliderBgView layoutIfNeeded];
    
    //更新Pir灵敏度设置Slider 和 入侵报警设置 状态
    [self updatePirSubCtrlViews];
}

- (void)sliderTouchDown:(UISlider *)sender {
    _gesRecog.enabled = NO;
}

- (void)sliderTouchUp:(UISlider *)sender {
    _gesRecog.enabled = YES;
}



- (void)saveSettingsBtnClicked:(id)sender{
    
    _tempChannelPirSetting.un_delay = (int)(_pirValueSettingSlider.sliderForPirValueSetting.value*2)+1;
    _tempChannelPirSetting.un_sensitivity = (int)(_sliderForPirDistanceSetting.value * 25);
    [self setPirValue];
}

- (void)cellSwitchClicked:(id)sender{
    UISwitch *aSwitch = (UISwitch*)sender;
    _tempChannelPirSetting.un_alarm_ring = aSwitch.isOn;
}

- (void)sliderValueChanged:(id)sender{

    int selectPostion = (int)(_sliderForPirDistanceSetting.value*10); // <1/4(0)  >1/4&&<3/4  (1/2)
    if (selectPostion < 1) {
        [_sliderForPirDistanceSetting setValue:0*0.1 animated:YES];
    }
    else if (selectPostion <3){
        [_sliderForPirDistanceSetting setValue:2*0.1 animated:YES];
    }
    else if (selectPostion <5){
        [_sliderForPirDistanceSetting setValue:4*0.1 animated:YES];
    }
    else if (selectPostion <7){
        [_sliderForPirDistanceSetting setValue:6*0.1 animated:YES];
    }
    else if (selectPostion <9){
        [_sliderForPirDistanceSetting setValue:8*0.1 animated:YES];
    }else {
        [_sliderForPirDistanceSetting setValue:10*0.1 animated:YES];
    }
    _sliderBgView.curPosition = (selectPostion+1)/2;
    NSLog(@"selectPostion:%d curPosition:%d",selectPostion,_sliderBgView.curPosition);
    [_sliderBgView  setNeedsDisplay];
    [_sliderBgView layoutIfNeeded];
    
    [self updatePirSubCtrlViews];

    
}

//MARK: - 禁用pir灵敏度设置 和 入侵报警声设置
- (void)updatePirSubCtrlViews{
    
    if (_sliderBgView.curPosition == 0) {//更新Pir灵敏度设置Slider
        [self.pirValueSettingSlider.sliderForPirValueSetting setValue:0 animated:NO];
    }
    
    [self enableAlarmSwitch: _sliderBgView.curPosition!=0 ];
    
    [self enablePirSensitivitySettingSlider: _sliderBgView.curPosition!=0];
}

- (void)enablePirSensitivitySettingSlider:(BOOL)enable{
    self.pirValueSettingSlider.userInteractionEnabled = enable;
    self.pirValueSettingSlider.alpha = enable?1:0.5;
}


@end
