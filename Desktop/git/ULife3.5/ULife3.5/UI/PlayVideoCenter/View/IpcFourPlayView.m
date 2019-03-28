//
//  IpcFourPlayView.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/9/21.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "IpcFourPlayView.h"
#import "EnlargeClickButton.h"
#import "IpcFourViewDevListTableViewCell.h"
#import "MBProgressHUD.h"


#define HALF_WIDTH  (self.bounds.size.width * 0.5f - 1.0f)
#define HALF_HEIGHT (self.bounds.size.height * 0.5f - 1.0f)

#define RELOAD_BTN_WIDTH  130.0f
#define RELOAD_BTN_HEIGHT 50.0f

#define AUTO_HIDDEN_BTN_DURATION 3.0f

/** 设备列表 cell 高度 */
#define IPC_FOUR_VIEW_LIST_CELL_HEIGHT 44.0f


typedef NS_ENUM(NSUInteger, TapCountStyle) {
    TapCountSingle                  = 1,        // 单击
    TapCountDouble                  = 2,        // 双击
};


@interface IpcFourPlayView ()   <
                                    UITableViewDataSource,
                                    UITableViewDelegate
                                >
{
    /** 添加的目标位置 */
    PositionType _targetPosition;
    
    PositionType _lastPosition;
    
    CGPoint _singleTapLocation;
    
    /** 是否已添加设备(0 下标不用) */
    BOOL _isAddDevice[5];
    
    /** 是否隐藏按钮（添加设备、删除设备）0 下标不用 */
    BOOL _isHiddenBtn[5];
}


/** IPC 四画面：左上角(top-left) Activity Indicator */
@property (nonatomic, strong) UIActivityIndicatorView *tlActivity;

/** IPC 四画面：右上角(top-right) Activity Indicator */
@property (nonatomic, strong) UIActivityIndicatorView *trActivity;

/** IPC 四画面：左下角(bottom-left) Activity Indicator */
@property (nonatomic, strong) UIActivityIndicatorView *blActivity;

/** IPC 四画面：右下角(bottom-right) Activity Indicator */
@property (nonatomic, strong) UIActivityIndicatorView *brActivity;


/** IPC 四画面：左上角(top-left) 离线 Button */
@property (nonatomic, strong) EnlargeClickButton *tlOfflineButton;

/** IPC 四画面：右上角(top-right) 离线 Button */
@property (nonatomic, strong) EnlargeClickButton *trOfflineButton;

/** IPC 四画面：左上角(bottom-left) 离线 Button */
@property (nonatomic, strong) EnlargeClickButton *blOfflineButton;

/** IPC 四画面：左上角(bottom-right) 离线 Button */
@property (nonatomic, strong) EnlargeClickButton *brOfflineButton;


/** IPC 四画面：左上角(top-left) 添加设备 Button */
@property (nonatomic, strong) EnlargeClickButton *tlAddDevButton;

/** IPC 四画面：右上角(top-right) 添加设备 Button */
@property (nonatomic, strong) EnlargeClickButton *trAddDevButton;

/** IPC 四画面：左下角(bottom-left) 添加设备 Button */
@property (nonatomic, strong) EnlargeClickButton *blAddDevButton;

/** IPC 四画面：右下角(bottom-right) 添加设备 Button */
@property (nonatomic, strong) EnlargeClickButton *brAddDevButton;


/** IPC 四画面：左上角(top-left) 删除设备 Button */
@property (nonatomic, strong) EnlargeClickButton *tlDeleteDevButton;

/** IPC 四画面：右上角(top-right) 删除设备 Button */
@property (nonatomic, strong) EnlargeClickButton *trDeleteDevButton;

/** IPC 四画面：左下角(bottom-left) 删除设备 Button */
@property (nonatomic, strong) EnlargeClickButton *blDeleteDevButton;

/** IPC 四画面：右下角(bottom-right) 删除设备 Button */
@property (nonatomic, strong) EnlargeClickButton *brDeleteDevButton;


/** IPC 四画面设备列表 */
@property (nonatomic, strong) UITableView *devListTableView;


@end

