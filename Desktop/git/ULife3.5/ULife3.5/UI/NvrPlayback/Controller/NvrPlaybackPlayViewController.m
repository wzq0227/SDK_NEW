//
//  NvrPlaybackPlayViewController.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/21.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "NvrPlaybackPlayViewController.h"
#import "NvrPlaybackCtrlView.h"
#import "NvrPBPlayView.h"
#import "GDVideoPlayer.h"
#import "NetAPISet.h"
#import <Masonry.h>
#import "MediaManager.h"
#import <AVFoundation/AVFoundation.h>

#define CTRL_VIEW_HEIGHT 75.0f

#define NAV_BAR_HEIGHT 64.0f

@interface NvrPlaybackPlayViewController () <
                                                NvrPlaybackCtrlViewDelegate,
                                                GDVideoPlayerDelegate,
                                                GDNetworkSourceDelegate,
                                                GDNetworkStateDelegate,
                                                NvrPBPlayViewDelegate
                                            >
{
    /** 保存屏幕宽度 */
    CGFloat _screenWidth;
    
    /** 保存屏幕高度 */
    CGFloat _screenHeight;
    
    /** 竖屏时 nvr 回放 view 大小 */
    CGSize _portraintPlayViewSize;
    
    /** 横屏时 nvr 回放 view 大小 */
    CGSize _landscapePlayViewSize;
    
    /** NVR 录像回放 AV 通道 */
    long _pbAvChannel;
    
    /** 文件总时长：毫秒 */
    uint32_t _fileTotalTime;
    
    /** 是否进入后台 */
    BOOL _isEnterBackground;

    /** 是否拖拽 Slider */
    BOOL _isDragingSlider;
    
    /** 是否有拖拽的操作（过滤点击）*/
    BOOL _hasDragingSlider;
    
    /** 是否开始播放 */
    BOOL _isStartPlay;
    
    /** 是否发送了文件名 */
    BOOL _isSendFilePath;
    
    /**  是否正在播放 */
    BOOL _isPlaying;
    
    /** 是否播放结束 */
    BOOL _isPlayFinish;
    /** 是否暂停 */
    BOOL _isPause;
    
    /** 拖拽 Slider 播放时间点 */
    NSString *_seekTime;
    
    /** 拖拽结束点相对起始点的时间(单位：毫秒) */
    uint32_t _endDragTime;
}

/** 播放 View*/
@property (nonatomic, strong) NvrPBPlayView *playView;

/** 当前播放时间 Label */
@property (nonatomic, strong) UILabel *currentTimeLabel;

/** 播放进度条 Slider */
@property (nonatomic, strong) UISlider *slider;

/** 播放控制 View*/
@property (nonatomic, strong) NvrPlaybackCtrlView *ctrlView;

/** 录像回放文件 Model */
@property (nonatomic, strong) NvrPlaybackListModel *pbListModel;

/** NVR 回放播放器 */
@property (nonatomic, strong) GDVideoPlayer *pbVideoPlayer;

/** 拍照按钮点击声音 播放器 */
@property (nonatomic, strong) AVAudioPlayer *snapshotAudioPlayer;

@end

@implementation NvrPlaybackPlayViewController


- (instancetype)initWithModel:(NvrPlaybackListModel *)listModel
                    tutkDevId:(NSString *)tutkDevId
{
    if (self = [super init])
    {
        self.pbListModel          = listModel;
        self.pbListModel.deviceId = tutkDevId;
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithRed:131.0f/255.0f
                                                green:130.0f/255.0f
                                                 blue:128.0f/255.0f
                                                alpha:1.0f];
    self.navigationItem.title = DPLocalizedString(@"VR360_playback");
    
    [self initParam];
    
    [self addCustomViews];
    
    [self configSliderStyle];
    
    [self saveNvrShowViewFrame];
    
    [self addBackgroundRunningEvent];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.ctrlView updatePlayButtonWithStyle:PlayOrPauseBtnNoUse];
    [self.ctrlView updateSnapshotBtn:_isPlaying];
    
    [self startActivity];
    
    [self setApiNetDelegate];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self createNvrPBPlayer];
    
    if (NO == _isSendFilePath)
    {
        [self startPBPlay];
    }
    else
    {
        [self startGetNvrVideoData];
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self stopGetNvrVideoData];
    
    [self releaseNvrPBPlayer];
    
    [self removeApiNetDelegate];
    
    [self stopActivity];
    
