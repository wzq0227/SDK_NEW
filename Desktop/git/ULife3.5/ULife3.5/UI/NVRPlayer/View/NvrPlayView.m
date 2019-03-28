//
//  NvrPlayView.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/14.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "NvrPlayView.h"
#import "EnlargeClickButton.h"


#define HALF_WIDTH  (self.bounds.size.width * 0.5f)
#define HALF_HEIGHT (self.bounds.size.height * 0.5f)

#define RELOAD_BTN_WIDTH  100.0f
#define RELOAD_BTN_HEIGHT 40.0f

typedef NS_ENUM(NSUInteger, TapCountStyle) {
    TapCountSingle                  = 1,        // 单击
    TapCountDouble                  = 2,        // 双击
};


@interface NvrPlayView ()
{
    CGPoint _singleTapLocation;
}

/** 离线 Button */
@property (nonatomic, strong) EnlargeClickButton *offlineButton;

/** NVR 左上角 重新加载 Button */
@property (nonatomic, strong) EnlargeClickButton *tlReloadButton;

/** NVR 右上角 重新加载 Button */
@property (nonatomic, strong) EnlargeClickButton *trReloadButton;

/** NVR 左下角 重新加载 Button */
@property (nonatomic, strong) EnlargeClickButton *blReloadButton;

/** NVR 右下角 重新加载 Button */
@property (nonatomic, strong) EnlargeClickButton *brReloadButton;

/** NVR：左上角角 Activity Indicator */
@property (nonatomic, strong) UIActivityIndicatorView *topLeftActivity;

/** NVR：右上角角 Activity Indicator */
@property (nonatomic, strong) UIActivityIndicatorView *topRightActivity;

/** NVR：左下角角 Activity Indicator */
@property (nonatomic, strong) UIActivityIndicatorView *bottomLeftActivity;

/** NVR：右下角角 Activity Indicator */
@property (nonatomic, strong) UIActivityIndicatorView *bottomRightActivity;

@end


@implementation NvrPlayView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.topLeftPlayView     = [[UIView alloc] init];
        self.topRightPlayView    = [[UIView alloc] init];
        self.bottomLeftPlayView  = [[UIView alloc] init];
        self.bottomRightPlayView = [[UIView alloc] init];
        self.topLeftActivity     = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.topRightActivity    = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.bottomLeftActivity  = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.bottomRightActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        
        self.offlineButton       = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.tlReloadButton      = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.trReloadButton      = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.blReloadButton      = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.brReloadButton      = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        
        [self.offlineButton setTitle:DPLocalizedString(@"Play_Ipc_unonline")
                            forState:UIControlStateNormal];
        [self.tlReloadButton setTitle:DPLocalizedString(@"reloadBtn")
                             forState:UIControlStateNormal];
        [self.trReloadButton setTitle:DPLocalizedString(@"reloadBtn")
                             forState:UIControlStateNormal];
        [self.blReloadButton setTitle:DPLocalizedString(@"reloadBtn")
                             forState:UIControlStateNormal];
        [self.brReloadButton setTitle:DPLocalizedString(@"reloadBtn")
                             forState:UIControlStateNormal];
        
        [self.offlineButton setTitleColor:[UIColor whiteColor]
                                 forState:UIControlStateNormal];
        
        self.offlineButton.backgroundColor  = [UIColor blackColor];
        self.tlReloadButton.backgroundColor = [UIColor lightGrayColor];
        self.trReloadButton.backgroundColor = [UIColor lightGrayColor];
        self.blReloadButton.backgroundColor = [UIColor lightGrayColor];
        self.brReloadButton.backgroundColor = [UIColor lightGrayColor];
        
        self.offlineButton.hidden           = YES;
        self.tlReloadButton.hidden          = YES;
        self.trReloadButton.hidden          = YES;
        self.blReloadButton.hidden          = YES;
        self.brReloadButton.hidden          = YES;
        
        [self.offlineButton addTarget:self
                               action:@selector(offlineBtnAction)
                     forControlEvents:UIControlEventTouchUpInside];
        [self.tlReloadButton addTarget:self
                                action:@selector(tlReloadBtnAction)
                      forControlEvents:UIControlEventTouchUpInside];
        [self.trReloadButton addTarget:self
                                action:@selector(trReloadBtnAction)
                      forControlEvents:UIControlEventTouchUpInside];
        [self.blReloadButton addTarget:self
                                action:@selector(blReloadBtnAction)
                      forControlEvents:UIControlEventTouchUpInside];
        [self.brReloadButton addTarget:self
                                action:@selector(brReloadBtnAction)
                      forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:self.topLeftPlayView];
        [self addSubview:self.topRightPlayView];
        [self addSubview:self.bottomLeftPlayView];
        [self addSubview:self.bottomRightPlayView];
        [self addSubview:self.offlineButton];
        
        [self.topLeftPlayView addSubview:self.topLeftActivity];
        [self.topRightPlayView addSubview:self.topRightActivity];
        [self.bottomLeftPlayView addSubview:self.bottomLeftActivity];
        [self.bottomRightPlayView addSubview:self.bottomRightActivity];
        
        [self.topLeftPlayView addSubview:self.tlReloadButton];
        [self.topRightPlayView addSubview:self.trReloadButton];
        [self.bottomLeftPlayView addSubview:self.blReloadButton];
        [self.bottomRightPlayView addSubview:self.brReloadButton];
        
        self.topLeftPlayView.backgroundColor     = [UIColor blackColor];
        self.topRightPlayView.backgroundColor    = [UIColor blackColor];
        self.bottomLeftPlayView.backgroundColor  = [UIColor blackColor];
        self.bottomRightPlayView.backgroundColor = [UIColor blackColor];
        
    }
    return self;
}


