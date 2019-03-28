
//
//  APDoorbellGoToSettingsVC.m
//  ULife3.5
//
//  Created by Goscam on 2017/12/5.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "APDoorbellGoToSettingsVC.h"
#import "APDoorbellSetupGuideCell.h"
#import "Header.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import <UIKit/UILocalNotification.h>
#import <UserNotifications/UserNotifications.h>
#import "APDoorbellSelectWifiVC.h"
#import "ConfigurationWiFiViewController.h"
#import "JumpWiFiTipsView.h"

@interface APDoorbellGoToSettingsVC ()<
UITableViewDelegate,
UITableViewDataSource,
UIAlertViewDelegate
>

{
    
}

@property (assign, nonatomic)  BOOL hasConnectedToAPWifi;

@property (strong, nonatomic) NSTimer *checkSSIDTimer;

@property (strong, nonatomic)  UILocalNotification *localNotification;


@property (weak, nonatomic) IBOutlet UITableView *setupGuideTableView;

@property (strong, nonatomic)  NSMutableArray<UIImage*>*imagesArray;

@end

const static NSString *kCellIdentifier = @"APDoorbellSetupGuideCell";

@implementation APDoorbellGoToSettingsVC


- (NSMutableArray*)imagesArray{
    if (!_imagesArray) {
        
        _imagesArray = [NSMutableArray arrayWithCapacity:1];
        for (int index =0; index<3; index++) {
            
            NSString *imageName = @"";
            switch (index) {
                case 0:
                {
                    imageName = @"APDoorbell_Tip_Settings@2x.png";
                    break;
                }
                case 1:
                {
                    imageName = @"APDoorbell_Tip_ChooseAPWifi@2x.png";
                    break;
                }
                case 2:
                {
                    imageName = @"APDoorbell_Tip_BackToApp@2x.png";
                    break;
                }
                default:
                    break;
            }
            UIImage *tipImage = [UIImage imageNamed:imageName];
            [_imagesArray addObject:tipImage];
        }
    }
    return _imagesArray;
}

#pragma mark - LifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];

    [self addNotifications];
    
    [self configTableView];
    
    [self configView];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
//    [self gotoSelectWifiVC ];
}

- (void)configView{
    self.title = DPLocalizedString(@"WiFi_Configuration");
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [self removeNotifications];
}


#pragma mark - 添键进入后台通知
- (void)addNotifications{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelAllLocalNotificationsFunc) name:@"APWifiConnected" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

    if (!_checkSSIDTimer) {
        [self queryCurWifiName:nil];
        _checkSSIDTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(queryCurWifiName:) userInfo:nil repeats:YES];
    }
}

- (void)applicationWillEnterForeground:(id)sender{
    
    NSString *curSSID = [CommonlyUsedFounctions getCurSSID];
    if ([self connectedToAPWifiWithCurSSID:curSSID] && _checkSSIDTimer ) {
        [self cancelAllLocalNotificationsFunc];
    }
}



- (void)removeNotifications{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_checkSSIDTimer invalidate];
    _checkSSIDTimer = nil;
}


- (void)cancelAllLocalNotificationsFunc{
    
    if (!_checkSSIDTimer) {
        return;
    }
    float sysVersion = [UIDevice currentDevice].systemVersion.floatValue;
    if (sysVersion>10) {
        [UNUserNotificationCenter.currentNotificationCenter removeAllDeliveredNotifications];
        [UNUserNotificationCenter.currentNotificationCenter removeAllPendingNotificationRequests];
    }else{
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        //        [[UIApplication sharedApplication] ];
    }
    if (_checkSSIDTimer) {
        [_checkSSIDTimer invalidate];
        _checkSSIDTimer = nil;
    }
    
    [self gotoSelectWifiVC];
}

- (void)gotoSelectWifiVC{
    
    dispatch_async(dispatch_get_main_queue(), ^{
//        APDoorbellSelectWifiVC *vc = [APDoorbellSelectWifiVC new];
//
//        vc.addDevInfo = _addDevInfo;
//        [self.navigationController pushViewController:vc animated:YES];
        
        _addDevInfo.addDeviceMode                    = AddDeviceByAPDoorbell;
        _addDevInfo.devWifiName                      = self.ssid;
        _addDevInfo.devWifiPassWord                  = self.password;
        _addDevInfo.deviceType                       = GosDeviceIPC;

        ConfigurationWiFiViewController *vc = [ConfigurationWiFiViewController new];
        vc.addDevInfo = self.addDevInfo;
        [self.navigationController pushViewController:vc animated:YES];
    });
}

- (void)applicationDidEnterBackground:(UIApplication *)sender {
    
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
        
        NSLog(@"Starting background task with %f seconds remaining", application.backgroundTimeRemaining);
        
        if (bgTaskIdentifier != UIBackgroundTaskInvalid)
        {
            [application endBackgroundTask:bgTaskIdentifier];
            bgTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }];
}

- (BOOL)connectedToAPWifiWithCurSSID:(NSString*)ssid{
    
    return [ssid containsString:@"GOS-"]||[ssid containsString:@"RouterSet-"];
}

