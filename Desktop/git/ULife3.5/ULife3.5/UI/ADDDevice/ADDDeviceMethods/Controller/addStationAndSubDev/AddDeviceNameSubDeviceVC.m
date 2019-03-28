//
//  AddDeviceNameSubDeviceVC.m
//  ULife3.5
//
//  Created by Goscam on 2018/3/22.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "AddDeviceNameSubDeviceVC.h"
#import "Masonry.h"
#import "APDoorbellSetDevNameView.h"
#import "CBSCommand.h"
#import "BaseCommand.h"
#import "NetSDK.h"
#import "NSTimer+YYAdd.h"
#import "DeviceNameSettingViewController.h"
#import "DeviceManagement.h"

@interface AddDeviceNameSubDeviceVC ()<UITextFieldDelegate>
{
    BOOL needShowDeviceNameView;
}

@property (nonatomic, assign)  NSInteger notifyStationFailedCnt;

@property (strong, nonatomic)  UIImageView *tipImgView;

@property (strong, nonatomic)  UILabel *tipLabel;

@property (nonatomic, strong)  UILabel *loadingLabel;

@property (nonatomic, strong)  UIActivityIndicatorView *activityView;

@property (strong, nonatomic)  APDoorbellSetDevNameView *deviceNameView;

@property (nonatomic,strong)   UIView *bgViewForDevNameView;

@property (strong, nonatomic)  NSString *deviceName;

@property (strong, nonatomic)  NSTimer *checkTimer;

@property (strong, nonatomic)  SubDevInfoModel *subDevInfo;

@property (strong, nonatomic)  NSTimer *bindTimer;

@property (strong, nonatomic)  NSTimer *notifyStationTimer;

@end

@implementation AddDeviceNameSubDeviceVC

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self configUI];
    
    
}

- (void)viewDidAppear:(BOOL)animated{
    
//    [self showDevNameView];
//    [self.checkTimer invalidate];
    
    [self configModel];
}

- (void)viewWillAppear:(BOOL)animated{
    if (needShowDeviceNameView)
        [self showDeviceNameView:YES];
        
    [self addNotifications];
}

- (void)viewWillDisappear:(BOOL)animated{
    
    [self removeNotifications];
    
    [self removeTimers];
    
    [GOSUIManager hideSVProgressHUD];
    
    [[NSObject class] cancelPreviousPerformRequestsWithTarget:self];
}

- (void)removeTimers{
    if ([_checkTimer isValid]) {
        [_checkTimer invalidate];
        _checkTimer = nil;
    }
    
    if ([_notifyStationTimer isValid]) {
        [_notifyStationTimer invalidate];
        _notifyStationTimer = nil;
    }
}

- (void)configModel{
//    [SVProgressHUD showWithStatus:@"Loading..."];
    [self setLoadingHidden:NO];
    
    self.activityView.hidden = NO;
    [self.activityView startAnimating];
    // 适配遮挡问题
//    if ([SYDeviceInfo syScreenType] == SYScreen_iPhone_4_7 || [SYDeviceInfo syScreenType] == SYScreen_iPhone_5_8) {
        // 图片的高度+估算3行的label高度+状态栏高度+导航栏高度+HUD的高度
//        CGFloat componentY = ([UIScreen mainScreen].bounds.size.width - 20)*(420.0/639.0)+80+[UIApplication sharedApplication].statusBarFrame.size.height+44+100;
//        [SVProgressHUD setOffsetFromCenter:UIOffsetMake(0, componentY-self.view.centerY)];
//    }
    
    
    [self startCheckTimer];
    
    [self configTimeOutFunc];
}

- (void)configTimeOutFunc{
    [self performSelector:@selector(showAddFailedMsg) withObject:self afterDelay:180];
}

- (void)showAddFailedMsg{
    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_addFailed")];
    [self setLoadingHidden:YES];
}

- (void)addNotifications{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textValueChanged:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)removeNotifications{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


//MARK: - UI
- (void)configUI{
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.title=DPLocalizedString(@"ADDDevice");

    [self addSubViews];
    
    [self makeConstraints];
}

- (void)addSubViews{
    [self.view addSubview: self.tipImgView];
    [self.view addSubview: self.tipLabel];
    [self.view addSubview: self.loadingLabel];
    [self.view addSubview: self.activityView];
}

- (void)makeConstraints{
    [self.tipImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.leading.equalTo(self.view).offset(10);
        make.width.equalTo(self.tipImgView.mas_height).multipliedBy(639.0/420);
        make.top.equalTo(self.view).offset(15);
    }];
    
    [self.tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.leading.equalTo(self.view).offset(20);
        make.top.equalTo(self.tipImgView.mas_bottom).offset(10);
    }];
    
    [self.loadingLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view);
        make.top.mas_equalTo(self.tipLabel.mas_bottom).offset(30);
    }];
    
    [self.activityView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.loadingLabel);
        make.leading.mas_equalTo(self.loadingLabel.mas_trailing).offset(10);
        make.width.height.mas_equalTo(20);
    }];
}

