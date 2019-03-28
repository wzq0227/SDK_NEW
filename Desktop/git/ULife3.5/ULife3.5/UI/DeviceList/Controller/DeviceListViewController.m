//
//  DeviceListViewController.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/1.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "DeviceListViewController.h"
#import "DeviceDataModel.h"
#import <MJRefresh/MJRefresh.h>
#import "DeviceListTableViewCell.h"
#import "CBSCommand.h"
#import "NetSDK.h"
#import <MJExtension/MJExtension.h>
#import "EnlargeClickButton.h"
#import "PlayVideoViewController.h"
#import "PreScanQrCodeViewController.h"
#import "DeviceManagement.h"
#import "DevPushManagement.h"
#import "UserDB.h"
#import "NetAPISet.h"
#import <RealReachability.h>
#import "APNSManager.h"
#import "NSTimer+YYAdd.h"
#import "PushVideoViewController.h"
#import "HWLogManager.h"
#import "PanoramaLivePlayerVC.h"
#import "ExperienceCenterViewController.h"
#import "UIColor+YYAdd.h"
#import "Header.h"
#import "APPVersionTool.h"
#import "NvrPlayerViewController.h"
//#import "CloudPlayViewController.h"
#import "Masonry.h"
#import "SettingViewController.h"
#import "GOSLivePlayerVC.h"

#import "APDoorbellChooseDevNameVC.h"
#import "ShareWithFriendsViewController.h"
#import "RecordDateListViewController.h"
#import "PushMsgViewController.h"
#import "AppDelegate.h"

#import "SubDeviceTableViewCell.h"

#import "CloudSDCardViewController.h"
#import "CloudPlayBackViewController.h"

#import "DeviceListTableViewCell_5200.h"
#import "AddStationAndSubDeviceVC.h"

#import "SubDevMotionDetectSettingVC.h"
#import "SubDeviceSettingVC.h"

#import "SaveDataModel.h"
#import "NSObject+YYModel.h"
#import <AFNetworking.h>

#import "GosTFCardViewController.h"

//#import "ConfigurationWiFiViewController.h"

#define EXP_VIDEO_VIEW_HEIGHT 40.0f
#define BTN_VERTICAL_MARGIN 5.0f
#define EXP_VIDEO_VIEW_BOTTOM_MARGIN 25

#define REQ_LIST_TIME_OUT 8.0f

#define SubDeviceCellHeight (40+SCREEN_WIDTH*9/16)
#define StationHeight (40)

/// 全局设备升级提醒
bool gos_firmware_next_time_update = false;

static NSMutableDictionary *statusCacheDict;
static int updateCount = 1;

@interface DeviceListViewController ()
<
UITableViewDelegate,
UITableViewDataSource
>

{
//    int  _selectRowForDoorBell;             //门铃设备在列表中的位置
    BOOL _isNeedUpCovert;                   // 是否需要更新封面
    NSIndexPath *_covertIndexPath;          // 更新封面 NSIdexPath
    DeviceDataModel *_covertDevDataModel;   // 更新封面 cell dataModel
    
    bool cellRefreshedAtIndex[1000];
}

@property (weak, nonatomic) IBOutlet UITableView *deviceListTableView;
@property (weak, nonatomic) IBOutlet UIView *experienceVideoView;
@property (weak, nonatomic) IBOutlet UIButton *addDeviceBtn;
@property (weak, nonatomic) IBOutlet UIButton *experienceVideoBtn;
@property (weak, nonatomic) IBOutlet EnlargeClickButton *closeExperienceBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *experienceViewHeightCponstraints;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *btnVerticalMargin;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ExpVideoViewBottomConstraints;


/**云存储服务是否在有效期内*/
@property(nonatomic,assign) BOOL csValid;

/** 请求CS状态失败 重新请求 */
@property(nonatomic,assign) BOOL requestCSStatusSuccesfully;


/* 是否为国内测试环境 */
@property (nonatomic, assign)  BOOL isDomesticDev;

/**
 设备在线状态缓存字典，这里逻辑比较绕
 */
//@property (strong, nonatomic)NSMutableDictionary *statusCacheDict;


/**
 缓存的视频控制器，主要用于，不在重复重连
 */
@property (nonatomic,weak)GOSLivePlayerVC *cacheVideoVC;

/**
 当前连接device
 */
@property (nonatomic,copy)NSString *currentConnectDevice;

/**
 需要连接数组
 */
@property (nonatomic,strong)NSMutableArray *needConnectArray;

/**
 清理连接定时器
 */
@property (nonatomic,strong)NSTimer *clearTimer;

/**
 连接定时器
 */
@property (nonatomic,strong)NSTimer *connectTimer;


/**
 network check定时器
 */
@property (nonatomic,strong)NSTimer *networkCheckTimer;


@property (nonatomic,assign)NSUInteger networkOfflineTime;

/**
 是否已经弹出没有设备，请添加设备
 */
@property (assign, nonatomic)  BOOL hasShownNoDeviceVC;

@end

static NSString * const kDevListTableViewId = @"devListTableViewIdentifier";
static NSString * const kSubCellIdentifier = @"SubDeviceTableViewCell";
static NSString * const kDevList_5200_CellIdentifier = @"DeviceListTableViewCell_5200";

static NSString * const kGetDevListResp     = @"GetUserDeviceListResponse";
static NSString * const kNotifyDevStatus    = @"NotifyDeviceStatus";


@implementation DeviceListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //3.5 平台推送
    [self registPushToken];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        statusCacheDict = [NSMutableDictionary dictionary];
    });
    
    [self configUI];
    
    [self setRowHeight];
    
    [self setupDeviceTableView];
    
    [self addDeviceStatusNotify];
    
    [self addRefreshListNotify];
    
    [self addUpdateDevNameNotify];
    
    [self addUpdateDevCovertNotify];
    
    [self addClientConnectStatusNotification];
    

    if (updateCount > 0) {
        //获取最新版本 --只会获取一次
        [[APPVersionTool shareInstance] checkVersion];
        updateCount = 0;
    }
    else{
        //直接不操作
    }
    
    

    //放到ViewWillAppear中
    //开启清除定时器
//    [self startClearTimer];
//
//    //开启连接定时器
//    [self startConnectTimer];
    
    self.needConnectArray = [NSMutableArray array];
    
    //添加网络监听
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkChanged:)
                                                 name:kRealReachabilityChangedNotification
                                               object:nil];
    
}

- (void)printToken:(NSString*)token uuid:(NSString*)uuid{
    if ([[SaveDataModel getUserName] isEqualToString:@"1348179538@qq.com"]) {
        ///
        
        self.navigationItem.titleView = [CommonlyUsedFounctions titleLabelWithStr:uuid];
        
        self.addDeviceBtn.titleLabel.numberOfLines = 3;
        self.addDeviceBtn.titleLabel.font = [UIFont systemFontOfSize:11];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.addDeviceBtn setTitle:token forState:0];
        });
    }
}

