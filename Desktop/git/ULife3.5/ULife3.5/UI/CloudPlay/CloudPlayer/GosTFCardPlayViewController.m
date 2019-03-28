//
//  CloudSDCardViewController.m
//  ULife3.5
//
//  Created by zz on 2018/3/17.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "GosTFCardPlayViewController.h"
#import "Masonry.h"
#import "UIColor+YYAdd.h"
#import "UIView+YYAdd.h"
#import "CameraInfoManager.h"
#import "DeviceManagement.h"
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
#import "CloudShortCutViewController.h"
#import "GDVideoPlayer.h"
#import "ACVideoDecoder.h"
#import "GDPlayerView.h"
#import "PCMPlayer.h"
#import "SaveDataModel.h"
#import "SDCloudAlarmModel.h"
#import "SDCloudVideoModel.h"
#import "AHRuler.h"
#import "OSSUtil.h"
#import "OSSTask.h"
#import "OSSClient.h"
#import "OSSModel.h"
#import <AFNetworking.h>
#import "StreamPasswordView.h"
#import "BaseCommand.h"
#import "NetSDK.h"
#import "GOSNetStatusManager.h"
#import "PushMessageManagement.h"
#import "RecordNoSDCardView.h"
#import "GosTFCardViewController.h"

//播放通知Key
static NSString *const PlayStatusNotification = @"PlayStatusNotification";
static NSString *const ConvertMP4Notification = @"ConvertMP4Notification";

#define JOYSTICK_ANIMATION_DURATION 0.25f
#define NetInstanceManager [NetAPISet sharedInstance]
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


@interface GosTFCardPlayViewController ()<
GDVideoPlayerDelegate,
GDNetworkSourceDelegate,
GDNetworkStateDelegate,
AHRrettyRulerDelegate,UIPickerViewDelegate,UIPickerViewDataSource
>{
    //是否连接上视频流
    BOOL _isRunning;
    
    //audio Flag
    BOOL _isAudioOn;
    
    //是否已经退出该界面
    BOOL _isNavBack;
    
    BOOL isSaveRecord;
}

@property(nonatomic,strong)RecordNoSDCardView *noSDCardView;

@property(nonatomic,strong)UIView             *noSDCardViewBg;

/** 播放视频 View */
@property (strong, nonatomic)  UIView *playView;

/** 视频数据加载 Activity */
@property (strong, nonatomic)  UIActivityIndicatorView *loadVideoActivity;

/** 重新请求按钮 */
@property (nonatomic, strong) UIButton *reloadBtn;

/** 离线按钮 */
@property (nonatomic, strong) UIButton *offlineBtn;

/** 对讲弹出的View */
@property (nonatomic, strong) UIImageView *talkingView;

/** 预览图片imgView */
@property (nonatomic, strong) UIImageView *previewImgView;

/** Camera Info Manager */
@property (nonatomic, strong) CameraInfoManager *cameraInfoManger;

/** 播放器 */
@property (nonatomic, strong) GDVideoPlayer *gdVideoPlayer;

/** 拍照按钮点击声音 播放器 */
@property (nonatomic, strong) AVAudioPlayer *snapShotBtnAudioPlayer;

/** 平台UID */
@property (nonatomic, strong)NSString *platformUID;

/** 是否全屏 */
@property (nonatomic,assign)BOOL isLandSpace;

/** 流超时定时器 */
@property(nonatomic,strong)NSTimer *streamTimer;

/** 拉流计时 */
@property(nonatomic,assign)NSUInteger streamTime;

@property (nonatomic,strong)dispatch_queue_t serailQueue;

@property (nonatomic,strong)StreamPasswordView *passwordView;


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

/***************************************云存储数据*********************************************/

/**当前选中日期*/
@property (nonatomic,strong)NSDate *currentSelectDate;

/**当前时间日期*/
@property (nonatomic,strong)NSDate *currentTimeDate;

/**pickView date Array*/
@property (nonatomic,strong)NSMutableArray *dateArray;

///**SD卡录制视频数组*/
//@property (nonatomic,strong)NSMutableArray *cloudVideoArray;

/**报警视频数组*/
@property (nonatomic,strong)NSMutableArray *cloudAlarmArray;

/**拖动时候预览时间点*/
@property (nonatomic,assign)NSInteger currentPreviewSeekTimeIndex;

/**拖动时候缓存预览时间点,用于seek到准确位置*/
@property (nonatomic,assign)NSInteger currentPreviewCacheSeekTimeIndex;

/**拖动时候当前播放的时间点*/
@property (nonatomic,assign)NSInteger currentPlaySeekTimeIndex;

/**当前播放时间*/
@property (nonatomic,assign)NSInteger currentPlayTime;

/**剪切视频文件名*/
@property (nonatomic,copy)NSString *shortCutFileName;

/***************************************云存储BOOL标识*********************************************/

/**是否手动切换了日期，这里逻辑相对复杂，需要这个标识符*/
@property (nonatomic,assign)BOOL isChangeDateManual;

/**SD卡当前播放Model*/
@property (nonatomic,strong)SDCloudVideoModel *sdPlayModel;

/**SD卡Unix时间,记录获取预览图时候对应的unixTime*/
@property (nonatomic,assign)int sdUnixTime;

/**SD卡当前播放时间*/
@property (nonatomic,assign)int sdCurrentPlayTime;

/**云存储的秒表 1s跳动一次*/
@property (nonatomic,strong)NSTimer *secondTimer;

/**重新拉取云存储数据timer 默认是60s*/
@property (nonatomic,strong)NSTimer *reloadDataTimer;

/**SD卡视频数据临时数组*/
@property (nonatomic,strong)NSMutableArray *tempSDVideoArray;

/**SD卡报警数据临时组装数组*/
@property (nonatomic,strong)NSMutableArray *tempSDAlarmArray;

/**SD卡日期查询*/
@property(nonatomic,strong)CMD_GetRecFileOneMonthResp *getAllRecFileResp;

/**剪切开始时间*/
@property (nonatomic,assign)NSInteger shortCutStartTime;

/**剪切总共时间*/
@property (nonatomic,assign)NSInteger shortCutTotalTime;



@property (nonatomic,strong)UIButton *pickCancelButton;

/**netErrorButton*/
@property (nonatomic,strong)UIButton *netErrorButton;

//正在播放
@property (nonatomic,assign)BOOL isPlaying;

//是否已经缓存好播放
@property (nonatomic,assign)BOOL isReadyPlay;


@property (nonatomic,assign)BOOL isFirstIn;
/// 记录下载的目标路径
@property (nonatomic, copy) NSString *destinationPath;
/// 标记当前视频已经播放完毕，没有必要再播下一段
@property (nonatomic, assign) BOOL isLoadStreamOnceTime;

@property (nonatomic, strong) UIButton *replayButton;

@end

@implementation GosTFCardPlayViewController

