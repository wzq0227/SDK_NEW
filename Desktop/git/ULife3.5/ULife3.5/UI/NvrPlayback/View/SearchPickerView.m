//
//  SearchPickerView.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/16.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "SearchPickerView.h"
#import <Masonry.h>

/** picker 高度 */
#define SEARCH_PICKER_HEIGHT 200.0f

/** Picker 显示隐藏动画时长（单位：秒）*/
#define PICKER_ANIMATION_DURATION 0.15f

@interface SearchPickerView ()  <
                                    UIPickerViewDelegate,
                                    UIPickerViewDataSource
                                >
{
    /** 上一次选择的日期 */
    NSString *_lastDate;
    
    /** 上一次选择的起始时间 */
    NSString *_lastStartTime;
    
    /** 上一次选择的结束时间 */
    NSString *_lastEndTime;
    
    /** 上一次选择的视频类型 */
    NSString *_lastType;
    
    /** 上一次选择的频道 */
    NSString *_lastChannel;
}
/** 搜索日期 Picker */
@property (nonatomic, strong) UIDatePicker *searchDatePicker;

/** 搜索起始时间 Picker */
@property (nonatomic, strong) UIDatePicker *startTimePicker;

/** 搜索结束时间 Picker */
@property (nonatomic, strong) UIDatePicker *endTimePicker;

/** 搜索类型 Picker */
@property (nonatomic, strong) UIPickerView *typePickerView;

/** 搜索频道 Picker */
@property (nonatomic, strong) UIPickerView *channelPickerView;

/** 视频类型数组 */
@property (nonatomic, strong) NSArray *typeArray;

/** 频道编号数组 */
@property (nonatomic, strong) NSArray *channelArray;

@end

@implementation SearchPickerView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.backgroundColor                = UIColorFromRGBA(238.0f, 238.0f, 238.0f, 1.0f);
        self.searchDatePicker               = [[UIDatePicker alloc] init];
        self.startTimePicker                = [[UIDatePicker alloc] init];
        self.endTimePicker                  = [[UIDatePicker alloc] init];
        self.typePickerView                 = [[UIPickerView alloc] init];
        self.channelPickerView              = [[UIPickerView alloc] init];
        
        self.typePickerView.delegate        = self;
        self.channelPickerView.delegate     = self;
        self.typePickerView.dataSource      = self;
        self.channelPickerView.dataSource   = self;
        
        [self addSubview:self.searchDatePicker];
        [self addSubview:self.startTimePicker];
        [self addSubview:self.endTimePicker];
        [self addSubview:self.typePickerView];
        [self addSubview:self.channelPickerView];
        
        [self configDatePicker:self.searchDatePicker];
        [self configDatePicker:self.startTimePicker];
        [self configDatePicker:self.endTimePicker];
        [self configPickerView:self.typePickerView];
        [self configPickerView:self.channelPickerView];
    }
    return self;
}


#pragma mark - 懒加载
#pragma mark -- 视频类型数组
- (NSArray *)typeArray
{
    if (!_typeArray)
    {
        _typeArray = @[DPLocalizedString(@"AllType"),
                       DPLocalizedString(@"ManualType"),
                       DPLocalizedString(@"PlanType"),
                       DPLocalizedString(@"AlarmType")];
        _lastType  = _typeArray[0];
    }
    
    return _typeArray;
}


#pragma mark -- 频道编号数组
- (NSArray *)channelArray
{
    if (!_channelArray)
    {
        _channelArray = @[[NSString stringWithFormat:@"%@1", DPLocalizedString(@"ChannelNo")],
                          [NSString stringWithFormat:@"%@2", DPLocalizedString(@"ChannelNo")],
                          [NSString stringWithFormat:@"%@3", DPLocalizedString(@"ChannelNo")],
                          [NSString stringWithFormat:@"%@4", DPLocalizedString(@"ChannelNo")]];
        _lastChannel  = _channelArray[0];
    }
    
    return _channelArray;
}


#pragma mark -- 返回上一次选择的 video 类型 的 row
- (NSInteger)lastVideoTypeRow:(NSString *)lastVideoStr
{
    for (int i = 0; i < self.typeArray.count; i++)
    {
        if ([lastVideoStr isEqualToString:self.typeArray[i]])
        {
            return i;
        }
    }
    
    return 0;
}


#pragma mark -- 返回上一次选择的 channel 类型 的 row
- (NSInteger)lastChannelRow:(NSString *)lastChannelStr
{
    for (int i = 0; i < self.channelArray.count; i++)
    {
        if ([lastChannelStr isEqualToString:self.channelArray[i]])
        {
            return i;
        }
    }
    
    return 0;
}