- (void)queryCurWifiName:(id)sender{
    NSString *curSSID = [CommonlyUsedFounctions getCurSSID];
    if ( [self connectedToAPWifiWithCurSSID:curSSID] && [UIApplication sharedApplication].applicationState != UIApplicationStateActive ) {
    
        
        float sysVersion = [UIDevice currentDevice].systemVersion.floatValue;
        
        
        if (sysVersion > 10.0) {
            UNUserNotificationCenter *curUNCenter = UNUserNotificationCenter.currentNotificationCenter;
            UNMutableNotificationContent *unContent = [UNMutableNotificationContent new];
            unContent.body = DPLocalizedString(@"APDoorbell_NotificationTip_TapToReturn");
            unContent.sound = [UNNotificationSound defaultSound];
            unContent.userInfo = @{@"LocalNotification":@"APWifiConnected"};
            unContent.categoryIdentifier = @"com.goscam.localNotification";
            UNTimeIntervalNotificationTrigger *timeTrigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:2 repeats:NO];
            UNNotificationRequest *req = [UNNotificationRequest requestWithIdentifier:@"LocalNotification" content:unContent trigger:timeTrigger];
            [curUNCenter addNotificationRequest:req withCompletionHandler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"addNotificationRequest:%@",error.description);
                }
            }];
            
        } else {
            NSDate *date = [NSDate dateWithTimeIntervalSinceNow:2];
            _localNotification = [[UILocalNotification alloc] init];
            _localNotification.timeZone = [NSTimeZone defaultTimeZone];
            _localNotification.fireDate = date;
            NSLog(@"localNotification________fireDate:%@",_localNotification.fireDate);
            _localNotification.repeatInterval = 0;
            
            _localNotification.alertBody = DPLocalizedString(@"APDoorbell_NotificationTip_TapToReturn");
            _localNotification.userInfo = @{@"LocalNotification":@"APWifiConnected"};
            _localNotification.soundName = UILocalNotificationDefaultSoundName;
            
            [[UIApplication sharedApplication] scheduleLocalNotification:_localNotification];
        }
        NSLog(@"Wifi is connected");
    }else{
        NSLog(@"Wifi not connected");
    }
}

- (void)configTableView {
    self.setupGuideTableView.dataSource = self;
    self.setupGuideTableView.delegate = self;
    self.setupGuideTableView.scrollEnabled = NO;
    self.setupGuideTableView.backgroundColor = mCustomBgColor;
    self.setupGuideTableView.separatorColor = [UIColor clearColor];
    
//    [self.setupGuideTableView registerClass:[APDoorbellSetupGuideCell class] forCellReuseIdentifier:kCellIdentifier];
    [self.setupGuideTableView registerNib:[UINib nibWithNibName:kCellIdentifier bundle:nil] forCellReuseIdentifier:kCellIdentifier];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 3;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    APDoorbellSetupGuideCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    NSString *imageName = @"";
    switch (indexPath.row) {
        case 0:
        {
            cell.tipTitleLabel.text = DPLocalizedString(@"APDoorbell_LaunchSettings_Tip");
            imageName = @"APDoorbell_Tip_Settings@2x";
            break;
        }
        case 1:
        {
            cell.tipTitleLabel.text = DPLocalizedString(@"APDoorbell_ChooseAPWifi_Tip");
            imageName = @"APDoorbell_Tip_ChooseAPWifi@2x";
            break;
        }
        case 2:
        {
            cell.tipTitleLabel.text = DPLocalizedString(@"APDoorbell_ReturnToApp_Tip");
            imageName = @"APDoorbell_Tip_BackToApp@2x";
            break;
        }
        default:
            break;
    }
    UIImage *tipImage = self.imagesArray[indexPath.row];
    cell.tipImageBtn.userInteractionEnabled = NO;
    [cell.tipImageBtn setBackgroundImage:tipImage forState:UIControlStateNormal];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, SCREEN_WIDTH);
    
    if (SCREEN_WIDTH < 321) {
        cell.tipTitleLabel.font = [UIFont systemFontOfSize:13];
        cell.spacingBetweenImgAndLabel.constant = 9;
    }
    
    return cell;
}


#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    UIImage *tipImage = self.imagesArray[indexPath.row];
    
    CGFloat height = tipImage.size.height *SCREEN_WIDTH/360;
    if (SCREEN_WIDTH < 321) {
        if (indexPath.row == 0) {
            return height + 48;
        }else if ( indexPath.row == 1){
            return height + 53;
        }else{
            return height + 79;
        }
    }else{
        return height + 60;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0.1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 50;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return nil;
}

- (void)nextBtnAction:(id)sender{
    
    NSString *curSSID = [CommonlyUsedFounctions getCurSSID];
    if ([self connectedToAPWifiWithCurSSID:curSSID] && _checkSSIDTimer ) {
        [self cancelAllLocalNotificationsFunc];
    }else if ([self connectedToAPWifiWithCurSSID:curSSID]){
        [self gotoSelectWifiVC];
    }else{
        [self jumpToSysWiFiSetting];//[self showAlertWithMsg: DPLocalizedString(@"APAdd_chooseNetworkTips_RoutersetGW20")];
    }

}

- (void)showAlertWithMsg:(NSString *)msg{
    UIAlertView *msgAlert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:self cancelButtonTitle:DPLocalizedString(@"Title_Confirm") otherButtonTitles:nil, nil];
    msgAlert.delegate = self;
    [msgAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{

    [self jumpToSysWiFiSetting ];
}

- (void)jumpToSysWiFiSetting{
    
//    NSURL *url;
//    url = [NSURL URLWithString:@"App-Prefs:root=WIFI"];
//    if ([[UIApplication sharedApplication]canOpenURL:url]) {
//        [[UIApplication sharedApplication]openURL:url];
//    }
    // 弹框提示设置WiFi
    [JumpWiFiTipsViewControl showTip];
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    UIView *view =[[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 50)];
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(30, 5, SCREEN_WIDTH-60, 40)];
    btn.backgroundColor = myColor;
    btn.titleLabel.textColor = [UIColor whiteColor];
    btn.layer.cornerRadius = 20;
    [btn setTitle:DPLocalizedString(@"Setting_NextStep") forState: UIControlStateNormal];
    [btn addTarget:self action:@selector(nextBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:btn];
    return view;
}
@end
