//
//  去掉录像时不能对讲和声音开关的限制
//
//
//  Created by Goscam on 2017/11/24.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "GOSLivePlayerVC.h"
#import "JoystickControllView.h"
#import "Masonry.h"
#import "SettingViewController.h"
#import "UIColor+YYAdd.h"
#import "UIView+YYAdd.h"
#import "CameraInfoManager.h"
#import "DeviceManagement.h"
#import "UISettingManagement.h"
#import "GDVideoPlayer.h"
#import "YYKitMacro.h"
#import <AVFoundation/AVFoundation.h>
#import "RecordDateListViewController.h"
#import <RealReachability.h>
#import "DevicePlayManager.h"
#import "DeviceDataModel.h"
#import "VideoImageManager.h"
#import "NSTimer+YYAdd.h"
#import "HWLogManager.h"
#import "MediaManager.h"
#import "EnlargeClickButton.h"

#import "StreamPasswordView.h"
#import "AcousticAddGuidePairingVC.h"
#import <AFNetworking.h>
#import "SaveDataModel.h"
#import "CloudRecordingServiceInfoVC.h"
#import "CSPackageTypeVC.h"
#import "UIButton+AFNetworking.h"

#import "CMSCommand.h"
#import "DeviceUpdateManager.h"
#import "GosTalkCountDownView.h"
#import "GOSNetStatusManager.h"

#import "CSNetworkLib.h"

#import <../../echocancel.framework/Headers/IoTcare_echo.h>

//播放通知Key
static NSString *const PlayStatusNotification = @"PlayStatusNotification";

#define JOYSTICK_ANIMATION_DURATION 0.25f
#define NetInstanceManager [NetAPISet sharedInstance]
//#define playViewRatio (iPhone4 ? (3/4.0f):(2.0/3.0f))
#define playViewRatio (SYName_iPhone_X == [SYDeviceInfo syDeviceName] ? (3/4.0f):(9/16.0f))

#define trueSreenWidth  (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))
#define trueScreenHeight (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))

#define HeightForStatusBarAndNaviBar (SYName_iPhone_X == [SYDeviceInfo syDeviceName]?88:64)

static NSString * const kNotifyDevStatus    = @"NotifyDeviceStatus";


//流加密存储key
static NSString * const StreamPassWordKey    = @"StreamPassWordKey";

/** 全屏切换动画时长（单位：秒） */
#define TRANSFORM_DURATION 0.25f

/** 横屏旋转切换状态 枚举*/
typedef NS_ENUM(NSUInteger, TransformViewState) {
    TransformViewSmall,             // 竖屏（小屏）状态
    TransformViewAnimating,         // 正在切换状态
    TransformViewFullscreen,        // 横屏（全屏）状态
};


typedef NS_ENUM(NSInteger, VideoQulityType) {
    VideoQulity_HD                  = 0x00,     // 高清
    VideoQulity_SD                  = 0x01,     // 标清
};


typedef NS_ENUM(NSUInteger, TalkingMode) {
    TalkingMode_HalfDuplex=1,
    TalkingMode_FullDuplex,
};

typedef NS_ENUM(NSUInteger, FullDuplexTalkingState) {
    FullDuplexTalkingState_Ended=0,
    FullDuplexTalkingState_Talking,
};

typedef void(^VideoQualityResulotBlock)(NSString *deviceId, VideoQulityType vqType);



@interface GOSLivePlayerVC ()<
                            GDVideoPlayerDelegate,
                            GDNetworkSourceDelegate,
                            GDNetworkStateDelegate,
                            IoTcareEchoDelegate,AGCProcessDelegate
                            >
{
    
    //是否连接上视频流
    BOOL _isRunning;
    
    //audio Flag
    BOOL _isAudioOn;
    
    //videoFlag
    BOOL _videoFlag;
    
    //判断是否录像标志
    BOOL _isRecordflag;
    
    //speakFlag
    BOOL _speakFlag;
    
    //视频码率切换
    BOOL _videoQualityChanged;
    
    //摄像头码率标识
    int _segmentIndex;
    
    //是否第一次进入
    BOOL _isFirstIn;
    
    //是否camera关闭
    BOOL _isCameraOff;
    
    //是否停止
    BOOL _isStop;
    
    //是否有摇篮曲
    BOOL _isHasBabyMusic;
    
    //是否在对讲中
    BOOL _isTalk;
    
    // 该标志用于是否打开过全双工对讲 如果打开过全双工对讲 需要在视图消失前调用[self performSelectorInBackground:@selector(activeAudioSessionModeforStopSpeak) withObject:nil];方法
    BOOL hasOpenFullTalk;
    
    int openTalkSuccess;
    
    

    dispatch_queue_t sendAudioDataQueue;
}

@property (nonatomic, assign) BOOL agcEnabled;

@property (nonatomic, assign)  FullDuplexTalkingState fullDuplexTalkingState;

@property (strong, nonatomic)  NSFileHandle *g711FileHandle;
@property (strong, nonatomic)  NSString *g711TalkFilePath;

/** 主设备加子设备的ID */
@property (nonatomic, strong)  NSString *devAndSubDevID;

@property (nonatomic, assign)  TalkingMode talkingMode;

@property (strong, nonatomic)  IoTcare_echo *echoCanceller;


@property (strong, nonatomic)  DeviceUpdateManager *devUpdateManager;


/** I 帧时间间隔 */
@property (assign, nonatomic)  CGFloat iFrameInterval;

/** 设备的详细类型 5600，5100 */
@property (assign, nonatomic)  GosDetailedDeviceType deviceTypeInDetail;


///** 顶部 View */
//@property (strong, nonatomic)  UIView *topView;
//
///** 操作提示 Label */
//@property (strong, nonatomic)  UILabel *tipsLabel;
//
///** 时间显示 Label */
//@property (strong, nonatomic)  UILabel *timeLabel;

/** 播放视频 View */
@property (strong, nonatomic)  UIView *playView;

//audio Flag
@property (assign, nonatomic)  BOOL audioFlag;

/** 播放控制 View */
@property (strong, nonatomic)  UIView *playControllView;

/** 摇篮曲开关按钮 */
@property (strong,nonatomic)   UIButton *babyMusicBtn;

/** 录像 Button */
@property (strong, nonatomic)  UIButton *recordingBtn;

/** 录像 标题 */
@property (strong, nonatomic)  UILabel *recordingLabel;

/** 云台控制 Button */
@property (strong, nonatomic)  UIButton *joystickBtn;

/** 画面质量切换 Button */
@property (strong, nonatomic)  UIButton *qualityChangeBtn;

/** 画面质量切换 Label */
@property (nonatomic,strong)  UILabel  *qualityChangeLabel;

/** 显示电量  */
@property (nonatomic,strong)  UIImageView *batteryLevelImgView;

/** 显示连接信号  */
@property (nonatomic,strong)  UIImageView *netLinkSignalImgView;

/** 录像时间显示 View */
@property (strong, nonatomic)  UIView *recordTimeView;

/** 录像闪烁提示 View */
@property (strong, nonatomic)  UIView *recordingShowView;

/** 录像时间 Label */
@property (strong, nonatomic)  UILabel *recordTimeLabel;

/** 视频数据加载 Activity */
@property (strong, nonatomic)  UIActivityIndicatorView *loadVideoActivity;

#pragma mark - 全屏按钮




/** 全屏顶部控制按钮 容器 */
@property (strong, nonatomic)  UIView *topBtnsContainer;


/** 声音开关 全屏按钮 */
@property (strong, nonatomic)  EnlargeClickButton *soundBtn_fullScreen;


/** 全屏右端控制按钮 容器 */
@property (strong, nonatomic)  UIView *rightBtnsContainer;

/** 对讲 全屏按钮 */
@property (strong, nonatomic) UIButton *talkBtn_fullScreen;

/** 拍照 全屏按钮 */
@property (strong, nonatomic) UIButton *snapshotBtn_fullScreen;

/** 录像 全屏按钮 */
@property (strong, nonatomic)  UIButton *recordingBtn_fullScreen;


/** 底部 View */
@property (strong, nonatomic)  UIView *bottomView;

/** 声音开关 Button */
@property (strong, nonatomic)  UIButton *soundBtn;

/** 对讲 Button */
@property (strong, nonatomic) UIButton *talkBtn;

/** 拍照 Button */
@property (strong, nonatomic) UIButton *snapshotBtn;

/** 声音开关 Label */
@property (nonatomic,strong)UILabel *soundLabel;

/** 对讲 Label */
@property (nonatomic,strong)UILabel *talkLabel;

/** 拍照 Label */
@property (nonatomic,strong)UILabel *snapshotLabel;

/** 控制杆区域 View */
@property (nonatomic, strong) JoystickControllView *joystickView;

/** 重新请求按钮 */
@property (nonatomic, strong) UIButton *reloadBtn;

/** 离线按钮 */
@property (nonatomic, strong) UIButton *offlineBtn;

/** 摄像头关闭按钮 */
@property (nonatomic, strong) UIButton *cameraOffBtn;

/** 对讲弹出的View */
@property (nonatomic, strong) UIImageView *talkingView;


@property (nonatomic, strong)  GosTalkCountDownView *countDownView;

/** 预览图片imgView */
@property (nonatomic, strong) UIImageView *previewImgView;

/** Camera Info Manager */
@property (nonatomic, strong) CameraInfoManager *cameraInfoManger;

/** 播放器 */
@property (nonatomic, strong) GDVideoPlayer *gdVideoPlayer;

/** 设备设置model，用于和设置页面交互 */
@property (nonatomic, strong) UISettingModel *refreshSettingModel;

/** 设备初始设置model */
@property (nonatomic, strong) UISettingModel *settingModel;

/** 获取设备能力resp */
@property (nonatomic, strong) CMD_GetDevAbilityResp *devAbilityCmd;

/** 录像按钮点击声音 播放器 */
@property (nonatomic, strong) AVAudioPlayer *recordBtnAudioPlayer;

/** 对讲按钮点击声音 播放器 */
@property (nonatomic, strong) AVAudioPlayer *talkBtnAudioPlayer;

/** 拍照按钮点击声音 播放器 */
@property (nonatomic, strong) AVAudioPlayer *snapShotBtnAudioPlayer;

/** record定时器 */
@property (nonatomic, strong) NSTimer* recordIconTimer;

/** record 闪烁View定时器 */
@property (nonatomic, strong) NSTimer* recordShowViewTimer;

/** 云台控制队列 */
@property (nonatomic, strong) dispatch_queue_t moveQueue;

@property (assign, nonatomic)  NSInteger repeatCount;


/** 对讲倒计时定时器 */
@property (nonatomic, strong)NSTimer *countDownTimer;

/** 切换清晰度指令超时定时器 */
@property (nonatomic, strong)NSTimer *cmdTimeoutTimer;

/** 平台UID*/
@property (nonatomic, strong)NSString *platformUID;

/** 温度定时器 */
@property (nonatomic,strong)NSTimer *temperatureTimer;

/** 温度imageView */
@property (nonatomic,strong)UIImageView *temperatureImageView;

/** 温度Label */
@property (nonatomic,strong)UILabel *temperatureLabel;

/** 是否全屏 */
@property (nonatomic,assign)BOOL isLandSpace;

/** 流超时定时器 */
@property(nonatomic,strong)NSTimer *streamTimer;

/** 获取连接信号定时器 */
@property(nonatomic,strong)NSTimer *getNetLinkSignalTimer;

/** 获取电池电量定时器 */
@property(nonatomic,strong)NSTimer *getBatteryLevelTimer;

/** 拉流计时器 */
@property(nonatomic,assign)NSUInteger streamTime;

@property (nonatomic,strong)dispatch_queue_t serailQueue;

@property (nonatomic,strong)StreamPasswordView *passwordView;



/**云存储服务是否在有效期内*/
@property(nonatomic,assign) BOOL csValid;

/** 请求CS状态失败 重新请求 */
@property(nonatomic,assign) BOOL requestCSStatusSuccesfully;

/** 云存储广告图片 */
@property (strong, nonatomic)  UIButton *csAdvertisingBtn;

@property (assign, nonatomic)  BOOL isLoading;

@end


@implementation GOSLivePlayerVC

#pragma mark - ViewController 生命周期
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    //初始化参数
    [self initParameter];
    
    //初始化UI
    [self setupUI];
    
    //初始化音频
    [self audioInit];
    
    //禁用锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    //添加云台控制手势
    [self swipeRecognizerFor:self.playView];
    
    //后台事件监听
    [self addBackgroundRunningEvent];
    
    //创建文件夹
    [self creatFolder];
    
    [self addClientConnectStatusNotification];
    
    //锁屏监听
    [self addLockScreenMonitor];
    
    self.serailQueue = dispatch_queue_create("StopAction", DISPATCH_QUEUE_SERIAL);
    
    [self checkNetwork];

    sendAudioDataQueue = dispatch_queue_create("SendAudioDataQueue", NULL);
}

- (void)checkNetwork{
    
    if (self.deviceModel.Status != GosDeviceStatusOnLine) {
        //不在线 return
        return;
    }
    [GOSNetStatusManager checkIfUsingCellularData];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        CSPackageTypeVC *vc = [CSPackageTypeVC new];
//        vc.deviceModel                     = self.deviceModel;
//        [self.navigationController pushViewController:vc animated:YES];
//    });
}

- (void)stopCheckingNetwork{
    [GOSNetStatusManager stopCheckingUsingCellularData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.deviceModel.Status == 1) {
        //填充播放器
        [self configGDPlayer];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //刷新设备名称和导航条透明度
    self.navigationController.navigationBar.translucent=YES;
    for (DeviceDataModel *model in [[DeviceManagement sharedInstance] deviceListArray]) {
        if ([model.DeviceId isEqualToString:self.deviceModel.DeviceId]) {
            _deviceName = model.selectedSubDevInfo.ChanName.length>0 ? model.selectedSubDevInfo.ChanName:  model.DeviceName;
            break;
        }
    }
    self.navigationItem.title = _deviceName;
    [self initAppearAction];
    
    if (_isLandSpace) {
        [self resetPlayerView];
    }
    
//#warning::::强制升级，下版取消
    [self queryDeviceUpdateState];
    
    [self addEnterForegroundNotifications];
}



- (void)resetPlayerView{
    [UIView animateWithDuration:0.25 animations:^{
        {
            _isLandSpace = NO;
            [self.navigationController setNavigationBarHidden:NO animated:NO];
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
            [[UIApplication sharedApplication] setStatusBarHidden:NO];
            //半屏幕约束
            [self.playView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.view).offset(HeightForStatusBarAndNaviBar);
                make.left.right.equalTo(self.view);
                make.height.mas_equalTo(self.playView.mas_width).multipliedBy(playViewRatio);
            }];
            
            
            if (_gdVideoPlayer) {
                [_gdVideoPlayer resizePlayViewFrame:CGRectMake(0, 0, trueSreenWidth, trueSreenWidth * playViewRatio)];
            }
            
            [self hideFullScreenCtrlBtns:YES];
        }
        
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
    }];
}



- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent=NO;
    [super viewWillDisappear:animated];
    [self leaveViewAction];
    //销毁拉流定时器
    [self stopStreamTimer];
    [self stopTemperatureTimer];
    [self stopValidTimers];
    [self removeEnterForegroundNotifications];
    
    if (self.talkingMode == TalkingMode_FullDuplex && _isTalk == YES)
        [_echoCanceller IoTcare_echo_destroy];
    
    if (hasOpenFullTalk)
        [self performSelectorInBackground:@selector(activeAudioSessionModeforStopSpeak) withObject:nil];
    
    if (_agcEnabled)
        [_echoCanceller IoTcare_agc_destroy];
    
//    if ( self.talkingMode == TalkingMode_FullDuplex ) {
//#warning TODO
//        [_echoCanceller IoTcare_agc_destroy];
//    }
    //self.fullDuplexTalkingState == FullDuplexTalkingState_Talking?
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (_isLandSpace) {
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }
}

- (void)dealloc
{
    [self stopCheckingNetwork];

    [self releaseBtnSoundAudioPlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"----------- PlayVideoViewController dealloc -----------");
}


#pragma mark - 初始化设置相关
#pragma mark -- 初始化参数
- (void)initParameter
{
    _videoFlag            = NO;
    _isRunning            = NO;
    _isAudioOn            = NO;
    _isRecordflag         = NO;
    _speakFlag            = NO;
    _videoQualityChanged  = NO;
    _isLandSpace          = NO;
    _isFirstIn            = NO;
    _isHasBabyMusic       = NO;
    _segmentIndex         = 0;

    NSLog(@"________________________talkingMode:%lu",(unsigned long)self.talkingMode);
    self.deviceTypeInDetail = [DeviceDataModel detailedDeviceTypeWithString: [self.deviceModel.DeviceId substringWithRange:NSMakeRange(3, 2)]] ;
}


#pragma mark -- 设置相关 UI
- (void)setupUI{
    //标题
    self.title = self.deviceName;
    
    //添加导航按钮
    [self configNavItem];
    
    //添加子View
    
    [self.view addSubview:self.playView];
    [self.view addSubview:self.playControllView];
    
    [self.view addSubview:self.rightBtnsContainer];
    [self.view addSubview:self.topBtnsContainer];
    
//    [self.view addSubview:self.babyMusicBtn];

    
    if (![self isWiFiDoorBell] ) {
        
        [self.playControllView addSubview:self.joystickBtn];
        [self.playControllView addSubview:self.qualityChangeBtn];
        [self.qualityChangeBtn addSubview:self.qualityChangeLabel];
    }else{
        [self.rightBtnsContainer addSubview:self.snapshotBtn_fullScreen];
        [self.rightBtnsContainer addSubview:self.talkBtn_fullScreen];
        [self.rightBtnsContainer addSubview:self.recordingBtn_fullScreen];
        
        [self.topBtnsContainer addSubview:self.soundBtn_fullScreen];
    }
    
    [self.view addSubview:self.recordTimeView];
    [self.recordTimeView addSubview:self.recordingShowView];
    [self.recordTimeView addSubview:self.recordTimeLabel];
    [self.view addSubview:self.loadVideoActivity];
    [self.view addSubview:self.bottomView];
    
    [self.bottomView addSubview:self.soundBtn];
    [self.bottomView addSubview:self.talkBtn];
    [self.bottomView addSubview:self.snapshotBtn];
    [self.bottomView addSubview:self.recordingBtn];
    
    [self.bottomView addSubview:self.recordingLabel];
    [self.bottomView addSubview:self.soundLabel];
    [self.bottomView addSubview:self.talkLabel];
    [self.bottomView addSubview:self.snapshotLabel];
    
//    [self.view addSubview:self.joystickView];
    [self.view addSubview:self.talkingView];
    [self.view addSubview:self.countDownView];
    
    
    [self.view addSubview:self.reloadBtn];
    [self.view addSubview:self.offlineBtn];
    [self.view addSubview:self.cameraOffBtn];
    
    [self.view addSubview:self.temperatureLabel];
    [self.view addSubview:self.temperatureImageView];
    //    [self.playView insertSubview:self.previewImgView atIndex:0];

    [self.view addSubview: self.csAdvertisingBtn];

    [self makeConstraints];
}