- (void)registPushToken{
    
    if ([[APNSManager shareManager].deviceToken isKindOfClass:[NSData class]]) {
        
        NSData *deviceToken = [APNSManager shareManager].deviceToken;
        //添加token到服务器
        NSString *tokenString = [NSString stringWithFormat:@"%@",deviceToken];
        tokenString = [tokenString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
        tokenString = [tokenString stringByReplacingOccurrencesOfString:@" "
                                                             withString:@""];
        
        
        //发送Token到自有服务器
        NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
        NSString *uuidStr = [self getUUID];
        NSDictionary *postDict = @{
                                   @"MessageType":@"LoginRequest",
                                   @"Body":
                                       @{
                                           @"Terminal":@"iphone", //终端系统类型
                                           @"Language":@{@"Cur":@"chinese",@"Def":@"chinese"},//终端系统 当前语言  默认语言(服务器端转换语言时 找不到)
                                           @"UserName":[SaveDataModel getUserName],//app就填账户名，dev就填ID
                                           @"Token":tokenString,  //对于APP没有token的就填写mac地址，对于camera写DEVICE ID,token是唯一的
                                           @"AppId":bundleId,//APP唯一表示符号
                                           @"UUID":uuidStr //手机唯一标识
                                           }
                                   };
        
        [self printToken:tokenString uuid:uuidStr];

        [[NetSDK sharedInstance] net_sendCBSRequestWithData:postDict timeout:15000 responseBlock:^(int result, NSDictionary *dict) {
            if (result==0) {
                [DevPushManagement shareDevPushManager].isRegisteToken=YES;
                NSLog(@"-------推送 %d",result);
            }
            else{
                [DevPushManagement shareDevPushManager].isRegisteToken=NO;
                NSLog(@"-------推送 %d",result);
            }
        }];
    }
    
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.translucent = NO;
    
    [self closeExpVideoViewAfterDelay:0];

//    if ([mUserDefaults boolForKey:SHOW_EXP_CENTER]) {
//        [self showEXpVideoView];
//    }else{
//        [self closeExpVideoViewAfterDelay:0];
//    }
    
    [self startClearTimer];
    [self startConnectTimer];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated{
    //去除加载中
    if ([SVProgressHUD isVisible]) {
        [SVProgressHUD dismiss];
    }
    
    [super viewWillDisappear:animated];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopClearTimer];
    [self stopConnectTimer];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    [self stopClearTimer];
    [self stopConnectTimer];
}


- (void)configUI
{
    self.title = DPLocalizedString(@"my_device");

    [self.addDeviceBtn setTitle:DPLocalizedString(@"ADDDevice") forState:0];
    self.addDeviceBtn.backgroundColor = myColor;
    self.experienceVideoView.backgroundColor = UIColorFromRGBA(113, 113, 110, 1);
    [self addbackbtn];
    
    self.experienceVideoBtn.backgroundColor = myColor;
    [self.experienceVideoBtn setTitle:DPLocalizedString(@"ExperienceCenter") forState:UIControlStateNormal];
    self.view.backgroundColor = UIColorFromRGBA(237, 237, 237, 1);
    self.deviceListTableView.backgroundColor = UIColorFromRGBA(237, 237, 237, 1);
    
    self.hasShownNoDeviceVC = NO;
    
    //For DoorBell
    [self hiddenExpVideoView:YES];
}


- (void)addbackbtn
{
    UIImage* img=[UIImage imageNamed:@"user_admin"];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame =CGRectMake(0, 0, 32, 32);
    [btn setBackgroundImage:img forState:UIControlStateNormal];
    [btn addTarget: self action: @selector(presentLeftMenuViewController:) forControlEvents: UIControlEventTouchUpInside];
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    temporaryBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.leftBarButtonItem=temporaryBarButtonItem;
}


- (void)showEXpVideoView
{
    self.experienceViewHeightCponstraints.constant = EXP_VIDEO_VIEW_HEIGHT;
    self.btnVerticalMargin.constant                = BTN_VERTICAL_MARGIN;
    self.ExpVideoViewBottomConstraints.constant    = EXP_VIDEO_VIEW_BOTTOM_MARGIN;
    [self hiddenExpVideoView:NO];
}


- (void)closeExpVideoViewAfterDelay:(CGFloat)delay
{
    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration: delay
                     animations:^{
                         
                         __strong typeof(weakSelf)strongSelf = weakSelf;
                         if (!strongSelf)
                         {
                             return ;
                         }
                         strongSelf.experienceViewHeightCponstraints.constant = 0;
                         strongSelf.btnVerticalMargin.constant                = 0;
                         strongSelf.ExpVideoViewBottomConstraints.constant    = -40;
                         [strongSelf hiddenExpVideoView:YES];
                     }];
    [mUserDefaults setBool:NO forKey:SHOW_EXP_CENTER ];
    [mUserDefaults synchronize];
}


- (void)hiddenExpVideoView:(BOOL)isHidden
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        strongSelf.experienceVideoView.hidden = isHidden;
        strongSelf.experienceVideoBtn.hidden  = isHidden;
        strongSelf.closeExperienceBtn.hidden  = isHidden;
    });
}


- (void)setRowHeight
{
    CGFloat screenWidth  = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    if (screenWidth > screenHeight)
    {
        CGFloat temp = screenWidth;
        screenWidth  = screenHeight;
        screenHeight = temp;
    }
    CGFloat bottomViewHeight = 50;
    CGFloat cellWidth = screenWidth - 33.0f;
    CGFloat cellHeight = (CGFloat)(((CGFloat)9.0f / (CGFloat)16.0f) * (CGFloat)cellWidth);
    self.deviceListTableView.rowHeight = cellHeight + 40.0f + bottomViewHeight + 1;
}

#pragma mark - 清理连接定时器
-(void)startClearTimer
{
    if ( _clearTimer ==nil)
    {
        __weak typeof(self) weakSelf = self;
        self.clearTimer =  [NSTimer yyscheduledTimerWithTimeInterval:5 block:^(NSTimer * _Nonnull timer) {
            weakSelf.currentConnectDevice = nil;
        } repeats:YES];
        [self.clearTimer setFireDate:[NSDate distantPast]];
        [[NSRunLoop mainRunLoop] addTimer:self.clearTimer forMode:NSDefaultRunLoopMode];
    }
}

- (void)stopClearTimer
{
    if (_clearTimer) {
        [_clearTimer invalidate];
        _clearTimer = nil;
    }
}


-(void)startConnectTimer
{
    if ( _connectTimer ==nil)
    {
        __weak typeof(self) weakSelf = self;
        self.connectTimer = [NSTimer yyscheduledTimerWithTimeInterval:1 block:^(NSTimer * _Nonnull timer) {
            //连接一台设备
            [weakSelf connectOneDevice];
        } repeats:YES];
        [self.connectTimer setFireDate:[NSDate distantPast]];
        [[NSRunLoop mainRunLoop] addTimer:self.connectTimer forMode:NSDefaultRunLoopMode];
    }
}


- (void)connectOneDevice{
    if (self.currentConnectDevice || self.deviceListTableView.hidden) {
        return;
    }
    
    if (self.needConnectArray.count == 0 && [self isCurrentViewControllerVisible]) {
        //去除加载中
//        NSLog(@"isViewVisible:%d",self.view.isHidden);
        
        if ([SVProgressHUD isVisible]) {
            [SVProgressHUD dismiss];
        }
    }
    
    for (DeviceDataModel *model in self.needConnectArray) {
        if ([self.cacheVideoVC.deviceModel.DeviceId isEqualToString:model.DeviceId]) {
            //这个不用管了
            continue;
        }
        
        BOOL isConnected = [[NetAPISet sharedInstance] isDeviceConnectedWithUID:[model.DeviceId substringFromIndex:8]];
        if (!isConnected) {
            [self connectClientWithUID:model.DeviceId password:model.StreamPassword];
            self.currentConnectDevice = model.DeviceId;
            return;
        }
    }
}