@implementation IpcFourPlayView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.tlPlayView        = [[UIView alloc] init];
        self.trPlayView        = [[UIView alloc] init];
        self.blPlayView        = [[UIView alloc] init];
        self.brPlayView        = [[UIView alloc] init];
        
        self.tlActivity        = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.trActivity        = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.blActivity        = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.brActivity        = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        
        self.tlOfflineButton   = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.trOfflineButton   = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.blOfflineButton   = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.brOfflineButton   = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        
        self.tlAddDevButton    = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.trAddDevButton    = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.blAddDevButton    = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.brAddDevButton    = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        
        self.tlDeleteDevButton = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.trDeleteDevButton = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.blDeleteDevButton = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        self.brDeleteDevButton = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        
        self.devListTableView  = [[UITableView alloc] init];
        
        self.tlOfflineButton.hidden   = YES;
        self.trOfflineButton.hidden   = YES;
        self.blOfflineButton.hidden   = YES;
        self.brOfflineButton.hidden   = YES;
        
        self.tlActivity.hidden        = YES;
        self.trActivity.hidden        = YES;
        self.blActivity.hidden        = YES;
        self.brActivity.hidden        = YES;
        
        self.tlAddDevButton.hidden    = YES;
        
        self.tlDeleteDevButton.hidden = YES;
        self.trDeleteDevButton.hidden = YES;
        self.blDeleteDevButton.hidden = YES;
        self.brDeleteDevButton.hidden = YES;
        
        self.devListTableView.hidden  = YES;
        
        
        [self.tlOfflineButton setTitle:DPLocalizedString(@"Play_Ipc_unonline")
                              forState:UIControlStateNormal];
        [self.trOfflineButton setTitle:DPLocalizedString(@"Play_Ipc_unonline")
                              forState:UIControlStateNormal];
        [self.blOfflineButton setTitle:DPLocalizedString(@"Play_Ipc_unonline")
                              forState:UIControlStateNormal];
        [self.brOfflineButton setTitle:DPLocalizedString(@"Play_Ipc_unonline")
                              forState:UIControlStateNormal];
        
        [self.tlAddDevButton setTitle:DPLocalizedString(@"ADDDevice")
                             forState:UIControlStateNormal];
        [self.trAddDevButton setTitle:DPLocalizedString(@"ADDDevice")
                             forState:UIControlStateNormal];
        [self.blAddDevButton setTitle:DPLocalizedString(@"ADDDevice")
                             forState:UIControlStateNormal];
        [self.brAddDevButton setTitle:DPLocalizedString(@"ADDDevice")
                             forState:UIControlStateNormal];
        
        [self.tlDeleteDevButton setTitle:DPLocalizedString(@"Setting_DeleteDevice")
                                forState:UIControlStateNormal];
        [self.trDeleteDevButton setTitle:DPLocalizedString(@"Setting_DeleteDevice")
                                forState:UIControlStateNormal];
        [self.blDeleteDevButton setTitle:DPLocalizedString(@"Setting_DeleteDevice")
                                forState:UIControlStateNormal];
        [self.brDeleteDevButton setTitle:DPLocalizedString(@"Setting_DeleteDevice")
                                forState:UIControlStateNormal];
        
        [self.tlOfflineButton setTitleColor:[UIColor whiteColor]
                                   forState:UIControlStateNormal];
        [self.trOfflineButton setTitleColor:[UIColor whiteColor]
                                   forState:UIControlStateNormal];
        [self.blOfflineButton setTitleColor:[UIColor whiteColor]
                                   forState:UIControlStateNormal];
        [self.brOfflineButton setTitleColor:[UIColor whiteColor]
                                   forState:UIControlStateNormal];
        
        [self.tlAddDevButton setTitleColor:[UIColor whiteColor]
                                  forState:UIControlStateNormal];
        [self.trAddDevButton setTitleColor:[UIColor whiteColor]
                                  forState:UIControlStateNormal];
        [self.blAddDevButton setTitleColor:[UIColor whiteColor]
                                  forState:UIControlStateNormal];
        [self.brAddDevButton setTitleColor:[UIColor whiteColor]
                                  forState:UIControlStateNormal];
        
        [self.tlDeleteDevButton setTitleColor:[UIColor whiteColor]
                                     forState:UIControlStateNormal];
        [self.trDeleteDevButton setTitleColor:[UIColor whiteColor]
                                     forState:UIControlStateNormal];
        [self.blDeleteDevButton setTitleColor:[UIColor whiteColor]
                                     forState:UIControlStateNormal];
        [self.brDeleteDevButton setTitleColor:[UIColor whiteColor]
                                     forState:UIControlStateNormal];
        
        self.backgroundColor                   = [UIColor whiteColor];
        self.devListTableView.backgroundColor  = DEV_LIST_CELL_BG_COLOR;
        
        self.tlPlayView.backgroundColor        = [UIColor blackColor];
        self.trPlayView.backgroundColor        = [UIColor blackColor];
        self.blPlayView.backgroundColor        = [UIColor blackColor];
        self.brPlayView.backgroundColor        = [UIColor blackColor];
        
        self.tlOfflineButton.backgroundColor   = [UIColor blackColor];
        self.trOfflineButton.backgroundColor   = [UIColor blackColor];
        self.blOfflineButton.backgroundColor   = [UIColor blackColor];
        self.brOfflineButton.backgroundColor   = [UIColor blackColor];
        
        self.tlAddDevButton.backgroundColor    = [UIColor redColor];
        self.trAddDevButton.backgroundColor    = [UIColor redColor];
        self.blAddDevButton.backgroundColor    = [UIColor redColor];
        self.brAddDevButton.backgroundColor    = [UIColor redColor];
        
        self.tlDeleteDevButton.backgroundColor = [UIColor redColor];
        self.trDeleteDevButton.backgroundColor = [UIColor redColor];
        self.blDeleteDevButton.backgroundColor = [UIColor redColor];
        self.brDeleteDevButton.backgroundColor = [UIColor redColor];
        
        
        
        [self.tlOfflineButton addTarget:self
                                 action:@selector(tlOfflineBtnAction)
                       forControlEvents:UIControlEventTouchUpInside];
        [self.trOfflineButton addTarget:self
                                 action:@selector(trOfflineBtnAction)
                       forControlEvents:UIControlEventTouchUpInside];
        [self.blOfflineButton addTarget:self
                                 action:@selector(blOfflineBtnAction)
                       forControlEvents:UIControlEventTouchUpInside];
        [self.brOfflineButton addTarget:self
                                 action:@selector(brOfflineBtnAction)
                       forControlEvents:UIControlEventTouchUpInside];
        
        [self.tlAddDevButton addTarget:self
                                action:@selector(tlAddDevBtnAction)
                      forControlEvents:UIControlEventTouchUpInside];
        [self.trAddDevButton addTarget:self
                                action:@selector(trAddDevBtnAction)
                      forControlEvents:UIControlEventTouchUpInside];
        [self.blAddDevButton addTarget:self
                                action:@selector(blAddDevBtnAction)
                      forControlEvents:UIControlEventTouchUpInside];
        [self.brAddDevButton addTarget:self
                                action:@selector(brAddDevBtnAction)
                      forControlEvents:UIControlEventTouchUpInside];
        
        [self.tlDeleteDevButton addTarget:self
                                   action:@selector(tlDeleteDevBtnAction)
                         forControlEvents:UIControlEventTouchUpInside];
        [self.trDeleteDevButton addTarget:self
                                   action:@selector(trDeleteDevBtnAction)
                         forControlEvents:UIControlEventTouchUpInside];
        [self.blDeleteDevButton addTarget:self
                                   action:@selector(blDeleteDevBtnAction)
                         forControlEvents:UIControlEventTouchUpInside];
        [self.brDeleteDevButton addTarget:self
                                   action:@selector(brDeleteDevBtnAction)
                         forControlEvents:UIControlEventTouchUpInside];
        
        
        [self addSubview:self.tlPlayView];
        [self addSubview:self.trPlayView];
        [self addSubview:self.blPlayView];
        [self addSubview:self.brPlayView];
        
        [self configTableView];
        [self addSubview:self.devListTableView];
        
        [self.tlPlayView addSubview:self.tlActivity];
        [self.trPlayView addSubview:self.trActivity];
        [self.blPlayView addSubview:self.blActivity];
        [self.brPlayView addSubview:self.brActivity];
        
        [self.tlPlayView addSubview:self.tlOfflineButton];
        [self.trPlayView addSubview:self.trOfflineButton];
        [self.blPlayView addSubview:self.blOfflineButton];
        [self.brPlayView addSubview:self.brOfflineButton];
        
        [self.tlPlayView addSubview:self.tlAddDevButton];
        [self.trPlayView addSubview:self.trAddDevButton];
        [self.blPlayView addSubview:self.blAddDevButton];
        [self.brPlayView addSubview:self.brAddDevButton];
        
        [self.tlPlayView addSubview:self.tlDeleteDevButton];
        [self.trPlayView addSubview:self.trDeleteDevButton];
        [self.blPlayView addSubview:self.blDeleteDevButton];
        [self.brPlayView addSubview:self.brDeleteDevButton];
        
        self.addedDevArray = [[NSMutableArray alloc] initWithCapacity:5];
        for (int i = 0; i < 5; i++)
        {
            _isAddDevice[i] = 1 == i ? YES : NO;
            _isHiddenBtn[i] = 1 == i ? YES : NO;
            [self.addedDevArray addObject:[[DeviceDataModel alloc] init]];
        }
        
    }
    return self;
}