- (void)layoutSubviews
{
    self.topLeftPlayView.frame      = CGRectMake(0, 0, HALF_WIDTH, HALF_HEIGHT);
    self.topRightPlayView.frame     = CGRectMake(HALF_WIDTH, 0, HALF_WIDTH, HALF_HEIGHT);
    self.bottomLeftPlayView.frame   = CGRectMake(0, HALF_HEIGHT, HALF_WIDTH, HALF_HEIGHT);
    self.bottomRightPlayView.frame  = CGRectMake(HALF_WIDTH, HALF_HEIGHT, HALF_WIDTH, HALF_HEIGHT);
    
    self.topLeftActivity.center     = CGPointMake(CGRectGetMidX(self.topLeftPlayView.bounds),
                                                  CGRectGetMidY(self.topLeftPlayView.bounds));
    self.topRightActivity.center    = CGPointMake(CGRectGetMidX(self.topLeftPlayView.bounds),
                                                  CGRectGetMidY(self.topLeftPlayView.bounds));
    self.bottomLeftActivity.center  = CGPointMake(CGRectGetMidX(self.topLeftPlayView.bounds),
                                                  CGRectGetMidY(self.topLeftPlayView.bounds));
    self.bottomRightActivity.center = CGPointMake(CGRectGetMidX(self.topLeftPlayView.bounds),
                                                  CGRectGetMidY(self.topLeftPlayView.bounds));
    
    self.offlineButton.frame        = CGRectMake(0, 0, RELOAD_BTN_WIDTH, RELOAD_BTN_HEIGHT);
    self.tlReloadButton.frame       = CGRectMake(0, 0, RELOAD_BTN_WIDTH, RELOAD_BTN_HEIGHT);
    self.trReloadButton.frame       = CGRectMake(0, 0, RELOAD_BTN_WIDTH, RELOAD_BTN_HEIGHT);
    self.blReloadButton.frame       = CGRectMake(0, 0, RELOAD_BTN_WIDTH, RELOAD_BTN_HEIGHT);
    self.brReloadButton.frame       = CGRectMake(0, 0, RELOAD_BTN_WIDTH, RELOAD_BTN_HEIGHT);
    
    self.offlineButton.center       = CGPointMake(CGRectGetMidX(self.bounds),
                                                  CGRectGetMidY(self.bounds));
    self.tlReloadButton.center      = CGPointMake(CGRectGetMidX(self.topLeftPlayView.bounds),
                                                  CGRectGetMidY(self.topLeftPlayView.bounds));
    self.trReloadButton.center      = CGPointMake(CGRectGetMidX(self.topLeftPlayView.bounds),
                                                  CGRectGetMidY(self.topLeftPlayView.bounds));
    self.blReloadButton.center      = CGPointMake(CGRectGetMidX(self.topLeftPlayView.bounds),
                                                  CGRectGetMidY(self.topLeftPlayView.bounds));
    self.brReloadButton.center      = CGPointMake(CGRectGetMidX(self.topLeftPlayView.bounds),
                                                  CGRectGetMidY(self.topLeftPlayView.bounds));
}