#pragma mark - 设置约束
- (void)makeConstraints{
    
    //设置约束
    //    [self.topView mas_makeConstraints:^(MASConstraintMaker *make) {
    //     make.top.equalTo(self.view).offset(HeightForStatusBarAndNaviBar);

    //        make.leading.trailing.equalTo(self.view);
    //        make.height.mas_equalTo(20);
    //    }];
    //
    //    [self.tipsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    //        make.left.equalTo(self.topView).offset(30);
    //        make.top.equalTo(self.topView);
    //        make.height.equalTo(@20);
    //        make.width.equalTo(@250);
    //    }];
    //
    //    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    //        make.top.equalTo(self.topView);
    //        make.height.equalTo(@30);
    //        make.right.equalTo(self.topView).offset(-30);
    //        make.width.equalTo(@200);
    //    }];
    
    
    [self.playView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.equalTo(self.view).offset(HeightForStatusBarAndNaviBar);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(self.playView.mas_width).multipliedBy(playViewRatio);
    }];
    
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    
    //真实屏幕宽度
    CGFloat playHeight = trueSreenWidth *playViewRatio;
    //计算一下控制按钮的宽高
    NSUInteger controllBtnHW = (playHeight - 20 - 6 *3.0f)/4.0f;
    
    [self.playControllView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.playView).offset(15);
        make.top.bottom.equalTo(self.playView);
        make.width.mas_equalTo(controllBtnHW);
    }];
    
    [self.rightBtnsContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.playView).offset(-15);
        make.top.bottom.equalTo(self.playView);
        make.width.mas_equalTo(15+53*screenWidth/370);
    }];
    
    [self.topBtnsContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.playView);
        make.height.mas_equalTo(controllBtnHW);
    }];
    
    
//    [self.babyMusicBtn mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.equalTo(self.playView).offset(32);
//        make.right.equalTo(self.playView).offset(-18);
//        make.width.height.mas_equalTo(36);
//    }];
    
    [self.csAdvertisingBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.playView.mas_bottom);
        make.centerX.equalTo(self.view);
        make.leading.equalTo(self.view);
        make.height.mas_equalTo(92);
    }];
    
    if (![self isWiFiDoorBell]) {
        
        
        [self.qualityChangeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.playControllView);
            make.top.equalTo(self.joystickBtn.mas_bottom).offset(6);
            make.height.mas_equalTo(controllBtnHW);
        }];
        
        [self.qualityChangeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.qualityChangeBtn);
        }];
    }else{
        
        CGFloat talkBtnWAndH = 53*screenWidth/370;
        CGFloat snapShotBtnWAndH = 40*screenWidth/370;
        CGFloat itemSpacing = 38*screenWidth/370;

        [self.talkBtn_fullScreen mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.rightBtnsContainer);
            make.centerY.equalTo(self.rightBtnsContainer);
            make.width.height.mas_equalTo(talkBtnWAndH);
        }];
        
        [self.snapshotBtn_fullScreen mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.rightBtnsContainer);
            make.width.height.mas_equalTo(snapShotBtnWAndH);
            make.bottom.equalTo(self.talkBtn_fullScreen.mas_top).offset(-itemSpacing);
        } ];
        
        [self.recordingBtn_fullScreen mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.rightBtnsContainer);
            make.width.height.mas_equalTo(snapShotBtnWAndH);
            make.top.equalTo(self.talkBtn_fullScreen.mas_bottom).offset(itemSpacing);
        }];
        
        [self.soundBtn_fullScreen mas_makeConstraints:^(MASConstraintMaker *make) {
             make.centerX.equalTo(self.rightBtnsContainer);
            make.top.equalTo(self.topBtnsContainer).offset(15);
            make.width.height.mas_equalTo(30*screenWidth/370);
        }];
    }
    
    
    [self.recordTimeView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.right.equalTo(self.playView).offset(-30);
        make.centerX.equalTo(self.playView);
        make.top.equalTo(self.playView).offset(10);
        make.width.equalTo(@80);
        make.height.equalTo(@30);
    }];
    
    [self.recordTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.recordTimeView).offset(5);
        make.bottom.equalTo(self.recordTimeView).offset(-5);
        make.left.equalTo(self.recordTimeView).offset(5);
        make.width.equalTo(@40);
    }];
    
    [self.recordingShowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.recordTimeLabel.mas_right).offset(0);
        make.top.equalTo(self.recordTimeView).offset(10);
        make.width.height.equalTo(@10);
    }];
    
    [self.loadVideoActivity mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.playView.mas_centerY);
        make.centerX.equalTo(self.playView.mas_centerX);
        make.width.height.equalTo(@50);
    }];
    
    CGFloat bottomHeight = (MAX(screenWidth, screenHeight) - HeightForStatusBarAndNaviBar - 30.0f - playHeight);
    
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.playView.mas_bottom);
        //这里添加40
        make.height.mas_equalTo(bottomHeight + 42);
        make.left.right.equalTo(self.view);
    }];
    
    //计算按钮大小 默认对讲按钮是1.2倍声音按钮大
    CGFloat bottomBtnWH;
//    bottomBtnWH = 53*screenWidth/360;
//
//    CGFloat itemSpacingInX = 55*screenWidth/360;
//    CGFloat itemSpacingInY = 31*screenWidth/360;
//    CGFloat bottomSpacing = (SYName_iPhone_X == [SYDeviceInfo syDeviceName]?1.5:1)* 60*screenWidth/360;

//    bottomBtnWH = (trueSreenWidth - 32 - 68)/4.0f;
//    CGFloat itemSpacing = 42*screenWidth/360;
//    CGFloat spacingInY = 58*screenWidth/375;
    
    CGFloat itemSpacing = 20;
    CGFloat spacingInY = 20;
    bottomBtnWH = (MIN([UIScreen mainScreen].bounds.size.width, bottomHeight+42-self.csAdvertisingBtn.height)-itemSpacing-spacingInY)/3;
    
    
    [self.recordingBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.bottomView);
//        make.top.equalTo(self.bottomView).offset(110*screenWidth/375);
        make.top.equalTo(self.csAdvertisingBtn.mas_bottom).offset(spacingInY);
        make.height.width.mas_equalTo(bottomBtnWH);
    }];
    
    int talkLabelH = 20, talkLabelOffset = 5;
    [self.talkBtn mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.equalTo(self.recordingLabel.mas_bottom).offset(spacingInY);
        make.bottom.equalTo(self.bottomView.mas_bottom).offset(-(spacingInY+talkLabelH+talkLabelOffset));
        make.centerX.equalTo(self.bottomView);
        make.height.width.mas_equalTo(bottomBtnWH);
    }];
    
    [self.soundBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.bottomView.mas_centerY).offset(self.csAdvertisingBtn.height/2);
//        make.right.equalTo(self.talkBtn.mas_left).offset(-itemSpacing);
        make.left.equalTo(self.bottomView.mas_left).offset(itemSpacing);
        make.height.width.mas_equalTo(bottomBtnWH);
    }];
    
    [self.snapshotBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.soundBtn.mas_centerY);
        make.right.equalTo(self.bottomView.mas_right).offset(-itemSpacing);
        make.height.width.mas_equalTo(bottomBtnWH);
    }];
    
    
    
    [self.recordingLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.recordingBtn);
        make.top.equalTo(self.recordingBtn.mas_bottom).offset(0);
        make.width.mas_equalTo(screenWidth);
    }];
    
    
    [self.soundLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.soundBtn);
        make.height.equalTo(@20);
        make.width.equalTo(@100);
        make.top.equalTo(self.soundBtn.mas_bottom).offset(0);
    }];
    
    [self.talkLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.talkBtn);
        make.height.equalTo(@(talkLabelH));
        make.width.equalTo(@180);
        make.top.equalTo(self.talkBtn.mas_bottom).offset(talkLabelOffset);
    }];
    
    [self.snapshotLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.snapshotBtn);
        make.height.equalTo(@20);
        make.width.equalTo(@100);
        make.top.equalTo(self.snapshotBtn.mas_bottom).offset(0);
    }];
    
    
    
    //reloadBtn
    [self.reloadBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.centerX.equalTo(self.playView);
        make.width.equalTo(@200);
        make.height.equalTo(@30);
    }];
    
    [self.offlineBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.centerX.equalTo(self.playView);
        make.width.equalTo(@200);
        make.height.equalTo(@30);
    }];
    
    [self.cameraOffBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.centerX.equalTo(self.playView);
        make.width.equalTo(@250);
        make.height.equalTo(@30);
    }];
    
    
    [self.talkingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(self.view);
        make.width.height.mas_equalTo(120);
    }];
    
    [self.countDownView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.width.height.mas_equalTo(100);
    }];
    
    //    [self.previewImgView mas_makeConstraints:^(MASConstraintMaker *make) {
    //        make.edges.equalTo(self.playView);
    //    }];
    
    
    [self.temperatureLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-8);
        make.bottom.equalTo(self.playView).offset(-18);
        make.height.equalTo(@12);
        make.width.equalTo(@30);
    }];
    
    [self.temperatureImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.temperatureLabel.mas_left);
        make.bottom.equalTo(self.playView).offset(-5);
        make.height.equalTo(@25);
        make.width.equalTo(@14);
    }];

}


#pragma mark - 设备升级
extern bool gos_firmware_next_time_update;
- (void)queryDeviceUpdateState{
    if (gos_firmware_next_time_update == true) {
        return ;
    }
    _devUpdateManager = [DeviceUpdateManager new];
    _devUpdateManager.deviceId = self.platformUID;
    _devUpdateManager.isWiFiDoorBell = YES;

    __weak typeof(self) weakSelf = self;
    [_devUpdateManager userFinishUpdatingCallback:^(BOOL updateSuccessfully) {
        [weakSelf.navigationController popViewControllerAnimated:YES];
    }];
    
    [_devUpdateManager queryDeviceUpdateState:^(BOOL needToUpdate) {
        if (needToUpdate) {
            [weakSelf stopConnecting];
            [weakSelf.loadVideoActivity stopAnimating];
            weakSelf.loadVideoActivity.hidden = YES;
        }
    }];
}

#pragma mark - 门铃判断设备是否已配对
- (void)checkCameraStatusOfDoorbell{
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_async(queue, ^{
        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [SVProgressHUD showSuccessWithStatus:@"请求子设备状态"];
//        });
        
        CMD_GetDoorbellCameraStatusReq *req = [CMD_GetDoorbellCameraStatusReq new];
        req.channel = _deviceModel.selectedSubDevInfo.ChanNum;
        NSDictionary *reqData = [req requestCMDData];
        
        __weak typeof(self) weakSelf = self;
        [[NetSDK sharedInstance] net_sendBypassRequestWithUID:self.deviceModel.DeviceId requestData:reqData timeout:7000 responseBlock:^(int result, NSDictionary *dict) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            if (result == 0 ) {
                CMD_GetDoorbellCameraStatusResp *resp = [CMD_GetDoorbellCameraStatusResp yy_modelWithDictionary:dict];
                [strongSelf dealWithCameraStatus:resp.camera_status];
            }else{
                
            }
        }];
    });
}

- (void)showAlertWithMsg:(NSString *)msg{
    UIAlertView *msgAlert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:self cancelButtonTitle:DPLocalizedString(@"Title_Confirm") otherButtonTitles:nil, nil];
    msgAlert.delegate = self;
    [msgAlert show];
}

- (void)showAlertWithTitle:(NSString*)title Msg:(NSString *)msg{
    UIAlertView *msgAlert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:DPLocalizedString(@"Setting_Cancel") otherButtonTitles:nil];
//    UIAlertView *msgAlert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:DPLocalizedString(@"Setting_Cancel") otherButtonTitles:DPLocalizedString(@"Setting_Setting"), nil];
    msgAlert.delegate = self;
    [msgAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:MLocalizedString(Privacy_Microphone_Forbidden_Title)]) {
        if (buttonIndex == 1) {

            //App-Prefs:root=WIFI
            //App-prefs:root=Privacy&path=Microphone
//            NSURL *url = [NSURL URLWithString:@"App-prefs:root=com.xm.gosbell"];
//            NSURL *url1 = [NSURL URLWithString:@"App-prefs:root=com.xm.gosbell"];
//
//            if ([UIDevice systemVersion] >= 11.0 ) {
//                [[UIApplication sharedApplication]openURL:url1];
//            }else{
//                [[UIApplication sharedApplication]openURL:url];
//            }
        }
    }else{
        [self navBack];
    }
}


- (void)dealWithCameraStatus:(MYCAMEREA_STATUS)status{
    NSLog(@"++++++++++++++++++++++++++dealWithCameraStatus:%lu",(unsigned long)status);
    switch (status) {
        case MYCAMEREA_STATUS_NO_PAIR:
        {
            AcousticAddGuidePairingVC *guideVC = [AcousticAddGuidePairingVC new];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.navigationController pushViewController:guideVC animated:YES];
            });
            break;
        }
            
        case MYCAMEREA_STATUS_CHANGE_BATTERY:
        case MYCAMEREA_STATUS_NO_ONLINE:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showAlertWithMsg:DPLocalizedString(@"AcousticAdd_devOffLineCheckBattery")];
            });
            break;
        }
        case MYCAMEREA_STATUS_FORBID_STREAM:
        {
            [self stopConnecting];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self.loadVideoActivity stopAnimating];
                self.loadVideoActivity.hidden = YES;
                
                [self showAlertWithMsg:DPLocalizedString(@"DB_BatteryLow_Tip")];
            });
            break;
        }
            
        case MYCAMEREA_STATUS_NORMAL:
        {
            break;
        }
        default:
            break;
    }
}

//是否为门铃设备，5100、5200
- (BOOL)isWiFiDoorBell{
    return self.deviceTypeInDetail==GosDetailedDeviceType_T5100ZJ || self.deviceTypeInDetail == GosDetailedDeviceType_T5200HCA;
}


#pragma mark - 设置导航栏按钮
-(void)configNavItem
{
    if (![self isWiFiDoorBell]) {
        UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        infoButton.frame = CGRectMake(0.0, 0.0, 40, 40);
        [infoButton setImage:[UIImage imageNamed:@"PlayBlackSetting"] forState:UIControlStateHighlighted];
        [infoButton setImage:[UIImage imageNamed:@"PlayWhiteSetting"] forState:UIControlStateNormal];
        [infoButton addTarget:self action:@selector(showCameraInfoView) forControlEvents:UIControlEventTouchUpInside];
        infoButton.exclusiveTouch = YES;
        UIBarButtonItem *infotemporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
        infotemporaryBarButtonItem.style = UIBarButtonItemStylePlain;
        self.navigationItem.rightBarButtonItem=infotemporaryBarButtonItem;
    }
    
    UIImage *image = [UIImage imageNamed:@"addev_back"];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 40, 40);
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self
               action:@selector(navBack)
     forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    leftBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
    
}




//初始化音频任务
- (void)audioInit{
    [self activeAudioSessionMode];
//    AVAudioSession *session = [AVAudioSession sharedInstance];
//    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [self initVoiceLib];
}


#pragma mark - 进入界面初始化

- (void)initAppearAction{
//    [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"在线状态：%d",self.deviceModel.Status]];
    if (self.deviceModel.Status == 1) {
        
        //初始化运行状态
        [self initRunningStatus];
        
        //填充播放器
//        [self configGDPlayer];
        
        //设置net代理
        [self setApiNetDelegate];
        
        //连接设备
        [self connctToDevice];
    }
    else{
        //设备不在线
        [self.loadVideoActivity stopAnimating];
        self.loadVideoActivity.hidden = YES;
        self.reloadBtn.hidden = YES;
        self.offlineBtn.hidden = NO;
        self.playView.layer.contents = [UIImage imageNamed:@""];
        _isRunning = NO;
    }
    
    //请求CS状态
    [self getCSStatus];
}


/**
 初始化设备运行状态
 */
- (void)initRunningStatus{
    _isRunning = NO;
    _isCameraOff = NO;
    self.reloadBtn.hidden = YES;
    self.offlineBtn.hidden = YES;
    self.cameraOffBtn.hidden = YES;
    [self.loadVideoActivity startAnimating];
    self.loadVideoActivity.hidden = NO;
    
    //获取摄像头开关
    [self getCameraSwitchStatus];
    
    //获取设置
    [self getDeviceSetting:nil];
}


/**
 连接设备拉流
 */
- (void)connctToDevice{
    //判断是否已经连接设备
    BOOL isConnected = [NetInstanceManager isDeviceConnectedWithUID:self.deviceId];
    if (isConnected) {
        _isRunning = YES;
        //已经连接，拉流
        NSLog(@"播放SD卡------4");
        [self getLiveStreamData];
    }
    else{
        //主动添加设备
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [[NetAPISet sharedInstance] addClient:self.deviceId andpassword:self.deviceModel.StreamPassword];
        });
    }
    
}


