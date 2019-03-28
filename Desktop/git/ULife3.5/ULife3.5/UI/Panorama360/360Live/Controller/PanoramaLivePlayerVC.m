//
//  PanoramaLivePlayerVC.m
//  ULife3.5
//
//  Created by zhuochuncai on 03/08/2017.
//  Copyright © 2017 GosCam. All rights reserved.
//

#import "PanoramaLivePlayerVC.h"
#import "Masonry.h"

#import "GOSOpenGLESVCViewController.h"

#import "NetAPISet.h"
#import "NetSDK.h"
#import "CMSCommand.h"

#import "UIColor+YYAdd.h"
#import "UIView+YYAdd.h"
#import "CameraInfoManager.h"
#import "DeviceManagement.h"
#import "UISettingManagement.h"

#import "ACVideoDecoder.h"
#import "GDVideoPlayer.h"
#import "YYKitMacro.h"
#import <AVFoundation/AVFoundation.h>

#import <RealReachability.h>
#import "DevicePlayManager.h"

#import "VideoImageManager.h"
#import "NSTimer+YYAdd.h"
#import "HWLogManager.h"
#import "EnlargeClickButton.h"

#import "SettingViewController.h"
#import "RecordDateListViewController.h"

#import <AVFoundation/AVAudioSession.h>

#define NetInstanceManager [NetAPISet sharedInstance]
#define PlayerViewRatio (iPhone4 ? (3/4.0f):(65/72.0f))

#define trueSreenWidth  (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))
#define trueScreenHeight (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
static NSString * const kNotifyDevStatus    = @"NotifyDeviceStatus";

@interface PanoramaLivePlayerVC ()<UIScrollViewDelegate,GDVideoPlayerDelegate,GDNetworkSourceDelegate,GDNetworkStateDelegate,NSURLSessionDownloadDelegate,AudioRecorderDelegate>
{
    //是否显示‘控制杆’view
    BOOL _isShowJoystickView;
    
    //是否正在loading
    BOOL _isLoading;
    
    //是否连接上视频流
    BOOL _isRunning;
    
    //audio Flag
    BOOL _audioFlag;
    
    //videoFlag
    BOOL _videoFlag;
    
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

    
    BOOL isLeftScroll;
    CGFloat userContentOffsetX;
    int _oldPageIndex;

}

@property(nonatomic,strong)NSString *vr360_h264FilePath;

@property(nonatomic,strong)NSString *vr360_h264FileName;

@property(nonatomic,strong) NSArray *controlButtonNames;


@property(nonatomic,strong) NSArray *displayHorizontalBtnNames;

@property(nonatomic,strong)NSArray  *displayVerticalBtnNames;

@property(nonatomic,strong) NSMutableArray *controlButtonSelected;


/**
 开启自动巡航标志
 */
@property (assign, nonatomic)  int autoRotateSignal;


/**
 显示模式
 */
@property (assign, nonatomic)  int clickSig;


@property(nonatomic,strong)GOSOpenGLESVCViewController *displayVC;

//判断是否录像标志
@property(nonatomic,assign)__block BOOL isRecordflag;

/**
 *  声音开关 Button
 */
@property (strong, nonatomic)  UIButton *soundBtn;

/**
 *  操作提示 Label
 */
@property (strong, nonatomic)  UILabel *tipsLabel;

/**
 *  时间显示 Label
 */
@property (strong, nonatomic)  UILabel *timeLabel;

/**
 *  视频数据加载 Activity
 */
@property (strong, nonatomic)  UIActivityIndicatorView *loadVideoActivity;

/**
 *  播放控制 View
 */
@property (strong, nonatomic)  UIView *playControllView;
/**
 *  画面质量切换 Label
 */
@property (nonatomic,strong)  UILabel  *qualityChangeLabel;

/**
 *  画面质量切换 Button
 */
@property (strong, nonatomic)  UIButton *qualityChangeBtn;

/**
 *  录像列表 Button
 */
@property (strong, nonatomic)  UIButton *recordListBtn;

/**
 *  录像时间显示 View
 */
@property (strong, nonatomic)  UIView *recordTimeView;

/**
 *  录像闪烁提示 View
 */
@property (strong, nonatomic)  UIView *recordingShowView;

/**
 *  录像时间 Label
 */
@property (strong, nonatomic)  UILabel *recordTimeLabel;
/**
 重新请求按钮
 */
@property (nonatomic, strong) UIButton *reloadBtn;
/**
 离线按钮
 */
@property (nonatomic, strong) UIButton *offlineBtn;

/**
 摄像头关闭按钮
 */
@property (nonatomic, strong) UIButton *cameraOffBtn;

/** 摄像头打开切换器 */
@property (nonatomic, strong) UISwitch *cameraStatusSwitcher;

/**
 预览图片imgView
 */
@property (nonatomic, strong) UIImageView *previewImgView;

/**
 Camera Info Manager
 */
@property (nonatomic, strong) CameraInfoManager *cameraInfoManger;

/**
 播放器
 */
@property (nonatomic, strong) GDVideoPlayer *gdVideoPlayer;

/**
 *  设备设置model，用于和设置页面交互
 */
@property (nonatomic, strong) UISettingModel *refreshSettingModel;

/**
 *  设备初始设置model
 */
@property (nonatomic, strong) UISettingModel *settingModel;
/**
 *  获取设备能力resp
 */
@property (nonatomic, strong) CMD_GetDevAbilityResp *devAbilityCmd;
/**
 *  录像按钮点击声音 播放器
 */
@property (nonatomic, strong) AVAudioPlayer *recordBtnAudioPlayer;

/**
 *  拍照按钮点击声音 播放器
 */
@property (nonatomic, strong) AVAudioPlayer *snapShotBtnAudioPlayer;


/**
 对讲弹出的View
 */
@property(nonatomic,strong)UIImageView *talkingView;


/**
 record定时器
 */
@property (nonatomic, strong) NSTimer* recordIconTimer;

/**
 record 闪烁View定时器
 */
@property (nonatomic, strong) NSTimer* recordShowViewTimer;

/**
 云台控制队列
 */
@property (nonatomic, strong) dispatch_queue_t moveQueue;
/**
 切换清晰度指令超时定时器
 */
@property (nonatomic, strong)NSTimer *cmdTimeoutTimer;

/**
 平台UID
 */
@property (nonatomic, strong)NSString *platformUID;
/**
 温度定时器
 */
@property (nonatomic,strong)NSTimer *temperatureTimer;

/**
 温度imageView
 */
@property (nonatomic,strong)UIImageView *temperatureImageView;
/**
 温度Label
 */
@property (nonatomic,strong)UILabel *temperatureLabel;

/**
 是否全屏
 */
@property (nonatomic,assign)BOOL isLandSpace;

/**
 流超时定时器
 */
@property(nonatomic,strong)NSTimer *streamTimer;
/**
 拉流计时器
 */
@property(nonatomic,assign)NSUInteger streamTime;

@end

@implementation PanoramaLivePlayerVC

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.autoRotateSignal = YES;
        self.clickSig = -1;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self configUI];
    
    [self configModel];
    
    [self configEvents];
}

- (void) configModel{
    
}

- (void)setDeviceModel:(DeviceDataModel *)deviceModel{
    _deviceModel = deviceModel;
    _deviceId   = [deviceModel.DeviceId substringFromIndex:8];//截取掉下标7之后的字符串;
    _deviceName = deviceModel.DeviceName;
    _platformUID= deviceModel.DeviceId;
}

