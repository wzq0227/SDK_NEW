//
//  NvrSinglePlayView.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/16.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "NvrSinglePlayView.h"
#import "EnlargeClickButton.h"


#define REC_TIPLABEL_WIDTH 30

#define RELOAD_BTN_WIDTH  100.0f
#define RELOAD_BTN_HEIGHT 40.0f
#define QUALITY_BTN_WIDTH 40.0f


@interface NvrSinglePlayView ()

/** 数据加载 Activity */
@property (nonatomic, strong) UIActivityIndicatorView *loadDataActivity;

/** 离线 Button */
@property (nonatomic, strong) EnlargeClickButton *offlineButton;

/** 重新加载 Button */
@property (nonatomic, strong) EnlargeClickButton *reloadButton;

/** 录像提示 Label */
@property (nonatomic, strong) UILabel *recordTipLabel;

/** 提示正在录像 View */
@property (nonatomic, strong) UIView *recordingView;

/** 画面质量切换 Button */
@property (nonatomic, strong) EnlargeClickButton *qualityChangeBtn;

/** 录像时长 Label */
//@property (nonatomic, strong) UILabel *recDurationLabel;

@end

@implementation NvrSinglePlayView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.backgroundColor  = [UIColor blackColor];
        self.loadDataActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.offlineButton    = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.reloadButton     = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.qualityChangeBtn = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.recordingView    = [[UIView alloc] init];
        self.recordTipLabel   = [[UILabel alloc] init];
//        self.recDurationLabel = [[UILabel alloc] init];
        
        [self.offlineButton setTitle:DPLocalizedString(@"Play_Ipc_unonline")
                            forState:UIControlStateNormal];
        [self.reloadButton setTitle:DPLocalizedString(@"reloadBtn")
                           forState:UIControlStateNormal];
        
        [self.offlineButton setTitleColor:[UIColor whiteColor]
                                 forState:UIControlStateNormal];
        [self.reloadButton setTitleColor:[UIColor whiteColor]
                                forState:UIControlStateNormal];
        
        [self.qualityChangeBtn addTarget:self
                                  action:@selector(qualityChangeBtnAction)
                        forControlEvents:UIControlEventTouchUpInside];
        
        [self.qualityChangeBtn setBackgroundImage:[UIImage imageNamed:@"PlayControllBG"]
                               forState:UIControlStateNormal];
        [self.qualityChangeBtn setBackgroundImage:[UIImage imageNamed:@"PlayControllBlackBG"]
                               forState:UIControlStateHighlighted];
        
        self.offlineButton.backgroundColor = [UIColor blackColor];
        self.reloadButton.backgroundColor  = [UIColor lightGrayColor];
        
        self.offlineButton.hidden          = YES;
        self.reloadButton.hidden           = YES;
        
        [self.offlineButton addTarget:self
                               action:@selector(offlineBtnAction)
                     forControlEvents:UIControlEventTouchUpInside];
        [self.reloadButton addTarget:self
                              action:@selector(reloadBtnAction)
                    forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:self.loadDataActivity];
        [self addSubview:self.offlineButton];
        [self addSubview:self.reloadButton];
        [self addSubview:self.recordingView];
        [self addSubview:self.recordTipLabel];
        [self addSubview:self.qualityChangeBtn];
//        [self addSubview:self.recDurationLabel];
        
        [self configRecordingView];
        [self configRecordTipLabel];
    }
    return self;
}


#pragma mark -- 配置 RecordView
- (void)configRecordingView
{
    self.recordingView.hidden              = YES;
    self.recordingView.backgroundColor     = [UIColor redColor];
    self.recordingView.layer.cornerRadius  = 5;
    self.recordingView.layer.masksToBounds = YES;
}


#pragma mark -- 配置 RecordTipsLabel
- (void)configRecordTipLabel
{
    self.recordTipLabel.text      = @"REC";
    self.recordTipLabel.hidden    = YES;
    self.recordTipLabel.textColor = [UIColor redColor];
    self.recordTipLabel.font      = [UIFont boldSystemFontOfSize:14];
}