- (UIImageView*)tipImgView{
    if (!_tipImgView) {
        _tipImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        _tipImgView.image = [UIImage imageNamed:_devType==DeviceTypeEnumDoorbell?@"addDev_guide_doorbell":@"addDev_guide_wirelesscamera"];
    }
    return _tipImgView;
}

- (UILabel*)tipLabel{
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        _tipLabel.font = [UIFont systemFontOfSize: 14];
        _tipLabel.numberOfLines = 0;
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        
        NSString *localString = DPLocalizedString(_devType==DeviceTypeEnumWirelessCamera?@"addDev_tip_pairStationWithCamera":@"addDev_tip_pairStationWithDoorbell");
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:localString];
        
        NSTextAttachment *attchment = [[NSTextAttachment alloc]init];
        attchment.bounds = CGRectMake(0, 0, 30, 36);//设置frame
        attchment.image = [UIImage imageNamed:@"AcousticAdd_icon_music"];//设置图片
        
        NSAttributedString *string = [NSAttributedString attributedStringWithAttachment:(NSTextAttachment *)(attchment)];
        
        NSRange range = [localString rangeOfString:@"”" options:NSBackwardsSearch ];
        
        [attributedString insertAttributedString:string atIndex:range.location];//插入到第几个下标
        
        _tipLabel.attributedText = attributedString;
//        _tipLabel.text = DPLocalizedString(_devType==DeviceTypeEnumWirelessCamera?@"addDev_tip_pairStationWithCamera":@"addDev_tip_pairStationWithDoorbell");
    }
    return _tipLabel;
}

- (UILabel *)loadingLabel {
    if (!_loadingLabel) {
        _loadingLabel = [[UILabel alloc] init];
        _loadingLabel.font = [UIFont systemFontOfSize: 25];
        _loadingLabel.numberOfLines = 0;
        _loadingLabel.textAlignment = NSTextAlignmentCenter;
        _loadingLabel.text = @"Loading...";
    }
    return _loadingLabel;
}

- (UIActivityIndicatorView *)activityView {
    if (!_activityView) {
        _activityView = [[UIActivityIndicatorView alloc] init];
        _activityView.color = [UIColor grayColor];
    }
    return _activityView;
}

//MARK: - 循环检测子设备是否已经配对
- (void)startCheckTimer{
    
    __weak typeof(self) weakSelf = self;
    _checkTimer = [NSTimer yyscheduledTimerWithTimeInterval:6 block:^(NSTimer * _Nonnull timer) {
        [weakSelf checkSubDevRegistered];
    } repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_checkTimer forMode:NSRunLoopCommonModes];
    [_checkTimer setFireDate: NSDate.new];
}

- (void)checkSubDevRegistered{
    BodyCheckSubDevRegisterRequest *body = [BodyCheckSubDevRegisterRequest new];
    body.DeviceId = _deviceId;
    
    CBS_CheckSubDevRegisterRequest *req = [CBS_CheckSubDevRegisterRequest new];
    req.Body = body;
    
    __weak typeof(self) weakSelf = self;
    
    [[NetSDK sharedInstance] net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:6000 responseBlock:^(int result, NSDictionary *dict) {
        if (result ==0  ) {
            CBS_CheckSubDevRegisterResponse *resp = [CBS_CheckSubDevRegisterResponse yy_modelWithDictionary:dict];
            
            
            for (NSDictionary *tempDict in resp.Body.SubDevList) {
                SubDevInfoModel *subDevInfo = [SubDevInfoModel yy_modelWithDictionary:tempDict];
                if (subDevInfo.Online == 1 ) {
                    
                    BOOL hasAdded = NO;
                    for (SubDevInfoModel *tempSubInfo in weakSelf.devModel.SubDevice) {
                        if ([tempSubInfo.SubId isEqualToString:subDevInfo.SubId]) {
                            hasAdded = YES;
                            break;
                        }
                    }
                    //过滤已经添加了的
                    if (hasAdded) {
                        continue;
                    }
                    
                    weakSelf.subDevInfo = subDevInfo;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [SVProgressHUD resetOffsetFromCenter];
                        [SVProgressHUD dismiss];
                        [self setLoadingHidden:YES];
                        [weakSelf showDevNameView];
                        [weakSelf.checkTimer invalidate];
                    });
                    break;
                }
            }
        }else{
           
        }
    }];
}

