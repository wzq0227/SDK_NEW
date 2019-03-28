//
//  SettingViewController.m
//  goscamapp
//
//  Created by goscam_sz on 17/5/6.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "SettingViewController.h"
#import "DeviceSettingView.h"
#import "DeviceInfoViewController.h"
#import "DetailSettingWiFiSettingVC.h"
#import "NightVersionViewController.h"
#import "ShareWithFriendsViewController.h"
#import "MotionDetectSettingVC.h"
#import "LightDurationViewController.h"
#import "VoiceDetectSettingVC.h"
#import "TimecheckViewController.h"
#import "TemperatureAlarmTableViewController.h"
#import "SaveDataModel.h"
#import "BaseCommand.h"
#import "CBSCommand.h"
#import "NetSDK.h"
#import "DevPushManagement.h"
#import "PlayListViewController.h"
#import "BabyMusicSettingViewController.h"
#import "CloudServiceOrderInfoVC.h"
#import "CSPackageTypeVC.h"
#import "CloudRecordingServiceInfoVC.h"
#import "CSNetworkLib.h"
#import "AlexaSkillViewController.h"
#import "GOSDeviceShareListVC.h"

#import "TalkingModeSettingVC.h"
#import "GOSThirdPartyAccessVC.h"

#import "DoorBellRingViewController.h"

@interface SettingViewController ()

@property (nonatomic,strong) DeviceSettingView * setView;
@property(nonatomic,strong)NetSDK *netSDK;

@property(nonatomic,strong)__block CMD_GetAllParamResp *getAllParamResp;

@property (strong, nonatomic)  UISettingModel *settingModel;

/** 获取设备能力resp */
@property (nonatomic, strong)__block CMD_GetDevAbilityResp *devAbilityCmd;

@property (strong, nonatomic)  CSNetworkLib *csNetworkLib;

@property (strong, nonatomic)  NSString *token;

@property (strong, nonatomic)  CSQueryCurServiceResp *curServiceResp;

@property (assign, nonatomic)  int userOnceBoughtService;

@property (assign, nonatomic)  BOOL hasRefreshedWithModel;
@end

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.setView= [[NSBundle mainBundle]loadNibNamed:@"DeviceSettingView" owner:self options:nil].lastObject;
    self.setView.frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height);
    self.setView.model = self.model;
    
    _settingModel = [[UISettingManagement sharedInstance] getSettingModel:_model.DeviceId];
    
    if (self.model.Status != GosDeviceStatusOffLine ) {
        if (!_settingModel) {
            [self getDevAbilityFromServer];
        }else{
            _settingModel.capModel = self.model.devCapModel;
            [self.setView refreshTableViewWithModel:_settingModel];
            [self getDeviceSettings];
        }
    }
    
    [self addClickEventForSettingView];
    
    [self configUI];
    
    
    [self.view addSubview:_setView];
    
}


- (void)viewWillAppear:(BOOL)animated{

    [super viewWillAppear:animated];
    
    if (isCloudServiceReady) {
        [self queryCurServiceOfDevice];
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if ([SVProgressHUD isVisible]) {
        [SVProgressHUD dismiss];
    }
}

- (void)configUI{
    self.title = DPLocalizedString(@"Setting_Setting");
    self.automaticallyAdjustsScrollViewInsets = YES;
    self.navigationController.navigationBar.translucent = NO;

}

- (void)configModel{
    self.userOnceBoughtService = -1;
}

-(void)getDevAbilityFromServer
{
    __weak typeof(self) weakSelf = self;
    NSDictionary *reqData = [[[CMD_GetDevAbilityReq alloc]init] requestCMDData];
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:self.model.DeviceId requestData:reqData timeout:15000 responseBlock:^(int result, NSDictionary *dict) {
        if (result ==0) {
            weakSelf.devAbilityCmd = [CMD_GetDevAbilityResp yy_modelWithDictionary:dict];
            
            //传入结构体进行初始化
            if (nil != weakSelf.model.DeviceId)
            {
                UISettingModel *modelinfo =[[UISettingModel alloc]initModelWithAbilityCmd:weakSelf.devAbilityCmd UID:weakSelf.model.DeviceId];
                
                modelinfo.capModel = weakSelf.model.devCapModel;
                
                weakSelf.settingModel = modelinfo;
                
                //存入模型
                [[UISettingManagement sharedInstance] addSettingModel:modelinfo];
                
                [weakSelf getDeviceSettings];

                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.setView refreshTableViewWithModel:modelinfo];
                });
            }
        }
    }];
}