#pragma mark - 开/锁屏监听
- (void)addLockScreenMonitor
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(intoLock)
                                                 name:LOCK_SCREEN_NOTIFY
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resignLock)
                                                 name:UN_LOCK_SCREEN_NOTIFY
                                               object:nil];
}

- (void)intoLock{
    //停止视频录制
    [self stopVideoRecord];
}


- (void)resignLock{
}

#pragma mark - 连接状态回调


- (void)showConnectStateWithUID:(NSString*)UUID state:(NotificationType)type error_ret:(int)error_ret
{
    
    if (error_ret < 0) {
        if (_reloadBtn.hidden) {
            dispatch_async_on_main_queue(^{
                self.reloadBtn.hidden = NO;
                //去除预览图片
                self.playView.layer.contents = (id)[UIImage imageNamed:@""];
                [self.loadVideoActivity stopAnimating];
                self.loadVideoActivity.hidden = YES;
            });
        }
        
        if (type == NotificationTypeDisconnect) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showNewStatusInfo:DPLocalizedString(@"localizied_293")];
                //去除预览图片
                self.playView.layer.contents = (id)[UIImage imageNamed:@""];
                //显示离线按钮
                self.reloadBtn.hidden = NO;
            });
            _isRunning = NO;
        }
    }
    else
    {
        if (type == NotificationTypeConnected) {
            if (_isRunning != YES) {
                _isRunning = YES;
                
                dispatch_async_on_main_queue(^{
                    if (!_reloadBtn.hidden) {
                        _reloadBtn.hidden = YES;
                    }
                });
                
            }
        }
        else{
            //这里也是连接失败 --先这么处理
            dispatch_async_on_main_queue(^{
                [self.loadVideoActivity stopAnimating];
                self.loadVideoActivity.hidden = YES;
                if (type == NotificationTypeDisconnect) {
                    //                    [self showNewStatusInfo:DPLocalizedString(@"Play_Ipc_unonline")];
                    self.reloadBtn.hidden = NO;
                    //去除预览图片
                    self.playView.layer.contents = (id)[UIImage imageNamed:@""];
                }
                
            });
        }
    }
}


- (void)addClientConnectStatusNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectStatusChange:)
                                                 name:ADDeviceConnectStatusNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(passwordError:)
                                                 name:ADDevicePwdErrorNotification
                                               object:nil];
}


#pragma mark - 连接状态回调
- (void)connectStatusChange:(NSNotification *)notifyData{
    NSDictionary *statusDict = notifyData.userInfo;
    
    NSString *UID = statusDict[@"UID"];
    
    if (!UID || ![UID isKindOfClass:[NSString class]]) {
        return;
    }
    
    if (![UID isEqualToString:self.deviceId]) {
        return;
    }
    
    if (!self.gdVideoPlayer) {
        return;
    }
    NSNumber *statusNumber = statusDict[@"State"];
    [self showConnectStateWithUID:UID state:statusNumber.intValue error_ret:0];
    if (statusNumber.intValue == NotificationTypeConnected) {
        //拉流
        NSLog(@"播放SD卡------5");
        [self getLiveStreamData];
        NSLog(@"AD Connect控制器内部连接开始");
    }
    
}

#pragma mark --- 摄像头密码错误处理

//摄像头拉流密码错误
- (void)passwordError:(NSNotification *)notifyData{
    
    NSString *uid = notifyData.userInfo[@"uid"];
    
    if ([uid isEqualToString:self.deviceId]) {
        //密码错误，开始弹窗
        dispatch_async_on_main_queue(^{
            self.reloadBtn.hidden = NO;
            //去除预览图片
            self.playView.layer.contents = (id)[UIImage imageNamed:@""];
            [self.loadVideoActivity stopAnimating];
            self.loadVideoActivity.hidden = YES;
            //停止拉流定时器
            [self stopStreamTimer];
            [self.passwordView show];
        });
        
    }
    
}

- (void)passwordConfirm{
    
    //没输入密码，不允许点击
    if (self.passwordView.pswTf.text.length == 0) {
        return;
    }
    
    //存储密码
    NSMutableDictionary *dict = [mUserDefaults objectForKey:StreamPassWordKey];
    
    if (!dict) {
        dict = [NSMutableDictionary dictionary];
    }else{
        dict = [NSMutableDictionary dictionaryWithDictionary:dict];
    }
    [dict setObject:self.passwordView.pswTf.text forKey:self.deviceId];
    [mUserDefaults setObject:dict forKey:StreamPassWordKey];
    [mUserDefaults synchronize];
    
    //重新拉流
    _reloadBtn.hidden = YES;
    self.loadVideoActivity.hidden = NO;
    [self.loadVideoActivity startAnimating];
    self.cameraOffBtn.hidden = YES;
    self.offlineBtn.hidden = YES;
    [self getLiveStreamData];
    [self.passwordView dismiss];
}

#pragma mark - 离开界面操作

- (void)leaveViewAction{
    if(_passwordView.superview){
        [self.passwordView dismiss];
    }
    
    //断开流连接
    [self stopConnecting];
}


-(void)stopConnecting
{
    dispatch_async(self.serailQueue, ^{
        _isStop = YES;
        //停止视频录制
        [self stopVideoRecord];
        
        //销毁播放器
        [self removGDPlayer];
        
        //停止播放音频
        [self releaseBtnSoundAudioPlayer];
        
        //停止音频播放
        if (_isAudioOn) {
            [self audioStop];
        }
        @synchronized(self){
            self.fullDuplexTalkingState = FullDuplexTalkingState_Ended;
        }
        [self.echoCanceller IoTcare_echo_destroy ];
        //        [self.g711FileHandle closeFile];

        //停止请求视频流
        [NetInstanceManager stopPlayWithUID:self.deviceId streamType:kNETPRO_STREAM_ALL];
        //停止请求音频流
        [NetInstanceManager setSpeakState:NO withUID:self.deviceId resultBlock:^(int result, int state, int cmd) {
            //
        }];
        
        //移除netAPI代理
        [self RemoveApiNetDelegate];
    });
    
}




#pragma mark - 获取摄像头开关
- (void)getCameraSwitchStatus{
    
    if( [self isWiFiDoorBell] ){
        [self checkCameraStatusOfDoorbell];
    }
    
    NSDictionary *reqData = [[[CMD_GetCameraSwitchReq alloc]init] requestCMDData];
    __weak typeof(self) weakSelf = self;
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:self.platformUID requestData:reqData timeout:10000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            CMD_GetCameraSwitchResp *cameraStatus = [CMD_GetCameraSwitchResp yy_modelWithDictionary:dict];
            if (cameraStatus.device_switch == 1) {
                _isCameraOff = NO;
            }
            else{
                _isCameraOff = YES;
                [weakSelf removePreview];
            }
        }
    }];
    
}


//移除预览
- (void)removePreview{
    dispatch_async_on_main_queue(^{
        
        //移除温度
        self.temperatureLabel.hidden = YES;
        self.temperatureImageView.hidden = YES;
        
        [self stopTemperatureTimer];
        
        self.playView.layer.contents = [UIImage imageNamed:@""];
        self.reloadBtn.hidden = YES;
        self.cameraOffBtn.hidden = NO;
        self.soundBtn.userInteractionEnabled = NO;
        
        [_soundBtn setImage:[UIImage imageNamed:@"btn_sound_disable"] forState:UIControlStateNormal];
        self.talkBtn.userInteractionEnabled = NO;
        [_talkBtn setImage:[UIImage imageNamed:@"btn_talk_disable"] forState:UIControlStateNormal];
        self.snapshotBtn.userInteractionEnabled = NO;
        [_snapshotBtn setImage:[UIImage imageNamed:@"btn_snapshot_disable"] forState:UIControlStateNormal];
        
        self.soundBtn_fullScreen.userInteractionEnabled = NO;
        self.talkBtn_fullScreen.userInteractionEnabled = NO;
        self.snapshotBtn.userInteractionEnabled = NO;
        
//        [_soundBtn_fullScreen setImage:[UIImage imageNamed:@"btn_sound_disable"] forState:UIControlStateNormal];
//        [_talkBtn_fullScreen setImage:[UIImage imageNamed:@"btn_talk_disable"] forState:UIControlStateNormal];
//        [_snapshotBtn_fullScreen setImage:[UIImage imageNamed:@"btn_snapshot_disable"] forState:UIControlStateNormal];
        
        
//        [self disappearControllView];
        [self.loadVideoActivity stopAnimating];
        //停止拉流
        [self stopConnecting];
    });
}

#pragma mark -- 添加设备在线状态通知
- (void)addDeviceStatusNotify
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDeviceStatus:)
                                                 name:kNotifyDevStatus
                                               object:nil];
}

#pragma mark - 更新设备在线状态
- (void)updateDeviceStatus:(NSNotification *)notifyData
{
    NSDictionary *recvDict = notifyData.object;
    NSString *msgType = recvDict[@"MessageType"];
    if (![msgType isEqualToString:kNotifyDevStatus])
    {
        NSLog(@"不是设备在线状态通知！");
        return;
    }
    if ([[NSNull null] isEqual:recvDict[@"Body"]]
        || [[NSNull null] isEqual:recvDict[@"Body"][@"DeviceStatus"]]
        || [[NSNull null] isEqual:recvDict[@"Body"][@"DeviceStatus"][0]]
        || [[NSNull null] isEqual:recvDict[@"Body"][@"DeviceStatus"][0][@"Status"]]
        || [[NSNull null] isEqual:recvDict[@"Body"][@"DeviceStatus"][0][@"DeviceId"]])
    {
        NSLog(@"无法提取设备在线状态！");
        return ;
    }
    GosDeviceStatus devStatus = (GosDeviceStatus)[recvDict[@"Body"][@"DeviceStatus"][0][@"Status"] integerValue];
    NSString *deviceId = recvDict[@"Body"][@"DeviceStatus"][0][@"DeviceId"];
    NSLog(@"更新设备 deviceId = %@ 在线状态：status = %d", deviceId, (int)devStatus);
    
    if ([deviceId isEqualToString:self.platformUID]) {
        if (devStatus == 1) {
            //在线
            [self updateDeviceWithOnlineStatus:YES];
        }
        else{
            //离线
            [self updateDeviceWithOnlineStatus:NO];
        }
    }
}


-(void)updateDeviceWithOnlineStatus:(BOOL)isOnline{
    
    dispatch_sync_on_main_queue(^{
        if (isOnline) {
            //在线
            if (!_isRunning) {
                self.deviceModel.Status =1;
                _isRunning = YES;
                [self initRunningStatus];
                [self configGDPlayer];
                [self setApiNetDelegate];
                NSLog(@"播放SD卡--------9");
                [self connctToDevice];
            }
        }
        else{
            //离线
            //设备不在线
            self.deviceModel.Status = 0;
            _isRunning = NO;
            [self stopConnecting];
            [self.loadVideoActivity stopAnimating];
            self.loadVideoActivity.hidden = YES;
            [self showNewStatusInfo:DPLocalizedString(@"Play_Ipc_unonline")];
            self.playView.layer.contents = (id)[UIImage imageNamed:@""];
            self.reloadBtn.hidden = YES;
            self.offlineBtn.hidden = NO;
        }
        
    });
}


#pragma mark - 温度获取

-(void)timerFire
{
    __weak typeof(self) weakSelf = self;
    
    NSDictionary *reqData = [[[CMD_GetTempAlarmReq alloc]init] requestCMDData];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        [[NetSDK sharedInstance] net_sendBypassRequestWithUID:self.platformUID  requestData:reqData timeout:15000 responseBlock:^(int result, NSDictionary *dict) {
            //温度表示类型， 0:表示摄氏温度.C， 1；表示华氏温度.F
            if(result==0){
                CMD_GetTempAlarmResp *tempAlarm = [CMD_GetTempAlarmResp yy_modelWithDictionary:dict];
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if ( tempAlarm.alarm_enale && (tempAlarm.curr_temperature_value > tempAlarm.max_alarm_value || tempAlarm.curr_temperature_value < tempAlarm.min_alarm_value)) {
                        weakSelf.temperatureImageView.image = [UIImage imageNamed:@"TemperatureUp"];
                    }
                    else{
                        weakSelf.temperatureImageView.image = [UIImage imageNamed:@"TemperatureDown@2x"];
                    }
                    
                    if (tempAlarm.temperature_type) {
                        weakSelf.temperatureLabel.text=[NSString stringWithFormat:@"%.1f°F",tempAlarm.curr_temperature_value];
                    }
                    else{
                        weakSelf.temperatureLabel.text=[NSString stringWithFormat:@"%.0f°C",tempAlarm.curr_temperature_value];
                    }
                });
            }
        }];
    });
}



-(void)startTimer
{
    if ( _temperatureTimer==nil)
    {
        __weak typeof(self) weakSelf = self;
        self.temperatureTimer = [NSTimer yyscheduledTimerWithTimeInterval:10 block:^(NSTimer * _Nonnull timer) {
            [weakSelf timerFire];
        } repeats:YES];
        [self.temperatureTimer setFireDate:[NSDate distantPast]];
        [[NSRunLoop mainRunLoop] addTimer:self.temperatureTimer forMode:NSDefaultRunLoopMode];
    }
    
}


- (void)stopValidTimers{
    if (_getBatteryLevelTimer) {
        [_getBatteryLevelTimer invalidate];
        _getBatteryLevelTimer = nil;
    }
    
    if (_getNetLinkSignalTimer) {
        [_getNetLinkSignalTimer invalidate];
        _getNetLinkSignalTimer = nil;
    }
}


- (void)stopTemperatureTimer
{
    if (_temperatureTimer) {
        [_temperatureTimer invalidate];
        _temperatureTimer = nil;
    }
}





//#pragma mark - 全屏代理
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    
    
    [UIView animateWithDuration:0.25 animations:^{
        if (UIDeviceOrientationIsLandscape(toInterfaceOrientation))
        {
            _isLandSpace = YES;
           
            [self.navigationController setNavigationBarHidden:YES animated:NO];
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
            //全屏约束
            [self.playView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.edges.equalTo(self.view);
            }];
            //            self.topView.hidden = YES;

            
            [self reLayoutNetLinkSignalImgView];

            [self hideFullScreenCtrlBtns:NO];

            if (_gdVideoPlayer) {
                [_gdVideoPlayer resizePlayViewFrame:CGRectMake(0, 0, trueScreenHeight, trueSreenWidth)];
            }

        }else{
            _isLandSpace = NO;
            [self.navigationController setNavigationBarHidden:NO animated:NO];
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
            [[UIApplication sharedApplication] setStatusBarHidden:NO];
            //半屏幕约束
            [self.playView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.view).offset(HeightForStatusBarAndNaviBar);
                make.left.right.equalTo(self.view);
                make.height.mas_equalTo(self.playView.mas_width).multipliedBy(playViewRatio);
            }];
            
            [self reLayoutNetLinkSignalImgView];

            if (_gdVideoPlayer) {
                [_gdVideoPlayer resizePlayViewFrame:CGRectMake(0, 0, trueSreenWidth, trueSreenWidth * playViewRatio)];
            }

            [self hideFullScreenCtrlBtns:YES];

        }
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
    }];
}

- (void)reLayoutNetLinkSignalImgView{
    [self.netLinkSignalImgView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.playView).offset(_isLandSpace?-23:-13);
        make.trailing.equalTo(self.playView).offset(_isLandSpace?-23:-42); //-50
        make.width.height.equalTo(@(25));
    }];
}

- (void)hideFullScreenCtrlBtns:(BOOL)hidden{
    
    self.rightBtnsContainer.hidden = hidden;
    self.topBtnsContainer.hidden = hidden;
    
    [self updateRecordingFlashViewInFullscreen:!hidden];

    if (!hidden) {
        [self resetTopCtrlBtns];
        [self configTopBtns];
    }
}

- (void)updateRecordingFlashViewInFullscreen:(BOOL)fullScreen{
    [self.recordTimeView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.playView).offset(fullScreen?-120:-30);
        make.top.equalTo(self.playView).offset(10);
        make.width.equalTo(@80);
        make.height.equalTo(@30);
    }];
    
    [self.recordTimeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.recordTimeView).offset(5);
        make.bottom.equalTo(self.recordTimeView).offset(-5);
        make.left.equalTo(self.recordTimeView).offset(5);
        make.width.equalTo(@40);
    }];
    
    [self.recordingShowView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.recordTimeLabel.mas_right).offset(0);
        make.top.equalTo(self.recordTimeView).offset(10);
        make.width.height.equalTo(@10);
    }];
}

- (void)configTopBtns{
    if (_isAudioOn) {
        //全屏声音按钮
        [_soundBtn_fullScreen setImage:[UIImage imageNamed:@"PlaySoundOnNormal_Full"] forState:UIControlStateNormal];
        [_soundBtn_fullScreen setImage:[UIImage imageNamed:@"PlaySoundOnSelected_Full"] forState:UIControlStateHighlighted];
    }
    else
    {
        //全屏声音按钮
        [_soundBtn_fullScreen setImage:[UIImage imageNamed:@"PlaySoundOffNormal_Full"] forState:UIControlStateNormal];
        [_soundBtn_fullScreen setImage:[UIImage imageNamed:@"PlaySoundOffSelected_Full"] forState:UIControlStateHighlighted];
    }
}

- (void)resetTopCtrlBtns{
    
}