//    dispatch_semaphore_wait(self.semaphore, dispatch_time(DISPATCH_TIME_NOW, 5 *NSEC_PER_SEC));
//    
//    dispatch_semaphore_signal(self.semaphore);
    
    [SVProgressHUD dismiss];
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc
{
    NSLog(@"----------- NvrPlaybackPlayViewController dealloc -----------");
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"DidRespEndUpPlayNvrPB"
                                                  object:nil];
}


#pragma mark - 保存设置相关
#pragma mark -- 初始化参数
- (void)initParam
{
    _screenWidth        = SCREEN_WIDTH;
    _screenHeight       = SCREEN_HEIGHT;
    if (_screenWidth > _screenHeight)
    {
        _screenWidth    = SCREEN_HEIGHT;
        _screenHeight   = SCREEN_WIDTH;
    }
    _isPlaying          = NO;
    _isPlayFinish       = NO;
    _isStartPlay        = NO;
    _isDragingSlider    = NO;
    _hasDragingSlider   = NO;
    _isSendFilePath     = NO;
    _isPause            = NO;
    _pbAvChannel        = self.devDataModel.avChnnelNum - 1;;
    _endDragTime        = 0;
    _isEnterBackground  = NO;
    _fileTotalTime      = [self getFileTimeWithVideoModel:self.pbListModel];
}


#pragma mark -- 添加子 View
- (void)addCustomViews
{
    self.playView = [[NvrPBPlayView alloc] initWithFrame:CGRectMake(0,
                                                                    NAV_BAR_HEIGHT,
                                                                    _screenWidth,
                                                                    _screenWidth * PLAY_VIEW_SCALE)];
    self.playView.delegate = self;
    self.currentTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(30.0f,
                                                                     _screenWidth * PLAY_VIEW_SCALE + NAV_BAR_HEIGHT + 30.0f,
                                                                     _screenWidth - 60.0f,
                                                                      20.0f)];
    self.currentTimeLabel.textAlignment = NSTextAlignmentRight;
    self.currentTimeLabel.textColor = [UIColor whiteColor];
    self.currentTimeLabel.text = @"00:00:00";
    self.slider = [[UISlider alloc] initWithFrame:CGRectMake(30.0f,
                                                            _screenWidth * PLAY_VIEW_SCALE + NAV_BAR_HEIGHT + 60.0f,
                                                            _screenWidth - 60.0f,
                                                             40.0f)];
    [self.slider addTarget:self
                    action:@selector(onSliderValChanged:forEvent:)
          forControlEvents:UIControlEventValueChanged];
    self.ctrlView = [[NvrPlaybackCtrlView alloc] initWithFrame:CGRectMake(0,
                                                                          _screenHeight - CTRL_VIEW_HEIGHT,
                                                                          _screenWidth,
                                                                          CTRL_VIEW_HEIGHT)];
    self.ctrlView.delegate = self;
    
    
    [self.view addSubview:self.playView];
    [self.view addSubview:self.currentTimeLabel];
    [self.view addSubview:self.slider];
    [self.view addSubview:self.ctrlView];
    
    [self.ctrlView showFileName:[self getFileNameWithVideoModel:self.pbListModel]];
}


#pragma mark -- 设置 Slider 样式
- (void)configSliderStyle
{
    UIImage *image = [self imageFromColor:[UIColor whiteColor]
                                     rect:CGRectMake(0, 0, 20, 20)];
    [self.slider setThumbImage:[self circleImage:image
                                       withParam:0.0f]
                      forState:UIControlStateNormal];
    self.slider.minimumTrackTintColor = UIColorFromRGB(0x1fbcd2);
    self.slider.maximumTrackTintColor = [UIColor whiteColor];
}


