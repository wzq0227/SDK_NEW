//
//  NvrCenterView.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/14.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "NvrCenterView.h"
#import "EnlargeClickButton.h"


@interface NvrCenterView ()

/** NVR 录像列表 Button */
@property (nonatomic, strong) EnlargeClickButton *nvrRecordListBtn;

/** NVR 全屏 Button */
@property (nonatomic, strong) EnlargeClickButton *nvrFullScreenBtn;

/** NVR 日期 Label */
@property (nonatomic, strong) UILabel *nvrDateLabel;

@end


@implementation NvrCenterView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.backgroundColor  = [UIColor colorWithRed:238.0f/255.0f
                                                green:238.0f/255.0f
                                                 blue:238.0f/255.0f
                                                alpha:1.0f];
        self.nvrRecordListBtn = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.nvrFullScreenBtn = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.nvrDateLabel     = [[UILabel alloc] init];
        self.nvrDateLabel.textAlignment = NSTextAlignmentCenter;
        
        [self.nvrRecordListBtn setImage:[UIImage imageNamed:@"SmallNvrPlaybackNormal"]
                               forState:UIControlStateNormal];
        [self.nvrRecordListBtn setImage:[UIImage imageNamed:@"SmallNvrPlaybackNormal"]
                               forState:UIControlStateHighlighted];
        [self.nvrFullScreenBtn setImage:[UIImage imageNamed:@"FullScreen"]
                               forState:UIControlStateNormal];
        
        [self.nvrRecordListBtn addTarget:self
                                  action:@selector(recordListAction)
                        forControlEvents:UIControlEventTouchUpInside];
        [self.nvrFullScreenBtn addTarget:self
                                  action:@selector(fullScreenAction)
                        forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:self.nvrRecordListBtn];
        [self addSubview:self.nvrFullScreenBtn];
        [self addSubview:self.nvrDateLabel];
    }
    return self;
}


- (void)layoutSubviews
{
    self.nvrRecordListBtn.frame = CGRectMake(15.0f, 8.0f, 32.0f, 32.0f);
    self.nvrFullScreenBtn.frame = CGRectMake(self.bounds.size.width - 35.0f, 14, 20, 20);
    self.nvrDateLabel.bounds    = CGRectMake(0, 0, self.bounds.size.width - 124, self.bounds.size.height * 0.5);
    self.nvrDateLabel.center    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}


#pragma mark - 按钮事件
#pragma mark -- 录像列表 按钮事件
- (void)recordListAction
{
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(nvrRecordListAction)])
    {
        [self.delegate nvrRecordListAction];
    }
    NSLog(@"NVR 录像列表 按钮事件!");
}


#pragma mark -- 全屏 按钮事件
- (void)fullScreenAction
{
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(nvrFullScreenAction)])
    {
        [self.delegate nvrFullScreenAction];
    }
    NSLog(@"NVR 全屏 按钮事件!");
}


#pragma mark -- 设置日期 Label 显示文本
- (void)configDateLabelWithStr:(NSString *)dateStr
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法停止 NVR Activity");
            return ;
        }
        strongSelf.nvrDateLabel.text = dateStr;
    });
}


- (void)configDateLabelHidden:(BOOL)isHidden
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法停止 NVR Activity");
            return ;
        }
        strongSelf.nvrDateLabel.hidden = isHidden;
        if (NO == isHidden)     // 显示
        {
            strongSelf.alpha = 1.0f;
        }
        else    // 隐藏
        {
            strongSelf.alpha = 0.5f;
        }
    });
}

@end
