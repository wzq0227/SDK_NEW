//
//  PlayVideoDelegateCenter.m
//  goscamapp
//
//  Created by shenyuanluo on 2017/4/27.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "PlayVideoDelegateCenter.h"
#import "RecordDateListViewController.h"
#import <AVFoundation/AVFoundation.h>


@interface PlayVideoDelegateCenter ()

/**
 *  录像按钮点击声音 播放器
 */
@property (nonatomic, strong) AVAudioPlayer *recordBtnAudioPlayer;

/**
 *  拍照按钮点击声音 播放器
 */
@property (nonatomic, strong) AVAudioPlayer *snapShotBtnAudioPlayer;

@end


@implementation PlayVideoDelegateCenter


- (void)dealloc
{
    NSLog(@"播放页面代理实现中心 - dealloc");
    [self realseBtnSoundAudioPlayer];
}

#pragma mark - 懒加载
#pragma mark -- ‘拍照’按钮音效播放器
- (AVAudioPlayer *)snapShotBtnAudioPlayer
{
    if (!_snapShotBtnAudioPlayer)
    {
        
        NSString *audioFilePath = [[NSBundle mainBundle] pathForResource:@"SnapshotSound" ofType:@"wav"];
        NSURL *audioFileUrl = [NSURL fileURLWithPath:audioFilePath];
        _snapShotBtnAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileUrl error:NULL];
    }
    
    return _snapShotBtnAudioPlayer;
}


#pragma mark -- ‘录像’按钮音效播放器
- (AVAudioPlayer *)recordBtnAudioPlayer
{
    if (!_recordBtnAudioPlayer)
    {
        NSString *audioFilePath = [[NSBundle mainBundle] pathForResource:@"RecordSound" ofType:@"wav"];
        NSURL *audioFileUrl = [NSURL fileURLWithPath:audioFilePath];
        _recordBtnAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileUrl error:NULL];
    }
    
    return _recordBtnAudioPlayer;
}


#pragma mark - 播放音效
#pragma mark -- 播放‘拍照’音效
- (void)playSnapShotSound
{
    if (self.snapShotBtnAudioPlayer)
    {
        [self.snapShotBtnAudioPlayer prepareToPlay];
        [self.snapShotBtnAudioPlayer play];
    }
}

#pragma mark -- 播放‘录像’音效
- (void)playRecordSound
{
    if (self.recordBtnAudioPlayer)
    {
        [self.recordBtnAudioPlayer prepareToPlay];
        [self.recordBtnAudioPlayer play];
    }
}


#pragma mark -- 停止按钮音效播放器
-(void)realseBtnSoundAudioPlayer
{
    if (self.snapShotBtnAudioPlayer)
    {
        [self.snapShotBtnAudioPlayer stop];
        self.snapShotBtnAudioPlayer = nil;
    }
    if (self.recordBtnAudioPlayer)
    {
        [self.recordBtnAudioPlayer stop];
        self.recordBtnAudioPlayer = nil;
    }
}


#pragma mark - 播放页面代理实现中心
#pragma mark -- 跳转至‘录像列表页面’
- (void)recordList
{
    NSLog(@"播放控制代理实现中心 - 跳转至‘录像列表页面’！");
    RecordDateListViewController *recordDateListVC = [[RecordDateListViewController alloc] init];
    if (recordDateListVC)
    {
        recordDateListVC.deviceId = self.deviceId;
        [self.viewController.navigationController pushViewController:recordDateListVC
                                                            animated:YES];
    }
}


#pragma mark -- 开启/停止录像功能
- (void)record
{
    NSLog(@"播放控制代理实现中心 - 开启/停止录像功能！");
    [self playRecordSound];
}

#pragma mark -- 跳转至‘控制杆页面’
- (void)joystickControll
{
    NSLog(@"播放控制代理实现中心 - 跳转至‘控制杆页面’！");
}

#pragma mark -- 视频画面质量切换功能
- (void)qualityChange
{
    NSLog(@"播放控制代理实现中心 - 视频画面质量切换功能！");
}


#pragma mark -- 声音开关功能
- (void)sound
{
    NSLog(@"播放控制代理实现中心 - 声音开关功能！");
}



#pragma mark -- 对讲功能
- (void)talk
{
    NSLog(@"播放控制代理实现中心 - 对讲功能！");
}



#pragma mark -- 拍照功能
- (void)snapshot
{
    NSLog(@"播放控制代理实现中心 - 拍照功能！");
    [self playSnapShotSound];
}


@end