- (void)stopConnectTimer
{
    if (_connectTimer) {
        [_connectTimer invalidate];
        _connectTimer = nil;
    }
}



-(void)startNetcheckTimer
{
    if ( _networkCheckTimer ==nil)
    {
        __weak typeof(self) weakSelf = self;
        self.networkCheckTimer = [NSTimer yyscheduledTimerWithTimeInterval:1 block:^(NSTimer * _Nonnull timer) {
            //加1秒
            weakSelf.networkOfflineTime += 1;
            if (weakSelf.networkOfflineTime > 15) {
                [weakSelf allOffline];
            }
        } repeats:YES];
        [self.networkCheckTimer setFireDate:[NSDate distantPast]];
        [[NSRunLoop mainRunLoop] addTimer:self.networkCheckTimer forMode:NSDefaultRunLoopMode];
    }
}


- (void)stopNetcheckTimer{
    _networkOfflineTime = 0;
    if (_networkCheckTimer) {
        [_networkCheckTimer invalidate];
        _networkCheckTimer = nil;
    }
}


- (NSString *)getNetWorkStates{
    UIApplication *app = [UIApplication sharedApplication];
    NSArray *children = nil;
    NSString *state = @"无网络";
    
    //iPhone X
    if ([[app valueForKeyPath:@"_statusBar"] isKindOfClass:NSClassFromString(@"UIStatusBar_Modern")]) {
        children = [[[[app valueForKeyPath:@"_statusBar"] valueForKeyPath:@"_statusBar"] valueForKeyPath:@"foregroundView"] subviews];
        for (UIView *view in children) {
            for (id child in view.subviews) {
                //wifi
                if ([child isKindOfClass:NSClassFromString(@"_UIStatusBarWifiSignalView")]) {
                    state = @"wifi";
                }
                //2G 3G 4G
                if ([child isKindOfClass:NSClassFromString(@"_UIStatusBarStringView")]) {
                    if ([[child valueForKey:@"_originalText"] containsString:@"G"]) {
                        state = [child valueForKey:@"_originalText"];
                    }
                }
            }
        }
        if (!state || state.length<=0) {
            state = @"无网络";
        }
    }else {
        children = [[[app valueForKeyPath:@"_statusBar"] valueForKeyPath:@"foregroundView"] subviews];
        for (id child in children) {
            if ([child isKindOfClass:NSClassFromString(@"UIStatusBarDataNetworkItemView")]) {
                //获取到状态栏
                switch ([[child valueForKeyPath:@"dataNetworkType"] intValue]) {
                    case 0:
                        state = @"无网络";
                        //无网模式
                        break;
                    case 1:
                        state = @"2G";
                        break;
                    case 2:
                        state = @"3G";
                        break;
                    case 3:
                        state = @"4G";
                        break;
                    case 5:
                        state = @"wifi";
                        break;
                    default:
                        break;
                }
            }
        }
    }
    //根据状态选择
    return state;
}


#pragma mark -- 添加刷新列表通知
- (void)addRefreshListNotify
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(beginRefreshList)
                                                 name:REFRESH_DEV_LIST_NOTIFY
                                               object:nil];
}


#pragma mark -- 添加设备在线状态通知
- (void)addDeviceStatusNotify
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDeviceStatus:)
                                                 name:kNotifyDevStatus
                                               object:nil];
}


#pragma mark -- 添加修改设备昵称通知
- (void)addUpdateDevNameNotify
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDeviceName:)
                                                 name:UPDATE_DEV_NAME_NOTIFY
                                               object:nil];
}


- (void)updateDeviceName:(NSNotification *)notifyData
{
    DeviceDataModel *deviceModel = notifyData.object;
    NSLog(@"修改设备昵称：%@",deviceModel.DeviceName);
    [[DeviceManagement sharedInstance] updateDeviceModel:deviceModel];
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法更新列表！");
            return ;
        }
        [strongSelf.deviceListTableView reloadData];
    });
}


#pragma mark -- 刷新列表
- (void)beginRefreshList
{
    [self.deviceListTableView.mj_header beginRefreshing];
}


- (void)setupDeviceTableView
{
    [self.deviceListTableView registerNib:[UINib nibWithNibName:NSStringFromClass([DeviceListTableViewCell class])
                                                         bundle:nil]
                   forCellReuseIdentifier:kDevListTableViewId];
    [self.deviceListTableView registerNib:[UINib nibWithNibName:kSubCellIdentifier bundle:nil] forCellReuseIdentifier:kSubCellIdentifier];
    [self.deviceListTableView registerNib:[UINib nibWithNibName:kDevList_5200_CellIdentifier bundle:nil] forCellReuseIdentifier:kDevList_5200_CellIdentifier];
    
    self.deviceListTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    // 删除tableView多余分割线
    [self.deviceListTableView setTableFooterView:[[UIView alloc]initWithFrame:CGRectZero]];
    
    // 头部刷新控件
    if ([self respondsToSelector:@selector(getDeviceList)])
    {
        self.deviceListTableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self
                      refreshingAction:@selector(getDeviceList)];
    }
    [self.deviceListTableView.mj_header beginRefreshing];
}





#pragma mark -- 获取设备列表
- (void)getDeviceList
{
    if ([self isCurrentViewControllerVisible]) {
        //展示加载中
        [SVProgressHUD showWithStatus:DPLocalizedString(@"loading")];
    }
    
//    //MARK: - 禁用点击
//    self.navigationItem.leftBarButtonItem.enabled = NO;
//    self.addDeviceBtn.userInteractionEnabled  = NO;
    
    memset(cellRefreshedAtIndex, 0, sizeof(cellRefreshedAtIndex));
    
    __weak typeof(self) weakSelf = self;
    NSString *userName = [[util sharedInstance] getUsername];
    
    CBS_GetDevListRequest *req  = [CBS_GetDevListRequest new];
    BodyGetDevListRequest *body = [BodyGetDevListRequest new];
    body.UserName = userName;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法获取设备列表！");
            return ;
        }
        
        NSLog(@"发送请求获取设备列表！");
        dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        });
        [[NetSDK sharedInstance] net_sendCBSRequestMsgType:req.MessageType
                                                  bodyData:[body yy_modelToJSONObject]
                                                   timeout:15000
                                             responseBlock:^(int result, NSDictionary *dict)
         {
             if (0 == result)
             {
                 NSLog(@"获取设备列表成功！");
                 // 请求成功
                 if ([[NSNull null] isEqual:dict[@"MessageType"]])
                 {
                     NSLog(@"无法判断信息响应类型!");
                     return ;
                 }
                 NSString *msgType = dict[@"MessageType"];
                 if ([msgType isEqualToString:kGetDevListResp])
                 {
                     if ([[NSNull null] isEqual:dict[@"Body"]]
                         || [[NSNull null] isEqual:dict[@"Body"][@"DeviceList"]])
                     {
                         NSLog(@"无法提取设备列表数据！");
                         return ;
                     }
                     NSMutableArray <DeviceDataModel *>*devArray = [DeviceDataModel mj_objectArrayWithKeyValuesArray:dict[@"Body"][@"DeviceList"]];
                     
                     for (int i = 0; i < devArray.count; i++) {

                         devArray[i].devCapModel = [DeviceCapModel capWithString:devArray[i].DeviceCap];
                     }
                     
                     [strongSelf updateDevlistWithArray:devArray];
                 }
             }
             else if(result == 8888){
                 //超时处理
                 [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"localizied_294")];
                 if (0 >= [[[DeviceManagement sharedInstance] deviceListArray] count])
                 {
                     [[[DeviceManagement sharedInstance] deviceListArray] addObjectsFromArray:[[UserDB sharedInstance] deviceListArray]];
                 }
             }
             else{
                 NSLog(@"获取设备列表失败！");
                 [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"data_unsuceess")];
             }
             [strongSelf.deviceListTableView.mj_header endRefreshing];
             dispatch_async(dispatch_get_main_queue(), ^{
//                 //MARK: - 放开点击
//                 self.navigationItem.leftBarButtonItem.enabled = YES;
//                 self.addDeviceBtn.userInteractionEnabled  = YES;
             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             });
         }];
    });
}


