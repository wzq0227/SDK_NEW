//
//  APDoorbellNoVoiceTipVC.m
//  ULife3.5
//
//  Created by Goscam on 2017/12/5.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "APDoorbellNoVoiceTipVC.h"
#import "APDoorbellGoToSettingsVC.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "CustomWindow.h"
#import "UILabel+GosLayoutAdd.h"
#pragma mark -Test
#import "CBSCommand.h"
#import "NetSDK.h"
#import "SaveDataModel.h"

@interface APDoorbellNoVoiceTipVC ()
{
    CustomWindow *customWindow;
}

@property (strong, nonatomic)  AVPlayerViewController *playerVC;

@property (assign, nonatomic)  int checkIfDevRegisteredCount;

@end

@implementation APDoorbellNoVoiceTipVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self configUI];
    
    [self addActions];
}

- (void)configUI{
    
    [self configView];
    
}

//DoorbellDemoVideo.mp4
- (void)configDemoVideo{
    NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"DoorbellDemoVideo" ofType:@"mp4"];
    
    _playerVC = [AVPlayerViewController new];
    _playerVC.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:videoPath]];
    _playerVC.view.frame = self.demoVideoView.bounds;
    [self.demoVideoView addSubview: _playerVC.view];
    _playerVC.showsPlaybackControls = NO;
    [_playerVC.player play];
    
    [self addNotification];
}

- (void)viewWillAppear:(BOOL)animated{
    [self configDemoVideo];
    
#pragma mark  -Test
//    self.checkIfDevRegisteredCount = 0;
//    [self checkIfDeviceRegisteredToServer ];
}

- (void)removeDemoVideo{
    [_playerVC.view removeFromSuperview];
    _playerVC = nil;
}

- (void)viewDidDisappear:(BOOL)animated{
    
    [self removeDemoVideo];
    [self removeNotification];
}

/**
 *  添加播放器通知
 */
-(void)addNotification{
    //给AVPlayerItem添加播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerVC.player.currentItem];
}

-(void)removeNotification{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
/**
 *  播放完成通知
 *
 *  @param notification 通知对象
 */
-(void)playbackFinished:(NSNotification *)notification{
    NSLog(@"视频播放完成.");
    
    
    // 播放完成后重复播放
    // 跳到最新的时间点开始播放
    [_playerVC.player seekToTime:CMTimeMake(0, 1)];
    [_playerVC.player play];
}


- (void)configView{
    
    self.title = DPLocalizedString(@"ADDDevice");
    
    self.voiceTipLabel.text = DPLocalizedString(@"APDoorbell_VoiceTipAfter60S");
    [self.heardVoiceBtn setTitle:DPLocalizedString(@"AcousticAdd_haveHeardVoiceTip") forState:UIControlStateNormal];
    self.heardVoiceBtn.backgroundColor = myColor;
    self.heardVoiceBtn.layer.cornerRadius = 20;
    
    self.notHeardVoiceBtn.titleLabel.numberOfLines = 0;
    self.notHeardVoiceBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.notHeardVoiceBtn setTitle:DPLocalizedString(@"AcousticAdd_notHeardVoiceTips") forState:UIControlStateNormal];
}

- (void)addActions{
    
    [self.heardVoiceBtn addTarget:self action:@selector(heardVoiceBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.notHeardVoiceBtn addTarget:self action:@selector(notHeardVoiceBtnAction:) forControlEvents:UIControlEventTouchUpInside];

}

#pragma mark -Test
- (void)checkIfDeviceRegisteredToServer{
    
    BodyCheckDeviceRegisterRequest *body = [BodyCheckDeviceRegisterRequest new];
    CBS_CheckDeviceRegisterRequest *req = [CBS_CheckDeviceRegisterRequest new];
    body.DeviceId = self.addDevInfo.devId;
    body.UserName = [SaveDataModel getUserName];
    req.Body = body;
    __weak typeof(self)weakSelf = self;
    [SVProgressHUD showWithStatus:DPLocalizedString(@"loading")];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [[NetSDK sharedInstance] net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
            
            weakSelf.checkIfDevRegisteredCount++;
            NSLog(@"________________________checkIfDeviceRegisteredToServer_result=%@",dict);
            if (result ==0  ) {
                CBS_CheckDeviceRegisterResponse *resp = [CBS_CheckDeviceRegisterResponse yy_modelWithDictionary:dict];
                if (resp.Body.Status ==1) {
//                    [weakSelf bind];
                }else{
                    if (weakSelf.checkIfDevRegisteredCount<=10 ) {
                        [weakSelf checkIfDeviceRegisteredToServer];
                    }
                }
            }else{
                if (weakSelf.checkIfDevRegisteredCount<=10 ) {
                    [weakSelf checkIfDeviceRegisteredToServer];
                }
            }
        }];
    });
}

- (void)notHeardVoiceBtnAction:(id)sender{
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CustomView" owner:self options:nil];
    UIView *tmpContentView = [nib objectAtIndex:4];
    tmpContentView.layer.cornerRadius=12;
    
    if (customWindow == NULL) {
        customWindow = [[CustomWindow alloc]initWithView:tmpContentView];
        
        UILabel  *tiplabel     = (UILabel  *)[tmpContentView viewWithTag:3000];
        UILabel  *label        = (UILabel  *)[tmpContentView viewWithTag:3001];
        UIButton *imageButton    = (UIButton *)[tmpContentView viewWithTag:3002];
        UIButton *confirmButton = (UIButton *)[tmpContentView viewWithTag:3003];
        
        tiplabel.text    =DPLocalizedString(@"APDoorbell_NoVoiceTip_Solution");
        
        NSRange iconStringRange = [DPLocalizedString(@"APDoorbell_NoVoiceTip_PressSignalBtn") rangeOfString:@"%@"];
        NSString *txtStr = [DPLocalizedString(@"APDoorbell_NoVoiceTip_PressSignalBtn") stringByReplacingOccurrencesOfString:@"%@" withString:@""];
        
        label.text = txtStr;
        [label insertImage:[UIImage imageNamed:@"AcousticAdd_icon_signal"]
                                              atIndex:iconStringRange.location
                                               bounds:CGRectMake(0, -2, 15, 13)];
        
        imageButton.userInteractionEnabled = NO;
        [imageButton setBackgroundImage:[UIImage imageNamed:@"APDoorbell_Tip_PressSignalBtn@2x.png"] forState:UIControlStateNormal];
        
        confirmButton.layer.cornerRadius = 20;
        confirmButton.titleLabel.textColor = UIColor.whiteColor;
        confirmButton.backgroundColor = myColor;
        [confirmButton setTitle:DPLocalizedString(@"Qrcode_soundBtn") forState:0];
        [confirmButton    addTarget:self
                         action:@selector(heardVoiceBtnAction:)
               forControlEvents:UIControlEventTouchUpInside];
        
    }
    [customWindow show];
}

- (void)heardVoiceBtnAction:(id)sender{
    
    if (customWindow) {
        [customWindow close];
    }
    
    APDoorbellGoToSettingsVC *vc = [APDoorbellGoToSettingsVC new];
    vc.addDevInfo = self.addDevInfo;
    [self.navigationController pushViewController:vc animated:YES];
}
@end