- (UIButton *)replayButton {
    if (!_replayButton) {
        _replayButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_replayButton setImage:[UIImage imageNamed:@"icon_play"] forState:UIControlStateNormal];
        [_replayButton addTarget:self action:@selector(replayButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _replayButton;
}

- (void)replayButtonDidClick:(id)sender {
    _isLoadStreamOnceTime = NO;
    
    [self initAppearAction];
    
    if (_isLandSpace) {
        [self resetPlayerView];
    }
    
    if (_isFirstIn) {
        _isFirstIn = NO;
        //第一次进来不解码
        [self.gdVideoPlayer.decoder stopAcDecode];
    }
    
    [self.gdVideoPlayer.decoder sendSDCardCommandWithType:SDCommandTypeLive destinaFileName:nil callBack:nil];
}

/// 时间戳 -> String 00:00:00
- (NSString *)getStartTime:(long long)time {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    NSDateComponents *comps = [[NSCalendar currentCalendar] components: NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:date];
    
    return [NSString stringWithFormat:@"%02zd:%02zd:%02zd", comps.hour, comps.minute, comps.second];
}
- (void)setPushMsgModel:(PushMessageModel *)pushMsgModel {
    _pushMsgModel = pushMsgModel;

    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    dateFormat.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    _pushTime = [[dateFormat dateFromString:pushMsgModel.pushTime] timeIntervalSince1970];
//    self.startTime = [date timeIntervalSince1970];
//    self.saveFileName = [self getFileName:[self getStartTime:self.startTime] date:date];
    // TODO: 获取此列表
//    vc.startTime = model.S;
//    vc.endTime = model.E;
//    vc.saveFileName = [self getFileName:model.startTime];
}

- (NSString *)getFileName:(NSString *)time currentTime:(NSTimeInterval)currentTime {
    NSDateComponents *comp = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[NSDate dateWithTimeIntervalSince1970:currentTime]];
    return [NSString stringWithFormat:@"%ld-%ld-%ld-%@", (long)comp.year, (long)comp.month, (long)comp.day, time];
}

#pragma mark - ViewController 生命周期
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.serailQueue = dispatch_queue_create("StopAction", DISPATCH_QUEUE_SERIAL);
    
    //初始化UI
    [self setupUI];
    _isLoadStreamOnceTime = NO;
    //初始化音频
    [self audioInit];
    
    //禁用锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    //后台事件监听
    [self addBackgroundRunningEvent];
    
    //创建文件夹
    [self creatFolder];
    
    [self addClientConnectStatusNotification];
    
    //云存储逻辑
//    [self configCloudPlay];
    
    _isFirstIn = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.loadVideoActivity.hidden = YES;
    });
    
    [self checkNetwork];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self getDaysHasRecord];
    });
}

/// 获取当月是否存在视频记录
- (void)getDaysHasRecord {
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [SVProgressHUD showWithStatus:DPLocalizedString(@"loading")];
//    });
    
    CMD_GetRecFileOneMonthReq *req = [CMD_GetRecFileOneMonthReq new];
    req.channel = 0;//self.channel;
//    req.subId = self.deviceModel.DeviceId;
    NSDictionary *reqData = [req requestCMDData];
    __weak typeof(self) weakself = self;
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:self.deviceModel.DeviceId requestData:reqData timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [SVProgressHUD dismiss];
//        });
        if (!weakself) return ;
        
        if (result == 3) {
            [weakself getHasRecordDataNoCard];
        }
    }];
}

/// 获取当月视频记录失败->无卡
- (void)getHasRecordDataNoCard {
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        [self configureForNoSDCardView];
        [self addNoSDCardViewIntoKeyWindow];
    });
}

- (void)checkNetwork{
    
    if (self.deviceModel.Status != GosDeviceStatusOnLine) {
        //不在线 return
        return;
    }
    [GOSNetStatusManager checkIfUsingCellularData];
}

- (void)stopCheckingNetwork{
    [GOSNetStatusManager stopCheckingUsingCellularData];
}

- (void)setAlarmMsgTime:(NSTimeInterval)alarmMsgTime{
    _alarmMsgTime = alarmMsgTime;
}


- (void)viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
    _isLoadStreamOnceTime = NO;
    //刷新设备名称和导航条透明度
    self.navigationController.navigationBar.translucent=YES;
    for (DeviceDataModel *model in [[DeviceManagement sharedInstance] deviceListArray]) {
        if ([model.DeviceId isEqualToString:self.deviceModel.DeviceId]) {
            _deviceName = model.selectedSubDevInfo.ChanName.length>0 ? model.selectedSubDevInfo.ChanName:  model.DeviceName;
            break;
        }
    }
    UILabel *tLabel = [CommonlyUsedFounctions titleLabelWithStr:[NSString stringWithFormat:@"%@",_deviceName]];
    self.navigationItem.titleView = tLabel;
    
    [self initAppearAction];
    
    if (_isLandSpace) {
        [self resetPlayerView];
    }
    
    if (_isFirstIn) {
        _isFirstIn = NO;
        //第一次进来不解码
        [self.gdVideoPlayer.decoder stopAcDecode];
    }
    
    [self.gdVideoPlayer.decoder sendSDCardCommandWithType:SDCommandTypeLive destinaFileName:nil callBack:nil];
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
                make.top.equalTo(self.view).offset(HeightForStatusBarAndNaviBar*2.5);
                make.left.right.equalTo(self.view);
                make.height.mas_equalTo(self.playView.mas_width).multipliedBy(playViewRatio);
            }];
//            self.cloudBottomView.hidden = NO;
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
    if (self.gdVideoPlayer) {
        [self.gdVideoPlayer setPlayerView:self.playView];
    }
    [self addEnterForegroundNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playStatusChange:) name:PlayStatusNotification object:nil];
    
//    [self startRecordPlay];
}


- (void)viewWillDisappear:(BOOL)animated
{   _isLoadStreamOnceTime = YES;
    self.navigationController.navigationBar.translucent=NO;
    [super viewWillDisappear:animated];
    [self leaveViewAction];
    //销毁拉流定时器
    [self stopStreamTimer];
    [self stopReloadDataTimer];
    [self removeEnterForegroundNotifications];
    [SVProgressHUD dismiss];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PlayStatusNotification object:nil];
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
    
    //    [self releaseBtnSoundAudioPlayer];
    //    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"----------- CloudSDCardViewController dealloc -----------");
}

#pragma mark - 云存储核心逻辑

- (void)configCloudPlay{
    [self getSDCardVideoTimeFirst];
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

//获取SD卡套餐时长
- (void)getSDCardVideoTimeFirst{
    return ;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [SVProgressHUD showWithStatus:DPLocalizedString(@"loading")];
    });
    __weak typeof(self) weakSelf = self;
    //开始获取
    CMD_GetRecFileOneMonthReq *req = [CMD_GetRecFileOneMonthReq new];
    req.channel = _channel;
    req.subId = _deviceModel.selectedSubDevInfo.SubId;
    NSDictionary *reqData = [req requestCMDData];
    
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:self.platformUID requestData:reqData timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            weakSelf.getAllRecFileResp = [CMD_GetRecFileOneMonthResp yy_modelWithDictionary:dict];
            dispatch_async_on_main_queue(^{
                [weakSelf configDateArrayWithString:weakSelf.getAllRecFileResp.page_data];
                [weakSelf cloudPlayPrapare];
                weakSelf.netErrorButton.hidden = YES;
                //获取数据
                [weakSelf getSDCardVideoDataWithLoading:YES];
            });
        }else if (result == 2){
            //没有数据
            dispatch_async_on_main_queue(^{
                weakSelf.netErrorButton.hidden = YES;
                //只有一天数据
                [weakSelf loadDateDataWithDays:1];
                [weakSelf cloudPlayPrapare];
                //获取数据
                [weakSelf getSDCardVideoDataWithLoading:YES];
            });
        }
        else if (result == 3){
            dispatch_async_on_main_queue(^{
                [SVProgressHUD dismiss];
                //请求失败 没有插入SD卡
                if (self.alarmMsgTime > 0) {
                    [weakSelf showAlertWithMsg:DPLocalizedString(@"PlayVideo_VideoUnrecorded")]; //NoSDCard_Tips_Title
                }else{
                    [self configureForNoSDCardView];
                    [self addNoSDCardViewIntoKeyWindow];
                }
            });
        }
        else{
            dispatch_async_on_main_queue(^{
                if (_isNavBack) {
                    return;
                }
                weakSelf.netErrorButton.hidden = NO;
                //SD卡请求失败---需要重试
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"GetDataFailed_Retry")];
            });
        }
        
    }];
}


#pragma mark - NoSDCard

- (void)okBtnClicked:(id)sender{
    [self removeNoSDCardViewFromKeywindow];
}

- (void)removeNoSDCardViewFromKeywindow{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_noSDCardView removeFromSuperview];
        [_noSDCardViewBg removeFromSuperview];
        
        [self.navigationController popViewControllerAnimated:YES];
    });
}