#pragma mark - 自动连接数组处理
- (void)addNeedArrayWithModel:(DeviceDataModel *)model{
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL isConnected = [[NetAPISet sharedInstance] isDeviceConnectedWithUID:(model.DeviceId.length) == 15 ? model.DeviceId : [model.DeviceId substringFromIndex:8]];
        if (isConnected) {
            return;
        }
        
        BOOL isExsit = NO;
        for (DeviceDataModel *dataModel in self.needConnectArray) {
            if ([dataModel.DeviceId isEqualToString:model.DeviceId]) {
                isExsit = YES;
                break;
            }
        }
        if (!isExsit) {
            [self.needConnectArray addObject:model];
        }
    });
    
    
}

- (void)removeNeedArrayWithModel:(DeviceDataModel *)model{
    dispatch_async(dispatch_get_main_queue(), ^{
        DeviceDataModel *tempModel;
        BOOL isExsit = NO;
        for (DeviceDataModel *dataModel in self.needConnectArray) {
            if ([dataModel.DeviceId isEqualToString:model.DeviceId]) {
                isExsit = YES;
                tempModel = model;
                break;
            }
        }
        if (isExsit) {
            [self.needConnectArray removeObject:tempModel];
        }
    });
}

- (void)removeNeedArrayWithDeviceID:(NSString *)deviceID{
    dispatch_async(dispatch_get_main_queue(), ^{
        DeviceDataModel *tempModel;
        for (DeviceDataModel *model in self.needConnectArray) {
            if ([model.DeviceId.length == 15 ? model.DeviceId : [model.DeviceId substringFromIndex:8] isEqualToString:deviceID]) {
                tempModel = model;
                break;
            }
        }
        if (tempModel) {
            [self removeNeedArrayWithModel:tempModel];
        }
    });
}

//连接TUTK
- (void)connectClientWithUID:(NSString *)uid password:(NSString *)password{
    
    NSLog(@"--- 设备列表--- 连接tutk deviceId = %@", uid);
    
    dispatch_queue_t tempQ = dispatch_queue_create("TestTUTK", 0);
    
    NSLog(@"______________________________tempQ:%@",tempQ);
    //异步线程操作
    dispatch_async(tempQ, ^{
        NSString *detailUid = (uid.length == 15) ?uid: [uid substringFromIndex:8];
        [[NetAPISet sharedInstance] addClient:detailUid andpassword:password];
    });
}



- (void)hideDeviceListAndOtherView:(BOOL)hidden{

//    self.addDeviceBtn.hidden = hidden;
//    [self hiddenExpVideoView:hidden];
    
    if (hidden) {
        
        [self.deviceListTableView reloadData];

        
        [[DeviceManagement sharedInstance] removeAllDevModelResult:^(int result) {
            NSLog(@"removeAllDevModelResult:%d",result);
        }];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            if (self.isDomesticDev) {
                AddStationAndSubDeviceVC *addDeviceVC = [AddStationAndSubDeviceVC new];
                [self.navigationController pushViewController:addDeviceVC animated:YES];
//            }else{
//                APDoorbellChooseDevNameVC *vc = [APDoorbellChooseDevNameVC new];
//                vc.isDevListEmpty = YES;
//                [self.navigationController pushViewController:vc animated:YES];
//            }
        });
        
    }else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}




#pragma mark -- 更新设备列表数据
- (void)updateDevlistWithArray:(NSMutableArray <DeviceDataModel *>*)newDevArray
{
    dispatch_async_on_main_queue(^{
       
        if (!newDevArray || newDevArray.count==0)
        {
            NSLog(@"newDevArray = nil ，无法更新列表！");
            
            [[[DeviceManagement sharedInstance] deviceListArray] removeAllObjects];
            
            [self hideDeviceListAndOtherView:YES];
            if ([SVProgressHUD isVisible] && [self isCurrentViewControllerVisible]) {
                [SVProgressHUD dismiss];
            }
            return;
        }
        
        [self hideDeviceListAndOtherView:NO];
        //获取旧的数组
        NSInteger oldArrayCount = [[DeviceManagement sharedInstance] deviceListArray].count;
        NSInteger newArrayCount = newDevArray.count;
        
        
        NSInteger oldIndex      = 0;
        NSInteger newIndesx     = 0;
        BOOL isExist            = NO;
        
        //遍历旧的数组
        for (oldIndex = 0; oldIndex < oldArrayCount; oldIndex++)
        {
            DeviceDataModel *oldModel = [[DeviceManagement sharedInstance] deviceListArray][oldIndex];
            isExist = NO;
            for (newIndesx = 0; newIndesx < newArrayCount; newIndesx++)
            {
                DeviceDataModel *newModel = newDevArray[newIndesx];
                if ([oldModel.DeviceId isEqualToString:newModel.DeviceId])  // 已存在
                {
                    NSLog(@"deviceId = %@ 已存在列表中！", newModel.DeviceId);
                    if (![oldModel.DeviceName isEqualToString:newModel.DeviceName] || oldModel.Status != newModel.Status
                        || ![oldModel.DeviceCap isEqualToString: newModel.DeviceCap] )
                    {
                        NSLog(@"deviceId = %@ 本地缓存需要修改设备昵称！", newModel.DeviceId);
                        [[DeviceManagement sharedInstance] updateDeviceModel:newModel];
                    }
                    [newDevArray removeObjectAtIndex:newIndesx];
                    newArrayCount--;
                    newIndesx--;
                    isExist = YES;
                    break;
                }
            }
            if (NO == isExist)     // 旧数据多余，移除设备
            {
                NSLog(@"deviceId = %@ 旧数据多余！", oldModel.DeviceId);
                [self removePushWithModel:oldModel];    // 移除推送
                [[DeviceManagement sharedInstance] deleteDevcieModel:oldModel];
                oldArrayCount--;
                oldIndex--;
            }
        }
        
        // 新增的设备
        for (int i = 0; i < newDevArray.count; i++)
        {
            DeviceDataModel *newModel = newDevArray[i];
            NSLog(@"deviceId = %@ 新增设备！", newModel.DeviceId);
            [[DeviceManagement sharedInstance] addDeviceModel:newModel];
            [[DeviceManagement sharedInstance] updateDeviceModel:newModel];
            [self addPushWithModel:newModel];       // 打开推送
        }
        
        //排序数组
        NSMutableArray *managerMentArray = [[DeviceManagement sharedInstance] deviceListArray];
        
        //请求回来的状态--以这个为准，刷新状态
        for (DeviceDataModel *dataModel in managerMentArray) {
            NSNumber *statusNum = [NSNumber numberWithInteger:dataModel.Status];
            [statusCacheDict setObject:statusNum forKey:dataModel.DeviceId];
        }
        
        [self sortArrayAndRefresh];
        
//        if ( self.isDomesticDev ) {
            [self getSubDevList];
//        }else{
//            [self.deviceListTableView reloadData];
//            [self handlePush];
//        }
    });
}


