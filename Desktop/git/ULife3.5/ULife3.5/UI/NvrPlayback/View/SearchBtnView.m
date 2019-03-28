//
//  SearchBtnView.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/16.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "SearchBtnView.h"
#import <Masonry.h>

/** 按钮高度 */
#define SEARCH_BTN_HEIGHT 40.0f

@interface SearchBtnView ()

/** 搜索提示 Label */
@property (nonatomic, strong) UILabel *searchTitleLabel;

/** 时间提示 Label */
@property (nonatomic, strong) UILabel *timtToLabel;

@end

@implementation SearchBtnView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.backgroundColor    = UIColorFromRGBA(238.0f, 238.0f, 238.0f, 1.0f);
        self.searchDateBtn      = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.searchStartTimeBtn = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.searchEndTimeBtn   = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.searchTypeBtn      = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.searchChannelBtn   = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.searchBtn          = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        
        self.searchTitleLabel   = [[UILabel alloc] init];
        self.timtToLabel        = [[UILabel alloc] init];
        
        self.searchTitleLabel.text          = DPLocalizedString(@"searchLabel");
        self.timtToLabel.text               = DPLocalizedString(@"timtToLabel");
        self.searchTitleLabel.font          = [UIFont systemFontOfSize:12.0f];
        self.timtToLabel.font               = [UIFont systemFontOfSize:12.0f];
        self.searchTitleLabel.textAlignment = NSTextAlignmentLeft;
        self.timtToLabel.textAlignment      = NSTextAlignmentCenter;
        
        // 设置样式
        [self configStyleWithButton:self.searchDateBtn];
        [self configStyleWithButton:self.searchStartTimeBtn];
        [self configStyleWithButton:self.searchEndTimeBtn];
        [self configStyleWithButton:self.searchTypeBtn];
        [self configStyleWithButton:self.searchChannelBtn];
        [self configStyleWithButton:self.searchBtn];
        
        // 设置点击事件
        [self.searchDateBtn addTarget:self
                               action:@selector(searchDateAction)
                     forControlEvents:UIControlEventTouchUpInside];
        [self.searchStartTimeBtn addTarget:self
                                    action:@selector(searchStartTimeAction)
                          forControlEvents:UIControlEventTouchUpInside];
        [self.searchEndTimeBtn addTarget:self
                                  action:@selector(searchEndTimeAction)
                        forControlEvents:UIControlEventTouchUpInside];
        [self.searchTypeBtn addTarget:self
                               action:@selector(searchTypeAction)
                     forControlEvents:UIControlEventTouchUpInside];
        [self.searchChannelBtn addTarget:self
                                  action:@selector(searchChannelAction)
                        forControlEvents:UIControlEventTouchUpInside];
        [self.searchBtn addTarget:self
                           action:@selector(searchAction)
                 forControlEvents:UIControlEventTouchUpInside];
        
        [self.searchBtn setTitle:DPLocalizedString(@"searchLabel")
                        forState:UIControlStateNormal];
        
        // 添加观察者方法
        [self addObserverWithButton:self.searchDateBtn];
        [self addObserverWithButton:self.searchStartTimeBtn];
        [self addObserverWithButton:self.searchEndTimeBtn];
        [self addObserverWithButton:self.searchTypeBtn];
        [self addObserverWithButton:self.searchChannelBtn];
        [self addObserverWithButton:self.searchBtn];
        
        [self addSubview:self.searchDateBtn];
        [self addSubview:self.searchStartTimeBtn];
        [self addSubview:self.searchEndTimeBtn];
        [self addSubview:self.searchTypeBtn];
        [self addSubview:self.searchChannelBtn];
        [self addSubview:self.searchBtn];
        
        [self addSubview:self.searchTitleLabel];
        [self addSubview:self.timtToLabel];
        
        [self configSearchTitleLabel];
        [self configSearchDateBtn];
        [self configSearchDateBtn];
        [self configSearchStartTimeBtn];
        [self configSearchEndTimeBtn];
        [self configSearchTypeBtn];
        [self configSearchChannelBtn];
        [self configSearchBtn];
        [self configTimgToLabel];
         
    }
    return self;
}