- (void)getDeviceSettings{

    CMD_GetAllParamReq *req = [CMD_GetAllParamReq new];
    
    __weak typeof(self) weakSelf = self;
    
    [SVProgressHUD showWithStatus:@"Loading..."];
    
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:_model.DeviceId requestData:[req requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            weakSelf.getAllParamResp = [CMD_GetAllParamResp yy_modelWithDictionary:dict];
            
            [weakSelf.setView  refreshTableViewWithResp:weakSelf.getAllParamResp];
        }
        [weakSelf dealWithGetOperationResultWithResult:result];
    }];
}

- (void)dealWithGetOperationResultWithResult:(int)result{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (result!=0) {
            if ([SVProgressHUD isVisible]) {
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Get_data_failed")];
            }
        }else{
            [SVProgressHUD dismiss];
        }
    });
}

- (void)dealWithOperationResultWithResult:(int)result{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (result!=0) {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
        }else{
            [SVProgressHUD dismiss];
        }
    });
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//
- (void)showDeleteAlert{
    NSString *alertTitle,*alertMsg;
    if ( self.model.DeviceOwner == GosDeviceShare ) {
        alertTitle = MLocalizedString(Setting_DeleteDeviceAlert_Title);
        alertMsg = MLocalizedString(Setting_DeleteDeviceAlert_Msg);
    }else{
        alertTitle = MLocalizedString(DeleteDev_Warnig);
        alertMsg = MLocalizedString(CSOrder_DeleteDevice_WipeData_Tip);
    }
    [self showAlertWithTitle:alertTitle Msg:alertMsg];
}

- (void)showAlertWithTitle:(NSString*)title Msg:(NSString *)msg{
    UIAlertView *msgAlert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:DPLocalizedString(@"Setting_Cancel") otherButtonTitles:DPLocalizedString(@"Title_Confirm"), nil];
    [msgAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self unbindDevice];
    }
}

- (void)unbindDevice{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [SVProgressHUD showWithStatus:@"Loading..."];
    });
    
    BodyUnbindRequest *body = [BodyUnbindRequest new];
    CBS_UnbindRequest *req  = [CBS_UnbindRequest new];
    body.DeviceId           = _model.DeviceId;
    body.UserName           = [SaveDataModel getUserName];
    body.DeviceOwner        = _model.DeviceOwner;
    req.Body = body;

    __weak typeof(self) weakSelf = self;
    [[DevPushManagement shareDevPushManager] deletePushWithDeviceId:_model.DeviceId resultBlock:^(BOOL isSuccess) {
        NSLog(@"Delete_Dev_Remove_Push_result:%d",isSuccess);
        
        if (isSuccess) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [[NetSDK sharedInstance] net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:12000 responseBlock:^(int result, NSDictionary *dict) {
    
                [strongSelf showUnbindOperationResultWithValue:result];
            }];
        }else{
            [weakSelf showUnbindOperationResultWithValue:-1];
        }
    }];
}


- (void)showUnbindOperationResultWithValue:(int)result{

    [self dealWithOperationResultWithResult:result];
    if (result ==0 ) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[NSNotificationCenter defaultCenter]postNotificationName:REFRESH_DEV_LIST_NOTIFY object:nil];

            [self.navigationController popToRootViewControllerAnimated:YES];
        });
    }
}