//MARK: - 绑定子设备
- (void)startBinding{
    
    __weak typeof(self) weakSelf = self;
    _bindTimer = [NSTimer yyscheduledTimerWithTimeInterval:6 block:^(NSTimer * _Nonnull timer) {
        [weakSelf bindSubDev];
    } repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_bindTimer forMode:NSRunLoopCommonModes];
    [_bindTimer setFireDate: NSDate.new];
}

- (void)bindSubDev{
    BodyAddSubDevRequest *body = [BodyAddSubDevRequest new];
    body.DeviceId              = _deviceId;
    body.SubId                 = _subDevInfo.SubId;
    body.ChanNum               = _subDevInfo.ChanNum;
    body.ChanName = _deviceNameView.devNameTxt.text;
    
    CBS_AddSubDevRequest *req = [CBS_AddSubDevRequest new];
    req.Body = body;
    
    __weak typeof(self) weakSelf = self;
    [[NetSDK sharedInstance] net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:6000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.bindTimer invalidate];
                [weakSelf startNotifyTimer];
            });
        }
    }];
}

//
- (void)notifyStationFunc{

    NSLog(@"_____________________notifyStationFunc");
    CMD_NotifyAddSubDevSuccessfullyReq *req = [CMD_NotifyAddSubDevSuccessfullyReq new];
    req.channel = _subDevInfo.ChanNum;
    
    NSDictionary *reqData = [req requestCMDData];
    
    __weak typeof(self) weakSelf = self;
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:_deviceId requestData:reqData timeout:6000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0 ) {
            dispatch_async(dispatch_get_main_queue(), ^{

                [weakSelf.navigationController popToRootViewControllerAnimated:YES];
                
                [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:REFRESH_DEV_LIST_NOTIFY object:nil]];
            });
        }else{
            if (weakSelf.notifyStationFailedCnt > 3) {
                dispatch_async(dispatch_get_main_queue(), ^{

                    [weakSelf.navigationController popToRootViewControllerAnimated:YES];
                    
                    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:REFRESH_DEV_LIST_NOTIFY object:nil]];
                });
            }
        }
        weakSelf.notifyStationFailedCnt++;
    }];
}


- (void)startNotifyTimer{

    _notifyStationFailedCnt = 0;
    __weak typeof(self) weakSelf = self;
    _notifyStationTimer = [NSTimer yyscheduledTimerWithTimeInterval:6 block:^(NSTimer * _Nonnull timer) {
        [weakSelf notifyStationFunc];
    } repeats:YES];
    [_notifyStationTimer setFireDate:[NSDate new]];
    [[NSRunLoop mainRunLoop] addTimer:_notifyStationTimer forMode:NSRunLoopCommonModes];
}

#pragma mark - 配对成功弹出命名对话框
-  (void)showDevNameView{
    if (!_bgViewForDevNameView) {
        _bgViewForDevNameView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        _bgViewForDevNameView.backgroundColor = [UIColor blackColor];
        _bgViewForDevNameView.alpha = 0.5;
        [_bgViewForDevNameView addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapToDismissShowDevNameView:)] ];
    }
    [self addDevNameViewIntoKeyWindow];
}

- (void)tapToDismissShowDevNameView:(id)sender{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [_deviceNameView removeFromSuperview];
        [_bgViewForDevNameView removeFromSuperview];
        
        _deviceNameView = nil;
        _bgViewForDevNameView = nil;        
    });
}

- (void)addDevNameViewIntoKeyWindow{
    
    if (!self.deviceNameView.superview) {
        [[UIApplication sharedApplication].keyWindow addSubview:self.bgViewForDevNameView];
        [[UIApplication sharedApplication].keyWindow addSubview: self.deviceNameView];
        
        [self.deviceNameView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.bgViewForDevNameView);
            make.leading.equalTo(self.bgViewForDevNameView).offset(40);
            make.width.equalTo(self.deviceNameView.mas_height).multipliedBy(280/180.0);
        }];
    }
}

//jump to devList
- (void)nextBtnAction:(id)sender{
    
    [self startBinding];
}