- (void)configureForNoSDCardView {
    
    _noSDCardView = [[[NSBundle mainBundle] loadNibNamed:@"RecordNoSDCardView" owner:self options:nil] objectAtIndex:0];
    _noSDCardView.layer.cornerRadius = 10;
    
    _noSDCardView.noSDCardTitle.text = DPLocalizedString(@"NoSDCard_Tips_Title");
    _noSDCardView.sdCardAutoDetect.text = DPLocalizedString(@"NoSDCard_Tips_InsertSDCardAutoRecording");
    _noSDCardView.sdCardSupportedType.text = DPLocalizedString(@"NoSDCard_Tips_MaxStorageSupport");
    _noSDCardView.sdCardUnrecognized.text = DPLocalizedString(@"NoSDCard_Tips_SDCardUnrecognized");
    _noSDCardView.sdCardFAT32.text = DPLocalizedString(@"NoSDCard_Tips_SDCardFormat");
    
    _noSDCardViewBg = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    _noSDCardViewBg.backgroundColor = [UIColor blackColor];
    _noSDCardViewBg.alpha = 0.5;
}

- (void)addNoSDCardViewIntoKeyWindow{
    
    if (!_noSDCardView.superview) {
        [[UIApplication sharedApplication].keyWindow addSubview:_noSDCardViewBg];
        [[UIApplication sharedApplication].keyWindow addSubview: _noSDCardView];
        [_noSDCardView.okBtn setTitle:DPLocalizedString(@"camera_check_time_ok") forState:0];
        [_noSDCardView.okBtn addTarget:self action:@selector(okBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_noSDCardView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_noSDCardViewBg);
            make.leading.equalTo(_noSDCardViewBg).offset(10);
            make.width.equalTo(_noSDCardView.mas_height).multipliedBy(300/420.0);
        }];
    }
}

- (long long)getcurrentTimeValue{
    return [self.currentTimeDate timeIntervalSince1970] - [self.currentSelectDate timeIntervalSince1970];
}


-(void)startReloadDataTimer
{
    if ( _reloadDataTimer ==nil)
    {
        __weak typeof(self) weakSelf = self;
        self.reloadDataTimer =  [NSTimer yyscheduledTimerWithTimeInterval:60 block:^(NSTimer * _Nonnull timer) {
            if ([weakSelf isSameDay:weakSelf.currentSelectDate date2:weakSelf.currentTimeDate]) {
                [weakSelf getSDCardVideoDataWithLoading:NO];
            }
        } repeats:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (weakSelf.reloadDataTimer) {
                [weakSelf.reloadDataTimer setFireDate:[NSDate distantPast]];
                [[NSRunLoop mainRunLoop] addTimer:weakSelf.reloadDataTimer forMode:NSDefaultRunLoopMode];
            }
        });
        
    }
}

- (void)stopReloadDataTimer
{
    if (_reloadDataTimer) {
        [_reloadDataTimer invalidate];
        _reloadDataTimer = nil;
    }
}


#pragma mark -- 设置相关 UI
- (void)setupUI{
    //标题
    self.title = [NSString stringWithFormat:@"%@-%@",self.deviceName,DPLocalizedString(@"PlayVideo_TF")];
    //添加导航按钮
    [self configNavItem];
    
    //添加子View
    [self.view addSubview:self.netErrorButton];
    [self.view addSubview:self.playView];
    [self.view addSubview:self.loadVideoActivity];
    
    [self.view addSubview:self.reloadBtn];
    [self.view addSubview:self.offlineBtn];
    [self.view addSubview:self.noVideoDataLabel];
    [self.view addSubview:self.replayButton];
    [self makeConstraints];
    
    UIButton *saveBtn = [[UIButton alloc] init];
    [saveBtn addTarget:self action:@selector(saveRecordBtnDidClick) forControlEvents:UIControlEventTouchUpInside];
    [saveBtn setImage:[UIImage imageNamed:@"icon_download"] forState:UIControlStateNormal];
    [self.view addSubview:saveBtn];
    [saveBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.playView.mas_centerX).mas_offset(60);
        make.top.equalTo(self.playView.mas_bottom).offset(80);
        make.width.height.equalTo(@(50));
    }];
    
    UIButton *deleteBtn = [[UIButton alloc] init];
    [deleteBtn addTarget:self action:@selector(deleteRecordBtnDidClick) forControlEvents:UIControlEventTouchUpInside];
    [deleteBtn setImage:[UIImage imageNamed:@"icon_delete"] forState:UIControlStateNormal];
    [self.view addSubview:deleteBtn];
    [deleteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.playView.mas_centerX).mas_offset(-60);
        make.top.equalTo(self.playView.mas_bottom).offset(80);
        make.width.height.equalTo(@(50));
    }];
    
}

#pragma mark - 设置约束
- (void)makeConstraints{
    [self.playView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.equalTo(self.view).offset(HeightForStatusBarAndNaviBar*2.5);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(self.playView.mas_width).multipliedBy(playViewRatio);
    }];
    [self.loadVideoActivity mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.playView.mas_centerY);
        make.centerX.equalTo(self.playView.mas_centerX);
        make.width.height.equalTo(@50);
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
    
    [self.noVideoDataLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@150);
        make.height.equalTo(@30);
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-200);
    }];
    [self.replayButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.bottom.equalTo(self.playView);
    }];
    [self initBottomView];
    
}





- (void)showAlertWithMsg:(NSString *)msg{
    if (_isNavBack) {
        return;
    }
    UIAlertView *msgAlert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:self cancelButtonTitle:DPLocalizedString(@"Title_Confirm") otherButtonTitles:nil, nil];
    msgAlert.delegate = self;
    [msgAlert show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    [self navBack];
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


//初始化音频任务
- (void)audioInit{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
}


#pragma mark - 进入界面初始化

- (void)initAppearAction{
    //设置net代理
    [self setApiNetDelegate];
    if (self.deviceModel.Status == 1) {
        //初始化运行状态
        [self initRunningStatus];
        //填充播放器
        [self configGDPlayer];
        //连接设备
        NSLog(@"播放SD卡--------8");
        [self connctToDevice];
    }
    else{
        //设备不在线
        self.loadVideoActivity.hidden = YES;
        self.reloadBtn.hidden = YES;
        self.offlineBtn.hidden = NO;
        self.playView.layer.contents = [UIImage imageNamed:@""];
        _isRunning = NO;
    }
}


/**
 初始化设备运行状态
 */
- (void)initRunningStatus{
    _isRunning = NO;
    self.reloadBtn.hidden = YES;
    self.offlineBtn.hidden = YES;
    self.replayButton.hidden = YES;
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
        [SVProgressHUD showWithStatus:DPLocalizedString(@"Loading")];
        //主动添加设备
        [[NetAPISet sharedInstance] addClient:self.deviceId andpassword:self.deviceModel.StreamPassword];
    }
    
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
                self.loadVideoActivity.hidden = YES;
                if (type == NotificationTypeDisconnect) {
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
    });
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
    self.offlineBtn.hidden = YES;
    [self getLiveStreamData];
    [self.passwordView dismiss];
}

#pragma mark - 离开界面操作

- (void)leaveViewAction{
    //断开流连接
    [self stopConnecting];
    if (_passwordView) {
        [self.passwordView dismiss];
    }
}


-(void)stopConnecting
{
    //停止请求SD卡数据
    [NetInstanceManager sendStopSDCardCammand:self.deviceId];
    //停止请求视频流
    [NetInstanceManager stopPlayWithUID:self.deviceId streamType:kNETPRO_STREAM_REC];
    
    dispatch_async(self.serailQueue, ^{
        //停止播放音频
        [self releaseBtnSoundAudioPlayer];
        
        //停止音频播放
        if (_isAudioOn) {
            [self audioStop];
        }
        
        //停止请求音频流
        [NetInstanceManager setSpeakState:NO withUID:self.deviceId resultBlock:^(int result, int state, int cmd) {
            //
        }];
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
            self.loadVideoActivity.hidden = YES;
            [self showNewStatusInfo:DPLocalizedString(@"Play_Ipc_unonline")];
            self.playView.layer.contents = (id)[UIImage imageNamed:@""];
            self.reloadBtn.hidden = YES;
            self.offlineBtn.hidden = NO;
        }
        
    });
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
                make.top.equalTo(self.view).offset(HeightForStatusBarAndNaviBar*2.5);
                make.left.right.equalTo(self.view);
                make.height.mas_equalTo(self.playView.mas_width).multipliedBy(playViewRatio);
            }];
