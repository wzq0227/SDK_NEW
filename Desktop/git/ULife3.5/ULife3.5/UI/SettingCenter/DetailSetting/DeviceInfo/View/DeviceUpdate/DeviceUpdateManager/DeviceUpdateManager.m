//
//  DeviceUpdateManager.m
//  ULife3.5
//
//  Created by Goscam on 2018/4/4.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "DeviceUpdateManager.h"
#import "CMSCommand.h"
#import "BaseCommand.h"
#import "SaveDataModel.h"
#import "DeviceDataModel.h"
#import "Masonry.h"
#import "NetSDK.h"
#import "DeviceUpdateView.h"
#import "DeviceUpdateTipsView.h"

#import "UISettingManagement.h"

@interface DeviceUpdateManager()<UIAlertViewDelegate>
{
    
    DeviceUpdateView *updateView;
    UIView *updateViewBg;

    DeviceUpdateTipsView *updateTipsView;
}

@property(nonatomic,strong)UIAlertView *updateAlertView;

@property(nonatomic,strong)NSTimer     *updateProgressTimer;

@property(nonatomic,strong)NSTimer     *autoUpdateProgressTimer;

/**
 设备端下载完升级包后，开始写Flash等操作(需要44S)，此时进度由App显示
 进度显示为30+count/22 *(98-30)
 */
@property(nonatomic,assign)int timerCountAfterUpdateThirdStage;//30+count/22 *(98-30)

@property (strong, nonatomic)  CMD_GetDevInfoResp *getDevInfoResp;

@property (strong, nonatomic)  __block CMD_QueryNewerVersionResp *queryUpdateResp;


@property (assign, nonatomic)  BOOL needToUpdate;

@property (assign, nonatomic)  UpdateStage updateStage;

@property (strong, nonatomic)  DevUpdateResultBlock resultBlock;

@property (strong, nonatomic)  DevUpdateStateBlock updateStateBlock;
@end


@implementation DeviceUpdateManager


-(void)queryDeviceUpdateState:(DevUpdateStateBlock)updateStateBlock{
    self.updateStateBlock = updateStateBlock;
    
    [self getDeviceInfo];
}

#pragma mark - 1:getDevInfo
- (void)getDeviceInfo{

    CMD_GetDevInfoReq *req = [CMD_GetDevInfoReq new];
    __weak typeof(self) wSelf = self;
    
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:self.deviceId requestData:[req requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            wSelf.getDevInfoResp = [CMD_GetDevInfoResp yy_modelWithDictionary:dict];
            
            [wSelf queryUpdateStateWithVersion:(wSelf.isWiFiDoorBell?wSelf.getDevInfoResp.a_gateway_version: wSelf.getDevInfoResp.a_software_version)];
        }
    }];
}

#pragma mark - 2:queryUpdateState
- (void)queryUpdateStateWithVersion:(NSString*)version {
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        NSArray *arr = [version componentsSeparatedByString:@"."];
        CMD_QueryNewerVersionReq *req = [CMD_QueryNewerVersionReq new];
        req.DeviceId = self.deviceId;
        req.FwVersion = arr[2];
        req.AppVersion = arr[3];
        req.DevType = arr[1];
        req.CustomType = arr[0];
        req.HardWareVersion = _getDevInfoResp.a_hardware_version;
        
        NSData *data = [NSJSONSerialization dataWithJSONObject:[req requestCMDData] options:0 error:nil ];
        ServerAddress *upsAddr = [ServerAddress yy_modelWithDictionary:[mUserDefaults objectForKey:@"UPSAddress"]];
        
        if (_updateStage == UpdateStageDownloading || _updateStage ==UpdateStageUpdating){
            return;
        }
        
        NSString *ipAddress = upsAddr.Address;
        int       port      = upsAddr.Port;
        [[NetSDK sharedInstance] net_queryDeviceVersionWithIP:ipAddress port:port data:data responseBlock:^(int result, NSDictionary *dict) {
            if (result == 0) {
                
                _queryUpdateResp = [CMD_QueryNewerVersionResp yy_modelWithJSON:dict];
                if(_queryUpdateResp.HasNewer==1){
                    weakSelf.needToUpdate = YES;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf showUpdateAlertView];
                    });
                }
                else{
                    weakSelf.needToUpdate = NO;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (weakSelf.updateStateBlock) {
                        weakSelf.updateStateBlock(weakSelf.needToUpdate);
                    }
                });
            }
        }];
    });
}

