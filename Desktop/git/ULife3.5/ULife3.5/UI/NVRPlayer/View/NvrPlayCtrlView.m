//
//  NvrPlayCtrlView.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/15.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "NvrPlayCtrlView.h"
#import "EnlargeClickButton.h"
#import <Masonry.h>


@interface NvrPlayCtrlView ()

/** 录像 Button */
@property (nonatomic, strong) EnlargeClickButton *recordButton;

/** 拍照 Button */
@property (nonatomic, strong) EnlargeClickButton *snapshotButton;

/** 相册 Button */
@property (nonatomic, strong) EnlargeClickButton *photoAlbumBtn;

/** 录像 Label */
@property (nonatomic, strong) UILabel *recordLabel;

/** 拍照 Label */
@property (nonatomic, strong) UILabel *snapshotLabel;

/** 历史流回放 Label */
@property (nonatomic, strong) UILabel *photoAlbumLabel;


@end

@implementation NvrPlayCtrlView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.recordButton                 = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.snapshotButton                = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.photoAlbumBtn                 = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        
        self.recordLabel                   = [[UILabel alloc] init];
        self.snapshotLabel                 = [[UILabel alloc] init];
        self.photoAlbumLabel               = [[UILabel alloc] init];
        
        self.recordLabel.font              = [UIFont systemFontOfSize:12];
        self.snapshotLabel.font            = [UIFont systemFontOfSize:12];
        self.photoAlbumLabel.font          = [UIFont systemFontOfSize:12];
        
        self.recordLabel.text              = DPLocalizedString(@"VR360_Record");
        self.snapshotLabel.text            = DPLocalizedString(@"play_Snapshot");
        self.photoAlbumLabel.text          = DPLocalizedString(@"Setting_PhotoAlbum");
        
        self.recordLabel.textColor         = [UIColor darkGrayColor];
        self.snapshotLabel.textColor       = [UIColor darkGrayColor];
        self.photoAlbumLabel.textColor     = [UIColor darkGrayColor];
        
        self.recordLabel.textAlignment     = NSTextAlignmentCenter;
        self.snapshotLabel.textAlignment   = NSTextAlignmentCenter;
        self.photoAlbumLabel.textAlignment = NSTextAlignmentCenter;
        
        [self.recordButton setImage:[UIImage imageNamed:@"NvrRecordDisable"]
                           forState:UIControlStateDisabled];
        [self.recordButton setImage:[UIImage imageNamed:@"NvrRecordNormal"]
                           forState:UIControlStateNormal];
        [self.recordButton setImage:[UIImage imageNamed:@"NvrRecordHighLight"]
                           forState:UIControlStateHighlighted];
        
        [self.snapshotButton setImage:[UIImage imageNamed:@"NvrSnapshotDisable"]
                             forState:UIControlStateDisabled];
        [self.snapshotButton setImage:[UIImage imageNamed:@"NvrSnapshotNormal"]
                             forState:UIControlStateNormal];
        [self.snapshotButton setImage:[UIImage imageNamed:@"NvrSnapshotHighLight"]
                             forState:UIControlStateHighlighted];
        
        [self.photoAlbumBtn setImage:[UIImage imageNamed:@"NvrAlbumDisable"]
                            forState:UIControlStateDisabled];
        [self.photoAlbumBtn setImage:[UIImage imageNamed:@"NvrAlbumNormal"]
                            forState:UIControlStateNormal];
        [self.photoAlbumBtn setImage:[UIImage imageNamed:@"NvrAlbumHighlight"]
                            forState:UIControlStateHighlighted];
        
        [self.recordButton addTarget:self
                              action:@selector(recordAction)
                    forControlEvents:UIControlEventTouchUpInside];
        [self.snapshotButton addTarget:self
                                action:@selector(snapshotAction)
                      forControlEvents:UIControlEventTouchUpInside];
        [self.photoAlbumBtn addTarget:self
                               action:@selector(photoAlbumAction)
                     forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:self.recordButton];
        [self addSubview:self.snapshotButton];
        [self addSubview:self.photoAlbumBtn];

        [self addSubview:self.recordLabel];
        [self addSubview:self.snapshotLabel];
        [self addSubview:self.photoAlbumLabel];
        
        [self configRecordButton];
        [self configSnapshotButton];
        [self configPlaybackButton];
    }
    return self;
}


