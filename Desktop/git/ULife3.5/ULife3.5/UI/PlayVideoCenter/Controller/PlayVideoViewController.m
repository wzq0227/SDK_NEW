//
//  PlayVideoViewController.m
//  goscamapp
//
//  Created by shenyuanluo on 2017/4/27.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "PlayVideoViewController.h"
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
#import "IpcFourPlayView.h"
#import "EnlargeClickButton.h"
//#import "CloudPlayViewController.h"
#import "StreamPasswordView.h"
#import "AcousticAddGuidePairingVC.h"


#define JOYSTICK_ANIMATION_DURATION 0.25f
#define NetInstanceManager [NetAPISet sharedInstance]
#define playViewRatio (iPhone4 ? (3/4.0f):(2.0/3.0f))
//#define playViewRatio (iPhone4 ? (3/4.0f):(9/16.0f))

#define trueSreenWidth  (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))
#define trueScreenHeight (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
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


typedef void(^VideoQualityResulotBlock)(NSString *deviceId, VideoQulityType vqType);



@interface PlayVideoViewController ()   <
                                            GDVideoPlayerDelegate,
                                            GDNetworkSourceDelegate,
                                            GDNetworkStateDelegate,
                                            IpcFourPlayViewDelegate
                                        >
{
    //是否显示‘控制杆’view
    BOOL _isShowJoystickView;
    
    //是否连接上视频流
    BOOL _isRunning;
    
    //audio Flag
    BOOL _audioFlag;
    
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
    
    /************************** 四画面 **************************/
    /** 保存屏幕宽度 */
    CGFloat _screenWidth;
    
    /** 保存屏幕高度 */
    CGFloat _screenHeight;
    
    /** 四画面是否进入全屏模式 */
    BOOL _isFourViewFullScreen;
    
    /** 是否已添加设备（0 下标不用） */
    BOOL _isAddDevice[5];
    
    /** 是否连接上视频流（0 下标不用） */
    BOOL _isFourViewRunning[5];
    
    /** 是否停止视频播放（0 下标不用） */
    BOOL _isFourViewStopVideo[5];
    
    /** 是否正在loading（0 下标：主画面） */
    BOOL _isLoading[5];
    
    /** 是否高清画质（原始设置）（0 下标不用） */
    NSMutableDictionary *_originVideoQualityDict;
    
    /** 当前主画面是四画面的哪个位置 */
    PositionType _fourViewPosition;
    
    BOOL _firstRequestStreamQuality;
}


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

/** 播放控制 View */
@property (strong, nonatomic)  UIView *playControllView;

/** 摇篮曲开关按钮 */
@property (strong,nonatomic)   UIButton *babyMusicBtn;

/** 录像列表 Button */
@property (strong, nonatomic)  UIButton *recordListBtn;

/** 录像 Button */
@property (strong, nonatomic)  UIButton *recordingBtn;

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

/** 摄像头打开切换器 */
@property (nonatomic, strong) UISwitch *cameraStatusSwitcher;

/** 对讲弹出的View */
@property (nonatomic, strong) UIImageView *talkingView;

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

#pragma mark - 四画面

/** 四画面按钮 */
@property (nonatomic, strong)EnlargeClickButton *fourViewBtn;

/** IPC 四画面 */
@property (nonatomic, strong) IpcFourPlayView *fourPlayView;

/** 记录竖屏时 fourView 的 parentView */
@property (nonatomic, weak) UIView *fourPlayViewParentView;

/** 记录竖屏时 fourView 的 frame */
@property (nonatomic, assign) CGRect fourPlayViewFrame;

/** 横屏旋转切换状态 */
@property (nonatomic, assign) TransformViewState transformState;

/** IPC 四画面：左上角(top-left) 设备数据 model */
@property (nonatomic, strong) DeviceDataModel *tlDevDataModel;

/** IPC 四画面：右上角(top-right) 设备数据 model */
@property (nonatomic, strong) DeviceDataModel *trDevDataModel;

/** IPC 四画面：左下角(bottom-left) 设备数据 model */
@property (nonatomic, strong) DeviceDataModel *blDevDataModel;

/** IPC 四画面：右下角(bottom-right) 设备数据 model */
@property (nonatomic, strong) DeviceDataModel *brDevDataModel;

/** IPC 四画面：左上角(top-left) 视频播放器 */
@property (nonatomic, strong) GDVideoPlayer *tlVideoPlayer;

/** IPC 四画面：右上角(top-right) 视频播放器 */
@property (nonatomic, strong) GDVideoPlayer *trVideoPlayer;

/** IPC 四画面：左下角(bottom-left) 视频播放器 */
@property (nonatomic, strong) GDVideoPlayer *blVideoPlayer;

/** IPC 四画面：右下角(bottom-right) 视频播放器 */
@property (nonatomic, strong) GDVideoPlayer *brVideoPlayer;

@end

@implementation PlayVideoViewController

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
    
    [self updateFourViewList];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //刷新设备名称和导航条透明度
    self.navigationController.navigationBar.translucent=YES;
    for (DeviceDataModel *model in [[DeviceManagement sharedInstance] deviceListArray]) {
        if ([model.DeviceId isEqualToString:self.deviceModel.DeviceId]) {
            _deviceName = model.DeviceName;
            break;
        }
    }
    self.navigationItem.title = _deviceName;
    [self initAppearAction];
    if (self.deviceModel.Status == 1) {
        //在线
        //获取预览图片
        UIImage *preViewImg = [[VideoImageManager manager] getImageWithDeviceID:_platformUID];
        if (preViewImg) {
            _playView.layer.contents = (id)preViewImg.CGImage;
        }
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.gdVideoPlayer) {
        [self.gdVideoPlayer setPlayerView:self.playView];
    }
    [self addEnterForegroundNotifications];
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
}

- (void)dealloc
{
    [self releaseBtnSoundAudioPlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"----------- PlayVideoViewController dealloc -----------");
}


#pragma mark - 初始化设置相关
#pragma mark -- 初始化参数
- (void)initParameter
{
    _isShowJoystickView   = NO;
    _videoFlag            = NO;
    _isRunning            = NO;
    _audioFlag            = NO;
    _isRecordflag         = NO;
    _speakFlag            = NO;
    _videoQualityChanged  = NO;
    _isLandSpace          = NO;
    _isFirstIn            = NO;
    _isHasBabyMusic       = NO;
    _segmentIndex         = 0;
    _screenWidth          = SCREEN_WIDTH;
    _screenHeight         = SCREEN_HEIGHT;
    if (_screenWidth > _screenHeight)
    {
        _screenWidth      = SCREEN_HEIGHT;
        _screenHeight     = SCREEN_WIDTH;
    }
    _isFourViewFullScreen = NO;
    self.tlDevDataModel   = self.deviceModel;
    _fourViewPosition     = PositionTopLeft;
    for (int i = 0; i < 5; i++)
    {
        _isAddDevice[i] = 1 == i ? YES : NO;
        _isFourViewStopVideo[i] = NO;
        _isLoading[i] = NO;
    }
    _originVideoQualityDict = [NSMutableDictionary dictionaryWithCapacity:0];

    self.deviceTypeInDetail = [DeviceDataModel detailedDeviceTypeWithString: [self.deviceModel.DeviceId substringWithRange:NSMakeRange(3, 2)]] ;
    
    _firstRequestStreamQuality = YES;

}


#pragma mark -- 设置相关 UI
- (void)setupUI{
    //标题
    self.title = self.deviceName;
    
    //添加导航按钮
    [self configNavItem];
    
    //添加子View
//    [self.view addSubview:self.topView];
//    [self.topView addSubview:self.tipsLabel];
//    [self.topView addSubview:self.timeLabel];
    [self.view addSubview:self.playView];
    [self.view addSubview:self.playControllView];
    [self.view addSubview:self.babyMusicBtn];
    [self.playControllView addSubview:self.recordListBtn];
    [self.playControllView addSubview:self.recordingBtn];
    
    if (self.deviceTypeInDetail != GosDetailedDeviceType_T5100ZJ ) {
        [self.view addSubview:self.fourViewBtn];

        [self.playControllView addSubview:self.joystickBtn];
        [self.playControllView addSubview:self.qualityChangeBtn];
        [self.qualityChangeBtn addSubview:self.qualityChangeLabel];
    }
    
    [self.view addSubview:self.recordTimeView];
    [self.recordTimeView addSubview:self.recordingShowView];
    [self.recordTimeView addSubview:self.recordTimeLabel];
    [self.view addSubview:self.loadVideoActivity];
    [self.view addSubview:self.bottomView];
    [self.bottomView addSubview:self.soundBtn];
    [self.bottomView addSubview:self.talkBtn];
    [self.bottomView addSubview:self.snapshotBtn];
    
    [self.bottomView addSubview:self.soundLabel];
    [self.bottomView addSubview:self.talkLabel];
    [self.bottomView addSubview:self.snapshotLabel];
    
    [self.view addSubview:self.joystickView];
    [self.view addSubview:self.talkingView];

    
    [self.view addSubview:self.reloadBtn];
    [self.view addSubview:self.offlineBtn];
    [self.view addSubview:self.cameraOffBtn];
    [self.view addSubview:self.cameraStatusSwitcher];
    
    [self.view addSubview:self.temperatureLabel];
    [self.view addSubview:self.temperatureImageView];
//    [self.playView insertSubview:self.previewImgView atIndex:0];
    [self makeConstraints];
    
    CGRect fourViewFrame = CGRectMake(0, 64, _screenWidth, _screenWidth * playViewRatio);
    self.fourPlayView = [[IpcFourPlayView alloc] initWithFrame:fourViewFrame];
    self.fourPlayView.delegate = self;
    [self.view addSubview:self.fourPlayView];
    
    [self configFourViewHidden:YES];
}