- (void)configEvents{
    //初始化音频
    [self audioInit];
  
    [self addBackgroundRunningEvent];
    
    //禁用锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

#pragma mark - 后台事件处理和网络监听处理
-(void)addBackgroundRunningEvent
{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    if (_curPanoramaType == PanoramaTypeLive) {
        //创建文件夹
        [self creatFolder];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(networkChanged:)
                                                     name:kRealReachabilityChangedNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(connectStatusChange:)
                                                     name:ADDeviceConnectStatusNotification
                                                   object:nil];
        //添加设备状态通知
        [self addDeviceStatusNotify];
    }
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
-(void)enterBackground
{
    if (_curPanoramaType == PanoramaTypeLive) {
        [self.displayVC stopPlay];
        [self stopConnecting];
    }else{
        [self removeGLKVC];
    }
    [self restoreDisplayModeToDefault];
}

- (void)restoreDisplayModeToDefault{
    
    _clickSig = self.displayVC.clickSig = self.displayVC.player.clickSig = -1;

    for (int i=0; i<self.displayHorizontalBtnNames.count; i++) {
        NSString *imageName = [NSString stringWithFormat:@"btn_360_%@_%@",self.displayHorizontalBtnNames[i],(i+1==1?@"select":@"normal")];
        UIButton *tempBtn = [self.displayHorizontalView viewWithTag:(i+1)];

        [tempBtn setImage:[UIImage imageNamed:imageName] forState:0];
    }

    for (int i=0; i<self.displayVerticalBtnNames.count; i++) {
        NSString *imageName = [NSString stringWithFormat:@"btn_360_%@_%@",self.displayVerticalBtnNames[i],(i+1==1?@"select":@"normal")];
        UIButton *tempBtn = [self.displayVerticalView viewWithTag:(i+1)];
        
        [tempBtn setImage:[UIImage imageNamed:imageName] forState:0];
    }
    
    [self.displayModeBtn setImage:[UIImage imageNamed:@"btn_360_asteroid_normal"] forState:0];
}

- (void)removeGLKVC{
    
    if (self.displayVC) {
        if (_curPanoramaType != PanoramaTypeLive) {
            [self.displayVC stopDecH264File];
        }else{
            [self.displayVC stopPlay];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.displayVC willMoveToParentViewController:nil];
            [self.displayVC.view removeFromSuperview];
            [self.displayVC removeFromParentViewController];
            
            self.displayVC = nil;
        });
    }
}

-(void)enterForeground
{
    if (_curPanoramaType == PanoramaTypeLive) {
        if (self.deviceModel.Status != 1) {
            //设备不在线
            [self.loadVideoActivity stopAnimating];
            self.loadVideoActivity.hidden = YES;
            [self showNewStatusInfo:DPLocalizedString(@"Play_Ipc_unonline")];
            self.reloadBtn.hidden = YES;
            self.offlineBtn.hidden = NO;
            self.playerView.layer.contents = [UIImage imageNamed:@""];
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
    }else{
        [self configForGLKVC];
        [self playH264Demo];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //刷新设备名称和导航条透明度
//    self.navigationController.navigationBar.translucent=YES;
    for (DeviceDataModel *model in [[DeviceManagement sharedInstance] deviceListArray]) {
        if ([model.DeviceId isEqualToString:self.deviceModel.DeviceId]) {
            _deviceName = model.DeviceName;
            break;
        }
    }
    
    if (_curPanoramaType == PanoramaTypeLive) {
        
        self.navigationItem.title = _deviceName;

        [self initAppearAction];
        if (self.deviceModel.Status == 1) {
            //在线
            //获取预览图片
			UIImage *preViewImg = [[MediaManager shareManager] coverWithDevId:self.deviceId fileName:nil deviceType:GosDevice360 position:PositionMain];
            if (preViewImg) {
                _playerView.layer.contents = (id)preViewImg.CGImage;
            }
        }
		[self addEnterForegroundNotifications];
    }else{
        self.navigationItem.title = _titleName;
//        [self configForGLKVC];
//        [self playH264Demo];
    }
}


- (void)playH264Demo{
    
    if([mFileManager fileExistsAtPath:self.vr360_h264FilePath]){
        [self.displayVC startToDecH264FileWithPort:0 filePath:self.vr360_h264FilePath];
    }else{
        [self downloadH264File];
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_curPanoramaType == PanoramaTypeLive) {
        if (self.displayVC) {
//            [self.gdVideoPlayer setPlayerView:self.playerView];
        }
    }else{
        [self configForGLKVC];
        [self playH264Demo];
    }
    
}



- (void)viewWillDisappear:(BOOL)animated
{
//    self.navigationController.navigationBar.translucent=NO;
    [super viewWillDisappear:animated];
    
    if (_curPanoramaType == PanoramaTypeLive) {
        [self leaveViewAction];
        //销毁拉流定时器
        [self stopStreamTimer];
		[self removeEnterForegroundNotifications];
    }else{
        [self removeGLKVC];
    }
    [self restoreDisplayModeToDefault];
}

- (void)dealloc
{
    [self releaseBtnSoundAudioPlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"PanoramaLive_Dealloc - dealloc");
}

#pragma mark - 横竖屏切换相关
-(BOOL)shouldAutorotate
{
    return YES;
}

#pragma mark -- 横竖屏方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
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

#pragma mark -- '对讲‘按钮事件
- (void)talkBtnAction:(id)sender
{
    NSLog(@"'对讲’事件");
    AVAuthorizationStatus audioAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (audioAuthStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            NSLog(@"granted:%d",granted);
        }];
        return;
    }
    
    if(_isRecordflag)
    {
        [SVProgressHUD showInfoWithStatus:DPLocalizedString(@"Play_record_no")];
        return;
    }
    
    if (_isRunning)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [NetInstanceManager setSpeakState:YES withUID:self.deviceId resultBlock:^(int result, int state, int cmd) {
                //
            }];
        });
        
        self.talkingView.hidden = NO;
        [self.view bringSubviewToFront:self.talkingView];
        
        NSLog(@"开始对讲--00");

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
        
//        [self showNewStatusInfo:DPLocalizedString(@"Play_Speaking_begin")];
        [self.recordBtnAudioPlayer play];

        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self.displayVC startAudioRecording];
        });

        NSLog(@"开始对讲--3");
    }
    else
    {
        [self showNewStatusInfo:DPLocalizedString(@"Play_camera_no_connect")];
    }
}


- (void)talkEndAction{
    if (_isRunning)
    {
        //开启声音
        _soundBtn.selected = YES;
        [_soundBtn setImage:[UIImage imageNamed:@"btn_360_audio_on"] forState:UIControlStateNormal];

        [SVProgressHUD dismiss];
        self.talkingView.hidden = YES;
        [self.view sendSubviewToBack:self.talkingView];
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self.displayVC stopAudioRecording];
        });
    }
    else
    {
        [SVProgressHUD dismiss];
        self.talkingView.hidden = YES;
        [self.view sendSubviewToBack:self.talkingView];
        [self showNewStatusInfo:DPLocalizedString(@"Play_camera_no_connect")];
    }

}

#pragma mark - 全屏代理
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
            
            [self.playerView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.edges.equalTo(self.view);
            }];
            
            [self.controlViewBg mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.playerView.mas_bottom);
                make.left.right.equalTo(self.view);
                make.height.equalTo(@(0));
            }];
            
            [self.controlViewBg mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.playerView.mas_bottom);
                make.left.right.equalTo(self.view);
                make.height.equalTo(@(0));
            }];
            
            [self.separatorView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.controlViewBg.mas_bottom);
                make.left.right.equalTo(self.view);
            }];
            
            [self.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.controlViewBg.mas_bottom).offset(1);
                make.left.right.equalTo(self.view);
                make.height.equalTo(@(0));
            }];

            
            self.bottomView.hidden = YES;
            self.controlViewBg.hidden = YES;
            self.separatorView.hidden = YES;
            
            _talkingView.hidden=YES;
