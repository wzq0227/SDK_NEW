//
//  CloudPlayBackViewController.m
//  ULife3.5
//
//  Created by AnDong on 2018/3/17.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "CloudPlayBackViewController.h"
#import "Masonry.h"
#import "UIColor+YYAdd.h"
#import "UIView+YYAdd.h"
#import "CameraInfoManager.h"
#import "DeviceManagement.h"
#import "UISettingManagement.h"
#import "GDVideoPlayer.h"
#import "YYKitMacro.h"
#import <AVFoundation/AVFoundation.h>
#import <RealReachability.h>
#import "DevicePlayManager.h"
#import "DeviceDataModel.h"
#import "VideoImageManager.h"
#import "NSTimer+YYAdd.h"
#import "HWLogManager.h"
#import "MediaManager.h"
#import "EnlargeClickButton.h"
#import "StreamPasswordView.h"
#import "ACVideoDecoder.h"
#import "GDPlayerView.h"
#import "PCMPlayer.h"
#import "SaveDataModel.h"
#import "CloudPlayModel.h"
#import "CloudRecordingServiceInfoVC.h"
#import "CSPackageTypeVC.h"
#import "SDCloudAlarmModel.h"
#import "SDCloudVideoModel.h"
#import "AHRuler.h"
#import "OSSUtil.h"
#import "OSSTask.h"
#import "CloudAlarmModel.h"
#import "CloudVideoModel.h"
#import "OSSClient.h"
#import "OSSModel.h"
#import <AFNetworking.h>
#import "CloudShortCutViewController.h"
#import "GOSNetStatusManager.h"

#import "CSNetworkLib.h"

//播放通知Key
static NSString *const PlayStatusNotification = @"PlayStatusNotification";
static NSString *const ConvertMP4Notification = @"ConvertMP4Notification";

#define playViewRatio (SYName_iPhone_X == [SYDeviceInfo syDeviceName] ? (3/4.0f):(9/16.0f))
#define trueSreenWidth  (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))
#define trueScreenHeight (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define HeightForStatusBarAndNaviBar (SYName_iPhone_X == [SYDeviceInfo syDeviceName]?88:64)

/** 全屏切换动画时长（单位：秒） */
#define TRANSFORM_DURATION 0.25f

/** 横屏旋转切换状态 枚举*/
typedef NS_ENUM(NSUInteger, TransformViewState) {
    TransformViewSmall,             // 竖屏（小屏）状态
    TransformViewAnimating,         // 正在切换状态
    TransformViewFullscreen,        // 横屏（全屏）状态
};


@interface CloudPlayBackViewController ()<
                                        GDVideoPlayerDelegate,
                                        AHRrettyRulerDelegate,
                                        UIPickerViewDelegate,
                                        UIPickerViewDataSource,UIAlertViewDelegate
>{

}

/** 播放视频 View */
@property (strong, nonatomic)  UIView *playView;

/** 播放控制 View */
@property (strong, nonatomic)  UIView *playControllView;

/** 视频数据加载 Activity */
@property (strong, nonatomic)  UIActivityIndicatorView *loadVideoActivity;

#pragma mark - 全屏按钮
/** 播放器 */
@property (nonatomic, strong) GDVideoPlayer *gdVideoPlayer;

/** 平台UID*/
@property (nonatomic, strong)NSString *platformUID;

/** 是否全屏 */
@property (nonatomic,assign)BOOL isLandSpace;

/** 拍照按钮点击声音 播放器 */
@property (nonatomic, strong) AVAudioPlayer *snapShotBtnAudioPlayer;

//audio Flag
@property (nonatomic,assign)BOOL isAudioOn;



#pragma mark - 云存储相关

/***************************************云存储相关*********************************************/

/***************************************云存储UI*********************************************/
/**刻度尺View*/
@property (nonatomic,strong)AHRuler *ruler;

/**云存储底部View*/
@property (strong, nonatomic)  UIView *cloudBottomView;

/** 云存储声音开关 Button */
@property (strong, nonatomic)  UIButton *cloudSoundBtn;

/** 云存储剪切 Button */
@property (strong, nonatomic) UIButton *cloudShortCutBtn;

/** 云存储拍照 Button */
@property (strong, nonatomic) UIButton *cloudSnapshotBtn;

/** 云存储声音开关 Label */
@property (nonatomic,strong)UILabel *cloudSoundLabel;

/** 云存储剪切 Label */
@property (nonatomic,strong)UILabel *cloudShortCutLabel;

/** 云存储拍照 Label */
@property (nonatomic,strong)UILabel *cloudSnapshotLabel;

/** 云存储弹出的日期选择View */
@property (nonatomic,strong)UIView *pickCoverView;

/**日期选择view*/
@property (nonatomic,strong)UIPickerView *pickView;

/**选择日期按钮*/
@property (nonatomic,strong)UIButton *dateButton;

/**netErrorButton*/
@property (nonatomic,strong)UIButton *netErrorButton;


/**日期View*/
@property (nonatomic,strong)UIView *dateView;

/**没有视频数据提示label*/
@property (nonatomic,strong)UILabel *noVideoDataLabel;

/**云存储预览图View*/
@property (nonatomic,strong)UIButton *previewView;

/**云存储预览图ImgageView*/
@property (nonatomic,strong)UIImageView *playImageView;

/**云存储预览图类型图标View*/
@property (nonatomic,strong)UIImageView *iconImgaeView;

/**云存储预览图底部View*/
@property (nonatomic,strong)UIView *preViewCoverView;

/**云存储预览图底部ImageView*/
@property (nonatomic,strong)UIImageView *preCoverImgView;

/**云存储预览图时间Label*/
@property (nonatomic,strong)UILabel *previewTimeLabel;

/**云存储预览图加载activity*/
@property (nonatomic,strong)UIActivityIndicatorView *cloudLoadVideoActivity;

/**云存储预览图播放按钮*/
@property (nonatomic,strong)UIImageView *playButton;

/**云存储订购按钮*/
@property (nonatomic,strong)UIButton *cloudOrderButton;

/**视频显示画面宽*/
@property(nonatomic,assign)CGFloat displayWidth;

/**视频显示画面高*/
@property(nonatomic,assign)CGFloat displayHeight;

/**视频实际宽*/
@property(nonatomic,assign)CGFloat videoWidth;

/**视频实际高*/
@property(nonatomic,assign)CGFloat videoHeight;

/***************************************云存储数据*********************************************/

/**云存储设备ID，兼容一拖四*/
@property (nonatomic,strong)NSString *csDeviceID;

/**阿里云client*/
@property (nonatomic,strong)OSSClient *client;

/**返回的token字典*/
@property (nonatomic,strong)NSDictionary *tokenDict;

/**当前选中日期*/
@property (nonatomic,strong)NSDate *currentSelectDate;

/**当前时间日期*/
@property (nonatomic,strong)NSDate *currentTimeDate;

/**pickView date Array*/
@property (nonatomic,strong)NSMutableArray *dateArray;

/**阿里云录制视频数组*/
@property (nonatomic,strong)NSMutableArray *cloudVideoArray;

/**阿里云录制视频url数组*/
@property (nonatomic,strong)NSMutableArray *cloudPlayUrlArray;

/**拷贝的阿里云录制视频url数组*/
@property (nonatomic,strong)NSMutableArray *cacheCloudPlayUrlArray;

/**报警视频数组*/
@property (nonatomic,strong)NSMutableArray *cloudAlarmArray;

/**阿里云下载好的H264播放路径*/
@property(nonatomic,strong)NSString *h264FilePath;

/**阿里云播放视频解码器*/
@property(nonatomic,strong)ACCloudVideoDecoder *videoDecoder;

/**获取预览图解码器*/
@property(nonatomic,strong)ACSeekVideoDecoder *previewDecoder;

/**剪切的编解码器*/
@property (nonatomic,strong)ACCaptureVideoDecoder *captureDecoder;

/**渲染帧数据*/
@property (nonatomic,strong)KxVideoFrameYUV *yuvFrame;

/**当前播放的模型在数组中的索引，用于自动播放和下载下一个 --只会缓存下载一个*/
@property (nonatomic,assign)NSInteger currentPlayIndex;

/**当前播放的数据模型,用于阿里云播放记录*/
@property (nonatomic,strong)CloudPlayModel *currentPlayModel;

/**拖动时候预览时间点*/
@property (nonatomic,assign)NSInteger currentPreviewSeekTimeIndex;

/**拖动时候缓存预览时间点,用于seek到准确位置*/
@property (nonatomic,assign)NSInteger currentPreviewCacheSeekTimeIndex;

/**拖动时候当前播放的时间点*/
@property (nonatomic,assign)NSInteger currentPlaySeekTimeIndex;

/**实际当前播放的model*/
@property (nonatomic,strong)CloudPlayModel *currentActurePlayModel;

/**当前需要seek的Model*/
@property (nonatomic,strong)CloudPlayModel *currentSeekModel;

/**当前播放时间*/
@property (nonatomic,assign)NSInteger currentPlayTime;

/**剪切需要的数据源url地址数组*/
@property (nonatomic,strong)NSMutableArray *shortCutArray;

/**剪切开始时间*/
@property (nonatomic,assign)NSInteger shortCutStartTime;

/**剪切总共时间*/
@property (nonatomic,assign)NSInteger shortCutTotalTime;

/**剪切需要下载的h264数量*/
@property (nonatomic,assign)NSInteger shortCutDownloadCount;

/**剪切视频文件名*/
@property (nonatomic,copy)NSString *shortCutFileName;

/***************************************云存储BOOL标识*********************************************/

/**是否手动切换了日期，这里逻辑相对复杂，需要这个标识符*/
@property (nonatomic,assign)BOOL isChangeDateManual;

/**是否开通云存储*/
@property (nonatomic,assign)BOOL isOrderCloudPlay;

/**是否正在播放云存储*/
@property (nonatomic,assign)BOOL isPlayCloudPlay;

/**云存储的秒表 1s跳动一次*/
@property (nonatomic,strong)NSTimer *secondTimer;

/**重新拉取云存储数据timer 默认是60s*/
@property (nonatomic,strong)NSTimer *reloadDataTimer;

@property (nonatomic,strong)UIButton *pickCancelButton;

/**是否开通云存储*/
@property (nonatomic,assign)BOOL isOrderCloud;

//跳转当天时间戳
@property (nonatomic,assign)int currentDayIndex;

@end

@implementation CloudPlayBackViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];

    //初始化UI
    [self setupUI];

    //初始化音频
    [self audioInit];

    //禁用锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

    //后台事件监听
    [self addBackgroundRunningEvent];

    //创建文件夹
    [self creatFolder];
    
    //开启声音
    _isAudioOn = YES;
    
    [self checkNetwork];
}

- (void)checkNetwork{
    
    [GOSNetStatusManager checkIfUsingCellularData];
}

- (void)stopCheckingNetwork{
    [GOSNetStatusManager stopCheckingUsingCellularData];
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
    
    UILabel *tLabel = [CommonlyUsedFounctions titleLabelWithStr:[NSString stringWithFormat:@"%@-%@",_deviceName,DPLocalizedString(@"PlayVideo_CS")]];
    self.navigationItem.titleView = tLabel;
    [self initAppearAction];

    if (_isLandSpace) {
        [self resetPlayerView];
    }
    
    if (!_isOrderCloud) {
        //云存储逻辑
        [self configCloudPlay];
    }
    
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

            self.cloudBottomView.hidden = NO;
            if (_gdVideoPlayer) {
                [_gdVideoPlayer resizePlayViewFrame:CGRectMake(0, 0, trueSreenWidth, trueSreenWidth * playViewRatio)];
            }
            [self refreshCloudDisplay];
        }
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.videoDecoder ac_pause:NO];
    if (self.gdVideoPlayer) {
        [self.gdVideoPlayer setPlayerView:self.playView];
    }
    self.loadVideoActivity.hidden = YES;
    [self addEnterForegroundNotifications];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent=NO;
    [super viewWillDisappear:animated];
    [self removeEnterForegroundNotifications];
    [self.videoDecoder ac_pause:YES];
}