#pragma mark - 设置约束
- (void)makeConstraints{
    
    //设置约束
//    [self.topView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.equalTo(self.view).mas_offset(64);
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
        make.top.equalTo(self.view).offset(64);
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
    
    [self.babyMusicBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.playView).offset(32);
        make.right.equalTo(self.playView).offset(-18);
        make.width.height.mas_equalTo(36);
    }];
    
    [self.recordListBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.playControllView);
        make.top.equalTo(self.playControllView).offset(10);
        make.height.mas_equalTo(controllBtnHW);
    }];
    
    [self.recordingBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.playControllView);
        make.top.equalTo(self.recordListBtn.mas_bottom).offset(6);
        make.height.mas_equalTo(controllBtnHW);
    }];
    
    if (self.deviceTypeInDetail != GosDetailedDeviceType_T5100ZJ) {

        [self.fourViewBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.babyMusicBtn.mas_bottom).mas_offset(20.0f);
            make.centerX.mas_equalTo(self.babyMusicBtn.mas_centerX);
            make.width.height.mas_equalTo(self.babyMusicBtn.mas_width);
        }];
        
        [self.joystickBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.playControllView);
            make.top.equalTo(self.recordingBtn.mas_bottom).offset(6);
            make.height.mas_equalTo(controllBtnHW);
        }];
        
        [self.qualityChangeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.playControllView);
            make.top.equalTo(self.joystickBtn.mas_bottom).offset(6);
            make.height.mas_equalTo(controllBtnHW);
        }];
        
        [self.qualityChangeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.qualityChangeBtn);
        }];
    }
    
    
    [self.recordTimeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.playView).offset(-30);
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
    
    CGFloat bottomHeight = (MAX(screenWidth, screenHeight) - 64.0f - 30.0f - playHeight);
    
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.playView.mas_bottom);
        //这里添加40
        make.height.mas_equalTo(bottomHeight + 40);
        make.left.right.equalTo(self.view);
    }];
    
    //计算按钮大小 默认对讲按钮是2倍声音按钮大
    CGFloat bottomBtnWH;
    bottomBtnWH = (trueSreenWidth - 32 - 64)/4.0f;
    [self.soundBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.bottomView.mas_centerY);
        make.left.equalTo(self.bottomView).offset(16);
        make.height.width.mas_equalTo(bottomBtnWH);
    }];
    
    [self.talkBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.bottomView.mas_centerY);
        make.left.equalTo(self.soundBtn.mas_right).offset(32);
        make.height.width.mas_equalTo(2 * bottomBtnWH);
    }];
    
    [self.snapshotBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.bottomView.mas_centerY);
        make.left.equalTo(self.talkBtn.mas_right).offset(32);
        make.height.width.mas_equalTo(bottomBtnWH);
    }];
    
    
    [self.soundLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.soundBtn);
        make.height.equalTo(@20);
        make.width.equalTo(@100);
        make.top.equalTo(self.soundBtn.mas_bottom).offset(5);
    }];
    
    [self.talkLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.talkBtn);
        make.height.equalTo(@20);
        make.width.equalTo(@100);
        make.top.equalTo(self.talkBtn.mas_bottom).offset(-5);
    }];
    
    [self.snapshotLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.snapshotBtn);
        make.height.equalTo(@20);
        make.width.equalTo(@100);
        make.top.equalTo(self.snapshotBtn.mas_bottom).offset(5);
    }];
    
    [self.joystickView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.height.equalTo(self.bottomView.mas_height);
        make.top.equalTo(self.view.mas_bottom);
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
    
    [self.cameraStatusSwitcher mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cameraOffBtn.mas_bottom);
        make.centerX.equalTo(self.cameraOffBtn);
        make.width.equalTo(@50);
        make.height.equalTo(@30);
    }];
    
    [self.talkingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(self.view);
        make.width.height.mas_equalTo(120);
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

#pragma mark - 门铃判断设备是否已配对
- (void)checkCameraStatusOfDoorbell{
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_async(queue, ^{
        
        CMD_GetDoorbellCameraStatusReq *req = [CMD_GetDoorbellCameraStatusReq new];
        
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


- (void)dealWithCameraStatus:(MYCAMEREA_STATUS)status{
    NSLog(@"++++++++++++++++++++++++++dealWithCameraStatus:%d",status);
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
            break;
        }
        default:
            break;
    }
}


#pragma mark - 设置导航栏按钮
-(void)configNavItem
{
    if (self.deviceTypeInDetail == GosDetailedDeviceType_T5100ZJ) {
        return;
    }
    UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    infoButton.frame = CGRectMake(0.0, 0.0, 40, 40);
    [infoButton setImage:[UIImage imageNamed:@"PlayBlackSetting"] forState:UIControlStateHighlighted];
    [infoButton setImage:[UIImage imageNamed:@"PlayWhiteSetting"] forState:UIControlStateNormal];
    [infoButton addTarget:self action:@selector(showCameraInfoView) forControlEvents:UIControlEventTouchUpInside];
    infoButton.exclusiveTouch = YES;
    UIBarButtonItem *infotemporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
    infotemporaryBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.rightBarButtonItem=infotemporaryBarButtonItem;
    
//    UIButton* backButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    backButton.frame = CGRectMake(0, 0.0, 40, 40);
//    [backButton setImage:[UIImage imageNamed:@"PlayBlackBack"] forState:UIControlStateHighlighted];
//    [backButton setImage:[UIImage imageNamed:@"PlayWhiteBack"] forState:UIControlStateNormal];
//    [backButton setImageEdgeInsets:UIEdgeInsetsMake(0, -20, 0, 0)];
//    [backButton addTarget:self action:@selector(navBack) forControlEvents:UIControlEventTouchUpInside];
//    backButton.exclusiveTouch = YES;
//    UIBarButtonItem *backtemporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
//    backtemporaryBarButtonItem.style = UIBarButtonItemStylePlain;
//    self.navigationItem.leftBarButtonItem=backtemporaryBarButtonItem;

}




//初始化音频任务
- (void)audioInit{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
}


#pragma mark - 进入界面初始化

- (void)initAppearAction{
    if (self.deviceModel.Status == 1) {
    
        //初始化运行状态
        [self initRunningStatus];

        //填充播放器
        [self configGDPlayer];

        //设置net代理
        [self setApiNetDelegate];

        //连接设备
        [self connctToDevice];

    }
    else{
        //设备不在线
        [self.loadVideoActivity stopAnimating];
        self.loadVideoActivity.hidden = YES;
//        [self showNewStatusInfo:DPLocalizedString(@"Play_Ipc_unonline")];
        self.reloadBtn.hidden = YES;
        self.offlineBtn.hidden = NO;
        self.playView.layer.contents = [UIImage imageNamed:@""];
        _isRunning = NO;
    }
    [self appearControllView];
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
    self.cameraStatusSwitcher.hidden = YES;
    
    [self.loadVideoActivity startAnimating];
    self.loadVideoActivity.hidden = NO;
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
        [self getLiveStreamData];
    }
    else{
        //主动添加设备
        [[NetAPISet sharedInstance] addClient:self.deviceId andpassword:self.deviceModel.StreamPassword];
        
//        BOOL isConnecting = [NetInstanceManager isDeviceConnectingWithUID:self.deviceId];
//        if (!isConnecting) {
//            //主动添加设备
//            [[NetAPISet sharedInstance] addClient:self.deviceId andpassword:self.deviceModel.StreamPassword];
//        }
//        else{
//            //否则等待通知
//        }
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
///**
// *  开始绑定连接时返回的消息类型
// *
// *  @param UID       UID
// *  @param type      返回连接的状态
// *  @param error_ret error_ret< 0：连接失败,error_ret >=0:连接成功
// */
//-(void)ConnectState:(NSString *)UID stateFlag:(NotificationType)type error_ret:(int)error_ret{
//    
//    if (![UID isEqualToString:self.deviceId]) {
//        return;
//    }
//    
//    if (type == NotificationTypeRunning) {
//        return;
//    }
//    [self showConnectStateWithUID:UID state:(int)type error_ret:(int)error_ret];
//    //获取流数据
//    if (error_ret >= 0 && type == NotificationTypeConnected) {
//        //连接成功
//        [self getLiveStreamData];
//    }
//}

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
    [self.passwordView dismiss];
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
        if (_audioFlag) {
            [self audioStop];
        }
        //停止请求视频流
        [NetInstanceManager stopPlayWithUID:self.deviceId streamType:kNETPRO_STREAM_REC];
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
    if( self.deviceTypeInDetail == GosDetailedDeviceType_T5100ZJ){
        [self checkCameraStatusOfDoorbell];
    }
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
        self.cameraStatusSwitcher.hidden = NO;
        
        self.soundBtn.userInteractionEnabled = NO;
        [_soundBtn setImage:[UIImage imageNamed:@"btn_sound_disable"] forState:UIControlStateNormal];
        self.talkBtn.userInteractionEnabled = NO;
        [_talkBtn setImage:[UIImage imageNamed:@"btn_talk_disable"] forState:UIControlStateNormal];
        self.snapshotBtn.userInteractionEnabled = NO;
        [_snapshotBtn setImage:[UIImage imageNamed:@"btn_snapshot_disable"] forState:UIControlStateNormal];
        [self disappearControllView];
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





#pragma mark - 全屏代理
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    

    
    [UIView animateWithDuration:0.25 animations:^{
        if (UIDeviceOrientationIsLandscape(toInterfaceOrientation))
        {
            _isLandSpace = YES;
//            if (_talkingView.hidden==NO) {
            

//            }
            [self.navigationController setNavigationBarHidden:YES animated:NO];
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
            //全屏约束
            [self.playView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.edges.equalTo(self.view);
            }];
//            self.topView.hidden = YES;
            [self disappearControllView];
            _talkingView.hidden=YES;
            [self talkEndAction];
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
                make.top.equalTo(self.view).offset(64);
                make.left.right.equalTo(self.view);
                make.height.mas_equalTo(self.playView.mas_width).multipliedBy(playViewRatio);
            }];
            
      
//            self.topView.hidden = NO;
            [self appearControllView];
            
            if (_gdVideoPlayer) {
                [_gdVideoPlayer resizePlayViewFrame:CGRectMake(0, 0, trueSreenWidth, trueSreenWidth * playViewRatio)];
            }
        }
        
        [self.view layoutIfNeeded];

    } completion:^(BOOL finished) {
    }];
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
//    NSLog(@"IPC 视频数据，deviceId = %@， framNO = %d， isIFrame = %d", deviceId, framNO, isIFrame);
    if (NO == _isFourViewFullScreen)
    {
        if ([self.deviceId isEqualToString:deviceId])
        {
//            NSLog(@"IPC 单画面 视频数据，deviceId = %@， framNO = %d， isIFrame = %d", deviceId, framNO, isIFrame);
            if (isIFrame) {
                //            NSLog(@"Waiting for get IFrame %d\n",framNO);
                if (!_isLoading[PositionMain])
                {
                    __weak typeof(self)weakSelf = self;
                    //关闭拉流定时器
                    [self stopStreamTimer];
                    //获取视频码流
                    [weakSelf getVideoQuality:weakSelf.deviceId];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"ADTest-----------------------------0");
                        self.loadVideoActivity.hidden = YES;
                        [self.loadVideoActivity stopAnimating];
                        //使能一些按钮
                        [self enableSnapShotBtn];
                        NSLog(@"ADTest-----------------------------1");
//                        [self enableRecordListBtn];
                        [self enableRecordingBtn];
                        [self enableQualityChangeBtn];
                    });
                    _isLoading[PositionMain] = YES;
                }
            }
            if (_isStop) {
                return;
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
    else
    {
        if ([deviceId isEqualToString:[self.tlDevDataModel.DeviceId substringFromIndex:8]])
        {
            NSLog(@"IPC Top-Left 视频数据，deviceId = %@， framNO = %d， isIFrame = %d", deviceId, framNO, isIFrame);
            if (YES == isIFrame && NO == _isLoading[PositionTopLeft])
            {
                if (VideoQulity_SD != [[_originVideoQualityDict objectForKey:deviceId] integerValue])
                {
                    NSLog(@"============ 四画面切换后 Top-Left  视频数据不是标清，切换为标清");
                    [self autoChangVideoQuality:VideoQulity_SD
                                       deviceId:deviceId];
                }
                
                [self.fourPlayView stopActivityOnPosition:PositionTopLeft];
                
                _isLoading[PositionTopLeft] = YES;
            }
            if (YES == _isFourViewStopVideo[PositionTopLeft])
            {
                return;
            }
            [self.tlVideoPlayer AddVideoFrame:pContentBuffer
                                          len:length
                                           ts:timeStamp
                                       framNo:framNO
                                    frameRate:frameRate
                                       iFrame:isIFrame
                                 andDeviceUid:deviceId];
        }
        else if ([deviceId isEqualToString:[self.trDevDataModel.DeviceId substringFromIndex:8]])
        {
            NSLog(@"IPC Top-Right 视频数据，deviceId = %@， framNO = %d， isIFrame = %d", deviceId, framNO, isIFrame);
            if (YES == isIFrame && NO == _isLoading[PositionTopRight])
            {
                if (VideoQulity_SD != [[_originVideoQualityDict objectForKey:deviceId] integerValue])
                {
                    NSLog(@"============ 四画面切换后 Top-Right  视频数据不是标清，切换为标清");
                    [self autoChangVideoQuality:VideoQulity_SD
                                       deviceId:deviceId];
                }
                
                [self.fourPlayView stopActivityOnPosition:PositionTopRight];
                
                _isLoading[PositionTopRight] = YES;
            }
            if (YES == _isFourViewStopVideo[PositionTopRight])
            {
                return;
            }
            [self.trVideoPlayer AddVideoFrame:pContentBuffer
                                          len:length
                                           ts:timeStamp
                                       framNo:framNO
                                    frameRate:frameRate
                                       iFrame:isIFrame
                                 andDeviceUid:deviceId];
        }
        else if ([deviceId isEqualToString:[self.blDevDataModel.DeviceId substringFromIndex:8]])
        {
            NSLog(@"IPC Bottom-Left 视频数据，deviceId = %@， framNO = %d， isIFrame = %d", deviceId, framNO, isIFrame);
            if (YES == isIFrame && NO == _isLoading[PositionBottomLeft])
            {
                if (VideoQulity_SD != [[_originVideoQualityDict objectForKey:deviceId] integerValue])
                {
                    NSLog(@"============ 四画面切换后 Bottom-Left  视频数据不是标清，切换为标清");
                    [self autoChangVideoQuality:VideoQulity_SD
                                       deviceId:deviceId];
                }
                
                [self.fourPlayView stopActivityOnPosition:PositionBottomLeft];
                
                _isLoading[PositionBottomLeft] = YES;
            }
            if (YES == _isFourViewStopVideo[PositionBottomLeft])
            {
                return;
            }
            [self.blVideoPlayer AddVideoFrame:pContentBuffer
                                          len:length
                                           ts:timeStamp
                                       framNo:framNO
                                    frameRate:frameRate
                                       iFrame:isIFrame
                                 andDeviceUid:deviceId];
        }
        else if ([deviceId isEqualToString:[self.brDevDataModel.DeviceId substringFromIndex:8]])
        {
            NSLog(@"IPC Bottom-Right 视频数据，deviceId = %@， framNO = %d， isIFrame = %d", deviceId, framNO, isIFrame);
            if (YES == isIFrame && NO == _isLoading[PositionBottomRight])
            {
                if (VideoQulity_SD != [[_originVideoQualityDict objectForKey:deviceId] integerValue])
                {
                    NSLog(@"============ 四画面切换后 Bottom-Right  视频数据不是标清，切换为标清");
                    [self autoChangVideoQuality:VideoQulity_SD
                                       deviceId:deviceId];
                }
                
                [self.fourPlayView stopActivityOnPosition:PositionBottomRight];
                
                _isLoading[PositionBottomRight] = YES;
            }
            if (YES == _isFourViewStopVideo[PositionBottomRight])
            {
                return;
            }
            [self.brVideoPlayer AddVideoFrame:pContentBuffer
                                          len:length
                                           ts:timeStamp
                                       framNo:framNO
                                    frameRate:frameRate
                                       iFrame:isIFrame
                                 andDeviceUid:deviceId];
        }
        else
        {
            NSLog(@"IPC 其他 视频数据，deviceId = %@， framNO = %d， isIFrame = %d", deviceId, framNO, isIFrame);
        }
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
            [NetInstanceManager startSpeakThread:self.deviceId andFilePath:filePath];
            [self audioInit];
//            [NSThread sleepForTimeInterval:1.0];
            if (_speakFlag) {
//                [NSThread sleepForTimeInterval:1.0];
            }
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
                NSString *string = [NSString stringWithFormat:@"%@,len = %d",DPLocalizedString(@"Play_video"),error_t];
                dispatch_async_on_main_queue(^{
                    NSString *_recoderPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"interfacetalk_tmp.711"];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:_recoderPath]) {
                        NSError *error;
                        [[NSFileManager defaultManager] removeItemAtPath:_recoderPath error:&error];
                        if (error) {
                            NSLog(@"removeItemAtPath_error:%@",error.description);
                        }
                    }
                    
//                    [self showNewStatusInfo:string];
                    [_gdVideoPlayer startVoice];
                });
                _audioFlag = YES;
                if (_gdVideoPlayer) {
                    [NetInstanceManager startAudioData:self.deviceId andBlock:^(int value, int state,int cmd) {
                    }];
                }
            }
            else if(type == AudioDrop)
            {
                //音频掉线
                _audioFlag = NO;
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
                    [_gdVideoPlayer startVoice];
                });
                _audioFlag = YES;
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
            [self showNewStatusInfo:DPLocalizedString(@"save_image")];
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
//            [self showNewStatusInfo:DPLocalizedString(@"save_video")];
        }
    });
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
            [self showNewStatusInfo:DPLocalizedString(@"save_image")];
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
-(void)getVideoQuality:(NSString *)UID
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [NetInstanceManager getVideoQuality:UID andBlock:^(int result, int state, int cmd)
         {
             __strong typeof(weakSelf) strongSelf = weakSelf;
             if (state == 0 )
             {
                 NSLog(@"============ 四画面切换，获取单画面码率：%d", cmd);
                 if (strongSelf->_firstRequestStreamQuality) {
                     if ([UID isEqualToString:strongSelf.deviceId]) {
                         [strongSelf->_originVideoQualityDict setObject:@(cmd)
                                                                 forKey:strongSelf.deviceId];
                     }
                     strongSelf->_firstRequestStreamQuality = NO;
                 }
                 
                 // 四画面切换后变回来原来的码率
                 if (cmd != [[strongSelf->_originVideoQualityDict objectForKey:UID] integerValue])
                 {
                     NSLog(@"============ 四画面切换后变回来原来的码率");
                     [strongSelf changeDisplayQuality:[[strongSelf->_originVideoQualityDict objectForKey:UID] integerValue]
                                               andUID:UID];
                 }
                 if ([UID isEqualToString:weakSelf.deviceId])
                 {
                     strongSelf -> _segmentIndex = cmd;
                     dispatch_async(dispatch_get_main_queue(), ^{
                         if (strongSelf -> _segmentIndex == 0) {
                             //切换显示高清
                             strongSelf.qualityChangeBtn.selected = NO;
                             strongSelf.qualityChangeLabel.text = DPLocalizedString(@"Play_HD");
                         }
                         else if(strongSelf -> _segmentIndex== 1){
                             //切换显示标清
                             strongSelf.qualityChangeBtn.selected = YES;
                             strongSelf.qualityChangeLabel.text = DPLocalizedString(@"Play_SD");
                         }
                     });
                 }
                 else
                 {
                     if (cmd == 0) {
                         [strongSelf changeDisplayQuality:1 andUID:UID];
                     }
                 }
             }
         }];
    });
}


