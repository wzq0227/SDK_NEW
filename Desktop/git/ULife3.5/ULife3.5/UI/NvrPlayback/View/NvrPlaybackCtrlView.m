//
//  NvrPlaybackCtrlView.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/21.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "NvrPlaybackCtrlView.h"
#import <Masonry.h>
#import "EnlargeClickButton.h"

#define FILE_TITLE_LABEL_HEIGHT 20.0f

@interface NvrPlaybackCtrlView ()

/** 文件名称 Label */
@property (nonatomic, strong) UILabel *fileTitleLabel;

/** 分割线 View */
@property (nonatomic, strong) UIView *lineView;

/** 播放/暂停 Button */
@property (nonatomic, strong) EnlargeClickButton *playOrPauseBtn;

/** 拍照 Button */
@property (nonatomic, strong) EnlargeClickButton *snapshotBtn;

@end

@implementation NvrPlaybackCtrlView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.backgroundColor          = UIColorFromRGB(0x1fbcd2);
        self.fileTitleLabel           = [[UILabel alloc] init];
        self.fileTitleLabel.font      = [UIFont systemFontOfSize:12];
        self.fileTitleLabel.textColor = [UIColor whiteColor];
        self.lineView                 = [[UIView alloc] init];
        self.lineView.backgroundColor = [UIColor darkGrayColor];
        self.playOrPauseBtn           = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.snapshotBtn              = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        
        [self.playOrPauseBtn addTarget:self
                                action:@selector(playOrPauseAction)
                      forControlEvents:UIControlEventTouchUpInside];
        [self.snapshotBtn addTarget:self
                             action:@selector(snapshotAction)
                   forControlEvents:UIControlEventTouchUpInside];
        // 设置默认为暂停状态
        [self.playOrPauseBtn setImage:[UIImage imageNamed:@"recordFilePlayResumeUnuse"]
                             forState:UIControlStateNormal];

        [self.snapshotBtn setImage:[UIImage imageNamed:@"recordFilePlaySnapshotUnuse"]
                          forState:UIControlStateNormal];
        
        [self addSubview:self.fileTitleLabel];
        [self addSubview:self.lineView];
        [self addSubview:self.playOrPauseBtn];
        [self addSubview:self.snapshotBtn];
        
        [self configFileTitleLabel];
        [self configLineView];
        [self configPlayOrPauseBtn];
        [self configSnapshotBtn];
    }
    return self;
}


#pragma mark -- 适配 fileTitleLabel
- (void)configFileTitleLabel
{
    __weak typeof(self)weakSelf = self;
    [self.fileTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NVR 文件名 Label");
            return ;
        }
        make.left.mas_equalTo(strongSelf.mas_left).mas_offset(10.0f);
        make.top.mas_equalTo(strongSelf.mas_top).mas_offset(2.0f);
        make.right.mas_equalTo(strongSelf.mas_right).mas_offset(-10.0f);
        make.height.mas_equalTo(FILE_TITLE_LABEL_HEIGHT);
    }];
}


#pragma mark -- 适配 lineView
- (void)configLineView
{
    __weak typeof(self)weakSelf = self;
    [self.lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NVR 回放 分割线 View");
            return ;
        }
        make.left.mas_equalTo(strongSelf.mas_left);
        make.top.mas_equalTo(strongSelf.fileTitleLabel.mas_bottom).mas_offset(2.0f);
        make.right.mas_equalTo(strongSelf.mas_right);
        make.height.mas_equalTo(1.0f);
    }];
}


#pragma mark -- 适配 playOrPauseBtn
- (void)configPlayOrPauseBtn
{
    __weak typeof(self)weakSelf = self;
    [self.playOrPauseBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NVR 回放 播放/暂停 Button");
            return ;
        }
        make.left.mas_equalTo(strongSelf.mas_left).mas_offset(40.0f);
        make.top.mas_equalTo(strongSelf.lineView.mas_bottom).mas_offset(5.0f);
        make.bottom.mas_equalTo(strongSelf.mas_bottom).mas_equalTo(-5.0f);
        make.width.mas_equalTo(strongSelf.playOrPauseBtn.mas_height);
    }];
}