#pragma mark - UI 适配
#pragma mark --- 适配 Date Picker
- (void)configDatePicker:(UIDatePicker *)datePicker
{
    __weak typeof(self)weakSelf = self;
    [datePicker mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NVR 搜索 Button");
            return ;
        }
        make.left.mas_equalTo(strongSelf.mas_left);
        make.right.mas_equalTo(strongSelf.mas_right);
        make.height.mas_equalTo(SEARCH_PICKER_HEIGHT);
        make.bottom.mas_equalTo(strongSelf.mas_bottom).mas_offset(SEARCH_PICKER_HEIGHT);
    }];
    if (datePicker == self.searchDatePicker)
    {
        datePicker.datePickerMode  = UIDatePickerModeDate;
        NSDate *currentDate = [NSDate date];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        _lastDate = [dateFormatter stringFromDate:currentDate];
    }
    else if (datePicker == self.startTimePicker)
    {
        datePicker.datePickerMode  = UIDatePickerModeCountDownTimer;
        _lastStartTime = @"00:00";
    }
    else if (datePicker == self.endTimePicker)
    {
        datePicker.datePickerMode  = UIDatePickerModeCountDownTimer;
        _lastEndTime = @"23:59";
    }
    [datePicker addTarget:self
                   action:@selector(dateSelected:)
         forControlEvents:UIControlEventValueChanged];
}


#pragma mark --- 适配 Picker View
- (void)configPickerView:(UIPickerView *)pickerView
{
    __weak typeof(self)weakSelf = self;
    [pickerView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NVR 搜索 Button");
            return ;
        }
        make.left.mas_equalTo(strongSelf.mas_left);
        make.right.mas_equalTo(strongSelf.mas_right);
        make.height.mas_equalTo(SEARCH_PICKER_HEIGHT);
        make.bottom.mas_equalTo(strongSelf.mas_bottom).mas_offset(SEARCH_PICKER_HEIGHT);
    }];
}


#pragma mark -- 隐藏/显示 Date Picker
- (void)configDatePicker:(DatePickerStyle)datePickerStyle
                isHidden:(BOOL)isHidden
{
    UIDatePicker *datePicker;
    switch (datePickerStyle)
    {
        case DatePickerDate:            // 日期
        {
            datePicker = self.searchDatePicker;
        }
            break;
            
        case DatePickerStartTime:       // 起始时间
        {
            datePicker = self.startTimePicker;
        }
            break;
            
        case DatePickerEndTime:         // 结束时间
        {
            datePicker = self.endTimePicker;
        }
            break;
            
        default:
        {
            
        }
            break;
    }
    __weak typeof(self)weakSelf = self;
    if (NO == isHidden) // 显示
    {
        [datePicker mas_updateConstraints:^(MASConstraintMaker *make) {
            
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                return ;
            }
            make.bottom.mas_equalTo(strongSelf.mas_bottom).mas_offset(0);
        }];
        [self scollDatePicker:datePickerStyle];
    }
    else    // 隐藏
    {
        [datePicker mas_updateConstraints:^(MASConstraintMaker *make) {
            
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                return ;
            }
            make.bottom.mas_equalTo(strongSelf.mas_bottom).mas_offset(SEARCH_PICKER_HEIGHT);
        }];
        
    }
    [UIView animateWithDuration:PICKER_ANIMATION_DURATION
                     animations:^{
                         
                         __strong typeof(weakSelf)strongSelf = weakSelf;
                         if (!strongSelf)
                         {
                             return ;
                         }
                         [strongSelf layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         
                     }];
}


#pragma mark -- 隐藏/显示 Picker View
- (void)configPickerView:(PickerViewStyle)pickerViewStyle
                isHidden:(BOOL)isHidden
{
    UIPickerView *pickerView;
    switch (pickerViewStyle)
    {
        case SearchPickerViewType:          // 类型
        {
            pickerView = self.typePickerView;
        }
            break;
            
        case SearchPickerViewChannel:       // 频道
        {
            pickerView = self.channelPickerView;
        }
            break;
            
        default:
        {
            
        }
            break;
    }
    __weak typeof(self)weakSelf = self;
    if (NO == isHidden) // 显示
    {
        [pickerView mas_updateConstraints:^(MASConstraintMaker *make) {
            
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                return ;
            }
            make.bottom.mas_equalTo(strongSelf.mas_bottom).mas_offset(0);
        }];
        // 滚动至上次选择的值
        [self scrollPickerView:pickerViewStyle];
    }
    else    // 隐藏
    {
        [pickerView mas_updateConstraints:^(MASConstraintMaker *make) {
            
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                return ;
            }
            make.bottom.mas_equalTo(strongSelf.mas_bottom).mas_offset(SEARCH_PICKER_HEIGHT);
        }];
        
    }
    [UIView animateWithDuration:PICKER_ANIMATION_DURATION
                     animations:^{
                         
                         __strong typeof(weakSelf)strongSelf = weakSelf;
                         if (!strongSelf)
                         {
                             return ;
                         }
                         [strongSelf layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         
                     }];
}