//            self.cloudBottomView.hidden = NO;
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
//        self.cloudBottomView.hidden = NO;
        self.dateView.hidden = NO;
        self.ruler.hidden = NO;
        self.previewView.frame = CGRectMake(trueSreenWidth/2.0f - 60, -90, 120, 90);
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
    self.ruler.rulerDeletate = self.ruler.isHidden?nil:self;
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
    if ([self.deviceId isEqualToString:deviceId])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            //关闭拉流定时器
            [self stopStreamTimer];
        });
        [_gdVideoPlayer AddVideoFrame:pContentBuffer
                                  len:length
                                   ts:timeStamp
                               framNo:framNO
                            frameRate:frameRate
                               iFrame:isIFrame
                         andDeviceUid:deviceId];
    }
}

- (void)sendDataTypeState:(SendDataType)type andUID:(NSString *)UID errno_ret:(int)error_t
{
    
}




#pragma mark -语音数据
-(void)sendAudioData:(Byte *)buffer len:(int)len framNo:(unsigned int)framNO andUID:(NSString *)UID frameType:(gos_codec_type_t)frameType
{
    [_gdVideoPlayer AddAudioFrame:buffer len:len frameType:frameType];
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



#pragma mark - 按钮事件中心

- (void)navBack{
    NSLog(@"'返回’事件");
    _isNavBack = YES;
    [self stopReloadDataTimer];
    [self stopStreamTimer];
    [self removGDPlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.navigationController popViewControllerAnimated:YES];
    [self RemoveApiNetDelegate];
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

- (BOOL)checkFileIsDownload {
    NSString *path = [self getMP4DestinationFileNamePathWith:[NSString stringWithFormat:@"%@.mp4", self.saveFileName]];
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

- (NSString *)recordPath {
    return nil;
}

- (void)convertMP4WithStartValue:(NSInteger)startValue totalValue:(NSInteger)totalValue fileName:(NSString *)fileName{
    self.shortCutTotalTime = totalValue;
    self.shortCutFileName = [NSString stringWithFormat:@"%@.mp4",fileName];
    self.destinationPath = [self getMP4DestinationFileNamePathWith:self.shortCutFileName];
    
    //发送指令开始裁剪
    [self.gdVideoPlayer.decoder sendSDCardCommandWithType:SDCommandTypeVideo destinaFileName:self.destinationPath callBack:nil];
    //剪切数据 --默认使用1s发送过去
    [NetInstanceManager sendSDCardControlWithType:2 deviceId:self.deviceId sudId:_deviceModel.selectedSubDevInfo.SubId startTime:(int)self.startTime duration:(int)totalValue];
    return;
    
    //先要打开流
    [NetInstanceManager startGettingVideoDataWithUID:self.deviceId videoType:4 resultBlock:^(int result, int state) {
        if (result == 0) {
            NSLog(@"剪切SD卡打开流成功");
            //发送指令开始裁剪
            [self.gdVideoPlayer.decoder sendSDCardCommandWithType:SDCommandTypeVideo destinaFileName:[self getMP4DestinationFileNamePathWith:self.shortCutFileName] callBack:nil];
            //剪切数据 --默认使用1s发送过去
            [NetInstanceManager sendSDCardControlWithType:2 deviceId:self.deviceId sudId:_deviceModel.selectedSubDevInfo.SubId startTime:(int)self.startTime duration:(int)totalValue];
        }
        else{
            NSLog(@"剪切SD卡打开流失败");
            //裁剪失败
            NSDictionary *notifyData = @{@"result":[NSNumber numberWithInt:0]
                                         };
            [[NSNotificationCenter defaultCenter] postNotificationName:ConvertMP4Notification object:nil userInfo:notifyData];
        }
    }];
}


- (NSString *)getMP4DestinationFileNamePathWith:(NSString *)fileName{
    NSString *devId = (self.deviceModel.DeviceId.length) == 15 ? self.deviceModel.DeviceId : [self.deviceModel.DeviceId substringFromIndex:8];
    NSString *folder = [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES)lastObject] stringByAppendingPathComponent:devId] stringByAppendingPathComponent:@"Record"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:folder]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    //    NSLog(@"下载路径: %@", path);
    return [folder stringByAppendingPathComponent:fileName];
//    NSString *path = [[MediaManager shareManager] mediaPathWithDevId:(self.deviceModel.DeviceId.length) == 15 ? self.deviceModel.DeviceId : [self.deviceModel.DeviceId substringFromIndex:8] fileName:fileName mediaType:GosMediaShortCut deviceType:GosDeviceIPC position:PositionMain];
//    return path;
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
    //    NSNumber * nPort = (NSNumber *)statusDict[@"nPort"];
    //    NSNumber * lUserParam = (NSNumber *)statusDict[@"lUserParam"];
    //    ACVideoDecoder *videoDecode = statusDict[@"Decode"];
    
    if (eventRec.intValue == 15 || eventRec.intValue == 16) {
    } else {
        printf("daniel: 播放回调: %d\n", [eventRec intValue]);
    }
    if (eventRec.intValue == 17) {
        //表示历史流加载中
        NSLog(@"daniel: %@", statusDict);
        // 加载过一次就不再加载
        if (_isLoadStreamOnceTime) {
            dispatch_async_on_main_queue(^{
                self.replayButton.hidden = NO;
            });
            return ;
        }
        dispatch_async_on_main_queue(^{
            
            self.loadVideoActivity.hidden = NO;
            [self.loadVideoActivity startAnimating];
        });
        
        return;
    }
    
    if (eventRec.intValue == 18) {
        //表示历史流加载完成
        dispatch_async_on_main_queue(^{
            self.loadVideoActivity.hidden = YES;
        });
        return;
    }
    
    if(eventRec.intValue == 11){
        if (self.sdPlayModel) {
            dispatch_async_on_main_queue(^{
                //SD卡抓拍成功
                UIImage *image = [UIImage imageNamed:[self getSDPreViewPhotoPathWithPlayModel:self.sdPlayModel]];
                if (image) {
                    NSLog(@"SD卡预览图存在，并且成功获取了");
                    [self.previewView setBackgroundImage:image forState:UIControlStateNormal];
                    self.previewView.userInteractionEnabled = YES;
                    self.previewView.hidden = NO;
                    [self.view bringSubviewToFront:self.previewView];
                    self.cloudLoadVideoActivity.hidden = YES;
                    self.playButton.hidden = NO;
                }
            });
            
        }
        return;
    }
    
//    if(eventRec.intValue == 12){
//        if (self.isChangeDateManual) {
//            //更换了日期 直接return
//            return;
//        }
//        int lValue = lData.intValue;
//        //如果存在seek的话
//        if (self.sdUnixTime > 1000) {
//            if (lValue - 10<=self.sdUnixTime && lValue + 10 >= self.sdUnixTime) {
//                //seek成功
//                self.sdUnixTime = 0;
//            }
//            else{
//                //                return;
//            }
//        }
//        dispatch_async_on_main_queue(^{
//            if (self.ruler.rulerScrollView.canScroll) {
//                //隐藏预览图View
//                self.previewView.hidden = YES;
//            }
//            int timeValue = lData.intValue - [self.currentSelectDate timeIntervalSince1970];
//            if (timeValue >= 3600 * 24) {
//                [self handleNextPlay];
//                return;
//            }
//            self.sdCurrentPlayTime = lValue;
//            if (timeValue >0) {
//                [self.ruler.rulerScrollView playViewTimeIntervalDrawCurrentIndicatorWithValue:timeValue withScroll:YES];
//            }
//        });
//        return;
//    }
    
    if (eventRec.intValue == 13) {
        // 剪切成功
        dispatch_async_on_main_queue(^{
            
            isSaveRecord = NO;
            [NetInstanceManager stopPlayWithUID:self.deviceId streamType:kNETPRO_STREAM_REC];
//            NSString *path = [[MediaManager shareManager] mediaPathWithDevId:self.deviceId fileName:[NSString stringWithFormat:@"%@.mp4", self.saveFileName] mediaType:GosMediaShortCut deviceType:GosDeviceIPC position:PositionMain];
//
//            NSLog(@"剪切 -- path: %@ - exist: %@  media - %@ - exist:%d", self.destinationPath, [[NSFileManager defaultManager] fileExistsAtPath:self.destinationPath]?@"YES":@"NO", path, [[NSFileManager defaultManager] fileExistsAtPath:path]);
            [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"PlayVideo_Download_Succeeded") ];
            [SVProgressHUD dismissWithDelay:3 completion:^{
                [self.navigationController popViewControllerAnimated:YES];
            }];
//            [self showAlertWithMsg:DPLocalizedString(@"PlayVideo_Download_Succeeded")];
            
//
        });
    }
    
    if (eventRec.intValue == 14) {
        //表示历史流全部播放完成
        dispatch_async_on_main_queue(^{
            self.loadVideoActivity.hidden = YES;
            [self.loadVideoActivity stopAnimating];
//            self.noVideoDataLabel.text = MLocalizedString(Play_Tip_LastVideoPlayed);
//            self.noVideoDataLabel.numberOfLines = 2;
//            self.noVideoDataLabel.adjustsFontSizeToFitWidth = YES;
//            [self showNoDataLabel];
        });
        return;
    }
    
    if (eventRec.intValue == 15) {
        //表示buffer满了 停止播放 只对历史流生效
        [NetInstanceManager pasueRecvStream:1 deviceId:self.deviceId];
        return;
    }
    
    if (eventRec.intValue == 16) {
        //表示buffer空闲了 开始播放 只对历史流生效
        [NetInstanceManager pasueRecvStream:0 deviceId:self.deviceId];
        return;
    }
    
    if(eventRec.intValue == 12) {
        NSLog(@"当前时间 %d - (%lld, %lld) - %d", lData.intValue, self.startTime, self.endTime, isSaveRecord);
        if (lData.intValue < self.startTime && !isSaveRecord) {
            _isLoadStreamOnceTime = YES;
//            dispatch_async_on_main_queue(^{
//                [NetInstanceManager stopPlayWithUID:self.deviceId streamType:kNETPRO_STREAM_REC];
//            });
        }
    }
}