- (void)layoutSubviews
{
    self.devListTableView.frame   = CGRectMake(0, 0, 0.5 * HALF_WIDTH, self.bounds.size.height);
    
    self.tlPlayView.frame         = CGRectMake(0, 0, HALF_WIDTH, HALF_HEIGHT);
    self.trPlayView.frame         = CGRectMake(HALF_WIDTH + 2, 0, HALF_WIDTH, HALF_HEIGHT);
    self.blPlayView.frame         = CGRectMake(0, HALF_HEIGHT + 2, HALF_WIDTH, HALF_HEIGHT);
    self.brPlayView.frame         = CGRectMake(HALF_WIDTH + 2, HALF_HEIGHT + 2, HALF_WIDTH, HALF_HEIGHT);
    
    self.tlOfflineButton.frame    = CGRectMake(0, 0, RELOAD_BTN_WIDTH, RELOAD_BTN_HEIGHT);
    self.trOfflineButton.frame    = CGRectMake(0, 0, RELOAD_BTN_WIDTH, RELOAD_BTN_HEIGHT);
    self.blOfflineButton.frame    = CGRectMake(0, 0, RELOAD_BTN_WIDTH, RELOAD_BTN_HEIGHT);
    self.brOfflineButton.frame    = CGRectMake(0, 0, RELOAD_BTN_WIDTH, RELOAD_BTN_HEIGHT);
    
    self.tlAddDevButton.frame     = CGRectMake(0, 0, RELOAD_BTN_WIDTH, RELOAD_BTN_HEIGHT);
    self.trAddDevButton.frame     = CGRectMake(0, 0, RELOAD_BTN_WIDTH, RELOAD_BTN_HEIGHT);
    self.blAddDevButton.frame     = CGRectMake(0, 0, RELOAD_BTN_WIDTH, RELOAD_BTN_HEIGHT);
    self.brAddDevButton.frame     = CGRectMake(0, 0, RELOAD_BTN_WIDTH, RELOAD_BTN_HEIGHT);
    
    self.tlDeleteDevButton.frame  = CGRectMake(0, 0, RELOAD_BTN_WIDTH, RELOAD_BTN_HEIGHT);
    self.trDeleteDevButton.frame  = CGRectMake(0, 0, RELOAD_BTN_WIDTH, RELOAD_BTN_HEIGHT);
    self.blDeleteDevButton.frame  = CGRectMake(0, 0, RELOAD_BTN_WIDTH, RELOAD_BTN_HEIGHT);
    self.brDeleteDevButton.frame  = CGRectMake(0, 0, RELOAD_BTN_WIDTH, RELOAD_BTN_HEIGHT);
    
    
    self.tlActivity.center        = CGPointMake(CGRectGetMidX(self.tlPlayView.bounds),
                                                CGRectGetMidY(self.tlPlayView.bounds));
    self.trActivity.center        = CGPointMake(CGRectGetMidX(self.trPlayView.bounds),
                                                CGRectGetMidY(self.trPlayView.bounds));
    self.blActivity.center        = CGPointMake(CGRectGetMidX(self.blPlayView.bounds),
                                                CGRectGetMidY(self.blPlayView.bounds));
    self.brActivity.center        = CGPointMake(CGRectGetMidX(self.brPlayView.bounds),
                                                CGRectGetMidY(self.brPlayView.bounds));
    
    self.tlOfflineButton.center   = CGPointMake(CGRectGetMidX(self.tlPlayView.bounds),
                                                CGRectGetMidY(self.tlPlayView.bounds));
    self.trOfflineButton.center   = CGPointMake(CGRectGetMidX(self.trPlayView.bounds),
                                                CGRectGetMidY(self.trPlayView.bounds));
    self.blOfflineButton.center   = CGPointMake(CGRectGetMidX(self.blPlayView.bounds),
                                                CGRectGetMidY(self.blPlayView.bounds));
    self.brOfflineButton.center   = CGPointMake(CGRectGetMidX(self.brPlayView.bounds),
                                                CGRectGetMidY(self.brPlayView.bounds));
    
    self.tlAddDevButton.center    = CGPointMake(CGRectGetMidX(self.tlPlayView.bounds),
                                                CGRectGetMidY(self.tlPlayView.bounds));
    self.trAddDevButton.center    = CGPointMake(CGRectGetMidX(self.trPlayView.bounds),
                                                CGRectGetMidY(self.trPlayView.bounds));
    self.blAddDevButton.center    = CGPointMake(CGRectGetMidX(self.blPlayView.bounds),
                                                CGRectGetMidY(self.blPlayView.bounds));
    self.brAddDevButton.center    = CGPointMake(CGRectGetMidX(self.brPlayView.bounds),
                                                CGRectGetMidY(self.brPlayView.bounds));
    
    self.tlDeleteDevButton.center = CGPointMake(CGRectGetMidX(self.tlPlayView.bounds),
                                                CGRectGetMidY(self.tlPlayView.bounds));
    self.trDeleteDevButton.center = CGPointMake(CGRectGetMidX(self.trPlayView.bounds),
                                                CGRectGetMidY(self.trPlayView.bounds));
    self.blDeleteDevButton.center = CGPointMake(CGRectGetMidX(self.blPlayView.bounds),
                                                CGRectGetMidY(self.blPlayView.bounds));
    self.brDeleteDevButton.center = CGPointMake(CGRectGetMidX(self.brPlayView.bounds),
                                                CGRectGetMidY(self.brPlayView.bounds));
}