#pragma mark -GDNetWork代理  获取视频数据
- (void)getVideoData:(unsigned char *)pContentBuffer
          dataLength:(int)length
           timeStamp:(int)timeStamp
              framNo:(unsigned int)framNO
           frameRate:(int)frameRate
            isIFrame:(BOOL)isIFrame
            deviceID:(NSString *)deviceId
           avChannel:(int)avChannel
{
    
//        NSLog(@"IPC 视频数据，deviceId = %@， framNO = %d， isIFrame = %d", deviceId, framNO, isIFrame);
    
    if ([self.deviceId isEqualToString:deviceId])
    {
        //            NSLog(@"IPC 单画面 视频数据，deviceId = %@， framNO = %d， isIFrame = %d", deviceId, framNO, isIFrame);
        if (isIFrame) {
            //            NSLog(@"Waiting for get IFrame %d\n",framNO);
            if (!_isLoading)
            {
                __weak typeof(self)weakSelf = self;
                //关闭拉流定时器
                [self stopStreamTimer];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"ADTest-----------------------------0");
                    self.loadVideoActivity.hidden = YES;
                    [self.loadVideoActivity stopAnimating];
                    //使能一些按钮
                    
                    [self setCtrlBtnsEnabled:YES];
                    

                    NSLog(@"ADTest-----------------------------1");
                    [self enableQualityChangeBtn];
                });
                _isLoading = YES;
            }
        }
        [_gdVideoPlayer AddVideoFrame:pContentBuffer
                                  len:length
                                   ts:timeStamp
                               framNo:framNO
                            frameRate:frameRate
                               iFrame:isIFrame
                         andDeviceUid:deviceId];
    }
    
}




/**
 * 获取对话语音的状态,如果为True,表示可以发送对讲语音解码数据了,当对讲完成后,进行解码会调用这个方法
 *
 *  @param state    表示对讲完成状态，state为YES,表示对讲语音解码成功，state,表示对讲语音解码失败
 *  @param filePath 传入对讲语音的文件
 */
-(void)SendVoiceRecoderData:(BOOL)state andFilePath:(NSString *)filePath;
{
    if (_isRunning) {
        if (state) {
            NSLog(@"SendVoiceTalk_filePath = %@",filePath);
            //子线程中发送对讲
            [NSThread detachNewThreadSelector:@selector(checkTalkStatusAndSendFile:) toTarget:self withObject:filePath];
//            dispatch_async(dispatch_get_global_queue(0, 0), ^{
//                [NetInstanceManager startSpeakThread:self.deviceId andFilePath:filePath];
//            });
            
//            [self audioInit];
            
            //            [NSThread sleepForTimeInterval:1.0];
            if (_speakFlag) {
                //                [NSThread sleepForTimeInterval:1.0];
            }
        }
    }
}

- (void)checkTalkStatusAndSendFile:(NSString *)filePath {
    while (YES) {
        switch (openTalkSuccess) {
            case -1:
                [NSThread sleepForTimeInterval:0.1];
                break;
            case 0:
                [NetInstanceManager startSpeakThread:self.deviceId andFilePath:filePath];
                return;
            case 1:
                [SVProgressHUD showErrorWithStatus:@"open talk failed"];
                return;
            default:
                [NSThread sleepForTimeInterval:0.1];
                break;
        }
    }
}

#pragma mark -语音数据
-(void)sendAudioData:(Byte *)buffer len:(int)len framNo:(unsigned int)framNO andUID:(NSString *)UID frameType:(gos_codec_type_t)frameType
{
    if (_isStop) {
        return;
    }
    [_gdVideoPlayer AddAudioFrame:buffer len:len frameType:frameType];
}

-(void)sendDataTypeState:(SendDataType)type andUID:(NSString *)UID errno_ret:(int)error_t
{
    if(error_t < 0)
    {
        if ([self.deviceId isEqualToString:UID])
        {
            if (type == VideoType) {
            }
            else if(type == AudioType){
            }
            else if(type == VideoDataTimeout){
                NSString *str =DPLocalizedString(@"network_error");
                dispatch_async_on_main_queue(^{
                    [self showNewStatusInfo:str];
                    [self.loadVideoActivity stopAnimating];
                    //                    self.previewImgView.hidden = YES;
                    self.loadVideoActivity.hidden = YES;
                });
            }
            else if(type == SpeakerSendDataFinish){
                NSString *string = [NSString stringWithFormat:@"%@", DPLocalizedString(@"Play_video")];
                dispatch_async_on_main_queue(^{
                    NSString *_recoderPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"interfacetalk_tmp.711"];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:_recoderPath]) {
                        NSError *error;
                        [[NSFileManager defaultManager] removeItemAtPath:_recoderPath error:&error];
                        if (error) {
                            NSLog(@"removeItemAtPath_error:%@",error.description);
                        }
                    }
                    
                    [self showNewStatusInfo:string];
                    
                });
                if (_gdVideoPlayer) {
                    [NetInstanceManager startAudioData:self.deviceId andBlock:^(int value, int state,int cmd) {
                    }];
                }
            }
            else if(type == AudioDrop)
            {
                //音频掉线
                _isAudioOn = NO;
                _isRunning = NO;
            }
            else if(type == VideoDrop)
            {
                //视频掉线
                _videoFlag = NO;
                _isRunning = NO;
            }
        }
    }
    else
    {
        if ([self.deviceId isEqualToString:UID])
        {
            //视频加载
            if (type == VideoBuffering) {
                _videoFlag = YES;
            }
            //音频加载
            else if(type == AudioTypeBuffering)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showNewStatusInfo:DPLocalizedString(@"audio_success")];
                });
            }
            //对讲数据发送数据结束
            else if(type == SpeakerSendDataFinish)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSString *_recoderPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"interfacetalk_tmp.711"];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:_recoderPath]) {
                        NSError *error;
                        [[NSFileManager defaultManager] removeItemAtPath:_recoderPath error:&error];
                        if (error) {
                            NSLog(@"removeItemAtPath_error:%@",error.description);
                        }
                    }
                    
                    //取消掉这个提示
                    //                    [self showNewStatusInfo:DPLocalizedString(@"Speaking_success")];
                    
                    
                });
                if (_gdVideoPlayer) {
                    [NetInstanceManager startAudioData:self.deviceId andBlock:^(int value, int state,int cmd) {
                    }];
                }
            }
        }
    }
}


#pragma mark-拍照的回调
- (void)SavePhotoImage:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSLog(@"didFinishSavingWithError");
    __block BOOL showError = (error != nil);
    dispatch_async_on_main_queue(^{
        [SVProgressHUD dismiss];
        if (showError)
        {
            [self showNewStatusInfo:DPLocalizedString(@"localizied_9")];
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"localizied_9")];
        }
        else
        {
            [self showNewStatusSuccess:DPLocalizedString(@"save_image")];
        }
    });
}


#pragma mark-保存录像到相册的回调
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    __block BOOL showError = (error != nil);
    NSLog(@"video error = %@",error);
    dispatch_async_on_main_queue(^{
        [SVProgressHUD dismiss];
        if (showError)
        {
            [self showNewStatusInfo:DPLocalizedString(@"localizied_9")];
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"localizied_9")];
        }
        else
        {
            [self showNewStatusSuccess:DPLocalizedString(@"save_video")];
        }
    });
}


-(void)showNewStatusSuccess:(NSString*)msg
{
    [SVProgressHUD showSuccessWithStatus:msg];
    [SVProgressHUD dismissWithDelay:2];
}



/**
 *  拍照返回结果,保存到自定义到路径
 *
 *  @param imagePath   返回拍照的文件路径
 *  @param error       如果拍照失败，返回错误值，否认为NULL;
 *  @param contextInfo <#contextInfo description#>
 */
- (void)image:(NSString *)imagePath
didFinishSavingWithError:(NSError *)error
  contextInfo:(void *)contextInfo{
    
    NSLog(@"didFinishSavingWithError");
    __block BOOL showError = (error != nil);
    dispatch_async_on_main_queue(^{
        [SVProgressHUD dismiss];
        if (showError)
        {
            [self showNewStatusInfo:DPLocalizedString(@"localizied_9")];
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"localizied_9")];
        }
        else
        {
            [self showNewStatusSuccess:DPLocalizedString(@"save_image")];
        }
    });
}


#pragma mark - GDNetWork对讲状态回调
-(void) SpeakerConnectState:(int)error andUID:(NSString *)UID
{
    if ([self.deviceId isEqualToString:UID])
    {
        if(error < 0)
        {
            dispatch_async_on_main_queue(^{
                [self showNewStatusInfo:DPLocalizedString(@"localizied_293")];
            });
        }
        else
        {
            dispatch_async_on_main_queue(^{
                [self showNewStatusInfo:DPLocalizedString(@"connect_success")];
            });
        }
    }
}


#pragma mark - 获取视频码率

#pragma mark - 按钮事件中心

- (void)showCameraInfoView
{
    NSLog(@"点击设备设置按钮");
    SettingViewController * setVC =[[SettingViewController alloc]init];
    setVC.model = _deviceModel;
    [self.navigationController pushViewController:setVC animated:YES];
}



- (void)navBack{
    NSLog(@"'返回’事件");
    [self removGDPlayer];



   
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.navigationController popViewControllerAnimated:YES];
    [self removeCacheFile];
    [self RemoveApiNetDelegate];
}

//清除cache文件夹中的缓存
- (void)removeCacheFile{
    NSString *extension1 = @"H264";
    NSString *extension2 = @"jpg";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];
    NSEnumerator *enumerator = [contents objectEnumerator];
    NSString *filename;
    while ((filename = [enumerator nextObject])) {
        if ([[filename pathExtension] isEqualToString:extension1] || [[filename pathExtension] isEqualToString:extension2]) {
            [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:filename] error:nil];
        }
    }
    
}


#pragma mark - 云存储方法

- (void)getCSStatus{
    
    //@{@"token" : [mUserDefaults objectForKey:USER_TOKEN],@"device_id" : self.deviceModel.DeviceId,@"username":[SaveDataModel getUserName],@"version":@"1.0" }
    //?device_id=Z99O610022H6ZJGYX6S6LV67111A&token=66e7c0fa-30d6-11e8-af4a-91c4692ab7c2&username=tanyc%40goscam.com&version=1.0
    NSString *getUrl = [NSString stringWithFormat:@"http://%@/api/cloudstore/cloudstore-service/service/data-valid?device_id=%@&token=%@&username=%@&version=1.0",kCloud_IP,self.deviceModel.DeviceId,[mUserDefaults objectForKey:USER_TOKEN],[SaveDataModel getUserName]];

//    [[CSNetworkLib sharedInstance] requestWithURLStr:getUrl method:@"GET" result:^(int result, NSData *data) {
//        //
//        if (result == 0 || result == 1204) {
//            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
//            NSArray *dataArray = dict[@"data"];
//            if ([dataArray isKindOfClass:[NSArray class]]) {
//                if (dataArray.count >0) {
//                    self.csValid = YES;
//                }
//                else{
//                    self.csValid = NO;
//                }
//            }
//            else{
//                self.csValid = NO;
//            }
//            self.requestCSStatusSuccesfully = YES;
//            [self configCSAdvertisingBtn];
//        }else{
//            self.requestCSStatusSuccesfully = NO;
//            [self configCSAdvertisingBtn];
//        }
//    }];

    [[AFHTTPSessionManager manager] GET:getUrl parameters:@{@"token" : [mUserDefaults objectForKey:USER_TOKEN],@"device_id" : self.deviceModel.DeviceId,@"username":[SaveDataModel getUserName],@"version":@"1.0" } progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //获取套餐时长数据
        NSArray *dataArray = responseObject[@"data"];
        if ([dataArray isKindOfClass:[NSArray class]]) {
            if (dataArray.count >0) {
                self.csValid = YES;
            }
            else{
                self.csValid = NO;
            }
        }
        else{
            self.csValid = NO;
        }
        self.requestCSStatusSuccesfully = YES;
        [self configCSAdvertisingBtn];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        //TODO:添加重新加载按钮
        self.requestCSStatusSuccesfully = NO;
        [self configCSAdvertisingBtn];
    }];
}

- (void)configCSAdvertisingBtn{
    
    BOOL hideCSAdvertisingBtn = self.requestCSStatusSuccesfully&&self.csValid;
    
    self.csAdvertisingBtn.hidden = hideCSAdvertisingBtn || (_deviceModel.DeviceOwner==GosDeviceShare);
    
    if (!hideCSAdvertisingBtn) {
        NSURL *reqURL = [NSURL URLWithString:@"http://www.ulifecam.com/image/img_cloud_ad.png"];
        [self.csAdvertisingBtn setBackgroundImageForState:UIControlStateNormal withURL:reqURL placeholderImage:[UIImage imageNamed:@"img_cloud_ad"] ];
    }
    
    
//    BOOL needToShowReloadTitle = !(self.requestCSStatusSuccesfully);
//    [self.csAdvertisingBtn setTitle:needToShowReloadTitle?DPLocalizedString(@"reloadBtn"):@"" forState:0];
}

- (UIButton*)csAdvertisingBtn{
    if (!_csAdvertisingBtn) {
        _csAdvertisingBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, screen_width, 92)];
        [_csAdvertisingBtn addTarget:self action:@selector(csAdvertisingBtnClicked:) forControlEvents:UIControlEventTouchUpInside];

        _csAdvertisingBtn.hidden = YES;
//        [_csAdvertisingBtn setBackgroundImage:[UIImage imageNamed:@"img_cloud_ad"] forState:UIControlStateNormal];
    }
    return _csAdvertisingBtn;
}


- (void)csAdvertisingBtnClicked:(id)sender{
    if (_requestCSStatusSuccesfully) {
        //跳到开通界面
        CSPackageTypeVC *vc = [CSPackageTypeVC new];
        vc.deviceModel                     = self.deviceModel;
        [self.navigationController pushViewController:vc animated:YES];
    }else{
        //继续请求云存储状态
        [self getCSStatus];
    }
}


#pragma mark - 工具方法
//nadate转nsstring
- (NSString *)getDateStringWithDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *dateTime = [formatter stringFromDate:date];
    return dateTime;
}


//nsstring转nadate
- (NSDate *)dateFromString:(NSString *)dateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"yyyy-MM-dd"];
    NSDate *destDate= [dateFormatter dateFromString:dateString];
    return destDate;
}




#pragma mark - 播放相关


- (NSString*)snapshotPath{
    NSString *path = [[MediaManager shareManager] mediaPathWithDevId:self.devAndSubDevID
                                                            fileName:nil
                                                           mediaType:GosMediaSnapshot
                                                          deviceType:GosDeviceIPC
                                                            position:PositionMain];
    return path;
}

-(void)showNewStatusInfo:(NSString*)info
{
    [SVProgressHUD showInfoWithStatus:info];
    [SVProgressHUD dismissWithDelay:4];
}



#pragma mark -- '录像列表’事件


#pragma mark -- '录像‘按钮事件
- (void)recordingBtnAction:(id)sender
{
    NSLog(@"'录像’事件");
    if (!self.recordingBtn.selected)
    {
        //录像
        if (!_isRunning) {
            [self showNewStatusInfo:DPLocalizedString(@"Play_camera_no_connect")];
            return;
        }
        UISettingModel *model = [[UISettingManagement sharedInstance] getSettingModel:self.platformUID];
        
        BOOL Enable = YES;
        if (!model.ability_mic)
        {
            Enable = NO;
        }
        __weak typeof(self) weakSelf = self;
        
        NSString *recordPath = [[MediaManager shareManager] mediaPathWithDevId:self.devAndSubDevID
                                                                      fileName:nil
                                                                     mediaType:GosMediaRecord
                                                                    deviceType:GosDeviceIPC
                                                                      position:PositionMain];
        _isRecordflag = [_gdVideoPlayer recordStartWithAudioEnabled:Enable
                                                       andSavePhoto:NO
                                                            andPath:recordPath // [self getPathWithVideo:YES]
                                                     andBlockRequst:^(int result, int count, NSError *error) {
                                                         if (result ==0) {
                                                             [weakSelf updateRecordViewWithCount:count];
                                                         }
                                                     }];
        
        if (_isRecordflag)
        {
            
            if (Enable && ![self isWiFiDoorBell])
            {

                
            }
            
            dispatch_async(dispatch_get_main_queue(), ^
                           {
                               self.recordTimeView.hidden=NO;
                               self.recordShowViewTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimer:) userInfo:nil repeats:YES];
                               [self updateTimer:nil];
                               //                               [self showNewStatusInfo:DPLocalizedString(@"Record_begin")];
                               [self playRecordSound];
                           });
            
            [self recordTimerStart];
        }
        else{//开启录像失败
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"RecordFailure")];
                return;
        }
        
        self.recordingBtn.selected = YES;
        [self.recordingBtn setImage:[UIImage imageNamed:@"PlayRecordSelected"] forState:UIControlStateNormal];
        [self.recordingBtn_fullScreen setImage:[UIImage imageNamed:@"PlayRecordSelected_Full"] forState:UIControlStateNormal];
    }
    else
    {
        //结束录像
        [self stopVideoRecord];
    }
}

- (void)updateRecordViewWithCount:(NSInteger)count{
    long time = count;
    long a = time % 60;
    long b = (time % 3600 - a)/60;
    long c = (time - a - b)/3600;
    NSString* str = [[NSString alloc] initWithFormat:@"%02ld:%02ld:%02ld", c, b, a];
    NSLog(@"_________________________________recordCountLabelstr:%@",str);
}

- (void)updateTimer:(NSTimer *)timer
{
    self.recordingShowView.hidden = !self.recordingShowView.hidden;
}


#pragma mark -- '声音开关‘按钮事件
- (void)soundBtnAction:(id)sender
{
    NSLog(@"'声音开关’事件");
    
    if(!_isRunning)
    {
        [self showNewStatusInfo:DPLocalizedString(@"Play_camera_no_connect")];
        return;
    }
    
//    if (_isRecordflag && ![self isWiFiDoorBell]) { //
//        [SVProgressHUD showInfoWithStatus:DPLocalizedString(@"record_no_audio")];
//    }
//    else
    {
        _isAudioOn = !_isAudioOn;
        [self enableAudio:_isAudioOn];
    }
}