- (void)delaySetReadyPlayStatus{
    _isReadyPlay = YES;
}

- (void)handleNextPlay{
    
    dispatch_async_on_main_queue(^{
        if ([self isSameDay:self.currentSelectDate date2:self.currentTimeDate]) {
            //是同一天 跳转到当前播放 播放完了
            
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
            
            //直接获取SD卡数据
            [self getSDCardVideoDataWithLoading:YES];
            
        }
        
    });
};


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
    //SD卡播放
    __block SDCloudAlarmModel *playModel;
    [self.cloudAlarmArray enumerateObjectsUsingBlock:^(SDCloudAlarmModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
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
    
    //开启解码
    [self.gdVideoPlayer.decoder startAcDecode];
    
    //停止拖动，去获取预览图
    [self setApiNetDelegate];
    [self getPlayPreviewWithValue:rulerScrollView.rulerValue];
    if ([self isSameDay:self.currentSelectDate date2:self.currentTimeDate]) {
        //如果是同一天就要判断是不是时间秒数大于当前秒数
        //        long long nowValue =[self.currentTimeDate timeIntervalSince1970] - [self.currentSelectDate timeIntervalSince1970];
        //        if (nowValue <= rulerScrollView.rulerValue + 5) {
        //            //说明滑动超过了当前时间 要弹回来
        //            //开始操作
        //            NSLog(@"test123456--------------nowValue-%lld-rulerValue%f",nowValue,rulerScrollView.rulerValue);
        //        }
    }
}

#pragma mark - 工具方法
- (void)getPlayPreviewWithValue:(NSInteger)selectValue{
    self.cloudLoadVideoActivity.hidden = NO;
    self.playButton.hidden = YES;
    
    //SD卡播放，去抓截图
    //遍历寻找播放模型
    __block SDCloudAlarmModel *playModel;
    __weak typeof(self) weakSelf = self;
    
    [self.cloudAlarmArray enumerateObjectsUsingBlock:^(SDCloudAlarmModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.accuracylastStamp > selectValue && obj.accuracyfirstStamp <= selectValue) {
            playModel = obj;
            *stop = YES;
        }
    }];
    
    //查询报警数组
    [self.cloudAlarmArray enumerateObjectsUsingBlock:^(SDCloudVideoModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.accuracylastStamp > selectValue && obj.accuracyfirstStamp <= selectValue) {
            playModel = obj;
            *stop = YES;
        }
    }];
    if (playModel) {
        //存在录制视频
        weakSelf.previewView.hidden = NO;
        [weakSelf.previewView setBackgroundImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
        weakSelf.previewTimeLabel.text = [self getNOSpaceTimeTextWithValue:selectValue];
        self.sdPlayModel = playModel;
        
        //先删除
        [self.gdVideoPlayer.decoder sendSDCardCommandWithType:SDCommandTypePic destinaFileName:[self getSDPreViewPhotoPathWithPlayModel:self.sdPlayModel] callBack:nil];
        self.sdUnixTime = [self getUnixTimeWithTime:selectValue];
        //抓取截图去
        [NetInstanceManager sendSDCardControlWithType:0 deviceId:self.deviceId  sudId:_deviceModel.selectedSubDevInfo.SubId startTime:[self getUnixTimeWithTime:selectValue] duration:0];
    }
    else{
        //不存在录制视频
        weakSelf.previewView.hidden = YES;
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

#pragma mark - 删除TF文件命令
- (void)deleteTFFileCommandWithStartTime:(long long)startTime endTime:(long long)endTime {
    
    if (endTime < startTime || endTime == 0) return ;
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:1];
    
    [result addObject:@{@"start_time":@(startTime),@"end_time":@(endTime)}];
    
    CMD_DeleteTFFileReq *req = [[CMD_DeleteTFFileReq alloc] init];
    req.list = [result copy];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showWithStatus:DPLocalizedString(@"Login_loading")];
    });
    __weak typeof(self) weakself = self;
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:self.deviceModel.DeviceId requestData:[req requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        dispatch_async(dispatch_get_main_queue(), ^{
            result == 0?[SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Operation_Succeeded")]:[SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
            
            if (result == 0) {
                [weakself deletePushMessage];
                [weakself.targetVC refreshListActionForDelete];
                [weakself.navigationController popViewControllerAnimated:YES];
                
            }
        });
    }];
}

