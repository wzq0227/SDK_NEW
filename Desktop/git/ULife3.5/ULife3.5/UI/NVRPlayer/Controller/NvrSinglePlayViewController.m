//
//  NvrSinglePlayViewController.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/15.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "NvrSinglePlayViewController.h"
#import "NvrSinglePlayView.h"
#import "NvrPlayCtrlView.h"
#import "NvrSearchPlaybackViewController.h"
#import "GDVideoPlayer.h"
#import "NetAPISet.h"
#import <AVFoundation/AVFoundation.h>
#import "MediaManager.h"
#import "PlayListViewController.h"

/** 全屏切换动画时长（单位：秒） */
#define TRANSFORM_DURATION 0.35f

#define NAV_BAR_HEIGHT 64.0f

/** 等待 NVR 四画面子码流 停止流响应超时时间 */
#define WAITE_RESP_TIME_OUT 10.0f

/** 横屏旋转切换状态 枚举*/
typedef NS_ENUM(NSUInteger, TransformViewState) {
    TransformViewSmall,             // 竖屏（小屏）状态
    TransformViewAnimating,         // 正在切换状态
    TransformViewFullscreen,        // 横屏（全屏）状态
};


@interface NvrSinglePlayViewController ()   <
                                                NvrPlayCtrlViewDelegate,
                                                NvrSinglePlayViewDelegate,
                                                GDVideoPlayerDelegate,
                                                GDNetworkSourceDelegate,
                                                GDNetworkStateDelegate
                                            >
{
    /** 保存屏幕宽度 */
    CGFloat _screenWidth;
    
    /** 保存屏幕高度 */
    CGFloat _screenHeight;
    
    /** 竖屏时 nvr 播放 view 大小 */
    CGSize _portraintPlayViewSize;
    
    /** 横屏时 nvr 播放 view 大小 */
    CGSize _landscapePlayViewSize;
    
    /** 页面是否已退出 */
    BOOL _isViewDisappare;
    
    /** 是否正在录像 */
    BOOL _isRecording;
    
    /** 是否隐藏正在录像指示 view */
    BOOL _isRecordingViewHidden;
    
    BOOL _isFirstViewDidAppare;
    
    /** 记录上一次屏幕方向 */
    UIDeviceOrientation _lastOrientation;
    
    /** 录像状态 view 定时器 */
    NSTimer *_recordingViewTimer;
    
    /** 监听超时次数 */
    int _monitorRespTimeoutCount;
    
    BOOL _isHD;
    BOOL _isChangeQuality;
}

/** NVR 单画面播放 View */
@property (nonatomic, strong) NvrSinglePlayView *singlePlayView;

/** NVR 单画面播放 控制 View */
@property (nonatomic, strong) NvrPlayCtrlView *playCtrlView;

/** 记录竖屏时 nvrPlayView 的 parentView */
@property (nonatomic, weak) UIView *singlePlayViewParentView;

/** 记录竖屏时 nvrPlayView 的 frame */
@property (nonatomic, assign) CGRect singlePlayViewFrame;

/** 记录 imageView 移到 window 上 Rect */
@property (nonatomic, assign) CGRect singlePlayViewRectInWindow;

/** 横屏旋转切换状态 */
@property (nonatomic, assign) TransformViewState transformState;

/** 设备数据模型 */
@property (nonatomic, strong) DeviceDataModel *devDataModel;

/** 从哪个画面进来的 */
@property (nonatomic, assign) PositionType positionType;

/** NVR 单画面播放器 */
@property (nonatomic, strong) GDVideoPlayer *singleVideoPlayer;

/** 录像按钮点击声音 播放器 */
@property (nonatomic, strong) AVAudioPlayer *recordAudioPlayer;

/** 拍照按钮点击声音 播放器 */
@property (nonatomic, strong) AVAudioPlayer *snapshotAudioPlayer;

/** TUTK 平台 ID （长度：20）*/
@property (nonatomic, copy) NSString *tutkDevId;

/** 3.5 平台 ID （长度：28）*/
@property (nonatomic, copy) NSString *platformDevId;

@end

@implementation NvrSinglePlayViewController