- (void)dealloc
{
    NSLog(@"----------- IpcFourPlayView dealloc -----------");
}


- (NSMutableArray<DeviceDataModel *> *)devListArray
{
    if (!_devListArray)
    {
        _devListArray = [NSMutableArray arrayWithCapacity:0];
    }
    return _devListArray;
}


- (void)configTableView
{
    self.devListTableView.delegate       = self;
    self.devListTableView.dataSource     = self;
    self.devListTableView.rowHeight      = IPC_FOUR_VIEW_LIST_CELL_HEIGHT;
    self.devListTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}


#pragma mark -- 设置 NVR play view 边框颜色：红色
- (void)configBorderColor:(UIColor *)color
              borderWidth:(CGFloat)width
               OnPosition:(PositionType)position
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法设置边框颜色！");
            return ;
        }
        switch (position)
        {
            case PositionTopLeft:        // 左上角
            {
                strongSelf.tlPlayView.layer.borderWidth = width;
                strongSelf.tlPlayView.layer.borderColor = [color CGColor];
            }
                break;
                
            case PositionTopRight:       // 右上角
            {
                strongSelf.trPlayView.layer.borderWidth = width;
                strongSelf.trPlayView.layer.borderColor = [color CGColor];
            }
                break;
                
            case PositionBottomLeft:     // 左下角
            {
                strongSelf.blPlayView.layer.borderWidth = width;
                strongSelf.blPlayView.layer.borderColor = [color CGColor];
            }
                break;
                
            case PositionBottomRight:    // 右下角
            {
                strongSelf.brPlayView.layer.borderWidth = width;
                strongSelf.brPlayView.layer.borderColor = [color CGColor];
            }
                break;
                
            default:
                break;
        }
    });
}