- (void)enableAudio:(BOOL)enable{
    if (enable) {
        [self audioStart];
        //开启声音
        [_soundBtn setImage:[UIImage imageNamed:@"PlaySoundNormal"] forState:UIControlStateNormal];
        [_soundBtn setImage:[UIImage imageNamed:@"PlaySoundSelected"] forState:UIControlStateHighlighted];
        
        //全屏声音按钮
        [_soundBtn_fullScreen setImage:[UIImage imageNamed:@"PlaySoundOnNormal_Full"] forState:UIControlStateNormal];
        [_soundBtn_fullScreen setImage:[UIImage imageNamed:@"PlaySoundOnSelected_Full"] forState:UIControlStateHighlighted];
    }
    else
    {
        [self audioStop];
        //静音
        [_soundBtn setImage:[UIImage imageNamed:@"PlayNoSoundNormal"] forState:UIControlStateNormal];
        [_soundBtn setImage:[UIImage imageNamed:@"PlayNoSoundSelected"] forState:UIControlStateHighlighted];
        
        //全屏声音按钮
        [_soundBtn_fullScreen setImage:[UIImage imageNamed:@"PlaySoundOffNormal_Full"] forState:UIControlStateNormal];
        [_soundBtn_fullScreen setImage:[UIImage imageNamed:@"PlaySoundOffSelected_Full"] forState:UIControlStateHighlighted];
    }
}

#pragma mark -- '对讲‘按钮事件
- (void)talkTouchUpAction:(id)sender{
    if (_talkingMode == TalkingMode_HalfDuplex) {
        [self talkEndAction];
    }else{
        
        [self talkBtnAction];
    }
}

- (void)talkTouchDownAction:(id)sender{
    if (_talkingMode == TalkingMode_HalfDuplex) {
        [self talkBtnAction];
    }
}

- (void)talkBtnAction
{
    AVAudioSession *session = [AVAudioSession new];
    if ( AVAudioSessionRecordPermissionDenied == session.recordPermission) {
        NSString *bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
        NSString *tipStr = [MLocalizedString(Privacy_Microphone_Forbidden_Tip) stringByReplacingOccurrencesOfString:@"%@" withString:bundleName];
        
        [self showAlertWithTitle:MLocalizedString(Privacy_Microphone_Forbidden_Title) Msg:tipStr];
        return;
    }
    
    NSLog(@"'对讲’事件");
//    if(_isRecordflag ) //&& ![self isWiFiDoorBell]
//    {
//        [SVProgressHUD showInfoWithStatus:DPLocalizedString(@"Play_record_no")];
//        return;
//    }
    
    if (_isRunning)
    {
        if (_talkingMode == TalkingMode_HalfDuplex) {
            _isTalk = YES;
            [self talkStartAction];
        }else{
            _isTalk = !_isTalk;
            if (_isTalk) {
                hasOpenFullTalk = YES;
                [self talkStartAction];
            }else{
                [self talkEndAction];
            }
        }
    }
    else
    {
        [self showNewStatusInfo:DPLocalizedString(@"Play_camera_no_connect")];
    }
    
}

- (void)talkStartAction{
   
    // 半双工先关闭播放音频 再开启对讲 全双工先打开对讲后再调用外协库及开启音频
    if(_talkingMode == TalkingMode_HalfDuplex){
        
        _isAudioOn = NO;
        dispatch_async_on_main_queue(^{
            [self enableAudio:_isAudioOn];
        });
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            openTalkSuccess = -1;
            [NetInstanceManager setSpeakState:YES withUID:self.deviceId resultBlock:^(int result, int state, int cmd) {
                
                if (result != 0){
                    NSLog(@"开启对讲失败 : %d", result);
                    openTalkSuccess = 1;
                } else {
                    openTalkSuccess = 0;
                }
            }];
        });
        
    }else{
        _isAudioOn = YES;
        dispatch_async_on_main_queue(^{
            [self startRecordingAudioUsingEchoCancellation];
            [self enableAudio:_isAudioOn];
            [SVProgressHUD showWithStatus:DPLocalizedString(@"Login_loading")];
        });
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [NetInstanceManager setSpeakState:YES withUID:self.deviceId resultBlock:^(int result, int state, int cmd) {
                dispatch_async_on_main_queue(^{
                    [SVProgressHUD dismiss];
                });
                if (result != 0){
                    NSLog(@"开启对讲失败 : %d", result);
                }
                else {
                    NSLog(@"ll 开启对讲成功 : %d", result);
                }
            }];
        });
    }
    
    //去掉isAudioOn=1
    NSLog(@"开始对讲--1");
    
    [self playTalkSound];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (_talkingMode == TalkingMode_HalfDuplex) {
            [_gdVideoPlayer startRecord];
        }
    });
    
    dispatch_async_on_main_queue(^{
        
        if (_talkingMode == TalkingMode_HalfDuplex) {
            self.countDownView.hidden = NO;
            [self.countDownView setRemainSeconds:50];
            [self.countDownView configView];
            [self.countDownView setNeedsDisplay];
            
            [self startCountDownTimer];
            [self.view bringSubviewToFront:self.countDownView];
        }else{
            [self.view bringSubviewToFront:self.talkingView];
        }
       
        
        _talkLabel.text =  DPLocalizedString(_talkingMode==TalkingMode_FullDuplex?@"Play_Talk_Duplex_Selected": @"PlayVideo_ReleaseToSend");
        
        [self.talkBtn setImage: [UIImage imageNamed:_talkingMode==TalkingMode_FullDuplex?@"PlaySpeak_Duplex_Selected": @"PlaySpeakSelected"] forState:UIControlStateNormal];
        [self.talkBtn_fullScreen setImage:[UIImage imageNamed:_talkingMode==TalkingMode_FullDuplex?@"PlaySpeak_Duplex_Selected":@"PlaySpeakSelected_Full"] forState:UIControlStateNormal];
    });
    NSLog(@"开始对讲--2");
}

//        [self.g711FileHandle writeData:g711OutData];

//MARK: - EchoCancel
- (void)echo_outbuf:(const char *)audiobuf bufsize:(int)size{
    unsigned char *pOutBuffer;
    int outLen = 0;
    
    NSData *g711OutData = nil;
    [self.gdVideoPlayer.decoder encodePCM2G711AWithSample:8000 channel:1 inputBuf:(unsigned char *)audiobuf inputLen:size outBuf:&pOutBuffer outLen: &outLen];

    if (pOutBuffer!=NULL && outLen > 0) {
        
        g711OutData = [NSData dataWithBytes:pOutBuffer length:outLen];
        //传输数据给设备端
        dispatch_async(sendAudioDataQueue, ^{
            [NetInstanceManager sendTalkDataWithUID:self.deviceId data:g711OutData];
        });
        free(pOutBuffer);
    }
}

// AGCProcessDelegate
/* 全双工 pcm agc处理后 调用App接口播放 */
-(NSData*)agcDataWithPcmData:(NSData*)data{

    //return data;
//    if ( self.fullDuplexTalkingState == FullDuplexTalkingState_Ended ) {
//        return data;
    int dataLen = (int)data.length;
    char agcOutBuf[dataLen];
    //NSLog(@"agcDataWithPcmData____________________:%d",dataLen);
    int lRet =  [self.echoCanceller IoTcare_echo_agc:data.bytes insize:dataLen agcbuf:agcOutBuf];
    if (lRet != 0) {
        NSLog(@"IoTcare_echo_agc:%d",lRet);
    }
    
    NSData *outData = [NSData dataWithBytes:agcOutBuf length:dataLen];
    
    //    @synchronized(self) {
    //        NSLog(@"开始写入");
    //        fwrite(outData.bytes, 1, outData.length, testFp);
    //    }
    
    return outData;
}


- (NSFileHandle *)g711FileHandle{
    if (!_g711FileHandle) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.g711TalkFilePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:self.g711TalkFilePath error:nil];
        }
        bool result = [[NSFileManager defaultManager] createFileAtPath:self.g711TalkFilePath contents:nil attributes:nil];
        NSLog(@"+++++++++++++++++create g711 file at path____________________________: %d",result);
        _g711FileHandle = [NSFileHandle fileHandleForWritingAtPath:self.g711TalkFilePath];
    }
    return _g711FileHandle;
}

- (NSString *)g711TalkFilePath{
    if (!_g711TalkFilePath) {
        _g711TalkFilePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"interfacetalk_tmp.711"];
    }
    return _g711TalkFilePath;
}




- (void)startRecordingAudioUsingEchoCancellation{
    

    int lRet = [self.echoCanceller IoTcare_echo_start];
    NSLog(@"IoTcare_echo_start:%d",lRet);

    
    @synchronized(self){
        self.fullDuplexTalkingState = FullDuplexTalkingState_Talking;
    }
}

//-(void)start{
//    if (self.isstart) {
//        [NetInstanceManager setSpeakState:NO withUID:self.deviceId resultBlock:^(int result, int state, int cmd) {
//            //
//        }];
//        int ret = [self.echo IoTcare_echo_destroy];
//        if (ret != ECHO_NOERR) {
//            NSLog(@"IoTcare_echo_destroy failed:%d",ret);
//            return;
//        }
//        else{
//            NSLog(@"IoTcare_echo_destroy 成功:%d",ret);
//        }
//        self.isstart=NO;
//        self.talkingView.hidden = YES;
//        [self.view sendSubviewToBack:self.talkingView];
//        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            AVAudioSession *audioSession = [AVAudioSession sharedInstance];
//            [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
//            [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
//            [audioSession setActive:YES error:nil];
//        });
//        
//        //释放句柄
//        //        _g711FileHandle = nil;
//        
//    }else{
//        //        [self activeAudioSessionMode];
//        int ret = [self.echo IoTcare_echo_start];
//        [NetInstanceManager setSpeakState:YES withUID:self.deviceId resultBlock:^(int result, int state, int cmd) {
//            //
//        }];
//        if (ret != ECHO_NOERR) {
//            NSLog(@"IoTcare_echo_start failed:%d",ret);
//            return;
//        }
//        else{
//            NSLog(@"IoTcare_echo_start 成功:%d",ret);
//        }
//        self.talkingView.hidden = NO;
//        [self.view bringSubviewToFront:self.talkingView];
//        self.isstart=YES;
//        //        [self.g711FileHandle writeData:[NSData data]];
//    }
//}

- (void)activeAudioSessionMode
{
    NSError *error = nil;
    NSLog(@"kAudioSessionCategory_LiveAudio");
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
    [audioSession setActive:YES error:&error];
    
    NSLog(@"activeAudioSession:%@",error);
}

- (void)activeAudioSessionModeforStopSpeak
{
    NSError *error = nil;
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:&error];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
    [audioSession setActive:YES error:&error];
}


- (void)initVoiceLib{
    
    _echoCanceller = [[IoTcare_echo alloc] init];

    int lRet = [_echoCanceller IoTcare_echo_auth:@"190389c8fbf61598af0f08a025b0541d97904f29898d47d5aa226c884da419ec5f849ac725d42cb98ac26248e3702e40"];
    //验证APIKEY
    if (lRet != ECHO_NOERR) {
        NSLog(@"IoTcare_echo auth failed:%d",lRet);
    }
    
    lRet =[_echoCanceller IoTcare_echo_set_sampleRate:8000 BitsPerChannel:16 ChannelsPerFrame:1];//8K 16bit 双通道
    if (lRet != ECHO_NOERR) {
        NSLog(@"IoTcare_echo_set_sampleRate failed:%d",lRet);
    }
    _agcEnabled = false;
    lRet = [_echoCanceller IoTcare_echo_enable_agc:8000];
    if (lRet == ECHO_NOERR) {
        _agcEnabled = true;
        lRet = [_echoCanceller IoTcare_echo_config_agc:15];
    }
    else {
        NSLog(@"IoTcare_echo_enable_agc failed:%d",lRet);
    }
    
    
    lRet = [_echoCanceller IoTcare_echo_outdata_size:640];
    if (lRet != ECHO_NOERR)
        NSLog(@"InTcare_echo_outdata_size failed : %d", lRet);
    
    _echoCanceller.delegate = self;

}

- (void)startCountDownTimer{
    if (!_countDownTimer) {
        
        _repeatCount = 0;
        __weak typeof(self) weakSelf = self;
        _countDownTimer = [NSTimer yyscheduledTimerWithTimeInterval:1 block:^(NSTimer * _Nonnull timer) {
            weakSelf.repeatCount++;
            dispatch_sync_on_main_queue(^{
                [weakSelf.countDownView setNeedsDisplay];
                [weakSelf.countDownView setRemainSeconds:50-weakSelf.repeatCount];
                
                if (weakSelf.repeatCount >= 50) {
                    [weakSelf talkEndAction];
                    [weakSelf restoreTalkBtnState:NO];
                    weakSelf.countDownView.remainSeconds = 50;
                }
            });
            
        } repeats:YES];
    }
}

- (void)restoreTalkBtnState:(bool)restore{
    
    [self.talkBtn setImage: [UIImage imageNamed: restore?@"PlaySpeakSelected":@"PlaySpeakNormal"] forState:UIControlStateHighlighted];
    [self.talkBtn_fullScreen setImage:[UIImage imageNamed:restore?@"PlaySpeakSelected_Full":@"PlaySpeakNormal_Full"] forState:UIControlStateHighlighted];

}


- (void)stopCountDownTimer{
    if ([_countDownTimer isValid]) {
        [_countDownTimer invalidate];
        _countDownTimer = nil;
    }
}


- (void)talkEndAction{
    
//    if(_isRecordflag )
//    {
//        return;
//    }
    
    if (!_isTalk && _talkingMode == TalkingMode_HalfDuplex) {
        [self restoreTalkBtnState:YES];
        return;
    }
    if (_isRunning )
    {
        if (_talkingMode == TalkingMode_HalfDuplex) {
            if (_isTalk) {
                _isTalk = NO;
            }else{
                return;
            }
        }

//        //开启声音
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//
//            if (_talkingMode == TalkingMode_HalfDuplex) {
//                _isAudioOn = YES;
//                [self enableAudio:_isAudioOn];
//            }
//        });

//        [_soundBtn setImage:[UIImage imageNamed:@"PlaySoundNormal"] forState:UIControlStateNormal];
//        [_soundBtn setImage:[UIImage imageNamed:@"PlaySoundSelected"] forState:UIControlStateHighlighted];
//        
//        //全屏声音按钮
//        [_soundBtn_fullScreen setImage:[UIImage imageNamed:@"PlaySoundOnNormal_Full"] forState:UIControlStateNormal];
//        [_soundBtn_fullScreen setImage:[UIImage imageNamed:@"PlaySoundOnSelected_Full"] forState:UIControlStateHighlighted];
        
        [self.talkBtn setImage: [UIImage imageNamed:_talkingMode==TalkingMode_FullDuplex?@"PlaySpeak_Duplex_Normal":@"PlaySpeakNormal"] forState:UIControlStateNormal];
        [self.talkBtn_fullScreen setImage:[UIImage imageNamed:_talkingMode==TalkingMode_FullDuplex?@"PlaySpeak_Duplex_Normal":@"PlaySpeakNormal_Full"] forState:UIControlStateNormal];
        
        _talkLabel.text = DPLocalizedString(_talkingMode==TalkingMode_FullDuplex?@"Play_Talk_Duplex_Normal": @"PlayVideo_PressToTalk");

        [SVProgressHUD dismiss];
        self.countDownView.hidden = YES;
        [self.view sendSubviewToBack:self.talkingView];
        
        if (_talkingMode == TalkingMode_HalfDuplex) {
//            dispatch_async(dispatch_get_global_queue(0, 0), ^{
            float delayTime = 0.3;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
                [_gdVideoPlayer stopRecord];
                _isAudioOn = YES;
                dispatch_async_on_main_queue(^{
                    [self enableAudio:_isAudioOn];
                });
            });
        }else{
            @synchronized(self){
                self.fullDuplexTalkingState = FullDuplexTalkingState_Ended;
            }
            
            [self.echoCanceller IoTcare_echo_destroy];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self activeAudioSessionModeforStopSpeak];
            });
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [NetInstanceManager setSpeakState:NO withUID:self.deviceId resultBlock:^(int result, int state, int cmd) {
                    if (result != 0)
                        NSLog(@"关闭对讲失败 : %d", result);
                }];
            });
        }
    }
    else
    {
        [SVProgressHUD dismiss];
        self.countDownView.hidden = YES;
        [self.view sendSubviewToBack:self.talkingView];
        [self showNewStatusInfo:DPLocalizedString(@"Play_camera_no_connect")];
    }
    [self stopCountDownTimer];
}

#pragma mark -- '拍照‘按钮事件
- (void)snapshotBtnAction:(id)sender
{
    NSLog(@"'拍照’事件");
    
    [SVProgressHUD dismiss];
    if (_isRunning)
    {
        [self playSnapShotSound];
        NSString *snapshotPath = [[MediaManager shareManager] mediaPathWithDevId:self.devAndSubDevID
                                                                        fileName:nil
                                                                       mediaType:GosMediaSnapshot
                                                                      deviceType:GosDeviceIPC
                                                                        position:PositionMain];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [_gdVideoPlayer screenshot:YES
                               andPath:snapshotPath //[self getPathWithVideo:NO]
                        andBlockRequst:^(int result, NSError *error) {
                            
                        }];
        });
    }
    else
    {
        [self showNewStatusInfo:DPLocalizedString(@"Play_camera_no_connect")];
    }
}


#pragma mark -- '重新加载‘按钮事件
- (void)reloadBtnClick{
    _reloadBtn.hidden = YES;
    self.loadVideoActivity.hidden = NO;
    [self.loadVideoActivity startAnimating];
    self.cameraOffBtn.hidden = YES;
    self.offlineBtn.hidden = YES;
    //    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_queue_create("ReconnectQueue", DISPATCH_QUEUE_SERIAL), ^{
        [NetInstanceManager reconnect:self.deviceId andBlock:^(int result, int state, int cmd) {
            if (result != 0) {
                //                //重新拉流
                //                [weakSelf reloadStream];
                //                [weakSelf getLiveStreamData];
            }
        }];
    });
}


#pragma mark - 横竖屏切换相关
#pragma mark -- 是否允许横竖屏
-(BOOL)shouldAutorotate
{
    //对讲不能转屏幕
    if (_isTalk)
    {
        return NO;
    }
    return YES;
}

#pragma mark -- 横竖屏方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;;
}



#pragma mark - Private Methods