- (void)dealloc
{
    [self stopCheckingNetwork];
    
    [self releaseBtnSoundAudioPlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"----------- CloudPlayBackViewController dealloc -----------");
}

- (void)setAlarmMsgTime:(NSTimeInterval)alarmMsgTime{
    _alarmMsgTime = alarmMsgTime +7;
}


#pragma mark - 云存储核心逻辑

- (void)configCloudPlay{
    //获取云存储套餐时长
    [self getCloudVideoTime];
}

- (void)configCloudPlayViewWithIsOrdered:(BOOL)isOrdered{
    if (isOrdered) {
        _isOrderCloud = YES;
        //隐藏订购按钮
        self.cloudOrderButton.hidden = YES;
        //开通了云存储
        _videoDecoder = [[ACCloudVideoDecoder alloc] init];
        _previewDecoder = [[ACSeekVideoDecoder alloc]init];
        _captureDecoder = [[ACCaptureVideoDecoder alloc]init];
        //准备View
        [self cloudPlayPrapare];
    }
    else{
        _isOrderCloud = NO;
        //未开通云存储 -获取SD卡数据
        [self showAlertWithMsg:DPLocalizedString(@"OpenCSNotice")];
        
        //添加订购按钮
        [self addOrderBtn];
    }
}

- (void)cloudPlayPrapare{
    //添加播放状态通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playStatusChange:) name:PlayStatusNotification object:nil];

    if (!self.ruler) {
        // 2.创建 AHRuler 对象 并设置代理对象
        self.ruler = [[AHRuler alloc] initWithFrame:CGRectMake(0, HeightForStatusBarAndNaviBar+SCREEN_WIDTH * playViewRatio, [UIScreen mainScreen].bounds.size.width, 120)];
        self.ruler.rulerDeletate = self;
        self.ruler.jumpToNowButton.hidden = YES;
        [self.view addSubview:self.ruler];
        //添加dateButton
        [self.view addSubview:self.dateView];
        [self.dateView addSubview:self.dateButton];
        //当前时间直接获取系统时间
        [self.ruler showRulerScrollViewWithAverage:rulerAverageTypeOne currentValue:[self getcurrentTimeValue]];
        // 初始化pickerView
        UIView *pickCoverView = [[UIView alloc]initWithFrame:CGRectMake(0, SCREEN_WIDTH * playViewRatio + 120 + 60 + HeightForStatusBarAndNaviBar, self.view.bounds.size.width, 150)];
        pickCoverView.backgroundColor = [UIColor whiteColor];
        self.pickCoverView = pickCoverView;
        self.pickCoverView.hidden = YES;
        [self.view addSubview:pickCoverView];
        
        //添加取消按钮
        self.pickCancelButton = [[UIButton alloc]initWithFrame: CGRectMake(self.view.bounds.size.width-100, 20, 60, 30)];
        [self.pickCancelButton addTarget:self action:@selector(cancelPickView) forControlEvents:UIControlEventTouchUpInside];
        self.pickCancelButton.layer.borderWidth = 1.0f;
        self.pickCancelButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.pickCancelButton.layer.masksToBounds = YES;
        self.pickCancelButton.layer.cornerRadius = 5.0f;
        self.pickCancelButton.titleLabel.font = [UIFont systemFontOfSize:14.0f];
        [self.pickCancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.pickCancelButton setTitle:DPLocalizedString(@"Setting_Cancel") forState:UIControlStateNormal];
  

        self.pickView = [[UIPickerView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 150)];
        [self.pickCoverView addSubview:self.pickView];
        [self.pickCoverView addSubview:self.pickCancelButton];

        //指定数据源和委托
        self.pickView.delegate = self;
        self.pickView.dataSource = self;
        [self initBottomView];
        [self.ruler addSubview:self.previewView];
        [self.previewView addSubview:self.playButton];
        [self.previewView addSubview:self.cloudLoadVideoActivity];
        [self.previewView addSubview:self.preViewCoverView];
        [self.preViewCoverView addSubview:self.previewTimeLabel];
        [self.preViewCoverView addSubview:self.preCoverImgView];

    }
}

- (void)cancelPickView{
    self.previewView.hidden = YES;
    [UIView animateWithDuration:0.2 animations:^{
        self.pickCoverView.hidden = YES;
    }];
}

- (void)addOrderBtn{
    dispatch_async_on_main_queue(^{
        self.cloudOrderButton.hidden = _deviceModel.DeviceOwner == GosDeviceShare;
        [self.view addSubview:self.cloudOrderButton];
    });
}

- (long long)getcurrentTimeValue{
    return [self.currentTimeDate timeIntervalSince1970] - [self.currentSelectDate timeIntervalSince1970];
}

#pragma mark -- 设置相关 UI
- (void)setupUI{
    //标题
    self.title = self.deviceName;

    //添加导航按钮
    [self configNavItem];

    //添加子View
    [self.view addSubview:self.playView];
    [self.view addSubview:self.loadVideoActivity];
    [self.view addSubview:self.noVideoDataLabel];
    [self.view addSubview:self.netErrorButton];
    [self makeConstraints];
}

#pragma mark - 设置导航栏按钮
-(void)configNavItem
{
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

#pragma mark - 设置约束
- (void)makeConstraints{
    [self.playView mas_makeConstraints:^(MASConstraintMaker *make) {

        make.top.equalTo(self.view).offset(HeightForStatusBarAndNaviBar);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(self.playView.mas_width).multipliedBy(playViewRatio);
    }];

    [self.loadVideoActivity mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.playView.mas_centerY);
        make.centerX.equalTo(self.playView.mas_centerX);
        make.width.height.equalTo(@50);
    }];

    [self.noVideoDataLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@150);
        make.height.equalTo(@30);
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-200);
    }];

    [self initBottomView];
}

- (void)showAlertWithMsg:(NSString *)msg{
    UIAlertView *msgAlert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:self
                                             cancelButtonTitle:(_deviceModel.DeviceOwner==GosDeviceShare)?DPLocalizedString(@"Title_Confirm"):DPLocalizedString(@"Setting_Cancel")
                                             otherButtonTitles:(_deviceModel.DeviceOwner==GosDeviceShare)?nil:DPLocalizedString(@"Setting_Detail_OrderNow"), nil];
    msgAlert.delegate = self;
    [msgAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        //取消
        [self navBack];
    }
    else{
        //订购
        [self orderCloud];
    }
    
}

//初始化音频任务
- (void)audioInit{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
}


#pragma mark - 进入界面初始化

- (void)initAppearAction{
    //填充播放器
    [self configGDPlayer];
    self.loadVideoActivity.hidden = YES;
}



//#pragma mark - 全屏代理
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [UIView animateWithDuration:0.25 animations:^{
        if (UIDeviceOrientationIsLandscape(toInterfaceOrientation))
        {
            _isLandSpace = YES;
            //全屏处理
            [self.navigationController setNavigationBarHidden:YES animated:NO];
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
            //全屏约束
            [self.playView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.edges.equalTo(self.view);
            }];
            [self refreshCloudDisplay];
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
            self.cloudBottomView.hidden = NO;
            if (_gdVideoPlayer) {
                [_gdVideoPlayer resizePlayViewFrame:CGRectMake(0, 0, trueSreenWidth, trueSreenWidth * playViewRatio)];
            }
            [self refreshCloudDisplay];
        }
        [self.view layoutIfNeeded];

    } completion:^(BOOL finished) {
    }];
}

//设置云存储全屏变换坐标
- (void)refreshCloudDisplay{
    //没有开通云存储直接Return
    if (!_isOrderCloudPlay) {
        return;
    }
    if (_isLandSpace) {
        self.dateView.alpha = 0.7f;
        self.ruler.alpha = 0.7f;
        self.dateView.frame = CGRectMake(0,trueSreenWidth -60, trueScreenHeight, 60);
        self.dateButton.frame = CGRectMake((trueScreenHeight - 120)/2, 20, 120, 30);
        self.ruler.frame = CGRectMake(0, trueSreenWidth -60-120, trueScreenHeight, 120);
        self.pickCoverView.frame = CGRectMake(0, trueSreenWidth -40 - 150,trueScreenHeight, 150);
        self.pickView.frame = CGRectMake(0, 0, trueScreenHeight, 150);
        self.cloudBottomView.hidden = YES;;
        self.previewView.frame = CGRectMake(trueScreenHeight/2.0f - 60,-90, 120, 90);
        self.pickCancelButton.frame = CGRectMake(trueScreenHeight -100, 20, 60, 30);
        //全屏先隐藏云存储
        self.dateView.hidden = YES;
        self.ruler.hidden = YES;
    }
    else{
        self.dateView.alpha = 1.0f;
        self.ruler.alpha = 1.0f;
        self.dateView.frame = CGRectMake(0, HeightForStatusBarAndNaviBar+trueSreenWidth * playViewRatio + 120, trueSreenWidth, 60);
        self.dateButton.frame = CGRectMake((trueSreenWidth - 120)/2, 20, 120, 30);
        self.ruler.frame = CGRectMake(0, HeightForStatusBarAndNaviBar+trueSreenWidth * playViewRatio, trueSreenWidth, 120);
        self.pickCoverView.frame = CGRectMake(0, trueSreenWidth * playViewRatio + 120 + 60 + HeightForStatusBarAndNaviBar, trueSreenWidth, 150);
        self.pickView.frame = CGRectMake(0, 0, trueSreenWidth, 150);
        self.pickCancelButton.frame = CGRectMake(trueSreenWidth -100, 20, 60, 30);
        self.cloudBottomView.hidden = NO;
        self.dateView.hidden = NO;
        self.ruler.hidden = NO;
        self.previewView.frame = CGRectMake(trueSreenWidth/2.0f - 60, -90, 120, 90);
        [self showCloudPlay];
    }
}

- (void)showCloudPlay{
    if (_isLandSpace) {
        if (self.ruler.hidden) {
            self.dateView.hidden = NO;
            self.ruler.hidden = NO;
        }
        else{
            self.dateView.hidden = YES;
            self.ruler.hidden = YES;
            self.pickCoverView.hidden = YES;
            self.noVideoDataLabel.hidden = YES;
        }
    }
    else{
        self.dateView.hidden = NO;
        self.ruler.hidden = NO;
    }
}



- (void)navBack{
    NSLog(@"'返回’事件");
    [self stopReloadDataTimer];
    [self removGDPlayer];
    [self.videoDecoder ac_uninit];
    self.videoDecoder = nil;
    [self.captureDecoder ac_uninit];
    self.captureDecoder = nil;
    [self.previewDecoder ac_uninit];
    self.previewDecoder = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.navigationController popViewControllerAnimated:YES];
    [self removeCacheFile];
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

- (void)showNoDataLabel{
    self.noVideoDataLabel.hidden = NO;
    [self.view bringSubviewToFront:self.noVideoDataLabel];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hiddenNoDataLabel) object:nil];
    [self performSelector:@selector(hiddenNoDataLabel) withObject:nil afterDelay:3];
}

- (void)hiddenNoDataLabel{
    self.noVideoDataLabel.text = DPLocalizedString(@"PlayVideo_CS_NoVideoData");
    self.noVideoDataLabel.hidden = YES;
}

- (void)orderCloud{
    CSPackageTypeVC *orderVC = [[CSPackageTypeVC alloc] init];
//    CloudRecordingServiceInfoVC *orderVC = [[CloudRecordingServiceInfoVC alloc] init];
    orderVC.deviceModel                     = self.deviceModel;
    [self.navigationController pushViewController:orderVC animated:YES];
}