#pragma mark -- 配置边框是否显示
- (void)configBorderHidden:(BOOL)isHidden
                onPosition:(PositionType)position
{
    if (NO == isHidden)
    {
        for (int i = PositionTopLeft; i <= PositionBottomRight; i++)
        {
            [self configBorderColor:position == i ? [UIColor colorWithRed:47.0f/255.0f
                                                                    green:158.0f/255.0f
                                                                     blue:218.0f/255.0f
                                                                    alpha:1.0f] : [UIColor blackColor]
                        borderWidth:2.0f
                         OnPosition:i];
        }
    }
    else
    {
        for (int i = PositionTopLeft; i <= PositionBottomRight; i++)
        {
            [self configBorderColor:[UIColor blackColor]
                        borderWidth:2.0f
                         OnPosition:i];
        }
    }
}


- (void)autoHiddenBorderOnPosition:(NSNumber *)position
{
    [self configBorderHidden:YES
                  onPosition:[position integerValue]];
}


#pragma mark - Public
#pragma mark -- 开启 Activity 动画
- (void)startActivityOnPosition:(PositionType)positionType
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
                strongSelf.tlActivity.hidden = NO;
                [strongSelf.tlActivity startAnimating];
            }
                break;
                
            case PositionTopRight:      // 右上角
            {
                strongSelf.trActivity.hidden = NO;
                [strongSelf.trActivity startAnimating];
            }
                break;
                
            case PositionBottomLeft:    // 左下角
            {
                strongSelf.blActivity.hidden = NO;
                [strongSelf.blActivity startAnimating];
            }
                break;
                
            case PositionBottomRight:   // 右下角
            {
                strongSelf.brActivity.hidden = NO;
                [strongSelf.brActivity startAnimating];
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
- (void)stopActivityOnPosition:(PositionType)positionType
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
                [strongSelf.tlActivity stopAnimating];
                strongSelf.tlActivity.hidden = YES;
            }
                break;
                
            case PositionTopRight:      // 右上角
            {
                [strongSelf.trActivity stopAnimating];
                strongSelf.trActivity.hidden = YES;
            }
                break;
                
            case PositionBottomLeft:    // 左下角
            {
                [strongSelf.blActivity stopAnimating];
                strongSelf.blActivity.hidden = YES;
            }
                break;
                
            case PositionBottomRight:   // 右下角
            {
                [strongSelf.brActivity stopAnimating];
                strongSelf.brActivity.hidden = YES;
            }
                break;
                
            default:
            {
                
            }
                break;
        }
    });
}


#pragma mark -- 设置‘添加设备’按钮是否隐藏
- (void)configAddDevBtnHidden:(BOOL)isHidden
                   onPosition:(PositionType)positionType
{
    _isHiddenBtn[positionType] = isHidden;
    
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
                strongSelf.tlAddDevButton.hidden = isHidden;
            }
                break;
                
            case PositionTopRight:      // 右上角
            {
                strongSelf.trAddDevButton.hidden = isHidden;
            }
                break;
                
            case PositionBottomLeft:    // 左下角
            {
                strongSelf.blAddDevButton.hidden = isHidden;
            }
                break;
                
            case PositionBottomRight:   // 右下角
            {
                strongSelf.brAddDevButton.hidden = isHidden;
            }
                break;
                
            default:
            {
                
            }
                break;
        }
    });
}