#pragma mark 云台控制手势添加
-(void)swipeRecognizerFor:(UIView*)view
{
    UISwipeGestureRecognizer *recognizerRight, *recognizerLeft, *recognizerUp, *recognizerDown;
    
//    recognizerRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureAction:)];
//    [recognizerRight setDirection:(UISwipeGestureRecognizerDirectionRight)];
//    [view addGestureRecognizer:recognizerRight];
//
//    recognizerLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureAction:)];
//    [recognizerLeft setDirection:(UISwipeGestureRecognizerDirectionLeft)];
//    [view addGestureRecognizer:recognizerLeft];
//
//    recognizerUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureAction:)];
//    [recognizerUp setDirection:(UISwipeGestureRecognizerDirectionDown)];
//    [view addGestureRecognizer:recognizerUp];
//
//    recognizerDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureAction:)];
//    [recognizerDown setDirection:(UISwipeGestureRecognizerDirectionUp)];
//    [view addGestureRecognizer:recognizerDown];
    
    //添加单击手势
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapClick:)];
    [view addGestureRecognizer:tapGes];
    
}


- (void)tapClick:(UIGestureRecognizer *)gesture{
    if (_isLandSpace) {
        //点击，隐藏或显示控制按钮
        
        self.rightBtnsContainer.hidden = !self.rightBtnsContainer.hidden;
        self.topBtnsContainer.hidden = !self.topBtnsContainer.hidden;
    }
    
    if (_isLandSpace || !self.cameraOffBtn.hidden) {
        return;
    }
//    [self appearControllView];
}


- (void)appearControllView{
    dispatch_async_on_main_queue(^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(disappearControllView) object:nil];
        [UIView animateWithDuration:0.2 animations:^{
            self.playControllView.hidden = NO;
            if (_isHasBabyMusic) {
                self.babyMusicBtn.hidden = NO;
            }
            [self performSelector:@selector(disappearControllView) withObject:nil afterDelay:3.0f];
        }];
    });
}


- (void)disappearControllView{
    dispatch_async_on_main_queue(^{
        [UIView animateWithDuration:0.2 animations:^{
            self.playControllView.hidden = YES;
            self.babyMusicBtn.hidden = YES;
        }];
    });
}

-(void)gestureAction:(UISwipeGestureRecognizer*)recognizer
{
    if (!_isRunning) {
        return;
    }
    
    dispatch_async(self.moveQueue, ^{
        int ret = -1;
        switch (recognizer.direction)
        {
            case UISwipeGestureRecognizerDirectionRight:
                ret = [NetInstanceManager sendCmd:CmdModel_Camera_PtzCommand_TYPE andParam:Camera_PtzCommand_TURN_TO_LEFT andUID:self.deviceId andChannel:0 andBlock:^(int result, int state, int cmd) {
                    if (result < 0) {
                        NSLog(@"右边 error = %d",ret);
                    }
                }];
                break;
            case UISwipeGestureRecognizerDirectionLeft:
                ret = [NetInstanceManager sendCmd:CmdModel_Camera_PtzCommand_TYPE andParam:Camera_PtzCommand_TURN_TO_RIGHT andUID:self.deviceId andChannel:0 andBlock:^(int result, int state, int cmd) {
                    if (result < 0) {
                        NSLog(@"左边 error = %d",ret);
                    }
                }];
                break;
            case UISwipeGestureRecognizerDirectionDown:
                ret = [NetInstanceManager sendCmd:CmdModel_Camera_PtzCommand_TYPE andParam:Camera_PtzCommand_TURN_TO_UP andUID:self.deviceId andChannel:0 andBlock:^(int result, int state, int cmd) {
                    if (result < 0) {
                        NSLog(@"下边 error = %d",ret);
                    }
                }];
                break;
            case UISwipeGestureRecognizerDirectionUp:
                ret = [NetInstanceManager sendCmd:CmdModel_Camera_PtzCommand_TYPE andParam:Camera_PtzCommand_TURN_TO_DOWN andUID:self.deviceId andChannel:0 andBlock:^(int result, int state, int cmd) {
                    if (result < 0) {
                        NSLog(@"上边 error = %d",ret);
                    }
                }];
                break;
            default:
                break;
        }
    });
}



#pragma mark - 获取实时流
-(void)getLiveStreamData
{
    
    _isStop = NO;
    
    //开始拉流计时
    [self startStreamTimer];
    
    _isLoading = NO;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [NetInstanceManager startGettingVideoDataWithUID:self.deviceId videoType:2 resultBlock:^(int result, int state) {
            
        }];
    });
}

/**
 超过五秒拉不了流，就开始重新拉流
 */
- (void)reloadStream{
    //    __weak typeof(self) weakSelf = self;
    if (!self.offlineBtn.hidden || !self.reloadBtn.hidden) {
        //离线和重新加载情况下 return
        return;
    }
    
    if (!self.deviceId) {
        [[HWLogManager manager] logMessage:@"拉流超时重连操作- uid不存在return---"];
        return;
    }
    [[HWLogManager manager] logMessage:@"拉流超时重连操作- 开始---"];
    [[HWLogManager manager] logMessage:self.deviceId];
    dispatch_async(dispatch_queue_create("ReconnectQueue", DISPATCH_QUEUE_SERIAL), ^{
        [NetInstanceManager reconnect:self.deviceId andBlock:^(int result, int state, int cmd) {
        }];
    });
    
}


-(void)startStreamTimer
{
    if ( _streamTimer ==nil)
    {
//        int repeatTimes = [self isWiFiDoorBell]? 15 : 5;
        int repeatTimes = 5;// 表示5s内，如果没能拉到流就 关闭流，重新拉流。如果再没能拉到流就显示reload的按钮，让用户自己抉择
        __weak typeof(self) weakSelf = self;
        self.streamTimer =  [NSTimer yyscheduledTimerWithTimeInterval:1 block:^(NSTimer * _Nonnull timer) {
            weakSelf.streamTime += 1;
            if (weakSelf.streamTime > repeatTimes) {
                //重新拉流
                [weakSelf stopStreamTimer];
                [weakSelf reloadStream];
            }
            
        } repeats:YES];
        [self.streamTimer setFireDate:[NSDate distantPast]];
        [[NSRunLoop mainRunLoop] addTimer:self.streamTimer forMode:NSDefaultRunLoopMode];
    }
}

- (void)stopStreamTimer
{
    _streamTime = 0;
    if (_streamTimer) {
        [_streamTimer invalidate];
        _streamTimer = nil;
    }
}


#pragma mark - 设备能力值获取设置
//0 屏蔽 NO
//1 开启 YES
-(void)getDeviceSetting:(NSString *)UID
{
    UISettingModel *model = [[UISettingManagement sharedInstance] getSettingModel:self.platformUID];
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//
//        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"获取能力集:%@",model]];
//    });
    
    if(model)
    {
        //获取设置UI
        //         [self getDevAbilityFromServer];
        [self getDeviceUI:model];
    }
    else
    {
        //从服务器获取设备参数
        [self getDevAbilityFromServer];
    }
}

-(void)getDeviceUI:(UISettingModel *)mode
{
    
    if (!mode) {
        return;
    }
    
    dispatch_async_on_main_queue(^{
        
        //设置静音按钮
//        [self setSoundBtnState:mode.ability_mic];
//
//        //设置对讲按钮
//        [self setIntercomBtnState:mode.ability_speakr];
        
        //获取温度
//        [self getDeviceTempWithModel:mode];
        
        [self getNetLinkSignalWithModel:mode];
        
        [self getDeviceBattryLevelWithModel:mode];
    });
}

//
- (void)configTalkingMode {

//    if (_talkingMode == TalkingMode_FullDuplex) {
//        [self.talkBtn setImage:[UIImage imageNamed:@"PlaySpeak_Duplex_Normal"] forState:UIControlStateNormal];
//        [self.talkBtn_fullScreen setImage:[UIImage imageNamed:@"PlaySpeak_Duplex_Normal"] forState:UIControlStateNormal];
//    }
}

- (void)getDeviceTempWithModel:(UISettingModel*)model{
    if (model.ability_temperature) {
        
        if (_isCameraOff) {
            return;
        }
        
        if (!self.temperatureTimer.valid) {
            [self startTimer];
        }
        
        self.temperatureLabel.hidden = NO;
        self.temperatureImageView.hidden = NO;
    }
    else{
        self.temperatureLabel.hidden = YES;
        self.temperatureImageView.hidden = YES;
    }
}

#pragma mark 获取电量
- (void)getDeviceBattryLevelWithModel:(UISettingModel*)model{
    if (_isCameraOff) {
        return;
    }
    
    if (model.ability_battery_level_flag) {
        
        if (!_batteryLevelImgView) {
            [self.playControllView addSubview:self.batteryLevelImgView];
            [self.batteryLevelImgView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(self.playView).offset(-15);
                make.trailing.equalTo(self.playView).offset(-15); //-21
                make.width.height.equalTo(@(20));
            }];
        }
        
        if (!_getBatteryLevelTimer) {
            _getBatteryLevelTimer = [NSTimer scheduledTimerWithTimeInterval:35 target:self selector:@selector(getBattryLevelTimerFunc:) userInfo:nil repeats:YES];
        }
        [self getBattryLevelFunc];
    }
}

- (void)getBattryLevelFunc{
    
    __weak typeof(self) weakSelf = self;
    CMD_GetBatteryLevelReq *reqCMD = [[CMD_GetBatteryLevelReq alloc] init];
    reqCMD.channel = _deviceModel.selectedSubDevInfo.ChanNum;
    NSDictionary *reqData = [reqCMD requestCMDData];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[NetSDK sharedInstance] net_sendBypassRequestWithUID:self.platformUID  requestData:reqData timeout:15000 responseBlock:^(int result, NSDictionary *dict) {
            
            if(result==0){
                __strong typeof(weakSelf) strongSelf = weakSelf;
                CMD_GetBatteryLevelResp *batteryLevelResp = [CMD_GetBatteryLevelResp yy_modelWithDictionary:dict];
                NSLog(@"当前获取的电量值：%d", batteryLevelResp.battery_level);
//                dispatch_async(dispatch_get_main_queue(), ^{
                    // TODO: 禁止出图，且提示低电量
                    if (batteryLevelResp.battery_level <= 10) {
                        [strongSelf lowBatteryAction];
                    }
                    
//                    strongSelf.batteryLevelImgView.image = [UIImage imageNamed:[NSString stringWithFormat:@"batteryLevel_%d",(batteryLevelResp.battery_level-1)/25]];
//                });
            }
        }];
    });
}

- (void)getBattryLevelTimerFunc:(NSTimer*)timer{
    [self getBattryLevelFunc];
}
- (void)lowBatteryAction {
    // 关闭重启流定时器
    [self stopStreamTimer];
    // 关闭连接
    [self stopConnecting];
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        // 停止加载动画
        [weakself.loadVideoActivity stopAnimating];
        // 隐藏加载视图
        weakself.loadVideoActivity.hidden = YES;
        // 提示
        [weakself showAlertWithMsg:DPLocalizedString(@"DB_BatteryLow_Tip")];
    });
    
}

#pragma mark 获取网关与路由器连接信号强度
- (void)getNetLinkSignalWithModel:(UISettingModel*)model{
    if (_isCameraOff) {
        return;
    }
    if (model.ability_netlink_signal_flag) {
        if (!_netLinkSignalImgView) {
            [self.playView addSubview:self.netLinkSignalImgView];
            [self.netLinkSignalImgView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(self.playView).offset(-13);
                make.trailing.equalTo(self.playView).offset(-15); //-50
                make.width.height.equalTo(@(25));
            }];
        }
        
        if (!_getNetLinkSignalTimer) {
            _getNetLinkSignalTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(getNetLinkSignalTimerFunc:) userInfo:nil repeats:YES];
        }
        [self getNetLinkSignalFunc];
    }
}

- (void)getNetLinkSignalFunc{
    __weak typeof(self) weakSelf = self;
    
    NSDictionary *reqData = [[[CMD_GetNetLinkSignalLevelReq alloc]init] requestCMDData];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[NetSDK sharedInstance] net_sendBypassRequestWithUID:self.platformUID  requestData:reqData timeout:15000 responseBlock:^(int result, NSDictionary *dict) {
            
            if(result==0){
                __strong typeof(weakSelf) strongSelf = weakSelf;
                CMD_GetNetLinkSignalLevelResp *netLinkSignalResp = [CMD_GetNetLinkSignalLevelResp yy_modelWithDictionary:dict];
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    int netlinkLevel = (netLinkSignalResp.netlink_signal)/25; //(level-1)/25
                    if (netlinkLevel<0) {
                        netlinkLevel = 0;
                    }else if (netlinkLevel>3){
                        netlinkLevel = 3;
                    }
                    strongSelf.netLinkSignalImgView.image = [UIImage imageNamed:[NSString stringWithFormat:@"netLinkSignal_%d",netlinkLevel]];
                });
            }
        }];
    });
}

- (void)getNetLinkSignalTimerFunc:(NSTimer*)timer{
    [self getNetLinkSignalFunc];
}

-(void)getDevAbilityFromServer
{
    __weak typeof(self) weakSelf = self;
    NSDictionary *reqData = [[[CMD_GetDevAbilityReq alloc]init] requestCMDData];
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:self.platformUID requestData:reqData timeout:15000 responseBlock:^(int result, NSDictionary *dict) {
        if (result ==0) {
            weakSelf.devAbilityCmd = [CMD_GetDevAbilityResp yy_modelWithDictionary:dict];
            UISettingModel *model = [[UISettingManagement sharedInstance] getSettingModel:weakSelf.platformUID];
            if([model.ability_id isEqualToString:weakSelf.platformUID])
            {
                [[UISettingManagement sharedInstance] removeSettingModel:weakSelf.platformUID];
            }
            //传入结构体进行初始化
            if (nil != weakSelf.platformUID)
            {
                UISettingModel *modelinfo =[[UISettingModel alloc]initModelWithAbilityCmd:weakSelf.devAbilityCmd UID:weakSelf.platformUID];
                //存入模型
                [[UISettingManagement sharedInstance] addSettingModel:modelinfo];
                //UI控制
                [weakSelf getDeviceUI:modelinfo];
            }
        }
    }];
}

//设置静音按钮
-(void)setSoundBtnState:(BOOL)soundSwitchBtnState
{
    if (!soundSwitchBtnState)
    {
        //不支持语音
        self.soundBtn.userInteractionEnabled=NO;
        self.soundBtn_fullScreen.userInteractionEnabled = NO;
     
        [_soundBtn setImage:[UIImage imageNamed: @"btn_sound_disable"] forState:UIControlStateNormal];
        [_soundBtn_fullScreen setImage:[UIImage imageNamed:@"btn_sound_disable"] forState:UIControlStateNormal];
    }
    else
    {
        
        if (_isCameraOff) {
            //摄像头关闭
            return;
        }
        
        //支持语音
        self.soundBtn.userInteractionEnabled=YES;
        self.soundBtn_fullScreen.userInteractionEnabled = YES;
        
        if (_isAudioOn) {
            [self.soundBtn setImage:[UIImage imageNamed:@"PlaySoundNormal"]forState:UIControlStateNormal];
            
            [self.soundBtn_fullScreen setImage:[UIImage imageNamed:@"PlaySoundOnNormal_Full"]forState:UIControlStateNormal];
        }
        else{
            [self.soundBtn setImage:[UIImage imageNamed:@"PlayNoSoundNormal"]forState:UIControlStateNormal];
            
            [self.soundBtn_fullScreen setImage:[UIImage imageNamed:@"PlaySoundOffNormal_Full"]forState:UIControlStateNormal];
        }
    }
}

//设置对讲按钮
-(void)setIntercomBtnState:(BOOL)intercomBtnState
{
    if (!intercomBtnState)
    {
        //不支持对讲
        self.talkBtn.userInteractionEnabled=NO;
        self.talkBtn_fullScreen.userInteractionEnabled = NO;
    }
    else
    {
        
        if (_isCameraOff) {
            //摄像头关闭
            return;
        }
        
        //支持对讲
//        [self enableTalkBtn];
    }
}

//设置摇杆
- (void)setJoystickState:(BOOL)joystickState{
    if (!joystickState) {
        //不支持摇杆
        self.joystickBtn.userInteractionEnabled = NO;
    }
    else{
        
        if (_isCameraOff) {
            //摄像头关闭
            return;
        }
        
        //支持摇杆
        [self enableJoyStickBtn];
    }
    
}


#pragma mark - 摇篮曲开关
- (void)babyMusicAction:(UIButton *)babyBtn{
    if (!babyBtn.selected) {
        //打开摇篮曲
        CMD_openBabyMusicReq *openReq = [[CMD_openBabyMusicReq alloc]init];
        [[NetSDK sharedInstance] net_sendBypassRequestWithUID:self.platformUID requestData:[openReq yy_modelToJSONObject] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
            if (result == 0) {
                dispatch_async_on_main_queue(^{
                    babyBtn.selected = YES;
                });
            }else{
                dispatch_async_on_main_queue(^{
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
                });
            }
        }];
    }
    else{
        //关闭摇篮曲
        CMD_closeBabyMusicReq *closeReq = [[CMD_closeBabyMusicReq alloc]init];
        [[NetSDK sharedInstance] net_sendBypassRequestWithUID:self.platformUID requestData:[closeReq yy_modelToJSONObject] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
            if (result == 0) {
                dispatch_async_on_main_queue(^{
                    babyBtn.selected = NO;
                });
            }else{
                dispatch_async_on_main_queue(^{
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
                });
            }
        }];
    }
}