#pragma mark -- 开启 Activity 动画
- (void)startActivityAnimationOnPosition:(PositionType)positionType
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法开启 NVR Activity");
            return ;
        }
        switch (positionType)
        {
            case PositionTopLeft:       // 左上角
            {
                strongSelf.topLeftActivity.hidden = NO;
                [strongSelf.topLeftActivity startAnimating];
            }
                break;
                
            case PositionTopRight:      // 右上角
            {
                strongSelf.topRightActivity.hidden = NO;
                [strongSelf.topRightActivity startAnimating];
            }
                break;
                
            case PositionBottomLeft:    // 左下角
            {
                strongSelf.bottomLeftActivity.hidden = NO;
                [strongSelf.bottomLeftActivity startAnimating];
            }
                break;
                
            case PositionBottomRight:   // 右下角
            {
                strongSelf.bottomRightActivity.hidden = NO;
                [strongSelf.bottomRightActivity startAnimating];
            }
                break;
                
            default:
            {
                
            }
                break;
        }
    });
}


#pragma mark -- 停止 Activity 动画
- (void)stopActivityAnimationOnPosition:(PositionType)positionType
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法停止 NVR Activity");
            return ;
        }
        switch (positionType)
        {
            case PositionTopLeft:       // 左上角
            {
                [strongSelf.topLeftActivity stopAnimating];
                strongSelf.topLeftActivity.hidden = YES;
            }
                break;
                
            case PositionTopRight:      // 右上角
            {
                [strongSelf.topRightActivity stopAnimating];
                strongSelf.topRightActivity.hidden = YES;
            }
                break;
                
            case PositionBottomLeft:    // 左下角
            {
                [strongSelf.bottomLeftActivity stopAnimating];
                strongSelf.bottomLeftActivity.hidden = YES;
            }
                break;
                
            case PositionBottomRight:   // 右下角
            {
                [strongSelf.bottomRightActivity stopAnimating];
                strongSelf.bottomRightActivity.hidden = YES;
            }
                break;
                
            default:
            {
                
            }
                break;
        }
    });
}


#pragma mark -- 设置‘重新加载’按钮是否隐藏
- (void)configReloadBtnHidden:(BOOL)isHidden
                   onPosition:(PositionType)positionType
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法停止 NVR Activity");
            return ;
        }
        switch (positionType)
        {
            case PositionTopLeft:       // 左上角
            {
                strongSelf.tlReloadButton.hidden = isHidden;
            }
                break;
                
            case PositionTopRight:      // 右上角
            {
                strongSelf.trReloadButton.hidden = isHidden;
            }
                break;
                
            case PositionBottomLeft:    // 左下角
            {
                strongSelf.blReloadButton.hidden = isHidden;
            }
                break;
                
            case PositionBottomRight:   // 右下角
            {
                strongSelf.brReloadButton.hidden = isHidden;
            }
                break;
                
            default:
            {
                
            }
                break;
        }
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


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch     = [touches anyObject];
    _singleTapLocation = [touch locationInView:self];
    NSTimeInterval delaytime = 0.4f;
    if (1 == touch.tapCount)
    {
        [self performSelector:@selector(singleTapAction)
                   withObject:nil
                   afterDelay:delaytime];
    }
    else if (2 == touch.tapCount)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self
                                                 selector:@selector(singleTapAction)
                                                   object:nil];
        [self performSelector:@selector(doubleTapAction)
                   withObject:nil
                   afterDelay:delaytime];
    }
}