- (void)convertMP4WithStartValue:(NSInteger)startValue totalValue:(NSInteger)totalValue fileName:(NSString *)fileName{
    //开始转换mp4
    self.shortCutTotalTime = totalValue;
    self.shortCutFileName = [NSString stringWithFormat:@"%@.mp4",fileName];
    [self.shortCutArray removeAllObjects];

    //先获取开始的模型
    __block CloudPlayModel *playModel;
    [self.cloudPlayUrlArray enumerateObjectsUsingBlock:^(CloudPlayModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.accuracylastStamp >= startValue && obj.accuracyfirstStamp <= startValue) {
            playModel = obj;
            //seek时间点获取到
            self.shortCutStartTime = startValue - obj.accuracyfirstStamp;
            *stop = YES;
        }
    }];

    self.shortCutDownloadCount = totalValue / 6;
    if (totalValue + self.shortCutStartTime> self.shortCutDownloadCount * 6) {
        self.shortCutDownloadCount = self.shortCutDownloadCount + 1;
    }

    if (playModel) {
        //可以裁剪 --开始下载
        [self downloadConvertMp4FileWithModel:playModel];
    }
    else{
        //裁剪失败
        NSDictionary *notifyData = @{@"result":[NSNumber numberWithInt:0]
                                     };
        [[NSNotificationCenter defaultCenter] postNotificationName:ConvertMP4Notification object:nil userInfo:notifyData];
    }

}


- (void)downloadConvertMp4FileWithModel:(CloudPlayModel *)model{
    if ([self isFileExist:model.key]) {
        NSString *path = [self getPlayPathWithKey:model.key];
        [self.shortCutArray addObject:path];

        if (self.shortCutArray.count >= self.shortCutDownloadCount) {
            [self finallyConvertMp4];
        }
        else{
            CloudPlayModel *playModel = [self getNextModelWithPlayModel:model];
            if (playModel) {
                [self downloadConvertMp4FileWithModel:playModel];
            }
            else{
                [self finallyConvertMp4];
            }
        }
        return;
    }

    NSString * downloadUrl = [self getDownloadUrlWithBucketName:model.bucket ObjectKey:model.key];
    //创建传话管理者
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:downloadUrl]];
    //下载文件
    /*
     第一个参数:请求对象
     第二个参数:progress 进度回调
     第三个参数:destination 回调(目标位置)
     有返回值
     targetPath:临时文件路径
     response:响应头信息
     第四个参数:completionHandler 下载完成后的回调
     filePath:最终的文件路径
     */
    NSURLSessionDownloadTask *download = [manager downloadTaskWithRequest:request
                                                                 progress:^(NSProgress * _Nonnull downloadProgress) {
                                                                     //下载进度
                                                                     NSLog(@"%f",1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
                                                                 }
                                                              destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                                                  //保存的文件路径
                                                                  NSString *fullPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[model.key stringByReplacingOccurrencesOfString:@"/" withString:@"_"]];
                                                                  return [NSURL fileURLWithPath:fullPath];
                                                              }
                                                        completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {


                                                            if (error) {
                                                                //剪切失败
                                                                NSDictionary *notifyData = @{@"result":[NSNumber numberWithInt:0]
                                                                                             };
                                                                [[NSNotificationCenter defaultCenter] postNotificationName:ConvertMP4Notification object:nil userInfo:notifyData];
                                                                return;
                                                            }

                                                            //添加路径
                                                            [self.shortCutArray addObject:filePath.path];
                                                            //下载完成，不会去自动播放
                                                            if (self.shortCutArray.count >=self.shortCutDownloadCount) {
                                                                [self finallyConvertMp4];
                                                            }
                                                            else{
                                                                CloudPlayModel *nextModel = [self getNextModelWithPlayModel:model];
                                                                if (nextModel) {
                                                                    [self downloadConvertMp4FileWithModel:nextModel];
                                                                }
                                                                else{
                                                                    [self finallyConvertMp4];
                                                                }
                                                            }

                                                        }];

    //执行Task
    [download resume];

}

- (NSString *)getMP4DestinationFileNamePathWith:(NSString *)fileName{
    return [[MediaManager shareManager] mediaPathWithDevId:[self.deviceModel.DeviceId substringFromIndex:8] fileName:fileName mediaType:GosMediaShortCut deviceType:GosDeviceIPC position:PositionMain];
}


- (void)finallyConvertMp4{
    //先删除
    [self deleteFileWithPath:[self getConvertMP4Path]];

    //写文件
    NSMutableData *writer = [[NSMutableData alloc] init];

    for (NSString *pathStr in self.shortCutArray) {
        NSData *fileData = [NSData dataWithContentsOfFile:pathStr];
        [writer appendData:fileData];
    }
    [writer writeToFile:[self getConvertMP4Path] atomically:YES];
    [writer resetBytesInRange:NSMakeRange(0, writer.length)];
    [writer setLength:0];

    //开始裁剪
    [self.captureDecoder initVideoDecoderWithDataCallBack:^(PDecodedFrameParam frameParam) {

    }];
    [self.captureDecoder ac_captureMP4WithOrgFileName:[self getConvertMP4Path] destinaFileName:[self getMP4DestinationFileNamePathWith:self.shortCutFileName] startTime:self.shortCutStartTime totalTime:self.shortCutTotalTime];
}


- (void)playStatusChange:(NSNotification *)statusNotify{
    NSDictionary *statusDict = statusNotify.userInfo;

    //
    //    AVRecOpenSuccess        = 0,
    //    AVRecOpenErr,
    //    AVRecRetTime,
    //    AVRecTimeEnd,
    //    AVRetPlayRecTotalTime,
    //    AVRetPlayRecTime,
    //    AVRetPlayRecFinish,
    //    AVRetPlayRecSeekCapture,
    //    AVRetPlayRecRecordFinish,

    NSNumber * eventRec = (NSNumber *)statusDict[@"eventRec"];
    NSNumber * lData = (NSNumber *)statusDict[@"lData"];
    NSNumber * nPort = (NSNumber *)statusDict[@"nPort"];
    NSNumber * lUserParam = (NSNumber *)statusDict[@"lUserParam"];
    ACVideoDecoder *videoDecode = statusDict[@"Decode"];



    if (eventRec.intValue == 5 && videoDecode == self.videoDecoder) {
        if (self.isChangeDateManual) {
            return;
        }
        //更新进度
        int playValue = self.currentActurePlayModel.accuracyfirstStamp + lData.longValue;
        if (lData.intValue > 10) {
            return;
        }
        self.currentPlayTime = playValue;
        dispatch_async_on_main_queue(^{
            if (self.ruler.rulerScrollView.canScroll) {
                //隐藏预览图View
                self.previewView.hidden = YES;
            }
            [self.ruler.rulerScrollView playViewTimeIntervalDrawCurrentIndicatorWithValue:playValue withScroll:YES];
        });
        //播放时间
        NSLog(@"播放时间----%ld",lData.longValue);
    }
    if (eventRec.intValue == 6 && videoDecode == self.videoDecoder) {
        NSLog(@"ADTest-----播放结束了---------------");
        //播放结束
        //先干掉之前的额
        CloudPlayModel *nextPlayModel = [self getNextModelWithPlayModel:self.currentActurePlayModel];
        if (nextPlayModel) {
            [self playNextModel:nextPlayModel];
        }
        else{
            if (self.isChangeDateManual) {
                return;
            }
            [self handleNextPlay];
        }
    }

    if (eventRec.intValue == 4 && videoDecode == self.previewDecoder) {
        //可以seek了
        if (self.currentPreviewSeekTimeIndex != INT_MAX) {
            if (self.currentPreviewSeekTimeIndex >9) {
                self.currentPreviewSeekTimeIndex = 9;
            }
            //seek到指定位置
            //开始seek --先删除缓存图片
            NSLog(@"SeekABC 读取文件成功，时间为%d-----------------------------------------------",self.currentPreviewSeekTimeIndex);
            [self deleteFilePhotoPathWithPlayModel:self.currentSeekModel];
            [self.previewDecoder seekToTime:self.currentPreviewSeekTimeIndex photoPath:[self getPreViewPhotoPathWithPlayModel:self.currentSeekModel]];
            self.currentPreviewSeekTimeIndex = INT_MAX;
        }
    }


    if (eventRec.intValue == 7 && videoDecode == self.previewDecoder) {
        NSLog(@"SeekABC 成功-----------------------------------------------");
        dispatch_async_on_main_queue(^{
            //停止解码 --//获取预览图
            //停止这个端口的解码
            [self.previewDecoder ac_stopDecH264FileWithPort:nPort.intValue];
            UIImage *preViewImage = [UIImage imageWithContentsOfFile:[self getPreViewPhotoPathWithPlayModel:self.currentSeekModel]];
            if (preViewImage) {
                //存在预览图
                NSLog(@"预览图存在，并且成功获取了");
                [self.previewView setBackgroundImage:preViewImage forState:UIControlStateNormal];
                self.previewView.userInteractionEnabled = YES;
                self.previewView.hidden = NO;
                [self.view bringSubviewToFront:self.previewView];
                self.cloudLoadVideoActivity.hidden = YES;
                self.playButton.hidden = NO;
            }
        });
    }
}

- (void)handleNextPlay{
    dispatch_async_on_main_queue(^{
        if ([self isSameDay:self.currentSelectDate date2:self.currentTimeDate]) {
            //是当天播放完了，不操作
            self.noVideoDataLabel.text = MLocalizedString(Play_Tip_LastVideoPlayed);//
            self.noVideoDataLabel.numberOfLines = 2;
            self.noVideoDataLabel.adjustsFontSizeToFitWidth = YES;
            [self showNoDataLabel];
        }
        else{
            //跳转到下一天第一个视频播放
            NSUInteger index = [self.dateArray indexOfObject:self.currentSelectDate];
            if (index == NSNotFound) {
                return;
            }
            if (index <1) {
                return;
            }
            index = index -1;
            self.currentSelectDate = self.dateArray[index];
            //设置按钮
            [self.dateButton setTitle:[self getDateStringWithDate:self.currentSelectDate] forState:UIControlStateNormal];

            //停止播放
            //先停止解码 -播放
            [self.videoDecoder ac_stopDecode];
            //回到零的位置
            self.ruler.rulerScrollView.rulerValue = 0;
            //重新绘制
            [self.ruler.rulerScrollView drawRuler];
            //重新获取数据
            [self getTokenWithPlayFirstOne];
        }
    });
};

- (void)decodeAndPlayVideoWithSeekTime:(NSInteger)seekTime{
    //切换播放
    dispatch_async_on_main_queue(^{
        self.currentActurePlayModel = self.currentPlayModel;
        self.h264FilePath = [self getPlayPathWithKey:self.currentPlayModel.key];
        //先停止解码
        [self.videoDecoder ac_stopDecode];
        __weak typeof(self) weakSelf = self;
        //解码并且播放
        [self.videoDecoder initVideoDecoderWithDataCallBack:^(PDecodedFrameParam frameParam) {
            if ( frameParam->lpBuf == NULL)
            {
                return;
            }
            //如果不再播放云存储 直接return
            if (!weakSelf.isPlayCloudPlay) {
                return;
            }
            if ( frameParam->nDecType == 0 ) {//YUV
                if (weakSelf.currentPreviewCacheSeekTimeIndex != INT_MAX) {
                    if (weakSelf.currentPreviewCacheSeekTimeIndex >5) {
                        weakSelf.currentPreviewCacheSeekTimeIndex = 5;
                    }
                    //开始seek
                    weakSelf.currentPreviewCacheSeekTimeIndex = INT_MAX;
                }

                @autoreleasepool {
                    long imageSize = frameParam->lWidth * frameParam->lHeight;
                    //交给播放器播放
                    if (!weakSelf.yuvFrame) {
                        weakSelf.yuvFrame = [[KxVideoFrameYUV alloc]init];
                    }else{
                        weakSelf.yuvFrame.luma = weakSelf.yuvFrame.chromaB = weakSelf.yuvFrame.chromaR = nil;
                    }
                    weakSelf.yuvFrame.width  = frameParam->lWidth;
                    weakSelf.yuvFrame.height = frameParam->lHeight;
                    weakSelf.yuvFrame.luma = [NSData dataWithBytes:frameParam->lpBuf length: imageSize];
                    weakSelf.yuvFrame.chromaB = [NSData dataWithBytes:frameParam->lpBuf+(int)imageSize length:imageSize/4];
                    weakSelf.yuvFrame.chromaR = [NSData dataWithBytes:frameParam->lpBuf+(int)(imageSize*5/4) length:imageSize/4];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //去掉加载
                        weakSelf.loadVideoActivity.hidden = YES;
                        //渲染视频
                        [weakSelf.gdVideoPlayer render:weakSelf.yuvFrame];
                    });
                }
            }
            else if(frameParam ->nDecType == 4){
                //音频数据播放
                if (weakSelf.isAudioOn) {
                    if (weakSelf.gdVideoPlayer) {
                        [weakSelf.gdVideoPlayer openAudioWithBuffer:frameParam->lpBuf length:frameParam->lSize];
                    }
                    else{
                        dispatch_async_on_main_queue(^{
                            [weakSelf configGDPlayer];
                            [weakSelf.gdVideoPlayer openAudioWithBuffer:frameParam->lpBuf length:frameParam->lSize];
                        });
                    }
                }
            }
        }];
        //开始解码h264文件
        [self.videoDecoder ac_startDecH264FileWithPort:0 filePath:_h264FilePath];
    });
    //    }
    //再缓存下载下一个
    CloudPlayModel *nextPlayModel = [self getNextModelWithPlayModel:self.currentPlayModel];
    if (nextPlayModel) {
        [self downloadH264FileWithModel:nextPlayModel];
    }
}