- (instancetype)initWithDevModel:(DeviceDataModel *)devDataModel
                      onPosition:(PositionType)positionType
{
    if (self = [super init])
    {
        self.devDataModel  = devDataModel;
        self.positionType  = positionType;
        self.tutkDevId     = [devDataModel.DeviceId substringFromIndex:8]; // 截取掉下标7之后的字符串;
        self.platformDevId = devDataModel.DeviceId;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = self.devDataModel.DeviceName;
    
    [self initParam];
    
    [self addCustomViews];
    
    [self saveNvrShowViewFrame];
    
    if (GosDeviceStatusOnLine == self.devDataModel.Status)
    {
        [self addBackgroundRunningEvent];
        
        [self addLockScreenMonitor];
        
        [self monitorStopSubStreamNotify];
    }
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.translucent = YES;
    
    if (GosDeviceStatusOffLine == self.devDataModel.Status)
    {
        [self stopActivity];
        
        [self configReloadBtnHidden:YES];
        [self configOffLineBtnHidden:NO];
    }
    else if (GosDeviceStatusOnLine == self.devDataModel.Status)
    {
        [self setApiNetDelegate];
        
        [self startActivity];
        
        [self configReloadBtnHidden:YES];
        [self configOffLineBtnHidden:YES];
    }
    else if (GosDeviceStatusSleep == self.devDataModel.Status)
    {
        
    }
    else
    {
        
    }
    
    [self configtQualityBtnTitle];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    _lastOrientation = [[UIDevice currentDevice] orientation];
    
    _isViewDisappare = NO;
    
    if (GosDeviceStatusOffLine == self.devDataModel.Status)
    {
        
    }
    else if (GosDeviceStatusOnLine == self.devDataModel.Status)
    {
        [self createNvrSinglePlayer];
        
        [self startGetNvrVideoData];
        
        if (UIDeviceOrientationLandscapeLeft != _lastOrientation
            && UIDeviceOrientationLandscapeRight != _lastOrientation
            && NO == self.isFourViewFullScreen)
        {
            [self updatePlayerViewSize:_portraintPlayViewSize];
        }
        
        if (UIDeviceOrientationLandscapeLeft == _lastOrientation
            || YES == self.isFourViewFullScreen)
        {
            _lastOrientation = UIDeviceOrientationPortrait;
            [self rotateToLeft];
        }
        if (UIDeviceOrientationLandscapeRight == _lastOrientation)
        {
            _lastOrientation = UIDeviceOrientationPortrait;
            [self rotateToRight];
        }
    }
    else if (GosDeviceStatusSleep == self.devDataModel.Status)
    {
        
    }
    else
    {
        
    }

    if (YES == _isFirstViewDidAppare)
    {
        [self addDevOrientationNotify];
        
        _isFirstViewDidAppare = NO;
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    _isViewDisappare = YES;
    
    if (GosDeviceStatusOffLine == self.devDataModel.Status)
    {
        
    }
    else if (GosDeviceStatusOnLine == self.devDataModel.Status)
    {
        if (YES == _isRecording)
        {
            [self stopRecordVideo];
        }
        
        [self stopGetNvrVideoData];
        
        [self releaseNvrSinglePlayer];
        
        [self stopActivity];
        
        [self removeApiNetDelegate];
    }
    else if (GosDeviceStatusSleep == self.devDataModel.Status)
    {
        
    }
    else
    {
        
    }
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)dealloc
{
    [self realseAudioPlayer];
    NSLog(@"----------- NvrSinglePlayViewController dealloc -----------");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NVR_STOP_VIDEO_NOTIFY
                                                  object:nil];
}



#pragma mark - 保存设置相关
#pragma mark -- 初始化参数
- (void)initParam
{
    _screenWidth           = SCREEN_WIDTH;
    _screenHeight          = SCREEN_HEIGHT;
    _isRecording           = NO;
    _isHD                  = YES;
    _isChangeQuality       = NO;
    _isRecordingViewHidden = YES;
    if (_screenWidth > _screenHeight)
    {
        _screenWidth    = SCREEN_HEIGHT;
        _screenHeight   = SCREEN_WIDTH;
    }
    _monitorRespTimeoutCount = 0;
    _isFirstViewDidAppare    = YES;
}


#pragma mark -- 添加自定义子 View
- (void)addCustomViews
{
    self.singlePlayViewFrame = CGRectMake(0,
                                          NAV_BAR_HEIGHT,
                                          _screenWidth,
                                          _screenWidth * PLAY_VIEW_SCALE);
    self.singlePlayView = [[NvrSinglePlayView alloc] initWithFrame:self.singlePlayViewFrame];
    self.singlePlayView.delegate = self;
    self.playCtrlView   = [[NvrPlayCtrlView alloc] initWithFrame:CGRectMake(0,
                                                                            _screenWidth * PLAY_VIEW_SCALE + NAV_BAR_HEIGHT,
                                                                            _screenWidth,
                                                                            _screenHeight - _screenWidth * PLAY_VIEW_SCALE - 64.0f)];
    self.playCtrlView.delegate = self;
    [self.view addSubview:self.singlePlayView];
    [self.view addSubview:self.playCtrlView];
    self.singlePlayViewParentView = self.singlePlayView.superview;
    
    self.singlePlayViewRectInWindow = [self.view convertRect:self.singlePlayView.bounds
                                                 toView:[UIApplication sharedApplication].keyWindow];
}


#pragma mark -- 保存竖屏是 NVR 单画面 frame
- (void)saveNvrShowViewFrame
{
    _portraintPlayViewSize = CGSizeMake(_screenWidth, _screenWidth * PLAY_VIEW_SCALE);
    _landscapePlayViewSize = CGSizeMake(_screenHeight, _screenWidth);
}


#pragma mark -- 开启 Activity 动画
- (void)startActivity
{
    [self.singlePlayView startActivityAnimation];
}


#pragma mark -- 停止 Activity 动画
- (void)stopActivity
{
    [self.singlePlayView stopActivityAnimation];
}

- (void)configtQualityBtnTitle
{
    [self.singlePlayView configQualityTitle:!_isHD];
}


#pragma mark -- 设置‘不在线’按钮是否隐藏
- (void)configOffLineBtnHidden:(BOOL)isHidden
{
    [self.singlePlayView configOfflineBtnHidden:isHidden];
}


#pragma mark -- 设置‘重新加载’按钮是否隐藏
- (void)configReloadBtnHidden:(BOOL)isHidden
{
    [self.singlePlayView configReloadBtnHidden:isHidden];
}


#pragma mark - 监听四画面子码流停流的响应’通知
- (void)monitorStopSubStreamNotify
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleStopSubstreamRet:)
                                                 name:NVR_STOP_VIDEO_NOTIFY
                                               object:nil];
}