//            [self talkEndAction];
            if (self.displayVC) {
                [self.displayVC updatePlayerViewFrame:CGRectMake(0, 0, trueScreenHeight, trueSreenWidth)];
            }
        }else{
            _isLandSpace = NO;
            [self.navigationController setNavigationBarHidden:NO animated:NO];
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
            [[UIApplication sharedApplication] setStatusBarHidden:NO];
            
            //半屏幕约束
            [self.playerView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.view).offset(0);
                make.left.right.equalTo(self.view);
                make.height.mas_equalTo(self.view.mas_width).multipliedBy(PlayerViewRatio);
            }];

            [self.controlViewBg mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.playerView.mas_bottom);
                make.left.right.equalTo(self.view);
                make.height.equalTo(self.view.mas_height).multipliedBy(150.0/1320);
            }];
            
            [self.separatorView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.controlViewBg.mas_bottom);
                make.left.right.equalTo(self.view);
                make.height.equalTo(@(1));
            }];

            [self.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.controlViewBg.mas_bottom).offset(1);
                make.left.right.bottom.equalTo(self.view);
            }];

            self.bottomView.hidden = NO;
            self.controlViewBg.hidden = NO;
            self.separatorView.hidden = NO;

            if (self.displayVC) {
                [self.displayVC updatePlayerViewFrame:CGRectMake(0, 0, trueSreenWidth, trueSreenWidth * PlayerViewRatio)];
            }
        }
        
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
    }];
}


#pragma mark 演示视频
- (NSString*)vr360_h264FileName{
    
    if (!_vr360_h264FileName) {
        if (_curPanoramaType == PanoramaType180) {
            _vr360_h264FileName = @"stream_chn0_1.h264";
        }else{
            _vr360_h264FileName = @"kk_stream_chn0_5.h264";
        }
    }
    return _vr360_h264FileName;
}

- (NSString*)vr360_h264FilePath{
    
    if (!_vr360_h264FilePath) {
        _vr360_h264FilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:(_curPanoramaType == PanoramaType180)?@"stream_chn0_1.h264":@"kk_stream_chn0_5.h264"] ;
    }
    return _vr360_h264FilePath;
}

- (void)downloadH264File{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.loadVideoActivity startAnimating];
        self.loadVideoActivity.hidden = NO;
        [self.playerView bringSubviewToFront:self.loadVideoActivity];
    });

	NSString *baseURLStr = nil;
	
//	ServerAddress *upsAddr = [ServerAddress yy_modelWithDictionary:[mUserDefaults objectForKey:@"UPSAddress"]];
//	if (upsAddr.Address.length >0) {
//		baseURLStr = [NSString stringWithFormat:@"http://%@:%d/H264",upsAddr.Address,upsAddr.Port];
//	}else{
		baseURLStr = @"http://119.23.130.8:5302/H264/";
//	}
    NSString *urlStr = [baseURLStr stringByAppendingString:self.vr360_h264FileName];
    
    NSURL *url = [NSURL URLWithString:urlStr];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    
    //3.创建session ：注意代理为NSURLSessionDownloadDelegate
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:req];
    
    [task resume];
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location{
    NSLog(@"downloadedLoc:%@",location);
    
    //1 文件存在的话先移除
    if ([mFileManager fileExistsAtPath:self.vr360_h264FilePath]) {
        
        [mFileManager removeItemAtPath:self.vr360_h264FilePath error:nil];
    }
    
    //2 剪切文件
    NSError *error;
    [[NSFileManager defaultManager]moveItemAtURL:location toURL:[NSURL fileURLWithPath:self.vr360_h264FilePath] error:&error];
    NSLog(@"moveToPath:%@",self.vr360_h264FilePath);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.loadVideoActivity stopAnimating];
        self.loadVideoActivity.hidden = YES;
    });
    
    if (!error) {//No error
        [self.displayVC startToDecH264FileWithPort:0 filePath:self.vr360_h264FilePath];
    }else{
        NSLog(@"moveFileError:%@",error.description);
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    NSLog(@"progress:%4.2f",totalBytesWritten*1.0/totalBytesExpectedToWrite);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"network_error") ];
        });
    }
}

#pragma mark UI 开始
- (void)configUI{

    [self configControlView];
    
    [self addSubViews];
    
    [self configLayout];
    
    [self configNavItem];
    
    [self configButtons];
}

- (void)configLayout{
    
    if (_curPanoramaType == PanoramaType180) {
        [self setupDisplayVerticalView];
    }else{
        [self setupDisplayHorizontalView];
    }
    self.playerView.backgroundColor = [UIColor blackColor];
    
    [self.loadVideoActivity mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.playerView.mas_centerY);
        make.centerX.equalTo(self.playerView.mas_centerX);
        make.width.height.equalTo(@50);
    }];
    
    [self.recordTimeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.playerView).offset(-30);
        make.top.equalTo(self.playerView).offset(10);
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
    
    //reloadBtn
    [self.reloadBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.centerX.equalTo(self.playerView);
        make.width.equalTo(@200);
        make.height.equalTo(@30);
    }];
    
    [self.offlineBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.centerX.equalTo(self.playerView);
        make.width.equalTo(@200);
        make.height.equalTo(@30);
    }];
    
    [self.cameraOffBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.centerX.equalTo(self.playerView);
        make.width.equalTo(@250);
        make.height.equalTo(@30);
    }];
	
	[self.cameraStatusSwitcher mas_makeConstraints:^(MASConstraintMaker *make) {
		make.top.equalTo(self.cameraOffBtn.mas_bottom);
		make.centerX.equalTo(self.cameraOffBtn);
		make.width.equalTo(@50);
		make.height.equalTo(@30);
	}];

}

- (void)addSubViews{
    
    [self.playerView addSubview:self.loadVideoActivity];

    [self.view addSubview:self.recordTimeView];
    
    [self.recordTimeView addSubview:self.recordingShowView];
    [self.recordTimeView addSubview:self.recordTimeLabel];
    
    [self.view addSubview:self.reloadBtn];
    [self.view addSubview:self.offlineBtn];
    [self.view addSubview:self.cameraOffBtn];
	[self.view addSubview:self.cameraStatusSwitcher];

}

-(void)configNavItem
{
    if (_curPanoramaType == PanoramaTypeLive) {
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
}

//
- (void)configButtons{
    self.talkBtn.userInteractionEnabled      = NO;
    self.recordingBtn.userInteractionEnabled = NO;
    self.snapshotBtn.userInteractionEnabled  = NO;
    
    [_talkBtn setImage:[UIImage imageNamed:@"btn_talk_disable"] forState:UIControlStateNormal];
    [_recordingBtn setImage:[UIImage imageNamed:@"NvrRecordDisable"] forState:UIControlStateNormal];
    [_snapshotBtn setImage:[UIImage imageNamed:@"btn_snapshot_disable"] forState:UIControlStateNormal];
    
    if (_curPanoramaType !=PanoramaTypeLive) {
        self.qualityChangeBtn.userInteractionEnabled = NO;

    }else{
        
//        [_talkBtn setImage:[UIImage imageNamed:@"PlaySpeakNormal"] forState:UIControlStateNormal];
//        [_recordingBtn setImage:[UIImage imageNamed:@"NvrRecordNormal"] forState:UIControlStateNormal];
//        [_snapshotBtn setImage:[UIImage imageNamed:@"PlayCameraNormal"] forState:UIControlStateNormal];

        [_talkBtn addTarget:self action:@selector(talkBtnAction:) forControlEvents:UIControlEventTouchDown];
        [_talkBtn addTarget:self action:@selector(talkEndAction) forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:self.talkingView];
        [self.talkingView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.centerY.equalTo(self.view);
            make.width.height.mas_equalTo(120);
        }];
    }
    
    _snapshotLabel.text = DPLocalizedString(@"play_Snapshot");
    _talkLabel.text =  DPLocalizedString(@"play_Talk");
    _recordingLabel.text =  DPLocalizedString(@"VR360_Record");
}