#pragma mark -- 适配 NVR 录像 Button
- (void)configRecordButton
{
    __weak typeof(self)weakSelf = self;
    [self.recordButton mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NVR 录像 Button");
            return ;
        }
        make.centerY.mas_equalTo(strongSelf.mas_centerY);
        make.centerX.mas_equalTo(strongSelf.mas_centerX).multipliedBy(0.25f);
        make.width.mas_equalTo(strongSelf.mas_width).multipliedBy(0.2f);
        make.height.mas_equalTo(strongSelf.recordButton.mas_width);
    }];
    
    [self.recordLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NVR 录像 Label");
            return ;
        }
        make.centerX.mas_equalTo(strongSelf.recordButton.mas_centerX);
        make.top.mas_equalTo(strongSelf.recordButton.mas_bottom).mas_offset(10);
        make.width.mas_equalTo(strongSelf.recordButton.mas_width);
    }];
}


#pragma mark -- 适配 NVR 拍照 Button
- (void)configSnapshotButton
{
    __weak typeof(self)weakSelf = self;
    [self.snapshotButton mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NVR 拍照 Button");
            return ;
        }
        make.centerY.mas_equalTo(strongSelf.mas_centerY);
        make.centerX.mas_equalTo(strongSelf.mas_centerX);
        make.width.mas_equalTo(strongSelf.mas_width).multipliedBy(0.45f);
        make.height.mas_equalTo(strongSelf.snapshotButton.mas_width);
    }];
    
    [self.snapshotLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NVR 拍照 Label");
            return ;
        }
        make.centerX.mas_equalTo(strongSelf.snapshotButton.mas_centerX);
        make.top.mas_equalTo(strongSelf.snapshotButton.mas_bottom).mas_offset(15);
        make.width.mas_equalTo(strongSelf.snapshotButton.mas_width);
        make.height.mas_equalTo(25);
    }];
}


#pragma mark -- 适配 NVR 回放 Button
- (void)configPlaybackButton
{
    __weak typeof(self)weakSelf = self;
    [self.photoAlbumBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NVR 回放 Button");
            return ;
        }
        make.centerY.mas_equalTo(strongSelf.mas_centerY);
        make.centerX.mas_equalTo(strongSelf.mas_centerX).multipliedBy(1.75f);
        make.width.mas_equalTo(strongSelf.recordButton.mas_width);
        make.height.mas_equalTo(strongSelf.photoAlbumBtn.mas_width);
    }];
    
    [self.photoAlbumLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NVR 回放 Label");
            return ;
        }
        make.centerX.mas_equalTo(strongSelf.photoAlbumBtn.mas_centerX);
        make.top.mas_equalTo(strongSelf.photoAlbumBtn.mas_bottom).mas_offset(10);
        make.width.mas_equalTo(strongSelf.photoAlbumBtn.mas_width);
    }];
}


#pragma mark -- 设置‘录像’按钮样式
- (void)configRecordBtnStyle:(RecordBtnStyle)btnStyle
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法设置‘录像’按钮样式！");
            return ;
        }
        switch (btnStyle)
        {
            case RecordBtnDisable:      // 不可用
            {
                strongSelf.recordButton.enabled = NO;
            }
                break;
                
            case RecordBtnNormal:       // 常态
            {
                strongSelf.recordButton.enabled  = YES;
//                strongSelf.recordButton.selected = NO;
                strongSelf.recordButton.highlighted = NO;
            }
                break;
                
            case RecordBtnHighLight:    // 高亮
            {
                strongSelf.recordButton.enabled  = YES;
//                strongSelf.recordButton.selected = NO;
                strongSelf.recordButton.highlighted = YES;
//                [strongSelf.recordButton setImage:[UIImage imageNamed:@"NvrRecordHighLight"]
//                                         forState:UIControlStateNormal];
            }
                break;
                
            default:
                break;
        }
    });
}


#pragma mark - 按钮事件
#pragma mark -- '录像'按钮事件
- (void)recordAction
{
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(recordButtonAction)])
    {
        [self.delegate recordButtonAction];
    }
}


#pragma mark -- '拍照'按钮事件
- (void)snapshotAction
{
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(snapshotButtonAction)])
    {
        [self.delegate snapshotButtonAction];
    }
}


#pragma mark -- '相册'按钮事件
- (void)photoAlbumAction
{
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(photoAlbumButtonAction)])
    {
        [self.delegate photoAlbumButtonAction];
    }
}

@end