#pragma mark - 手势点击 NVR 判断
#pragma mark -- 单击处理
-(void)singleTapAction
{
    NSLog(@"----- NvrPlayView ----- 单击！");
    
    [self handleTapOnCount:TapCountSingle];
}


#pragma mark -- 双击处理
-(void)doubleTapAction
{
    NSLog(@"----- NvrPlayView ----- 双击！");
    [self handleTapOnCount:TapCountDouble];
}


#pragma mark -- 处理点击事件
- (void)handleTapOnCount:(TapCountStyle)tapCountStyle
{
    CGRect topLeftViewFrame     = self.topLeftPlayView.frame;
    CGRect topRightViewFrame    = self.topRightPlayView.frame;
    CGRect bottomLeftViewFrame  = self.bottomLeftPlayView.frame;
    CGRect bottomRightViewFrame = self.bottomRightPlayView.frame;
    
    PositionType positionType = PositionTopLeft;
    if (CGRectContainsPoint(topLeftViewFrame, _singleTapLocation))            // 进入 top left view
    {
        NSLog(@"进入 NVR: Top Left 播放页面！");
        positionType = PositionTopLeft;
    }
    else if (CGRectContainsPoint(topRightViewFrame, _singleTapLocation))      // 进入 top right view
    {
        NSLog(@"进入 NVR: Top Right 播放页面！");
        positionType = PositionTopRight;
    }
    else if (CGRectContainsPoint(bottomLeftViewFrame, _singleTapLocation))    // 进入 bottom left view
    {
        NSLog(@"进入 NVR: Bottom Left 播放页面！");
        positionType = PositionBottomLeft;
    }
    else if (CGRectContainsPoint(bottomRightViewFrame, _singleTapLocation))   // 进入 bottom right view
    {
        NSLog(@"进入 NVR: Bottom Right 播放页面！");
        positionType = PositionBottomRight;
    }
    if (TapCountSingle == tapCountStyle)        // 单击
    {
        if (self.delegate
            && [self.delegate respondsToSelector:@selector(singleTapOnPosition:)])
        {
            [self.delegate singleTapOnPosition:positionType];
        }
    }
    else if (TapCountDouble == tapCountStyle)   // 双击
    {
        if (self.delegate
            && [self.delegate respondsToSelector:@selector(doubleTapOnPosition:)])
        {
            [self.delegate doubleTapOnPosition:positionType];
        }
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
- (void)tlReloadBtnAction
{
    NSLog(@"左上角‘重新加载’按钮事件");
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(reloadDataOnPosition:)])
    {
        [self.delegate reloadDataOnPosition:PositionTopLeft];
    }
}


#pragma mark -- 右上角‘重新加载’按钮事件
- (void)trReloadBtnAction
{
    NSLog(@"右上角‘重新加载’按钮事件");
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(reloadDataOnPosition:)])
    {
        [self.delegate reloadDataOnPosition:PositionTopRight];
    }
}


#pragma mark -- 左下角‘重新加载’按钮事件
- (void)blReloadBtnAction
{
    NSLog(@"左下角‘重新加载’按钮事件");
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(reloadDataOnPosition:)])
    {
        [self.delegate reloadDataOnPosition:PositionBottomLeft];
    }
}


#pragma mark -- 右下角‘重新加载’按钮事件
- (void)brReloadBtnAction
{
    NSLog(@"右下角‘重新加载’按钮事件");
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(reloadDataOnPosition:)])
    {
        [self.delegate reloadDataOnPosition:PositionBottomRight];
    }
}


@end