//查询当前设备是否开通过云存储
- (void)queryCurServiceOfDevice{
    
    _csNetworkLib = [CSNetworkLib sharedInstance];
    self.token = [mUserDefaults objectForKey:USER_TOKEN];
    
    if (self.model.Status==GosDeviceStatusOffLine) {
        [SVProgressHUD showWithStatus:@"loading..."];
    }
    
    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api/cloudstore/cloudstore-service/service/current",kCloud_IP];

    NSString *urlStrWithParams = [NSString stringWithFormat:@"%@?device_id=%@&token=%@&username=%@&version=1.0",urlStr,self.model.DeviceId,self.token,[SaveDataModel getUserName]];
    
    __weak typeof(self) wSelf = self;
    [_csNetworkLib requestWithURLStr:urlStrWithParams method:@"GET" result:^(int result, NSData *data) {
        NSDictionary  *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        if (result == 0 || result == 1200) {
            //0 正在用 1200 云存储服务已过期
            wSelf.curServiceResp             = [CSQueryCurServiceResp yy_modelWithDictionary:dict[@"data"]];
            wSelf.userOnceBoughtService      = YES;
            wSelf.setView.dataStorageTime    = wSelf.curServiceResp.dateLife;
        }else if(result == 1204){ //1204 服务不可用（未开通或已过期）
            wSelf.userOnceBoughtService     = NO;
            wSelf.setView.dataStorageTime   = 0;
        }
        [wSelf showQueryResult:result];
    }];
}

- (void)showQueryResult:(int)result{

    dispatch_async(dispatch_get_main_queue(), ^{

        if (result==0 ||
            result == 1204 ||
            result == 1200) {
            
            if (self.model.Status==GosDeviceStatusOffLine) {
                [SVProgressHUD dismiss];
            }

            if (self.model.Status == GosDeviceStatusOnLine || _hasRefreshedWithModel) {
                [self.setView refreshTableView];
            }else if(!_hasRefreshedWithModel){
                _hasRefreshedWithModel = YES;
                [self.setView refreshTableViewWithModel:_settingModel];
            }
        }
        else{
            if (self.model.Status==GosDeviceStatusOffLine) {
                [SVProgressHUD dismiss]; //showErrorWithStatus:DPLocalizedString(@"Get_data_failed");
            }
        }
    });
}

- (void)gotoCloudServicePage{
    if (self.userOnceBoughtService == -1) {//上次查询失败再去查询
        [self queryCurServiceOfDevice];
    }else if (self.userOnceBoughtService == 0){//未开通过
        
        CSPackageTypeVC *orderVC = [CSPackageTypeVC new];

//        CloudRecordingServiceInfoVC *orderVC = [CloudRecordingServiceInfoVC new];
        orderVC.deviceModel                     = self.model;
        [self.navigationController pushViewController:orderVC animated:YES];
    }else{//已开通
        CloudServiceOrderInfoVC *renewVC = [[CloudServiceOrderInfoVC alloc] init];
        renewVC.curServiceResp           = self.curServiceResp;
        renewVC.deviceModel                 = self.model;
        [self.navigationController pushViewController:renewVC animated:YES];
    }
}