#pragma mark -- 生成纯颜色 Image
- (UIImage *)imageFromColor:(UIColor *)color rect:(CGRect)rect
{
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


#pragma mark -- 给指定 Image 裁圆
-(UIImage*) circleImage:(UIImage*) image withParam:(CGFloat) inset
{
    UIGraphicsBeginImageContext(image.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 2);
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGRect rect = CGRectMake(inset, inset, image.size.width - inset * 2.0f, image.size.height - inset * 2.0f);
    CGContextAddEllipseInRect(context, rect);
    CGContextClip(context);
    
    [image drawInRect:rect];
    CGContextAddEllipseInRect(context, rect);
    CGContextStrokePath(context);
    UIImage *newimg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newimg;
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
    [self.playView startActivityAnimation];
}


#pragma mark -- 停止 Activity 动画
- (void)stopActivity
{
    [self.playView stopActivityAnimation];
}


#pragma mark -- 重新加载数据
- (void)reloadData
{
    [self.playView configReloadBtnHidden:YES];
    [self startActivity];
    if (NO == _isSendFilePath)
    {
        [self startPBPlay];
    }
    else
    {
        [self startGetNvrVideoData];
    }
}


#pragma mark -- 设置文件名显示
- (NSString *)getFileNameWithVideoModel:(NvrPlaybackListModel *)videoListModel
{
    if (!videoListModel
        || IS_STRING_EMPTY(videoListModel.startTime)
        || IS_STRING_EMPTY(videoListModel.endTime))
    {
        NSLog(@"无法显示文件名，startTime = %@, endTime = %@", videoListModel.startTime, videoListModel.endTime);
        
        return nil;
    }
    NSString *startTime = [videoListModel.startTime substringFromIndex:11];
    NSString *endTime = [videoListModel.endTime substringFromIndex:11];
    NSString *fileName = [NSString stringWithFormat:@"%@-%@", startTime, endTime];
    
    return fileName;
}


#pragma mark -- 根据时间戳（毫秒）更新进度条
- (void)updateSliderValueWithTiimestamp:(unsigned int)timestamp
{
    if (0 == timestamp)
    {
        return;
    }
    
    CGFloat progress = (CGFloat)((CGFloat)timestamp / (CGFloat)_fileTotalTime);
    //    NSLog(@"录像文件总时长：%d", _fileTotalTime);
    //    NSLog(@"录像文件播放进度：%f", progress);
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (!weakSelf)
        {
            return ;
        }
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (NO == strongSelf->_isDragingSlider)
        {
            [strongSelf.slider setValue:progress animated:YES];
        }
    });
    [self updateCurrentTimeValueWithTiimestamp:timestamp];
}


#pragma mark -- 根据时间戳(毫秒)更新播放时间
- (void)updateCurrentTimeValueWithTiimestamp:(unsigned int)timestamp
{
    NSString *currentTimeStr = [self getTimeStrWithTimeStamp:timestamp];
    //    NSLog(@"当前播放时间：%@", currentTimeStr);
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (!weakSelf)
        {
            return ;
        }
        __strong typeof(weakSelf)strongSelf = weakSelf;
        strongSelf.currentTimeLabel.text = currentTimeStr;
    });
}


#pragma mark -- 获取文件总时长：毫秒
- (NSTimeInterval)getFileTimeWithVideoModel:(NvrPlaybackListModel *)videoListModel
{
    if (!videoListModel)
    {
        NSLog(@"无法获取文件总时长，videoListModel = %@", videoListModel);
        
        return 0;
    }
    
    return videoListModel.length;
}