#pragma mark - 3: showUpdateTips
- (void)showUpdateAlertView{
    
    updateTipsView = [[NSBundle mainBundle] loadNibNamed:@"DeviceUpdateTipsView" owner:self options:nil][0];
    updateTipsView.layer.cornerRadius = 10;
    
    //app = "308.app.E_900.tar.bz2";
    NSMutableArray *newVersionArray = [[_queryUpdateResp.app componentsSeparatedByString:@"."] mutableCopy];
    NSMutableArray *oldVersionArray = [[(self.isWiFiDoorBell?_getDevInfoResp.a_gateway_version: _getDevInfoResp.a_software_version) componentsSeparatedByString:@"."] mutableCopy];
    
    if (newVersionArray.count>0 && oldVersionArray.count>=4) {
        oldVersionArray[3] = newVersionArray[0];
    }
    NSString *versionStr = [oldVersionArray componentsJoinedByString:@"."];
    
    updateTipsView.versionInfo.text = [NSString stringWithFormat:@"%@ %@",DPLocalizedString(@"Update_CanUpdateTo"),versionStr];
    
    updateTipsView.updateContentTxt.userInteractionEnabled = NO;
    updateTipsView.updateContentTxt.text = _queryUpdateResp.Des[@"app"];
    updateTipsView.updateTipsTitle.text = DPLocalizedString(@"Update_FirmwareUpdate");
    
    [updateTipsView.updateNowBtn setTitle:DPLocalizedString(@"Update_UpdateRightNow") forState:0];
    [updateTipsView.updateNowBtn addTarget:self action:@selector(updateNowBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [updateTipsView.updateNextTimeBtn setTitle:DPLocalizedString(@"Update_UpdateNextTime") forState:0];
    [updateTipsView.updateNextTimeBtn addTarget:self action:@selector(updateNextTimeBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    
    updateViewBg = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    updateViewBg.backgroundColor = [UIColor blackColor];
    updateViewBg.alpha = 0.5;
    
    [self addUpdateTipsViewIntoKeyWindow];
}

- (void)addUpdateTipsViewIntoKeyWindow{
    
    if (!updateTipsView.superview) {
        [[UIApplication sharedApplication].keyWindow addSubview:updateViewBg];
        [[UIApplication sharedApplication].keyWindow addSubview: updateTipsView];
        [updateTipsView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(updateViewBg);
            make.height.mas_equalTo(240);
            //            make.leading.equalTo(updateViewBg).offset(25);
            make.width.equalTo(updateTipsView.mas_height).multipliedBy(280/240.0);
        }];
    }
}

- (void)removeUpdateTipsView{
    dispatch_async(dispatch_get_main_queue(), ^{
        [updateTipsView removeFromSuperview];
        updateTipsView = nil;
        [updateViewBg removeFromSuperview];
        updateViewBg = nil;
    });
}

#pragma mark - 4: Updating
- (void)startToUpdateDevice{
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showWithStatus:@"Loading..."];
    });
    
    CMD_UpdateDeviceReq *req = [CMD_UpdateDeviceReq new];
    req.a_ipaddr = _queryUpdateResp.UpsIp;
    req.un_port  = _queryUpdateResp.UpsPort;
    req.cancelFlag = 0;
    
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:self.deviceId requestData:[req requestCMDData] timeout:12000 responseBlock:^(int result, NSDictionary *dict) {
        CMD_UpdateDeviceResp *resp = [CMD_UpdateDeviceResp yy_modelWithDictionary:dict];
        
        if (result == 0) {
            [weakSelf showUpdateStateWithResult:resp.result];
        }
        
        [weakSelf dealWithOperationResultWithResult:result];
    }];
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

