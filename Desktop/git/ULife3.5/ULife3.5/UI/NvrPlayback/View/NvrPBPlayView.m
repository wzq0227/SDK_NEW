//
//  NvrPBPlayView.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/21.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "NvrPBPlayView.h"
#import "EnlargeClickButton.h"

#define RELOAD_BTN_WIDTH  100.0f
#define RELOAD_BTN_HEIGHT 40.0f


@interface NvrPBPlayView ()

@property (nonatomic, strong) UIActivityIndicatorView *loadDataActivity;

/** 重新加载 Button */
@property (nonatomic, strong) EnlargeClickButton *reloadButton;

@end

@implementation NvrPBPlayView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.backgroundColor  = [UIColor blackColor];
        self.loadDataActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.reloadButton     = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        [self.reloadButton setTitle:DPLocalizedString(@"reloadBtn")
                             forState:UIControlStateNormal];
        self.reloadButton.backgroundColor = [UIColor lightGrayColor];
        self.reloadButton.hidden          = YES;
        [self.reloadButton addTarget:self
                              action:@selector(reloadBtnAction)
                    forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.loadDataActivity];
        [self addSubview:self.reloadButton];
    }
    return self;
}


- (void)layoutSubviews
{
    self.loadDataActivity.center = CGPointMake(CGRectGetMidX(self.bounds),
                                               CGRectGetMidY(self.bounds));
    self.reloadButton.frame      = CGRectMake(0, 0, RELOAD_BTN_WIDTH, RELOAD_BTN_HEIGHT);
    self.reloadButton.center     = CGPointMake(CGRectGetMidX(self.bounds),
                                               CGRectGetMidY(self.bounds));
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


#pragma mark -- ‘重新加载’按钮事件
- (void)reloadBtnAction
{
    NSLog(@"‘重新加载’按钮事件");
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(reloadData)])
    {
        [self.delegate reloadData];
    }
}


#pragma mark -- 设置‘重新加载’按钮是否隐藏
- (void)configReloadBtnHidden:(BOOL)isHidden
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法停止 NVR Activity");
            return ;
        }
        strongSelf.reloadButton.hidden = isHidden;
    });
}


@end
