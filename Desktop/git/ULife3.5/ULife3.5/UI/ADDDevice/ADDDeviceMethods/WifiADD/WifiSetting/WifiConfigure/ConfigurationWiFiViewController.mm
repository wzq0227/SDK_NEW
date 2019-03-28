//
//  ConfigurationWiFiViewController.m
//  goscamapp
//
//  Created by goscam_sz on 17/5/3.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//


#import "ConfigurationWiFiViewController.h"
#import "SVProgressHUD.h"
#import "SmartLink.h"
#import "CBSCommand.h"
#import "BaseCommand.h"
#import "NetSDK.h"
#import "SaveDataModel.h"
#import "AddDeviceViewController.h"
#import "DeviceListViewController.h"
#import "CustomWindow.h"
#import "WifiSettingViewController.h"
#import "APModeConfigPreconnectVC.h"
#import "AcousticConfigConnectVC.h"
#import "LanSDK.h"
#import "AcousticAddGuidePairingVC.h"
#import <AVFoundation/AVFoundation.h>
#import "APDoorbellGoToSettingsVC.h"
#import "iRouterInterface.h"
#import "NetCheckViewController.h"
#import "CheckNetViewController.h"
#import "AddDeviceBindedViewController.h"

#define PATTERN_DEF_PIN             @"57289961"
#define RTK_FAILED                  (-1)


/**
 添加设备的几种状态

 - AddDeviceState_SettingWifiInfo: 设置设备将要连接的路由器WiFi信息
 - AddDeviceState_CheckingIfDevRegistered: 查询设备是否已经到服务器报道
 - AddDeviceState_Binding: 绑定设备
 - AddDeviceState_Failed_Timeout: 添加超时，提示失败
 */
typedef NS_ENUM(NSUInteger, AddDeviceState) {
    AddDeviceState_SettingWifiInfo = 0,
    AddDeviceState_CheckingIfDevRegistered,
    AddDeviceState_Binding,
    AddDeviceState_Failed_Timeout,
};


@interface ConfigurationWiFiViewController () <UISmartLinkDelegate,UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *addDev_connectingImageView;


@property (strong, nonatomic) IBOutlet UIImageView *AnimationView;
@property (strong, nonatomic) IBOutlet UILabel     *PromptLabel;
@property (nonatomic, strong) SmartLink            *smart;
@property (nonatomic, strong) NetSDK               *netSDK;

@property (strong, nonatomic) IBOutlet UIImageView *connectStateView;

@property (strong, nonatomic) IBOutlet UIImageView *configureStateView;

@property (weak, nonatomic) IBOutlet UIImageView *devRegisteredCheckView;

@property (strong, nonatomic) IBOutlet UIButton *ShowTipBtn;

@property (strong, nonatomic) IBOutlet UILabel *FristConnetLabel;

@property (strong, nonatomic) IBOutlet UILabel *SecondConnetLabel;

@property (strong, nonatomic) IBOutlet UILabel *LastConnetLabel;

@property (assign, nonatomic)  BOOL hasRequestedCameraStatus;

@property (assign, nonatomic)  int repeatedlyQueryTimes;
@property (weak, nonatomic) IBOutlet UIButton *checkBtn;

/** 轮询设备是否已注册次数*/
@property (assign, nonatomic)  int checkIfDevRegisteredCount;


/** 轮询设备是否已注册次数*/
@property (assign, nonatomic)  int forceUnbindFailedCnt;

@property (nonatomic, assign)  AddDeviceState addDevState;

/** 设置WiFi和密码重复次数*/
@property (assign, nonatomic)  int setSSIDAndPwdCount;

@property (strong, nonatomic)  NSTimer *checkDevRegisteredTimer;

@end

@implementation ConfigurationWiFiViewController
{
     char com[128];
     CustomWindow *customWindow;
}