- (void)initBottomView{

    [self.view addSubview:self.cloudBottomView];
    [self.view insertSubview:self.cloudBottomView atIndex:0];
    [self.cloudBottomView addSubview:self.cloudSoundBtn];
    [self.cloudBottomView addSubview:self.cloudShortCutBtn];
    [self.cloudBottomView addSubview:self.cloudSnapshotBtn];

    [self.cloudBottomView addSubview:self.cloudSoundLabel];
    [self.cloudBottomView addSubview:self.cloudShortCutLabel];
    [self.cloudBottomView addSubview:self.cloudSnapshotLabel];

    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    //真实屏幕宽度
    CGFloat playHeight = trueSreenWidth *playViewRatio;
    CGFloat bottomHeight = (MAX(screenWidth, screenHeight) - HeightForStatusBarAndNaviBar - playHeight - 200);
    [self.cloudBottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view);
        //这里添加40
        make.height.mas_equalTo(bottomHeight + 40);
        make.left.right.equalTo(self.view);
    }];

    //计算按钮大小 默认剪切按钮是两倍声音按钮大
    CGFloat bottomBtnWH;
    bottomBtnWH = (trueSreenWidth - 32 - HeightForStatusBarAndNaviBar)/4.0f;
    [self.cloudSoundBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.cloudBottomView.mas_centerY);
        make.left.equalTo(self.cloudBottomView).offset(16);
        make.height.width.mas_equalTo(bottomBtnWH);
    }];

    [self.cloudShortCutBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.cloudBottomView.mas_centerY);
        make.left.equalTo(self.cloudSoundBtn.mas_right).offset(32);
        make.height.width.mas_equalTo(2 * bottomBtnWH);
    }];

    [self.cloudSnapshotBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.cloudBottomView.mas_centerY);
        make.left.equalTo(self.cloudShortCutBtn.mas_right).offset(32);
        make.height.width.mas_equalTo(bottomBtnWH);
    }];

    [self.cloudSoundLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.cloudSoundBtn);
        make.height.equalTo(@20);
        make.width.equalTo(@100);
        make.top.equalTo(self.cloudSoundBtn.mas_bottom).offset(5);
    }];

    [self.cloudShortCutLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.cloudShortCutBtn);
        make.height.equalTo(@20);
        make.width.equalTo(@100);
        make.top.equalTo(self.cloudShortCutBtn.mas_bottom).offset(-5);
    }];

    [self.cloudSnapshotLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.cloudSnapshotBtn);
        make.height.equalTo(@20);
        make.width.equalTo(@100);
        make.top.equalTo(self.cloudSnapshotBtn.mas_bottom).offset(5);
    }];

}


#pragma mark - ahRuler Delegate

- (void)ahRuler:(AHRulerScrollView *)rulerScrollView {
    //如果不是在拖动的话 不进行计算
    if (!self.ruler.rulerScrollView.isDragging) {
        return;
    }
    NSUInteger selectValue = rulerScrollView.rulerValue;
    //遍历寻找播放模型
    __block CloudPlayModel *playModel;
    [self.cloudPlayUrlArray enumerateObjectsUsingBlock:^(CloudPlayModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.accuracylastStamp >= selectValue && obj.accuracyfirstStamp <= selectValue) {
            playModel = obj;
            *stop = YES;
        }
    }];
    if (playModel) {
        //存在录制视频
        self.noVideoDataLabel.hidden = YES;
    }
    else{
        //不存在录制视频
        [self showNoDataLabel];
    }
}

// 判断是否是同一天
- (BOOL)isSameDay:(NSDate *)date1 date2:(NSDate *)date2
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    unsigned unitFlag = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSDateComponents *comp1 = [calendar components:unitFlag fromDate:date1];
    NSDateComponents *comp2 = [calendar components:unitFlag fromDate:date2];
    return (([comp1 day] == [comp2 day]) && ([comp1 month] == [comp2 month]) && ([comp1 year] == [comp2 year]));
}


- (void)ahRulerEndDrag:(AHRulerScrollView *)rulerScrollView{
    //停止拖动，去获取预览图
    [self getPlayPreviewWithValue:rulerScrollView.rulerValue];
//    if ([self isSameDay:self.currentSelectDate date2:self.currentTimeDate]) {
//        //如果是同一天就要判断是不是时间秒数大于当前秒数
//        long long nowValue =[self.currentTimeDate timeIntervalSince1970] - [self.currentSelectDate timeIntervalSince1970];
//        if (nowValue <= rulerScrollView.rulerValue + 5) {
//            //说明滑动超过了当前时间 要弹回来
//            //开始操作
//            NSLog(@"test123456--------------nowValue-%lld-rulerValue%f",nowValue,rulerScrollView.rulerValue);
//        }
//    }
}

#pragma mark - 工具方法
- (void)getPlayPreviewWithValue:(NSInteger)selectValue{
    self.cloudLoadVideoActivity.hidden = NO;
    self.playButton.hidden = YES;
    //遍历寻找播放模型
    __block CloudPlayModel *playModel;
    __weak typeof(self) weakSelf = self;
    [self.cloudPlayUrlArray enumerateObjectsUsingBlock:^(CloudPlayModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.accuracylastStamp >= selectValue && obj.accuracyfirstStamp <= selectValue) {
            weakSelf.currentSeekModel = obj;
            playModel = obj;
            //seek时间点获取到
            weakSelf.currentPreviewSeekTimeIndex = selectValue - obj.accuracyfirstStamp;
            weakSelf.currentPreviewCacheSeekTimeIndex = selectValue - obj.accuracyfirstStamp;
            *stop = YES;
        }
    }];

    if (playModel) {
        //存在录制视频
        weakSelf.previewView.hidden = NO;
        [weakSelf.previewView setBackgroundImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
        weakSelf.previewTimeLabel.text = [self getNOSpaceTimeTextWithValue:selectValue];
        weakSelf.currentSeekModel = playModel;
        //seek到这个位置并且缓存一个
        [weakSelf seekToTime:weakSelf.currentPreviewSeekTimeIndex playModel:playModel];
    }
    else{
        //不存在录制视频
        weakSelf.previewView.hidden = YES;
    }
}

- (void)playAlarmTimeVideoWithValue:(NSInteger)selectValue{
    //遍历寻找播放模型
    __block CloudPlayModel *playModel;
    __weak typeof(self) weakSelf = self;
    [self.cloudPlayUrlArray enumerateObjectsUsingBlock:^(CloudPlayModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ((obj.accuracylastStamp >= selectValue && obj.accuracyfirstStamp <= selectValue) || (obj.accuracyfirstStamp > selectValue)) {
            weakSelf.currentSeekModel = obj;
            playModel = obj;
            //seek时间点获取到
            weakSelf.currentPreviewSeekTimeIndex = selectValue - obj.accuracyfirstStamp;
            weakSelf.currentPreviewCacheSeekTimeIndex = selectValue - obj.accuracyfirstStamp;
            *stop = YES;
        }
    }];
    
    if (playModel) {
        //完成跳转
        dispatch_async_on_main_queue(^{
            _alarmMsgTime = 0;
            self.currentSeekModel = playModel;
            self.isChangeDateManual = NO;
            [self openCloudPlay];
            self.currentPlayModel = self.currentSeekModel;
            //放到最大
            [self.ruler.rulerScrollView zoomToMAX];
            //滑动一下
            int playValue = playModel.accuracyfirstStamp;
            [self.ruler.rulerScrollView playViewTimeIntervalDrawCurrentIndicatorWithValue:playValue withScroll:YES];
            //下载播放
            [self downloadH264FileWithModelAndPlay:playModel];
        });
    }
    else{
        //没查到对应数据
        dispatch_sync_on_main_queue(^{
            self.loadVideoActivity.hidden = YES;
        });
        _alarmMsgTime = 0;
    }
    
}

- (void)delayHiddenPreView{
    [self performSelector:@selector(hiddenPreViewBtn) withObject:nil afterDelay:5];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hiddenPreViewBtn) object:nil];
}


- (void)hiddenPreViewBtn{
    self.previewView.hidden = YES;
    self.previewView.userInteractionEnabled = NO;
}


- (void)seekToTime:(NSInteger)seekTime playModel:(CloudPlayModel *)playModel{
    //下载视频 并且seek到指定时间点 设置预览图
    if ([self isFileExist:playModel.key]) {
        //如果存在直接开始播放
        //渲染预览图
        [self seekFileAndGetPreviewWithModel:playModel seekTime:seekTime];
    }
    else{
        //下载播放
        NSString * downloadUrl = [self getDownloadUrlWithBucketName:playModel.bucket ObjectKey:playModel.key];
        //创建传话管理者
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:downloadUrl]];
        //下载文件
        /*
         第一个参数:请求对象
         第二个参数:progress 进度回调
         第三个参数:destination 回调(目标位置)
         有返回值
         targetPath:临时文件路径
         response:响应头信息
         第四个参数:completionHandler 下载完成后的回调
         filePath:最终的文件路径
         */
        NSURLSessionDownloadTask *download = [manager downloadTaskWithRequest:request
                                                                     progress:^(NSProgress * _Nonnull downloadProgress) {
                                                                         //下载进度
                                                                         NSLog(@"%f",1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
                                                                     }
                                                                  destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                                                      //保存的文件路径
                                                                      NSString *fullPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[playModel.key stringByReplacingOccurrencesOfString:@"/" withString:@"_"]];
                                                                      return [NSURL fileURLWithPath:fullPath];
                                                                  }
                                                            completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                                                //下载完成，去seek播放
                                                                //                                                                self.h264FilePath = filePath.path;
                                                                //判断一下是否当时还是选中的这个，如果是的，渲染一下预览图
                                                                if (self.currentSeekModel == playModel) {
                                                                    [self seekFileAndGetPreviewWithModel:playModel seekTime:seekTime];
                                                                }
                                                            }];

        //执行Task
        [download resume];
    }
}