#pragma mark -- 计算时间差：秒
- (NSTimeInterval)timeIntervarlWithStartTime:(NSString *)startTime
                                     endTime:(NSString *)endTime
{
    // 2017-03-21 11:03:37
    if (IS_STRING_EMPTY(startTime)
        || IS_STRING_EMPTY(endTime)
        || 19 > startTime.length || 19 > endTime.length)
    {
        NSLog(@"无法计算时间差，startTime = %@, endTime = %@", startTime, endTime);
        
        return 0;
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *dateStart = [dateFormatter dateFromString:startTime];
    NSDate *dateEnd   = [dateFormatter dateFromString:endTime];
    
    return [dateEnd timeIntervalSinceDate:dateStart];
}


#pragma mark -- 根据拖拽的 progress 计算播放时间点
- (NSString *)getSeeTimeStrWithProgress:(CGFloat)progress
{
    uint32_t seekTimeMS = _fileTotalTime * progress;
    
    NSString *fileStartTime   = self.pbListModel.startTime;    // yyyy-MM-dd HH:mm:ss
    NSString *fileStartDate   = [fileStartTime substringWithRange:NSMakeRange(0, 10)];
    NSString *fileStartHour   = [fileStartTime substringWithRange:NSMakeRange(11, 2)];
    NSString *fileStartMinute = [fileStartTime substringWithRange:NSMakeRange(14, 2)];
    NSString *fileStartSecond = [fileStartTime substringWithRange:NSMakeRange(17, 2)];
    
    int startHour   = [fileStartHour intValue];
    int startMinute = [fileStartMinute intValue];
    int startSecond = [fileStartSecond intValue];
    
    uint32_t fileStartTimeMS = startHour * 3600 * 1000 + startMinute * 60 * 1000 + startSecond * 1000;
    uint32_t fileSeekStartTimeMS = fileStartTimeMS + seekTimeMS;
    
    NSString *seekTimeStr = [self getTimeStrWithTimeStamp:fileSeekStartTimeMS];
    
    NSString *seekDateStr = [NSString stringWithFormat:@"%@ %@", fileStartDate, seekTimeStr];
    
    return seekDateStr;
}


#pragma mark -- 根据时间戳（毫秒）转换成时间串（HH:mm:ss）
- (NSString *)getTimeStrWithTimeStamp:(uint32_t)timeStamp
{
    if (0 == timeStamp)
    {
        return @"00:00:00";
    }
    // 01:12:25 = 4345
    uint32_t hour = timeStamp / (3600 * 1000);
    uint32_t minute = (timeStamp - hour * (3600 * 1000)) / (60 * 1000);
    uint32_t second = (timeStamp - hour * (3600 * 1000) - minute * (60 * 1000)) / 1000;
    NSString *hourStr = [NSString stringWithFormat:@"%d", hour];
    NSString *minuteStr = [NSString stringWithFormat:@"%d", minute];
    NSString *secondStr = [NSString stringWithFormat:@"%d", second];
    
    if (9 >= hour)
    {
        hourStr = [NSString stringWithFormat:@"0%d", hour];
    }
    if (9 >= minute)
    {
        minuteStr = [NSString stringWithFormat:@"0%d", minute];
    }
    if (9 >= second)
    {
        secondStr = [NSString stringWithFormat:@"0%d", second];
    }
    NSString *timeStr = [NSString stringWithFormat:@"%@:%@:%@", hourStr, minuteStr, secondStr];
    
    return timeStr;
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
    
    [self releaseNvrPBPlayer];
    if (YES == _isPlaying)
    {
        [self recordFilePlayWithType:kNETPRO_RECSTREAM_PAUSE
                          seekSecond:0];
    }
    _isEnterBackground = YES;
}


#pragma mark -- 进入 Forground 监控通知
- (void)willEnterForeground
{
    [self createNvrPBPlayer];
    
    if (YES == _isPlaying)
    {
        [self recordFilePlayWithType:kNETPRO_RECSTREAM_RESUME
                          seekSecond:0];
    }
    _isEnterBackground = NO;
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


#pragma mark -- 播放‘拍照’音效
- (void)playSnapShotSound
{
    if (self.snapshotAudioPlayer)
    {
        [self.snapshotAudioPlayer prepareToPlay];
        [self.snapshotAudioPlayer play];
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
}


#pragma mark -- 拍照
- (void)startSnapshot
{
    NSString *snapshotPath = [[MediaManager shareManager] mediaPathWithDevId:self.pbListModel.deviceId
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
        [strongSelf.pbVideoPlayer screenshot:YES
                                     andPath:snapshotPath
                              andBlockRequst:^(int result,
                                               NSError *error) {
                                  
                              }];
    });
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
- (void)createNvrPBPlayer
{
    if (!self.pbListModel.deviceId)
    {
        NSLog(@"无法创建 NVR 回放 播放器，nvrDeviceId = %@", self.pbListModel.deviceId);
        
        return ;
    }
    if (self.playView)
    {
        self.pbVideoPlayer = [[GDVideoPlayer alloc] init];
        [self.pbVideoPlayer initWithViewAndDelegate:self.playView
                                           Delegate:self
                                        andDeviceID:self.pbListModel.deviceId
                                 andWithdoubleScale:NO
                                    nvrPositionType:PositionTopLeft];
        NSString *covertPath = [[MediaManager shareManager] mediaPathWithDevId:self.pbListModel.deviceId
                                                                      fileName:nil
                                                                     mediaType:GosMediaCover
                                                                    deviceType:GosDeviceNVR
                                                                      position:5];
        self.pbVideoPlayer.coverPath = covertPath;
        NSLog(@"创建：回放 VideoPlayer ");
    }
}


#pragma mark -- 释放播发器
- (void)releaseNvrPBPlayer
{
    if (self.pbVideoPlayer)
    {
        [self.pbVideoPlayer stopPlay];
        self.pbVideoPlayer.delegate = nil;
        self.pbVideoPlayer = nil;
    }
}


#pragma mark - 视频流
#pragma mark -- 开始回放
- (void)startPBPlay
{
    NSLog(@"--- NvrPlaybackPlayViewController --- 准备发送录像文件名！");
    __weak typeof(self)weakSelf = self;
    [[NetAPISet sharedInstance] nvrPBPlayWithDevId:self.pbListModel.deviceId
                                          filePath:self.pbListModel.fileName
                                     playCtrlBlock:^(BOOL isSuccess,
                                                     NVRRecordFilePlayType nvrRecordFilePlayType,
                                                     int avIndex) {
                                         
                                         if (NVRRecordFilePlayStop == nvrRecordFilePlayType)
                                         {
                                             NSLog(@"--- NvrPlaybackPlayViewController -- 发送 -- EndUpPlayNvrPBCallBack 通知");
                                             [[NSNotificationCenter defaultCenter] postNotificationName:@"EndUpPlayNvrPBCallBack"
                                                                                                 object:nil];
                                         }
                                         __strong typeof(weakSelf)strongSelf = weakSelf;
                                         if (!strongSelf)
                                         {
                                             NSLog(@"对象丢失，无法设置 NVR 回放状态！");
                                             return ;
                                         }
                                         [strongSelf playControlResult:isSuccess
                                                               avIndex:avIndex
                                                          playCtrlType:nvrRecordFilePlayType];
                                     }];
}


#pragma mark -- 播放控制回调（avIndex，只有开启播放时返回的时 AV 通道，其他的都是：0 表示正常，-1 表示异常出错了）
- (void)playControlResult:(BOOL)isSuccess
                  avIndex:(int)avIndex
             playCtrlType:(NVRRecordFilePlayType)playCtrlType
{
    if (YES == isSuccess)
    {
        switch (playCtrlType)
        {
            case NVRRecordFilePlayStart:        // 开启播放
            {
                NSLog(@"请求录像回放文件开启播放成功, avIndex = %d", avIndex);
                _isSendFilePath = YES;
                [self startGetNvrVideoData];
                [self.ctrlView updateSnapshotBtn:_isPlaying];
                [self.ctrlView updatePlayButtonWithStyle:PlayOrPauseBtnPause];
                _isPlayFinish = NO;
            }
                break;
                
            case NVRRecordFilePlayPause:        // 暂停播放
            {
                if (0 <= avIndex)
                {
                    _isPause = YES;
                    
                    NSLog(@"请求录像回放文件暂停播放成功, result = %d", avIndex);
                    [self.ctrlView updatePlayButtonWithStyle:PlayOrPauseBtnPlay];
                    if (YES == _isEnterBackground)
                    {
                        _isPlaying = YES;
                    }
                    else
                    {
                        _isPlaying = NO;
                    }
                }
            }
                break;
                
            case NVRRecordFilePlayResume:       // 恢复播放
            {
                if (0 <= avIndex)
                {
                    _isPause = NO;
                    
                    NSLog(@"请求录像回放文件恢复播放成功, result = %d", avIndex);
                    [self.ctrlView updatePlayButtonWithStyle:PlayOrPauseBtnPause];
                    _isPlaying = YES;
                }
            }
                break;
                
            case NVRRecordFilePlayStop:         // 停止播放
            {
                NSLog(@"请求录像回放文件停止播放成功, result = %d", avIndex);
//                dispatch_semaphore_signal(self.semaphore);
            }
                break;
                
            case NVRRecordFilePlaySeek:         // 定点播放
            {
                NSLog(@"请求录像回放文件定点播放成功, result = %d", avIndex);
                [self.ctrlView updatePlayButtonWithStyle:PlayOrPauseBtnPause];
                _isDragingSlider = NO;
            }
                break;
                
            case NVRRecordFilePlayEnd:          // 播放结束、播放出错
            {
                NSLog(@"录像回放文件播放结束或者播放出错, result = %d", avIndex);
//                [self.playView configReloadBtnHidden:NO];
                [self.ctrlView updatePlayButtonWithStyle:PlayOrPauseBtnNoUse];
                _isPlayFinish = YES;
            }
                break;
                
            default:
                break;
        }
    }
    else
    {
        switch (playCtrlType)
        {
            case NVRRecordFilePlayStart:        // 开启播放
            {
                NSLog(@"请求录像回放文件开启播放失败，avIndex = %d", avIndex);
            }
                break;
                
            case NVRRecordFilePlayPause:        // 暂停播放
            {
                NSLog(@"请求录像回放文件暂停播放失败，result = %d", avIndex);
            }
                break;
                
            case NVRRecordFilePlayResume:       // 恢复播放
            {
                NSLog(@"请求录像回放文件恢复播放失败，result = %d", avIndex);
            }
                break;
                
            case NVRRecordFilePlayStop:         // 停止播放
            {
                NSLog(@"请求录像回放文件停止播放失败，result = %d", avIndex);
//                dispatch_semaphore_signal(self.semaphore);
            }
                break;
                
            case NVRRecordFilePlaySeek:         // 定点播放
            {
                NSLog(@"请求录像回放文件定点播放失败，result = %d", avIndex);
                _isDragingSlider = NO;
            }
                break;
                
            case NVRRecordFilePlayEnd:
            {
                NSLog(@"录像回放文件播放结束或者播放出错, result = %d", avIndex);
                _isPlayFinish = YES;
            }
                break;
                
            default:
                break;
        }
    }
}


#pragma mark -- 获取视频流
- (void)startGetNvrVideoData
{
    NSLog(@"==== 准备发送获取 NVR 回放视频流请求,avChannel：%d", (int) _pbAvChannel);
    [[NetAPISet sharedInstance] nvrStartGetVideoDataWithDeviceId:self.pbListModel.deviceId
                                                       avChannel:_pbAvChannel
                                                     playViewNum:1
                                            nvrGetVideoDataBlock:^(NvrGetDataStatus retStatus,
                                                                   NSString *nvrDeviceId,
                                                                   long avChannel) {
                                                
                                                switch (retStatus)
                                                {
                                                    case NvrGetDataSuccess:         // 拉流成功
                                                    {
                                                        NSLog(@"NVR 开启回放视频流成功，nvrDeviceId = %@，avChannel = %ld", nvrDeviceId, avChannel);
                                                    }
                                                        break;
                                                        
                                                    case NvrGetDataFailure:         // 拉流失败
                                                    {
                                                        NSLog(@"NVR 开启回放视频流失败，nvrDeviceId = %@，avChannel = %ld", nvrDeviceId, avChannel);
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


#pragma mark -- NVR 回放播放控制
- (void)recordFilePlayWithType:(kNetRecCtrlType)playCtrlType
                    seekSecond:(long)seekSecond
{
    NSLog(@"==== 准备发送控制 NVR 回放播放请求 playCtrlType = %d", (int)playCtrlType);
    [[NetAPISet sharedInstance] nvrRecordPlayCtrlWithDeviceId:self.pbListModel.deviceId
                                                    avChannel:(int)_pbAvChannel
                                                 playCtrlType:playCtrlType
                                                   seekSecond:seekSecond];
}


#pragma mark -- 停止拉取视频流
- (void)stopGetNvrVideoData
{
    NSLog(@"--- NvrPlaybackPlayViewController -- 停止拉取视频流");
    [self recordFilePlayWithType:kNETPRO_RECSTREAM_STOP
                      seekSecond:0];
}


#pragma mark -- Slider 事件
- (void)onSliderValChanged:(UISlider *)slider
                  forEvent:(UIEvent *)event
{
    UITouch *touchEvent = [[event allTouches] anyObject];
    switch (touchEvent.phase)
    {
        case UITouchPhaseBegan:
        {
            _hasDragingSlider = NO;
            _isDragingSlider  = YES;
            NSLog(@"handle drag began");
        }
            break;
            
        case UITouchPhaseMoved:
        {
            _hasDragingSlider = YES;
//            NSLog(@"handle drag moved");
        }
            break;
            
        case UITouchPhaseEnded:
        {
            if (NO == _hasDragingSlider)
            {
                NSLog(@"handle drag ended: 没有拖拽slider，不处理！");
                _isDragingSlider = NO;
                return;
            }
            CGFloat progress = slider.value;
            _seekTime = [self getSeeTimeStrWithProgress:progress];
            NSLog(@"handle drag ended: 拖动结束，播放进度：%f，时间：%@", progress, _seekTime);
            
            _endDragTime = (self.pbListModel.length * progress);
            NSLog(@"handle drag ended: 拖拽时间点：%u", _endDragTime);
            [self recordFilePlayWithType:kNETPRO_RECSTREAM_SEEK
                              seekSecond:_endDragTime];
            
            [self startActivity];
        }
            break;
            
        default:
            break;
    }
}


#pragma mark - NvrPlaybackCtrlViewDelegate
#pragma mark -- 播放/暂停 按钮事件代理回调
- (void)playOrPauseBtnAction
{
    NSLog(@"playOrPauseBtnAction");
    if (YES == _isPlaying)
    {
        [self recordFilePlayWithType:kNETPRO_RECSTREAM_PAUSE
                          seekSecond:0];
    }
    else
    {
        [self recordFilePlayWithType:kNETPRO_RECSTREAM_RESUME
                          seekSecond:0];
    }
}


#pragma mark -- 拍照 按钮事件代理回调
- (void)snapshotBtnAction
{
    NSLog(@"snapshotBtnAction");
    [self playSnapShotSound];
    [self startSnapshot];
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
    NSLog(@"NVR 回放视频数据：timeStamp = %d, isIFrame = %d, frameRate = %d, framNO = %d", timeStamp, isIFrame, frameRate, framNO);
    if (YES == _isEnterBackground
        || avChannel != _pbAvChannel
        || YES == _isPause)
    {
        NSLog(@"不播放 NVR 回放视频数据, _isEnterBackground = %d, _pbAvChannel = %ld, avChannel = %d", _isEnterBackground, _pbAvChannel, avChannel);
        return ;
    }
    if (YES == isIFrame)
    {
        [self stopActivity];
    }
    _isPlaying = YES;
    if (NO == _isStartPlay)
    {
        [self.ctrlView updateSnapshotBtn:_isPlaying];
        [self.ctrlView updatePlayButtonWithStyle:PlayOrPauseBtnPause];
        _isStartPlay = YES;
    }
    if (self.pbVideoPlayer)
    {
        [self.pbVideoPlayer AddVideoFrame:pContentBuffer
                                      len:length
                                       ts:timeStamp
                                   framNo:framNO
                                frameRate:frameRate
                                   iFrame:isIFrame
                             andDeviceUid:deviceId];
        [self updateSliderValueWithTiimestamp:timeStamp];
    }
}


#pragma mark - 拍照的回调
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


-(void)showNewStatusInfo:(NSString*)info
{
    [SVProgressHUD showInfoWithStatus:info];
    [SVProgressHUD dismissWithDelay:2];
}


@end
