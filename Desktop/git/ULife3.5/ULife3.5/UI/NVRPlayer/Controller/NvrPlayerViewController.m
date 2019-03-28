//
//  NvrPlayerViewController.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/14.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "NvrPlayerViewController.h"
#import "NvrPlayView.h"
#import "NvrCenterView.h"
#import "NvrPushMsgView.h"
#import "NvrSinglePlayViewController.h"
#import "NvrSearchPlaybackViewController.h"
#import "GDVideoPlayer.h"
#import "NetAPISet.h"
#import "DeviceManagement.h"
#import "NvrSettingViewController.h"
#import "MediaManager.h"
#import "PushMessageManagement.h"


#define CENTER_VIEW_HEIGHT 48.0f

/** 全屏切换动画时长（单位：秒） */
#define TRANSFORM_DURATION 0.5f

#define NAV_BAR_HEIGHT 64.0f

/** 请求视频流超时时间（单位：秒） */
#define REQ_VIDEO_TIMEOUT 30.0f

/** 横屏旋转切换状态 枚举*/
typedef NS_ENUM(NSUInteger, TransformViewState) {
    TransformViewSmall,             // 竖屏（小屏）状态
    TransformViewAnimating,         // 正在切换状态
    TransformViewFullscreen,        // 横屏（全屏）状态
};


@interface NvrPlayerViewController ()   <
                                            NvrPlayViewDelegate,
                                            NvrCenterViewDelegate,
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
    
    /** 是否第一次进入页面 */
    BOOL _isFirstAppear;
    
    /** 是否进入全屏模式 */
    BOOL _isFullScreen;
    
    /** 是否隐藏 Center View */
    BOOL _isHiddenCenterView;
    
    /** 页面是否已退出 */
    BOOL _isViewDisappare;
    
    /** 设备昵称 */
    NSString *_nvrDevNickName;
    
    FILE *_pWriteFile;
    
    NSString *_writeFilePath;
    
    /** 是否从单画面返回来 */
    BOOL _isBackFromSingleView;
    
    /** 是否有有接收数据流 */
    BOOL _isReceiveData[4];
    
    /** '重新加载’按钮是否隐藏 */
    BOOL _isHiddenRealoadBtn[4];
    
    /** 是否已经停止流成功 用于控制二次拉流 */
    BOOL _isStopVideo[4];
}

/** NVR 播放 View*/
@property (nonatomic, strong) NvrPlayView *nvrPlayView;

/** 横屏控制 View*/
@property (nonatomic, strong) NvrCenterView *centerView;

/** 推送消息 View*/
@property (nonatomic, strong) NvrPushMsgView *pushMsgView;

/** 记录竖屏时 nvrPlayView 的 parentView */
@property (nonatomic, weak) UIView *nvrPlayViewParentView;

/** 记录竖屏时 nvrPlayView 的 frame */
@property (nonatomic, assign) CGRect nvrPlayViewFrame;

/** 记录竖屏时 centerView 的 parentView */
@property (nonatomic, weak) UIView *centerViewParentView;

/** 记录竖屏时 centerView 的 frame */
@property (nonatomic, assign) CGRect centerViewFrame;

/** 横屏旋转切换状态 */
@property (nonatomic, assign) TransformViewState transformState;

/** 设备数据模型 */
@property (nonatomic, strong) DeviceDataModel *devDataModel;

/** NVR 播放器：左上角 Top-Left */
@property (nonatomic, strong) GDVideoPlayer *tlVideoPlayer;

/** NVR 播放器：右上角 Top-Right */
@property (nonatomic, strong) GDVideoPlayer *trVideoPlayer;

/** NVR 播放器：左下角 Bottom-Left */
@property (nonatomic, strong) GDVideoPlayer *blVideoPlayer;

/** NVR 播放器：右下角 Bottom-Right */
@property (nonatomic, strong) GDVideoPlayer *brVideoPlayer;

/** TUTK 平台 ID （长度：20）*/
@property (nonatomic, copy) NSString *tutkDevId;

/** 3.5 平台 ID （长度：28）*/
@property (nonatomic, copy) NSString *platformDevId;

@end

@implementation NvrPlayerViewController