#pragma mark -- 处理子码流停流结果
- (void)handleStopSubstreamRet:(NSNotification *)notify
{
     NSDictionary *resultDict = (NSDictionary *)notify.object;
    if (![[resultDict allKeys] containsObject:[NSNumber numberWithLong:self.positionType - 1]])
    {
        return;
    }
    BOOL isStopSubStream = [[resultDict objectForKey:[NSNumber numberWithLong:self.positionType - 1]] boolValue];
    NSLog(@"停止 NVR 四画面视频流通知 -- 四画面子码流停流结果：%d", isStopSubStream);
    self.stopNvrSubStream = isStopSubStream;
}


#pragma mark - 开/锁屏监听
- (void)addLockScreenMonitor
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lockScreen)
                                                 name:LOCK_SCREEN_NOTIFY
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(unLockScreen)
                                                 name:UN_LOCK_SCREEN_NOTIFY
                                               object:nil];
}


#pragma mark -- 锁屏
- (void)lockScreen
{
    if (UIDeviceOrientationPortrait != _lastOrientation)
    {
        [self exitFullscreen];
    }
    [self stopGetNvrVideoData];
    
    [self releaseNvrSinglePlayer];
    
    [self stopActivity];
}


#pragma mark -- 解锁屏
- (void)unLockScreen
{
    
}


#pragma mark -- 添加屏幕旋转通知
- (void)addDevOrientationNotify
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(devOrientDidChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}


#pragma mark -- 屏幕方向监控
- (void)devOrientDidChange
{
    if (YES == _isViewDisappare)
    {
        return;
    }
    UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
    
    switch (currentOrientation)
    {
        case UIDeviceOrientationUnknown:        // 位未知方向
        {
            NSLog(@"NvrSinglePlayViewController 屏幕旋转 ：UIDeviceOrientationUnknown ！");
        }
            break;
            
        case UIDeviceOrientationPortrait:
        {
            NSLog(@"NvrSinglePlayViewController 屏幕旋转 ：UIDeviceOrientationPortrait ！");
            [self exitFullscreen];
        }
            break;
            
        case UIDeviceOrientationLandscapeLeft:
        {
            NSLog(@"NvrSinglePlayViewController 屏幕旋转 ：UIDeviceOrientationLandscapeLeft ！");
            if (UIDeviceOrientationLandscapeRight == _lastOrientation)  // 360 旋转
            {
                [self rotate360OnOrientation:UIDeviceOrientationLandscapeLeft
                               transforAngle:M_PI_2];
            }
            else
            {
                [self rotateToLeft];
            }
        }
            break;
            
        case UIDeviceOrientationLandscapeRight:
        {
            NSLog(@"NvrSinglePlayViewController 屏幕旋转 ：UIDeviceOrientationLandscapeRight ！");
            if (UIDeviceOrientationLandscapeLeft == _lastOrientation) // 360 旋转
            {
                [self rotate360OnOrientation:UIDeviceOrientationLandscapeRight
                               transforAngle:-M_PI_2];
            }
            else
            {
                [self rotateToRight];
            }
            
        }
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
        {
            NSLog(@"NvrSinglePlayViewController 屏幕旋转 ：UIDeviceOrientationPortraitUpsideDown ！");
        }
            break;
            
        case UIDeviceOrientationFaceUp:
        {
            NSLog(@"NvrSinglePlayViewController 屏幕旋转 ：UIDeviceOrientationFaceUp ！");
        }
            break;
            
        case UIDeviceOrientationFaceDown:
        {
            NSLog(@"NvrSinglePlayViewController 屏幕旋转 ：UIDeviceOrientationFaceDown ！");
        }
            break;
            
        default:
        {
            NSLog(@"NvrSinglePlayViewController 屏幕旋转 ：default ！");
        }
            break;
    }
}