- (void) viewWillAppear:(BOOL)animated
{
    NSLog(@"viewVillAppear");
    [super viewWillAppear:animated];
    
    
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    NSLog(@"viewWillDisappear");
    if ([SVProgressHUD isVisible]) {
        [SVProgressHUD dismiss];
    }

    [self invalidateCheckDevRegTimer];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:REFRESH_DEV_LIST_NOTIFY object:nil];
    [_smart destroySearchTimer];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setUI];
    
    [SVProgressHUD showWithStatus:DPLocalizedString(@"loading")];

    if(_addDevInfo.addDeviceMode == AddDeviceByVoice){
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self configForAcousticWaveAdd];
            [self startAcousticWaveAdd];
        });
        
        self.addDev_connectingImageView.image = [UIImage imageNamed:@"addev_connecting_doorbell"];
    }
    else if (_addDevInfo.addDeviceMode == AddDeviceByAPMode) {
        
        // 延迟7秒等待设备连上服务器
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self showConnectingAnimation];
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(7 * NSEC_PER_SEC)), dispatch_get_global_queue(0,0), ^{
            __weak typeof(self) weakSelf = self;
            [[LanSDK sharedLanSDKInstance] searchDeviceWithUID:_addDevInfo.devId timeout:60000 deviceType:@"" resultBlock:^(int result) {
                if (result==0) {
                    [weakSelf SmartLinkSuccessful];
                }else{
                    [weakSelf SmartLinkFailure];
                }
            } ];
        });
        
    }else if (_addDevInfo.addDeviceMode == AddDeviceByAPDoorbell) {
        
        self.addDev_connectingImageView.image = [UIImage imageNamed:@"addev_connecting_doorbell"];

        [self performSelector:@selector(showAddTimeouMsg) withObject:nil afterDelay:120];

        self.setSSIDAndPwdCount = 0;
        [self passSSIDAndPasswordToDevice];

    }
    else{
        SmartLinkModel * model = [[SmartLinkModel alloc]init];
        model.devUid           = _addDevInfo.devId;
        
        model.wifiName         = _addDevInfo.devWifiName;
        model.wifiPassword     = _addDevInfo.devWifiPassWord;
        model.smartStyle       = _addDevInfo.smartStyle;
        
        _smart                 = [[SmartLink alloc]initWithSmartModel:model];
        _smart.delegate = self;
        [_smart startSearchLocalCamre];
    }
}

- (void)forceUnbindDevice{
    
    if (self.addDevState == AddDeviceState_Failed_Timeout) {
        return;
    }
    
    BodyStrongUnbindRequest *body = [BodyStrongUnbindRequest new];
    CBS_StrongUnbindRequest *req = [CBS_StrongUnbindRequest new];
    body.DeviceId = _addDevInfo.devId;
    
    __weak typeof(self) weakSelf = self;
    [[NetSDK sharedInstance] net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (result == 0) {
            //延迟10秒去绑定
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
                [strongSelf endAnimation];
                [strongSelf bind];
            });
        }
        else if (result == -10093){//设备未绑定：可能硬解绑过程中设备已经被删除
            //延迟6秒去绑定
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
                [strongSelf endAnimation];
                [strongSelf bind];
            });
        }
        else{
            strongSelf.forceUnbindFailedCnt++;
            if (strongSelf.forceUnbindFailedCnt<=3) {
                [strongSelf forceUnbindDevice];
            }
        }
    }];
}

- (void)passSSIDAndPasswordToDevice{
    
    NSString * UID = _addDevInfo.devId;
    NSString * userName = @"admin";
    NSString * pwd = @"goscam123";
    NSString * devType = @""; //传空表示所有类型
    
    __weak typeof(self) weakSelf = self;
    
    //FIXME: 搜索到设备之后把WiFi名称和密码传给设备
    NSString *wifiSSID = _addDevInfo.devWifiName;
    NSString *password = _addDevInfo.devWifiPassWord;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        [[LanSDK sharedLanSDKInstance] searchAndConnectDeviceWithUID:UID userName:userName password:pwd timeout:24000 deviceType:devType ssid:wifiSSID password:password resultBlock:^(int result, DeviceInfo *devInfo)
        {
            weakSelf.setSSIDAndPwdCount++;
            if (result == 0) {//设置WiFi成功,轮询设备是否已注册
                if (devInfo->ybindFlag == 0 &&
                    self.addDevInfo.addedByOthers == YES) {//设备已被绑定且未恢复出厂设置开启硬解绑
                    [self gotoNeedResetDeviceVC];
                    return ;
                }
                [strongSelf SmartLinkSuccessful];
            }else{
                if (weakSelf.setSSIDAndPwdCount<=2) {
                    [weakSelf passSSIDAndPasswordToDevice];
                }else{
                    //不管，直接去查询设备是否已报到
                    [strongSelf SmartLinkSuccessful];
                }
            }
        }];
    });
}