- (instancetype)initWithDevModel:(DeviceDataModel *)devDataModel
{
    if (self = [super init])
    {
        self.devDataModel  = devDataModel;
        self.tutkDevId     = [devDataModel.DeviceId substringFromIndex:8]; // 截取掉下标7之后的字符串;
        self.platformDevId = devDataModel.DeviceId;
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initParam];
    
    [self addCustomViews];
    
    [self addSettingButton];
    
    if (GosDeviceStatusOnLine == self.devDataModel.Status)
    {
        [self addBackgroundRunningEvent];
    }
    
    __weak typeof(self)weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法获取 NVR 设备推送消息！");
            return ;
        }
        [strongSelf reqPushData];
        
        [strongSelf.centerView configDateLabelWithStr:[strongSelf getCurrentDateAndTime]];
    });
    
    _writeFilePath = [self getWriteFilePath];
    _pWriteFile    = fopen([_writeFilePath cStringUsingEncoding:NSUTF8StringEncoding], "ab");  // 以追加二进制方式打开文件

}


- (NSString *)getWriteFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *fileName = @"RawData.h264";
    
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    
    return filePath;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _isViewDisappare = NO;
    // 刷新设备名称和导航条透明度
    self.navigationController.navigationBar.translucent = YES;
    
    for (DeviceDataModel *model in [[DeviceManagement sharedInstance] deviceListArray])
    {
        if ([model.DeviceId isEqualToString:self.devDataModel.DeviceId])
        {
            _nvrDevNickName = model.DeviceName;
            break;
        }
    }
    self.navigationItem.title = _nvrDevNickName;
    
    if (GosDeviceStatusOffLine == self.devDataModel.Status)
    {
        [self stopAllActivity];
        
        for (int i = 1; i <= 4 ; i++)
        {
            [self configReloadBtnHidden:YES
                               position:i];
        }
        [self configOffLineBtnHidden:NO];
    }
    else if (GosDeviceStatusOnLine == self.devDataModel.Status)
    {
        [self startAllActivity];
        
        [self setApiNetDelegate];
        
        for (int i = 1; i <= 4 ; i++)
        {
            [self configReloadBtnHidden:YES
                               position:i];
        }
        [self configOffLineBtnHidden:YES];
    }
    else if (GosDeviceStatusSleep == self.devDataModel.Status)
    {
        
    }
    else
    {
        
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (YES == _isFirstAppear)
    {
        [self saveNvrShowViewFrame];
        _isFirstAppear = NO;
    }
    
    if (GosDeviceStatusOffLine == self.devDataModel.Status)
    {
        
    }
    else if (GosDeviceStatusOnLine == self.devDataModel.Status)
    {
        [self createNvrPlayers];
        
        [self startGetNvrVideoData];
    }
    else if (GosDeviceStatusSleep == self.devDataModel.Status)
    {
        
    }
    else
    {
        
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (GosDeviceStatusOffLine == self.devDataModel.Status)
    {
        
    }
    else if (GosDeviceStatusOnLine == self.devDataModel.Status)
    {
        [self stopGetNvrVideoData];
        
        [self releaseNvrPlayers];
        
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
    
    _isViewDisappare = YES;
}


- (void)dealloc
{
    NSLog(@"----------- NvrPlayerViewController dealloc -----------");
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - 保存设置相关
#pragma mark -- 初始化参数
- (void)initParam
{
    _isFirstAppear      = YES;
    _isFullScreen       = NO;
    _isHiddenCenterView = NO;
    _screenWidth        = SCREEN_WIDTH;
    _screenHeight       = SCREEN_HEIGHT;
    self.transformState = TransformViewSmall;
    if (_screenWidth > _screenHeight)
    {
        _screenWidth    = SCREEN_HEIGHT;
        _screenHeight   = SCREEN_WIDTH;
    }
    // 禁用自动锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    _isBackFromSingleView = NO;
    for (int i = 0; i < 4; i++)
    {
        _isReceiveData[i]      = NO;
        _isHiddenRealoadBtn[i] = YES;
    }
    for (int i = 0; i < 4; i++)
    {
        _isStopVideo[i] = YES;
    }
}


#pragma mark -- 添加自定义子View
- (void)addCustomViews
{
    CGRect nvrPlayViewFrame = CGRectMake(0,
                                         NAV_BAR_HEIGHT,
                                         _screenWidth,
                                         _screenWidth * PLAY_VIEW_SCALE);
    CGRect centerViewFrame  = CGRectMake(0,
                                         _screenWidth * PLAY_VIEW_SCALE + NAV_BAR_HEIGHT,
                                         _screenWidth,
                                         CENTER_VIEW_HEIGHT);
    CGRect pushMsgViewFrame = CGRectMake(0,
                                         _screenWidth * PLAY_VIEW_SCALE + CENTER_VIEW_HEIGHT + NAV_BAR_HEIGHT,
                                         _screenWidth,
                                         _screenHeight - (_screenWidth * PLAY_VIEW_SCALE + CENTER_VIEW_HEIGHT + 64.0f));
    self.nvrPlayView = [[NvrPlayView alloc] initWithFrame:nvrPlayViewFrame];
    self.centerView  = [[NvrCenterView alloc] initWithFrame:centerViewFrame];
    self.pushMsgView = [[NvrPushMsgView alloc] initWithFrame:pushMsgViewFrame];
    self.pushMsgView.deviceId = self.devDataModel.DeviceId;
    self.nvrPlayView.delegate = self;
    self.centerView.delegate  = self;
    [self.view addSubview:self.nvrPlayView];
    [self.view addSubview:self.centerView];
    [self.view addSubview:self.pushMsgView];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
}


#pragma mark -- 保存竖屏是 NVR 单画面 frame
- (void)saveNvrShowViewFrame
{
    _portraintPlayViewSize = self.nvrPlayView.topLeftPlayView.bounds.size;
    _landscapePlayViewSize = CGSizeMake(_screenHeight * 0.5, _screenWidth * 0.5);
}


#pragma mark -- 添加设置按钮
- (void)addSettingButton
{
    UIButton *settingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    settingButton.frame = CGRectMake(0.0f, 0.0f, 40.0f, 40.0f);
    [settingButton setImage:[UIImage imageNamed:@"PlayBlackSetting"]
                   forState:UIControlStateHighlighted];
    [settingButton setImage:[UIImage imageNamed:@"PlayWhiteSetting"]
                   forState:UIControlStateNormal];
    [settingButton addTarget:self
                      action:@selector(showNvrSettingView:)
            forControlEvents:UIControlEventTouchUpInside];
    settingButton.exclusiveTouch = YES;
    
    UIBarButtonItem *rightBarButtomItem = [[UIBarButtonItem alloc] initWithCustomView:settingButton];
    rightBarButtomItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.rightBarButtonItem = rightBarButtomItem;
}


#pragma mark -- 跳转至 NVR 设置页面
-(void)showNvrSettingView:(UIButton *)sender
{
    NSLog(@"跳转至 NVR 设置页面");
    NvrSettingViewController *nvrSettingVC = [[NvrSettingViewController alloc] initWithDevDataModel:self.devDataModel];
    if (nvrSettingVC)
    {
        [self.navigationController pushViewController:nvrSettingVC
                                             animated:YES];
    }
}


#pragma mark -- 查询推送消息
- (void)reqPushData
{
    self.pushMsgView.pushMsgDataArray = [[PushMessageManagement sharedInstance] pushMsgArrayWithDevId:self.platformDevId];
    if (!self.pushMsgView.pushMsgDataArray)
    {
        self.pushMsgView.pushMsgDataArray = [NSMutableArray arrayWithCapacity:0];
    }
    if (0 >= self.pushMsgView.pushMsgDataArray.count)
    {
        [self.pushMsgView configNoPushMsgViewHidden:NO];
        return;
    }
    else
    {
        [self.pushMsgView configNoPushMsgViewHidden:YES];
        [self.pushMsgView.pushMsgTableView reloadData];
    }
}


#pragma mark -- 配置 Center View 是否隐藏（横屏全屏模式下）
- (void)configCenterViewHidden:(BOOL)isHidden
{
    if (NO == _isFullScreen)
    {
        NSLog(@"不是横屏全屏模式，无法设置 Center View 隐藏！");
        return;
    }
    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:TRANSFORM_DURATION * 0.5f
                     animations:^{
                         
                         __strong typeof(weakSelf)strongSelf = weakSelf;
                         if (!strongSelf)
                         {
                             NSLog(@"对象丢失，无法配置 Center View 是否隐藏");
                             return ;
                         }
                         if (NO == isHidden) // 显示
                         {
                             strongSelf.centerView.center = CGPointMake(0 + 0.5 * CENTER_VIEW_HEIGHT,
                                                                        _screenHeight * 0.5f);
                         }
                         else    // 隐藏
                         {
                             strongSelf.centerView.center = CGPointMake(0 - 0.5 * CENTER_VIEW_HEIGHT,
                                                                        _screenHeight * 0.5f);
                         }
                     }
                     completion:nil];
}


#pragma mark -- 延迟隐藏 Center View（横屏时）
- (void)laterHiddenCenterView
{
    if (NO == _isFullScreen)
    {
        return;
    }
    // 先取消之前的延时调用
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(performLaterHiddenCenterView)
                                               object:nil];
    [self performSelector:@selector(performLaterHiddenCenterView)
               withObject:nil
               afterDelay:3.0f];
}


#pragma mark -- 执行延迟隐藏 Center View（横屏时）
- (void)performLaterHiddenCenterView
{
    _isHiddenCenterView = YES;
    [self configCenterViewHidden:_isHiddenCenterView];
}


#pragma mark -- 开启所有 Activity 动画
- (void)startAllActivity
{
    [self.nvrPlayView startActivityAnimationOnPosition:PositionTopLeft];
    [self.nvrPlayView startActivityAnimationOnPosition:PositionTopRight];
    [self.nvrPlayView startActivityAnimationOnPosition:PositionBottomLeft];
    [self.nvrPlayView startActivityAnimationOnPosition:PositionBottomRight];
}


#pragma mark -- 停止所有 Activity 动画
- (void)stopAllActivity
{
    [self stopActivityOnPosition:PositionTopLeft];
    [self stopActivityOnPosition:PositionTopRight];
    [self stopActivityOnPosition:PositionBottomLeft];
    [self stopActivityOnPosition:PositionBottomRight];
}


#pragma mark -- 停止 Activity 动画
- (void)stopActivityOnPosition:(PositionType)position
{
    [self.nvrPlayView stopActivityAnimationOnPosition:position];
}


#pragma mark -- 设置‘重新加载’按钮是否隐藏
- (void)configReloadBtnHidden:(BOOL)isHidden
                    position:(PositionType)position
{
    [self.nvrPlayView configReloadBtnHidden:isHidden
                                 onPosition:position];
    if (position - 1< 4)
    {
        _isHiddenRealoadBtn[position - 1] = isHidden;
    }
}


#pragma mark -- 设置‘不在线’按钮是否隐藏
- (void)configOffLineBtnHidden:(BOOL)isHidden
{
    [self.nvrPlayView configOfflineBtnHidden:isHidden];
}


#pragma mark -- 显示/隐藏 statue bar
- (void)hiddentStatueBar:(BOOL)isHidden
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[UIApplication sharedApplication] setStatusBarHidden:isHidden
                                                withAnimation:UIStatusBarAnimationFade];
    });
}


