//
//  NvrSearchPlaybackViewController.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/16.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "NvrSearchPlaybackViewController.h"
#import "SearchBtnView.h"
#import "SearchPickerView.h"
#import "NvrPlaybackListViewController.h"

#define NAV_BAR_HEIGHT 64.0f

@interface NvrSearchPlaybackViewController ()   <
                                                    SearchBtnViewDelegate,
                                                    SearchPickerViewDelegate
                                                >
{
    /** 保存屏幕宽度 */
    CGFloat _screenWidth;
    
    /** 保存屏幕高度 */
    CGFloat _screenHeight;
}

@property (nonatomic, strong) SearchBtnView *searchBtnView;

@property (nonatomic, strong) SearchPickerView *searchPickerView;

/** 设备数据模型 */
@property (nonatomic, strong) DeviceDataModel *devDataModel;

/** TUTK 平台 ID （长度：20）*/
@property (nonatomic, copy) NSString *tutkDevId;

/** 3.5 平台 ID （长度：28）*/
@property (nonatomic, copy) NSString *platformDevId;

/** 选择的搜索日期 */
@property (nonatomic, copy) NSString *searchDate;

/** 选择的搜索起始时间 */
@property (nonatomic, copy) NSString *searchStartTime;

/** 选择的搜索结束 */
@property (nonatomic, copy) NSString *searchEndTime;

/** 选择的搜索类型 */
@property (nonatomic, assign) uint32_t searchType;

/** 选择的搜索频道 */
@property (nonatomic, assign) uint32_t searchChannel;

@end

@implementation NvrSearchPlaybackViewController


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
    
    self.navigationItem.title = DPLocalizedString(@"VR360_playback");
    [SVProgressHUD show];
    [self initParam];
    
    __weak typeof(self)weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        self.searchBtnView = [[SearchBtnView alloc] initWithFrame:CGRectMake(0,
                                                                             NAV_BAR_HEIGHT,
                                                                             _screenWidth,
                                                                             280)];
        self.searchBtnView.delegate = self;
        self.searchPickerView = [[SearchPickerView alloc] initWithFrame:CGRectMake(0,
                                                                                   280 + NAV_BAR_HEIGHT,
                                                                                   _screenWidth,
                                                                                   _screenHeight - 280 - 64.0f)];
        self.searchPickerView.delegate = self;
        [self.view addSubview:self.searchBtnView];
        [self.view addSubview:self.searchPickerView];
        
        [self setDefaultSearchOption];
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:strongSelf
                                                                                    action:@selector(hiddenAllPickerView)];
        singleTap.numberOfTapsRequired    = 1;//单指单击手势
        singleTap.numberOfTouchesRequired = 1;
        [strongSelf.view addGestureRecognizer:singleTap];
        [SVProgressHUD dismiss];
    });
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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
    NSLog(@"----------- NvrSearchPlaybackViewController dealloc -----------");
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
}


#pragma mark - 设置默认的搜索条件
- (void)setDefaultSearchOption
{
    NSDate  *currentDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    self.searchDate      = [dateFormatter stringFromDate:currentDate];
    self.searchStartTime = @"00:00";
    self.searchEndTime   = @"23:59";
    self.searchType      = 0xff;//DPLocalizedString(@"AllType");
    self.searchChannel   = 0;
    NSString *channelStr = [NSString stringWithFormat:@"%@%d", DPLocalizedString(@"ChannelNo"), self.searchChannel + 1];
    
    [self.searchBtnView updateButton:self.searchBtnView.searchDateBtn
                           withTitle:self.searchDate];
    [self.searchBtnView updateButton:self.searchBtnView.searchStartTimeBtn
                           withTitle:self.searchStartTime];
    [self.searchBtnView updateButton:self.searchBtnView.searchEndTimeBtn
                           withTitle:self.searchEndTime];
    [self.searchBtnView updateButton:self.searchBtnView.searchTypeBtn
                           withTitle:DPLocalizedString(@"AllType")];
    [self.searchBtnView updateButton:self.searchBtnView.searchChannelBtn
                           withTitle:channelStr];
}


#pragma mark -- 隐藏所有 Picker View
- (void)hiddenAllPickerView
{
    [self.searchPickerView configDatePicker:DatePickerDate
                                   isHidden:YES];
    [self.searchPickerView configDatePicker:DatePickerStartTime
                                   isHidden:YES];
    [self.searchPickerView configDatePicker:DatePickerEndTime
                                   isHidden:YES];
    [self.searchPickerView configPickerView:SearchPickerViewType
                                   isHidden:YES];
    [self.searchPickerView configPickerView:SearchPickerViewChannel
                                   isHidden:YES];
}


#pragma mark - SearchBtnViewDelegate
#pragma mark -- ‘日期’按钮事件
- (void)searchDateButtonAction
{
    NSLog(@"‘日期’按钮事件");
    [self.searchPickerView configDatePicker:DatePickerStartTime
                                   isHidden:YES];
    [self.searchPickerView configDatePicker:DatePickerEndTime
                                   isHidden:YES];
    [self.searchPickerView configPickerView:SearchPickerViewType
                                   isHidden:YES];
    [self.searchPickerView configPickerView:SearchPickerViewChannel
                                   isHidden:YES];
    
    [self.searchPickerView configDatePicker:DatePickerDate
                                   isHidden:NO];
}