- (void)showCameraInfoView{
    NSLog(@"点击设备设置按钮");
    SettingViewController * setVC =[[SettingViewController alloc]init];
    setVC.model = _deviceModel;
    [self.navigationController pushViewController:setVC animated:YES];
}

/**
 吊装模式
 */
- (void)setupDisplayHorizontalView{

    _displayHorizontalView = [[UIImageView alloc]initWithFrame:CGRectMake(0,0,60,233)];
    _displayHorizontalView.image = [UIImage imageNamed:@"btn_360_displayModeBg_normal"];
    
    [self.view addSubview:_displayHorizontalView];
    [_displayHorizontalView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.width.equalTo(self.view).multipliedBy(1.0/6);
        make.height.mas_equalTo(200*SCREEN_WIDTH/360); //_displayHorizontalView.mas_width).multipliedBy(233/60.0);
        make.centerX.equalTo(self.displayModeBtn);
//        make.trailing.mas_equalTo(self.view).offset(12*360.0/SCREEN_WIDTH);
        make.bottom.mas_equalTo(self.controlViewBg.mas_top);
    }];
    _displayHorizontalView.hidden = YES;
    _displayHorizontalView.userInteractionEnabled = YES;
    
    
    for (int i=0; i<self.displayHorizontalBtnNames.count; i++) {
        NSString *imageName = [NSString stringWithFormat:@"btn_360_%@_%@",self.displayHorizontalBtnNames[i],(i==0?@"select":@"normal")];
        
        EnlargeClickButton *btn = [[EnlargeClickButton alloc]initWithFrame:CGRectMake(0, 0, 31, 31)];
        [btn setImage:[UIImage imageNamed:imageName] forState:0];
        [btn addTarget:self action:@selector(displayHorizontalBtnTouchUpAction:) forControlEvents:UIControlEventTouchUpInside];
        [btn addTarget:self action:@selector(displayHorizontalBtnTouchDownAction:) forControlEvents:UIControlEventTouchDown];
        [btn setTag:(i+1)];//排除Tag为0的_displayHorizontalView
    
        [self.displayHorizontalView addSubview:btn];
        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.displayHorizontalView);
            make.width.height.mas_equalTo(31*SCREEN_WIDTH/360);
            make.top.equalTo(self.displayHorizontalView.mas_top).offset(12+i*46*SCREEN_WIDTH/360);
        }];
    }
}

//UI: @[@"asteroid",@"cylinder",@"twoView",@"fourView"]
//clickSig(Model): 小行星，桶形状,广角，二画面，四画面
- (void)displayHorizontalBtnTouchDownAction:(id)sender{
    UIButton *btn = (UIButton*)sender;
    switch (btn.tag-1) {
        case 0:  //asteroid
        {
            self.displayVC.player.clickSig = DisplayModeAsteroid;
            break;
        }
        case 1:  //cylinder
        {
            self.displayVC.player.clickSig = DisplayModeCylinder;
            break;
        }
        case 2:  //twoView
        {
            self.displayVC.player.clickSig = DisplayModeTwoView;
            break;
        }
        case 3:  //fourView
        {
            self.displayVC.player.clickSig = DisplayModeFourView;
            break;
        }
        default:
            break;
    }
    _clickSig = self.displayVC.clickSig = self.displayVC.player.clickSig;
    
    [self.displayVC.player gosPanorama_updateClickSignal];
//    [self.displayVC.player gosPanorama_updateWithYUVData:nil];
}

- (void)displayHorizontalBtnTouchUpAction:(id)sender{
    UIButton *btn = (UIButton*)sender;
    int tag = btn.tag;
    
    NSString *tempImageName = nil;
    for (int i=0; i<self.displayHorizontalBtnNames.count; i++) {
        NSString *imageName = [NSString stringWithFormat:@"btn_360_%@_%@",self.displayHorizontalBtnNames[i],(i+1==tag?@"select":@"normal")];
        
        UIButton *tempBtn = [self.displayHorizontalView viewWithTag:(i+1)];
        [tempBtn setImage:[UIImage imageNamed:imageName] forState:0];
        
        if (i+1==tag) {
            tempImageName = [imageName stringByReplacingOccurrencesOfString:@"select" withString:@"normal"];
        }
    }
    
    //更新信号参数
    self.displayVC.player.clickSig = -1;
    [self.displayVC.player gosPanorama_updateClickSignal];

    //更新显示模式按钮
    [self.displayModeBtn setImage:[UIImage imageNamed:tempImageName] forState:0];
}


//360:小行星 圆柱 二画面 四画面
//180:小行星 广角
-(NSArray*)displayHorizontalBtnNames{
    if (!_displayHorizontalBtnNames) {
        _displayHorizontalBtnNames = @[@"asteroid",@"cylinder",@"twoView",@"fourView"];
    }
    return _displayHorizontalBtnNames;
}

-(NSArray*)displayVerticalBtnNames{
    if (!_displayVerticalBtnNames) {
        _displayVerticalBtnNames = @[@"asteroid",@"wideAngle"];
    }
    return _displayVerticalBtnNames;
}

/**
 侧装模式
 */
- (void)setupDisplayVerticalView{
    
    _displayVerticalView = [[UIImageView alloc]initWithFrame:CGRectMake(0,0,60,164)];
    _displayVerticalView.image = [UIImage imageNamed:@"btn_360_installModeBg_normal"];
    
    [self.view addSubview:_displayVerticalView];
    [_displayVerticalView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.width.equalTo(self.view).multipliedBy(1.0/6);
        make.height.mas_equalTo(115*SCREEN_WIDTH/360);
        make.centerX.equalTo(self.displayModeBtn);
        make.bottom.equalTo(self.controlViewBg.mas_top);
    }];
    
    for (int i=0; i< self.displayVerticalBtnNames.count; i++) {
        NSString *imageName = [NSString stringWithFormat:@"btn_360_%@_%@",self.displayVerticalBtnNames[i],(i==0?@"select":@"normal")];
        
        EnlargeClickButton *btn = [[EnlargeClickButton alloc]initWithFrame:CGRectMake(0, 0, 31, 31)];
        [btn setImage:[UIImage imageNamed:imageName] forState:0];
        [btn addTarget:self action:@selector(displayVerticalBtnTouchUpAction:) forControlEvents:UIControlEventTouchUpInside];
        [btn addTarget:self action:@selector(displayVerticalBtnTouchDownAction:) forControlEvents:UIControlEventTouchDown];

        [btn setTag:(i+1)];//排除Tag为0的_displayVerticalView
        
        [_displayVerticalView addSubview:btn];
        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.displayVerticalView);
            make.width.height.mas_equalTo(31*SCREEN_WIDTH/360);
            make.top.equalTo(self.displayVerticalView.mas_top).offset(20+i*(50)*SCREEN_WIDTH/360);
        }];
    }
    
    _displayVerticalView.hidden = YES;
    _displayVerticalView.userInteractionEnabled = YES;
}