#pragma mark -- 显示/隐藏 statue bar
- (void)hiddentStatueBar:(BOOL)isHidden
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[UIApplication sharedApplication] setStatusBarHidden:isHidden
                                                withAnimation:UIStatusBarAnimationFade];
    });
}


#pragma mark -- 向左旋转
- (void)rotateToLeft
{
    CGRect bounds = CGRectMake(0,
                               0,
                               _screenHeight,
                               _screenWidth);
    CGPoint center = CGPointMake(CGRectGetMidX(self.view.bounds),
                                 CGRectGetMidY(self.view.bounds));
    
    [self enterFullscreenOnOrientation:UIDeviceOrientationLandscapeLeft
                            viewBounds:bounds
                            viewCenter:center
                         transforAngle:M_PI_2];
}


#pragma mark -- 向右旋转
- (void)rotateToRight
{
    CGRect bounds = CGRectMake(0,
                               0,
                               _screenHeight,
                               _screenWidth);
    CGPoint center = CGPointMake(CGRectGetMidX(self.view.bounds),
                                 CGRectGetMidY(self.view.bounds));
    
    [self enterFullscreenOnOrientation:UIDeviceOrientationLandscapeRight
                            viewBounds:bounds
                            viewCenter:center
                         transforAngle:-M_PI_2];
}


#pragma mark -- 180 旋转 View
- (void)rotate360OnOrientation:(UIDeviceOrientation)devOrientation
                 transforAngle:(CGFloat)angle
{
    if (UIDeviceOrientationPortrait == _lastOrientation
        || UIDeviceOrientationPortraitUpsideDown == _lastOrientation
        || UIDeviceOrientationFaceUp == _lastOrientation
        || UIDeviceOrientationFaceDown == _lastOrientation
        || UIDeviceOrientationPortrait == devOrientation
        || UIDeviceOrientationPortraitUpsideDown == devOrientation
        || UIDeviceOrientationFaceUp == devOrientation
        || UIDeviceOrientationFaceDown == devOrientation)
    {
        NSLog(@"当前 iOS 设备不是横屏方向，不全屏旋转！");
        return;
    }
    if (TransformViewFullscreen != self.transformState)
    {
        return;
    }
    self.transformState = TransformViewAnimating;
    [UIView animateWithDuration:TRANSFORM_DURATION
                     animations:^{
                         
                         self.singlePlayView.transform = CGAffineTransformMakeRotation(angle);
                         
                         [self refreshStatusBarOrientation:(UIInterfaceOrientation)devOrientation];
                     }
                     completion:^(BOOL finished) {
                         
                         self.transformState = TransformViewFullscreen;
                         _lastOrientation = devOrientation;
                     }];
}


#pragma mark -- 进入全屏(由竖屏——>横屏时调用)
- (void)enterFullscreenOnOrientation:(UIDeviceOrientation)devOrientation
                          viewBounds:(CGRect)bounds
                          viewCenter:(CGPoint)center
                       transforAngle:(CGFloat)angle

{
    if (UIDeviceOrientationLandscapeLeft == _lastOrientation
        || UIDeviceOrientationLandscapeRight == _lastOrientation
        || UIDeviceOrientationPortrait == devOrientation
        || UIDeviceOrientationPortraitUpsideDown == devOrientation
        || UIDeviceOrientationFaceUp == devOrientation
        || UIDeviceOrientationFaceDown == devOrientation)
    {
        NSLog(@"当前 iOS 设备不是横屏方向，不进入全屏模式！");
        return;
    }
    if (TransformViewSmall != self.transformState)
    {
        return;
    }
    self.transformState = TransformViewAnimating;
    
    // 先 singlePlayView
    [UIView animateWithDuration:TRANSFORM_DURATION
                     animations:^{
                         
                         [self hiddentStatueBar:YES];
                         
                         [self.singlePlayView removeFromSuperview];
                         self.singlePlayView.frame = self.singlePlayViewRectInWindow;
                         [[UIApplication sharedApplication].keyWindow addSubview:self.singlePlayView];

                         self.singlePlayView.transform = CGAffineTransformMakeRotation(angle);
                         self.singlePlayView.bounds    = bounds;
                         self.singlePlayView.center    = center;
                         
                         [self updatePlayerViewSize:_landscapePlayViewSize];
                     }
                     completion:^(BOOL finished) {
                         
                     }];
    [UIView animateWithDuration:TRANSFORM_DURATION * 0.1
                     animations:^{
                         
                         [self refreshStatusBarOrientation:(UIInterfaceOrientation)devOrientation];
                     }
                     completion:^(BOOL finished) {
                         
                         self.transformState = TransformViewFullscreen;
                         _lastOrientation = devOrientation;
                     }];
}