- (void)playNextModel:(CloudPlayModel *)playModel{

    //设置当前播放模型
    self.currentPlayModel = playModel;

    NSLog(@"nextModel--------------------------------%@",playModel.key);

    //自动播放下一个视频
    if ([self isFileExist:playModel.key]) {
        //停止转圈
        dispatch_async_on_main_queue(^{
            self.loadVideoActivity.hidden = YES;
        });
        //如果存在直接开始播放
        [self decodeAndPlayVideoWithSeekTime:0];
    }
    else{
        //转圈
        dispatch_async_on_main_queue(^{
            self.loadVideoActivity.hidden = NO;
            [self.loadVideoActivity startAnimating];
        });
        //下载播放
        NSString * downloadUrl = [self getDownloadUrlWithBucketName:playModel.bucket ObjectKey:playModel.key];
        //创建传话管理者
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:downloadUrl]];
        //下载文件
        /*
         第一个参数:请求对象
         第二个参数:progress 进度回调
         第三个参数:destination 回调(目标位置)
         有返回值
         targetPath:临时文件路径
         response:响应头信息
         第四个参数:completionHandler 下载完成后的回调
         filePath:最终的文件路径
         */
        NSURLSessionDownloadTask *download = [manager downloadTaskWithRequest:request
                                                                     progress:^(NSProgress * _Nonnull downloadProgress) {
                                                                         //下载进度
                                                                         NSLog(@"%f",1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
                                                                     }
                                                                  destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                                                      //保存的文件路径
                                                                      NSString *fullPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[playModel.key stringByReplacingOccurrencesOfString:@"/" withString:@"_"]];
                                                                      return [NSURL fileURLWithPath:fullPath];
                                                                  }
                                                            completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                                                //下载完成，去自动播放 如果还是播放这一个的话
                                                                if (self.currentPlayModel == playModel) {
                                                                    //去掉转圈
                                                                    dispatch_async_on_main_queue(^{
                                                                        self.loadVideoActivity.hidden = YES;
                                                                    });
                                                                    [self decodeAndPlayVideoWithSeekTime:0];
                                                                }
                                                            }];

        //执行Task
        [download resume];
    }

}


- (void)seekFileAndGetPreviewWithModel:(CloudPlayModel *)playModel seekTime:(NSInteger)seekTime{
    //停止上一个解码
    [self.previewDecoder ac_stopDecode];
    NSLog(@"SeekABC 开始-----------------------------------------------");
    //初始化
    [self.previewDecoder initVideoDecoderWithDataCallBack:^(PDecodedFrameParam frameParam) {
    }];
    [self.previewDecoder ac_startDecH264FileWithPort:0 filePath:[self getPlayPathWithKey:playModel.key]];
}


- (void)deleteFilePhotoPathWithPlayModel:(CloudPlayModel *)playModel{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *fileFullPath = [self getPreViewPhotoPathWithPlayModel:playModel];
    BOOL bRet = [fileMgr fileExistsAtPath:fileFullPath];
    if (bRet) {
        //删除
        [fileMgr removeItemAtPath:fileFullPath error:nil];
    }
}


- (void)deleteFileWithPath:(NSString *)path{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    BOOL bRet = [fileMgr fileExistsAtPath:path];
    if (bRet) {
        //删除
        [fileMgr removeItemAtPath:path error:nil];
    }
}


- (NSString *)getConvertMP4Path{
    return [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"ACEDONG_0806.H264"];
}

- (NSString *)getPreViewPhotoPathWithPlayModel:(CloudPlayModel *)playModel{
    return [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[[playModel.key stringByReplacingOccurrencesOfString:@"/" withString:@"_"] stringByReplacingOccurrencesOfString:@".H264" withString:@".jpg"]];
}

- (NSString *)getSDPreViewPhotoPathWithPlayModel:(SDCloudVideoModel *)playModel{

    NSString *startStr = @"";
    if ([playModel respondsToSelector:@selector(S)]) {
        startStr = [NSString stringWithFormat:@"%lld",playModel.S];
    }
    return [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[startStr stringByAppendingString:@".jpg"]];
}


- (CloudPlayModel *)getNextModelWithPlayModel:(CloudPlayModel *)playModel{

    __block NSUInteger index;
    __block CloudPlayModel *exsitModel;

    if (self.isChangeDateManual) {
        //调用缓存的
        [self.cacheCloudPlayUrlArray enumerateObjectsUsingBlock:^(CloudPlayModel  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.startTime == playModel.startTime) {
                exsitModel = obj;
                index = idx;
                *stop = YES;
            }
        }];
    }
    else{
        [self.cloudPlayUrlArray enumerateObjectsUsingBlock:^(CloudPlayModel  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.startTime == playModel.startTime) {
                exsitModel = obj;
                index = idx;
                *stop = YES;
            }
        }];
    }

    if (exsitModel) {
        if (self.isChangeDateManual) {
            if (index + 1 < self.cacheCloudPlayUrlArray.count) {
                CloudPlayModel *returnPlayModel = self.cacheCloudPlayUrlArray[index +1];
                if (returnPlayModel.startTime == playModel.startTime) {
                    //数据重复
                    if (index + 2 < self.cacheCloudPlayUrlArray.count) {
                        return self.cacheCloudPlayUrlArray[index +2];
                    }
                }
                else{
                    return self.cacheCloudPlayUrlArray[index +1];
                }

            }
        }
        else{
            if (index + 1 < self.cloudPlayUrlArray.count) {
                CloudPlayModel *returnPlayModel = self.cloudPlayUrlArray[index +1];
                if (returnPlayModel.startTime == playModel.startTime) {
                    //数据重复
                    if (index + 2 < self.cloudPlayUrlArray.count) {
                        return self.cloudPlayUrlArray[index +2];
                    }
                }
                else{
                    return self.cloudPlayUrlArray[index +1];
                }
            }
        }
    }
    return nil;
}


- (void)loadDateDataWithDays:(int)days{
    self.dateArray = [NSMutableArray array];
    NSDate* currentDate = [NSDate dateWithTimeIntervalSinceNow:0];
    //转换为当天零点date
    currentDate = [self getZeroDateWithCurrentDate:currentDate];
    self.currentSelectDate = currentDate;
    self.ruler.rulerScrollView.selectDate = self.currentSelectDate;
    [self.dateButton setTitle:[self getDateStringWithDate:currentDate] forState:UIControlStateNormal];
    [self.dateArray addObject:currentDate];
    for (int i = 0;i < days;i++) {
        NSDate *lastDate = [NSDate dateWithTimeInterval:-24*60*60*(i+1) sinceDate:currentDate];//前一天
        [self.dateArray addObject:lastDate];
    }
}

//获取云存储套餐时长
- (void)getCloudVideoTime{
    [SVProgressHUD showWithStatus:DPLocalizedString(@"loading")];
    
    NSString *getUrl = [NSString stringWithFormat:@"http://%@/api/cloudstore/cloudstore-service/service/data-valid",kCloud_IP];
    [[AFHTTPSessionManager manager] GET:getUrl parameters:@{@"token" : [mUserDefaults objectForKey:USER_TOKEN],@"device_id" : self.deviceModel.DeviceId,@"username":[SaveDataModel getUserName],@"version":@"1.0" } progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //获取套餐时长数据
        NSArray *dataArray = responseObject[@"data"];
        if ([dataArray isKindOfClass:[NSArray class]]) {
            if (dataArray.count >0) {
                NSDictionary *dataDict = dataArray[0];
                NSNumber *dataLifeNumber = dataDict[@"dateLife"];
                NSNumber *startTime = dataDict[@"startTime"];
                //获取当天0点的date
                NSDate *currentDate = [self getZeroDateWithCurrentDate:[NSDate date]];
                NSTimeInterval currentInterval = [currentDate timeIntervalSince1970];
                int distanceTime = currentInterval - startTime.intValue;
                int totalDays = dataLifeNumber.intValue;
                if (distanceTime >0) {
                    int days = distanceTime/(24 * 3600) + 1;
                    if (days < totalDays) {
                        //如果开通时间数据不够
                        totalDays = days;
                    }
                }
                else{
                    //就是今天
                    totalDays = 0;
                }

                [self loadDateDataWithDays:totalDays];
                //刷新数据
                [self.pickView reloadAllComponents];
                [self getTokenWithLoading:YES];
                _isOrderCloudPlay = YES;
                self.netErrorButton.hidden = YES;
                [self configCloudPlayViewWithIsOrdered:YES];
            }
            else{
                [SVProgressHUD dismiss];
                self.netErrorButton.hidden = YES;
                [self configCloudPlayViewWithIsOrdered:NO];
                _isOrderCloudPlay = NO;
            }
        }
        else{
            [SVProgressHUD dismiss];
            self.netErrorButton.hidden = YES;
            [self configCloudPlayViewWithIsOrdered:NO];
            _isOrderCloudPlay = NO;
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        //显示网络异常
        self.netErrorButton.hidden = NO;
        //数据加载失败
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"GetDataFailed_Retry")];
    }];
}



//获取云存储token
- (void)getTokenWithLoading:(BOOL)isLoading{
    if (isLoading) {
        [SVProgressHUD showWithStatus:DPLocalizedString(@"loading")];
    }
    NSString *tokenUrl = [NSString stringWithFormat:@"http://%@/api/cloudstore/cloudstore-service/sts/check-token",kCloud_IP];
    [[AFHTTPSessionManager manager] POST:tokenUrl parameters:@{@"token" : [mUserDefaults objectForKey:USER_TOKEN],@"device_id" : self.deviceModel.DeviceId,@"username":[SaveDataModel getUserName]} progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        self.tokenDict = responseObject[@"data"];
        //请求一次当前数据
        [self getcurrentVideoData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [SVProgressHUD dismiss];
    }];
}


//获取云存储token
- (void)getTokenWithPlayFirstOne{
    [SVProgressHUD showWithStatus:DPLocalizedString(@"loading")];
    NSString *tokenUrl = [NSString stringWithFormat:@"http://%@/api/cloudstore/cloudstore-service/sts/check-token",kCloud_IP];
    [[AFHTTPSessionManager manager] POST:tokenUrl parameters:@{@"token" : [mUserDefaults objectForKey:USER_TOKEN],@"device_id" : self.deviceModel.DeviceId,@"username":[SaveDataModel getUserName]} progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        self.tokenDict = responseObject[@"data"];
        //请求一次当前数据
        [self getcurrentVideoDataWithPlayFirstOne];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [SVProgressHUD dismiss];
    }];
}

- (void)getcurrentVideoData{
    __weak typeof(self) weakSelf = self;
    //开启云存储定时器
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //30s后添加定时器
        [weakSelf startReloadDataTimer];
    });
    
    if (_alarmMsgTime >0) {
        //开始处理跳转逻辑
        int distanceTime = [self.currentSelectDate timeIntervalSince1970] - _alarmMsgTime;
        if (distanceTime >0) {
            //需要跳转天数
            int daysIndex = distanceTime/(24 *3600) +1;
            if (self.dateArray.count >daysIndex) {
                //说明在数据内 切换到对应时期
                self.currentSelectDate = self.dateArray[daysIndex];
                [self.dateButton setTitle:[self getDateStringWithDate:self.currentSelectDate] forState:UIControlStateNormal];
                [self.pickView selectRow:daysIndex inComponent:0 animated:NO];
                self.currentDayIndex = _alarmMsgTime-[self.currentSelectDate timeIntervalSince1970];
            }
            else{
                //清空,没查到数据，数据过期
                _alarmMsgTime = 0;
            }
        }
        else{
            //就是今天 不操作
            self.currentDayIndex = _alarmMsgTime-[self.currentSelectDate timeIntervalSince1970];
        }
    }

    __block NSDate *nowDate = [self.currentSelectDate copy];
    //获取视频录制记录
    [[AFHTTPSessionManager manager] GET:[self getAlarmUrlByStartTime:self.currentSelectDate endTime:[self getNextDayWithDate:self.currentSelectDate]] parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //不是同一天，return
        if (![self isSameDay:nowDate date2:self.currentSelectDate]) {
            return;
        }

        NSLog(@"视频录制记录%@",responseObject);
        NSArray *dataArray = responseObject[@"data"];
        if ([responseObject[@"data"] isKindOfClass:[NSArray class]]) {
            //获取视频切片数据
            [self handleVideoArrayData:dataArray];
        }

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"获取视频录制记录失败");
    }];

    //获取播放ts片段url数据
    [[AFHTTPSessionManager manager] GET:[self getPlayListUrlWithStartByStartTime:self.currentSelectDate endTime:[self getNextDayWithDate:self.currentSelectDate]] parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {

    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //不是同一天，return
        if (![self isSameDay:nowDate date2:self.currentSelectDate]) {
            return;
        }
        NSArray *dataArray = responseObject[@"data"];
        //解析出url数组
        NSLog(@"视频ts数据%@",responseObject);
        [self handleVideoUrlArrayData:dataArray];
        [SVProgressHUD dismiss];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"获取ts数据记录失败");
        [SVProgressHUD dismiss];
    }];
}