- (void)displayVerticalBtnTouchUpAction:(id)sender{
    UIButton *btn = (UIButton*)sender;
    int tag = btn.tag;
    
    NSString *tempImageName = nil;
    for (int i=0; i<self.displayVerticalBtnNames.count; i++) {
        NSString *imageName = [NSString stringWithFormat:@"btn_360_%@_%@",self.displayVerticalBtnNames[i],(i+1==tag?@"select":@"normal")];
        
        UIButton *tempBtn = [self.displayVerticalView viewWithTag:(i+1)];
        [tempBtn setImage:[UIImage imageNamed:imageName] forState:0];
        
        if (i+1==tag) {
            tempImageName = [imageName stringByReplacingOccurrencesOfString:@"select" withString:@"normal"];
        }
    }
    
    //更新信号参数
    self.displayVC.player.clickSig = -1;
    [self.displayVC.player gosPanorama_updateClickSignal];

    //更新显示模式按钮
    [self.displayModeBtn setImage:[UIImage imageNamed:tempImageName] forState:0];
}

//UI: @[@"asteroid",@"wideAngle"]
//clickSig(Model): 小行星，桶形状,广角，二画面，四画面
- (void)displayVerticalBtnTouchDownAction:(id)sender{
    UIButton *btn = (UIButton*)sender;
    switch (btn.tag-1) {
        case 0:  //asteroid
        {
            self.displayVC.player.clickSig = DisplayModeVerticalAsteroid;
            break;
        }
        case 1:  //wideAngle
        {
            self.displayVC.player.clickSig = DisplayModeVerticalWideAngle;
            break;
        }
        default:
            break;
    }
    _clickSig = self.displayVC.clickSig = self.displayVC.player.clickSig;
    [self.displayVC.player gosPanorama_updateClickSignal];
//    [self.displayVC.player gosPanorama_updateWithYUVData:nil];
}


//- (void)installModeBtnAction:(id)sender{
//    
//    UIButton *btn = (UIButton*)sender;
//    UIImage *tempImage = nil;
//    NSString *imageName = nil;
//    switch (btn.tag) {
//        case 1:  //选中水平
//        {
//            for (int i=1; i<3; i++) {
//                
//                if (i==1) {
//                    imageName = @"btn_360_installMode_horizontal_select";
//                }else{
//                    imageName = @"btn_360_installMode_vertical_normal";
//                }
//                
//                UIButton *btn = [self.displayVerticalView viewWithTag:(i)];
//                [btn setImage:[UIImage imageNamed:imageName] forState:0];
//                
//                if (i==1) {
//                    tempImage = [UIImage imageNamed:[imageName stringByReplacingOccurrencesOfString:@"select" withString:@"normal"]];
//                }
//            }
//            break;
//        }
//        case 2:  //选中垂直
//        {
//            for (int i=1; i<3; i++) {
//                
//                if (i==1) {
//                    imageName = @"btn_360_installMode_horizontal_normal";
//                }else{
//                    imageName = @"btn_360_installMode_vertical_select";
//                }
//                UIButton *btn = [self.displayVerticalView viewWithTag:(i)];
//                [btn setImage:[UIImage imageNamed:imageName] forState:0];
//                
//                if (i==2) {
//                    tempImage = [UIImage imageNamed:[imageName stringByReplacingOccurrencesOfString:@"select" withString:@"normal"]];
//                }
//            }
//            break;
//        }
//        default:
//            break;
//    }
//    //更新安装模式按钮
//}


#pragma mark= PlayerView
- (void)configPlayerView{
}

- (void)configForGLKVC{
    if (!self.displayVC) {
        self.displayVC = [[GOSOpenGLESVCViewController alloc] init];
        self.displayVC.audioDelegate = self;
        CGFloat displayW = SCREEN_WIDTH;
        CGFloat displayH = SCREEN_WIDTH*PlayerViewRatio;
        
        self.displayVC.autoRotSig = _autoRotateSignal;
        self.displayVC.clickSig = _clickSig;
		
		self.displayVC.initialMode = _curPanoramaType==PanoramaType180? InitialModeVertical: InitialModeHorizontal;
		
        [self.displayVC configPlayerWidth:displayW height:displayH];
        
        self.playerView.multipleTouchEnabled = YES;
        [self.playerView addSubview:self.displayVC.view];
        [self addChildViewController:self.displayVC];
        [self.displayVC didMoveToParentViewController:self];
        
        self.displayVC.view.frame = CGRectMake(0, 0, displayW, displayH);
        [self.displayVC.view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.playerView);
        }];
        self.displayVC.deviceId = self.deviceId;
    }
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
        [self showNewStatusInfo:DPLocalizedString(@"Play_Ipc_unonline")];
        self.reloadBtn.hidden = YES;
        self.offlineBtn.hidden = NO;
        self.playerView.layer.contents = [UIImage imageNamed:@""];
        _isRunning = NO;
    }
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
    }
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
    
    if (!self.displayVC) {
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

- (void)showConnectStateWithUID:(NSString*)UUID state:(NotificationType)type error_ret:(int)error_ret
{
    
    if (error_ret < 0) {
        if (_reloadBtn.hidden) {
            dispatch_async_on_main_queue(^{
                self.reloadBtn.hidden = NO;
                //去除预览图片
                self.playerView.layer.contents = (id)[UIImage imageNamed:@""];
                [self.loadVideoActivity stopAnimating];
                self.loadVideoActivity.hidden = YES;
            });
        }
        
        if (type == NotificationTypeDisconnect) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showNewStatusInfo:DPLocalizedString(@"localizied_293")];
                //去除预览图片
                self.playerView.layer.contents = (id)[UIImage imageNamed:@""];
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
                    self.playerView.layer.contents = (id)[UIImage imageNamed:@""];
                }
                
            });
        }
    }
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
        _recordingShowView.hidden = YES;
    }
    return _recordingShowView;
}

/**
 *  录像文字REC Label
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
 *  提醒区域label
 */
- (UILabel *)tipsLabel{
    if (!_tipsLabel) {
        _tipsLabel = [[UILabel alloc]init];
        _tipsLabel.textColor = [UIColor colorWithHexString:@"#262324"];
        _tipsLabel.font = [UIFont systemFontOfSize:12.0];
        _tipsLabel.textAlignment = NSTextAlignmentLeft;
        _tipsLabel.alpha = 0.0f;
    }
    return _tipsLabel;
}

/**
 闪现提示Label
 */
-(void)showNewStatusInfo:(NSString*)info
{
    [SVProgressHUD showInfoWithStatus:info];
    [SVProgressHUD dismissWithDelay:2];
    
    self.tipsLabel.text = info;
    [UIView animateWithDuration:0.3f delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.tipsLabel.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3f delay:2.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.tipsLabel.alpha = 0.0;
        } completion:nil];
    }];
}

#pragma mark - 获取实时流
-(void)getLiveStreamData
{
    //获取设置
    [self getDeviceSetting:nil];
    
    //获取摄像头开关
    [self getCameraSwitchStatus];
    
    //开始拉流计时
    [self startStreamTimer];
    
    _isLoading = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [NetInstanceManager startGettingVideoDataWithUID:self.deviceId videoType:2 resultBlock:^(int result, int state) {
            
        }];
    });
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
        //重新连接
        [NetInstanceManager reconnect:self.deviceId andBlock:^(int result, int state, int cmd) {
            
        }];
    }
}