- (void)gotoNeedResetDeviceVC {
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        AddDeviceBindedViewController *vc = [[AddDeviceBindedViewController alloc] init];
        [weakself.navigationController pushViewController:vc animated:YES];
    });
}

- (void)configBackBtn{
    UIImage *image = [UIImage imageNamed:@"addev_back"];
    EnlargeClickButton *button = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 70, 40);
    button.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 50);
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self
               action:@selector(backToPrevieousVC:)
     forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    leftBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
}

- (void)backToPrevieousVC:(id)sender{

    if (customWindow.isKeyWindow) {
        return;
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)configForAcousticWaveAdd{
    
#if KeepAcousticAdd

    AVAudioSession *mySession = [AVAudioSession sharedInstance];
    //[mySession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
//    [mySession setActive:YES error:nil];
    [mySession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
    
    int base = 12000;
    for (int i = 0; i < sizeof(freqs)/sizeof(int); i ++) {
        freqs[i] = base + i *150;
    }
    
    recog = [[MyVoiceRecog alloc] init:self vdpriority:VD_MemoryUsePriority];
    //    [recog setFreqs:freqs freqCount:sizeof(freqs)/sizeof(int)];
    player=[[VoicePlayer alloc] init];
    //    [player setFreqs:freqs freqCount:sizeof(freqs)/sizeof(int)];
    //[player setPlayerType:VE_WavPlayer];
    //[player setWavPlayer:@"/Users/godliu/Desktop/aaa/player.wav"];
    //[player mixWav:@"/Users/godliu/Desktop/aaa/Global.wav" muteInterval:1000];
#endif
}

- (void) onRecognizerEnd:(int)_result data:(char *)_data dataLen:(int)_dataLen
{
#if KeepAcousticAdd
    NSString *msg = nil;
    char s[100];
    if (_result == VD_SUCCESS)
    {
        printf("------------------recognized data:%s\n", _data);
        enum InfoType infoType = vr_decodeInfoType(_data, _dataLen);
        if(infoType == IT_STRING)
        {
            vr_decodeString(_result, _data, _dataLen, s, sizeof(s));
            printf("string:%s\n", s);
            char buf[30];char* string = "UUID:";
            memset(buf, 0,sizeof(buf));
            if (strstr(s, "UUID:")) {
                if(strlen(s)  - strlen(string)<= sizeof(buf))
                {
                    char* pos1 = strstr(s, "\r\n");
                    char* pos2 = strstr(s, "\n");
                    if (pos1) {
                        memcpy(buf,s+strlen(string),strlen(s) - strlen(string)-strlen(pos1));
                    }
                    else if(pos2) {
                        memcpy(buf,s+strlen(string),strlen(s) - strlen(string)-strlen(pos2));
                    }
                    else {
                        strcpy(buf,s);
                    }
                    msg = [NSString stringWithFormat:@"%s", buf];
                    
                }
                
            }
            else{
                char* pos = strstr(s, "=");
                if (pos){
                    memcpy(buf,s,pos - s);
                }
                else {
                    char* pos1 = strstr(s, "\r\n");
                    char* pos2 = strstr(s, "\n");
                    if (pos1) {
                        memcpy(buf,s,strlen(s)-strlen(pos1));
                    }
                    else if(pos2) {
                        memcpy(buf,s,strlen(s)-strlen(pos2));
                    }
                    else {
                        strcpy(buf,s);
                    }
                }
                msg = [NSString stringWithFormat:@"%s", buf];
            }
            //            configresult = true;
        }
        else if (infoType == IT_SSID_WIFI){
            SSIDWiFiInfo test;
            vr_decodeSSIDWiFi(_result,_data,_dataLen,&test);
            printf("ssid:%s,passwd:%s\n", test.ssid,test.pwd);
            
        }
        else
        {
            printf("------------------recognized data:%s\n", _data);
        }
    }
    else
    {
        printf("------------------recognize invalid data, errorCode:%d, error:%s\n", _result, recorderRecogErrorMsg(_result));
    }
    if(msg != nil){
        [self performSelectorOnMainThread:@selector(showRecogResult:) withObject:msg waitUntilDone:NO];
    }
#endif
}

#pragma mark 配置成功去绑定
- (void) showRecogResult:(NSString *)_msg
{
    
    if ([self deviceConnectedToRouterWiFi:_msg]) {

        [self SmartLinkSuccessful];
        [NSObject cancelPreviousPerformRequestsWithTarget: self];
        [SVProgressHUD dismiss];
    }
}

- (BOOL)deviceConnectedToRouterWiFi:(NSString *)msg{
    if ([msg isEqualToString:_addDevInfo.devId]) {
        return YES;
    }else if (msg.length == 28 && [msg hasSuffix:@"111A"]){
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_ID_Mismatch")];
    }
    return NO;
}

- (void)setUI
{
    self.title = DPLocalizedString(@"WiFi_Configuration");
    self.FristConnetLabel.text =DPLocalizedString(@"WiFi_Frist_Connet");
    self.SecondConnetLabel.text = DPLocalizedString(@"WiFi_Second_Connet");
    self.LastConnetLabel.text = DPLocalizedString(@"WiFi_Last_Connet");
    self.AnimationView.hidden=YES;
    self.devRegisteredCheckView.hidden=YES;
    self.connectStateView.hidden=YES;
    self.configureStateView.hidden=YES;
    self.PromptLabel.text=DPLocalizedString(@"WiFi_wait");
    [self.ShowTipBtn setTitle:DPLocalizedString(@"WiFi_connet_exceed") forState:UIControlStateNormal];
    [self.ShowTipBtn.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self.ShowTipBtn.titleLabel setNumberOfLines:0];
    
    [self configBackBtn];
    
    [self.checkBtn setTitle:DPLocalizedString(@"NetCheckTitle") forState:UIControlStateNormal];
    [self.checkBtn.titleLabel setTextAlignment:NSTextAlignmentCenter];
    self.checkBtn.titleLabel.numberOfLines = 0;
    [self.checkBtn addTarget:self action:@selector(checkNetWork) forControlEvents:UIControlEventTouchUpInside];
}


/**  smartflg 连接方式：
 0   不支持smart
 1   7601smart
 2   8188smart
 3   ap6212a
 9   不支持二维码扫描
 10  只支持二维码扫描
 11  二维码扫描+7601smart
 12  二维码扫描+8188smart
 13  二维码扫描+ap6212a
 **/


#pragma mark 开启声波配网
- (void)startAcousticWaveAdd{
    
#if KeepAcousticAdd
    [SVProgressHUD showWithStatus:@"Loading..."];
    int base;
    base  = 12000;
    for (int i = 0; i < sizeof(freqs)/sizeof(int); i ++) {
        freqs[i] = base + i *150;
    }
    [recog setFreqs:freqs freqCount:sizeof(freqs)/sizeof(int)];
    [recog start];
    
    [player setFreqs:freqs freqCount:sizeof(freqs)/sizeof(int)];
    [player playSSIDWiFi:self.devWifiName pwd:self.devWifiPassWord playCount:3 muteInterval:200];
#endif
}

- (void)showAddTimeouMsg{
    [self invalidateCheckDevRegTimer];
    self.addDevState = AddDeviceState_Failed_Timeout;
    
    [SVProgressHUD dismiss];
    [self SmartLinkFailure];
}




- (void) onRecognizerStart
{
    printf("------------------recognize start\n");
}


//开始搜索
- (void)startSmartLink
{
    NSLog(@"smartlink  正在连接");
}

//搜索超时
- (void)SmartLinkFailure
{
    NSLog(@"smartlink  失败");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showDoorbellTipsView];
    });
}