#pragma mark -- 退出全屏
- (void)exitFullscreen
{
    if (TransformViewFullscreen != self.transformState)
    {
        return;
    }
    self.transformState = TransformViewAnimating;
    CGRect nvrPlayViewFrame = [self.singlePlayViewParentView convertRect:self.singlePlayViewFrame
                                                             toView:[UIApplication sharedApplication].keyWindow];
    [UIView animateWithDuration:TRANSFORM_DURATION * 0.1
                     animations:^{
                         
                         [self refreshStatusBarOrientation:UIInterfaceOrientationPortrait];
                     }
                     completion:^(BOOL finished) {
                         
                     }];
    [UIView animateWithDuration:TRANSFORM_DURATION
                     animations:^{
                         
                         self.singlePlayView.transform = CGAffineTransformIdentity;
                         self.singlePlayView.frame = nvrPlayViewFrame;
                         
                         // movieView回到竖屏位置
                         [self.singlePlayView removeFromSuperview];
                         self.singlePlayView.frame = self.singlePlayViewFrame;
                         [self.singlePlayViewParentView addSubview:self.singlePlayView];
                         
                         
                         [self updatePlayerViewSize:_portraintPlayViewSize];
                     }
                     completion:^(BOOL finished) {
                         
                         self.transformState = TransformViewSmall;
                         _lastOrientation    = UIDeviceOrientationPortrait;
                         [self hiddentStatueBar:NO];
                     }];
}


#pragma mark -- 设置状态栏 位置
- (void)refreshStatusBarOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    [[UIApplication sharedApplication] setStatusBarOrientation:interfaceOrientation
                                                      animated:YES];
}


#pragma mark - 自动横竖屏切换
- (BOOL)shouldAutorotate
{
    return NO;
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


-(void)showNewStatusInfo:(NSString*)info
{
    [SVProgressHUD showInfoWithStatus:info];
    [SVProgressHUD dismissWithDelay:2];
}


#pragma mark -- 开启录像 view 定时器
-(void)startRecordingViewTimer
{
    _recordingViewTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                           target:self
                                                         selector:@selector(showRecordingView)
                                                         userInfo:nil
                                                          repeats:YES];
    [_recordingViewTimer fire];
}


#pragma mark --  更新显示‘正在录像显示’ view
- (void)showRecordingView
{
    _isRecordingViewHidden = !_isRecordingViewHidden;
    [self.singlePlayView configRecordingViewHidden:_isRecordingViewHidden];
}


#pragma mark -- 停止录像 view 定时器
-(void)stopRecordingViewTimer
{
    if (_recordingViewTimer && [_recordingViewTimer isValid])
    {
        [_recordingViewTimer invalidate];
        _recordingViewTimer = nil;
    }
}


#pragma mark -- 录像时间回调
- (void)parseRecordDuration:(NSInteger)duration
{
    long second = duration % 60;
    long minute = (duration % 3600 - second) / 60;
    long hour   = (duration - second - minute) / 3600;
    NSString *durationStr = [[NSString alloc] initWithFormat:@"%02ld:%02ld:%02ld", hour, minute, second];
    NSLog(@"NVR 单画面录像时间:%@",durationStr);
}


#pragma mark - 音频相关
#pragma mark -- 创建‘拍照’按钮音效播放器
- (AVAudioPlayer *)snapshotAudioPlayer
{
    if (!_snapshotAudioPlayer)
    {
        NSString *audioFilePath = [[NSBundle mainBundle] pathForResource:@"SnapshotSound"
                                                                  ofType:@"wav"];
        NSURL *audioFileUrl = [NSURL fileURLWithPath:audioFilePath];
        _snapshotAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileUrl
                                                                      error:NULL];
    }
    
    return _snapshotAudioPlayer;
}


#pragma mark -- 创建‘录像’按钮音效播放器
- (AVAudioPlayer *)recordAudioPlayer
{
    if (!_recordAudioPlayer)
    {
        NSString *audioFilePath = [[NSBundle mainBundle] pathForResource:@"RecordSound"
                                                                  ofType:@"wav"];
        NSURL *audioFileUrl = [NSURL fileURLWithPath:audioFilePath];
        _recordAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileUrl
                                                                    error:NULL];
    }
    
    return _recordAudioPlayer;
}