#pragma mark -- 设置‘删除设备’按钮是否隐藏
- (void)configDeleteDevBtnHidden:(BOOL)isHidden
                      onPosition:(PositionType)positionType
{
    _isHiddenBtn[positionType] = isHidden;
    
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
                strongSelf.tlDeleteDevButton.hidden = isHidden;
            }
                break;
                
            case PositionTopRight:      // 右上角
            {
                strongSelf.trDeleteDevButton.hidden = isHidden;
            }
                break;
                
            case PositionBottomLeft:    // 左下角
            {
                strongSelf.blDeleteDevButton.hidden = isHidden;
            }
                break;
                
            case PositionBottomRight:   // 右下角
            {
                strongSelf.brDeleteDevButton.hidden = isHidden;
            }
                break;
                
            default:
            {
                
            }
                break;
        }
    });
}


- (void)autoHiddenDeleteBtnOnPosition:(NSNumber *)positionTypeNum
{
    [self configDeleteDevBtnHidden:YES
                        onPosition:[positionTypeNum integerValue]];
}


#pragma mark -- 设置‘离线’按钮是否隐藏
- (void)configOfflineBtnHidden:(BOOL)isHidden
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
                strongSelf.tlOfflineButton.hidden = isHidden;
            }
                break;
                
            case PositionTopRight:      // 右上角
            {
                strongSelf.trOfflineButton.hidden = isHidden;
            }
                break;
                
            case PositionBottomLeft:    // 左下角
            {
                strongSelf.blOfflineButton.hidden = isHidden;
            }
                break;
                
            case PositionBottomRight:   // 右下角
            {
                strongSelf.brOfflineButton.hidden = isHidden;
            }
                break;
                
            default:
            {
                
            }
                break;
        }
    });
}


#pragma mark - 手势点击
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
    [self configTableViewHidden:YES];
    
    CGRect topLeftViewFrame     = self.tlPlayView.frame;
    CGRect topRightViewFrame    = self.trPlayView.frame;
    CGRect bottomLeftViewFrame  = self.blPlayView.frame;
    CGRect bottomRightViewFrame = self.brPlayView.frame;
    
    PositionType positionType = PositionTopLeft;
    if (CGRectContainsPoint(topLeftViewFrame, _singleTapLocation))            // 进入 top left view
    {
        NSLog(@"进入 IPC: Top Left 播放页面！");
        positionType = PositionTopLeft;
    }
    else if (CGRectContainsPoint(topRightViewFrame, _singleTapLocation))      // 进入 top right view
    {
        NSLog(@"进入 IPC: Top Right 播放页面！");
        positionType = PositionTopRight;
    }
    else if (CGRectContainsPoint(bottomLeftViewFrame, _singleTapLocation))    // 进入 bottom left view
    {
        NSLog(@"进入 IPC: Bottom Left 播放页面！");
        positionType = PositionBottomLeft;
    }
    else if (CGRectContainsPoint(bottomRightViewFrame, _singleTapLocation))   // 进入 bottom right view
    {
        NSLog(@"进入 IPC: Bottom Right 播放页面！");
        positionType = PositionBottomRight;
    }
    else
    {
        NSLog(@"进入 IPC: Top Left 播放页面！");
        positionType = PositionTopLeft;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(autoHiddenBorderOnPosition:)
                                               object:[NSNumber numberWithInteger:_lastPosition]];
    [self performSelector:@selector(autoHiddenBorderOnPosition:)
               withObject:[NSNumber numberWithInteger:positionType]
               afterDelay:AUTO_HIDDEN_BTN_DURATION * 2];
    
    [self configBorderHidden:NO
                  onPosition:positionType];
    _lastPosition = positionType;
    
    if (NO == _isAddDevice[positionType])   // 该画面位置没有添加设备
    {
        return;
    }
    if (TapCountSingle == tapCountStyle)        // 单击
    {
        NSInteger addDevCount = 0;
        for (NSInteger i = PositionTopLeft; i <=PositionBottomRight ; i++)
        {
            if (YES == _isAddDevice[i])
            {
                addDevCount++;
            }
        }
        // 只添加一个设备，不显示‘删除按钮’
        if (1 >= addDevCount)
        {
            return;
        }
        _isHiddenBtn[positionType] = !_isHiddenBtn[positionType];
        
        if (NO == _isHiddenBtn[positionType])
        {
            [NSObject cancelPreviousPerformRequestsWithTarget:self
                                                     selector:@selector(autoHiddenDeleteBtnOnPosition:)
                                                       object:[NSNumber numberWithInteger:positionType]];
            [self performSelector:@selector(autoHiddenDeleteBtnOnPosition:)
                       withObject:[NSNumber numberWithInteger:positionType]
                       afterDelay:AUTO_HIDDEN_BTN_DURATION];
        }
        
        [self configDeleteDevBtnHidden:_isHiddenBtn[positionType]
                            onPosition:positionType];
        
        if (self.delegate
            && [self.delegate respondsToSelector:@selector(singleTapActionOnPosition:)])
        {
            [self.delegate singleTapActionOnPosition:positionType];
        }
    }
    else if (TapCountDouble == tapCountStyle)   // 双击
    {
        if (self.delegate
            && [self.delegate respondsToSelector:@selector(doubleTapActionOnPosition:)])
        {
            [self.delegate doubleTapActionOnPosition:positionType];
        }
    }
}