- (void)changeSubDevName:(NSString*)subDevName{
    BodyModifyChanNameRequest *body = [BodyModifyChanNameRequest new];
    body.DeviceId = _deviceId;
    body.ChanNum = _subDevInfo.ChanNum;
    body.ChanName = subDevName;
    
    CBS_ModifyChanNameRequest *req = [CBS_ModifyChanNameRequest new];
    req.Body = body;
    
    __weak typeof(self) weakSelf = self;
    [[NetSDK sharedInstance] net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:6000 responseBlock:^(int result, NSDictionary *dict) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showOperationResult:result];
            [weakSelf.navigationController popToRootViewControllerAnimated:YES];
        });
        
    }];
}

- (void)showOperationResult:(int)result{
    if (result == 0) {
        [SVProgressHUD dismiss];
        [self setLoadingHidden:YES];
    }else{
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
    }
}


- (void)confirmBtnAction:(id)sender{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_deviceNameView removeFromSuperview];
        [_bgViewForDevNameView removeFromSuperview];
        self.deviceName = _deviceNameView.devNameTxt.text;

//        [SVProgressHUD showWithStatus:@"Loading..."];
        [self setLoadingHidden:NO];

        [self nextBtnAction:nil];
    });
}

- (void)textValueChanged:(id)sender{
    
    self.deviceNameView.confirmBtn.userInteractionEnabled = self.deviceNameView.devNameTxt.text.length > 0 ;
    _deviceNameView.confirmBtn.alpha =self.deviceNameView.confirmBtn.userInteractionEnabled ? 1: 0.5;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    needShowDeviceNameView = YES;
    [self showDeviceNameView:NO];
    
    DeviceNameSettingViewController *vc = [[DeviceNameSettingViewController alloc] init];
    vc.subDevName = [self getDeviceName];
    [vc didChangeDevNameCallback:^(NSString *name) {
        [self.navigationController popViewControllerAnimated:YES];
        [self showDeviceNameView:YES];
        _deviceNameView.devNameTxt.text = name;
        _deviceNameView.confirmBtn.userInteractionEnabled = YES;
    }];
    [self.navigationController pushViewController:vc animated:YES];
    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    [_deviceNameView.devNameTxt resignFirstResponder];
    return YES;
}

- (APDoorbellSetDevNameView*)deviceNameView{
    if (!_deviceNameView) {
        _deviceNameView = [[[NSBundle mainBundle] loadNibNamed:@"APDoorbellSetDevNameView" owner:self options:nil] lastObject];
        [_deviceNameView.confirmBtn setTitle:DPLocalizedString(@"Qrcode_Title_Confirm") forState:UIControlStateNormal];
        [_deviceNameView.confirmBtn addTarget:self action:@selector(confirmBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        
        _deviceNameView.confirmBtn.titleLabel.textColor = UIColor.whiteColor;
        
        _deviceNameView.confirmBtn.backgroundColor = myColor;
        _deviceNameView.confirmBtn.userInteractionEnabled = YES;
        _deviceNameView.confirmBtn.alpha = 1.0;
        _deviceNameView.confirmBtn.layer.cornerRadius = 20;
        
        _deviceNameView.nameDevSubTipLabel.hidden = NO;

        [_deviceNameView.nameDevTipLabel setText:DPLocalizedString(@"APDoorbell_NameSubDev_AddSuc")];
        [_deviceNameView.nameDevSubTipLabel setText:DPLocalizedString(@"APDoorbell_NameDevice_Tip")];

        [_deviceNameView.devNameLabel setText:DPLocalizedString(@"APDoorbell_DeviceName_Tip")];
        
        _deviceNameView.devNameTxt.text = [self getDeviceName];
        _deviceNameView.devNameTxt.returnKeyType = UIReturnKeyDone;
        _deviceNameView.devNameTxt.delegate = self;
        _deviceNameView.layer.cornerRadius = 10;
    }
    return _deviceNameView;
}

- (NSString *)getDeviceName {
    NSString *str = DPLocalizedString(@"Setting_Group_Camera");
    int hasDevice = 0;
    // 查找子设备列表中是否存在Camera的名字
    for (SubDevInfoModel *model in
         _devModel.SubDevice) {
        if ([model.ChanName rangeOfString:str].location != NSNotFound)
            hasDevice++;
    }
    
//    if (hasDevice == 0)
//        return str;
//    else
    return [NSString stringWithFormat:@"%@%@", str, [NSString stringWithFormat:@" : (%d)", hasDevice+1]];
}

- (void)showDeviceNameView:(BOOL)show {
    _bgViewForDevNameView.hidden = !show;
    _deviceNameView.hidden = !show;
}

- (void)setLoadingHidden:(BOOL)isHidden {
    dispatch_async_on_main_queue(^{
        self.loadingLabel.hidden = isHidden;
        self.activityView.hidden = isHidden;
    });
}


@end