- (void)deletePushMessage {
    // 存在就删除推送消息
    if (_pushMsgModel) {
        [[PushMessageManagement sharedInstance] deletePushMessage:self.pushMsgModel];
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


- (NSString *)getSDPreViewPhotoPathWithPlayModel:(SDCloudVideoModel *)playModel{
    
    NSString *startStr = @"";
    if ([playModel respondsToSelector:@selector(S)]) {
        startStr = [NSString stringWithFormat:@"%lld",playModel.S];
    }
    return [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[startStr stringByAppendingString:@".jpg"]];
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



- (void)configDateArrayWithString:(NSString *)dateString{
    //"201803012102|201802260845|201802270492|201802280236|"
    if (!dateString || ![dateString isKindOfClass:[NSString class]]) {
        return;
    }
    NSArray *tempArray = [dateString componentsSeparatedByString:@"|"];
    //开始排序
    NSArray *dateArray = [tempArray sortedArrayUsingComparator:^NSComparisonResult(NSString*  _Nonnull obj1, NSString*  _Nonnull obj2) {
        return [obj1 longLongValue] < [obj2 longLongValue];
    }];
    self.dateArray = [NSMutableArray array];
    NSDate* currentDate = [NSDate dateWithTimeIntervalSinceNow:0];
    //转换为当天零点date
    currentDate = [self getZeroDateWithCurrentDate:currentDate];
    self.currentSelectDate = currentDate;
    self.ruler.rulerScrollView.selectDate = self.currentSelectDate;
    [self.dateButton setTitle:[self getDateStringWithDate:currentDate] forState:UIControlStateNormal];
    for (NSString *sortDateString in dateArray) {
        if (sortDateString.length >=8) {
            NSString *dateFormatStr = [NSString stringWithFormat:@"%@-%@-%@",[sortDateString substringWithRange:NSMakeRange(0,4)],[sortDateString substringWithRange:NSMakeRange(4,2)],[sortDateString substringWithRange:NSMakeRange(6,2)]];
            NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
            [formatter setDateFormat:@"yyyy-MM-dd"];
            NSDate *resDate = [formatter dateFromString:dateFormatStr];
            if ([resDate isKindOfClass: [NSDate class] ]) {
                [self.dateArray addObject:resDate];
            }
        }
    }
    [self.pickView reloadAllComponents];
}

- (void)getSDCardVideoDataWithLoading:(BOOL)needLoading{
    
    __weak typeof(self) weakSelf = self;
    [weakSelf startReloadDataTimer];
    if (needLoading) {
        [SVProgressHUD showWithStatus:DPLocalizedString(@"loading")];
    }
    //开始处理跳转逻辑
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
            }
            else{
                //清空,没查到数据，数据过期
                _alarmMsgTime = 0;
            }
        }
        else{
            //就是今天 不操作
        }
    }
    self.tempSDVideoArray = [NSMutableArray array];
    long long startTime=(long long)[self.currentSelectDate timeIntervalSince1970];
    long long endTime=(long long)[[self getNextDayWithDate:self.currentSelectDate] timeIntervalSince1970];
    CMD_searchSDVideoReq *videoReq = [[CMD_searchSDVideoReq alloc]init];
    videoReq.start_time = [NSString stringWithFormat:@"%lld",startTime];
    videoReq.end_time = [NSString stringWithFormat:@"%lld",endTime];
    videoReq.channel  = _channel;
    videoReq.subId = _deviceModel.selectedSubDevInfo.SubId;
    
    
    //    NSString *platformUIDCopy = [NSString stringWithString:self.platformUID ];
    //    [[NetSDK sharedInstance] net_sendLongLinkRequestWithUID:platformUIDCopy requestData:[videoReq yy_modelToJSONObject] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
    //        //        NSLog(@"---------------------video%@",dict);
    //        if (result == 0) {
    //            NSArray *dataArray = dict[@"RecordList"];
    //            if (![dataArray isKindOfClass:[NSArray class]]) {
    //                return;
    //            }
    //            //添加数据
    //            [weakSelf.tempSDVideoArray addObjectsFromArray:dataArray];
    //            if (dataArray.count == 0) {
    //                dispatch_async_on_main_queue(^{
    //                    //获取视频切片数据
    //                    [weakSelf handleSDVideoArrayData:weakSelf.tempSDVideoArray];
    //                });
    //            }
    //
    //        }else{
    //            dispatch_async_on_main_queue(^{
    //                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"SD卡数据请求失败")];
    //            });
    //        }
    //    }];
    
    //获取报警数据
    [self getSDCardAlarmData];
    
}

- (void)fetchOptimiseWithPushModel:(PushMessageModel *)pushModel startTime:(long long *)startTime endTime:(long long *)endTime {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    dateFormat.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSTimeInterval pushTime = [[dateFormat dateFromString:pushModel.pushTime] timeIntervalSince1970];
    // 起始时间十分钟
    *startTime = pushTime - (10*60);
    *endTime = pushTime + (30*60);
}

- (void)getSDCardAlarmData {
    long long startTime = 0;
    long long endTime = 0;
    
    [self fetchOptimiseWithPushModel:self.pushMsgModel startTime:&startTime endTime:&endTime];
    
    
    CMD_searchSDAlarmReq *alarmReq = [[CMD_searchSDAlarmReq alloc] init];
    alarmReq.start_time = [NSString stringWithFormat:@"%lld",startTime];
    alarmReq.end_time = [NSString stringWithFormat:@"%lld",endTime];
    alarmReq.channel  = _channel;
    alarmReq.subId = _deviceModel.selectedSubDevInfo.SubId;
    
    __weak typeof(self) weakSelf = self;
    [[NetSDK sharedInstance] net_sendLongLinkRequestWithUID:self.platformUID requestData:[alarmReq yy_modelToJSONObject] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        
        if (result == 0) {
            NSArray *dataArray = dict[@"RecordList"];
            if (![dataArray isKindOfClass:[NSArray class]]) {
                return;
            }
            
            if (dataArray > 0) {
                for (int i = 0; i < dataArray.count; i++) {
                    NSDictionary *dict = dataArray[i];
                    //转换模型数组
                    SDCloudAlarmModel *alarmModel = [SDCloudAlarmModel yy_modelWithDictionary:dict];
                    // 推送时间可能比录像的早，也可能比录像的早，那么就找与录像时间最接近的
                    if (weakSelf.pushTime >= alarmModel.S && weakSelf.pushTime <= alarmModel.E) {
                        // 推送时间在区间内，认定就是你了
                        weakSelf.startTime = alarmModel.S;
                        weakSelf.endTime = alarmModel.E;
                        break;
                    } else if (weakSelf.pushTime > alarmModel.S) {
                        
                        if (i == [dataArray count]-1) {
                            // 这已经是最后一个，没办法就是你了
                            weakSelf.startTime = alarmModel.S;
                            weakSelf.endTime = alarmModel.E;
                            break;
                        } else {
                            continue;
                        }
                    } else if (self.pushTime < alarmModel.S) {
                        
                        if (i == 0) {
                            // 这是第一个，没办法也就是你了
                            weakSelf.startTime = alarmModel.S;
                            weakSelf.endTime = alarmModel.E;
                            break;
                        } else {
                            // 比较与之前的那个更接近推送时间
                            NSDictionary *previousDict = dataArray[i-1];
                            SDCloudAlarmModel *previousModel = [SDCloudAlarmModel yy_modelWithDictionary:previousDict];
                            
                            NSTimeInterval previousDiff = ABS(previousModel.S - weakSelf.pushTime);
                            NSTimeInterval curDiff = ABS(alarmModel.S - weakSelf.pushTime);
                            
                            if (previousDiff > curDiff) {
                                weakSelf.startTime = alarmModel.S;
                                weakSelf.endTime = alarmModel.E;
                            } else if (previousDiff < curDiff) {
                                weakSelf.startTime = previousModel.S;
                                weakSelf.endTime = previousModel.E;
                            } else {
                                weakSelf.startTime = alarmModel.S;
                                weakSelf.endTime = alarmModel.E;
                            }
                            break;
                        }
                    }
                }
                
                if (weakSelf.startTime != 0 && weakSelf.endTime != 0) {
                    NSLog(@"daniel: 获取录像点：%lld - %lld", weakSelf.startTime, weakSelf.endTime);
                    weakSelf.saveFileName =  [weakSelf getFileName:[weakSelf getStartTime:weakSelf.startTime] currentTime:weakSelf.pushTime];;
                    [weakSelf audioStart];
//                    [weakSelf startStreamTimer];
                    [NetInstanceManager sendSDCardControlWithType:1 deviceId:weakSelf.deviceId sudId:_deviceModel.selectedSubDevInfo.SubId startTime:(int)weakSelf.startTime duration:0];
                    //开启解码
                    [weakSelf.gdVideoPlayer.decoder startAcDecode];
                }
//                dispatch_async_on_main_queue(^{
//                    [SVProgressHUD dismiss];
//                    //获取视频切片数据
//                    [weakSelf handleSDAlarmArrayData:weakSelf.tempSDAlarmArray];
//                });
            }
        }else{
            dispatch_async_on_main_queue(^{
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"data_unsuceess")];//SD卡数据请求失败
            });
        }
    }];
}