#pragma mark - 切换大小码流,高清流畅
-(void)changeDisplayQuality:(NSUInteger)quality andUID:(NSString *)UID;
{
    dispatch_async(self.moveQueue,^{
        if (UID != self.deviceId){
            NSLog(@"============ 四画面 发送切换码率命令 失败啊啊啊！");
        }
        else
        {
            if (_isRunning)
            {
                if (_isRecordflag)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [SVProgressHUD showInfoWithStatus:DPLocalizedString(@"Play_record_no")];
                    });
                    return;
                }
                
                __weak typeof(self) weakSelf = self;
                NSLog(@"============ 四画面 发送切换码率命令！");
                [NetInstanceManager sendCmd:CmdModel_Camera_VIDEOQUALITY andParam: quality==0?Camera_VIDEOQUALITY_MAX:Camera_VIDEOQUALITY_HIGH andUID:UID andChannel:0 andBlock:^(int value,int state,int cmd) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //切换高清标清按钮
                        if (state >= 0) {
                            weakSelf.qualityChangeBtn.selected = !weakSelf.qualityChangeBtn.selected;
                            if (weakSelf.qualityChangeBtn.selected) {
                                weakSelf.qualityChangeLabel.text = DPLocalizedString(@"Play_SD");
                            }
                            else{
                                weakSelf.qualityChangeLabel.text = DPLocalizedString(@"Play_HD");
                            }
                        }
                        
                        _videoQualityChanged = NO;
                        [weakSelf.cmdTimeoutTimer invalidate];
                        weakSelf.cmdTimeoutTimer = nil;
                    });
                    
                }];
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Play_camera_no_connect")];
                    [self showNewStatusInfo:DPLocalizedString(@"Play_camera_no_connect")];
                });
                return;
            }
        }
    });
}

- (void)showChangeVideoQualityTimeoutMsg{
    if(!_cmdTimeoutTimer){
        _cmdTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(cmdTimeoutAction) userInfo:nil repeats:NO];
    }
}

- (void)cmdTimeoutAction{
    if (_videoQualityChanged) {
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"localizied_294")];
        _videoQualityChanged = NO;
    }
}



#pragma mark -- 播放‘拍照’音效
- (void)playSnapShotSound
{
    if (self.snapShotBtnAudioPlayer)
    {
        [self.snapShotBtnAudioPlayer prepareToPlay];
        [self.snapShotBtnAudioPlayer play];
    }
}

#pragma mark -- 播放‘录像’音效
- (void)playRecordSound
{
    if (self.recordBtnAudioPlayer)
    {
        [self.recordBtnAudioPlayer prepareToPlay];
        [self.recordBtnAudioPlayer play];
    }
}

- (void)playTalkSound
{
    if (self.talkBtnAudioPlayer)
    {
        [self.talkBtnAudioPlayer prepareToPlay];
        [self.talkBtnAudioPlayer play];
    }
}


#pragma mark -- 停止按钮音效播放器
-(void)releaseBtnSoundAudioPlayer
{
    if (self.snapShotBtnAudioPlayer)
    {
        [self.snapShotBtnAudioPlayer stop];
        self.snapShotBtnAudioPlayer = nil;
    }
    if (self.recordBtnAudioPlayer)
    {
        [self.recordBtnAudioPlayer stop];
        self.recordBtnAudioPlayer = nil;
    }
    
    if (self.talkBtnAudioPlayer) {
        [self.talkBtnAudioPlayer stop];
        self.talkBtnAudioPlayer = nil;
    }
}


#pragma mark - 摇杆按钮事件中心
#pragma mark -- ‘向上移动’按钮事件
- (void)moveUpBtnAction:(id)sender
{
    NSLog(@"‘向上移动’按钮事件");
    if (!_isRunning) {
        [self showNewStatusInfo:DPLocalizedString(@"Play_Ipc_unonline")];
        return;
    }
    int ret = -1;
    ret = [NetInstanceManager sendCmd:CmdModel_Camera_PtzCommand_TYPE andParam:Camera_PtzCommand_TURN_TO_DOWN andUID:self.deviceId andChannel:0 andBlock:^(int result, int state, int cmd) {
        if (result < 0) {
            NSLog(@"上边 error = %d",ret);
        }
    }];
}


#pragma mark -- ‘向右移动’按钮事件
- (void)moveRightBtnAction:(id)sender
{
    if (!_isRunning) {
        [self showNewStatusInfo:DPLocalizedString(@"Play_Ipc_unonline")];
        return;
    }
    int ret = -1;
    ret = [NetInstanceManager sendCmd:CmdModel_Camera_PtzCommand_TYPE andParam:Camera_PtzCommand_TURN_TO_LEFT andUID:self.deviceId andChannel:0 andBlock:^(int result, int state, int cmd) {
        if (result < 0) {
            NSLog(@"右边 error = %d",ret);
        }
    }];
}


#pragma mark -- ‘向下移动’按钮事件
- (void)moveDownBtnAction:(id)sender
{
    NSLog(@"‘向下移动’按钮事件");
    if (!_isRunning) {
        [self showNewStatusInfo:DPLocalizedString(@"Play_Ipc_unonline")];
        return;
    }
    int ret = -1;
    ret = [NetInstanceManager sendCmd:CmdModel_Camera_PtzCommand_TYPE andParam:Camera_PtzCommand_TURN_TO_UP andUID:self.deviceId andChannel:0 andBlock:^(int result, int state, int cmd) {
        if (result < 0) {
            NSLog(@"下边 error = %d",ret);
        }
    }];
}


#pragma mark -- ‘向左移动’按钮事件
- (void)moveLeftBtnAction:(id)sender
{
    NSLog(@"‘向左移动’按钮事件");
    if (!_isRunning) {
        [self showNewStatusInfo:DPLocalizedString(@"Play_Ipc_unonline")];
        return;
    }
    int ret = -1;
    ret = [NetInstanceManager sendCmd:CmdModel_Camera_PtzCommand_TYPE andParam:Camera_PtzCommand_TURN_TO_RIGHT andUID:self.deviceId andChannel:0 andBlock:^(int result, int state, int cmd) {
        if (result < 0) {
            NSLog(@"左边 error = %d",ret);
        }
    }];
}


/**
 开始播放音频
 */
-(BOOL)audioStart
{
    _isAudioOn = YES;
   
    NSLog(@"----------------开启音频--------------------");
    [self.gdVideoPlayer startVoice];
    return YES;
}

/**
 停止播放音频
 */
-(BOOL)audioStop
{
    _isAudioOn = NO;
    NSLog(@"----------------关闭音频--------------------");
    [self.gdVideoPlayer stopVoice];
    return YES;
}


#pragma mark -- 停止视频录像
-(void)stopVideoRecord
{
    if (NO == _isRecordflag)
    {
        return;
    }
    
    [self.recordBtnAudioPlayer play];
    [self.gdVideoPlayer recordStop];
    [self recordTimerStop];
    

    _isRecordflag = NO;
    dispatch_async_on_main_queue(^{
        self.recordTimeView.hidden =YES;
        [self.recordShowViewTimer  invalidate];
        self.recordShowViewTimer =nil;
        
        //设置录像按钮
        [self.recordingBtn setImage:[UIImage imageNamed:@"PlayRecordNormal"] forState:UIControlStateNormal];
        [self.recordingBtn_fullScreen setImage:[UIImage imageNamed:@"PlayRecordNormal_Full"] forState:UIControlStateNormal];
        self.recordingBtn.selected = NO;
    });
}


-(void)recordTimerStart
{
    if (_recordIconTimer) {
        [_recordIconTimer invalidate];
        _recordIconTimer = nil;
    }
    _recordIconTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(showTime) userInfo:nil repeats:YES];
    [_recordIconTimer fire];
}

-(void)recordTimerStop
{
    if (_recordIconTimer && [_recordIconTimer isValid])
    {
        [_recordIconTimer invalidate];
        _recordIconTimer = nil;
    }
}

-(void)showTime
{
    dispatch_async_on_main_queue(^{
        if (!_isRunning && _isRecordflag) {
            //关闭语音
            [self.gdVideoPlayer recordStop];
            [self recordTimerStop];
            //            [self showNewStatusInfo:DPLocalizedString(@"record_end")];
            _isRecordflag = !_isRecordflag;
        }
    });
}


#pragma mark - 后台事件处理和网络监听处理
-(void)addBackgroundRunningEvent
{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkChanged:)
                                                 name:kRealReachabilityChangedNotification
                                               object:nil];
    
    //添加设备状态通知
    [self addDeviceStatusNotify];
}

- (void)removeEnterForegroundNotifications{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}
- (void)addEnterForegroundNotifications{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}
- (void)networkChanged:(NSNotification *)notification{
    RealReachability *reachability = (RealReachability *)notification.object;
    ReachabilityStatus curStatus = [reachability currentReachabilityStatus];
    ReachabilityStatus prevStatus = [reachability previousReachabilityStatus];
    
    
    bool needToReconnect = NO;
    if (curStatus == RealStatusViaWiFi && (prevStatus ==RealStatusViaWWAN|| prevStatus==RealStatusNotReachable) ){
        needToReconnect = YES;
    }
    else if (curStatus ==RealStatusViaWWAN && (prevStatus== RealStatusViaWiFi|| prevStatus == RealStatusNotReachable) ){
        needToReconnect = YES;
    }
    if (needToReconnect) {
        //        __weak typeof(self) weakSelf = self;
        
        //重新连接
        [NetInstanceManager reconnect:self.deviceId andBlock:^(int result, int state, int cmd) {
            
        }];
    }
}

-(void)enterBackground
{
    if (_isTalk) { //停止全双工对讲
        [self talkTouchUpAction:nil];
    }

    _isStop = YES;
    //停止视频录制
    [self stopVideoRecord];
    //销毁播放器
    [self removGDPlayer];
    //停止播放音频
    [self releaseBtnSoundAudioPlayer];
    
    //设置控制按钮不可点击
    [self setCtrlBtnsEnabled: NO];

    //停止音频播放
    if (_isAudioOn) {
        [self audioStop];
    }
    //停止请求视频流
    [NetInstanceManager stopPlayWithUID:self.deviceId streamType:kNETPRO_STREAM_ALL];
    //停止请求音频流
    [NetInstanceManager setSpeakState:NO withUID:self.deviceId resultBlock:^(int result, int state, int cmd) {
        //
    }];
    //移除netAPI代理
    [self RemoveApiNetDelegate];
    
    
}

-(void)enterForeground
{
    if (self.deviceModel.Status != 1) {
        //设备不在线
        [self.loadVideoActivity stopAnimating];
        self.loadVideoActivity.hidden = YES;
        [self showNewStatusInfo:DPLocalizedString(@"Play_Ipc_unonline")];
        self.reloadBtn.hidden = YES;
        self.offlineBtn.hidden = NO;
        self.playView.layer.contents = [UIImage imageNamed:@""];
        self.cameraOffBtn.hidden = YES;
        _isRunning = NO;
        return;
    }
    
    
    //初始化运行状态
    [self initRunningStatus];
    [self setApiNetDelegate];
    [self configGDPlayer];
    NSLog(@"播放SD卡--------7");
    [self connctToDevice];
}

- (void)creatFolder{
    NSFileManager *fileManager = [[NSFileManager alloc]init];
    NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString *folderPath = [NSString stringWithFormat:@"%@/storeVideo/%@",pathDocuments,self.deviceId];
    if (![[NSFileManager defaultManager]fileExistsAtPath:folderPath]) {
        
        [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }else{
        NSLog(@"有这个文件了");
    }
}

- (NSString *)getPathWithVideo:(BOOL)isVideo{
    NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString *timeStr = [self getCurrentDate];
    NSString *createPath;
    if (isVideo) {
        createPath = [NSString stringWithFormat:@"%@/storeVideo/%@/%@.mp4",pathDocuments,self.deviceId,timeStr];
    }
    else{
        createPath = [NSString stringWithFormat:@"%@/storeVideo/%@/%@.jpg",pathDocuments,self.deviceId,timeStr];
    }
    
    return createPath;
}

#pragma mark -- 获取当前日期
- (NSString *)getCurrentDate
{
    NSDate *date =[NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *currentDate = [formatter stringFromDate:date];
    
    return currentDate;
}




#pragma mark - 按钮状态使能

- (void)setCtrlBtnsEnabled:(BOOL)enabled{
    
    [self enableSnapShotBtn:enabled];
    [self enableTalkBtn:enabled];
    [self enableSoundBtn:enabled];
    [self enableRecordingBtn:enabled];
}

- (void)enableJoyStickBtn{
    dispatch_async_on_main_queue(^{
        _joystickBtn.userInteractionEnabled = YES;
        [_joystickBtn setImage:[UIImage imageNamed:@"PlayControllerNormal"] forState:UIControlStateNormal];
        [_joystickBtn setImage:[UIImage imageNamed:@"PlayControllSelected"] forState:UIControlStateHighlighted];
    });
}

- (void)enableRecordingBtn:(BOOL)enable{
    dispatch_async_on_main_queue(^{
        _recordingBtn.userInteractionEnabled = enable;
        _recordingBtn_fullScreen.userInteractionEnabled = enable;
        
        [_recordingBtn setImage:[UIImage imageNamed: enable?@"PlayRecordNormal@2x.png":@"btn_record_disable"] forState:UIControlStateNormal];
        
        [_recordingBtn_fullScreen setImage:[UIImage imageNamed:enable?@"PlayRecordNormal_Full":@"btn_record_disable"] forState:UIControlStateNormal];
        NSLog(@"ADTest-----------------------------3");
    });
}


- (void)enableTalkBtn:(BOOL)enable{
    dispatch_async_on_main_queue(^{
        _talkBtn.userInteractionEnabled = enable;
        _talkBtn_fullScreen.userInteractionEnabled = enable;

        if (enable) {
            if (!self.gdVideoPlayer.decoder.agcDelegate) {
                self.gdVideoPlayer.decoder.full_duplex_flag = self.talkingMode==TalkingMode_FullDuplex;
                self.gdVideoPlayer.decoder.agcDelegate = self;
            }
            
            [self.talkBtn setImage: [UIImage imageNamed:_talkingMode==TalkingMode_FullDuplex?@"PlaySpeak_Duplex_Normal":@"PlaySpeakNormal"] forState:UIControlStateNormal];
            [self.talkBtn_fullScreen setImage:[UIImage imageNamed:_talkingMode==TalkingMode_FullDuplex?@"PlaySpeak_Duplex_Normal":@"PlaySpeakNormal_Full"] forState:UIControlStateNormal];
        }else{
            [_talkBtn setImage:[UIImage imageNamed: _talkingMode==TalkingMode_HalfDuplex? @"btn_talk_disable" :@"btn_talk_disable_fullDuplex"]  forState:UIControlStateNormal];
            [_talkBtn_fullScreen setImage:[UIImage imageNamed: _talkingMode==TalkingMode_HalfDuplex? @"btn_talk_disable" :@"btn_talk_disable_fullDuplex"] forState:UIControlStateNormal];
        }
    });
}

- (void)enableSoundBtn:(BOOL)enable{

    [self setSoundBtnState:enable];
}

- (void)enableSnapShotBtn:(BOOL)enable{
    dispatch_async_on_main_queue(^{
        
        _snapshotBtn.userInteractionEnabled = enable;
        _snapshotBtn_fullScreen.userInteractionEnabled = enable;

        [_snapshotBtn setImage:[UIImage imageNamed: enable ? @"PlayCameraNormal":@"btn_snapshot_disable"] forState:UIControlStateNormal];
        [_snapshotBtn setImage:[UIImage imageNamed:@"PlayCameraSelected"] forState:UIControlStateHighlighted];
        
        [_snapshotBtn_fullScreen setImage:[UIImage imageNamed:enable ? @"PlaySnapshotNormal_Full":@"btn_snapshot_disable"] forState:UIControlStateNormal];
        [_snapshotBtn_fullScreen setImage:[UIImage imageNamed:@"PlaySnapshotSelected_Full"] forState:UIControlStateHighlighted];
    });
}


- (void)enableQualityChangeBtn{
    dispatch_async_on_main_queue(^{
        _qualityChangeBtn.userInteractionEnabled = YES;
    });
    
}


#pragma mark - GDPlayer
#pragma mark -- 创建主界面 Video player
- (void)configGDPlayer
{
    if (!_gdVideoPlayer)
    {
        _gdVideoPlayer = [[GDVideoPlayer alloc]init];
        [_gdVideoPlayer initWithViewAndDelegate:self.playView
                                       Delegate:self
                                    andDeviceID:self.deviceId
                             andWithdoubleScale:YES];
        [_gdVideoPlayer.decoder initlizeAudioFrameTypeToG711];
        NSString *covertPath = [[MediaManager shareManager] mediaPathWithDevId:self.devAndSubDevID
                                                                      fileName:nil
                                                                     mediaType:GosMediaCover
                                                                    deviceType:GosDeviceIPC
                                                                      position:PositionMain];
        _gdVideoPlayer.coverPath = covertPath;
//        [self.gdVideoPlayer setPlayerView:self.playView];
    }
}


#pragma mark -- 移除主界面 Video player
- (void)removGDPlayer
{
    if (_gdVideoPlayer)
    {
        [_gdVideoPlayer stopPlay];
        _gdVideoPlayer.delegate = nil;
        _gdVideoPlayer = nil;
    }
}


#pragma mark - NetAPISet
#pragma mark -- 设置全局NetAPI代理
- (void)setApiNetDelegate
{
    NetAPISet *apiSet = [NetAPISet sharedInstance];
    apiSet.sourceDelegage = self;
    [apiSet setStreamChannel: _deviceModel.selectedSubDevInfo.ChanNum];
    
    //    apiSet.networkDelegate = self;
}


#pragma mark -- 移除全局NetAPI代理
- (void)RemoveApiNetDelegate
{
    NetAPISet *apiSet = [NetAPISet sharedInstance];
    apiSet.sourceDelegage = nil;
    [apiSet setStreamChannel: 0];

    //    apiSet.networkDelegate = nil;
}


#pragma mark - Getter && Setter

/**
 *  播放视频 View
 */
- (UIView *)playView{
    if (!_playView) {
        _playView = [[UIView alloc]init];
        _playView.backgroundColor = [UIColor blackColor];
    }
    return _playView;
}


/**
 *  播放控制 View
 */
- (UIView *)playControllView{
    if (!_playControllView) {
        _playControllView = [[UIView alloc]init];
        _playControllView.backgroundColor = [UIColor clearColor];
//        _playControllView.hidden = YES;
        _playControllView.userInteractionEnabled = NO;
    }
    return _playControllView;
}


- (UIView *)rightBtnsContainer{
    if (!_rightBtnsContainer) {
        _rightBtnsContainer = [[UIView alloc]init];
        _rightBtnsContainer.backgroundColor = [UIColor clearColor];
        _rightBtnsContainer.hidden = YES;
//        _rightBtnsContainer.userInteractionEnabled = NO;
    }
    return _rightBtnsContainer;
}


- (UIView *)topBtnsContainer{
    if (!_topBtnsContainer) {
        _topBtnsContainer = [[UIView alloc]init];
        _topBtnsContainer.backgroundColor = [UIColor clearColor];
        _topBtnsContainer.hidden = YES;
//        _topBtnsContainer.userInteractionEnabled = NO;
    }
    return _topBtnsContainer;
}


/**
 *  摇篮曲开关按钮
 */
- (UIButton *)babyMusicBtn{
    if (!_babyMusicBtn) {
//        _babyMusicBtn = [[UIButton alloc]init];
//        _babyMusicBtn.selected = NO;
//        [_babyMusicBtn addTarget:self action:@selector(babyMusicAction:) forControlEvents:UIControlEventTouchUpInside];
//        [_babyMusicBtn setImage:[UIImage imageNamed:@"btn_music_normal"] forState:UIControlStateNormal];
//        [_babyMusicBtn setImage:[UIImage imageNamed:@"btn_music_select"] forState:UIControlStateSelected];
//        [_babyMusicBtn setImage:[UIImage imageNamed:@"btn_music_press"] forState:UIControlStateHighlighted];
//        _babyMusicBtn.hidden = YES;
    }
    return _babyMusicBtn;
}



/**
 *  录像 Button
 */
- (UIButton *)recordingBtn{
    if (!_recordingBtn) {
        _recordingBtn = [[UIButton alloc]init];
        [_recordingBtn addTarget:self action:@selector(recordingBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        _recordingBtn.userInteractionEnabled = NO;
        [_recordingBtn setImage:[UIImage imageNamed:@"btn_record_disable"] forState:UIControlStateNormal];
    }
    return _recordingBtn;
}



/**
 *  录像 标题
 */
- (UILabel *)recordingLabel{
    if (!_recordingLabel) {
        _recordingLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 200, 30)];
        _recordingLabel.textAlignment = NSTextAlignmentCenter;
        _recordingLabel.font = [UIFont systemFontOfSize:14.0f];
        _recordingLabel.text = DPLocalizedString(@"play_Record");
        _recordingLabel.backgroundColor = [UIColor clearColor];
    }
    return _recordingLabel;
}


/**
 *  画面质量切换 Button
 */
- (UIButton *)qualityChangeBtn{
    if (!_qualityChangeBtn) {
//        _qualityChangeBtn = [[UIButton alloc]init];
//        [_qualityChangeBtn addTarget:self action:@selector(qualityChangeBtnAction:) forControlEvents:UIControlEventTouchUpInside];
//        [_qualityChangeBtn setImage:[UIImage imageNamed:@"PlayControllBG"] forState:UIControlStateNormal];
//        [_qualityChangeBtn setImage:[UIImage imageNamed:@"PlayControllBlackBG"] forState:UIControlStateHighlighted];
//        _qualityChangeBtn.userInteractionEnabled = NO;
    }
    return _qualityChangeBtn;
}

/**
 *  画面质量切换 Label
 */
- (UILabel *)qualityChangeLabel{
    if (!_qualityChangeLabel) {
//        _qualityChangeLabel = [[UILabel alloc]init];
//        _qualityChangeLabel.textAlignment = NSTextAlignmentCenter;
//        _qualityChangeLabel.font = [UIFont systemFontOfSize:12.0f];
//        _qualityChangeLabel.textColor = [UIColor whiteColor];
//        _qualityChangeLabel.text = DPLocalizedString(@"Play_HD");
//        _qualityChangeLabel.backgroundColor = [UIColor clearColor];
    }
    return _qualityChangeLabel;
}


- (UIImageView *)netLinkSignalImgView{
    if (!_netLinkSignalImgView) {
        _netLinkSignalImgView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 260, 25, 25)];
        _netLinkSignalImgView.image = [UIImage imageNamed:@"netLinkSignal_3"];
    }
    return _netLinkSignalImgView;
}