#pragma mark -- 获取设备视频码率
- (void)queryDeviceId:(NSString *)deviceId
   VideoQualityResult:(VideoQualityResulotBlock)resultBlock
{
    if (IS_STRING_EMPTY(deviceId))
    {
        return;
    }
    [NetInstanceManager getVideoQuality:deviceId
                               andBlock:^(int result, int state, int cmd) {
                                 
                                   if (!resultBlock)
                                   {
                                       return;
                                   }
                                   resultBlock(deviceId, cmd);
                               }];
}


/**
  获取系统时间
 */
-(double)GetSystemtime
{
    NSTimeInterval time=[[NSDate date] timeIntervalSince1970]*1000;
    double value =time;      //NSTimeInterval返回的是double类型
    return value;
}




#pragma mark - 控制杆显示隐藏事件
- (void)showJoystickView:(BOOL)isShow
{
    if (!isShow)   // 隐藏
    {
        [self.joystickView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.view);
            make.right.equalTo(self.view);
            make.height.equalTo(self.bottomView.mas_height);
            make.top.equalTo(self.view.mas_bottom);
        }];
        // 更新约束
        [UIView animateWithDuration:JOYSTICK_ANIMATION_DURATION
                         animations:^{
                             [self.view layoutIfNeeded];
                         }];
    }
    else    // 显示
    {
        [self.joystickView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.view);
            make.right.equalTo(self.view);
            make.height.equalTo(self.bottomView.mas_height);
            make.top.equalTo(self.playView.mas_bottom);
        }];
        
        // 更新约束
        [UIView animateWithDuration:JOYSTICK_ANIMATION_DURATION
                         animations:^{
                             [self.view layoutIfNeeded];
                         }];
    }
}


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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NetInstanceManager setSpeakState:NO withUID:self.deviceId resultBlock:^(int result, int state, int cmd) {
            //
        }];
    });
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark -- '录像列表’事件