//MARK:- 排序刷新
- (void)sortArrayAndRefresh{
    //排序数组
    NSMutableArray *managerMentArray = [[DeviceManagement sharedInstance] deviceListArray];
    //更新缓存状态
    for (DeviceDataModel *dataModel in managerMentArray) {
        NSString *devId = dataModel.DeviceId;
        NSNumber *statusNum = [statusCacheDict objectForKey:devId];
        if ([statusNum isKindOfClass:[NSNumber class]]) {
            dataModel.Status = statusNum.intValue;
        }
        if (dataModel.Status == 1) {
            [self addNeedArrayWithModel:dataModel];
        }
        else{
            [self removeNeedArrayWithModel:dataModel];
        }
    }
    
    //排序
    [managerMentArray sortUsingComparator:^NSComparisonResult(DeviceDataModel *obj1, DeviceDataModel *obj2) {
        int obj1Value = obj1.Status;
        int obj2Value = obj2.Status;
        if (obj1Value == 1) {
            obj1Value = INT_MAX;
        }
        if (obj2Value == 1) {
            obj2Value = INT_MAX;
        }
        return obj1Value < obj2Value;
    }];
    
    
}

- (void)getSubDevList{
    CBS_GetSubDevListRequest *req  = [CBS_GetSubDevListRequest new];
    BodyGetSubDevListRequest *body = [BodyGetSubDevListRequest new];
    body.UserName = [SaveDataModel getUserName];
    
    __weak typeof(self) wSelf = self;
    [[NetSDK sharedInstance] net_sendCBSRequestMsgType:req.MessageType
                                              bodyData:[body yy_modelToJSONObject]
                                               timeout:8000
                                         responseBlock:^(int result, NSDictionary *dict)
     {
         __strong typeof(wSelf) strongSelf = wSelf;
         if (result == 0) {
             
             CBS_GetSubDevListResponse *resp = [CBS_GetSubDevListResponse yy_modelWithDictionary:dict];
             
             NSMutableArray *devicesArray = [[DeviceManagement sharedInstance] deviceListArray];
             
             for (DeviceDataModel *devModel in devicesArray) {
                 NSMutableArray *subDevices = [NSMutableArray arrayWithCapacity:1];

                 for (NSDictionary *tempDict in resp.Body.SubDevList) {
                     
                     SubDevInfoModel *info = [SubDevInfoModel yy_modelWithDictionary:tempDict];
                     if ([info.DeviceId isEqualToString: devModel.DeviceId]) {
                         [subDevices addObject:info];
                     }
                 }
                 [subDevices sortUsingComparator:^NSComparisonResult(SubDevInfoModel   * _Nonnull obj1, SubDevInfoModel   * _Nonnull obj2) {
                     if (obj1.Status == obj2.Status) {
                         return [obj1.ChanName compare: obj2.ChanName];
                     }else{
                         return obj2.Status - obj1.Status;
                     }
                 }];
                 devModel.SubDevice = subDevices;
             }
         }
         
         dispatch_async_on_main_queue(^{
             [strongSelf.deviceListTableView reloadData];
             [self handlePush];
         });
     }];
}

- (void)handlePush{
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        __weak  DeviceListViewController * weakself = self;
        PushMessageModel *pushDeviceModel = [APNSManager shareManager].pushDeviceModel;

        //不在显示 return
        if (![pushDeviceModel.deviceId isKindOfClass:[NSString class]]) {
            return;
        }
        NSString *pushDevId = pushDeviceModel.deviceId;
        
        if ([pushDevId isKindOfClass:[NSString class]]) {
            NSMutableArray *deviceArray = [DeviceManagement sharedInstance].deviceListArray;
            

            
            for (DeviceDataModel *aDevModel in deviceArray) {
                if ([aDevModel.DeviceId isEqualToString:pushDevId]) {
                    
                    for (SubDevInfoModel *subInfo in aDevModel.SubDevice) {
                        if ([subInfo.SubId isEqualToString: pushDeviceModel.subDeviceID] || subInfo.ChanNum== pushDeviceModel.subChannel ) {
                            aDevModel.selectedSubDevInfo = subInfo;
                            break;
                        }
                    }
                    
                    if ([APNSManager shareManager].isPushLaunch) {
                        
                        [APNSManager shareManager].isPushLaunch = NO;
                        // 根据channel更新subDevID 若子设备不存在subDevID
                        for (SubDevInfoModel * subInfo in aDevModel.SubDevice) {
                            if ( pushDeviceModel.subChannel>=0  && pushDeviceModel.subChannel == subInfo.ChanNum) {
                                pushDeviceModel.subDeviceID = subInfo.SubId;
                                pushDeviceModel.deviceName = subInfo.ChanName;
                                break;
                            }
                        }
                    }
                    
                    PushVideoViewController *playVideoVC = [[PushVideoViewController alloc] init];
                    if (playVideoVC)
                    {
                        playVideoVC.pushModel = pushDeviceModel;
                        playVideoVC.md = aDevModel;
                        //block 回调
                        playVideoVC.playbock=^(NSString * str){
                            for (DeviceDataModel *model in deviceArray)
                            {
                                if ([model.DeviceId isEqualToString:str])
                                {
                                    //
                                    if (pushDeviceModel.apnsMsgType == APNSMsgBellRing &&[self isBellRingEventRealWithTime:[self timeWithTimeStr:pushDeviceModel.pushTime]]  ) {
                                        GOSLivePlayerVC *playerVC = [[GOSLivePlayerVC alloc] init];
                                        playerVC.deviceModel = aDevModel;
                                        [self.navigationController pushViewController:playerVC animated:YES];
                                    }else{
                                        [self getCSStatusWithDevID:model.DeviceId];
                                    }
                                    break;
                                }
                            }
                        };
                        [self presentViewController:playVideoVC animated:YES completion:nil];
                    }
                    break;
                }
            }
        };
    });
}

//按铃是否是18S以内发生的实时事件
- (BOOL)isBellRingEventRealWithTime:(NSTimeInterval)alarmEventTime{
    BOOL isReal = NO;

    NSDate *date = [NSDate date];
    NSTimeInterval curTime = [date timeIntervalSince1970];
    NSLog(@"isBellRingEventRealWithTime:%f",curTime - alarmEventTime );
    
    isReal = curTime - alarmEventTime < 18;
    return isReal;
}


- (void)getCSStatusWithDevID:(NSString*)devID{
    
    [SVProgressHUD showWithStatus:@"Loading..."];
    
    NSString *getUrl = [NSString stringWithFormat:@"http://%@/api/cloudstore/cloudstore-service/service/data-valid",kCloud_IP];
    [[AFHTTPSessionManager manager] GET:getUrl parameters:@{@"token" : [mUserDefaults objectForKey:USER_TOKEN],@"device_id" :devID ,@"username":[SaveDataModel getUserName],@"version":@"1.0" } progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //获取套餐时长数据
        NSArray *dataArray = responseObject[@"data"];
        if ([dataArray isKindOfClass:[NSArray class]]) {
            if (dataArray.count >0) {
                self.csValid = YES;
            }
            else{
                self.csValid = NO;
            }
        }
        else{
            self.csValid = NO;
        }
        self.requestCSStatusSuccesfully = YES;
        [self showOperationResult];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        //TODO:添加重新加载按钮
        self.requestCSStatusSuccesfully = NO;
        [self showOperationResult];
    }];
}