#pragma mark - ‘离线’按钮事件中心
#pragma mark -- IPC 四画面：左上角(top-left) ‘离线’按钮事件
- (void)tlOfflineBtnAction
{
    NSLog(@"IPC 四画面：左上角(top-left) ‘离线’按钮事件");
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(reconnOnPosition:)])
    {
        [self.delegate reconnOnPosition:PositionTopLeft];
    }
}


#pragma mark -- IPC 四画面：右上角(top-right) ‘离线’按钮事件
- (void)trOfflineBtnAction
{
    NSLog(@"IPC 四画面：右上角(top-right) ‘离线’按钮事件");
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(reconnOnPosition:)])
    {
        [self.delegate reconnOnPosition:PositionTopRight];
    }
}


#pragma mark -- IPC 四画面：左下角(bottom-left) ‘离线’按钮事件
- (void)blOfflineBtnAction
{
    NSLog(@"IPC 四画面：左下角(bottom-left) ‘离线’按钮事件");
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(reconnOnPosition:)])
    {
        [self.delegate reconnOnPosition:PositionBottomLeft];
    }
}


#pragma mark -- IPC 四画面：右下角(bottom-right) ‘离线’按钮事件
- (void)brOfflineBtnAction
{
    NSLog(@"IPC 四画面：右下角(bottom-right) ‘离线’按钮事件");
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(reconnOnPosition:)])
    {
        [self.delegate reconnOnPosition:PositionBottomRight];
    }
}


#pragma mark - ‘添加设备’按钮事件中心
#pragma mark -- IPC 四画面：左上角(top-left) ‘添加设备’按钮事件
- (void)tlAddDevBtnAction
{
    NSLog(@"IPC 四画面：左上角(top-left) ‘添加设备’按钮事件");
    _targetPosition = PositionTopLeft;
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(addDevActionOnPosition:)])
    {
        [self.delegate addDevActionOnPosition:PositionTopLeft];
    }
    
    [self configTableViewHidden:NO];
    [self configBorderHidden:NO
                  onPosition:_targetPosition];
}


#pragma mark -- IPC 四画面：右上角(top-right) ‘添加设备’按钮事件
- (void)trAddDevBtnAction
{
    NSLog(@"IPC 四画面：右上角(top-right) ‘添加设备’按钮事件");
    _targetPosition = PositionTopRight;
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(addDevActionOnPosition:)])
    {
        [self.delegate addDevActionOnPosition:PositionTopRight];
    }
    
    [self configTableViewHidden:NO];
    [self configBorderHidden:NO
                  onPosition:_targetPosition];
}


#pragma mark -- IPC 四画面：左下角(bottom-left) ‘添加设备’按钮事件
- (void)blAddDevBtnAction
{
    NSLog(@"IPC 四画面：左下角(bottom-left) ‘添加设备’按钮事件");
    _targetPosition = PositionBottomLeft;
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(addDevActionOnPosition:)])
    {
        [self.delegate addDevActionOnPosition:PositionBottomLeft];
    }
    
    [self configTableViewHidden:NO];
    [self configBorderHidden:NO
                  onPosition:_targetPosition];
}


#pragma mark -- IPC 四画面：右下角(bottom-right) ‘添加设备’按钮事件
- (void)brAddDevBtnAction
{
    NSLog(@"IPC 四画面：右下角(bottom-right)‘添加设备’按钮事件");
    _targetPosition = PositionBottomRight;
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(addDevActionOnPosition:)])
    {
        [self.delegate addDevActionOnPosition:PositionBottomRight];
    }
    
    [self configTableViewHidden:NO];
    [self configBorderHidden:NO
                  onPosition:_targetPosition];
}


#pragma mark - ‘删除设备’按钮事件中心
#pragma mark -- IPC 四画面：左上角(top-left) ‘删除设备’按钮事件
- (void)tlDeleteDevBtnAction
{
    NSLog(@"IPC 四画面：左上角(top-left) ‘删除设备’按钮事件");
    
    _isAddDevice[PositionTopLeft] = NO;
    
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(deleteDevActionOnPosition:)])
    {
        [self.delegate deleteDevActionOnPosition:PositionTopLeft];
    }
    [self removeAddedTargetOnPosition:PositionTopLeft];
}