//处理SD卡视频数据数组
- (void)handleSDVideoArrayData:(NSArray *)dataArray{
    //    [self.cloudVideoArray removeAllObjects];
    //    if (dataArray.count > 0) {
    //        for (NSDictionary *dict in dataArray) {
    //            //转换模型数组
    //            SDCloudVideoModel *videoModel = [SDCloudVideoModel yy_modelWithDictionary:dict];
    //            [self.cloudVideoArray addObject:videoModel];
    //        }
    //    }
    //    if (self.cloudVideoArray.count > 0) {
    //    }
    //    //进行疯狂计算--转换为今天的秒数
    //    for (SDCloudVideoModel *videoModel in self.cloudVideoArray) {
    //        long long accuracyfirstStamp = videoModel.S - [self.currentSelectDate timeIntervalSince1970];
    //        long long accuracylastStamp = videoModel.E - [self.currentSelectDate timeIntervalSince1970];
    //        videoModel.accuracyfirstStamp = accuracyfirstStamp;
    //        videoModel.accuracylastStamp = accuracylastStamp;
    //    }
    //    //时间赶，先这样写吧 --赋值数组
    //    self.ruler.rulerScrollView.selectDate = self.currentSelectDate;
    //    self.ruler.rulerScrollView.SDVideoArray = self.cloudVideoArray;
}

//处理SD卡报警数据数组
- (void)handleSDAlarmArrayData:(NSArray *)dataArray{
    [self.cloudAlarmArray removeAllObjects];
    if (dataArray.count > 0) {
        for (NSDictionary *dict in dataArray) {
            //转换模型数组
            SDCloudAlarmModel *alarmModel = [SDCloudAlarmModel yy_modelWithDictionary:dict];
            [self.cloudAlarmArray addObject:alarmModel];
        }
    }
    
    
    NSTimeInterval selectValue = _alarmMsgTime - [self.currentSelectDate timeIntervalSince1970];
    BOOL find = NO;
    //进行疯狂计算--转换为今天的秒数
    for (SDCloudAlarmModel *alarmModel in self.cloudAlarmArray) {
        long long accuracyfirstStamp = alarmModel.S - [self.currentSelectDate timeIntervalSince1970];
        long long accuracylastStamp = alarmModel.E - [self.currentSelectDate timeIntervalSince1970];
        alarmModel.accuracyfirstStamp = accuracyfirstStamp;
        alarmModel.accuracylastStamp = accuracylastStamp;
        
        if (((accuracylastStamp >= selectValue && accuracyfirstStamp <= selectValue) || accuracyfirstStamp > selectValue) && !find) {
            self.sdUnixTime = (int)alarmModel.S;
            find = YES;
        }
        
    }
    //赋值数组
    self.ruler.rulerScrollView.selectDate = self.currentSelectDate;
    self.ruler.rulerScrollView.SDMoveDetectArray = self.cloudAlarmArray;
    
    //开始播放数据
    if (_alarmMsgTime >0) {
        if (!find) {
            self.sdUnixTime = _alarmMsgTime;
        }
        dispatch_async_on_main_queue(^{
            [self playBtnClick];
            int timeValue = _alarmMsgTime - [self.currentSelectDate timeIntervalSince1970];
            if (timeValue >0) {
                [self.ruler.rulerScrollView playViewTimeIntervalDrawCurrentIndicatorWithValue:timeValue withScroll:YES];
            }
        });
        _alarmMsgTime = 0;
    }
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

//选中的当天时间转换unix时间
- (int)getUnixTimeWithTime:(int)selectTime{
    long long time = [self.currentSelectDate timeIntervalSince1970] + selectTime;
    return time;
}




#pragma mark - Event Handle
- (void)tapClick:(UIGestureRecognizer *)gesture{
    if (_isLandSpace) {
        [self showCloudPlay];
    }
}

//云存储播放按钮点击时间
- (void)playBtnClick{
    _isPlaying = YES;
    self.isChangeDateManual = NO;
    //停止当前解码缓存
    [self.gdVideoPlayer.decoder stopAcDecode];
    //    //开始加载
    //    self.loadVideoActivity.hidden = NO;
    
    //开始播放指定时间
    self.previewView.hidden = YES;
    self.previewView.userInteractionEnabled = NO;
    [self openSDPlay];
    //    停止请求SD卡数据
    //    [NetInstanceManager sendStopSDCardCammand:self.deviceId];
    //    if (![NetInstanceManager isStreamOpenedWithUID:self.deviceId]) {
    //        //先连接一次
    //        [self getLiveStreamData];
    //    }
    //    else{
    //
    //    }
    //    [self startStreamTimer];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delaySetReadyPlayStatus) object:nil];
    _isReadyPlay = NO;
    [self.gdVideoPlayer.decoder sendSDCardCommandWithType:SDCommandTypeLive destinaFileName:nil callBack:nil];
    self.sdCurrentPlayTime = self.sdUnixTime;
    int timeX = self.sdUnixTime;
    if (timeX >1000) {
        //切换到对应播放
        [NetInstanceManager sendSDCardControlWithType:1 deviceId:self.deviceId sudId:_deviceModel.selectedSubDevInfo.SubId startTime:self.sdUnixTime duration:0];
        //设置录像流畅播放
        [self.gdVideoPlayer.decoder ac_setBufferSize:100 nType:1];
        //开启解码
        [self.gdVideoPlayer.decoder startAcDecode];
        [self audioStart];
    }
    
    //放到最大
    [self.ruler.rulerScrollView zoomToMAX];
}


- (void)openSDPlay{
    //允许自动滚动
    self.ruler.rulerScrollView.canScroll = YES;
    if (!_isLandSpace) {
//        self.cloudBottomView.hidden = NO;
    }
    self.cloudSoundBtn.selected = NO;
}


- (void)cloudSnapshotBtnAction:(UIButton *)btn{
    [self snapshotBtnAction:nil];
}

#pragma mark -- '拍照‘按钮事件
- (void)snapshotBtnAction:(id)sender
{
    NSLog(@"'拍照’事件");
    
    if (!_isPlaying) {
        return;
    }
    
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


#pragma mark -- 播放‘拍照’音效
- (void)playSnapShotSound
{
    if (self.snapShotBtnAudioPlayer)
    {
        [self.snapShotBtnAudioPlayer prepareToPlay];
        [self.snapShotBtnAudioPlayer play];
    }
}


- (void)shortCutAction:(UIButton *)btn{
    if (!_isPlaying) {
        return;
    }
    CloudShortCutViewController *shortCutVC = [[CloudShortCutViewController alloc]init];
    shortCutVC.deviceId = self.deviceModel.DeviceId;
    shortCutVC.cloudPlayVC = self;
    shortCutVC.currentSelectDate = self.currentSelectDate;
    
    //遍历模型获取
    SDCloudAlarmModel *searchVideoModel;
    for (SDCloudAlarmModel *videoModel in self.cloudAlarmArray) {
        //找到对应时间段
        if (videoModel.S <= _sdCurrentPlayTime && videoModel.E >= _sdCurrentPlayTime) {
            searchVideoModel = videoModel;
            break;
        }
    }
    NSInteger totalSecs = !searchVideoModel?10:(searchVideoModel.E - _sdCurrentPlayTime);
    
    shortCutVC.mins = 0;
    shortCutVC.seconds = totalSecs > 30 ? 30:totalSecs;
    int startTime = self.sdCurrentPlayTime - [self.currentSelectDate timeIntervalSince1970];
    if (startTime < 0) {
        return;
    }
    shortCutVC.currentShortCutTime = startTime;
    [self.navigationController pushViewController:shortCutVC animated:YES];
}

- (void)cloudSoundBtnAction:(UIButton *)btn{
    btn.selected = !btn.selected;
    if (btn.selected) {
        //暂停声音
        [self audioStop];
    }
    else{
        //打开声音
        [self audioStart];
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
    [self getSDCardVideoDataWithLoading:YES];
}

#pragma mark - 播放相关
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


#pragma mark -- '重新加载‘按钮事件
- (void)reloadBtnClick{
    _reloadBtn.hidden = YES;
    self.loadVideoActivity.hidden = NO;
    [self.loadVideoActivity startAnimating];
    self.offlineBtn.hidden = YES;
    dispatch_async(dispatch_queue_create("ReconnectQueue", DISPATCH_QUEUE_SERIAL), ^{
        [NetInstanceManager reconnect:self.deviceId andBlock:^(int result, int state, int cmd) {
            if (result != 0) {
            }
        }];
    });
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


#pragma mark - 获取实时流
-(void)getLiveStreamData
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        //在播放云存储
        //设置历时流流畅播放
        [self.gdVideoPlayer.decoder ac_setBufferSize:100 nType:1];
        //在播放SD卡 先打开流
        //开始拉流计时
        
        __weak typeof(self) weakSelf = self;
        [NetInstanceManager startGettingVideoDataWithUID:self.deviceId videoType:4 resultBlock:^(int result, int state) {
            if (result == 0) {
                NSLog(@"播放SD卡打开流成功");
                //打开流之后，发送播放指定时间指令
                //切换到对应时间播放
                if (self.pushMsgModel && self.endTime == 0) {
                    [self getSDCardAlarmData];
                } else if (self.startTime > 1000) {
                    NSLog(@"daniel: %lld trans:%d", _startTime, (int)_startTime);
                    [weakSelf audioStart];
//                    [weakSelf startStreamTimer];
                    [NetInstanceManager sendSDCardControlWithType:1 deviceId:weakSelf.deviceId sudId:_deviceModel.selectedSubDevInfo.SubId startTime:(int)self.startTime duration:0];
                    //开启解码
                    [weakSelf.gdVideoPlayer.decoder startAcDecode];
                }
            }
            else{
                NSLog(@"播放SD卡打开流失败");
            }
            
        }];
    });
}

- (void)setStartTime:(long long)startTime {
    NSLog(@"daniel: start before:%lld will:%lld", _startTime, startTime);
    _startTime = startTime;
    NSLog(@"daniel: end after:%lld", _startTime);
}

/**
 超过五秒拉不了流，就开始重新拉流
 */
- (void)reloadStream{
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
        int repeatTimes = 10;
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
    [self.gdVideoPlayer startVoice];
    _isAudioOn = YES;
    dispatch_async_on_main_queue(^{
        NSLog(@"----------------开启音频--------------------");
        [self.cloudSoundBtn setImage:[UIImage imageNamed:@"PlaySoundNormal"] forState:UIControlStateNormal];
        [self.cloudSoundBtn setImage:[UIImage imageNamed:@"PlaySoundSelected"] forState:UIControlStateHighlighted];
        self.cloudSoundBtn.selected = NO;
    });
    
    return YES;
}

/**
 停止播放音频
 */
-(BOOL)audioStop
{
    _isAudioOn = NO;
    [self.gdVideoPlayer stopVoice];
    dispatch_async_on_main_queue(^{
        NSLog(@"----------------关闭音频--------------------");
        [self.cloudSoundBtn setImage:[UIImage imageNamed:@"PlayNoSoundNormal"] forState:UIControlStateNormal];
        [self.cloudSoundBtn setImage:[UIImage imageNamed:@"PlayNoSoundSelected"] forState:UIControlStateHighlighted];
        self.cloudSoundBtn.selected = YES;
    });
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
        //重新连接
        [NetInstanceManager reconnect:self.deviceId andBlock:^(int result, int state, int cmd) {
            
        }];
    }
}