-(void)startStreamTimer
{
    if ( _streamTimer ==nil)
    {
        __weak typeof(self) weakSelf = self;
        self.streamTimer =  [NSTimer yyscheduledTimerWithTimeInterval:1 block:^(NSTimer * _Nonnull timer) {
            weakSelf.streamTime += 1;
            if (weakSelf.streamTime > 6) {
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

/**
 超过五秒拉不了流，就开始重新拉流
 */
- (void)reloadStream{
    if (!self.offlineBtn.hidden || !self.reloadBtn.hidden || _isCameraOff) {
        //离线和重新加载情况下 外加摄像头关闭 return
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

#pragma mark - 离开界面操作

- (void)leaveViewAction{
    //断开流连接
    [self stopConnecting];
}


-(void)stopConnecting
{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        //销毁播放器
        [self removGDPlayer];
        
        //停止播放音频
        [self releaseBtnSoundAudioPlayer];
        //停止视频录制
        [self stopVideoRecord];
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

/**
 开始播放音频
 */
-(BOOL)audioStart
{
    _audioFlag = YES;
    if (self.displayVC) {
        [NetInstanceManager startAudioData:self.deviceId andBlock:^(int value, int state,int cmd) {
        }];
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.displayVC openLiveAudio];
    });
    return YES;
}

/**
 停止播放音频
 */
-(BOOL)audioStop
{
    _audioFlag = NO;
    if (self.displayVC) {
        [NetInstanceManager stopAudioData:self.deviceId andBlock:^(int value, int state,int cmd) {
        }];
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.displayVC closeLiveAudio];
    });

    return YES;
}
/**
 停止视频录像
 */
-(void)stopVideoRecord
{
    if (_isRecordflag) {
        [self.recordBtnAudioPlayer play];
        [self.displayVC stopRecording];
        [self recordTimerStop];
        if (_speakFlag == YES)
        {
        }
        else
        {
            [NSThread sleepForTimeInterval:0.01];
            if (_audioFlag) {
                [self audioStop];
            }
            
        }
        _isRecordflag = NO;
        dispatch_async_on_main_queue(^{
            self.recordTimeView.hidden =YES;
            self.recordingShowView.hidden = YES;
            [self.recordShowViewTimer  invalidate];
            self.recordShowViewTimer =nil;
            //静音
            _soundBtn.selected = NO;
            [_soundBtn setImage:[UIImage imageNamed:@"btn_360_audio_off"] forState:UIControlStateNormal];
            //关闭语音
            //            [self showNewStatusInfo:DPLocalizedString(@"record_end")];
        });
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //设置录像按钮
            [self.recordingBtn setImage:[UIImage imageNamed:@"NvrRecordNormal"] forState:UIControlStateNormal];
            self.recordingBtn.selected = NO;
        });
    }
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
            [self.displayVC stopRecording];
            [self recordTimerStop];
            //            [self showNewStatusInfo:DPLocalizedString(@"record_end")];
            _isRecordflag = !_isRecordflag;
        }
    });
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
        
//        _cameraOffBtn.backgroundColor = [UIColor blackColor];
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
}


//移除预览
- (void)removePreview{
    dispatch_async_on_main_queue(^{
        
        self.playerView.layer.contents = [UIImage imageNamed:@""];
        
        self.reloadBtn.hidden = YES;
        self.cameraOffBtn.hidden = NO;
		self.cameraStatusSwitcher.hidden = NO;

        self.soundBtn.userInteractionEnabled = NO;
        [_soundBtn setImage:[UIImage imageNamed:@"btn_360_audio_off"] forState:UIControlStateNormal];
        self.talkBtn.userInteractionEnabled = NO;
        [_talkBtn setImage:[UIImage imageNamed:@"btn_talk_disable"] forState:UIControlStateNormal];
        self.snapshotBtn.userInteractionEnabled = NO;
        [_snapshotBtn setImage:[UIImage imageNamed:@"btn_snapshot_disable"] forState:UIControlStateNormal];

        self.recordingBtn.userInteractionEnabled = NO;
        [self.recordingBtn setImage:[UIImage imageNamed:@"NvrRecordDisable"] forState:UIControlStateNormal];
        
        [self.loadVideoActivity stopAnimating];
        //停止拉流
        [self stopConnecting];
    });
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

#pragma mark - GDPlayer
/**
 创建GDPlayer
 */
- (void)configGDPlayer{
    
    [self configForGLKVC];
    if (!_gdVideoPlayer) {

    }
}
/**
 移除GDPlayer
 */
- (void)removGDPlayer{
    
    [self removeGLKVC];
    
    if (_gdVideoPlayer) {
    }
}


#pragma mark - NetAPISet
/**
 设置全局NetAPI代理
 */
- (void)setApiNetDelegate{
    NetAPISet *apiSet = [NetAPISet sharedInstance];
    apiSet.sourceDelegage = self;
    //    apiSet.networkDelegate = self;
}
/**
 设置全局NetAPI代理
 */
- (void)RemoveApiNetDelegate{
    NetAPISet *apiSet = [NetAPISet sharedInstance];
    apiSet.sourceDelegage = nil;
    //    apiSet.networkDelegate = nil;
}

#pragma mark -GDNetWork代理  获取视频数据回调
- (void)getVideoData:(unsigned char *)pContentBuffer
          dataLength:(int)length
           timeStamp:(int)timeStamp
              framNo:(unsigned int)framNO
           frameRate:(int)frameRate
            isIFrame:(BOOL)isIFrame
            deviceID:(NSString *)deviceId
           avChannel:(int)avChannel
{
    
    if ([self.deviceId isEqualToString:deviceId])
    {
        if (isIFrame) {
            //            NSLog(@"Waiting for get IFrame %d\n",framNO);
            if (!_isLoading)
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
                    [self enableRecordListBtn];
                    [self enableRecordingBtn];
                    [self enableTalkBtn];
                });
                _isLoading = YES;
            }
        }
        [self.displayVC AddVideoFrame:pContentBuffer len:length ts:timeStamp framNo:framNO frameRate:frameRate iFrame:isIFrame  andDeviceUid:deviceId];

    }
    else{
        if (isIFrame) {
            NSLog(@"Waiting for else get IFrame %d\n",framNO);
        }
    }
    
}

//初始化音频任务
- (void)audioInit{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
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
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [NetInstanceManager startSpeakThread:self.deviceId andFilePath:filePath];
            });

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
    [self.displayVC AddAudioFrame:buffer len:len framNo:framNO isIframe:0 timeStamp:0];
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
//                    [self showNewStatusInfo:string];
					[self.displayVC openLiveAudio];
                });
                _audioFlag = YES;
                if (self.displayVC) {
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
                    //取消这个对讲
//                    [self showNewStatusInfo:DPLocalizedString(@"Speaking_success")];
                    [self.displayVC openLiveAudio];
                });
                _audioFlag = YES;
                if (self.displayVC) {
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
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"localizied_9")];
        }
        else
        {
            [self showNewStatusInfo:DPLocalizedString(@"save_image")];
        }
    });
}