//搜索成功
- (void)SmartLinkSuccessful
{
    
    NSLog(@"smartlink  成功");
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.checkIfDevRegisteredCount = 0;
        self.repeatedlyQueryTimes = 0;
        
        self.addDevState = AddDeviceState_CheckingIfDevRegistered;

        [self showConnectingAnimation];

        [self addCheckDevRegisterTimer];
    });
}

- (void)invalidateCheckDevRegTimer{
    if (_checkDevRegisteredTimer) {
        [_checkDevRegisteredTimer invalidate];
        _checkDevRegisteredTimer = nil;
    }
}

- (void)addCheckDevRegisterTimer{
    
    if (!_checkDevRegisteredTimer) {
        _checkDevRegisteredTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(checkIfDeviceRegisteredToServer) userInfo:nil repeats:YES];
    }
}


- (void)showConnectingAnimation{
    
    self.connectStateView.hidden=NO;

    [self startAnimation];
    self.AnimationView.hidden=NO;
}

//加载动画  图片360°旋转
- (void)startAnimation
{
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat:M_PI * -2.0];
    rotationAnimation.duration = 1;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount =ULLONG_MAX;
    rotationAnimation.removedOnCompletion=NO;
    [_AnimationView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)endAnimation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_AnimationView.layer removeAllAnimations];
        
        _AnimationView.hidden = YES;
        _devRegisteredCheckView.hidden=NO;
    });
}