- (void)recordListBtnAction:(id)sender
{
    NSLog(@"'录像列表’事件");
//    if (isCloudServiceReady) {
//        CloudPlayViewController *cloudVC = [[CloudPlayViewController alloc]init];
//        cloudVC.deviceId = self.deviceModel.DeviceId;
//        [self.navigationController pushViewController:cloudVC animated:YES];
//    }
//    else{
        RecordDateListViewController *recordDateListVC = [[RecordDateListViewController alloc] init];
        recordDateListVC.model    = _deviceModel;
        [self.navigationController pushViewController:recordDateListVC animated:YES];
//    }
}


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
        self.recordingBtn.selected = YES;
        [self.recordingBtn setImage:[UIImage imageNamed:@"PlayRecordSelected"] forState:UIControlStateNormal];
        NSString *recordPath = [[MediaManager shareManager] mediaPathWithDevId:[self.deviceModel.DeviceId substringFromIndex:8]
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
      
            if (Enable && self.deviceTypeInDetail!=GosDetailedDeviceType_T5100ZJ)
            {
                if (_audioFlag == NO)
                {
                    _speakFlag = NO;
                    [self audioStart];
//                    [NSThread sleepForTimeInterval:1.0];
                    //开启声音
                    [_soundBtn setImage:[UIImage imageNamed:@"PlaySoundNormal"] forState:UIControlStateNormal];
                    [_soundBtn setImage:[UIImage imageNamed:@"PlaySoundSelected"] forState:UIControlStateHighlighted];
                }
                else
                {
                    _speakFlag = YES;
                }
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

#pragma mark -- '云台控制’按钮事件
- (void)joystickBtnAction:(id)sender
{
    NSLog(@"'云台控制’事件");
    _isShowJoystickView = !_isShowJoystickView;
    [self showJoystickView:_isShowJoystickView];
}


#pragma mark -- '画面质量切换‘按钮事件
- (void)qualityChangeBtnAction:(id)sender
{
    NSLog(@"'画面质量切换’事件");
    //如果正在切换 return
    if (_videoQualityChanged) {
        return;
    }
    _videoQualityChanged = YES;
    
    //创建超时定时器
    [self showChangeVideoQualityTimeoutMsg];
    if (self.qualityChangeBtn.selected)
    {
        //切换高清
        [self changeDisplayQuality:0 andUID:self.deviceId];
        [_originVideoQualityDict setObject:[NSNumber numberWithInteger:VideoQulity_HD]
                                    forKey:self.deviceId];
    }
    else
    {
        //切换标清
        [self changeDisplayQuality:1 andUID:self.deviceId];
        [_originVideoQualityDict setObject:[NSNumber numberWithInteger:VideoQulity_SD]
                                    forKey:self.deviceId];
    }
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
    
    if (_isRecordflag && self.deviceTypeInDetail!=GosDetailedDeviceType_T5100ZJ) { //
        [SVProgressHUD showInfoWithStatus:DPLocalizedString(@"record_no_audio")];
    }
    else{
        _audioFlag = !_audioFlag;
        if (_audioFlag) {
            [self audioStart];
            //开启声音
            [_soundBtn setImage:[UIImage imageNamed:@"PlaySoundNormal"] forState:UIControlStateNormal];
            [_soundBtn setImage:[UIImage imageNamed:@"PlaySoundSelected"] forState:UIControlStateHighlighted];
        }
        else
        {
            [self audioStop];
            //静音
            [_soundBtn setImage:[UIImage imageNamed:@"PlayNoSoundNormal"] forState:UIControlStateNormal];
            [_soundBtn setImage:[UIImage imageNamed:@"PlayNoSoundSelected"] forState:UIControlStateHighlighted];
        }
    }
}


#pragma mark -- '对讲‘按钮事件
- (void)talkBtnAction:(id)sender
{
    NSLog(@"'对讲’事件");
    if(_isRecordflag ) //&& self.deviceTypeInDetail!=GosDetailedDeviceType_T5100ZJ
    {
        [SVProgressHUD showInfoWithStatus:DPLocalizedString(@"Play_record_no")];
        return;
    }
    
    _isTalk = YES;
    
    if (_isRunning)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [NetInstanceManager setSpeakState:YES withUID:self.deviceId resultBlock:^(int result, int state, int cmd) {
                //
            }];
        });
        
        if (_audioFlag) {
            [self audioStop];
            _speakFlag = YES;
//            [NSThread sleepForTimeInterval:1.0];
        }
        else
        {
            _speakFlag = NO;
        }
        
        NSLog(@"开始对讲--1");
        _audioFlag = YES;
 
        //先注释掉对讲提示
//        [self showNewStatusInfo:DPLocalizedString(@"Play_Speaking_begin")];
        [self playTalkSound];
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [_gdVideoPlayer startRecord];
        });
        
        dispatch_async_on_main_queue(^{
            self.talkingView.hidden = NO;
            [self.view bringSubviewToFront:self.talkingView];
        });
        NSLog(@"开始对讲--2");
    }
    else
    {
        [self showNewStatusInfo:DPLocalizedString(@"Play_camera_no_connect")];
    }
    
}

- (void)talkEndAction{
    
    if(_isRecordflag )
    {
        return;
    }
    
    _isTalk = NO;
    if (_isRunning)
    {
        //开启声音
        [_soundBtn setImage:[UIImage imageNamed:@"PlaySoundNormal"] forState:UIControlStateNormal];
        [_soundBtn setImage:[UIImage imageNamed:@"PlaySoundSelected"] forState:UIControlStateHighlighted];
        [SVProgressHUD dismiss];
        self.talkingView.hidden = YES;
        [self.view sendSubviewToBack:self.talkingView];
    }
    else
    {
        [SVProgressHUD dismiss];
        self.talkingView.hidden = YES;
        [self.view sendSubviewToBack:self.talkingView];
        [self showNewStatusInfo:DPLocalizedString(@"Play_camera_no_connect")];
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [_gdVideoPlayer stopRecord];
    });
}

#pragma mark -- '拍照‘按钮事件
- (void)snapshotBtnAction:(id)sender
{
    NSLog(@"'拍照’事件");
    
    [SVProgressHUD dismiss];
    if (_isRunning)
    {
        [self playSnapShotSound];
        NSString *snapshotPath = [[MediaManager shareManager] mediaPathWithDevId:[self.deviceModel.DeviceId substringFromIndex:8]
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
    self.cameraStatusSwitcher.hidden = YES;

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
    if (_isTalk
        || _isFourViewFullScreen)
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
    
    recognizerRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureAction:)];
    [recognizerRight setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [view addGestureRecognizer:recognizerRight];
    
    recognizerLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureAction:)];
    [recognizerLeft setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [view addGestureRecognizer:recognizerLeft];
    
    recognizerUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureAction:)];
    [recognizerUp setDirection:(UISwipeGestureRecognizerDirectionDown)];
    [view addGestureRecognizer:recognizerUp];
    
    recognizerDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureAction:)];
    [recognizerDown setDirection:(UISwipeGestureRecognizerDirectionUp)];
    [view addGestureRecognizer:recognizerDown];
    
    //添加单击手势
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapClick:)];
    [view addGestureRecognizer:tapGes];
    
}


- (void)tapClick:(UIGestureRecognizer *)gesture{
    if (_isLandSpace || !self.cameraOffBtn.hidden) {
        return;
    }
    [self appearControllView];
}


- (void)appearControllView{
    dispatch_async_on_main_queue(^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(disappearControllView) object:nil];
        [UIView animateWithDuration:0.2 animations:^{
            self.playControllView.hidden = NO;
            self.fourViewBtn.hidden = NO;
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
            self.fourViewBtn.hidden = YES;
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


/**
 闪现提示Label
 */
-(void)showNewStatusInfo:(NSString*)info
{
    [SVProgressHUD showInfoWithStatus:info];
    [SVProgressHUD dismissWithDelay:2];
//    self.tipsLabel.text = info;
//    [UIView animateWithDuration:0.3f delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
//        self.tipsLabel.alpha = 1.0;
//    } completion:^(BOOL finished) {
//        [UIView animateWithDuration:0.3f delay:2.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
//            self.tipsLabel.alpha = 0.0;
//        } completion:nil];
//    }];
}

#pragma mark - 获取实时流
-(void)getLiveStreamData
{
    
    _isStop = NO;
    
    //获取设置
    [self getDeviceSetting:nil];
    
    //获取摄像头开关
    [self getCameraSwitchStatus];
    
    //开始拉流计时
    [self startStreamTimer];

    _isLoading[0] = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
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
//            if (result==0) {
//                if (_gdVideoPlayer) {
//                    [weakSelf getLiveStreamData];
//                }
//            }
//            else{
//                if (!weakSelf.loadVideoActivity.hidden) {
//                    //递归拉流
//                    [weakSelf reloadStream];
//                }
//            }
        }];
    });

}


-(void)startStreamTimer
{
    if ( _streamTimer ==nil)
    {
        int repeatTimes = self.deviceTypeInDetail == GosDetailedDeviceType_T5100ZJ?10:5;
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
        [self setSoundBtnState:mode.ability_mic];
        
        //设置对讲按钮
        [self setIntercomBtnState:mode.ability_speakr];
        
        //设置摇篮曲按钮
        self.babyMusicBtn.hidden = !mode.ability_babyMusic;
        
        if (mode.ability_sd) {
            [self enableRecordListBtn];
        }
        else{
            
        }
        
        if (mode.ability_babyMusic) {
            _isHasBabyMusic = YES;
        }
        
        //设置摇杆
        [self setJoystickState:mode.ability_ptz];
        self.refreshSettingModel=[[UISettingModel alloc]init];
        self.refreshSettingModel=[mode copy];
        NSLog(@"%@",self.refreshSettingModel.ability_id);
        NSLog(@"%d",mode.ability_pir);
        
        //获取温度
        [self getDeviceTempWithModel:mode];
        
        [self getNetLinkSignalWithModel:mode];
        [self getDeviceBattryLevelWithModel:mode];
    });
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
    reqCMD.channel = _deviceModel.avChnnelNum;
    NSDictionary *reqData = [reqCMD requestCMDData];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[NetSDK sharedInstance] net_sendBypassRequestWithUID:self.platformUID  requestData:reqData timeout:15000 responseBlock:^(int result, NSDictionary *dict) {

            if(result==0){
                __strong typeof(weakSelf) strongSelf = weakSelf;
                CMD_GetBatteryLevelResp *batteryLevelResp = [CMD_GetBatteryLevelResp yy_modelWithDictionary:dict];
                dispatch_async(dispatch_get_main_queue(), ^{

                    strongSelf.batteryLevelImgView.image = [UIImage imageNamed:[NSString stringWithFormat:@"batteryLevel_%d",(batteryLevelResp.battery_level-1)/25]];
                });
            }
        }];
    });
}