- (void)dealloc
{
    [self removeObserverWithButton:self.searchDateBtn];
    [self removeObserverWithButton:self.searchStartTimeBtn];
    [self removeObserverWithButton:self.searchEndTimeBtn];
    [self removeObserverWithButton:self.searchTypeBtn];
    [self removeObserverWithButton:self.searchChannelBtn];
    [self removeObserverWithButton:self.searchBtn];
}


#pragma mark -- 设置 Button 样式
- (void)configStyleWithButton:(EnlargeClickButton *)button
{
    if (!button)
    {
        return;
    }
    button.backgroundColor     = UIColorFromRGB(0x1fbcd2);
    button.layer.cornerRadius  = 8.0f;
    button.layer.masksToBounds = YES;
    button.titleLabel.font     = [UIFont systemFontOfSize:16.0f];
}


#pragma mark -- 添加点击观察者
- (void)addObserverWithButton:(EnlargeClickButton *)button
{
    if (!button)
    {
        return;
    }
    [button addObserver:self
             forKeyPath:@"highlighted"
                options:NSKeyValueObservingOptionNew
                context:nil];
}


#pragma mark -- 移除观察者
- (void)removeObserverWithButton:(EnlargeClickButton *)button
{
    [button removeObserver:self
                forKeyPath:@"highlighted"
                   context:nil];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context
{
    EnlargeClickButton *button = (EnlargeClickButton *)object;
    if ([keyPath isEqualToString:@"highlighted"])
    {
        if (button.highlighted)
        {
            button.backgroundColor = UIColorFromRGBA(50.0f, 177.0f, 155.0f, 1.0f);
            return;
        }
        button.backgroundColor = UIColorFromRGB(0x1fbcd2);
    }
}


#pragma mark - UI 适配
- (void)configSearchTitleLabel
{
    __weak typeof(self)weakSelf = self;
    [self.searchTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NVR 搜索标题 Label");
            return ;
        }
        make.left.mas_equalTo(strongSelf.mas_left).mas_offset(20.0f);
        make.top.mas_equalTo(strongSelf.mas_top).mas_offset(20.0f);
        make.right.mas_equalTo(strongSelf.mas_right).mas_offset(-20.0f);
        make.height.mas_equalTo(20.0f);
    }];
}


- (void)configSearchDateBtn
{
    __weak typeof(self)weakSelf = self;
    [self.searchDateBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NVR 搜索日期 Button");
            return ;
        }
        make.left.mas_equalTo(strongSelf.searchTitleLabel.mas_left);
        make.top.mas_equalTo(strongSelf.searchTitleLabel.mas_bottom).mas_offset(2.0f);
        make.right.mas_equalTo(strongSelf.searchTitleLabel.mas_right);
        make.height.mas_equalTo(SEARCH_BTN_HEIGHT);
    }];
}


- (void)configSearchStartTimeBtn
{
    __weak typeof(self)weakSelf = self;
    [self.searchStartTimeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NVR 搜索起始时间 Button");
            return ;
        }
        make.left.mas_equalTo(strongSelf.searchDateBtn.mas_left);
        make.top.mas_equalTo(strongSelf.searchDateBtn.mas_bottom).mas_offset(10.0f);
        make.width.mas_equalTo(strongSelf.searchDateBtn.mas_width).multipliedBy(0.5f).mas_offset(-7);
        make.height.mas_equalTo(SEARCH_BTN_HEIGHT);
    }];
}


- (void)configSearchEndTimeBtn
{
    __weak typeof(self)weakSelf = self;
    [self.searchEndTimeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NVR 搜索结束时间 Button");
            return ;
        }
        make.right.mas_equalTo(strongSelf.searchDateBtn.mas_right);
        make.centerY.mas_equalTo(strongSelf.searchStartTimeBtn.mas_centerY);
        make.width.mas_equalTo(strongSelf.searchDateBtn.mas_width).multipliedBy(0.5f).mas_offset(-7);
        make.height.mas_equalTo(SEARCH_BTN_HEIGHT);
    }];
}