- (void)getcurrentVideoDataWithPlayFirstOne{
     __weak typeof(self) weakSelf = self;
    //开启云存储定时刷新最新数据
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //30s后添加定时器
        [weakSelf startReloadDataTimer];
    });
    __block NSDate *nowDate = [self.currentSelectDate copy];
    //获取视频录制记录
    [[AFHTTPSessionManager manager] GET:[self getAlarmUrlByStartTime:self.currentSelectDate endTime:[self getNextDayWithDate:self.currentSelectDate]] parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //不是同一天，return
        if (![self isSameDay:nowDate date2:self.currentSelectDate]) {
            return;
        }

        NSLog(@"视频录制记录%@",responseObject);
        NSArray *dataArray = responseObject[@"data"];
        if ([responseObject[@"data"] isKindOfClass:[NSArray class]]) {
            //获取视频切片数据
            [self handleVideoArrayData:dataArray];
        }

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"获取视频录制记录失败");
    }];

    //获取播放ts片段url数据
    [[AFHTTPSessionManager manager] GET:[self getPlayListUrlWithStartByStartTime:self.currentSelectDate endTime:[self getNextDayWithDate:self.currentSelectDate]] parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {

    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //不是同一天，return
        if (![self isSameDay:nowDate date2:self.currentSelectDate]) {
            return;
        }
        NSArray *dataArray = responseObject[@"data"];
        //解析出url数组
        NSLog(@"视频ts数据%@",responseObject);
        [self handleVideoUrlArrayDataAndPlayFirstOne:dataArray];
        [SVProgressHUD dismiss];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"获取ts数据记录失败");
        [SVProgressHUD dismiss];
    }];
}



-(void)startReloadDataTimer
{
    if ( _reloadDataTimer ==nil)
    {
        __weak typeof(self) weakSelf = self;
        self.reloadDataTimer =  [NSTimer yyscheduledTimerWithTimeInterval:60 block:^(NSTimer * _Nonnull timer) {
            if (!weakSelf.isOrderCloudPlay) {
                return;
            }
            if ([weakSelf isSameDay:weakSelf.currentSelectDate date2:weakSelf.currentTimeDate]) {
                //是当天才开始请求
                [weakSelf getTokenWithLoading:NO];
                
            }
        } repeats:YES];
        [self.reloadDataTimer setFireDate:[NSDate distantPast]];
        [[NSRunLoop mainRunLoop] addTimer:self.reloadDataTimer forMode:NSDefaultRunLoopMode];
    }
}

- (void)stopReloadDataTimer
{
    if (_reloadDataTimer) {
        [_reloadDataTimer invalidate];
        _reloadDataTimer = nil;
    }
}


- (void)handleVideoUrlArrayDataAndPlayFirstOne:(NSArray *)dataArray{
    if (dataArray.count > 0) {
        [self.cloudPlayUrlArray removeAllObjects];
        for (NSDictionary *dict in dataArray) {
            //转换模型数组
            CloudPlayModel *videoModel = [CloudPlayModel yy_modelWithDictionary:dict];
            [self.cloudPlayUrlArray addObject:videoModel];
        }
    }

    //进行疯狂计算--转换为今天的秒数
    for (CloudPlayModel *playModel in self.cloudPlayUrlArray) {
        long long accuracyfirstStamp = playModel.startTime - [self.currentSelectDate timeIntervalSince1970];
        long long accuracylastStamp = playModel.endTime - [self.currentSelectDate timeIntervalSince1970];
        playModel.accuracyfirstStamp = accuracyfirstStamp;
        playModel.accuracylastStamp = accuracylastStamp;
    }

    if (self.cloudPlayUrlArray.count >0) {
        CloudPlayModel *playModel = self.cloudPlayUrlArray[0];
        self.currentSeekModel = self.currentPlayModel = self.cloudPlayUrlArray[0];
        [self downloadH264FileWithModelAndPlay:playModel];
    }
}


- (void)handleVideoUrlArrayData:(NSArray *)dataArray{
    if (dataArray.count > 0) {
        [self.cloudPlayUrlArray removeAllObjects];
        for (NSDictionary *dict in dataArray) {
            //转换模型数组
            CloudPlayModel *videoModel = [CloudPlayModel yy_modelWithDictionary:dict];
            [self.cloudPlayUrlArray addObject:videoModel];
        }
    }

    //进行疯狂计算--转换为今天的秒数
    for (CloudPlayModel *playModel in self.cloudPlayUrlArray) {
        long long accuracyfirstStamp = playModel.startTime - [self.currentSelectDate timeIntervalSince1970];
        long long accuracylastStamp = playModel.endTime - [self.currentSelectDate timeIntervalSince1970];
        playModel.accuracyfirstStamp = accuracyfirstStamp;
        playModel.accuracylastStamp = accuracylastStamp;
//        NSLog(@"daniel: urlArray %d: first:%lld---end%lld",i, accuracyfirstStamp,accuracylastStamp);
    }
    
    //请求完成了
    if (_alarmMsgTime >0) {
        dispatch_async_on_main_queue(^{
            self.loadVideoActivity.hidden = NO;
        });
        //查找模型
        [self playAlarmTimeVideoWithValue:self.currentDayIndex];
    }
}


- (void)downloadH264FileWithModel:(CloudPlayModel *)playModel{
    if ([self isFileExist:playModel.key]) {
        return;
    }
    NSString * downloadUrl = [self getDownloadUrlWithBucketName:playModel.bucket ObjectKey:playModel.key];
    //创建传话管理者
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:downloadUrl]];
    NSURLSessionDownloadTask *download = [manager downloadTaskWithRequest:request
                                                                 progress:^(NSProgress * _Nonnull downloadProgress) {
                                                                 }
                                                              destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                                                  //保存的文件路径
                                                                  NSString *fullPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[playModel.key stringByReplacingOccurrencesOfString:@"/" withString:@"_"]];
                                                                  return [NSURL fileURLWithPath:fullPath];
                                                              }
                                                        completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                                            //下载完成，不会去自动播放
                                                        }];

    //执行Task
    [download resume];
}


- (void)downloadH264FileWithModelAndPlay:(CloudPlayModel *)playModel{
//    if ([self isFileExist:playModel.key]) {
//        return;
//    }
    NSString * downloadUrl = [self getDownloadUrlWithBucketName:playModel.bucket ObjectKey:playModel.key];
    //创建传话管理者
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:downloadUrl]];
    NSURLSessionDownloadTask *download = [manager downloadTaskWithRequest:request
                                                                 progress:^(NSProgress * _Nonnull downloadProgress) {
                                                                 }
                                                              destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                                                  //保存的文件路径
                                                                  NSString *fullPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[playModel.key stringByReplacingOccurrencesOfString:@"/" withString:@"_"]];
                                                                  return [NSURL fileURLWithPath:fullPath];
                                                              }
                                                        completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                                            self.loadVideoActivity.hidden = YES;
                                                            //下载完成，自动播放
                                                            [self decodeAndPlayVideoWithSeekTime:0];
                                                        }];

    //执行Task
    [download resume];
}

//判断H264文件是否已经存在
-(BOOL)isFileExist:(NSString *)fileName
{
    fileName = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *filePath = [path stringByAppendingPathComponent:fileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL result = [fileManager fileExistsAtPath:filePath];
    return result;
}


//获取H264文件路径
- (NSString *)getPlayPathWithKey:(NSString *)fileName{
    fileName = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    NSString *fullPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileName];
    return fullPath;
}

//处理视频返回数据
- (void)handleVideoArrayData:(NSArray *)dataArray{
    [self.cloudVideoArray removeAllObjects];
    if (dataArray.count > 0) {
        for (NSDictionary *dict in dataArray) {
            //转换模型数组
            CloudVideoModel *videoModel = [CloudVideoModel yy_modelWithDictionary:dict];
            [self.cloudVideoArray addObject:videoModel];
        }
    }
    if (self.cloudVideoArray.count > 0) {
    }
    //进行疯狂计算--转换为今天的秒数
    for (CloudVideoModel *videoModel in self.cloudVideoArray) {
        long long accuracyfirstStamp = videoModel.startTime - [self.currentSelectDate timeIntervalSince1970];
        long long accuracylastStamp = videoModel.endTime - [self.currentSelectDate timeIntervalSince1970];
        videoModel.accuracyfirstStamp = accuracyfirstStamp;
        videoModel.accuracylastStamp = accuracylastStamp;
    }
    //时间赶，先这样写吧 --赋值数组
    self.ruler.rulerScrollView.selectDate = self.currentSelectDate;
    self.ruler.rulerScrollView.videoArray = self.cloudVideoArray;
}


//处理报警数据数组
- (void)handleAlarmArrayData:(NSArray *)dataArray{
    [self.cloudAlarmArray removeAllObjects];
    if (dataArray.count > 0) {
        for (NSDictionary *dict in dataArray) {
            //转换模型数组
            CloudAlarmModel *alarmModel = [CloudAlarmModel yy_modelWithDictionary:dict];
            [self.cloudAlarmArray addObject:alarmModel];
        }
    }
    //进行疯狂计算--转换为今天的秒数
    for (CloudAlarmModel *alarmModel in self.cloudAlarmArray) {
        long long timeStamp = alarmModel.timeStamp - [self.currentSelectDate timeIntervalSince1970];
        alarmModel.accuracyTimeStamp = timeStamp;
    }
    //赋值数组
    self.ruler.rulerScrollView.selectDate = self.currentSelectDate;
    self.ruler.rulerScrollView.moveDetectArray = self.cloudAlarmArray;
}


//获取时间字符串
- (NSString *)getTimeTextWithValue:(NSUInteger)TimeValue{
    NSString *timeText;
    int hrs = (int)TimeValue / 3600;
    int totolSecond = (int)TimeValue % 3600;
    int min = (int)totolSecond / 60;
    int second = (int)totolSecond % 60;
    timeText = [NSString stringWithFormat:@"%02d : %02d : %02d",hrs,min,second];
    return timeText;
}

//获取时间字符串-没空格
- (NSString *)getNOSpaceTimeTextWithValue:(NSUInteger)TimeValue{
    NSString *timeText;
    int hrs = (int)TimeValue / 3600;
    int totolSecond = (int)TimeValue % 3600;
    int min = (int)totolSecond / 60;
    int second = (int)totolSecond % 60;
    timeText = [NSString stringWithFormat:@"%02d:%02d:%02d",hrs,min,second];
    return timeText;
}

//一拖四云存储设备ID：主设备ID/子设备ID

- (NSString*)csDeviceID{
    if(!_csDeviceID){
        NSString *subId = self.deviceModel.selectedSubDevInfo.SubId ?:@"";
        subId = [@"/" stringByAppendingString:subId];
        _csDeviceID = [self.deviceModel.DeviceId stringByAppendingString:self.deviceModel.devCapModel.four_channel_flag==1?subId:@""];
    }
    return _csDeviceID;
}