- (void)getBattryLevelTimerFunc:(NSTimer*)timer{
    [self getBattryLevelFunc];
}

#pragma mark 获取网关与路由器连接信号强度
- (void)getNetLinkSignalWithModel:(UISettingModel*)model{
    if (_isCameraOff) {
        return;
    }
    if (model.ability_netlink_signal_flag) {
        if (!_netLinkSignalImgView) {
            [self.playControllView addSubview:self.netLinkSignalImgView];
            [self.netLinkSignalImgView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(self.playView).offset(-13);
                make.trailing.equalTo(self.playView).offset(-40); //-50
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
                    strongSelf.netLinkSignalImgView.image = [UIImage imageNamed:[NSString stringWithFormat:@"netLinkSignal_%d",(netLinkSignalResp.netlink_signal-1)/25]];
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
    }
    else
    {
        
        if (_isCameraOff) {
            //摄像头关闭
            return;
        }
        
        //支持语音
        self.soundBtn.userInteractionEnabled=YES;
        if (_audioFlag) {
            [self.soundBtn setImage:[UIImage imageNamed:@"PlaySoundNormal"]forState:UIControlStateNormal];
        }
        else{
            [self.soundBtn setImage:[UIImage imageNamed:@"PlayNoSoundNormal"]forState:UIControlStateNormal];
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
    }
    else
    {
        
        if (_isCameraOff) {
            //摄像头关闭
            return;
        }
        
        //支持对讲
        [self enableTalkBtn];
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
    _audioFlag = YES;
    if (self.gdVideoPlayer) {
        [NetInstanceManager startAudioData:self.deviceId andBlock:^(int value, int state,int cmd) {
        }];
    }
    [self.gdVideoPlayer startVoice];
    return YES;
}

/**
 停止播放音频
 */
-(BOOL)audioStop
{
    _audioFlag = NO;
    if (self.gdVideoPlayer) {
        [NetInstanceManager stopAudioData:self.deviceId andBlock:^(int value, int state,int cmd) {
        }];
    }
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
    if (_speakFlag == YES)
    {
    }
    else
    {
        if (_audioFlag && self.deviceTypeInDetail!=GosDetailedDeviceType_T5100ZJ) {
            [self audioStop];
        }
    }
    _isRecordflag = NO;
    dispatch_async_on_main_queue(^{
        self.recordTimeView.hidden =YES;
        [self.recordShowViewTimer  invalidate];
        self.recordShowViewTimer =nil;
        
        if ( self.deviceTypeInDetail!=GosDetailedDeviceType_T5100ZJ ) {
            //静音
            [_soundBtn setImage:[UIImage imageNamed:@"PlayNoSoundNormal"] forState:UIControlStateNormal];
            [_soundBtn setImage:[UIImage imageNamed:@"PlayNoSoundSelected"] forState:UIControlStateHighlighted];
        }
        
        //设置录像按钮
        [self.recordingBtn setImage:[UIImage imageNamed:@"PlayRecordNormal"] forState:UIControlStateNormal];
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
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//            [NetInstanceManager reconnect:self.deviceId resultBlock:^(int result, int state, int cmd) {
////                if (result==0 && _gdVideoPlayer) {
////                    [weakSelf getLiveStreamData];
////                }
//                
////                if (result != 0) {
////                    //重新拉
////                    [weakSelf reloadStream];
////                }
//                
//            }];
//        });
    }
}

-(void)enterBackground
{
    _isStop = YES;
    //停止视频录制
    [self stopVideoRecord];
    //销毁播放器
    [self removGDPlayer];
    //停止播放音频
    [self releaseBtnSoundAudioPlayer];
    //停止音频播放
    if (_audioFlag) {
        [self audioStop];
    }
    
    //停止请求视频流
    [NetInstanceManager stopPlayWithUID:self.deviceId streamType:kNETPRO_STREAM_REC];
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
        self.cameraStatusSwitcher.hidden = YES;

        _isRunning = NO;
        return;
    }
    //初始化运行状态
    [self initRunningStatus];
    [self setApiNetDelegate];
    [self configGDPlayer];
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

- (void)enableJoyStickBtn{
    dispatch_async_on_main_queue(^{
        _joystickBtn.userInteractionEnabled = YES;
        [_joystickBtn setImage:[UIImage imageNamed:@"PlayControllerNormal"] forState:UIControlStateNormal];
        [_joystickBtn setImage:[UIImage imageNamed:@"PlayControllSelected"] forState:UIControlStateHighlighted];
    });
}

- (void)enableRecordListBtn{
    dispatch_async_on_main_queue(^{
        _recordListBtn.userInteractionEnabled = YES;
        [_recordListBtn setImage:[UIImage imageNamed:@"PlayMediaList"] forState:UIControlStateNormal];
        [_recordListBtn setImage:[UIImage imageNamed:@"PlayMediaListSelected"] forState:UIControlStateHighlighted];
        NSLog(@"ADTest-----------------------------2");
    });
}

- (void)enableRecordingBtn{
    dispatch_async_on_main_queue(^{
        _recordingBtn.userInteractionEnabled = YES;
        [_recordingBtn setImage:[UIImage imageNamed:@"PlayRecordNormal@2x.png"] forState:UIControlStateNormal];
            NSLog(@"ADTest-----------------------------3");
    });
}


- (void)enableTalkBtn{
    dispatch_async_on_main_queue(^{
        _talkBtn.userInteractionEnabled = YES;
        [_talkBtn setImage:[UIImage imageNamed:@"PlaySpeakNormal"] forState:UIControlStateNormal];
        [_talkBtn setImage:[UIImage imageNamed:@"PlaySpeakSelected"] forState:UIControlStateHighlighted];
    });
}


- (void)enableSnapShotBtn{
    dispatch_async_on_main_queue(^{
        _snapshotBtn.userInteractionEnabled = YES;
        [_snapshotBtn setImage:[UIImage imageNamed:@"PlayCameraNormal"] forState:UIControlStateNormal];
        [_snapshotBtn setImage:[UIImage imageNamed:@"PlayCameraSelected"] forState:UIControlStateHighlighted];
    });
}

- (void)enableSoundBtn{
    dispatch_async_on_main_queue(^{
        _soundBtn.userInteractionEnabled = YES;
        [_soundBtn setImage:[UIImage imageNamed:@"PlayNoSoundNormal"] forState:UIControlStateNormal];
        [_soundBtn setImage:[UIImage imageNamed:@"PlayNoSoundSelected"] forState:UIControlStateHighlighted];
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
        NSString *covertPath = [[MediaManager shareManager] mediaPathWithDevId:self.deviceId
                                                                      fileName:nil
                                                                     mediaType:GosMediaCover
                                                                    deviceType:GosDeviceIPC
                                                                      position:PositionMain];
        _gdVideoPlayer.coverPath = covertPath;
        [self.gdVideoPlayer setPlayerView:self.playView];
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
//    apiSet.networkDelegate = self;
}


#pragma mark -- 移除全局NetAPI代理
- (void)RemoveApiNetDelegate
{
    NetAPISet *apiSet = [NetAPISet sharedInstance];
    apiSet.sourceDelegage = nil;
//    apiSet.networkDelegate = nil;
}


#pragma mark - Getter && Setter

///**
// * 顶部View
// */
//- (UIView *)topView{
//    if (!_topView) {
//        _topView = [[UIView alloc]init];
//        _topView.backgroundColor = [UIColor whiteColor];
//    }
//    return _topView;
//}
//
//
///**
// *  提醒区域label
// */
//- (UILabel *)tipsLabel{
//    if (!_tipsLabel) {
//        _tipsLabel = [[UILabel alloc]init];
//        _tipsLabel.textColor = [UIColor colorWithHexString:@"#262324"];
//        _tipsLabel.font = [UIFont systemFontOfSize:12.0];
//        _tipsLabel.textAlignment = NSTextAlignmentLeft;
//        _tipsLabel.alpha = 0.0f;
//    }
//    return _tipsLabel;
//}
//
///**
// *  时间Label
// */
//- (UILabel *)timeLabel{
//    if (!_timeLabel) {
//        _timeLabel = [[UILabel alloc]init];
//        _timeLabel.textColor = [UIColor colorWithHexString:@"#262324"];
//        _timeLabel.font = [UIFont systemFontOfSize:12.0];
//        _timeLabel.textAlignment = NSTextAlignmentRight;
//        _timeLabel.hidden = YES;
//    }
//    return _timeLabel;
//}


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
        _playControllView.hidden = YES;
    }
    return _playControllView;
}

/**
 *  摇篮曲开关按钮
 */
- (UIButton *)babyMusicBtn{
    if (!_babyMusicBtn) {
        _babyMusicBtn = [[UIButton alloc]init];
        _babyMusicBtn.selected = NO;
        [_babyMusicBtn addTarget:self action:@selector(babyMusicAction:) forControlEvents:UIControlEventTouchUpInside];
        [_babyMusicBtn setImage:[UIImage imageNamed:@"btn_music_normal"] forState:UIControlStateNormal];
        [_babyMusicBtn setImage:[UIImage imageNamed:@"btn_music_select"] forState:UIControlStateSelected];
        [_babyMusicBtn setImage:[UIImage imageNamed:@"btn_music_press"] forState:UIControlStateHighlighted];
        _babyMusicBtn.hidden = YES;
    }
    return _babyMusicBtn;
}

/**
 *  录像列表 Button
 */
- (UIButton *)recordListBtn{
    if (!_recordListBtn) {
        _recordListBtn = [[UIButton alloc]init];
        [_recordListBtn addTarget:self action:@selector(recordListBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_recordListBtn setImage:[UIImage imageNamed:@"btn_playback_disable"] forState:UIControlStateNormal];
        _recordListBtn.userInteractionEnabled = NO;
    }
    return _recordListBtn;
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
 *  云台控制 Button
 */
- (UIButton *)joystickBtn{
    if (!_joystickBtn) {
        _joystickBtn = [[UIButton alloc]init];
        [_joystickBtn addTarget:self action:@selector(joystickBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_joystickBtn setImage:[UIImage imageNamed:@"btn_ptz_disable"] forState:UIControlStateNormal];
        _joystickBtn.userInteractionEnabled = NO;
    }
    return _joystickBtn;
}

/**
 *  画面质量切换 Button
 */
- (UIButton *)qualityChangeBtn{
    if (!_qualityChangeBtn) {
        _qualityChangeBtn = [[UIButton alloc]init];
        [_qualityChangeBtn addTarget:self action:@selector(qualityChangeBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_qualityChangeBtn setImage:[UIImage imageNamed:@"PlayControllBG"] forState:UIControlStateNormal];
        [_qualityChangeBtn setImage:[UIImage imageNamed:@"PlayControllBlackBG"] forState:UIControlStateHighlighted];
        _qualityChangeBtn.userInteractionEnabled = NO;
    }
    return _qualityChangeBtn;
}

/**
 *  画面质量切换 Label
 */
- (UILabel *)qualityChangeLabel{
    if (!_qualityChangeLabel) {
        _qualityChangeLabel = [[UILabel alloc]init];
        _qualityChangeLabel.textAlignment = NSTextAlignmentCenter;
        _qualityChangeLabel.font = [UIFont systemFontOfSize:12.0f];
        _qualityChangeLabel.textColor = [UIColor whiteColor];
        _qualityChangeLabel.text = DPLocalizedString(@"Play_HD");
        _qualityChangeLabel.backgroundColor = [UIColor clearColor];
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

- (UIImageView *)batteryLevelImgView{
    if (!_batteryLevelImgView) {
        _batteryLevelImgView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 290, 20, 20)];
        _batteryLevelImgView.image = [UIImage imageNamed:@"batteryLevel_3"];
    }
    return _batteryLevelImgView;
}

/**
 *  录像时间显示 View
 */
- (UIView *)recordTimeView{
    if (!_recordTimeView) {
        _recordTimeView = [[UIView alloc]init];
//        _recordTimeView.backgroundColor = [UIColor colorWithRed:120 green:120 blue:120 alpha:0.5];
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
        [_talkBtn setImage:[UIImage imageNamed:@"btn_talk_disable"] forState:UIControlStateNormal];
        [_talkBtn addTarget:self action:@selector(talkBtnAction:) forControlEvents:UIControlEventTouchDown];
        [_talkBtn addTarget:self action:@selector(talkEndAction) forControlEvents:UIControlEventTouchUpInside];
        _talkBtn.userInteractionEnabled = NO;
    }
    return _talkBtn;
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
        _talkLabel.text = DPLocalizedString(@"play_Talk");
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
 *  控制杆区域 View
 */
- (JoystickControllView *)joystickView{
    if (!_joystickView) {
        _joystickView = [[JoystickControllView alloc]init];
        [_joystickView.moveUpBtn addTarget:self action:@selector(moveUpBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_joystickView.moveLeftBtn addTarget:self action:@selector(moveLeftBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_joystickView.moveDownBtn addTarget:self action:@selector(moveDownBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_joystickView.moveRightBtn addTarget:self action:@selector(moveRightBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        _joystickView.backgroundColor = [UIColor whiteColor];
    }
    return _joystickView;
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
 摄像头打开
 */
- (UISwitch *)cameraStatusSwitcher{
    if (!_cameraStatusSwitcher) {
        _cameraStatusSwitcher = [[UISwitch alloc]init];
        _cameraStatusSwitcher.hidden = YES;
        [_cameraStatusSwitcher setOn:NO animated:NO];
        [_cameraStatusSwitcher addTarget:self action:@selector(turnOnCamera:) forControlEvents:UIControlEventValueChanged];
    }
    return _cameraStatusSwitcher;
}

- (void)turnOnCamera:(id)sender{
    if(!_isCameraOff){
        return;
    }
    
    CMD_SetCameraSwitchReq *req = [CMD_SetCameraSwitchReq new];
    req.device_switch = 1;
    NSDictionary *reqData = [req requestCMDData];
    __weak typeof(self) weakSelf = self;
    [SVProgressHUD showWithStatus:@"Loading..."];
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:self.platformUID requestData:reqData timeout:7000 responseBlock:^(int result, NSDictionary *dict) {
        
        if (result == 0) {
            _isCameraOff = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.cameraOffBtn.hidden = YES;
                weakSelf.cameraStatusSwitcher.hidden = YES;
                [weakSelf enterForeground];
            });
        }else{
            _isCameraOff = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            [weakSelf.cameraStatusSwitcher setOn: !weakSelf.cameraStatusSwitcher.isOn animated:NO];
        });
    }];
}

/**
 对讲弹出的View
 */
- (UIImageView *)talkingView{
    if (!_talkingView) {
        _talkingView = [[UIImageView alloc]init];
        _talkingView.image = [UIImage imageNamed:@"PlayRecording"];
        _talkingView.hidden = YES;
    }
    return _talkingView;
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

- (AVAudioPlayer *)talkBtnAudioPlayer
{
    if (!_talkBtnAudioPlayer)
    {
        NSString *audioFilePath = [[NSBundle mainBundle] pathForResource:@"RecordSound" ofType:@"wav"];
        NSURL *audioFileUrl = [NSURL fileURLWithPath:audioFilePath];
        _talkBtnAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileUrl error:NULL];
    }
    return _talkBtnAudioPlayer;
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


#pragma mark - 四画面相关
- (EnlargeClickButton *)fourViewBtn
{
    if (!_fourViewBtn)
    {
        _fourViewBtn = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        [_fourViewBtn addTarget:self
                         action:@selector(fourViewBtnAction)
               forControlEvents:UIControlEventTouchUpInside];
        [_fourViewBtn setImage:[UIImage imageNamed:@"ipcFourViewBtnNormal"]
                      forState:UIControlStateNormal];
        [_fourViewBtn setImage:[UIImage imageNamed:@"ipcFourViewBtnHighlight"]
                      forState:UIControlStateSelected];
        [_fourViewBtn setImage:[UIImage imageNamed:@"ipcFourViewBtnHighlight"]
                      forState:UIControlStateHighlighted];
        _fourViewBtn.hidden = NO;
    }
    return _fourViewBtn;
}


#pragma mark -- 更新设备列表
- (void)updateFourViewList
{
    [self.fourPlayView.devListArray removeAllObjects];
    NSInteger devCount = [[[DeviceManagement sharedInstance] deviceListArray] count];
    for (int i = 0; i < devCount; i++)
    {
        DeviceDataModel *devModel = [[DeviceManagement sharedInstance] deviceListArray][i];
        if (GosDeviceIPC != devModel.DeviceType
            || GosDeviceStatusOnLine != devModel.Status)
//            || [devModel.DeviceId isEqualToString:self.tlDevDataModel.DeviceId]
//            || [devModel.DeviceId isEqualToString:self.trDevDataModel.DeviceId]
//            || [devModel.DeviceId isEqualToString:self.blDevDataModel.DeviceId]
//            || [devModel.DeviceId isEqualToString:self.brDevDataModel.DeviceId])
        {
            continue;
        }
        if ([devModel.DeviceId isEqualToString:self.tlDevDataModel.DeviceId])
        {
            [self.fourPlayView.addedDevArray replaceObjectAtIndex:PositionTopLeft
                                                       withObject:devModel];
        }
        if ([devModel.DeviceId isEqualToString:self.trDevDataModel.DeviceId])
        {
            [self.fourPlayView.addedDevArray replaceObjectAtIndex:PositionTopRight
                                                       withObject:devModel];
        }
        if ([devModel.DeviceId isEqualToString:self.blDevDataModel.DeviceId])
        {
            [self.fourPlayView.addedDevArray replaceObjectAtIndex:PositionBottomLeft
                                                       withObject:devModel];
        }
        if ([devModel.DeviceId isEqualToString:self.brDevDataModel.DeviceId])
        {
            [self.fourPlayView.addedDevArray replaceObjectAtIndex:PositionBottomRight
                                                       withObject:devModel];
        }
        
        [self.fourPlayView.devListArray addObject:devModel];
    }
}


- (void)addVideoQualityWithDevId:(NSString *)deviceId
{
    if (IS_STRING_EMPTY(deviceId))
    {
        return;
    }
    if ([[_originVideoQualityDict allKeys] containsObject:deviceId])
    {
        return;
    }
    __weak typeof(self)weakSelf = self;
    [self queryDeviceId:deviceId
     VideoQualityResult:^(NSString *deviceId,
                          VideoQulityType vqType){
         
         __strong typeof(weakSelf)strongSelf = weakSelf;
         if (!strongSelf)
         {
             return ;
         }
         NSLog(@"============ 四画面 添加原始码率，deviceId = %@", deviceId);
         [strongSelf->_originVideoQualityDict setObject:[NSNumber numberWithInteger:vqType]
                                                 forKey:deviceId];
     }];
}


#pragma mark -- 自动切换视频码率（四画面切换时）
-(void)autoChangVideoQuality:(VideoQulityType)qvType
                    deviceId:(NSString *)deviceId;
{
    if (IS_STRING_EMPTY(deviceId))
    {
        NSLog(@"============ 四画面 ‘自动切换’ 无法发送切换码率命令， deviceId= nil");
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
        
        [NetInstanceManager sendCmd:CmdModel_Camera_VIDEOQUALITY
                           andParam:VideoQulity_HD == qvType ? Camera_VIDEOQUALITY_MAX : Camera_VIDEOQUALITY_HIGH
                             andUID:deviceId
                         andChannel:0
                           andBlock:^(int value, int state,int cmd) {
                               
                               if (0 == state)
                               {
                                   NSLog(@"============ 四画面 ‘自动切换’ 发送切换码率命令 成功！");
                               }
                               else
                               {
                                   NSLog(@"============ 四画面 ‘自动切换’ 发送切换码率命令 失败！");
                               }
                           }];
    });
}


- (void)fourViewBtnAction
{
    NSLog(@"IPC 四画面按钮！");
    
    [self enterBackground];
    
    _isFourViewFullScreen = YES;
    
    [self.fourPlayView configBorderHidden:NO
                               onPosition:_fourViewPosition];
    
    [self.fourPlayView performSelector:@selector(autoHiddenBorderOnPosition:)
                            withObject:[NSNumber numberWithInteger:_fourViewPosition]
                            afterDelay:6];
    
    if (UIInterfaceOrientationPortrait == [[UIApplication sharedApplication] statusBarOrientation])
    {
        [self enterFullscreen:YES];
    }
    else
    {
        [self enterFullscreen:NO];
    }
    for (NSInteger pos = PositionTopLeft; pos <= PositionBottomRight; pos++)
    {
        [self.fourPlayView startActivityOnPosition:pos];
    }
}


#pragma mark - GDVideoPlayer（四画面）
#pragma mark -- 创建 Video player（四画面）
- (GDVideoPlayer *)createVideoPlayerOnPosition:(PositionType)positionType
{
    GDVideoPlayer *_pVideoPlayer    = nil;
    UIView *_pVideoPlayView         = nil;
    DeviceDataModel *_pDevDataModel = nil;
    
    switch (positionType)
    {
        case PositionTopLeft:
        {
            _pVideoPlayView = self.fourPlayView.tlPlayView;
            _pDevDataModel  = self.tlDevDataModel;
        }
            break;
            
        case PositionTopRight:
        {
            _pVideoPlayView = self.fourPlayView.trPlayView;
            _pDevDataModel  = self.trDevDataModel;
        }
            break;
            
        case PositionBottomLeft:
        {
            _pVideoPlayView = self.fourPlayView.blPlayView;
            _pDevDataModel  = self.blDevDataModel;
        }
            break;
            
        case PositionBottomRight:
        {
            _pVideoPlayView = self.fourPlayView.brPlayView;
            _pDevDataModel  = self.brDevDataModel;
        }
            break;
            
        default:
            break;
    }
    if (!_pVideoPlayView
        || !_pDevDataModel
        || !_pDevDataModel.DeviceId || 28 > _pDevDataModel.DeviceId.length)
    {
        return nil;
    }
    _pVideoPlayer = [[GDVideoPlayer alloc] init];
    [_pVideoPlayer initWithViewAndDelegate:_pVideoPlayView
                                  Delegate:self
                               andDeviceID:(_pDevDataModel.DeviceId.length == 15) ? _pDevDataModel.DeviceId : [_pDevDataModel.DeviceId substringFromIndex:8]
                        andWithdoubleScale:YES];
    NSString *covertPath = [[MediaManager shareManager] mediaPathWithDevId:[_pDevDataModel.DeviceId substringFromIndex:8]
                                                                  fileName:nil
                                                                 mediaType:GosMediaCover
                                                                deviceType:GosDeviceIPC
                                                                  position:PositionMain];
    _pVideoPlayer.coverPath = covertPath;
    [_pVideoPlayer setPlayerView:_pVideoPlayView];
    
    return _pVideoPlayer;
}



#pragma mark -- 释放 Video player（四画面）
- (void)releaseVideoPlayer:(GDVideoPlayer *__strong*)videoPlayer;
{
    if (!videoPlayer)
    {
        return;
    }
    [*videoPlayer stopPlay];
    (*videoPlayer).delegate = nil;
    *videoPlayer = nil;
}


#pragma mark -- 连接设备拉流（四画面）
- (void)connctToDeviceOnPosition:(PositionType)positionType
{
    DeviceDataModel *_pDevDataModel = nil;
    switch (positionType)
    {
        case PositionTopLeft:
        {
            _pDevDataModel  = self.tlDevDataModel;
        }
            break;
            
        case PositionTopRight:
        {
            _pDevDataModel  = self.trDevDataModel;
        }
            break;
            
        case PositionBottomLeft:
        {
            _pDevDataModel  = self.blDevDataModel;
        }
            break;
            
        case PositionBottomRight:
        {
            _pDevDataModel  = self.brDevDataModel;
        }
            break;
            
        default:
            break;
    }
    if (!_pDevDataModel
        || !_pDevDataModel.DeviceId || 28 > _pDevDataModel.DeviceId.length)
    {
        return ;
    }
    BOOL isConnected = [NetInstanceManager isDeviceConnectedWithUID:(_pDevDataModel.DeviceId.length == 15)?_pDevDataModel.DeviceId : [_pDevDataModel.DeviceId substringFromIndex:8]];
    if (YES == isConnected)
    {
        if (4 >= positionType)
        {
            _isFourViewRunning[positionType] = YES;
        }
        
        //已经连接，拉流
        [self reqLiveStreamDataOnPosition:positionType];
    }
    else
    {
        //主动添加设备
        [[NetAPISet sharedInstance] addClient:(_pDevDataModel.DeviceId.length == 15)?_pDevDataModel.DeviceId : [_pDevDataModel.DeviceId substringFromIndex:8]
                                  andpassword:_pDevDataModel.StreamPassword];
    }
    
}


#pragma mark -- 获取实时流（四画面）
-(void)reqLiveStreamDataOnPosition:(PositionType)positionType
{
    DeviceDataModel *_pDevDataModel = nil;
    switch (positionType)
    {
        case PositionTopLeft:
        {
            _pDevDataModel  = self.tlDevDataModel;
        }
            break;
            
        case PositionTopRight:
        {
            _pDevDataModel  = self.trDevDataModel;
        }
            break;
            
        case PositionBottomLeft:
        {
            _pDevDataModel  = self.blDevDataModel;
        }
            break;
            
        case PositionBottomRight:
        {
            _pDevDataModel  = self.brDevDataModel;
        }
            break;
            
        default:
            break;
    }
    if (!_pDevDataModel
        || !_pDevDataModel.DeviceId || 28 > _pDevDataModel.DeviceId.length)
    {
        return ;
    }
    if (4 >= positionType)
    {
        _isFourViewStopVideo[positionType] = NO;
        _isLoading[positionType] = NO;
    }
    
    
    //获取摄像头开关
//    [self getCameraSwitchStatus];
    
    // 开始拉流计时
//    [self startStreamTimer];
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        [NetInstanceManager startGettingVideoDataWithUID:(_pDevDataModel.DeviceId.length == 15)?_pDevDataModel.DeviceId : [_pDevDataModel.DeviceId substringFromIndex:8]
                                              videoType:2 resultBlock:^(int result,
                                                           int state) {
                                                 
                                             }];
    });
}


#pragma mark -- 停止实时流（四画面
- (void)stopVideoDataOnPosition:(PositionType)positionType
{
//    DeviceDataModel *_pDevDataModel = nil;
//    switch (positionType)
//    {
//        case PositionTopLeft:
//        {
//            _pDevDataModel  = self.tlDevDataModel;
//        }
//            break;
//            
//        case PositionTopRight:
//        {
//            _pDevDataModel  = self.trDevDataModel;
//        }
//            break;
//            
//        case PositionBottomLeft:
//        {
//            _pDevDataModel  = self.blDevDataModel;
//        }
//            break;
//            
//        case PositionBottomRight:
//        {
//            _pDevDataModel  = self.brDevDataModel;
//        }
//            break;
//            
//        default:
//            break;
//    }
//    if (!_pDevDataModel
//        || !_pDevDataModel.DeviceId || 28 > _pDevDataModel.DeviceId.length)
//    {
//        return ;
//    }
//    //停止请求视频流
//    [NetInstanceManager stopPlayWithUID:(_pDevDataModel.DeviceId.length == 15)?_pDevDataModel.DeviceId : [_pDevDataModel.DeviceId substringFromIndex:8]];
}

#pragma mark -- 进入全屏
- (void)enterFullscreen:(BOOL)isPortraint
{
    if (TransformViewSmall != self.transformState)
    {
        return;
    }
    self.transformState = TransformViewAnimating;
    
    [self configFourViewHidden:NO];
    
    // 记录进入全屏前的parentView和frame
    self.fourPlayViewFrame      = self.fourPlayView.frame;
    self.fourPlayViewParentView = self.fourPlayView.superview;
    
    // movieView移到window上
    CGRect nvrPlayViewRectInWindow = [self.view convertRect:self.fourPlayView.bounds
                                                     toView:[UIApplication sharedApplication].keyWindow];
    [self.fourPlayView removeFromSuperview];
    self.fourPlayView.frame = nvrPlayViewRectInWindow;
    [[UIApplication sharedApplication].keyWindow addSubview:self.fourPlayView];
    
    // 执行动画
    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:TRANSFORM_DURATION
                     animations:^{
                         
                         __strong typeof(weakSelf)strongSelf = weakSelf;
                         if (!strongSelf)
                         {
                             return ;
                         }
                         [self hiddentStatueBar:YES];
                         strongSelf.fourPlayView.transform = CGAffineTransformMakeRotation((NO == isPortraint) ? 0 : M_PI_2);
                         strongSelf.fourPlayView.bounds = CGRectMake(0,
                                                              0,
                                                              strongSelf->_screenHeight,
                                                              strongSelf->_screenWidth);
                         if (NO == isPortraint)
                         {
                             strongSelf.fourPlayView.center = CGPointMake(strongSelf->_screenHeight * 0.5f,
                                                                          strongSelf->_screenWidth * 0.5f);
                         }
                         else
                         {
                             strongSelf.fourPlayView.center = CGPointMake(strongSelf->_screenWidth * 0.5f,
                                                                          strongSelf->_screenHeight * 0.5f);
                         }
                     }
                     completion:^(BOOL finished) {
                         
                         __strong typeof(weakSelf)strongSelf = weakSelf;
                         if (!strongSelf)
                         {
                             return ;
                         }
                         strongSelf.transformState = TransformViewFullscreen;
                         [strongSelf startFourViewVideoData];
                     }];
}


#pragma mark -- 退出全屏
- (void)exitFullscreen
{
    if (TransformViewFullscreen != self.transformState)
    {
        return;
    }
    self.transformState     = TransformViewAnimating;
    
    CGRect fourViewFrame = [self.fourPlayViewParentView convertRect:self.fourPlayViewFrame
                                                             toView:[UIApplication sharedApplication].keyWindow];
    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:TRANSFORM_DURATION
                     animations:^{
                         
                         __strong typeof(weakSelf)strongSelf = weakSelf;
                         if (!strongSelf)
                         {
                             return ;
                         }
                         strongSelf.fourPlayView.transform = CGAffineTransformIdentity;
                         strongSelf.fourPlayView.frame = fourViewFrame;
                         
                         // movieView回到竖屏位置
                         [strongSelf.fourPlayView removeFromSuperview];
                         strongSelf.fourPlayView.frame = strongSelf.fourPlayViewFrame;
                         [strongSelf.fourPlayViewParentView addSubview:strongSelf.fourPlayView];
                         
                         [strongSelf configFourViewHidden:YES];
                     }
                     completion:^(BOOL finished) {
                         
                         __strong typeof(weakSelf)strongSelf = weakSelf;
                         if (!strongSelf)
                         {
                             return ;
                         }
                         strongSelf.transformState = TransformViewSmall;
                         
                         [strongSelf hiddentStatueBar:NO];
                     }];
}


#pragma mark -- 设置状态栏 位置
- (void)refreshStatusBarOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    [[UIApplication sharedApplication] setStatusBarOrientation:interfaceOrientation
                                                      animated:YES];
}


#pragma mark -- 显示/隐藏 statue bar
- (void)hiddentStatueBar:(BOOL)isHidden
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[UIApplication sharedApplication] setStatusBarHidden:isHidden
                                                withAnimation:UIStatusBarAnimationFade];
    });
}


#pragma mark -- 开启四画面‘已添加的设备’的视频
- (void)startFourViewVideoData
{
    [NetAPISet sharedInstance].sourceDelegage = self;
    
    for (int pos = PositionTopLeft; pos <= PositionBottomRight; pos++)
    {
        if (NO == _isAddDevice[pos])
        {
            continue;
        }
        switch (pos)
        {
            case PositionTopLeft:
            {
                self.tlVideoPlayer  = [self createVideoPlayerOnPosition:pos];
            }
                break;
                
            case PositionTopRight:
            {
                self.trVideoPlayer  = [self createVideoPlayerOnPosition:pos];
            }
                break;
                
            case PositionBottomLeft:
            {
                self.blVideoPlayer  = [self createVideoPlayerOnPosition:pos];
            }
                break;
                
            case PositionBottomRight:
            {
                self.brVideoPlayer  = [self createVideoPlayerOnPosition:pos];
            }
                break;
                
            default:
                break;
        }
        [self connctToDeviceOnPosition:pos];
    }
}


#pragma mark -- 停止四画面‘已添加的设备’的视频
- (void)stopFourViewVideoData
{
    for (int pos = PositionTopLeft; pos <= PositionBottomRight; pos++)
    {
        if (NO == _isAddDevice[pos])
        {
            continue;
        }
        switch (pos)
        {
            case PositionTopLeft:
            {
                [self releaseVideoPlayer:&_tlVideoPlayer];
                
            }
                break;
                
            case PositionTopRight:
            {
                [self releaseVideoPlayer:&_trVideoPlayer];
            }
                break;
                
            case PositionBottomLeft:
            {
                [self releaseVideoPlayer:&_blVideoPlayer];
            }
                break;
                
            case PositionBottomRight:
            {
                [self releaseVideoPlayer:&_brVideoPlayer];
            }
                break;
                
            default:
                break;
        }
        [self stopVideoDataOnPosition:pos];
    }
}


#pragma mark -- 更新主画面数据
- (void)updateDevDataModelOnPosition:(PositionType)positionType
{
    switch (positionType)
    {
        case PositionTopLeft:
        {
            self.deviceModel = self.tlDevDataModel;
            self.deviceId    = (_tlDevDataModel.DeviceId.length == 15)?_tlDevDataModel.DeviceId : [_tlDevDataModel.DeviceId substringFromIndex:8];
            self.deviceName  = self.tlDevDataModel.DeviceName;
            
        }
            break;
            
        case PositionTopRight:
        {
            self.deviceModel = self.trDevDataModel;
            self.deviceId    = (self.trDevDataModel.DeviceId.length == 15)?self.trDevDataModel.DeviceId : [self.trDevDataModel.DeviceId substringFromIndex:8];
;
            self.deviceName  = self.trDevDataModel.DeviceName;
        }
            break;
            
        case PositionBottomLeft:
        {
            self.deviceModel = self.blDevDataModel;
            self.deviceId    = (self.blDevDataModel.DeviceId.length == 15)?self.blDevDataModel.DeviceId : [self.blDevDataModel.DeviceId substringFromIndex:8];
;
            self.deviceName  = self.blDevDataModel.DeviceName;
        }
            break;
            
        case PositionBottomRight:
        {
            self.deviceModel = self.brDevDataModel;
            self.deviceId    = (self.brDevDataModel.DeviceId.length == 15)?self.brDevDataModel.DeviceId : [self.brDevDataModel.DeviceId substringFromIndex:8];
            self.deviceName  = self.brDevDataModel.DeviceName;
        }
            break;
            
        default:
            break;
    }
    self.navigationItem.title = self.deviceName;
}


#pragma mark -- 还原视频码率
- (void)revertVideoQuality
{
    if (VideoQulity_SD != [[_originVideoQualityDict objectForKey:[self.tlDevDataModel.DeviceId substringFromIndex:8]] integerValue])
    {
        NSLog(@"============ 四画面切换后 Top-Left  视频数据还原为：高清");
        [self autoChangVideoQuality:VideoQulity_HD
                           deviceId:[self.tlDevDataModel.DeviceId substringFromIndex:8]];
    }
    if (VideoQulity_SD != [[_originVideoQualityDict objectForKey:[self.trDevDataModel.DeviceId substringFromIndex:8]] integerValue])
    {
        NSLog(@"============ 四画面切换后 Top-Right  视频数据还原为：高清");
        [self autoChangVideoQuality:VideoQulity_HD
                           deviceId:[self.trDevDataModel.DeviceId substringFromIndex:8]];
    }
    if (VideoQulity_SD != [[_originVideoQualityDict objectForKey:[self.blDevDataModel.DeviceId substringFromIndex:8]] integerValue])
    {
        NSLog(@"============ 四画面切换后 Bottom-Left  视频数据还原为：高清");
        [self autoChangVideoQuality:VideoQulity_HD
                           deviceId:[self.blDevDataModel.DeviceId substringFromIndex:8]];
    }
    if (VideoQulity_SD != [[_originVideoQualityDict objectForKey:[self.brDevDataModel.DeviceId substringFromIndex:8]] integerValue])
    {
        NSLog(@"============ 四画面切换后 Bottom-Right  视频数据还原为：高清");
        [self autoChangVideoQuality:VideoQulity_HD
                           deviceId:[self.brDevDataModel.DeviceId substringFromIndex:8]];
    }
}


#pragma mark -- 更新主画面预览图
- (void)updatePreImage
{
    //获取预览图片
    UIImage *preViewImg = [[MediaManager shareManager] coverWithDevId:self.deviceId
                                                             fileName:nil
                                                           deviceType:GosDeviceIPC
                                                             position:PositionMain];
    
    if (preViewImg)
    {
        _playView.layer.contents = (id)preViewImg.CGImage;
    }
}


#pragma mark -- 设置四画面是否隐藏
- (void)configFourViewHidden:(BOOL)isHidden
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
       
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法设置四画面是否隐藏！");
            return ;
        }
        if (NO == isHidden)
        {
            [strongSelf.fourPlayView configTableViewHidden:YES];
        }
        strongSelf.fourPlayView.hidden = isHidden;
    });
}