- (void)showUpdateStateWithResult:(int)result{
    if( result == 0 ){
        [self showUpdatingDeviceView];
    }else if( result >= 100 && result<=200 ){
        
        if (result >= 130 ) {
            _updateStage = UpdateStageUpdating;
            if (!_autoUpdateProgressTimer) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _autoUpdateProgressTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(autoUpdateProgressTimerFunc) userInfo:nil repeats:YES];
                });
            }
        }else{
            [self updateViewWithProgress:(result-100)];
        }
        
    }else if(result == 3){
        if (_updateStage == UpdateStageDownloading || _updateStage == UpdateStageUpdating) {
            [self showUpdateErrorInfo];
            //            [self updateViewWithProgress:0];
            //            [self showUpdateErrorAndTryAgain];
        }
    }
    else if(result == 4 || result ==5){
        
        [self updateViewWithProgress:100];
        _updateStage = UpdateStageSucceeded;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissUpdateDeviceViewAndShowThirdStage];
        });
    }else if(result <= 2){ ////1->请求下载失败，申请内存失败 //2->请求下载失败,设备端创建线程失败
        [self showUpdateErrorInfo];
    }
}

- (void)showUpdatingDeviceView{ //防止设备端在升级下载的1,2,3阶段，突然返回一个0
    
    if (_updateStage == UpdateStageDownloading || _updateStage == UpdateStageUpdating || _updateStage == UpdateStageSucceeded) {
        return;
    }
    _updateStage = UpdateStageDownloading;
    _timerCountAfterUpdateThirdStage = 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self configureForUpdateView];
        [self addUpdateViewIntoKeyWindow];
        
        [self startUpdateProgressTimer];
    });
}

- (void)startUpdateProgressTimer{
    
    if(!_updateProgressTimer){
        _updateProgressTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(updateProgressTiemrFunc:) userInfo:nil repeats:YES];
    }
}

- (void)stopProgressTimer{
    if([_updateProgressTimer isValid ]){
        [_updateProgressTimer invalidate];
        _updateProgressTimer = nil;
    }
}

- (void)updateProgressTiemrFunc:(id)sender{
    __weak typeof(self) weakSelf = self;
    
    
    CMD_UpdateDeviceReq *req = [CMD_UpdateDeviceReq new];
    req.a_ipaddr = _queryUpdateResp.UpsIp;
    req.un_port  = _queryUpdateResp.UpsPort;
    req.cancelFlag = 0;
    
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:self.deviceId requestData:[req requestCMDData] timeout:12000 responseBlock:^(int result, NSDictionary *dict) {
        CMD_UpdateDeviceResp *resp = [CMD_UpdateDeviceResp yy_modelWithDictionary:dict];
        if (result == 0) {
            [weakSelf showUpdateStateWithResult:resp.result];
        }
    }];
}

- (void)showUpdateErrorAndTryAgain{
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showWithStatus:DPLocalizedString(@"Update_DownloadErrorTryAgain")];
        [SVProgressHUD dismissWithDelay:2];
    });
}


- (void)showUpdateErrorInfo{
    _updateStage = UpdateStageFailed;
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showWithStatus:DPLocalizedString(@"Update_UpdateError_TryAgainLater")];
        [SVProgressHUD dismissWithDelay:3];
        
        [updateView removeFromSuperview];
        updateView = nil;
        [updateViewBg removeFromSuperview];
        updateViewBg = nil;
    });
}

- (void)updateViewWithProgress:(int)progress{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if(!updateView){
            [self configureForUpdateView];
        }
        if(!updateView.superview){
            [self addUpdateViewIntoKeyWindow];
        }
        if(!_updateProgressTimer){
            _updateProgressTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(updateProgressTiemrFunc:) userInfo:nil repeats:YES];
        }
        updateView.updateProgressView.progress = progress*1.0/100;
        updateView.updateProgressLabel.text = [NSString stringWithFormat:@"%d/100",progress];
    });
}

- (void)autoUpdateProgressTimerFunc{
    
    if (_updateStage == UpdateStageSucceeded) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_autoUpdateProgressTimer invalidate];
            _autoUpdateProgressTimer = nil;
        });
        return;
    }
    
    if ( _timerCountAfterUpdateThirdStage++ > 440) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_autoUpdateProgressTimer invalidate];
            _autoUpdateProgressTimer = nil;
        });
    }
    int progress = 30 + _timerCountAfterUpdateThirdStage/440.0 *(99-30);
    if (progress>99) {
        progress = 99;
    }
    [self updateViewWithProgress:progress];
}

- (void)dismissUpdateDeviceViewAndShowThirdStage{
    
    _timerCountAfterUpdateThirdStage = 0;
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil message:DPLocalizedString(@"Update_Tips_DowloadComplete") delegate:nil cancelButtonTitle:DPLocalizedString(@"Title_Confirm") otherButtonTitles:nil];
    alert.delegate = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopProgressTimer];
        
        [updateView removeFromSuperview];
        updateView = nil;
        [updateViewBg removeFromSuperview];
        updateViewBg = nil;
        
        [alert show];
    });
    
    //移除能力集缓存
    [[UISettingManagement sharedInstance] removeSettingModel:self.deviceId];
}