/**
 *  录像时间显示 View
 */
- (UIView *)recordTimeView{
    if (!_recordTimeView) {
        _recordTimeView = [[UIView alloc]init];
        _recordTimeView.backgroundColor = [UIColor clearColor];
        _recordTimeView.hidden = YES;
    }
    return _recordTimeView;
}

/**
 *  录像闪烁提示 View
 */
- (UIView *)recordingShowView{
    if (!_recordingShowView) {
        _recordingShowView = [[UIView alloc]init];
        _recordingShowView.backgroundColor = [UIColor redColor];
        _recordingShowView.layer.masksToBounds = YES;
        _recordingShowView.layer.cornerRadius = 5;
    }
    return _recordingShowView;
}


/**
 *  录像时间 Label
 */
- (UILabel *)recordTimeLabel{
    if (!_recordTimeLabel) {
        _recordTimeLabel = [[UILabel alloc]init];
        _recordTimeLabel.textColor = [UIColor redColor];
        _recordTimeLabel.font = [UIFont boldSystemFontOfSize:13];
        _recordTimeLabel.text = @"REC";
        _recordTimeLabel.textAlignment = NSTextAlignmentLeft;
        _recordTimeLabel.backgroundColor = [UIColor clearColor];
    }
    return _recordTimeLabel;
}


/**
 *  视频数据加载 Activity
 */

- (UIActivityIndicatorView *)loadVideoActivity{
    if (!_loadVideoActivity) {
        _loadVideoActivity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [_loadVideoActivity stopAnimating];
        _loadVideoActivity.hidden = YES;
    }
    return _loadVideoActivity;
}

#pragma mark - 全屏按钮初始化





/**
 *  声音开关 全屏按钮
 */
- (EnlargeClickButton *)soundBtn_fullScreen{
    if (!_soundBtn_fullScreen) {
        _soundBtn_fullScreen = [[EnlargeClickButton alloc]init];
        [_soundBtn_fullScreen addTarget:self action:@selector(soundBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_soundBtn_fullScreen setImage:[UIImage imageNamed:@"btn_sound_disable"] forState:UIControlStateNormal];
        _soundBtn_fullScreen.userInteractionEnabled = NO;
    }
    return _soundBtn_fullScreen;
}


/**
 *  录像 全屏按钮
 */
- (UIButton *)recordingBtn_fullScreen{
    if (!_recordingBtn_fullScreen) {
        _recordingBtn_fullScreen = [[UIButton alloc]init];
        [_recordingBtn_fullScreen addTarget:self action:@selector(recordingBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        _recordingBtn_fullScreen.userInteractionEnabled = YES;
        [_recordingBtn_fullScreen setImage:[UIImage imageNamed:@"btn_record_disable"] forState:UIControlStateNormal];
    }
    return _recordingBtn_fullScreen;
}

/**
 *  对讲 全屏按钮
 */
- (UIButton *)talkBtn_fullScreen{
    if (!_talkBtn_fullScreen) {
        _talkBtn_fullScreen = [[UIButton alloc]init];
        [_talkBtn_fullScreen setImage:[UIImage imageNamed: _talkingMode==TalkingMode_HalfDuplex? @"btn_talk_disable" :@"btn_talk_disable_fullDuplex"] forState:UIControlStateNormal];
        [_talkBtn_fullScreen addTarget:self action:@selector(talkTouchDownAction:) forControlEvents:UIControlEventTouchDown];
        [_talkBtn_fullScreen addTarget:self action:@selector(talkTouchUpAction:) forControlEvents:UIControlEventTouchUpOutside];
        [_talkBtn_fullScreen addTarget:self action:@selector(talkTouchUpAction:) forControlEvents:UIControlEventTouchUpInside];
        _talkBtn_fullScreen.userInteractionEnabled = NO;
    }
    return _talkBtn_fullScreen;
}


/**
 *  拍照 全屏按钮
 */

- (UIButton *)snapshotBtn_fullScreen{
    if (!_snapshotBtn_fullScreen) {
        _snapshotBtn_fullScreen = [[UIButton alloc]init];
        [_snapshotBtn_fullScreen addTarget:self action:@selector(snapshotBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_snapshotBtn_fullScreen setImage:[UIImage imageNamed:@"btn_snapshot_disable"] forState:UIControlStateNormal];
        _snapshotBtn_fullScreen.userInteractionEnabled = NO;
    }
    return _snapshotBtn_fullScreen;
}


/**
 *  底部 View
 */
- (UIView *)bottomView{
    if (!_bottomView) {
        _bottomView = [[UIView alloc]init];
        _bottomView.backgroundColor = [UIColor whiteColor];
    }
    return _bottomView;
}


/**
 *  声音开关 Button
 */
- (UIButton *)soundBtn{
    if (!_soundBtn) {
        _soundBtn = [[UIButton alloc]init];
        [_soundBtn addTarget:self action:@selector(soundBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_soundBtn setImage:[UIImage imageNamed:@"btn_sound_disable"] forState:UIControlStateNormal];
        _soundBtn.userInteractionEnabled = NO;
    }
    return _soundBtn;
}


/**
 *  对讲 Button
 */
- (UIButton *)talkBtn{
    if (!_talkBtn) {
        _talkBtn = [[UIButton alloc]init];
        [_talkBtn setImage:[UIImage imageNamed: _talkingMode==TalkingMode_HalfDuplex? @"btn_talk_disable" :@"btn_talk_disable_fullDuplex"]  forState:UIControlStateNormal];
        [_talkBtn addTarget:self action:@selector(talkTouchDownAction:) forControlEvents:UIControlEventTouchDown];
        [_talkBtn addTarget:self action:@selector(talkTouchUpAction:) forControlEvents:UIControlEventTouchUpOutside];
        [_talkBtn addTarget:self action:@selector(talkTouchUpAction:) forControlEvents:UIControlEventTouchUpInside];
        _talkBtn.userInteractionEnabled = NO;
    }
    return _talkBtn;
}

- (TalkingMode)talkingMode{
    if (!_talkingMode) {
        NSString *talkingModeStr = [mUserDefaults stringForKey:[@"TalkingMode_" stringByAppendingString:self.deviceModel.DeviceId]]?:@"FullDuplex";
        bool isFullDuplexReady = true;
        if ( (_deviceModel.devCapModel.full_duplex_flag==1 || (_deviceModel.devCapModel.full_duplex_flag==2 && [talkingModeStr isEqualToString:@"FullDuplex"]))  && isFullDuplexReady ) {
            _talkingMode = TalkingMode_FullDuplex;
        }else{
            _talkingMode = TalkingMode_HalfDuplex;
        }
    }
    //_talkingMode = TalkingMode_FullDuplex;
    return _talkingMode;
}

- (NSString*)devAndSubDevID{
    if (!_devAndSubDevID) {
        _devAndSubDevID = [_deviceId stringByAppendingString:_deviceModel.selectedSubDevInfo.SubId?:@""];
    }
    return _devAndSubDevID;
}

/**
 *  拍照 Button
 */

- (UIButton *)snapshotBtn{
    if (!_snapshotBtn) {
        _snapshotBtn = [[UIButton alloc]init];
        [_snapshotBtn addTarget:self action:@selector(snapshotBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_snapshotBtn setImage:[UIImage imageNamed:@"btn_snapshot_disable"] forState:UIControlStateNormal];
        _snapshotBtn.userInteractionEnabled = NO;
    }
    return _snapshotBtn;
}


/**
 *  声音开关 Label
 */
- (UILabel *)soundLabel{
    if (!_soundLabel) {
        _soundLabel = [[UILabel alloc]init];
        _soundLabel.font = [UIFont systemFontOfSize:14.0f];
        _soundLabel.textColor = [UIColor colorWithHexString:@"0x242421"];
        _soundLabel.text = DPLocalizedString(@"play_Sound");
        _soundLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _soundLabel;
}


/**
 *  对讲 Label
 */
- (UILabel *)talkLabel{
    if (!_talkLabel) {
        _talkLabel = [[UILabel alloc]init];
        _talkLabel.font = [UIFont systemFontOfSize:14.0f];
        _talkLabel.textColor = [UIColor colorWithHexString:@"0x242421"];
        _talkLabel.text = DPLocalizedString(_talkingMode==TalkingMode_FullDuplex?@"Play_Talk_Duplex_Normal": @"PlayVideo_PressToTalk");
        _talkLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _talkLabel;
}


/**
 *  拍照 Label
 */
- (UILabel *)snapshotLabel{
    if (!_snapshotLabel) {
        _snapshotLabel = [[UILabel alloc]init];
        _snapshotLabel.font = [UIFont systemFontOfSize:14.0f];
        _snapshotLabel.textColor = [UIColor colorWithHexString:@"0x242421"];
        _snapshotLabel.text = DPLocalizedString(@"play_Snapshot");
        _snapshotLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _snapshotLabel;
}




/**
 重新请求按钮
 */
- (UIButton *)reloadBtn{
    if (!_reloadBtn) {
        _reloadBtn = [[UIButton alloc]init];
        [_reloadBtn addTarget:self action:@selector(reloadBtnClick) forControlEvents:UIControlEventTouchUpInside];
        _reloadBtn.hidden = YES;
        //        _reloadBtn.backgroundColor = [UIColor lightGrayColor];
        [_reloadBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_reloadBtn setTitle:DPLocalizedString(@"reloadBtn") forState:UIControlStateNormal];
    }
    return _reloadBtn;
}

/**
 离线按钮
 */
- (UIButton *)offlineBtn{
    if (!_offlineBtn) {
        _offlineBtn = [[UIButton alloc]init];
        _offlineBtn.hidden = YES;
        //        _offlineBtn.backgroundColor = [UIColor lightGrayColor];
        [_offlineBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_offlineBtn setTitle: DPLocalizedString(@"Play_Ipc_unonline") forState:UIControlStateNormal];
    }
    return _offlineBtn;
}

/**
 摄像头关闭按钮
 */
- (UIButton *)cameraOffBtn{
    if (!_cameraOffBtn) {
        _cameraOffBtn = [[UIButton alloc]init];
        _cameraOffBtn.hidden = YES;
        //        _offlineBtn.backgroundColor = [UIColor lightGrayColor];
        [_cameraOffBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _cameraOffBtn.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [_cameraOffBtn setTitle:DPLocalizedString(@"Play_Video_off") forState:UIControlStateNormal];
    }
    return _cameraOffBtn;
}

/**
 对讲弹出的View
 */
- (UIImageView *)talkingView{
    if (!_talkingView) {
//        _talkingView = [[UIImageView alloc]init];
//        _talkingView.image = [UIImage imageNamed:@"PlayRecording"];
//        _talkingView.hidden = YES;
    }
    return _talkingView;
}

- (GosTalkCountDownView*)countDownView{
    if (!_countDownView) {
        _countDownView = [[GosTalkCountDownView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        _countDownView.hidden = YES;
    }
    return _countDownView;
}

- (UIImageView *)previewImgView{
    if (!_previewImgView) {
        _previewImgView = [[UIImageView alloc]init];
        _previewImgView.backgroundColor = [UIColor clearColor];
    }
    return _previewImgView;
}

-(CameraInfoManager *)cameraInfoManger
{
    if (!_cameraInfoManger) {
        _cameraInfoManger = [[CameraInfoManager alloc]init];
    }
    return _cameraInfoManger;
}


- (void)setDeviceModel:(DeviceDataModel *)deviceModel{
    _deviceModel = deviceModel;
    if (deviceModel.DeviceId.length != 15) {
        _deviceId   = [deviceModel.DeviceId substringFromIndex:8];//截取掉下标7之后的字符串
    }
    else{
        _deviceId = deviceModel.DeviceId;
    }
    _deviceName = deviceModel.DeviceName;
    _platformUID= deviceModel.DeviceId;
}


- (StreamPasswordView *)passwordView{
    if (!_passwordView) {
        _passwordView = [StreamPasswordView passwordView];
        [_passwordView.confirmBtn addTarget:self action:@selector(passwordConfirm) forControlEvents:UIControlEventTouchUpInside];
    }
    return _passwordView;
}

#pragma mark -- ‘拍照’按钮音效播放器
- (AVAudioPlayer *)snapShotBtnAudioPlayer
{
    if (!_snapShotBtnAudioPlayer)
    {
        NSString *audioFilePath = [[NSBundle mainBundle] pathForResource:@"SnapshotSound" ofType:@"wav"];
        NSURL *audioFileUrl = [NSURL fileURLWithPath:audioFilePath];
        _snapShotBtnAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileUrl error:NULL];
    }
    return _snapShotBtnAudioPlayer;
}



#pragma mark -- ‘录像’按钮音效播放器
- (AVAudioPlayer *)recordBtnAudioPlayer
{
    if (!_recordBtnAudioPlayer)
    {
        NSString *audioFilePath = [[NSBundle mainBundle] pathForResource:@"RecordSound" ofType:@"wav"];
        NSURL *audioFileUrl = [NSURL fileURLWithPath:audioFilePath];
        _recordBtnAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileUrl error:NULL];
    }
    return _recordBtnAudioPlayer;
}


- (dispatch_queue_t)moveQueue{
    if (!_moveQueue) {
        _moveQueue = dispatch_queue_create("moveQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return _moveQueue;
}


- (UIImageView *)temperatureImageView{
    if (!_temperatureImageView) {
        _temperatureImageView = [[UIImageView alloc]init];
        _temperatureImageView.hidden = YES;
        _temperatureImageView.image = [UIImage imageNamed:@"TemperatureDown@2x"];
    }
    return _temperatureImageView;
}

- (UILabel *)temperatureLabel{
    if (!_temperatureLabel) {
        _temperatureLabel = [[UILabel alloc]init];
        _temperatureLabel.font = [UIFont systemFontOfSize:8.0f];
        _temperatureLabel.textColor = [UIColor whiteColor];
        _temperatureLabel.text = @"";
        _temperatureLabel.hidden = YES;
        _temperatureLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _temperatureLabel;
}
@end