//获取裸流切片url
- (NSString *)getPlayListUrlWithStartByStartTime:(NSDate *)startDate endTime:(NSDate *)endDate{
    long long startTime=(long long)[startDate timeIntervalSince1970];
    long long endTime=(long long)[endDate timeIntervalSince1970];
    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api/cloudstore/cloudstore-service/move-video/time-line/details?device_id=%@&start_time=%lld&end_time=%lld&token=%@&username=%@",kCloud_IP,self.csDeviceID,startTime,endTime,[mUserDefaults objectForKey:USER_TOKEN],[SaveDataModel getUserName]];
    return urlStr;
}

//获取报警查询时间url
- (NSString *)getAlarmUrlByStartTime:(NSDate *)startDate endTime:(NSDate *)endDate{
    long long startTime=(long long)[startDate timeIntervalSince1970];
    long long endTime=(long long)[endDate timeIntervalSince1970];
    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api/cloudstore/cloudstore-service/move-video/time-line?device_id=%@&start_time=%lld&end_time=%lld&token=%@&username=%@",kCloud_IP,self.csDeviceID,startTime,endTime,[mUserDefaults objectForKey:USER_TOKEN],[SaveDataModel getUserName]];
    return urlStr;
}


//获取视频录制时间url
- (NSString *)getVideoUrlByStartTime:(NSDate *)startDate endTime:(NSDate *)endDate{
    long long startTime=(long long)[startDate timeIntervalSince1970];
    long long endTime=(long long)[endDate timeIntervalSince1970];
    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api/cloudstore/cloudstore-service/move-video/time-line?device_id=%@&start_time=%lld&end_time=%lld&token=%@&username=%@",kCloud_IP,self.csDeviceID,startTime,endTime,[mUserDefaults objectForKey:USER_TOKEN],[SaveDataModel getUserName]];
    return urlStr;
}


//获取前一天的date
- (NSDate *)getLastDayWithDate:(NSDate *)date{
    return [NSDate dateWithTimeInterval:-24*60*60 sinceDate:date];//前一天
}

//获取后一天的date
- (NSDate *)getNextDayWithDate:(NSDate *)date{
    return [NSDate dateWithTimeInterval:+24*60*60 sinceDate:date];//前一天
}

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


//获取当天零点nsdate
- (NSDate *)getZeroDateWithCurrentDate:(NSDate *)currentDate{
    NSString *dateString = [self getDateStringWithDate:currentDate];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"yyyy-MM-dd"];
    NSDate *zeroDate= [dateFormatter dateFromString:dateString];
    return zeroDate;
}



//前面获取下载url
- (NSString *)getDownloadUrlWithBucketName:(NSString *)bucketName ObjectKey:(NSString *)objectKey{
    if (!self.tokenDict) {
        return nil;
    }
    NSString *key = self.tokenDict[@"key"];
    NSString *security = self.tokenDict[@"secret"];
    NSString *token = self.tokenDict[@"token"];
    NSString *endpoint = self.tokenDict[@"endPoint"];
    id<OSSCredentialProvider> credential = [[OSSStsTokenCredentialProvider alloc] initWithAccessKeyId:key secretKeyId:security securityToken:token];
    OSSClientConfiguration * conf = [OSSClientConfiguration new];
    conf.maxRetryCount = 2;
    conf.timeoutIntervalForRequest = 30;
    conf.timeoutIntervalForResource = 24 * 60 * 60;;
    self.client = [[OSSClient alloc] initWithEndpoint:endpoint credentialProvider:credential clientConfiguration:conf];
    OSSTask *mytask = [self.client presignConstrainURLWithBucketName:bucketName withObjectKey:objectKey withExpirationInterval:3600];
    return mytask.result;
}


#pragma mark - Event Handle
//云存储播放按钮点击时间
- (void)playBtnClick{
    self.isChangeDateManual = NO;
    [self openCloudPlay];
    self.currentPlayModel = self.currentSeekModel;
    self.previewView.hidden = YES;
    self.previewView.userInteractionEnabled = NO;
    [self decodeAndPlayVideoWithSeekTime:self.currentPreviewCacheSeekTimeIndex];
    //放到最大
    [self.ruler.rulerScrollView zoomToMAX];
}

/**
 开始云存储显示
 */
- (void)openCloudPlay{
    _isPlayCloudPlay = YES;
    //允许自动滚动
    self.ruler.rulerScrollView.canScroll = YES;
    if (!_isLandSpace) {
        self.cloudBottomView.hidden = NO;
    }
    self.cloudSoundBtn.selected = NO;
}



- (void)cloudSnapshotBtnAction:(UIButton *)btn{
    //保存图片
    [self saveVideoScreenShot];
}

- (void)shortCutAction:(UIButton *)btn{
    CloudShortCutViewController *shortCutVC = [[CloudShortCutViewController alloc]init];
    shortCutVC.deviceId = self.deviceModel.DeviceId;
    shortCutVC.cloudPlayVC = self;
    shortCutVC.currentSelectDate = self.currentSelectDate;
    
    if (!self.currentPlayModel) {
        //当前未播放，return
        return;
    }
    //获取当前播放模型的开始时间和结束时间
    long long startTime = self.currentPlayModel.accuracyfirstStamp;
    long long endTime = self.currentPlayModel.accuracylastStamp;
    NSInteger currentPlayTime = self.currentPlayTime;
    
    //遍历模型获取
    CloudVideoModel *searchVideoModel;
    for (CloudVideoModel *videoModel in self.cloudVideoArray) {
        //找到对应时间段
        if (videoModel.accuracyfirstStamp <= startTime && videoModel.accuracylastStamp >= endTime) {
            searchVideoModel = videoModel;
            break;
        }
    }
    if (!searchVideoModel) {
        return;
    }
    
    //连续时间段
    int timeSlape = (int)searchVideoModel.accuracylastStamp - (int)currentPlayTime;
    if (timeSlape <= 0) {
        //数据有问题 return
        return;
    }
    //大于10分钟
    if (timeSlape > 600) {
        timeSlape = 600;
    }
    shortCutVC.videoModel = searchVideoModel;
    shortCutVC.mins = timeSlape / 60;
    shortCutVC.seconds = timeSlape % 60;
    shortCutVC.currentShortCutTime = self.currentPlayTime;
    [self.navigationController pushViewController:shortCutVC animated:YES];
}

- (void)cloudSoundBtnAction:(UIButton *)btn{
    btn.selected = !btn.selected;
    if (btn.selected) {
        //暂停声音
        [self audioStop];
        [btn setImage:[UIImage imageNamed:@"PlayNoSoundNormal"] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:@"PlayNoSoundSelected"] forState:UIControlStateHighlighted];
    }
    else{
        //打开声音
        [self audioStart];
        [btn setImage:[UIImage imageNamed:@"PlaySoundNormal"] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:@"PlaySoundSelected"] forState:UIControlStateHighlighted];
    }
}

#pragma mark UIPickerView DataSource Method 数据源方法

//指定pickerview有几个表盘
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

//指定每个表盘上有几行数据
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.dateArray.count;
}


#pragma mark - Event Handle
- (void)selectDate{
    self.pickCoverView.hidden = NO;
}

#pragma mark UIPickerView Delegate Method 代理方法

//指定每行如何展示数据（此处和tableview类似）
-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSDate *date = self.dateArray[row];
    return [self getDateStringWithDate:date];
}


//选中时回调的委托方法
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (self.currentSelectDate == self.dateArray[row]) {
        //选择了同一天，直接return
        //        return;
    }
    self.previewView.hidden = YES;
    [UIView animateWithDuration:0.2 animations:^{
        self.pickCoverView.hidden = YES;
    }];
    self.isChangeDateManual = YES;
    self.currentSelectDate = self.dateArray[row];
    [self.dateButton setTitle:[self getDateStringWithDate:self.currentSelectDate] forState:UIControlStateNormal];
    [self.ruler.rulerScrollView initialized];
    //重新绘制
    [self.ruler.rulerScrollView drawRuler];
    //重新获取数据
    //先拷贝当前数据
    self.cacheCloudPlayUrlArray = [NSMutableArray array];
    for (NSObject *obj in self.cloudPlayUrlArray) {
        [self.cacheCloudPlayUrlArray addObject:obj];
    }
    [self getTokenWithLoading:YES];
}

#pragma mark - 播放相关
- (void)saveVideoScreenShot{
    BOOL capResult = [self.videoDecoder ac_captureWithPort:0 filePath: [self snapshotPath]];
    if (!capResult)
    {
        [self showNewStatusInfo:DPLocalizedString(@"localizied_9")];
    }
    else
    {
        [self showNewStatusInfo:DPLocalizedString(@"save_image")];
    }
}


- (NSString*)snapshotPath{
    NSString *path = [[MediaManager shareManager] mediaPathWithDevId:[self.deviceId substringFromIndex:8]
                                                            fileName:nil
                                                           mediaType:GosMediaSnapshot
                                                          deviceType:GosDeviceIPC
                                                            position:PositionMain];
    return path;
}

-(void)showNewStatusInfo:(NSString*)info
{
    [SVProgressHUD showInfoWithStatus:info];
    [SVProgressHUD dismissWithDelay:2];
}


#pragma mark - 横竖屏切换相关
#pragma mark -- 是否允许横竖屏
-(BOOL)shouldAutorotate
{
    return YES;
}

#pragma mark -- 横竖屏方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;;
}



#pragma mark - Private Methods