#pragma mark - 取消升级
- (void)cancelUpdateBtnClicked:(id)sender{
    CMD_CancelUpdateDeviceReq *req = [CMD_CancelUpdateDeviceReq new];
    req.a_ipaddr = _queryUpdateResp.UpsIp;
    req.un_port  = _queryUpdateResp.UpsPort;
    req.cancelFlag = 1;
    
    __weak typeof(self) weakSelf = self;
    
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:self.deviceId requestData:[req requestCMDData] timeout:12000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            [weakSelf actionForCancelUpdate];
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showInfoWithStatus:DPLocalizedString(@"Operation_Failed")];
            });
        }
    }];
}

- (void)actionForCancelUpdate{
    _updateStage = UpdateStageCancelled;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (_autoUpdateProgressTimer) {
            [_autoUpdateProgressTimer invalidate];
            _autoUpdateProgressTimer  = nil;
        }
        
        if (_updateProgressTimer) {
            [_updateProgressTimer invalidate];
            _updateProgressTimer = nil;
        }
        
        [updateView removeFromSuperview];
        updateView = nil;
        [updateViewBg removeFromSuperview];
        updateViewBg = nil;
        
        [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Update_CancelSucceeded")];
        
        if (self.resultBlock) {
            self.resultBlock(NO);
        }
    });
}

- (void)configureForUpdateView {
    
    updateView = [[[NSBundle mainBundle] loadNibNamed:@"DeviceUpdateView" owner:self options:nil] objectAtIndex:0];
    updateView.layer.cornerRadius = 10;
    
    updateView.updateTipsTxtView.userInteractionEnabled = NO;
    updateView.updateTipsTxtView.text = DPLocalizedString(@"Update_Tips_Downloading");
    [updateView.updateTitleLabel setText:DPLocalizedString(@"Update_Downloading")];
    [updateView.cancelUpdateBtn setTitle:DPLocalizedString(@"Setting_Cancel") forState: UIControlStateNormal];
    [updateView.cancelUpdateBtn addTarget:self action:@selector(cancelUpdateBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
#warning 先屏蔽 取消升级按钮
    updateView.cancelUpdateBtn.userInteractionEnabled = NO;
    [updateView.cancelUpdateBtn setTitle:DPLocalizedString(@"") forState: UIControlStateNormal];

    
    updateViewBg = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    updateViewBg.backgroundColor = [UIColor blackColor];
    updateViewBg.alpha = 0.5;
}

- (void)addUpdateViewIntoKeyWindow{
    
    if (!updateView.superview) {
        [[UIApplication sharedApplication].keyWindow addSubview:updateViewBg];
        [[UIApplication sharedApplication].keyWindow addSubview: updateView];
        [updateView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(updateViewBg);
            make.leading.equalTo(updateViewBg).offset(30);
            make.width.equalTo(updateView.mas_height).multipliedBy(28/20.0);
        }];
    }
}



- (void)updateNowBtnClicked:(id)sender{
    [self removeUpdateTipsView];
    [self startToUpdateDevice];
}
extern bool gos_firmware_next_time_update;
- (void)updateNextTimeBtnClicked:(id)sender{
    [self removeUpdateTipsView];
    
    if (self.resultBlock) {
        gos_firmware_next_time_update = true;
        self.resultBlock(NO);
    }
}

- (void)userFinishUpdatingCallback:(DevUpdateResultBlock)resultBlock
{
    self.resultBlock = resultBlock;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (self.resultBlock) {
        self.resultBlock(YES);
    }
}


- (void)showUpdateAlertWithTitle:(NSString*)title Message:(NSString*)msg cancelTitle:(NSString*)cancelTitle
                    confirmTitle:(NSString*)confirmTitle{
    _updateAlertView = [[UIAlertView alloc]initWithTitle:title message:msg delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:confirmTitle, nil];
    _updateAlertView.delegate = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_updateAlertView show];
    });
    
//    if( [[UIDevice currentDevice]systemVersion].floatValue < 8 ){
//    }else{
//    }
}


@end