- (void)configSearchTypeBtn
{
    __weak typeof(self)weakSelf = self;
    [self.searchTypeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NVR 搜索类型 Button");
            return ;
        }
        make.left.mas_equalTo(strongSelf.searchStartTimeBtn.mas_left);
        make.top.mas_equalTo(strongSelf.searchStartTimeBtn.mas_bottom).mas_offset(10.0f);
        make.width.mas_equalTo(strongSelf.searchDateBtn.mas_width).multipliedBy(0.5f).mas_offset(-7);
        make.height.mas_equalTo(SEARCH_BTN_HEIGHT);
    }];
}


- (void)configSearchChannelBtn
{
    __weak typeof(self)weakSelf = self;
    [self.searchChannelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NVR 搜索频道 Button");
            return ;
        }
        make.right.mas_equalTo(strongSelf.searchEndTimeBtn.mas_right);
        make.centerY.mas_equalTo(strongSelf.searchTypeBtn.mas_centerY);
        make.width.mas_equalTo(strongSelf.searchDateBtn.mas_width).multipliedBy(0.5f).mas_offset(-7);
        make.height.mas_equalTo(SEARCH_BTN_HEIGHT);
    }];
}


- (void)configSearchBtn
{
    __weak typeof(self)weakSelf = self;
    [self.searchBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NVR 搜索 Button");
            return ;
        }
        make.left.mas_equalTo(strongSelf.searchDateBtn.mas_left);
        make.top.mas_equalTo(strongSelf.searchTypeBtn.mas_bottom).mas_offset(40.0f);
        make.right.mas_equalTo(strongSelf.searchDateBtn.mas_right);
        make.height.mas_equalTo(SEARCH_BTN_HEIGHT);
    }];
}


- (void)configTimgToLabel
{
    __weak typeof(self)weakSelf = self;
    [self.timtToLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NVR 至 Label");
            return ;
        }
        make.left.mas_equalTo(strongSelf.searchStartTimeBtn.mas_right);
        make.right.mas_equalTo(strongSelf.searchEndTimeBtn.mas_left);
        make.centerY.mas_equalTo(strongSelf.searchStartTimeBtn.mas_centerY);
    }];
}


#pragma mark - 按钮事件
#pragma mark -- ‘搜索日期’按钮事件
- (void)searchDateAction
{
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(searchDateButtonAction)])
    {
        [self.delegate searchDateButtonAction];
    }
}


#pragma mark -- ‘搜索起始时间’按钮事件
- (void)searchStartTimeAction
{
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(searchStartTimeButtonAction)])
    {
        [self.delegate searchStartTimeButtonAction];
    }
}


#pragma mark -- ‘搜索结束时间’按钮事件
- (void)searchEndTimeAction
{
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(searchEndTimeButtonAction)])
    {
        [self.delegate searchEndTimeButtonAction];
    }
}


#pragma mark -- ‘搜索类型’按钮事件
- (void)searchTypeAction
{
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(searchTypButtoneAction)])
    {
        [self.delegate searchTypButtoneAction];
    }
}


#pragma mark -- ‘搜索频道’按钮事件
- (void)searchChannelAction
{
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(searchChannelButtonAction)])
    {
        [self.delegate searchChannelButtonAction];
    }
}


#pragma mark -- ‘搜索’按钮事件
- (void)searchAction
{
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(searchButtonAction)])
    {
        [self.delegate searchButtonAction];
    }
}


#pragma mark -- 更新按钮标题
- (void)updateButton:(EnlargeClickButton *)button
           withTitle:(NSString *)titleStr
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法更新按钮标题");
            return ;
        }
        [button setTitle:titleStr forState:UIControlStateNormal];
    });
}


@end