- (void)showAlertWithMsg:(NSString *)msg{
    UIAlertView *msgAlert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:self cancelButtonTitle:DPLocalizedString(@"Title_Confirm") otherButtonTitles:nil, nil];
    msgAlert.delegate = self;
    [msgAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showSuccessAndJumpToDeviceListVC];

    });
}

- (void)dealWithCameraStatus:(MYCAMEREA_STATUS)status{
    switch (status) {
        case MYCAMEREA_STATUS_NO_PAIR:
        {
            AcousticAddGuidePairingVC *guideVC = [AcousticAddGuidePairingVC new];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.navigationController pushViewController:guideVC animated:YES];
            });
            break;
        }
           
        case MYCAMEREA_STATUS_NO_ONLINE:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showAlertWithMsg:DPLocalizedString(@"AcousticAdd_devOffLineCheckBattery")];
                
            });
            break;
        }
            
        case MYCAMEREA_STATUS_NORMAL:
        {
            [self showSuccessAndJumpToDeviceListVC];
            break;
        }
        default:
            break;
    }
}

- (void) showSuccessAndJumpToDeviceListVC{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Configure_success")];
    });
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSNotification *notification =[NSNotification notificationWithName:REFRESH_DEV_LIST_NOTIFY object:nil];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
        
        for (UIViewController *controller in self.navigationController.viewControllers) {
            if ([controller isKindOfClass:[DeviceListViewController class]]) {
                [self.navigationController popToViewController:controller animated:NO];
                break;
            }
        }
    });
}

- (void)checkIfDeviceRegisteredToServer{
    
    BodyCheckDeviceRegisterRequest *body = [BodyCheckDeviceRegisterRequest new];
    CBS_CheckDeviceRegisterRequest *req = [CBS_CheckDeviceRegisterRequest new];
    body.DeviceId = _addDevInfo.devId;
    body.UserName = [SaveDataModel getUserName];
    req.Body = body;
    __weak typeof(self)weakSelf = self;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [[NetSDK sharedInstance] net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:5000 responseBlock:^(int result, NSDictionary *dict) {
            
            weakSelf.checkIfDevRegisteredCount++;
            NSLog(@"________________________checkIfDeviceRegisteredToServer_cnt=%d",weakSelf.checkIfDevRegisteredCount);
            if (result ==0  ) {
                CBS_CheckDeviceRegisterResponse *resp = [CBS_CheckDeviceRegisterResponse yy_modelWithDictionary:dict];
                
                if (resp.Body.Status ==1) {

                    [weakSelf invalidateCheckDevRegTimer];
                    weakSelf.addDevState = AddDeviceState_Binding;
                    if (weakSelf.addDevInfo.addedByOthers) {
                        weakSelf.forceUnbindFailedCnt = 0;
                        [weakSelf forceUnbindDevice];
                    }else{
                        //延迟6秒去绑定
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
                            [weakSelf endAnimation];
                            [weakSelf bind];
                        });
                    }
                }else{
                    if (weakSelf.checkIfDevRegisteredCount<=21 ) {
                        
                    }
                }
            }else{
                if (weakSelf.checkIfDevRegisteredCount<=21 ) {
                    
                }
            }
        }];
    });
}