-(void)enterBackground
{
    //停止播放音频
    [self releaseBtnSoundAudioPlayer];
    //停止音频播放
    if (_isAudioOn) {
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
{   _isLoadStreamOnceTime = NO;
    if (self.deviceModel.Status != 1) {
        //设备不在线
        [self.loadVideoActivity stopAnimating];
        self.loadVideoActivity.hidden = YES;
        [self showNewStatusInfo:DPLocalizedString(@"Play_Ipc_unonline")];
        self.reloadBtn.hidden = YES;
        self.offlineBtn.hidden = NO;
        self.playView.layer.contents = [UIImage imageNamed:@""];
        _isRunning = NO;
        return;
    }
    
    //开启云存储播放
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
    
    [apiSet setStreamChannel: _deviceModel.selectedSubDevInfo.ChanNum];
}


#pragma mark -- 移除全局NetAPI代理
- (void)RemoveApiNetDelegate
{
    NetAPISet *apiSet = [NetAPISet sharedInstance];
    apiSet.sourceDelegage = nil;
    
    [apiSet setStreamChannel: 0];
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
    _platformUID= deviceModel.DeviceId;
    
    _channel = deviceModel.selectedSubDevInfo.ChanNum;
    
    _deviceName = deviceModel.selectedSubDevInfo.ChanName.length>0 ? deviceModel.selectedSubDevInfo.ChanName:  deviceModel.DeviceName;
    
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


#pragma mark - 云存储 getter

//没有视频数据提示label
- (UILabel *)noVideoDataLabel{
    if (!_noVideoDataLabel) {
        _noVideoDataLabel = [[UILabel alloc]init];
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

//- (NSMutableArray *)cloudVideoArray{
//    if (!_cloudVideoArray) {
//        _cloudVideoArray = [NSMutableArray array];
//    }
//    return _cloudVideoArray;
//}


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
        _cloudBottomView.hidden = YES;
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


- (UIActivityIndicatorView *)cloudLoadVideoActivity{
    if (!_cloudLoadVideoActivity) {
        _cloudLoadVideoActivity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _cloudLoadVideoActivity.frame = CGRectMake(35, 20, 50, 50);
        [_cloudLoadVideoActivity startAnimating];
        _cloudLoadVideoActivity.hidden = YES;
    }
    return _cloudLoadVideoActivity;
}

- (UIButton *)netErrorButton{
    if (!_netErrorButton) {
        _netErrorButton = [[UIButton alloc]initWithFrame:CGRectMake((SCREEN_WIDTH - 120)/2, HeightForStatusBarAndNaviBar+SCREEN_WIDTH * playViewRatio + 120, 120, 30)];
        _netErrorButton.backgroundColor = [UIColor whiteColor];
        _netErrorButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
        [_netErrorButton setTitle:DPLocalizedString(@"reloadBtn") forState:UIControlStateNormal];
        [_netErrorButton setBackgroundImage:[UIImage imageNamed:@"CloudDateBtnBG"] forState:UIControlStateNormal];
        [_netErrorButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_netErrorButton addTarget:self action:@selector(getSDCardVideoTimeFirst) forControlEvents:UIControlEventTouchUpInside];
        _netErrorButton.hidden = YES;
    }
    return _netErrorButton;
}

#pragma mark - ZZ
- (void)saveRecordBtnDidClick {
    BOOL isConnected = [NetInstanceManager isDeviceConnectedWithUID:self.deviceId];
    if (!isConnected) {
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Play_camera_no_connect")];
        return;
    }
    
    isSaveRecord = YES;
    [SVProgressHUD showWithStatus:DPLocalizedString(@"loading")];
    int duration = (int)(self.endTime - self.startTime);
    [self convertMP4WithStartValue:self.startTime totalValue:duration > 30 ? 30 : duration fileName:self.saveFileName];
}

- (void)deleteRecordBtnDidClick {
    
    [self deleteTFFileCommandWithStartTime:self.startTime endTime:self.endTime];
}

- (void)setSaveFileName:(NSString *)saveFileName {
    if ([saveFileName containsString:@":"]) {
        _saveFileName = [saveFileName stringByReplacingOccurrencesOfString:@":" withString:@"-"];
    } else {
        _saveFileName = saveFileName;
    }
}
@end