- (void)showOperationResult{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.requestCSStatusSuccesfully) {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"network_error")];
            return ;
        }else{
            [SVProgressHUD dismiss];
        }
        
        PushMessageModel *pushModel = [APNSManager shareManager].pushDeviceModel;
        NSTimeInterval time = [self timeWithTimeStr: pushModel.pushTime];
        DeviceDataModel *devModel = [self getCurDevModelWithPushMsg:pushModel];
        

        if (!devModel) {
            return;
        }
        
        if (self.csValid) {//CS
            CloudPlayBackViewController *vc = [CloudPlayBackViewController new];
            vc.deviceModel                  = devModel;
            vc.alarmMsgTime                 = time;
            [self.navigationController pushViewController:vc animated:YES];
        }else{//TF
            CloudSDCardViewController *vc   = [CloudSDCardViewController new];
            vc.deviceModel                  = devModel;
            vc.alarmMsgTime                 = time;
            [self.navigationController pushViewController:vc animated:YES];
        }
        
        [APNSManager shareManager].pushDeviceModel = nil; //置空
    });
}

- (NSTimeInterval)timeWithTimeStr:(NSString*)timeStr{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [format setTimeZone:[NSTimeZone defaultTimeZone]];
    NSDate *date = [format dateFromString:timeStr];
    
    return [date timeIntervalSince1970];
}

-(DeviceDataModel*)getCurDevModelWithPushMsg:(PushMessageModel*)pushMsg{
    for (DeviceDataModel *dataModel in [[DeviceManagement sharedInstance] deviceListArray]) {
        if ([dataModel.DeviceId isEqualToString:pushMsg.deviceId]) {
            return dataModel;
        }
    }
    return nil;
}


#pragma mark -- 添加推送
- (void)addPushWithModel:(DeviceDataModel *)devModel
{
    //先去读状态
    if ([[DevPushManagement shareDevPushManager] isOpenPushWithDeviceId:devModel.DeviceId]) {
        //如果设置的打开，就去打开 否则不去处理
        [[DevPushManagement shareDevPushManager] openPushWithDeviceId:devModel.DeviceId
                                                          resultBlock:^(BOOL isSuccess)
         {
             if (NO == isSuccess)
             {
                 NSLog(@"新添加设备 deviceId = %@ ，打开推送失败！", devModel.DeviceId);
             }
             else
             {
                 NSLog(@"新添加设备 deviceId = %@ ，打开推送成功！", devModel.DeviceId);
             }
         }];
    }
}


#pragma mark -- 移除推送
- (void)removePushWithModel:(DeviceDataModel *)devModel
{
    [[DevPushManagement shareDevPushManager] deletePushWithDeviceId:devModel.DeviceId
                                                        resultBlock:^(BOOL isSuccess)
     {
         if (NO == isSuccess)
         {
             NSLog(@"移除旧设备 deviceId = %@ ，移除推送失败！", devModel.DeviceId);
         }
         else
         {
             NSLog(@"移除旧设备 deviceId = %@ ，移除推送成功！", devModel.DeviceId);
         }
     }];
}


#pragma mark - 更新设备在线状态
#pragma mark -- 接收在线状态通知
- (void)updateDeviceStatus:(NSNotification *)notifyData
{
    dispatch_async_on_main_queue(^{
        NSDictionary *recvDict = notifyData.object;
        NSString *msgType = recvDict[@"MessageType"];
        if (![msgType isEqualToString:kNotifyDevStatus])
        {
            NSLog(@"不是设备在线状态通知！");
            return;
        }
        if ([[NSNull null] isEqual:recvDict[@"Body"]]
            || [[NSNull null] isEqual:recvDict[@"Body"][@"DeviceStatus"]]
            || [[NSNull null] isEqual:recvDict[@"Body"][@"DeviceStatus"][0]]
            || [[NSNull null] isEqual:recvDict[@"Body"][@"DeviceStatus"][0][@"Status"]]
            || [[NSNull null] isEqual:recvDict[@"Body"][@"DeviceStatus"][0][@"DeviceId"]])
        {
            NSLog(@"无法提取设备在线状态！");
            return ;
        }
        
        NSArray *array = recvDict[@"Body"][@"DeviceStatus"];
        for (NSDictionary *statusDict in array) {
            GosDeviceStatus devStatus = (GosDeviceStatus)[statusDict[@"Status"] integerValue];
            NSString *deviceId = statusDict[@"DeviceId"];
            
            NSArray *subDevicesArray = statusDict[@"SubDevList"];//SubDevices
            if (subDevicesArray.count > 0) {
                
                DeviceDataModel *deviceModel = [[DeviceManagement sharedInstance] getDevcieModelWithDeviceId:deviceId];
                
                for (NSDictionary *subDevStatus in subDevicesArray) {
                    for (SubDevInfoModel *subInfo in deviceModel.SubDevice) {
                        if ([subInfo.SubId isEqualToString: subDevStatus[@"SubId"]]) {
                            subInfo.Status = [subDevStatus[@"Online"] intValue];
                            break;
                        }
                    }
                }
            }
            
            NSLog(@"更新设备 deviceId = %@ 在线状态：status = %d", deviceId, (int)devStatus);
            [self updateDeviceStatus:devStatus withDeviceId:deviceId];
        }

    });
}


#pragma mark -- 更新在线状态
- (void)updateDeviceStatus:(GosDeviceStatus)status
              withDeviceId:(NSString *)deviceId
{
    //加锁
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!deviceId || 0 >= deviceId.length)
        {
            NSLog(@"deviceId 错误，无法更新在线状态！");
            return;
        }
        //缓存在线状态
        NSNumber *statusNum = [NSNumber numberWithInt:status];
        [statusCacheDict setObject:statusNum forKey:deviceId];
        [self sortArrayAndRefresh];
        
        [self.deviceListTableView reloadData];

        dispatch_semaphore_signal(semaphore);
    });
}


#pragma mark -- 更新封面
- (void)updateDevCovert
{
    //刷新tableView
    dispatch_async_on_main_queue(^{
        [self.deviceListTableView reloadData];
    });
}



#pragma mark - 网络监听处理
- (void)networkChanged:(NSNotification *)notification{
    RealReachability *reachability = (RealReachability *)notification.object;
    ReachabilityStatus curStatus = [reachability currentReachabilityStatus];
    ReachabilityStatus prevStatus = [reachability previousReachabilityStatus];
    
    
    if (curStatus == RealStatusViaWiFi || curStatus == RealStatusViaWWAN) {
        //结束离线判断
        [self stopNetcheckTimer];
    }
    
    if ((curStatus == RealStatusViaWiFi || curStatus == RealStatusViaWWAN) && (prevStatus==RealStatusNotReachable || prevStatus == RealStatusUnknown)){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self beginRefreshList];
        });
    }
    
    
    if ((prevStatus == RealStatusViaWiFi || prevStatus == RealStatusViaWWAN) && (curStatus==RealStatusNotReachable || curStatus == RealStatusUnknown)){
        //开始离线判断
        [self startNetcheckTimer];
    }
    
    
    //判断是否需要重连的场景
    
    bool needToReconnect = NO;
    if (curStatus == RealStatusViaWiFi && (prevStatus ==RealStatusViaWWAN|| prevStatus==RealStatusNotReachable) ){
        needToReconnect = YES;
    }
    else if (curStatus ==RealStatusViaWWAN && (prevStatus== RealStatusViaWiFi|| prevStatus == RealStatusNotReachable) ){
        needToReconnect = YES;
    }
    if (needToReconnect) {
        //重连
        for (DeviceDataModel *model in [[DeviceManagement sharedInstance] deviceListArray]) {
            if (model.Status == GosDeviceStatusOnLine) {
                if (self.cacheVideoVC) {
                    if ([self.cacheVideoVC.deviceModel.DeviceId isEqualToString:model.DeviceId]){
                        continue;
                    }
                }
                [self reconectClientWithDeviceID:[model.DeviceId substringFromIndex:8]];
            }
        }
        
    }
    
}