#pragma mark -- IPC 四画面：右上角(top-right) ‘删除设备’按钮事件
- (void)trDeleteDevBtnAction
{
    NSLog(@"IPC 四画面：右上角(top-right) ‘删除设备’按钮事件");
    
    _isAddDevice[PositionTopRight] = NO;
    
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(deleteDevActionOnPosition:)])
    {
        [self.delegate deleteDevActionOnPosition:PositionTopRight];
    }
    [self removeAddedTargetOnPosition:PositionTopRight];
}


#pragma mark -- IPC 四画面：左下角(bottom-left) ‘删除设备’按钮事件
- (void)blDeleteDevBtnAction
{
    NSLog(@"IPC 四画面：左下角(bottom-left) ‘删除设备’按钮事件");
    
    _isAddDevice[PositionBottomLeft] = NO;
    
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(deleteDevActionOnPosition:)])
    {
        [self.delegate deleteDevActionOnPosition:PositionBottomLeft];
    }
    [self removeAddedTargetOnPosition:PositionBottomLeft];
}


#pragma mark -- IPC 四画面：右下角(bottom-right) ‘删除设备’按钮事件
- (void)brDeleteDevBtnAction
{
    NSLog(@"IPC 四画面：右下角(bottom-right)‘删除设备’按钮事件");
    
    _isAddDevice[PositionBottomRight] = NO;
    
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(deleteDevActionOnPosition:)])
    {
        [self.delegate deleteDevActionOnPosition:PositionBottomRight];
    }
    [self removeAddedTargetOnPosition:PositionBottomRight];
}


#pragma mark -- 清空已删除设备
- (void)removeAddedTargetOnPosition:(PositionType)position
{
    [self.addedDevArray replaceObjectAtIndex:position
                                  withObject:[[DeviceDataModel alloc] init]];
}


- (void)configTableViewHidden:(BOOL)isHidden
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
       
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法设置 TableView 是否隐藏！");
            return ;
        }
        
        if (NO == isHidden)
        {
            if (YES == strongSelf.devListTableView.hidden)
            {
                strongSelf.devListTableView.hidden = NO;
                [strongSelf.devListTableView reloadData];
            }
        }
        else
        {
            if (NO == strongSelf.devListTableView.hidden)
            {
                strongSelf.devListTableView.hidden = YES;
            }
        }
//        strongSelf.devListTableView.hidden = isHidden;
    });
}


#pragma mark -- 提示信息
- (void)hasAlertMsg:(NSString *)msgStr
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self
                                              animated:YES];
    hud.label.text = msgStr;
    hud.mode = MBProgressHUDModeCustomView;
    hud.removeFromSuperViewOnHide = YES;
    [hud hideAnimated:YES
           afterDelay:1];
}


#pragma mark - TableView delegate && datasource
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    if (self.devListArray)
    {
        return self.devListArray.count;
    }
    else
    {
        return 0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *devListCellId = @"IpcFourViewDevListCellId";
    NSInteger rowIndex = indexPath.row;
    IpcFourViewDevListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:devListCellId];
    if (!cell)
    {
        NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"IpcFourViewDevListTableViewCell"
                                                          owner:self
                                                        options:nil];
        cell = nibArray[0];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (self.devListArray.count > rowIndex)
    {
        DeviceDataModel *devDataModel = [self.devListArray objectAtIndex:rowIndex];
        cell.devListCellData = devDataModel;
//        for (NSInteger pos = PositionTopLeft; pos <= PositionBottomRight; pos++)
//        {
//            if ([devDataModel.DeviceId isEqualToString:[self.addedDevArray objectAtIndex:pos].DeviceId])
//            {
//                [cell configLabelColor:[UIColor redColor]];
//            }
//        }
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger rowIndex = indexPath.row;
    if (rowIndex >= self.devListArray.count)
    {
        return;
    }
    DeviceDataModel *devDataModel = [self.devListArray objectAtIndex:rowIndex];
    if (GosDeviceStatusOnLine != devDataModel.Status)
    {
        [self hasAlertMsg:DPLocalizedString(@"Play_Ipc_unonline")];
        return;
    }
    for (NSInteger pos = PositionTopLeft; pos <= PositionBottomRight; pos++)
    {
        if ([devDataModel.DeviceId isEqualToString:[self.addedDevArray objectAtIndex:pos].DeviceId])
        {
            [self hasAlertMsg:DPLocalizedString(@"IpcFourViewAdded")];
            return;
        }
    }
    NSLog(@"添加设备：%@ 到画面位置：%ld", devDataModel.DeviceName, (long)_targetPosition);
    
    _isAddDevice[_targetPosition] = YES;
    
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(addDevModel:onPostition:)])
    {
        [self.delegate addDevModel:[devDataModel mutableCopy]
                       onPostition:_targetPosition];
    }
    
    [self.addedDevArray replaceObjectAtIndex:_targetPosition
                                  withObject:devDataModel];
    
    [self configTableViewHidden:YES];
    
    [self configAddDevBtnHidden:YES
                     onPosition:_targetPosition];
    
    [self startActivityOnPosition:_targetPosition];
}

@end