#pragma mark -- 播放‘拍照’音效
- (void)playSnapShotSound
{
    if (self.snapshotAudioPlayer)
    {
        [self.snapshotAudioPlayer prepareToPlay];
        [self.snapshotAudioPlayer play];
    }
}

#pragma mark -- 播放‘录像’音效
- (void)playRecordSound
{
    if (self.recordAudioPlayer)
    {
        [self.recordAudioPlayer prepareToPlay];
        [self.recordAudioPlayer play];
    }
}


#pragma mark -- 释放按钮音效播放器
-(void)realseAudioPlayer
{
    if (_snapshotAudioPlayer)
    {
        [_snapshotAudioPlayer stop];
        _snapshotAudioPlayer = nil;
    }
    if (_recordAudioPlayer)
    {
        [_recordAudioPlayer stop];
        _recordAudioPlayer = nil;
    }
}


#pragma mark -- 开启录像
- (void)startRecordVideo
{
    NSString *recordPath = [[MediaManager shareManager] mediaPathWithDevId:self.tutkDevId
                                                                  fileName:nil
                                                                 mediaType:GosMediaRecord
                                                                deviceType:GosDeviceNVR
                                                                  position:self.positionType];
    __weak typeof(self)weakSelf = self;
    BOOL startRecord = [self.singleVideoPlayer recordStartWithAudioEnabled:NO
                                                              andSavePhoto:NO
                                                                   andPath:recordPath
                                                            andBlockRequst:^(int result,
                                                                             int count,
                                                                             NSError *error) {
                                       
                                                                __strong typeof(weakSelf)strongSelf = weakSelf;
                                                                if (!strongSelf)
                                                                {
                                                                    NSLog(@"对象丢失，无法处理 NVR 录像时长！");
                                                                    return ;
                                                                }
                                                                if (0 == result)
                                                                {
                                                                    [strongSelf parseRecordDuration:count];
                                                                }
                                                            }];
    
    if (NO == startRecord)
    {
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"RecordFailure")];
        
        return;
    }
    NSLog(@"开启 NVR 录像成功！");
    _isRecording = YES;
    [self.singlePlayView configRecordTipLabelViewHidden:NO];
    [self startRecordingViewTimer];
    [self.playCtrlView configRecordBtnStyle:RecordBtnHighLight];
}


#pragma mark -- 停止录像
- (void)stopRecordVideo
{
    [self.singleVideoPlayer recordStop];
    NSLog(@"停止 NVR 录像成功！");
    _isRecording = NO;
    [self stopRecordingViewTimer];
    [self.singlePlayView configRecordTipLabelViewHidden:YES];
    [self.singlePlayView configRecordingViewHidden:YES];
    [self.playCtrlView configRecordBtnStyle:RecordBtnNormal];
}


#pragma mark -- 拍照
- (void)startSnapshot
{
    NSString *snapshotPath = [[MediaManager shareManager] mediaPathWithDevId:self.tutkDevId
                                                                    fileName:nil
                                                                   mediaType:GosMediaSnapshot
                                                                  deviceType:GosDeviceNVR
                                                                    position:self.positionType];
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法进行拍照！");
            return ;
        }
        [strongSelf.singleVideoPlayer screenshot:YES
                                         andPath:snapshotPath
                                  andBlockRequst:^(int result,
                                                   NSError *error) {
                                      
                                  }];
    });
}


#pragma mark - NvrPlayCtrlViewDelegate
#pragma mark -- ‘录像’按钮事件代理回调
- (void)recordButtonAction
{
    NSLog(@"‘录像’按钮事件");
    [self playRecordSound];
    if (NO == _isRecording)
    {
        [self startRecordVideo];
    }
    else
    {
        [self stopRecordVideo];
    }
}


#pragma mark -- ‘拍照’按钮事件代理回调
- (void)snapshotButtonAction
{
    NSLog(@"‘拍照’按钮事件");
    [self playSnapShotSound];
    [self startSnapshot];
}


#pragma mark -- ‘相册’按钮事件代理回调
- (void)photoAlbumButtonAction
{
    PlayListViewController *playListVC = [[PlayListViewController alloc]init];
    playListVC.deviceID                = [self.devDataModel.DeviceId substringFromIndex:8];
    playListVC.model                   = self.devDataModel;
    playListVC.positionType            = self.positionType;
    if (playListVC)
    {
        self.navigationController.navigationBar.translucent = NO;
        [self.navigationController pushViewController:playListVC
                                             animated:YES];
    }
}


- (void)qualityChangeButtonAction
{
    _isChangeQuality = YES;
    [self startActivity];
    
    [self.singlePlayView configQualityBtnUsable:NO];
    
    [self stopGetNvrVideoData];
}

