//
//  RecordVideoPlayViewController.m
//  goscamapp
//
//  Created by shenyuanluo on 2017/4/28.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "RecordVideoPlayViewController.h"

@interface RecordVideoPlayViewController ()

@property (weak, nonatomic) IBOutlet UIButton *finishButton;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *videoProgressView;
@property (weak, nonatomic) IBOutlet UIView *videoPlayView;
@property (weak, nonatomic) IBOutlet UIButton *previousVideoBtn;
@property (weak, nonatomic) IBOutlet UIButton *nextVideoBtn;
@property (weak, nonatomic) IBOutlet UIButton *playOrPauseBtn;
@property (weak, nonatomic) IBOutlet UISlider *soundSilder;

@end

@implementation RecordVideoPlayViewController

#pragma mark - ViewController 生命周期
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initParameter];
    
    [self configUI];
    
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)dealloc
{
    NSLog(@"录像‘视频’播放页面 - dealloc");
}


#pragma mark - 初始化设置相关
#pragma mark -- 初始化参数
- (void)initParameter
{
    
}


#pragma mark -- 设置相关 UI
- (void)configUI
{
    
}


#pragma mark - 按钮事件中心
#pragma mark -- '完成'按钮事件
- (IBAction)finishBtnAction:(id)sender
{
    NSLog(@"'完成'按钮事件");
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}


#pragma mark -- '上一视频'按钮事件
- (IBAction)preVideoBtnAction:(id)sender
{
    NSLog(@"'上一视频'按钮事件");
}


#pragma mark -- '下一视频'按钮事件
- (IBAction)nextVideoBtnAction:(id)sender
{
    NSLog(@"'下一视频'按钮事件");
}


#pragma mark -- '暂停/播放'按钮事件
- (IBAction)playOrPausBtnAction:(id)sender
{
    NSLog(@"'暂停/播放'按钮事件");
}





#pragma mark - 横竖屏切换相关
#pragma mark -- 是否允许横竖屏
-(BOOL)shouldAutorotate
{
    return NO;
}


#pragma mark -- 横竖屏方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