- (void)allOffline{
    
    [self stopNetcheckTimer];
    
    //不是无网络 return
    if (![[self getNetWorkStates] isEqualToString:@"无网络"]) {
        //不是无网络
        return;
    }
    
    ReachabilityStatus status = [[RealReachability sharedInstance] currentReachabilityStatus];
    
    //如果是wifi和4G return
    if (status == RealStatusViaWWAN || status == RealStatusViaWiFi) {
        return;
    }
    
    dispatch_async_on_main_queue(^{
        for (DeviceDataModel *dataModel in [[DeviceManagement sharedInstance] deviceListArray]) {
            dataModel.Status = GosDeviceStatusOffLine;
            [self.deviceListTableView reloadData];
        }
    });
}

- (void)reconectClientWithDeviceID:(NSString *)deviceID{
    
    [[HWLogManager manager] logMessage:@"首页devicelist重连操作---uid"];
    [[HWLogManager manager] logMessage:deviceID];
    
    dispatch_async(dispatch_queue_create("ReconnectQueue", DISPATCH_QUEUE_SERIAL), ^{
        [[NetAPISet sharedInstance] reconnect:deviceID andBlock:^(int result, int state, int cmd)
         
         {
             
         }];
    });
}
#pragma mark -- 添加更新封面通知
- (void)addUpdateDevCovertNotify
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDevCovert)
                                                 name:@"UpdateScrrenShot"
                                               object:nil];
}


- (void)addClientConnectStatusNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectStatusChange:)
                                                 name:ADDeviceConnectStatusNotification
                                               object:nil];
}


#pragma mark - 连接状态回调
- (void)connectStatusChange:(NSNotification *)notifyData{
    NSDictionary *statusDict = notifyData.userInfo;
    
    NSString *UID = statusDict[@"UID"];
    NSNumber *statusNumber = statusDict[@"State"];
    
    
    if (![UID isKindOfClass:[NSString class]]) {
        return;
    }
    else{
        
        if ([UID isEqualToString:(self.currentConnectDevice.length == 15) ? self.currentConnectDevice : [self.currentConnectDevice substringFromIndex:8]]) {
            self.currentConnectDevice = nil;
        }
    }
    if (statusNumber.intValue == NotificationTypeConnected) {
        //成功移除
        [self removeNeedArrayWithDeviceID:UID];
        NSLog(@"AD ConnectSuccess-----------------%@",UID);
    }
    else{
        //失败先不移除
        [self removeNeedArrayWithDeviceID:UID];
        NSLog(@"AD ConnectFail-----------------%@",UID);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self configOnlineStatus:GosDeviceStatusOffLine
                            deviceId:UID];
        });
    }
}


- (void)configOnlineStatus:(GosDeviceStatus)onlineStatus
                  deviceId:(NSString *)deviceId
{
    if (IS_STRING_EMPTY(deviceId))
    {
        return;
    }
    DeviceDataModel *devDataModel = nil;
    NSInteger rowIndex = -1;
    for (NSInteger i = 0; i < [[DeviceManagement sharedInstance] deviceListArray].count; i++)
    {
        devDataModel = [[DeviceManagement sharedInstance] deviceListArray][i];
        if (![[devDataModel.DeviceId substringFromIndex:8] isEqualToString:deviceId])
        {
            continue;
        }
        rowIndex = i;
    }
    if (-1 >= rowIndex)
    {
        return;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIndex
                                                inSection:0];
    
    
    dispatch_async_on_main_queue(^{
        DeviceListTableViewCell *cell = [self.deviceListTableView cellForRowAtIndexPath:indexPath];
        
        switch (onlineStatus) {
            case GosDeviceStatusOffLine:        // 离线
            {
                [cell setOnlineView:NO];
            }
                break;
                
            case GosDeviceStatusOnLine:         // 在线
            {
                [cell setOnlineView:YES];
            }
                break;
                
            case GosDeviceStatusSleep:          // 睡眠
            {
                [cell setOnlineView:YES];
            }
                break;

            default:
            {
                [cell setOnlineView:NO];
            }
                break;
        }
        // 中继离线，则子设备离线
        if (devDataModel.SubDevice.count > 0 && onlineStatus == GosDeviceStatusOffLine) {
        
        }
    });
}


#pragma mark - 按钮事件中心
#pragma mark -- ‘添加设备’按钮事件
- (IBAction)addDeviceBtnAction:(id)sender
{
//    if (self.isDomesticDev) {
        AddStationAndSubDeviceVC *addDeviceVC = [AddStationAndSubDeviceVC new];

        [self.navigationController pushViewController:addDeviceVC animated:YES];
//    }else{
//        APDoorbellChooseDevNameVC *addDeviceVC = [[APDoorbellChooseDevNameVC alloc] init];
//        addDeviceVC.isDevListEmpty = [[[DeviceManagement sharedInstance] deviceListArray] count]<=0;
//        [self.navigationController pushViewController:addDeviceVC animated:YES];
//    }
}


#pragma mark -- ‘体验视频’按钮事件
- (IBAction)experienceVideoBtnAction:(id)sender
{
    ExperienceCenterViewController *experienceCenterVC = [[ExperienceCenterViewController alloc] init];
    
    if (experienceCenterVC)
    {
//        experienceCenterVC.pushedFromDevListVC = YES;
        [self.navigationController pushViewController:experienceCenterVC
                                             animated:YES];
    }
   // CloudPlayViewController *cloudVC = [[CloudPlayViewController alloc]init];
    //[self.navigationController pushViewController:cloudVC animated:YES];
    NSLog(@"体验视频！");
}


#pragma mark -- ‘关闭体验视频’按钮事件
- (IBAction)closeExperienceBtnAction:(id)sender
{
    [self closeExpVideoViewAfterDelay:0.3f];
}