#pragma mark-保存录像到相册的回调
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{

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

- (dispatch_queue_t)moveQueue{
    if (!_moveQueue) {
        _moveQueue = dispatch_queue_create("moveQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return _moveQueue;
}

#pragma mark - 切换大小码流,高清流畅
-(void)changeDisplayQuality:(NSUInteger)quality andUID:(NSString *)UID;
{
    dispatch_async(self.moveQueue,^{
        if (UID != self.deviceId){
            //NVR
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
                [NetInstanceManager sendCmd:CmdModel_Camera_VIDEOQUALITY andParam: quality==0?Camera_VIDEOQUALITY_MAX:Camera_VIDEOQUALITY_HIGH andUID:UID andChannel:0 andBlock:^(int value,int state,int cmd) {
                    
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //切换高清标清按钮
                        if (state >= 0) {
                            strongSelf->_segmentIndex = quality;
                            if (strongSelf->_segmentIndex==1) {
                                strongSelf.qualityChangeLabel.text = DPLocalizedString(@"Play_SD");
                            }
                            else{
                                strongSelf.qualityChangeLabel.text = DPLocalizedString(@"Play_HD");
                            }
							[strongSelf restoreDisplayModeToDefault];
//                                [strongSelf removeGLKVC];
//                                [strongSelf configForGLKVC];
//                            });
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
            self.playerView.layer.contents = (id)[UIImage imageNamed:@""];
            self.reloadBtn.hidden = YES;
            self.offlineBtn.hidden = NO;
        }
        
    });
}



#pragma mark - 设备能力值获取设置
//0 屏蔽 NO
//1 开启 YES
-(void)getDeviceSetting:(NSString *)UID
{
    UISettingModel *model = [[UISettingManagement sharedInstance] getSettingModel:self.platformUID];
    if([model.ability_id isEqualToString:self.platformUID])
    {
        //获取设置UI
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
        
        //设置摇杆

        self.refreshSettingModel=[[UISettingModel alloc]init];
        self.refreshSettingModel=[mode copy];
        NSLog(@"%@",self.refreshSettingModel.ability_id);
        NSLog(@"%d",mode.ability_pir);
    
    });
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
            [self.soundBtn setImage:[UIImage imageNamed:@"btn_360_audio_on"]forState:UIControlStateNormal];
        }
        else{
            [self.soundBtn setImage:[UIImage imageNamed:@"btn_360_audio_off"]forState:UIControlStateNormal];
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
//        [self enableTalkBtn];
    }
}

#pragma mark - 按钮状态使能


- (void)enableRecordListBtn{
    dispatch_async_on_main_queue(^{
        _recordListBtn.userInteractionEnabled = YES;
        [_recordListBtn setImage:[UIImage imageNamed:@"btn_360_playback_normal"] forState:UIControlStateNormal];
        [_recordListBtn setImage:[UIImage imageNamed:@"btn_360_playback_select"] forState:UIControlStateHighlighted];
        NSLog(@"ADTest-----------------------------2");
    });
}

- (void)enableRecordingBtn{
    dispatch_async_on_main_queue(^{
        _recordingBtn.userInteractionEnabled = YES;
        [_recordingBtn setImage:[UIImage imageNamed:@"NvrRecordNormal"] forState:UIControlStateNormal];
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
        [_soundBtn setImage:[UIImage imageNamed:@"btn_360_audio_off"] forState:UIControlStateNormal];
    });
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




#pragma mark= UIScrollView

/**
 声音 巡航 安装模式 显示模式 回放 清晰度
 @[@"audio",@"cruise",@"installMode",@"displayMode",@"playback",@"videoQuality"]
 btn_360_cruise_normal
 btn_360_playback_normal
 */
- (void)configControlView{
    
    
    CGFloat leadingSpace = 25*SCREEN_WIDTH/360;
    CGFloat buttonW = 31*SCREEN_WIDTH/360;
    CGFloat spacingBetweenButtons = 62*SCREEN_WIDTH/360;
    
    //第四个和第5个之间相差50 而非62 所以要减去12(i>3)
    CGFloat missingW = 12*SCREEN_WIDTH/360;
    
    for (int i=0; i<6; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(leadingSpace+i*(buttonW+spacingBetweenButtons)-(i>3?missingW:0), 7, buttonW, buttonW);
        [btn setTag:i];
        [btn addTarget:self action:@selector(controlButtonsAction:) forControlEvents:UIControlEventTouchUpInside];
        
        //
        NSString *imagName = [NSString stringWithFormat:@"btn_360_%@_normal",self.controlButtonNames[i] ];
        
        if (i==0) {
            imagName = @"btn_360_audio_off";
            self.soundBtn = btn;
        }
        if (i== 2) {
            
            imagName = [NSString stringWithFormat:@"btn_360_installMode_%@_select",_curPanoramaType==PanoramaType180?@"vertical":@"horizontal"];
            self.installModeBtn = btn;
        }
        
        if(i == 3){
            imagName = @"btn_360_asteroid_normal";
            self.displayModeBtn = btn;
        }
        
        
        UIImage *image = [UIImage imageNamed:imagName];
        [btn setImage:image forState:0];
        
        
        UILabel *label      = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 17)];
        label.font          = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        label.textColor     = BACKCOLOR(131, 131, 131, 1);
        label.textAlignment = NSTextAlignmentCenter;
        label.text = DPLocalizedString( [@"VR360_" stringByAppendingString:self.controlButtonNames[i]] );
        
        [self.controlScrollView addSubview:btn];
        [self.controlScrollView addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(btn.mas_bottom).mas_offset(1);
            make.centerX.equalTo(btn);
        }];
        
        if (i==4) {
            self.recordListBtn = btn;
            self.recordListBtn.userInteractionEnabled = NO;
        }
        
        if (i==5) {
            self.qualityChangeBtn = btn;
            [self configQualityChangeLabel];
        }
    }
    [self configScrollView];
}

- (void)configQualityChangeLabel{
    UILabel *label      = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 31, 31)];
    label.font          = [UIFont fontWithName:@"PingFangSC-Regular" size:11];
    label.textColor     = BACKCOLOR(131, 131, 131, 1);
    label.textAlignment = NSTextAlignmentCenter;
    label.text = DPLocalizedString(@"Play_HD");
    
    [self.controlScrollView addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.qualityChangeBtn);
        make.center.equalTo(self.qualityChangeBtn);
    }];
    _qualityChangeLabel = label;
}

- (void)configScrollView{
    [self.pageNumberIndicator setImage:[UIImage imageNamed:@"btn_360_sliding_block_0"]];

    self.controlScrollView.backgroundColor = [UIColor clearColor];
    self.controlScrollView.bounces = YES;
    self.controlScrollView.showsVerticalScrollIndicator = NO;
    self.controlScrollView.showsHorizontalScrollIndicator = NO;
    
    self.controlScrollView.pagingEnabled = YES;
    self.controlScrollView.userInteractionEnabled = YES;
    self.controlScrollView.delegate = self;
    
    self.controlScrollView.contentSize = CGSizeMake(2*SCREEN_WIDTH, 0);
    userContentOffsetX = 0;
}