#pragma mark -- 滑动 Picker View 到之前选择的值
- (void)scollDatePicker:(DatePickerStyle)datePickerStyle
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法滚动 PickerView");
            return ;
        }
        switch (datePickerStyle)
        {
            case DatePickerDate:            // 日期
            {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
                NSString *dateStr = [NSString stringWithFormat:@"%@ %@:00", strongSelf->_lastDate, strongSelf->_lastStartTime];
                NSDate *pickerDate = [formatter dateFromString:dateStr];
                [strongSelf.searchDatePicker setDate:pickerDate animated:YES];
            }
                break;
                
            case DatePickerStartTime:       // 起始时间
            {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
                NSString *dateStr = [NSString stringWithFormat:@"%@ %@:00", strongSelf->_lastDate, strongSelf->_lastStartTime];
                NSDate *pickerDate = [formatter dateFromString:dateStr];
                [strongSelf.startTimePicker setDate:pickerDate animated:YES];
            }
                break;
                
            case DatePickerEndTime:         // 结束时间
            {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
                NSString *dateStr = [NSString stringWithFormat:@"%@ %@:00", strongSelf->_lastDate, strongSelf->_lastEndTime];
                NSDate *pickerDate = [formatter dateFromString:dateStr];
                [strongSelf.endTimePicker setDate:pickerDate animated:YES];
            }
                break;
                
            default:
            {
                
            }
                break;
        }
    });
}


#pragma mark -- 滑动 Picker View 到之前选择的值
- (void)scrollPickerView:(PickerViewStyle)pickerViewStyle
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法滚动 PickerView");
            return ;
        }
        switch (pickerViewStyle)
        {
            case SearchPickerViewType:          // 类型
            {
                [strongSelf.typePickerView selectRow:[strongSelf lastVideoTypeRow:strongSelf->_lastType]
                                         inComponent:0
                                            animated:YES];
            }
                break;
                
            case SearchPickerViewChannel:       // 频道
            {
                [strongSelf.channelPickerView selectRow:[strongSelf lastChannelRow:strongSelf->_lastChannel]
                                            inComponent:0
                                               animated:YES];
            }
                break;
                
            default:
            {
                
            }
                break;
        }
    });
}


#pragma mark - Pick View Delegate and Datasource
#pragma mark -- Pick View Datasource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    if (pickerView == self.typePickerView)  // 录像类型
    {
        return self.typeArray.count;
    }
    else if (pickerView == self.channelPickerView)    // 频道类型
    {
        return self.channelArray.count;
    }
    else
    {
        return 0;
    }
}


- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    if (pickerView == self.typePickerView)  // 录像类型
    {
        return self.typeArray[row % self.typeArray.count];
    }
    else if (pickerView == self.channelPickerView)    // 频道类型
    {
        return self.channelArray[row % self.channelArray.count];
    }
    else
    {
        return nil;
    }
}


#pragma mark -- Info Pick View Delegate
- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component
{
    if (pickerView == self.typePickerView)  // 录像类型
    {
        NSString *videoType = self.typeArray[row % self.typeArray.count];
        _lastType = videoType;
        if (self.delegate
            && [self.delegate respondsToSelector:@selector(selectedType:)])
        {
            [self.delegate selectedType:videoType];
        }
    }
    else if (pickerView == self.channelPickerView)    // 频道类型
    {
        NSString *channel = self.channelArray[row % self.channelArray.count];
        _lastChannel = channel;
        if (self.delegate
            && [self.delegate respondsToSelector:@selector(selectedChannel:)])
        {
            [self.delegate selectedChannel:channel];
        }
    }
    else
    {
        return ;
    }
}


#pragma mark - Date Picker 事件监听
-(void)dateSelected:(id)sender
{
    UIDatePicker *datePicker        = (UIDatePicker *)sender;
    NSDate *pickerDate              = datePicker.date;
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    
    NSString *dateString;
    if (datePicker == self.searchDatePicker)
    {
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        dateString = [dateFormatter stringFromDate:pickerDate];
        
        _lastDate = dateString;
        if (self.delegate
            && [self.delegate respondsToSelector:@selector(selectedDate:)])
        {
            [self.delegate selectedDate:dateString];
        }
    }
    else if (datePicker == self.startTimePicker)
    {
        [dateFormatter setDateFormat:@"HH:mm"];
        dateString = [dateFormatter stringFromDate:pickerDate];
        
        _lastStartTime = dateString;
        if (self.delegate
            && [self.delegate respondsToSelector:@selector(selectedStartTime:)])
        {
            [self.delegate selectedStartTime:dateString];
        }
    }
    else if (datePicker == self.endTimePicker)
    {
        [dateFormatter setDateFormat:@"HH:mm"];
        dateString = [dateFormatter stringFromDate:pickerDate];
        
        _lastEndTime = dateString;
        if (self.delegate
            && [self.delegate respondsToSelector:@selector(selectedEndTime:)])
        {
            [self.delegate selectedEndTime:dateString];
        }
    }
}


@end