#pragma mark -- 获取当前日期
- (NSString *)getCurrentDateAndTime
{
    NSDate *date =[NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *currentDate = [formatter stringFromDate:date];
    
    return [NSString stringWithFormat:@"< %@ >", currentDate];
}


#pragma mark -- 进入全屏
- (void)enterFullscreen
{    
    if (TransformViewSmall != self.transformState)
    {
        return;
    }
    self.transformState = TransformViewAnimating;
    
    self.centerView.hidden     = YES;
    
    // 记录进入全屏前的parentView和frame
    self.nvrPlayViewFrame      = self.nvrPlayView.frame;
    self.nvrPlayViewParentView = self.nvrPlayView.superview;
    self.centerViewFrame       = self.centerView.frame;
    self.centerViewParentView  = self.centerView.superview;
    
    // movieView移到window上
    CGRect nvrPlayViewRectInWindow = [self.view convertRect:self.nvrPlayView.bounds
                                                     toView:[UIApplication sharedApplication].keyWindow];
    [self.nvrPlayView removeFromSuperview];
    self.nvrPlayView.frame = nvrPlayViewRectInWindow;
    [[UIApplication sharedApplication].keyWindow addSubview:self.nvrPlayView];
    
    CGRect centerViewRectInWindow = [self.view convertRect:self.centerView.bounds
                                                    toView:[UIApplication sharedApplication].keyWindow];
    [self.centerView removeFromSuperview];
    self.centerView.frame = centerViewRectInWindow;
    [[UIApplication sharedApplication].keyWindow addSubview:self.centerView];
    
    // 执行动画
    [UIView animateWithDuration:TRANSFORM_DURATION
                     animations:^{
                         
                         [self hiddentStatueBar:YES];
                         self.nvrPlayView.transform = CGAffineTransformMakeRotation(M_PI_2);
                         self.nvrPlayView.bounds = CGRectMake(0,
                                                              0,
                                                              _screenHeight,
                                                              _screenWidth);
                         self.nvrPlayView.center = CGPointMake(_screenWidth * 0.5f,
                                                               _screenHeight * 0.5f);
                         
                         self.centerView.transform = CGAffineTransformMakeRotation(M_PI_2);
                         self.centerView.bounds = CGRectMake(0,
                                                             0,
                                                             _screenHeight,
                                                             CENTER_VIEW_HEIGHT);
                         self.centerView.center = CGPointMake(CENTER_VIEW_HEIGHT * 0.5f,
                                                              _screenHeight * 0.5f);
                         
                         [self refreshStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
                         
                         _isHiddenCenterView = YES;
                         [self configCenterViewHidden:_isHiddenCenterView];
                     }
                     completion:^(BOOL finished) {
                         
                         self.transformState    = TransformViewFullscreen;
                         self.centerView.hidden = NO;
                         _isHiddenCenterView = NO;
                         [self configCenterViewHidden:_isHiddenCenterView];
                         
                         [self laterHiddenCenterView];
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
    self.centerView.hidden  = YES;
    CGRect nvrPlayViewFrame = [self.nvrPlayViewParentView convertRect:self.nvrPlayViewFrame
                                                               toView:[UIApplication sharedApplication].keyWindow];
    CGRect centerViewFrame  = [self.centerViewParentView convertRect:self.centerViewFrame
                                                              toView:[UIApplication sharedApplication].keyWindow];
    // 先 Center View
    [UIView animateWithDuration:TRANSFORM_DURATION * 0.1f
                     animations:^{
                         
                         self.centerView.transform = CGAffineTransformIdentity;
                         self.centerView.frame = centerViewFrame;
                         
                         [self.centerView removeFromSuperview];
                         self.centerView.frame = self.centerViewFrame;
                         [self.centerViewParentView addSubview:self.centerView];
                         
                         [self refreshStatusBarOrientation:UIInterfaceOrientationPortrait];
                     }
                     completion:^(BOOL finished) {
                         
                         self.centerView.hidden= NO;
                     }];
    // 再 Play View
    [UIView animateWithDuration:TRANSFORM_DURATION
                     animations:^{
                         
                         self.nvrPlayView.transform = CGAffineTransformIdentity;
                         self.nvrPlayView.frame = nvrPlayViewFrame;
                         
                         // movieView回到竖屏位置
                         [self.nvrPlayView removeFromSuperview];
                         self.nvrPlayView.frame = self.nvrPlayViewFrame;
                         [self.nvrPlayViewParentView addSubview:self.nvrPlayView];
                     }
                     completion:^(BOOL finished) {
                         
                         self.transformState = TransformViewSmall;
                         
                         [self hiddentStatueBar:NO];
                     }];
}


#pragma mark -- 设置状态栏 位置
- (void)refreshStatusBarOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    [[UIApplication sharedApplication] setStatusBarOrientation:interfaceOrientation
                                                      animated:YES];
}


#pragma mark - NvrPlayViewDelegate
#pragma mark -- 单击处理
- (void)singleTapOnPosition:(PositionType)positionType
{
    if (NO == _isFullScreen)
    {
        NSLog(@"不是横屏全屏模式，不响应单击事件");
        return;
    }
    NSLog(@"单击。。。。");
    _isHiddenCenterView = !_isHiddenCenterView;
    [self configCenterViewHidden:_isHiddenCenterView];
}


#pragma mark -- 双击处理
- (void)doubleTapOnPosition:(PositionType)positionType
{
    NvrSinglePlayViewController *singlePlayVC = [[NvrSinglePlayViewController alloc] initWithDevModel:self.devDataModel
                                                                                           onPosition:positionType];
    if (singlePlayVC)
    {
        _isBackFromSingleView           = YES;
        singlePlayVC.stopNvrSubStream   = _isStopVideo[positionType - 1];
        singlePlayVC.fourViewFullScreen = _isFullScreen;
        [self.navigationController pushViewController:singlePlayVC
                                             animated:YES];
    }
    if (YES == _isFullScreen)
    {
        _isFullScreen = !_isFullScreen;
        [self.centerView configDateLabelHidden:_isFullScreen];
        [self exitFullscreen];
    }
}


#pragma mark -- ‘重新加载’按钮事件回调处理
- (void)reloadDataOnPosition:(PositionType)positionType
{
    [self configReloadBtnHidden:YES
                       position:positionType];
    _isHiddenRealoadBtn[positionType - 1] = YES;
    [self reqStartVideoDataWithChannel:positionType - 1];
}


#pragma mark - NvrCenterViewDelegate
#pragma mark -- NVR 录像列表 按钮事件
- (void)nvrRecordListAction
{
    if (YES == _isFullScreen)
    {
        _isFullScreen = !_isFullScreen;
        [self.centerView configDateLabelHidden:_isFullScreen];
        [self exitFullscreen];
    }
    NvrSearchPlaybackViewController *searchPlaybackVC = [[NvrSearchPlaybackViewController alloc] initWithDevModel:self.devDataModel];
    if (searchPlaybackVC)
    {
        [self.navigationController pushViewController:searchPlaybackVC
                                             animated:YES];
    }
}


#pragma mark -- '全屏' 按钮事件
- (void)nvrFullScreenAction
{
    NSLog(@"nvrFullScreenAction");
    _isFullScreen = !_isFullScreen;
    [self.centerView configDateLabelHidden:_isFullScreen];
    if (NO == _isFullScreen)
    {
        [self exitFullscreen];
        
        [self updatePlayerViewSize:_portraintPlayViewSize];
    }
    else
    {
        [self enterFullscreen];
        
        [self updatePlayerViewSize:_landscapePlayViewSize];
    }
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
    
    [self releaseNvrPlayers];
    
    [self stopAllActivity];
}


#pragma mark -- 进入 Forground 监控通知
- (void)willEnterForeground
{
    if (YES == _isViewDisappare)
    {
        return;
    }
    
    [self createNvrPlayers];
    
    [self startGetNvrVideoData];
    
    [self startAllActivity];
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
- (void)createNvrPlayers
{
    if (!self.devDataModel.DeviceId)
    {
        NSLog(@"无法创建 NVR 播放器，nvrDeviceId = %@", self.devDataModel.DeviceId);
        
        return ;
    }
    if (self.nvrPlayView.topLeftPlayView)
    {
        self.tlVideoPlayer = [[GDVideoPlayer alloc] init];
        [self.tlVideoPlayer initWithViewAndDelegate:self.nvrPlayView.topLeftPlayView
                                           Delegate:self
                                        andDeviceID:self.tutkDevId
                                 andWithdoubleScale:NO
                                    nvrPositionType:PositionTopLeft];
        NSString *covertPath = [[MediaManager shareManager] mediaPathWithDevId:self.tutkDevId
                                                                      fileName:nil
                                                                     mediaType:GosMediaCover
                                                                    deviceType:GosDeviceNVR
                                                                      position:PositionTopLeft];
        self.tlVideoPlayer.coverPath = covertPath;
        NSLog(@"创建：topLeftVideoPlayer ");
    }
    
    if (self.nvrPlayView.topRightPlayView)
    {
        self.trVideoPlayer = [[GDVideoPlayer alloc] init];
        [self.trVideoPlayer initWithViewAndDelegate:self.nvrPlayView.topRightPlayView
                                           Delegate:self
                                        andDeviceID:self.tutkDevId
                                 andWithdoubleScale:NO
                                    nvrPositionType:PositionTopRight];
        NSString *covertPath = [[MediaManager shareManager] mediaPathWithDevId:self.tutkDevId
                                                                      fileName:nil
                                                                     mediaType:GosMediaCover
                                                                    deviceType:GosDeviceNVR
                                                                      position:PositionTopRight];
        self.trVideoPlayer.coverPath = covertPath;
        NSLog(@"创建：topRightVideoPlayer ");
    }
    
    if (self.nvrPlayView.bottomLeftPlayView)
    {
        self.blVideoPlayer = [[GDVideoPlayer alloc] init];
        [self.blVideoPlayer initWithViewAndDelegate:self.nvrPlayView.bottomLeftPlayView
                                           Delegate:self
                                        andDeviceID:self.tutkDevId
                                 andWithdoubleScale:NO
                                    nvrPositionType:PositionBottomLeft];
        NSString *covertPath = [[MediaManager shareManager] mediaPathWithDevId:self.tutkDevId
                                                                      fileName:nil
                                                                     mediaType:GosMediaCover
                                                                    deviceType:GosDeviceNVR
                                                                      position:PositionBottomLeft];
        self.blVideoPlayer.coverPath = covertPath;
        NSLog(@"创建：bottomLeftVideoPlayer ");
    }
    
    if (self.nvrPlayView.bottomRightPlayView)
    {
        self.brVideoPlayer = [[GDVideoPlayer alloc] init];
        [self.brVideoPlayer initWithViewAndDelegate:self.nvrPlayView.bottomRightPlayView
                                           Delegate:self
                                        andDeviceID:self.tutkDevId
                                 andWithdoubleScale:NO
                                    nvrPositionType:PositionBottomRight];
        NSString *covertPath = [[MediaManager shareManager] mediaPathWithDevId:self.tutkDevId
                                                                      fileName:nil
                                                                     mediaType:GosMediaCover
                                                                    deviceType:GosDeviceNVR
                                                                      position:PositionBottomRight];
        self.brVideoPlayer.coverPath = covertPath;
        NSLog(@"创建：bottomRightVideoPlayer ");
    }
}


#pragma mark -- 释放播发器
- (void)releaseNvrPlayers
{
    // 左上角播放器
    if (self.tlVideoPlayer)
    {
        [self.tlVideoPlayer stopPlay];
        self.tlVideoPlayer.delegate = nil;
        self.tlVideoPlayer = nil;
    }
    // 右上角播放
    if (self.trVideoPlayer)
    {
        [self.trVideoPlayer stopPlay];
        self.trVideoPlayer.delegate = nil;
        self.trVideoPlayer = nil;
    }
    // 左下角播放器
    if (self.blVideoPlayer)
    {
        [self.blVideoPlayer stopPlay];
        self.blVideoPlayer.delegate = nil;
        self.blVideoPlayer = nil;
    }
    // 右下角播放器
    if (self.brVideoPlayer)
    {
        [self.brVideoPlayer stopPlay];
        self.brVideoPlayer.delegate = nil;
        self.brVideoPlayer = nil;
    }
}


#pragma mark -- 屏幕旋转更新播放窗口大小
- (void)updatePlayerViewSize:(CGSize)viewSize
{
    NSLog(@"NvrPlayer updatePlayerViewSize = %@", NSStringFromCGSize(viewSize));
    [self.tlVideoPlayer nvrUpdatePlayerViewSize:viewSize];
    [self.trVideoPlayer nvrUpdatePlayerViewSize:viewSize];
    [self.blVideoPlayer nvrUpdatePlayerViewSize:viewSize];
    [self.brVideoPlayer nvrUpdatePlayerViewSize:viewSize];
}


#pragma mark - 视频流
#pragma mark -- 开始拉取视频流
#pragma mark -- 获取所有视频流
- (void)startGetNvrVideoData
{
    
    for (int i = 0; i < 4 /* self.devDataModel.avChnnelNum - 5*/; i++)
    {
        NSLog(@"==== 准备发送获取 NVR 第 %d 路视频流请求,总路数：%ld", i, self.devDataModel.avChnnelNum);
        [self reqStartVideoDataWithChannel:i];
    }
}


#pragma mark -- 请求‘开启’视频流
- (void)reqStartVideoDataWithChannel:(long)avChannel
{
    __weak typeof(self)weakSelf = self;
    [[NetAPISet sharedInstance] nvrStartGetVideoDataWithDeviceId:self.devDataModel.DeviceId
                                                       avChannel:avChannel
                                                     playViewNum:4
                                            nvrGetVideoDataBlock:^(NvrGetDataStatus retStatus,
                                                                   NSString *nvrDeviceId,
                                                                   long avChannel) {
                                                
                                                __strong typeof(weakSelf)strongSelf = weakSelf;
                                                if (!strongSelf)
                                                {
                                                    NSLog(@"对象丢失，无法处理 NVR 四画面拉流结果！");
                                                    return ;
                                                }
                                                [strongSelf handleReqStartVideoDataResult:retStatus
                                                                                 deviceId:nvrDeviceId
                                                                                avChannel:avChannel];
                                            }];
    if (avChannel < 4)
    {
        _isReceiveData[avChannel] = NO;
    }
}


#pragma mark -- 开始拉流超时，显示‘重新加载’按钮
- (void)handleReqVideoTimeoutOnChannel:(NSNumber *)avChannelObj
{
    long avChannel = [avChannelObj longValue];
    if (avChannel < 4
        && NO == _isReceiveData[avChannel])
    {
        [self configReloadBtnHidden:NO
                           position:avChannel + 1];
    }
}


#pragma mark -- 处理请求‘开启’视频流结果
- (void)handleReqStartVideoDataResult:(NvrGetDataStatus)retStatus
                             deviceId:(NSString *)deviceId
                            avChannel:(long)avChannel
{
    switch (retStatus)
    {
        case NvrGetDataSuccess:         // 拉流成功
        {
            NSLog(@"NVR 开启四画面视频流成功，nvrDeviceId = %@，avChannel = %ld", deviceId, avChannel);
            __weak typeof(self)weakSelf = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                         (int64_t)(REQ_VIDEO_TIMEOUT * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                               
                               __strong typeof(weakSelf)strongSelf = weakSelf;
                               if (!strongSelf)
                               {
                                   return ;
                               }
                               [strongSelf handleReqVideoTimeoutOnChannel:[NSNumber numberWithLong:avChannel]];
                           });
        }
            break;
            
        case NvrGetDataFailure:         // 拉流失败
        {
            NSLog(@"NVR 开启四画面视频流失败，nvrDeviceId = %@，avChannel = %ld", deviceId, avChannel);
            [self configReloadBtnHidden:NO
                               position:avChannel + 1];
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
}


#pragma mark -- 停止拉取视频流
- (void)stopGetNvrVideoData
{
    __weak typeof(self)weakSelf = self;
    for (int i = 0; i < 4 /*self.devDataModel.avChnnelNum - 5*/; i++)
    {
        NSLog(@"==== 准备发送停止 NVR 第 %d 路视频流请求,总路数：%ld", i, self.devDataModel.avChnnelNum);
        [[NetAPISet sharedInstance] nvrStopGetVideoDataWithDeviceId:self.devDataModel.DeviceId
                                                          avChannel:i
                                              nvrStopVideoDataBlock:^(BOOL isSuccess,
                                                                      NSString *nvrDeviceId,
                                                                      long avChannel) {
                                                  
                                                  if (4 > avChannel)
                                                  {
                                                      NSDictionary *stopVideResultDict = @{[NSNumber numberWithLong:avChannel] : [NSNumber numberWithBool:isSuccess]};
                                                      [[NSNotificationCenter defaultCenter] postNotificationName:NVR_STOP_VIDEO_NOTIFY
                                                                                                          object:stopVideResultDict];
                                                  }
                                                  __strong typeof(weakSelf)strongSelf = weakSelf;
                                                  if (!strongSelf)
                                                  {
                                                      NSLog(@"对象丢失，无法处理 NVR 四画面停流结果！");
                                                      return ;
                                                  }
                                                  [strongSelf handleReqStopVideoDataResult:isSuccess
                                                                                  deviceId:nvrDeviceId
                                                                                 avChannel:avChannel];
                                               }];
    }
}


#pragma mark -- 处理请求‘关闭’视频流结果
- (void)handleReqStopVideoDataResult:(BOOL)isSuccess
                            deviceId:(NSString *)deviceId
                           avChannel:(long)avChannel
{
    if (NO == isSuccess)
    {
        NSLog(@"停止 NVR 四画面视频流失败，nvrDeviceId = %@ avChannel = %ld", deviceId, avChannel);
    }
    else
    {
        NSLog(@"停止 NVR 四画面视频流成功，nvrDeviceId = %@ avChannel = %ld", deviceId, avChannel);
    }
    if (4 > avChannel)
    {
        _isStopVideo[avChannel] = isSuccess;
    }
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
    if (YES == _isBackFromSingleView)
    {
//        NSLog(@"从 NVR 单画面回来，暂时不播放！");
//        return;
    }
//    NSLog(@"NVR视频数据：length-%d, isIFrame = %d, avChannel-%d", length, isIFrame, avChannel);
    if (avChannel < 4 && YES == isIFrame)
    {
        [self stopActivityOnPosition:avChannel + 1];
        
        _isReceiveData[avChannel] = YES;
        
        if (NO == _isHiddenRealoadBtn[avChannel])
        {
            [self configReloadBtnHidden:YES
                               position:avChannel + 1];
        }
    }
    switch (avChannel)
    {
        case PositionTopLeft - 1:
        {
            
            if (YES == isIFrame)
            {
                NSLog(@"NVR:Top left 视频数据: deviceId = %@", deviceId);
            }
            [self.tlVideoPlayer AddVideoFrame:pContentBuffer
                                          len:length
                                           ts:timeStamp
                                       framNo:framNO
                                    frameRate:frameRate
                                       iFrame:isIFrame
                                 andDeviceUid:deviceId];
            
        }
            break;
            
        case PositionTopRight - 1:
        {
            
            if (YES == isIFrame)
            {
                NSLog(@"NVR:Top right 视频数据: deviceId = %@", deviceId);
            }
            [self.trVideoPlayer AddVideoFrame:pContentBuffer
                                          len:length
                                           ts:timeStamp
                                       framNo:framNO
                                    frameRate:frameRate
                                       iFrame:isIFrame
                                 andDeviceUid:deviceId];
            
        }
            break;
            
        case PositionBottomLeft - 1:
        {
            
            if (YES == isIFrame)
            {
                NSLog(@"NVR:Bottom left 视频数: deviceId = %@", deviceId);
            }
            [self.blVideoPlayer AddVideoFrame:pContentBuffer
                                          len:length
                                           ts:timeStamp
                                       framNo:framNO
                                    frameRate:frameRate
                                       iFrame:isIFrame
                                 andDeviceUid:deviceId];
            
        }
            break;
            
        case PositionBottomRight - 1:
        {
            
            if (YES == isIFrame)
            {
                NSLog(@"NVR:Bottom right 视频数据: deviceId = %@", deviceId);
            }
            [self.brVideoPlayer AddVideoFrame:pContentBuffer
                                          len:length
                                           ts:timeStamp
                                       framNo:framNO
                                    frameRate:frameRate
                                       iFrame:isIFrame
                                 andDeviceUid:deviceId];
//            fseek(_pWriteFile, 0, SEEK_END);
//            fwrite(pContentBuffer, length, 1, _pWriteFile);

            
        }
            break;
            
        default:
        {
            
        }
            break;
    }
}


@end