#pragma mark - 播放相关
#pragma mark - Backgournd / Forground 切换监控观察通知
-(void)addBackgroundRunningEvent
{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}


#pragma mark -- 进入 Background 监控通知
-(void)didEnterBackground
{
    if (YES == _isViewDisappare)
    {
        return;
    }
    [self stopGetNvrVideoData];
    
    [self releaseNvrSinglePlayer];
    
    [self stopActivity];
}


#pragma mark -- 进入 Forground 监控通知
- (void)willEnterForeground
{
    if (YES == _isViewDisappare)
    {
        return;
    }
    
    [self createNvrSinglePlayer];
    
    [self startGetNvrVideoData];
    
    [self startActivity];
}


#pragma mark - NetAPISet
#pragma mark -- 设置全局NetAPI代理
- (void)setApiNetDelegate
{
    [NetAPISet sharedInstance].sourceDelegage = self;
}


#pragma mark -- 移除全局NetAPI代理
- (void)removeApiNetDelegate
{
    [NetAPISet sharedInstance].sourceDelegage = nil;
}


#pragma mar - 播放器
#pragma mark -- 创建播发器
- (void)createNvrSinglePlayer
{
    if (!self.devDataModel.DeviceId)
    {
        NSLog(@"无法创建 NVR 播放器，nvrDeviceId = %@", self.devDataModel.DeviceId);
        
        return ;
    }
    if (self.singlePlayView)
    {
        self.singleVideoPlayer = [[GDVideoPlayer alloc] init];
        [self.singleVideoPlayer initWithViewAndDelegate:self.singlePlayView
                                           Delegate:self
                                        andDeviceID:self.tutkDevId
                                 andWithdoubleScale:NO
                                    nvrPositionType:self.positionType];
        NSString *covertPath = [[MediaManager shareManager] mediaPathWithDevId:self.tutkDevId
                                                                      fileName:nil
                                                                     mediaType:GosMediaCover
                                                                    deviceType:GosDeviceNVR
                                                                      position:self.positionType];
        self.singleVideoPlayer.coverPath    = covertPath;
        NSLog(@"创建：singleVideoPlayer ");
    }
}


#pragma mark -- 释放播发器
- (void)releaseNvrSinglePlayer
{
    if (self.singleVideoPlayer)
    {
        [self.singleVideoPlayer stopPlay];
        self.singleVideoPlayer.delegate = nil;
        self.singleVideoPlayer = nil;
    }
}


#pragma mark -- 屏幕旋转更新播放窗口大小
- (void)updatePlayerViewSize:(CGSize)viewSize
{
    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:TRANSFORM_DURATION
                     animations:^{
                         
                         __strong typeof(weakSelf)strongSelf = weakSelf;
                         if (!strongSelf)
                         {
                             NSLog(@"对象丢失，无法更新播放窗口大小！");
                             return ;
                         }
                         [strongSelf.singleVideoPlayer nvrUpdatePlayerViewSize:viewSize];
                     }
                     completion:^(BOOL finished) {
                         
                         __strong typeof(weakSelf)strongSelf = weakSelf;
                         if (!strongSelf)
                         {
                             NSLog(@"对象丢失，无法更新播放窗口大小！");
                             return ;
                         }
                         [strongSelf.singleVideoPlayer nvrUpdatePlayerViewSize:viewSize];
                     }];
}


#pragma mark - 视频流
#pragma mark -- 开始拉取视频流
- (void)startGetNvrVideoData
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        strongSelf->_monitorRespTimeoutCount = 0;
        while (NO == strongSelf.stopNvrSubStream)
        {
            NSLog(@"循环等待 NVR 四画面的子码流停流回应结果！");
            strongSelf->_monitorRespTimeoutCount++;
            if (100 == strongSelf->_monitorRespTimeoutCount)
            {
                NSLog(@"循环等待 NVR 四画面的子码流停流回应结果 --- 超时了！");
                strongSelf.stopNvrSubStream = YES;
            }
            [NSThread sleepForTimeInterval:0.1];
        }
        [strongSelf requestNvrVideo];
    });
}