- (void)bind
{
    if (self.addDevState == AddDeviceState_Failed_Timeout) {
        return;
    }
    NSString *password = @"goscam123";
    CBS_BindRequest *req = [CBS_BindRequest new];
    BodyBindRequest *body = [BodyBindRequest new];
    body.DeviceId = _addDevInfo.devId;
    body.DeviceName = _addDevInfo.devName;
    body.DeviceType = _addDevInfo.deviceType;

    body.DeviceOwner = 1;
    body.AreaId  = @"000001";
    body.StreamUser = @"admin";
    
    body.UserName = [SaveDataModel getUserName];
    body.StreamPassword = password;
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [[NetSDK sharedInstance] net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:7000 responseBlock:^(int result, NSDictionary *dict) {
              NSLog(@"_________________________________________bind_result=%d",result);
            if (result ==-101 || result == -105) {
                //服务端没有准备好，轮询3次
                weakSelf.repeatedlyQueryTimes++;
                if (weakSelf.repeatedlyQueryTimes<=15) {
                    [weakSelf bind];
                }
            }
            else if(result == IROUTER_DEVICE_DUPLICATED){
                [weakSelf showSuccessAndJumpToDeviceListVC];
            }
            else if ([dict[@"MessageType"]isEqualToString:@"BindSmartDeviceResponse"]) {
                
                if (result == 0) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.configureStateView.hidden=NO;
                    });
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [weakSelf showSuccessAndJumpToDeviceListVC];
                    });
                    
                }
                else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                                [weakSelf showTipsView];
                    });
                }
            }
        }];
    });
}

                


- (IBAction)ShowTipViewBtnAction:(id)sender {
    
    [_smart destroySearchTimer];
    [self showDoorbellTipsView];
}


- (void)insertImage:(UIImage*)image atIndex:(NSUInteger)index bounds:(CGRect)bounds inTxtView:(UITextView*)txtView{
    
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 7;// 字体的行间距

    NSDictionary *attributes = @{
                                 NSFontAttributeName:[UIFont systemFontOfSize:14],
                                 NSParagraphStyleAttributeName:paragraphStyle
                                 };
    
    //创建富文本
    NSMutableAttributedString *attri = [[NSMutableAttributedString alloc] initWithString: txtView.text];
    
    [attri addAttributes:attributes range:NSRangeFromString(txtView.text)];
    
    //NSTextAttachment可以将要插入的图片作为特殊字符处理
    NSTextAttachment *attch = [[NSTextAttachment alloc] init];
    //定义图片内容及位置和大小
    attch.image = image;
    attch.bounds = bounds;
    //创建带有图片的富文本
    NSAttributedString *string = [NSAttributedString attributedStringWithAttachment:attch];
    
    //将图片放在最后一位
    //[attri appendAttributedString:string];
    //将图片放在第一位
    [attri insertAttributedString:string atIndex:index];
    //用label的attributedText属性来使用富文本
    txtView.attributedText = attri;
}

- (void)showDoorbellTipsView{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CustomView" owner:self options:nil];
    
    UIView *tmpContentView = [nib objectAtIndex:5];
    tmpContentView.layer.cornerRadius=12;
     UILabel *tipTitle = (UILabel    *)[tmpContentView viewWithTag:4000];
    UITextView * view = (UITextView *)[tmpContentView viewWithTag:4001];
    UIButton *confirmButton  = (UIButton *)[tmpContentView viewWithTag:4003];

    tipTitle.text = DPLocalizedString(@"Configure_show_tip2");
    
    NSRange iconStringRange = [DPLocalizedString(@"Configure_FailedTip_Doorbell") rangeOfString:@"%@"];
    NSString *txtStr = [DPLocalizedString(@"Configure_FailedTip_Doorbell") stringByReplacingOccurrencesOfString:@"%@" withString:@""];
    
    view.text = txtStr;
    [self  insertImage:[UIImage imageNamed:@"AcousticAdd_icon_signal"]
               atIndex:iconStringRange.location
                bounds:CGRectMake(0, -2, 15, 13)
             inTxtView:view];
    
    confirmButton.layer.cornerRadius = 15;
    confirmButton.titleLabel.textColor = UIColor.whiteColor;
    confirmButton.backgroundColor = myColor;
    [confirmButton setTitle:DPLocalizedString(@"Qrcode_soundBtn") forState:0];
    [confirmButton    addTarget:self
                         action:@selector(heardVoiceBtnAction:)
               forControlEvents:UIControlEventTouchUpInside];
    
    customWindow = [[CustomWindow alloc]initWithView:tmpContentView];
    [customWindow show];
}