#pragma mark -- ‘起始时间’按钮事件
- (void)searchStartTimeButtonAction
{
    NSLog(@"‘起始时间’按钮事件");
    [self.searchPickerView configDatePicker:DatePickerDate
                                   isHidden:YES];
    [self.searchPickerView configDatePicker:DatePickerEndTime
                                   isHidden:YES];
    [self.searchPickerView configPickerView:SearchPickerViewType
                                   isHidden:YES];
    [self.searchPickerView configPickerView:SearchPickerViewChannel
                                   isHidden:YES];
    
    [self.searchPickerView configDatePicker:DatePickerStartTime
                                   isHidden:NO];
}


#pragma mark -- ‘结束时间’按钮事件
- (void)searchEndTimeButtonAction
{
    NSLog(@"‘结束时间’按钮事件");
    [self.searchPickerView configDatePicker:DatePickerDate
                                   isHidden:YES];
    [self.searchPickerView configDatePicker:DatePickerStartTime
                                   isHidden:YES];
    [self.searchPickerView configPickerView:SearchPickerViewType
                                   isHidden:YES];
    [self.searchPickerView configPickerView:SearchPickerViewChannel
                                   isHidden:YES];
    
    [self.searchPickerView configDatePicker:DatePickerEndTime
                                   isHidden:NO];
}


#pragma mark -- ‘类型’按钮事件
- (void)searchTypButtoneAction
{
    NSLog(@"‘类型’按钮事件");
    [self.searchPickerView configDatePicker:DatePickerDate
                                   isHidden:YES];
    [self.searchPickerView configDatePicker:DatePickerStartTime
                                   isHidden:YES];
    [self.searchPickerView configDatePicker:DatePickerEndTime
                                   isHidden:YES];
    [self.searchPickerView configPickerView:SearchPickerViewChannel
                                   isHidden:YES];
    
    [self.searchPickerView configPickerView:SearchPickerViewType
                                   isHidden:NO];
}


#pragma mark -- ‘频道’按钮事件
- (void)searchChannelButtonAction
{
    NSLog(@"‘频道’按钮事件");
    [self.searchPickerView configDatePicker:DatePickerDate
                                   isHidden:YES];
    [self.searchPickerView configDatePicker:DatePickerStartTime
                                   isHidden:YES];
    [self.searchPickerView configDatePicker:DatePickerEndTime
                                   isHidden:YES];
    [self.searchPickerView configPickerView:SearchPickerViewType
                                   isHidden:YES];
    
    [self.searchPickerView configPickerView:SearchPickerViewChannel
                                   isHidden:NO];
}


#pragma mark -- ‘搜索’按钮事件
- (void)searchButtonAction
{
    NSLog(@"‘搜索’按钮事件");
    [self hiddenAllPickerView];
    if (IS_STRING_EMPTY(self.searchDate)
        || IS_STRING_EMPTY(self.searchStartTime)
        || IS_STRING_EMPTY(self.searchEndTime))
    {
        NSLog(@"NVR Playback 搜索条件不符合！");
        return;
    }
    NvrPlaybackListViewController *playbackListVC = [[NvrPlaybackListViewController alloc] init];
    if (playbackListVC)
    {
        playbackListVC.nvrDeviceId  = self.tutkDevId;
        playbackListVC.videoType    = self.searchType;
        playbackListVC.searchDate   = self.searchDate;
        playbackListVC.startTime    = self.searchStartTime;
        playbackListVC.endTime      = self.searchEndTime;
        playbackListVC.channelMask  = self.searchChannel;
        playbackListVC.devDataModel = self.devDataModel;
        
        [self.navigationController pushViewController:playbackListVC
                                             animated:YES];
    }
}


#pragma mark - SearchPickerViewDelegate
#pragma mark -- 日期选择（yyyy-mm-dd)
- (void)selectedDate:(NSString *)dateStr
{
    self.searchDate = dateStr;
    [self.searchBtnView updateButton:self.searchBtnView.searchDateBtn
                           withTitle:self.searchDate];
}


#pragma mark -- 起始时间选择
- (void)selectedStartTime:(NSString *)startTimeStr
{
    self.searchStartTime = startTimeStr;
    [self.searchBtnView updateButton:self.searchBtnView.searchStartTimeBtn
                           withTitle:self.searchStartTime];
}


#pragma mark -- 结束时间选择
- (void)selectedEndTime:(NSString *)endTimeStr
{
    self.searchEndTime = endTimeStr;
    [self.searchBtnView updateButton:self.searchBtnView.searchEndTimeBtn
                           withTitle:self.searchEndTime];
}


#pragma mark -- 类型选择
- (void)selectedType:(NSString *)typeStr
{
//    全部：0xff  ，    计划（定时）：0x1，   报警：0x3
    if ([typeStr isEqualToString:DPLocalizedString(@"AllType")])
    {
        self.searchType = 0xff;
    }
    else if ([typeStr isEqualToString:DPLocalizedString(@"ManualType")])
    {
        self.searchType = 0xff;
    }
    else if ([typeStr isEqualToString:DPLocalizedString(@"PlanType")])
    {
        self.searchType = 0x1;
    }
    else if ([typeStr isEqualToString:DPLocalizedString(@"AlarmType")])
    {
        self.searchType = 0x3;
    }
    else
    {
        self.searchType = 0xff;
    }
    
    [self.searchBtnView updateButton:self.searchBtnView.searchTypeBtn
                           withTitle:typeStr];
}


#pragma mark -- 频道选择
- (void)selectedChannel:(NSString *)channleStr
{
    NSString *channel = [channleStr substringFromIndex:channleStr.length - 1];
    self.searchChannel   = [channel intValue] - 1;
    [self.searchBtnView updateButton:self.searchBtnView.searchChannelBtn
                           withTitle:channleStr];
}


@end