- (void)layoutSubviews
{
    self.offlineButton.frame     = CGRectMake(0, 0, RELOAD_BTN_WIDTH, RELOAD_BTN_HEIGHT);
    self.reloadButton.frame      = CGRectMake(0, 0, RELOAD_BTN_WIDTH, RELOAD_BTN_HEIGHT);
    self.offlineButton.center    = CGPointMake(CGRectGetMidX(self.bounds),
                                               CGRectGetMidY(self.bounds));
    self.reloadButton.center     = CGPointMake(CGRectGetMidX(self.bounds),
                                               CGRectGetMidY(self.bounds));
    self.loadDataActivity.center = CGPointMake(CGRectGetMidX(self.bounds),
                                               CGRectGetMidY(self.bounds));
    self.recordingView.frame = CGRectMake(self.bounds.size.width - 120, 25, 10, 10);
    self.recordTipLabel.frame = CGRectMake(self.bounds.size.width - 120 - 10 - REC_TIPLABEL_WIDTH, 20, REC_TIPLABEL_WIDTH, 20);
    self.qualityChangeBtn.frame     = CGRectMake(40, self.bounds.size.height - 80, QUALITY_BTN_WIDTH, QUALITY_BTN_WIDTH);
}


#pragma mark -- 开启 Activity 动画
- (void)startActivityAnimation
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法开启 loadDataActivity 动画！");
            return ;
        }
        strongSelf.loadDataActivity.hidden = NO;
        [strongSelf.loadDataActivity startAnimating];
    });
}


#pragma mark -- 停止 Activity 动画
- (void)stopActivityAnimation
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法开启 loadDataActivity 动画！");
            return ;
        }
        [strongSelf.loadDataActivity stopAnimating];
        strongSelf.loadDataActivity.hidden = YES;
    });
}


#pragma mark -- 设置 正在录像 View 是否显示
- (void)configRecordingViewHidden:(BOOL)isHidden
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法设置 正在录像 View 是否显示！");
            return ;
        }
        strongSelf.recordingView.hidden = isHidden;
    });
}


#pragma mark -- 设置录像提示 Label 是否显示
- (void)configRecordTipLabelViewHidden:(BOOL)isHidden
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法设置录像提示 Label 是否显示！");
            return ;
        }
        strongSelf.recordTipLabel.hidden = isHidden;
    });
}


#pragma mark -- 设置‘不在线’按钮是否隐藏
- (void)configOfflineBtnHidden:(BOOL)isHidden
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，设置‘不在线’按钮是否隐藏");
            return ;
        }
        strongSelf.offlineButton.hidden = isHidden;
    });
}


#pragma mark -- 设置‘重新加载’按钮是否隐藏
- (void)configReloadBtnHidden:(BOOL)isHidden
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，设置‘重新加载’按钮是否隐藏");
            return ;
        }
        strongSelf.reloadButton.hidden = isHidden;
    });
}


#pragma mark -- 设置视频质量切换按钮 title
- (void)configQualityTitle:(BOOL)isHD
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        [strongSelf.qualityChangeBtn setTitle:NO == isHD ? @"SD" : @"HD"
                                     forState:UIControlStateNormal];
    });
}


- (void)configQualityBtnUsable:(BOOL)isUsable
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        strongSelf.qualityChangeBtn.userInteractionEnabled = isUsable;
    });
}


#pragma mark -- 切换视频码率
- (void)qualityChangeBtnAction
{
    NSLog(@"‘切换码流’按钮事件");
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(qualityChangeButtonAction)])
    {
        [self.delegate qualityChangeButtonAction];
    }
}


#pragma mark -- ‘不在线’按钮事件
- (void)offlineBtnAction
{
    NSLog(@"‘不在线’按钮事件");
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(offlineButtonAction)])
    {
        [self.delegate offlineButtonAction];
    }
}


#pragma mark -- 左上角‘重新加载’按钮事件
- (void)reloadBtnAction
{
    NSLog(@"‘重新加载’按钮事件");
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(reloadDataButtonAction)])
    {
        [self.delegate reloadDataButtonAction];
    }
}


@end