- (void)heardVoiceBtnAction:(id)sender{
    
    if (customWindow) {
        [customWindow close];
    }
    
    UIViewController *target = nil;
    for (UIViewController * controller in self.navigationController.viewControllers) {
        if ( [controller isKindOfClass:[APDoorbellGoToSettingsVC class]] ) {
            target = controller;
            break;
        }
    }
    if (target) {
        [self.navigationController popToViewController:target animated:NO];
    }
}

- (void)showTipsView
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CustomView" owner:self options:nil];
    
    UIView *tmpContentView = [nib objectAtIndex:2];
    tmpContentView.layer.cornerRadius=12;
    UILabel *tipTitle = (UILabel    *)[tmpContentView viewWithTag:4000];
    UILabel *errLabel = (UILabel    *)[tmpContentView viewWithTag:4003];
    UITextView * view = (UITextView *)[tmpContentView viewWithTag:4001];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 5;// 字体的行间距
    
    NSDictionary *attributes = @{
                                 NSFontAttributeName:[UIFont systemFontOfSize:14],
                                 NSParagraphStyleAttributeName:paragraphStyle
                                 };
    view.attributedText = [[NSAttributedString alloc]
                           initWithString:DPLocalizedString(@"Configure_show_tip")
                           attributes:attributes];
    
    UIButton *WifiButton = (UIButton *)[tmpContentView viewWithTag:4002];
    UIButton *IpcButton  = (UIButton *)[tmpContentView viewWithTag:4004];
    [WifiButton addTarget:self
                   action:@selector(returnWifi:)
         forControlEvents:UIControlEventTouchUpInside];
    
    [IpcButton  addTarget:self
                   action:@selector(returnIpc:)
         forControlEvents:UIControlEventTouchUpInside];
    
    tipTitle.text = DPLocalizedString(@"Configure_show_tip2");
    
    if( _addDevInfo.addDeviceMode == AddDeviceByVoice ){
        errLabel.text = DPLocalizedString(@"Configure_tryAPModeAdd_tip");
    }else if (_addDevInfo.addDeviceMode == AddDeviceByAPMode){
        errLabel.text = DPLocalizedString(@"Configure_tryAcousticAdd_tip");
    }else{
        errLabel.text = DPLocalizedString(@"Configure_show_tip4");
    }
    
    if(self.addDevInfo.addDeviceMode == AddDeviceByVoice){
        errLabel.hidden = YES;
    }
    
    [WifiButton setTitle:DPLocalizedString(@"Configure_back")
                forState:UIControlStateNormal];
    [IpcButton  setTitle:DPLocalizedString(@"Configure_add")
                forState:UIControlStateNormal];
    customWindow = [[CustomWindow alloc]initWithView:tmpContentView];
    [customWindow show];
}

-(void)returnWifi:(id)sender
{
    UIViewController *target = nil;
    for (UIViewController * controller in self.navigationController.viewControllers) {
        if ([controller isKindOfClass:[WifiSettingViewController class]]
            || [controller isKindOfClass:[APModeConfigPreconnectVC class]]
            || [controller isKindOfClass:[AcousticConfigConnectVC class]] ) {
            target = controller;
            break;
        }
    }
    if (target) {
        [customWindow close];
        [self.navigationController popToViewController:target animated:NO];
    }
}

-(void)returnIpc:(id)sender
{
    UIViewController *target = nil;
    for (UIViewController * controller in self.navigationController.viewControllers) {
        if ([controller isKindOfClass:[AddDeviceViewController class]]) {
            target = controller;
            break;
        }
    }
    if (target) {
        [customWindow close];
        [self.navigationController popToViewController:target animated:NO]; //跳转
    }
}


- (BOOL)shouldAutorotate
{
    //NSLog(@"shouldAutorotate . %ld", (long)[[AppInfomation sharedInstance] isPlayerViewShown]);
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)checkNetWork {
    CheckNetViewController *vc = [[CheckNetViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}
@end