#pragma mark -- 适配 snapshotBtn
- (void)configSnapshotBtn
{
    __weak typeof(self)weakSelf = self;
    [self.snapshotBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NVR 回放 拍照 Button");
            return ;
        }
        make.right.mas_equalTo(strongSelf.mas_right).mas_offset(-40.0f);
        make.centerY.mas_equalTo(strongSelf.playOrPauseBtn.mas_centerY);
        make.height.mas_equalTo(strongSelf.playOrPauseBtn.mas_height);
        make.width.mas_equalTo(strongSelf.snapshotBtn.mas_height);
    }];
}


#pragma mark -- 显示回放文件名
- (void)showFileName:(NSString *)fileName
{
    if (IS_STRING_EMPTY(fileName))
    {
        return;
    }
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法修改 NVR 回放‘播放/暂停’按钮图标");
            return ;
        }
        strongSelf.fileTitleLabel.hidden = NO;
        strongSelf.fileTitleLabel.text = fileName;
    });
}


#pragma mark -- 修改‘播放/暂停’按钮图标
- (void)updatePlayButtonWithStyle:(PlayOrPauseBtnStyle)playOrPauseBtnStyle
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法修改 NVR 回放‘播放/暂停’按钮图标");
            return ;
        }
        switch (playOrPauseBtnStyle)
        {
            case PlayOrPauseBtnNoUse:   // 无视频流，不可操作按钮
            {
                [strongSelf.playOrPauseBtn setImage:[UIImage imageNamed:@"recordFilePlayPauseUnuse"]
                                           forState:UIControlStateNormal];
                strongSelf.playOrPauseBtn.userInteractionEnabled = NO;
            }
                break;
                
            case PlayOrPauseBtnPlay:    // 播放状态
            {
                [strongSelf.playOrPauseBtn setImage:[UIImage imageNamed:@"recordFilePlayResume"]
                                           forState:UIControlStateNormal];
                strongSelf.playOrPauseBtn.userInteractionEnabled = YES;
            }
                break;
                
            case PlayOrPauseBtnPause:   // 暂停状态
            {
                [strongSelf.playOrPauseBtn setImage:[UIImage imageNamed:@"recordFilePlayPause"]
                                           forState:UIControlStateNormal];
                strongSelf.playOrPauseBtn.userInteractionEnabled = YES;
            }
                break;
                
            default:
            {
                [strongSelf.playOrPauseBtn setImage:[UIImage imageNamed:@"recordFilePlayPauseUnuse"]
                                           forState:UIControlStateNormal];
                strongSelf.playOrPauseBtn.userInteractionEnabled = NO;
            }
                break;
        }
    });
}


#pragma mark -- 修改‘拍照’按钮图标
- (void)updateSnapshotBtn:(BOOL)isPlaying
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法修改 NVR 回放‘播放/暂停’按钮图标");
            return ;
        }
        if (YES == isPlaying)
        {
            [strongSelf.snapshotBtn setImage:[UIImage imageNamed:@"recordFilePlaySnapshot"]
                                    forState:UIControlStateNormal];
            strongSelf.snapshotBtn.userInteractionEnabled = YES;
        }
        else
        {
            [strongSelf.snapshotBtn setImage:[UIImage imageNamed:@"recordFilePlaySnapshotUnuse"]
                                    forState:UIControlStateNormal];
            strongSelf.snapshotBtn.userInteractionEnabled = NO;
        }
    });
}


#pragma mark - 按钮事件
#pragma mark -- ‘播放/暂停’ 按钮事件
- (void)playOrPauseAction
{
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(playOrPauseBtnAction)])
    {
        [self.delegate playOrPauseBtnAction];
    }
}


#pragma mark -- ‘拍照’ 按钮事件
- (void)snapshotAction
{
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(snapshotBtnAction)])
    {
        [self.delegate snapshotBtnAction];
    }
}


@end