- (void)controlButtonsAction:(id)sender{
    UIButton *btn = (UIButton*)sender;
    int tag = btn.tag;
    
    btn.selected = !btn.selected;
//    self.controlButtonSelected[tag] = @([self.controlButtonSelected[tag]intValue]^1);
    
    NSString *imageName =nil;
    BOOL selected = btn.selected; //[self.controlButtonSelected[tag] intValue]==1;

    if (selected) {
        imageName = [NSString stringWithFormat:@"btn_360_%@_select",self.controlButtonNames[tag] ];
    }else{
        imageName = [NSString stringWithFormat:@"btn_360_%@_normal",self.controlButtonNames[tag] ];
    }
    
    switch (tag) {
        case 0:  //audio
        {
            if (selected) {
                imageName = [NSString stringWithFormat:@"btn_360_%@_on",self.controlButtonNames[tag] ];
                [self.displayVC openLiveAudio];
            }else{
                imageName = [NSString stringWithFormat:@"btn_360_%@_off",self.controlButtonNames[tag] ];
                [self.displayVC closeLiveAudio];
            }
            //btn_360_audio_off
            break;
        }
        case 1:  //cruise
        {
            _autoRotateSignal = !_autoRotateSignal;
            self.displayVC.player.autoRotSig = _autoRotateSignal;
            break;
        }
        case 2:  //installMode
        {
//            self.displayVerticalView.hidden = !self.displayVerticalView.hidden;
            break;
        }
        case 3:  //displayMode
        {
            if (_curPanoramaType == PanoramaType180) {
                self.displayVerticalView.hidden = !self.displayVerticalView.hidden;
            }else{
                self.displayHorizontalView.hidden = !self.displayHorizontalView.hidden;
            }
            break;
        }
        case 4:  //_playback
        {
            [self recordListBtnAction:nil];
            break;
        }
        case 5:  //videoQuality
        {
            imageName = @"btn_360_videoQuality_normal";
            [self.qualityChangeLabel setText:DPLocalizedString(selected?@"Play_SD":@"Play_HD")];
            [self changeVideoQualityAction];
            break;
        }
        default:
            break;
    }
    if (tag!=2 && tag!=3) {
        [btn setImage:[UIImage imageNamed:imageName] forState:0];
    }
}

- (void)changeVideoQualityAction
{
    NSLog(@"'画面质量切换’事件");
    //如果正在切换 return
    if (_videoQualityChanged) {
        return;
    }
    _videoQualityChanged = YES;
    
    //创建超时定时器
    [self showChangeVideoQualityTimeoutMsg];
    if (self->_segmentIndex==1)
    {
        //切换到高清
        [self changeDisplayQuality:0 andUID:self.deviceId];
    }
    else
    {
        //切换到标清
        [self changeDisplayQuality:1 andUID:self.deviceId];
    }
}

- (void)recordListBtnAction:(id)sender
{
    NSLog(@"'录像列表’事件");
    RecordDateListViewController *recordDateListVC = [[RecordDateListViewController alloc] init];
    recordDateListVC.model    = _deviceModel;
    [self.navigationController pushViewController:recordDateListVC animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self refreshScrollView];
}


-(void)refreshScrollView {
    
    int page=0;
    if (isLeftScroll) {
        //_controlScrollView.contentOffset.x
        page = (_controlScrollView.contentOffset.x+_controlScrollView.frame.size.width/2.0) /_controlScrollView.frame.size.width;
    }else {
        page = (_controlScrollView.contentOffset.x+_controlScrollView.frame.size.width/2.0) /_controlScrollView.frame.size.width;
    }
    
    
//    NSLog(@"loadData_:%d",page);
    
    if (page == _oldPageIndex) {
        return;
    }else{
        _oldPageIndex = page;
    }
    [self.pageNumberIndicator setImage:[UIImage imageNamed:[NSString stringWithFormat:@"btn_360_sliding_block_%d",page]]];
//    [_controlScrollView setContentOffset:CGPointMake(page*SCREEN_WIDTH, 0) ];
}




#pragma mark = Lazily Load
//声音 巡航 安装模式 显示模式 回放 清晰度
-(NSArray*)controlButtonNames{
    if (!_controlButtonNames) {
        _controlButtonNames = @[@"audio",@"cruise",@"installMode",@"displayMode",@"playback",@"videoQuality"];
    }
    return _controlButtonNames;
}

- (void)creatFolder{
    NSString *folderPath = [NSString stringWithFormat:@"%@/storeVideo/%@",mDocumentPath,self.deviceId];
    if (![mFileManager fileExistsAtPath:folderPath]) {
        
        [mFileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }else{
        NSLog(@"有这个文件了");
    }
}

//controlButtonSelected
-(NSMutableArray*)controlButtonSelected{
    if (!_controlButtonSelected) {
        _controlButtonSelected = [NSMutableArray arrayWithCapacity:1];
        for (int i=0; i<6; i++) {
            [_controlButtonSelected addObject:@(0)];
        }
    }
    return _controlButtonSelected;
}

- (NSString *)pathWithFileType:(FileType)type{

    NSString *timeStr = [self getCurrentDate];
    NSString *createPath;
    if (type == File_mp4) {
        createPath = [NSString stringWithFormat:@"%@/storeVideo/%@/%@.mp4",mDocumentPath,self.deviceId,timeStr];
    }
    else{
        createPath = [NSString stringWithFormat:@"%@/storeVideo/%@/%@.jpg",mDocumentPath,self.deviceId,timeStr];
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

- (void)updateTimer:(NSTimer *)timer
{
    self.recordingShowView.hidden = !self.recordingShowView.hidden;
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

#pragma mark 按钮事件

/**
 开始录像
 */
- (IBAction)recordingAction:(id)sender {

    if (!self.recordingBtn.selected)
    {
        //录像
        if (!_isRunning) {
            [self showNewStatusInfo:DPLocalizedString(@"Play_camera_no_connect")];
            return;
        }
        
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.displayVC startRecordingWithStoragePath:[self pathWithFileType:File_mp4] result:^(int result, int count) {
                if (result == 0) {
                    weakSelf.isRecordflag = YES;
                }else if (result == -1){
                    weakSelf.isRecordflag = NO;
                }
                
                if(result == 0 || result == -1){
                    [weakSelf dealWithStartingRecordingResult];
                }
            } ];
        });
        
    }
    else
    {
        //结束录像
        [self stopVideoRecord];
    }
}

- (void)dealWithStartingRecordingResult{
    if (_isRecordflag)
    {
        UISettingModel *model = [[UISettingManagement sharedInstance] getSettingModel:self.platformUID];
        if (model.ability_mic)
        {
            if (_audioFlag == NO)
            {
                _speakFlag = NO;
                [self audioStart];
                [NSThread sleepForTimeInterval:0.1];
                //开启声音
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_soundBtn setImage:[UIImage imageNamed:@"btn_360_audio_on"] forState:UIControlStateNormal];
                });
            }
            else
            {
                _speakFlag = YES;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^
                       {
                           self.recordTimeView.hidden=NO;
                           self.recordingShowView.hidden = NO;
                           
                           self.recordShowViewTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimer:) userInfo:nil repeats:YES];
                           [self updateTimer:nil];
                           
                           [self playRecordSound];
						   
						   self.recordingBtn.selected = YES;
						   [self.recordingBtn setImage:[UIImage imageNamed:@"NvrRecordHighLight"] forState:UIControlStateNormal];
                       });
        
        //            [self recordTimerStart];
	}else{//开启录像失败
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[SVProgressHUD showErrorWithStatus:DPLocalizedString(@"RecordFailure")];
		});
	}

}


- (IBAction)snapshotAction:(id)sender {
    if (_isRunning)
    {
        [self playSnapShotSound];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.displayVC snapshotWithStoragePath:[self pathWithFileType:File_img] result:^(int result) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    dispatch_async_on_main_queue(^{
                        if (result==0){
                            [self showNewStatusInfo:DPLocalizedString(@"save_image")];
                        }
                        else
                        {
                            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"localizied_9")];
                        }
                    });
                });
            }];
        });
    }
    else
    {
        [self showNewStatusInfo:DPLocalizedString(@"Play_camera_no_connect")];
    }
}

@end