#pragma mark - IpcFourViewDelegate
#pragma mark -- ‘添加设备’按钮事件
- (void)addDevActionOnPosition:(PositionType)positionType
{
    [self updateFourViewList];
}


#pragma mark -- ‘删除设备’按钮事件
- (void)deleteDevActionOnPosition:(PositionType)positionType
{
    [self.fourPlayView configDeleteDevBtnHidden:YES
                                     onPosition:positionType];
    switch (positionType)
    {
        case PositionTopLeft:
        {
            [self releaseVideoPlayer:&_tlVideoPlayer];
            [self stopVideoDataOnPosition:positionType];
            self.tlDevDataModel = nil;
        }
            break;
            
        case PositionTopRight:
        {
            [self releaseVideoPlayer:&_trVideoPlayer];
            [self stopVideoDataOnPosition:positionType];
            self.trDevDataModel = nil;
        }
            break;
            
        case PositionBottomLeft:
        {
            [self releaseVideoPlayer:&_blVideoPlayer];
            [self stopVideoDataOnPosition:positionType];
            self.blDevDataModel = nil;
        }
            break;
            
        case PositionBottomRight:
        {
            [self releaseVideoPlayer:&_brVideoPlayer];
            [self stopVideoDataOnPosition:positionType];
            self.brDevDataModel = nil;
        }
            break;
            
        default:
            break;
    }
    
    _isAddDevice[positionType] = NO;
    
    [self.fourPlayView configAddDevBtnHidden:NO
                                  onPosition:positionType];
}