#pragma mark -- 请求视频流
- (void)requestNvrVideo
{
    NSLog(@"==== 准备发送获取 NVR 第 单 路视频流请求,avChannel：%d", (int)(NO == _isHD ? self.positionType - 1 : self.positionType + 3));
    __weak typeof(self)weakSelf = self;
    [[NetAPISet sharedInstance] nvrStartGetVideoDataWithDeviceId:self.platformDevId
                                                       avChannel:NO == _isHD ? self.positionType - 1 : self.positionType + 3
                                                     playViewNum:1
                                            nvrGetVideoDataBlock:^(NvrGetDataStatus retStatus,
                                                                   NSString *nvrDeviceId,
                                                                   long avChannel) {
                                                
                                                __strong typeof(weakSelf)strongSelf = weakSelf;
                                                if (!strongSelf)
                                                {
                                                    return ;
                                                }
                                                switch (retStatus)
                                                {
                                                    case NvrGetDataSuccess:         // 拉流成功
                                                    {
                                                        [strongSelf.singlePlayView configQualityBtnUsable:YES];
                                                        [strongSelf configtQualityBtnTitle];
                                                        NSLog(@"NVR 开启单画面视频流成功，nvrDeviceId = %@，avChannel = %ld", nvrDeviceId, avChannel);
                                                    }
                                                        break;
                                                        
                                                    case NvrGetDataFailure:         // 拉流失败
                                                    {
                                                        NSLog(@"NVR 开启单画面视频流失败，nvrDeviceId = %@，avChannel = %ld", nvrDeviceId, avChannel);
                                                    }
                                                        break;
                                                        
                                                    case NvrGetDataOffLine:         // 设备不在线
                                                    {
                                                        
                                                    }
                                                        break;
                                                        
                                                    case NvrGetDataConnFailure:     // 设备连接失败
                                                    {
                                                        
                                                    }
                                                        break;
                                                        
                                                    case NvrGetDataParamError:      // 参数错误
                                                    {
                                                        
                                                    }
                                                        break;
                                                        
                                                    default:
                                                        break;
                                                }
                                            }];
}


#pragma mark -- 停止拉取视频流
- (void)stopGetNvrVideoData
{
    NSLog(@"==== 准备发送停止 NVR 第 单 路视频流请求,avChannel：%d", (int)(NO == _isHD ? self.positionType - 1 : self.positionType + 3));
    __weak typeof(self)weakSelf = self;
    [[NetAPISet sharedInstance] nvrStopGetVideoDataWithDeviceId:self.platformDevId
                                                      avChannel:NO == _isHD ? self.positionType - 1 : self.positionType + 3
                                          nvrStopVideoDataBlock:^(BOOL isSuccess, NSString *nvrDeviceId, long avChannel) {
                                              
                                              __strong typeof(weakSelf)strongSelf = weakSelf;
                                              if (!strongSelf)
                                              {
                                                  return ;
                                              }
                                              if (NO == isSuccess)
                                              {
                                                  NSLog(@"停止 NVR 单画面视频流失败，nvrDeviceId = %@ avChannel = %ld", nvrDeviceId, avChannel);
                                              }
                                              else
                                              {
                                                  NSLog(@"停止 NVR 单画面视频流成功，nvrDeviceId = %@ avChannel = %ld", nvrDeviceId, avChannel);
                                                  if (YES == strongSelf->_isChangeQuality)
                                                  {
                                                      NSLog(@"停止 NVR 单画面视频流成功，开始切换码流！");
                                                      strongSelf->_isChangeQuality = NO;
                                                      strongSelf->_isHD = !strongSelf->_isHD;
                                                      [strongSelf requestNvrVideo];
                                                  }
                                              }
                                          }];
}


#pragma mark - GDNetWork代理
#pragma mark -- 获取视频数据
- (void)getVideoData:(unsigned char *)pContentBuffer
          dataLength:(int)length
           timeStamp:(int)timeStamp
              framNo:(unsigned int)framNO
           frameRate:(int)frameRate
            isIFrame:(BOOL)isIFrame
            deviceID:(NSString *)deviceId
           avChannel:(int)avChannel
{
    if (YES == _isViewDisappare)
    {
        NSLog(@"NVR 单画面已退出，不处理视频流数据！");
        return;
    }
    NSLog(@"NVR 单画面视频数据：length-%d, isIFrame = %d, avChannel-%d", length, isIFrame, avChannel);
    if (YES == isIFrame)
    {
        [self stopActivity];
    }
    [self.singleVideoPlayer AddVideoFrame:pContentBuffer
                                      len:length
                                       ts:timeStamp
                                   framNo:framNO
                                frameRate:frameRate
                                   iFrame:isIFrame
                             andDeviceUid:deviceId];
}


#pragma mark-拍照的回调
- (void)SavePhotoImage:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSLog(@"didFinishSavingWithError");
    __block BOOL showError = (error != nil);
    dispatch_async(dispatch_get_main_queue(), ^{
       
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


- (void)image:(NSString *)imagePath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    
    NSLog(@"didFinishSavingWithError");
    __block BOOL showError = (error != nil);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
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
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [SVProgressHUD dismiss];
        if (showError)
        {
            [self showNewStatusInfo:DPLocalizedString(@"localizied_9")];
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"localizied_9")];
        }
        else
        {
            [self showNewStatusInfo:DPLocalizedString(@"save_video")];
        }
    });
}

@end