#pragma mark - UITableview delegate & datasource
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return [[DeviceManagement sharedInstance] deviceListArray].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    DeviceDataModel *model = [[DeviceManagement sharedInstance] deviceListArray][indexPath.row];
    GosDetailedDeviceType detailDevType = [DeviceDataModel detailedDeviceTypeWithString: [model.DeviceId substringWithRange:NSMakeRange(3, 2)]];
    if (detailDevType == GosDetailedDeviceType_T5200HCA || model.devCapModel.four_channel_flag==1) {
        return (StationHeight+SubDeviceCellHeight*model.SubDevice.count)+10;
    }
    return 289+10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger rowIndex = indexPath.row;
    if (rowIndex >= [[DeviceManagement sharedInstance] deviceListArray].count){
        return nil;
    }
    DeviceDataModel *cellData = [[DeviceManagement sharedInstance] deviceListArray][rowIndex];
    if (nil == cellData){
        return nil;
    }
    GosDetailedDeviceType detailDevType = [DeviceDataModel detailedDeviceTypeWithString: [cellData.DeviceId substringWithRange:NSMakeRange(3, 2)]];

    
    __weak typeof(self) weakSelf = self;
    if (detailDevType == GosDetailedDeviceType_T5200HCA || cellData.devCapModel.four_channel_flag==1){
        DeviceListTableViewCell_5200 *cell = [tableView dequeueReusableCellWithIdentifier:kDevList_5200_CellIdentifier];
        [cell subDeviceClickCallback:^(SubDevCellAction actionType, int index) {
            [weakSelf cellAction:actionType rowIndex:indexPath.row subDevIndex:index];
        }];
        
        cell.backgroundColor = [UIColor clearColor];
        cell.cellData = cellData;
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.stationSettingBtn.tag = indexPath.row+1000;
        [cell.stationSettingBtn addTarget:self action:@selector(stationSettingBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
    //if (detailDevType == GosDetailedDeviceType_T5100ZJ )
    else{
        SubDeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSubCellIdentifier];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.backgroundColor = [UIColor clearColor];

        cell.devListTableViewCellData = cellData;
        [cell subDeviceClickCallback:^(SubDevCellAction actionType,int index) {
            [weakSelf cellAction:actionType rowIndex:indexPath.row subDevIndex:index];
        }];
        return cell;
    }
}

- (void)stationSettingBtnClicked:(id)sender{
    NSInteger rowIndex = ((UIButton*)sender).tag-1000;
    DeviceDataModel *model = [[DeviceManagement sharedInstance] deviceListArray][rowIndex];
    [self gotoDeviceSettingsPageWithModel: model];
}

- (void)cellAction:(SubDevCellAction)action rowIndex:(NSInteger)rowIndex subDevIndex:(int)subDevIndex{
    
    DeviceDataModel *model = [[DeviceManagement sharedInstance] deviceListArray][rowIndex];
    
    if (nil == model){
        NSLog(@"cellAction_model:%@",model);
        return ;
    }
    
    GosDetailedDeviceType detailDevType = [DeviceDataModel detailedDeviceTypeWithString: [model.DeviceId substringWithRange:NSMakeRange(3, 2)]];
    
    if (model.SubDevice.count>0) {
        model.selectedSubDevInfo = model.SubDevice[subDevIndex];
    }else{
        NSLog(@"cellAction_model:%@",model);
        
    }
    
    
    switch (action) {
        case SubDevCellActionShowMsgCenter:
        {
            [self gotoMsgCenterPageWithDevID:model.DeviceId subID: model.selectedSubDevInfo.SubId];
            break;
        }
        case SubDevCellActionShowSettings:
        {
            if (detailDevType == GosDetailedDeviceType_T5200HCA || model.devCapModel.four_channel_flag==1 ) {
                
                [self gotoSubDevSettingWithModel: model subDevIndex:subDevIndex];
            }else{
                [self  gotoDeviceSettingsPageWithModel:model];
            }
            break;
        }
        case SubDevCellActionPlayLiveStream:
        {
            if (detailDevType == GosDetailedDeviceType_T5100ZJ || detailDevType == GosDetailedDeviceType_T5200HCA ) {
                
                GOSLivePlayerVC *playerVC = [[GOSLivePlayerVC alloc] init];
                playerVC.deviceModel = model;
                [self.navigationController pushViewController:playerVC animated:YES];
            }else{
                
                PlayVideoViewController *playerVC = [[PlayVideoViewController alloc] init];
                playerVC.deviceModel = model;
                [self.navigationController pushViewController:playerVC animated:YES];
            }
            break;
        }
        case SubDevCellActionShowCloudPlayback:
        {
            CloudPlayBackViewController *vc = [CloudPlayBackViewController new];
            vc.deviceId                     = model.DeviceId;
            vc.deviceName                   = model.DeviceName;
            vc.deviceModel                  = model;
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case SubDevCellActionShowTFCardPlayback:
        {
//    #ifndef DEBUG
            GosTFCardViewController *vc = [[GosTFCardViewController alloc] init];
            vc.deviceModel = model;
            [self.navigationController pushViewController:vc animated:YES];
            break;
//    #else
//            CloudSDCardViewController *vc   = [CloudSDCardViewController new];
//            vc.deviceId                     = model.DeviceId;
//            vc.deviceName                   = model.DeviceName;
//            vc.deviceModel                  = model;
//            [self.navigationController pushViewController:vc animated:YES];
//            break;
//    #endif
        }
        default:
            break;
    }
}


- (void)cellBtnClickAction:(id)sender{
//    UIButton *btn = (UIButton*)sender;
//    int tag = (int)btn.tag;
//    int devIndexInTableView = tag%1000;
//    int btnActionType = tag/1000;
}

- (void)gotoMsgCenterPageWithDevID:(NSString*)devId subID:(NSString*)subID{
    
    PushMsgViewController *pushVC = [PushMsgViewController new];
    pushVC.deviceID = devId;
    pushVC.subId    = subID;
    [self.navigationController pushViewController:pushVC animated:NO];
}


- (void)gotoRecordPlaybackPageWithModel:(DeviceDataModel*)model{
    
    RecordDateListViewController *recordDateListVC = [[RecordDateListViewController alloc] init];
    recordDateListVC.model    = model;
    [self.navigationController pushViewController:recordDateListVC animated:YES];
}

- (void)gotoFriendSharePageWithModel:(DeviceDataModel*)model{
    
    ShareWithFriendsViewController * setVC =[[ShareWithFriendsViewController alloc]init];
    setVC.model = model;
    [self.navigationController pushViewController:setVC animated:YES];
}

- (void)gotoSubDevSettingWithModel:(DeviceDataModel*)model subDevIndex:(NSInteger)subDevIndex{
    SubDeviceSettingVC *subDevSettingVC = [SubDeviceSettingVC new];
    subDevSettingVC.devModel = model;
    subDevSettingVC.subDevInfo = model.SubDevice[subDevIndex];
    [self.navigationController pushViewController:subDevSettingVC animated:YES];
}

- (void)gotoDeviceSettingsPageWithModel:(DeviceDataModel*)model{

    SettingViewController * setVC =[[SettingViewController alloc]init];
    setVC.model = model;
    [self.navigationController pushViewController:setVC animated:YES];
}

#pragma mark - UITableviewDelegate 代理方法
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ;
}

- (BOOL)isDomesticDev{
    if (!_isDomesticDev) {
//        NSString *csbIPStr =  [mUserDefaults objectForKey:@"kCBS_IP"];
        //[csbIPStr isEqualToString:@"119.23.124.137"];
        _isDomesticDev = [mUserDefaults integerForKey:IsBetaVersion];
    }
    return _isDomesticDev;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

-(BOOL)isCurrentViewControllerVisible
{
    AppDelegate *appdelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    RESideMenu *resideMenu = (RESideMenu*)appdelegate.window.rootViewController;
    
    if ([resideMenu isMemberOfClass:[RESideMenu class]]) {
        UIViewController *vc = ((UINavigationController*)resideMenu.contentViewController).topViewController;
        return ![resideMenu isLeftMenuVisible] &&[vc isKindOfClass:[DeviceListViewController class]] ;
    }else{
        return (self.isViewLoaded && self.view.window);
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (NSString *)getUUID {
    NSString *UUID = [[NSUserDefaults standardUserDefaults] objectForKey:@"UUID_RANDOM"];
    if (UUID && UUID.length > 0)
        return UUID;
    
    UUID = [NSString stringWithFormat:@"%@&%d", [[[UIDevice currentDevice] identifierForVendor] UUIDString], arc4random()];
    [[NSUserDefaults standardUserDefaults] setObject:UUID forKey:@"UUID_RANDOM"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    return UUID;
}
@end