#pragma mark -- ‘重连设备’按钮事件
- (void)reconnOnPosition:(PositionType)PositionType
{
    
}


#pragma mark -- 单击手势处理
- (void)singleTapActionOnPosition:(PositionType)positionType
{
    
}


#pragma mark -- 双击手势处理
- (void)doubleTapActionOnPosition:(PositionType)positionType
{
    for (NSInteger pos = PositionTopLeft; pos <= PositionBottomRight; pos++)
    {
        [self.fourPlayView stopActivityOnPosition:pos];
    }
    _isFourViewStopVideo[positionType] = YES;
    
    [self revertVideoQuality];
    
    [self stopFourViewVideoData];
    
    [self updateDevDataModelOnPosition:positionType];
    
    [self updatePreImage];
    
    [self exitFullscreen];
    
    _isFourViewFullScreen = NO;
    _fourViewPosition     = positionType;
    
    __weak typeof(self)weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(TRANSFORM_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        [strongSelf enterForeground];
    });
}


#pragma mark -- ‘设备添加’源处理
- (void)addDevModel:(DeviceDataModel *)devDataModel
        onPostition:(PositionType)positionType
{
    if (!devDataModel)
    {
        return;
    }
    _isAddDevice[positionType] = YES;
    
    __weak typeof(self)weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        [strongSelf addVideoQualityWithDevId:[devDataModel.DeviceId substringFromIndex:8]];
    });
    
    switch (positionType)
    {
        case PositionTopLeft:       // 左上角
        {
            self.tlDevDataModel = devDataModel;
            self.tlVideoPlayer = [self createVideoPlayerOnPosition:positionType];
            [self connctToDeviceOnPosition:positionType];
        }
            break;
            
        case PositionTopRight:      // 右上角
        {
            self.trDevDataModel = devDataModel;
            self.trVideoPlayer = [self createVideoPlayerOnPosition:positionType];
            [self connctToDeviceOnPosition:positionType];
        }
            break;
            
        case PositionBottomLeft:    // 左下角
        {
            self.blDevDataModel = devDataModel;
            self.blVideoPlayer = [self createVideoPlayerOnPosition:positionType];
            [self connctToDeviceOnPosition:positionType];
        }
            break;
            
        case PositionBottomRight:   // 右下角
        {
            self.brDevDataModel = devDataModel;
            self.brVideoPlayer = [self createVideoPlayerOnPosition:positionType];
            [self connctToDeviceOnPosition:positionType];
        }
            break;
            
        default:
            break;
    }
}


@end
