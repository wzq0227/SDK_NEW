//
//  VideoListDataViewController.m
//  goscamapp
//
//  Created by goscam_sz on 17/4/20.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "VideoListDataViewController.h"
#import "QQIGetDeviceListSocket.h"
#import "VideoModel.h"
#import "PlayVideoViewController.h"
#import "AddDeviceViewController.h"
#import "RESideMenu.h"
#import "SaveDataModel.h"
#import "MainNavigationController.h"





@interface VideoListDataViewController () <UITableViewDelegate,UITableViewDataSource,pushNextViewAdDeviceDelegate,GetDeviceListDelegate,RESideMenuDelegate>


@property (nonatomic,strong) UITableView *mytableview;

@property (nonatomic,copy) NSMutableArray * devListArr;

@property (nonatomic,strong) VideoView * myVideoView;

@property (nonatomic,strong) QQIGetDeviceListSocket *getDeviceListSocket;

@property (nonatomic,strong) UIRefreshControl* refreshControl;

@property (nonatomic,strong) UIView * myview;

@property (nonatomic,strong) RESideMenu * myside;

@end

@implementation VideoListDataViewController


-(void)addRefreshView
{
    if (_refreshControl == nil)
    {
        _refreshControl = [[UIRefreshControl alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        [_refreshControl addTarget:self
                            action:@selector(downloadCameraList)
                  forControlEvents:UIControlEventValueChanged];
    }
    [_myVideoView.myVideoListTabbleView addSubview:_refreshControl];
}



-(NSMutableArray *)devListArr
{
    if (_devListArr==nil) {
        _devListArr=[[NSMutableArray alloc]init];
    }
    return _devListArr;
}



-(UITableView *)mytableview
{
    if (_mytableview==nil) {
        _mytableview=[[UITableView alloc]initWithFrame:CGRectMake(0, 0,SCREEN_WIDTH,SCREEN_HEIGHT-100) style:UITableViewStylePlain];
        _mytableview.delegate=self;
        _mytableview.dataSource=self;
        _mytableview.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _mytableview;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.myVideoView= [[NSBundle mainBundle]loadNibNamed:@"VideoView" owner:self options:nil].lastObject;
    self.myVideoView.frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height);
    self.myVideoView.delegate=self;
    [self.view addSubview:_myVideoView];
    _myview =[[UIView alloc]initWithFrame: CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height)];
    _myview.alpha=0;
    _myview.backgroundColor=[UIColor darkGrayColor];
    [self.view addSubview:_myview];
    
    [self addRefreshView];
    self.title=@"设备列表";
    self.myVideoView.backgroundColor=[UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor=[UIColor colorWithRed:76/255.0 green:182/255.0 blue:174/255.0 alpha:1.0];
    UIImage *image = [[UIImage imageNamed:@"infoBtn.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(presentLeftMenuViewController:)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(amplify) name:@"ViewController" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideamplify) name:@"hideViewController" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(action) name:@"actionViewController" object:nil];
    [self downloadCameraList];
}

-(void)amplify
{
    if (_myview.alpha>=0.6) {
    }
    else{
        _myview.alpha+=0.008;
        NSLog(@"%f",_myview.alpha);
    }
}

-(void)hideamplify
{
    _myview.alpha=0;
}


-(void)action
{
    [UIView animateWithDuration:0.35 animations:^{
        _myview.alpha = 0.6;
    } completion:^(BOOL finished) {
    }];
}


#pragma mark - 请求摄像头列表
-(void)downloadCameraList
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_refreshControl beginRefreshing];
    });
    self.getDeviceListSocket = [QQIGetDeviceListSocket shareInstanceUpListand:[SaveDataModel getUserInforIp] andPort:[SaveDataModel getUserInforPort]];
    self.getDeviceListSocket.delegate=self;
    
    [[QQIGetDeviceListSocket shareInstanceUpListand:[SaveDataModel getUserInforIp]  andPort:[SaveDataModel getUserInforPort]]getDeviceListWithId:[SaveDataModel getUserld] resultClass:[VideoModel class]];
}



#pragma mark - 获取设备列表代理
- (void)didReceiveList:(NSMutableArray *)listArray
           userLoginId:(NSString *)userLoginId
             isSuccess:(BOOL)isSuccess
{
    if (YES == isSuccess)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_refreshControl endRefreshing];
        });
        self.devListArr=[[NSMutableArray alloc]initWithArray:listArray];
        [self.myVideoView loadListArr:self.devListArr];
    }
}


#pragma mark -- 跳转到播放页面
- (void)startPushToPlayVideoView:(NSString *)deviceId
                      deviceName:(NSString *)deviceName
{
    if (IS_STRING_EMPTY(deviceId) || IS_STRING_EMPTY(deviceName))
    {
        NSLog(@"无法跳转到播放页面，deviceId = %@, deviceName = %@", deviceId, deviceName);
        
        return;
    }
    PlayVideoViewController *playVideoVC = [[PlayVideoViewController alloc] init];
    if (playVideoVC)
    {
        playVideoVC.deviceId   = deviceId;
        playVideoVC.deviceName = deviceName;
        [self.navigationController pushViewController:playVideoVC
                                             animated:YES];
    }
}



#pragma mark - 获取设备列表代理
-(void)startPushToAdDevice
{
    NSLog(@"添加设备");
    [self.navigationController pushViewController:[[AddDeviceViewController alloc]init] animated:NO];
}

#pragma mark - 跳转到体验视频界面代理
-(void)startPushExperienceVideoView
{
    NSLog(@"跳转体验视频列表");
}



-(void)viewDidAppear:(BOOL)animated
{

}


- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;;
}

@end