#pragma mark 云台控制手势添加
- (void)tapClick:(UIGestureRecognizer *)gesture{
    if (_isLandSpace) {
      [self showCloudPlay];
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




#pragma mark -- 停止按钮音效播放器
-(void)releaseBtnSoundAudioPlayer
{
    if (self.snapShotBtnAudioPlayer)
    {
        [self.snapShotBtnAudioPlayer stop];
        self.snapShotBtnAudioPlayer = nil;
    }

}




/**
 开始播放音频
 */
-(BOOL)audioStart
{
    _isAudioOn = YES;
    [self.gdVideoPlayer startVoice];
    return YES;
}

/**
 停止播放音频
 */
-(BOOL)audioStop
{
    _isAudioOn = NO;
    [self.gdVideoPlayer stopVoice];
    return YES;
}



#pragma mark - 后台事件处理和网络监听处理
-(void)addBackgroundRunningEvent
{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
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
    //停止云存储播放
    [self.videoDecoder ac_pause:YES];

    //停止播放音频
    [self releaseBtnSoundAudioPlayer];
    //停止音频播放
    if (_isAudioOn) {
        [self audioStop];
    }
}

-(void)enterForeground
{
    if (!self.cloudSoundBtn.selected) {
        //打开声音
        [self audioStart];
    }
    //重新播放
    [self decodeAndPlayVideoWithSeekTime:0];
//    //初始化运行状态
//    [self configGDPlayer];
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
//- (void)enableSnapShotBtn{
//    dispatch_async_on_main_queue(^{
//        _snapshotBtn.userInteractionEnabled = YES;
//        [_snapshotBtn setImage:[UIImage imageNamed:@"PlayCameraNormal"] forState:UIControlStateNormal];
//        [_snapshotBtn setImage:[UIImage imageNamed:@"PlayCameraSelected"] forState:UIControlStateHighlighted];
//
//        _snapshotBtn_fullScreen.userInteractionEnabled = YES;
//        [_snapshotBtn_fullScreen setImage:[UIImage imageNamed:@"PlaySnapshotNormal_Full"] forState:UIControlStateNormal];
//        [_snapshotBtn_fullScreen setImage:[UIImage imageNamed:@"PlaySnapshotSelected_Full"] forState:UIControlStateHighlighted];
//    });
//}

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
        //设置默认G711播放
        [_gdVideoPlayer.decoder initlizeAudioFrameTypeToG711];
        NSString *covertPath = [[MediaManager shareManager] mediaPathWithDevId:self.deviceId
                                                                      fileName:nil
                                                                     mediaType:GosMediaCover
                                                                    deviceType:GosDeviceIPC
                                                                      position:PositionMain];
        _gdVideoPlayer.coverPath = covertPath;
        if (_isAudioOn) {
            [self audioStart];
        }
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



#pragma mark - Getter && Setter

/**
 *  播放视频 View
 */
- (UIView *)playView{
    if (!_playView) {
        _playView = [[UIView alloc]init];
        _playView.backgroundColor = [UIColor blackColor];
        //添加单击手势
        UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapClick:)];
        [_playView addGestureRecognizer:tapGes];
    }
    return _playView;
}


/**
 *  视频数据加载 Activity
 */

- (UIActivityIndicatorView *)loadVideoActivity{
    if (!_loadVideoActivity) {
        _loadVideoActivity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [_loadVideoActivity startAnimating];
        _loadVideoActivity.hidden = YES;
    }
    return _loadVideoActivity;
}

#pragma mark - 全屏按钮初始化
- (void)setDeviceModel:(DeviceDataModel *)deviceModel{
    _deviceModel = deviceModel;
    if (deviceModel.DeviceId.length != 15) {
        _deviceId   = [deviceModel.DeviceId substringFromIndex:8];//截取掉下标7之后的字符串
    }
    else{
        _deviceId = deviceModel.DeviceId;
    }
    _deviceName = deviceModel.selectedSubDevInfo.ChanName.length>0 ? deviceModel.selectedSubDevInfo.ChanName:  deviceModel.DeviceName;
    _platformUID= deviceModel.DeviceId;
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





#pragma mark - 云存储 getter


//没有视频数据提示label
- (UILabel *)noVideoDataLabel{
    if (!_noVideoDataLabel) {
        _noVideoDataLabel = [UILabel new];
        _noVideoDataLabel.text = DPLocalizedString(@"PlayVideo_CS_NoVideoData");
        _noVideoDataLabel.backgroundColor =  [UIColor colorWithHexString:@"0x1fbcd2"];
        _noVideoDataLabel.textColor = [UIColor whiteColor];
        _noVideoDataLabel.hidden = YES;
        _noVideoDataLabel.textAlignment = NSTextAlignmentCenter;
        _noVideoDataLabel.layer.masksToBounds = YES;
        _noVideoDataLabel.layer.cornerRadius = 5.0f;
    }
    return _noVideoDataLabel;
}


- (UIButton *)dateButton{
    if (!_dateButton) {
        _dateButton = [[UIButton alloc]initWithFrame:CGRectMake((SCREEN_WIDTH - 120)/2, 20, 120, 30)];
        _dateButton.backgroundColor = [UIColor whiteColor];
        _dateButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
        [_dateButton setBackgroundImage:[UIImage imageNamed:@"CloudDateBtnBG"] forState:UIControlStateNormal];
        [_dateButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_dateButton addTarget:self action:@selector(selectDate) forControlEvents:UIControlEventTouchUpInside];
    }
    return _dateButton;
}

- (UIButton *)netErrorButton{
    if (!_netErrorButton) {
        _netErrorButton = [[UIButton alloc]initWithFrame:CGRectMake((SCREEN_WIDTH - 120)/2, HeightForStatusBarAndNaviBar+SCREEN_WIDTH * playViewRatio + 120, 120, 30)];
        _netErrorButton.backgroundColor = [UIColor whiteColor];
        _netErrorButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
        [_netErrorButton setTitle:DPLocalizedString(@"reloadBtn") forState:UIControlStateNormal];
        [_netErrorButton setBackgroundImage:[UIImage imageNamed:@"CloudDateBtnBG"] forState:UIControlStateNormal];
        [_netErrorButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_netErrorButton addTarget:self action:@selector(getCloudVideoTime) forControlEvents:UIControlEventTouchUpInside];
        _netErrorButton.hidden = YES;
    }
    return _netErrorButton;
}



- (UIView *)dateView{
    if (!_dateView) {
        _dateView = [[UIView alloc]initWithFrame:CGRectMake(0, HeightForStatusBarAndNaviBar+SCREEN_WIDTH * playViewRatio + 120, SCREEN_WIDTH, 60)];
        _dateView.backgroundColor = [UIColor whiteColor];
    }
    return _dateView;
}




- (NSDate *)currentTimeDate{
    return [NSDate dateWithTimeIntervalSinceNow:0];
}



- (NSMutableArray *)cloudPlayUrlArray{
    if (!_cloudPlayUrlArray) {
        _cloudPlayUrlArray = [NSMutableArray array];
    }
    return _cloudPlayUrlArray;
}

- (NSMutableArray *)cloudVideoArray{
    if (!_cloudVideoArray) {
        _cloudVideoArray = [NSMutableArray array];
    }
    return _cloudVideoArray;
}


- (NSMutableArray *)cloudAlarmArray{
    if (!_cloudAlarmArray) {
        _cloudAlarmArray = [NSMutableArray array];
    }
    return _cloudAlarmArray;
}


/**
 *  声音开关 Button
 */
- (UIButton *)cloudSoundBtn{
    if (!_cloudSoundBtn) {
        _cloudSoundBtn = [[UIButton alloc]init];
        [_cloudSoundBtn addTarget:self action:@selector(cloudSoundBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_cloudSoundBtn setImage:[UIImage imageNamed:@"PlaySoundNormal"] forState:UIControlStateNormal];
        [_cloudSoundBtn setImage:[UIImage imageNamed:@"PlaySoundSelected"] forState:UIControlStateHighlighted];
        //        _soundBtn.userInteractionEnabled = NO;
    }
    return _cloudSoundBtn;
}


/**
 *  剪切 Button
 */
- (UIButton *)cloudShortCutBtn{
    if (!_cloudShortCutBtn) {
        _cloudShortCutBtn = [[UIButton alloc]init];
        [_cloudShortCutBtn setImage:[UIImage imageNamed:@"btn_shear_normal"] forState:UIControlStateNormal];
        [_cloudShortCutBtn setImage:[UIImage imageNamed:@"btn_shear_press"] forState:UIControlStateHighlighted];
        [_cloudShortCutBtn addTarget:self action:@selector(shortCutAction:) forControlEvents:UIControlEventTouchUpInside];
        //        _shortCutBtn.userInteractionEnabled = NO;
    }
    return _cloudShortCutBtn;
}


/**
 *  拍照 Button
 */

- (UIButton *)cloudSnapshotBtn{
    if (!_cloudSnapshotBtn) {
        _cloudSnapshotBtn = [[UIButton alloc]init];
        [_cloudSnapshotBtn addTarget:self action:@selector(cloudSnapshotBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_cloudSnapshotBtn setImage:[UIImage imageNamed:@"PlayCameraNormal"] forState:UIControlStateNormal];
        [_cloudSnapshotBtn setImage:[UIImage imageNamed:@"PlayCameraSelected"] forState:UIControlStateHighlighted];
        //        _snapshotBtn.userInteractionEnabled = NO;
    }
    return _cloudSnapshotBtn;
}


/**
 *  声音开关 Label
 */
- (UILabel *)cloudSoundLabel{
    if (!_cloudSoundLabel) {
        _cloudSoundLabel = [[UILabel alloc]init];
        _cloudSoundLabel.font = [UIFont systemFontOfSize:14.0f];
        _cloudSoundLabel.textColor = [UIColor colorWithHexString:@"0x242421"];
        _cloudSoundLabel.text = DPLocalizedString(@"play_Sound");
        _cloudSoundLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _cloudSoundLabel;
}


/**
 *  剪切 Label
 */
- (UILabel *)cloudShortCutLabel{
    if (!_cloudShortCutLabel) {
        _cloudShortCutLabel = [[UILabel alloc]init];
        _cloudShortCutLabel.font = [UIFont systemFontOfSize:14.0f];
        _cloudShortCutLabel.textColor = [UIColor colorWithHexString:@"0x242421"];
        _cloudShortCutLabel.text = DPLocalizedString(@"PlayVideo_CS_Cut");
        _cloudShortCutLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _cloudShortCutLabel;
}


/**
 *  拍照 Label
 */
- (UILabel *)cloudSnapshotLabel{
    if (!_cloudSnapshotLabel) {
        _cloudSnapshotLabel = [[UILabel alloc]init];
        _cloudSnapshotLabel.font = [UIFont systemFontOfSize:14.0f];
        _cloudSnapshotLabel.textColor = [UIColor colorWithHexString:@"0x242421"];
        _cloudSnapshotLabel.text = DPLocalizedString(@"play_Snapshot");
        _cloudSnapshotLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _cloudSnapshotLabel;
}

/**
 *  底部 View
 */
- (UIView *)cloudBottomView{
    if (!_cloudBottomView) {
        _cloudBottomView = [[UIView alloc]init];
        _cloudBottomView.backgroundColor = [UIColor whiteColor];
    }
    return _cloudBottomView;
}



- (UIButton *)previewView{
    if (!_previewView) {
        //        _previewView = [[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH/2.0f - 60, playViewRatio * SCREEN_WIDTH - 45, 120, 90)];
        _previewView = [[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH/2.0f - 60, -90, 120, 90)];
        _previewView.backgroundColor = [UIColor blackColor];
        [_previewView addTarget:self action:@selector(playBtnClick) forControlEvents:UIControlEventTouchUpInside];
        _previewView.userInteractionEnabled = NO;
        _previewView.hidden = YES;
    }
    return _previewView;
}

- (UIImageView *)playButton{
    if (!_playButton) {
        _playButton = [[UIImageView alloc]initWithFrame:CGRectMake(45, 20, 30, 30)];
        _playButton.userInteractionEnabled = NO;
        UIImage *image = [UIImage imageNamed:@"Cloud_btn_play_normal"];
        _playButton.image = image;
        _playButton.hidden = YES;
    }
    return _playButton;
}

- (UIView *)preViewCoverView{
    if (!_preViewCoverView) {
        _preViewCoverView = [[UIView alloc]initWithFrame:CGRectMake(0, 60, 120, 30)];
        _preViewCoverView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        //        _preViewCoverView.alpha = 0.5;
    }
    return _preViewCoverView;
}

- (UIImageView *)preCoverImgView{
    if (!_preCoverImgView) {
        _preCoverImgView = [[UIImageView alloc]initWithFrame:CGRectMake(15, 5, 20, 20)];
        _preCoverImgView.image = [UIImage imageNamed:@"ic_cloud_alarm_motion"];
    }
    return _preCoverImgView;
}

- (UILabel *)previewTimeLabel{
    if (!_previewTimeLabel) {
        _previewTimeLabel = [[UILabel alloc]initWithFrame:CGRectMake(30, 0, 90, 30)];
        _previewTimeLabel.textAlignment = NSTextAlignmentCenter;
        _previewTimeLabel.font = [UIFont boldSystemFontOfSize:14.0f];
        _previewTimeLabel.textColor = [UIColor whiteColor];
        _previewTimeLabel.backgroundColor = [UIColor clearColor];
        _previewTimeLabel.alpha = 1.0f;
    }
    return _previewTimeLabel;
}

- (UIButton *)cloudOrderButton{
    if (!_cloudOrderButton) {
        _cloudOrderButton = [[UIButton alloc]initWithFrame:CGRectMake(0, HeightForStatusBarAndNaviBar+playViewRatio *kScreen_Width, kScreen_Width, 120)];
        UIImage *image = [UIImage imageNamed:@"img_cloud_ad"];
        [_cloudOrderButton setBackgroundImage:image forState:UIControlStateNormal];
        [_cloudOrderButton addTarget:self action:@selector(orderCloud) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cloudOrderButton;
}

- (UIActivityIndicatorView *)cloudLoadVideoActivity{
    if (!_cloudLoadVideoActivity) {
        _cloudLoadVideoActivity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _cloudLoadVideoActivity.frame = CGRectMake(35, 20, 50, 50);
        [_cloudLoadVideoActivity startAnimating];
        _cloudLoadVideoActivity.hidden = YES;
    }
    return _cloudLoadVideoActivity;
}

- (NSMutableArray *)shortCutArray{
    if (!_shortCutArray) {
        _shortCutArray = [NSMutableArray array];
    }
    return _shortCutArray;
}


@end