- (void)addClickEventForSettingView{
    
    __weak typeof(self) weakSelf = self;

    [self.setView deleteDeviceCallback:^{
            [weakSelf showDeleteAlert];
    }];
    
    [self.setView didSelectRowCallback:^(DeviceSettingType type) {
        
        switch (type) {
                
            case DeviceSettingMotionDetection:
            {
                MotionDetectSettingVC *vc =[[MotionDetectSettingVC alloc]init];
                vc.model = _model;
                vc.getAllParamResp = _getAllParamResp;
                [self.navigationController pushViewController:vc animated:YES];
                break;

                break;
            }
            case DeviceSettingVoiceDetection:
            {
                
                VoiceDetectSettingVC *vc =[[VoiceDetectSettingVC alloc]init];
                vc.model = _model;
                vc.getAllParamResp = _getAllParamResp;
                [self.navigationController pushViewController:vc animated:YES];

                break;
            }
                
            case DeviceSettingTempAlarmSetting:
            {
                
                TemperatureAlarmTableViewController *vc =[[TemperatureAlarmTableViewController alloc]init];
                vc.deviceID = _model.DeviceId;
                [self.navigationController pushViewController:vc animated:YES];
                
                break;
            }
                
            case DeviceSettingPhotoAlbum:
            {
                PlayListViewController *vc = [[PlayListViewController alloc]init];
                vc.deviceID                = [_model.DeviceId substringFromIndex:8];
                vc.model                   = _model;
                vc.positionType            = PositionMain;
                [self.navigationController pushViewController:vc animated:YES];
                break;
            }

            case DeviceSettingLightDuration:
            {
                LightDurationViewController *vc = [[LightDurationViewController alloc]init];
                vc.model = _model;
                [self.navigationController pushViewController:vc animated:YES];
                break;
            }
                
            case DeviceSettingCloudService:{
                [self gotoCloudServicePage];
                break;
            }

            case DeviceSettingTalkingMode:{
                [self gotoTalkingModeSettingPage];
                break;
            }
                
            case DeviceSettingNightVersion:
            {
                NightVersionViewController *vc =[[NightVersionViewController alloc]init];
                vc.model = _model;
                [self.navigationController pushViewController:vc animated:YES];
                break;
            }
            case DeviceSettingShareWithFriends:
            {
//                NSString *csbIPStr =  [[NSUserDefaults standardUserDefaults] objectForKey:@"kCBS_IP"];
                
                
//                if ([csbIPStr isEqualToString:@"119.23.124.137"]) {
                    GOSDeviceShareListVC *vc =[[GOSDeviceShareListVC alloc]init];
                    vc.devModel = _model;
                    [self.navigationController pushViewController:vc animated:YES];
//                }else{
//                    ShareWithFriendsViewController *vc =[[ShareWithFriendsViewController alloc]init];
//                    vc.model = _model;
//                    [self.navigationController pushViewController:vc animated:YES];
//                }
             
                break;
            }
                
            case DeviceSettingTimeCheck:
            {
                TimecheckViewController *vc =[[TimecheckViewController alloc]init];
                vc.deviceID = _model.DeviceId;
                [self.navigationController pushViewController:vc animated:YES];
                break;
            }
                
            case DeviceSettingWiFiSetting:
            {
                DetailSettingWiFiSettingVC *vc =[[DetailSettingWiFiSettingVC alloc]init];
                vc.model = _model;
                [self.navigationController pushViewController:vc animated:YES];
                break;
            }
            case DeviceSettingDeviceInfo:
            {
                DeviceInfoViewController *vc = [[DeviceInfoViewController alloc]init];
                vc.model = _model;
                [self.navigationController pushViewController:vc animated:YES];
                break;
            }
                
            case DeviceSettingBabyMusic:
            {
                //待处理
                BabyMusicSettingViewController *babyMusicVC = [[BabyMusicSettingViewController alloc]init];
                babyMusicVC.deviceID = _model.DeviceId;
                [self.navigationController pushViewController:babyMusicVC animated:YES];
                break;
            }
                
            case DeviceSettingAlexa:
            {
                //待处理
//                AlexaSkillViewController *alexaVC = [[AlexaSkillViewController alloc]init];
                GOSThirdPartyAccessVC *vc = [GOSThirdPartyAccessVC new];
                vc.thirdPartySupport = _settingModel.ability_c_Alexa_Skills_Kit_flag;
                [self.navigationController pushViewController:vc animated:YES];
                break;
            }
              
            case DeviceSettingUnbindSubDevice:
            {
                [self unbindSubDev];
                break;
            }

            case DeviceSettingDBBellRemindSetting:
            {
                DoorBellRingViewController *vc = [[DoorBellRingViewController alloc] init];
                vc.model = self.model;
                vc.getAllParamResp = self.getAllParamResp;
                [self.navigationController pushViewController:vc animated:YES];
                break;
            }
            
            default:
                break;
        }
        
    }];
}

- (void)gotoTalkingModeSettingPage{
    TalkingModeSettingVC *vc = [TalkingModeSettingVC new];
    vc.deviceID = self.model.DeviceId;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)unbindSubDev{
    
    CMD_DeleteSubDeviceReq *req = [CMD_DeleteSubDeviceReq new];
    
    [SVProgressHUD showWithStatus:@"Loading"];

    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:_model.DeviceId requestData:[req requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (result == 0) {
                [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Operation_Succeeded")];
            }else{
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
            }
            
        });
    }];
    //
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
