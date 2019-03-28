//
//  VoiceDetectSettingVC.m
//  ULife3.5
//
//  Created by zhuochuncai on 12/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "VoiceDetectSettingVC.h"
#import "NetSDK.h"
#import "SensitivitySettingTableViewCell.h"
#import "settingCell.h"

@interface VoiceDetectSettingVC ()<UITableViewDelegate,UITableViewDataSource>
@property(nonatomic,strong)CMD_AudioAlarm   *audioAlarmData;
@property(nonatomic,strong)CMD_AudioAlarm   *tempReq;
@property(nonatomic,strong)NetSDK *netSDK;
@property(nonatomic,assign)BOOL isChanged;
@end

@implementation VoiceDetectSettingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChanged = NO;
    [self configUI];
    [self configureTableView];
    [self getSensitivitySetting];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if ([SVProgressHUD isVisible]) {
        [SVProgressHUD dismiss];
    }
}

- (void)configureTableView{
    

    [self.tableView registerNib:[UINib nibWithNibName:@"SensitivitySettingTableViewCell" bundle:nil] forCellReuseIdentifier:@"SensitivitySettingTableViewCell"];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"settingCell" bundle:nil] forCellReuseIdentifier:@"cell"];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

#pragma mark ==<TableViewDelegate>

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return 1;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.section) {
        case 0:
            return 50;
        case 1:
            return 71;
    }
    return 50;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    __weak typeof(self) weakSelf = self;

    if (indexPath.section == 0) {
        settingCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
        [cell.settingSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
        cell.settingSwitch.on = (_audioAlarmData.un_switch == 1);

        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.settingArrow.hidden = cell.detailLabel.hidden = YES;
        cell.iconImageView.image = [UIImage imageNamed:@"Setting_VoiceDetection"];
        cell.nameLabel.text = DPLocalizedString(@"Setting_VoiceDetection");
        return cell;
    }
    else if (indexPath.section == 1 ) {
        SensitivitySettingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SensitivitySettingTableViewCell" forIndexPath:indexPath];
        cell.tag = indexPath.section;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.lowLabel.text = DPLocalizedString(@"Setting_Sensitivity_Low");
        cell.defaultLabel.text = DPLocalizedString(@"Setting_Sensitivity_Default");
        cell.highLabel.text = DPLocalizedString(@"Setting_Sensitivity_High");
        
        cell.slider.value = _audioAlarmData?(_audioAlarmData.un_sensitivity - 1 ) *0.5:0.5;
        
        [cell sliderValueChangeCallback:^(int sectionIndex, int selectPosition) {
            weakSelf.isChanged = YES;
            [weakSelf sendSensitivitySettingRequestWithType:sectionIndex positionValue:selectPosition];
        }];
        return cell;
    }
    return nil;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    
    return section==1?DPLocalizedString(@"Setting_VoiceSensitivity"):@"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return section == 0 ? 30:40;
}


- (void)switchValueChanged:(id)sender{
    _isChanged = YES;
    UISwitch *mySwitch = (UISwitch*)sender;
    BOOL isON = mySwitch.on;
    _audioAlarmData.un_switch = (int)isON;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark <保存>
- (void)configNavigationItem{
    
    
    UIImage *image = [UIImage imageNamed:@"addev_back"];
    EnlargeClickButton *button = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 70, 40);
    button.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 50);
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self
               action:@selector(navBack)
     forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    leftBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
    
    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    saveBtn.frame     = CGRectMake(0, 0, 60, 40);
    [saveBtn setTitle:DPLocalizedString(@"Title_Save") forState:0];
    [saveBtn addTarget:self action:@selector(saveBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:saveBtn];
}


- (void)navBack{
    if (_isChanged) {
        //发生了设置更改弹窗
        UIAlertController *alertView = [UIAlertController alertControllerWithTitle:nil
                                                                           message:DPLocalizedString(@"Setting_Save_title")
                                                                    preferredStyle:UIAlertControllerStyleAlert];
        
        
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:DPLocalizedString(@"Setting_Save_YES")
                                                                style:UIAlertActionStyleDestructive
                                                              handler:^(UIAlertAction * _Nonnull action) {
                                                                  [self finishSetting];
                                                              }];
        
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:DPLocalizedString(@"Setting_Cancel")
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction * _Nonnull action) {
                                                                 [self.navigationController popViewControllerAnimated:YES];
                                                             }];
        [alertView addAction:confirmAction];
        [alertView addAction:cancelAction];
        [self presentViewController:alertView
                           animated:YES
                         completion:nil];
        
        
    }
    else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}


//完成设置
- (void)finishSetting{
    [SVProgressHUD showWithStatus:@"Loading..."];
    CMD_SetAudioAlarmReq *req = [CMD_SetAudioAlarmReq new];
    _tempReq.CMDType = _audioAlarmData.CMDType = req.CMDType;
    __weak typeof(self) weakSelf = self;
    [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[_audioAlarmData requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        if (result != 0) {
            weakSelf.audioAlarmData = [CMD_SetAudioAlarmReq yy_modelWithDictionary:[weakSelf.tempReq yy_modelToJSONObject]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
                [weakSelf.navigationController popViewControllerAnimated:YES];
            });
            
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.isChanged = NO;
                weakSelf.tempReq = [CMD_SetAudioAlarmReq yy_modelWithDictionary:[weakSelf.audioAlarmData yy_modelToJSONObject]];
                [weakSelf.navigationController popViewControllerAnimated:YES];
            });
        }
    }];
}



- (void)saveBtnClicked:(id)sender{
    [SVProgressHUD showWithStatus:@"Loading..."];
    CMD_SetAudioAlarmReq *req = [CMD_SetAudioAlarmReq new];
    _tempReq.CMDType = _audioAlarmData.CMDType = req.CMDType;
    __weak typeof(self) weakSelf = self;
    [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[_audioAlarmData requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        if (result != 0) {
            weakSelf.audioAlarmData = [CMD_SetAudioAlarmReq yy_modelWithDictionary:[weakSelf.tempReq yy_modelToJSONObject]];
        }else{
            weakSelf.isChanged = NO;
            weakSelf.tempReq = [CMD_SetAudioAlarmReq yy_modelWithDictionary:[weakSelf.audioAlarmData yy_modelToJSONObject]];
        }
        [weakSelf dealWithOperationResultWithResult:result];
    }];
    
}


#pragma mark <SensitivitySetting>
- (void)sendSensitivitySettingRequestWithType:(int)type positionValue:(float)value{
    
    [self sendAudioSensitivitySettingRequestWithValue:value+1];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}


- (void)configUI{
    self.title = DPLocalizedString(@"Setting_VoiceDetection");
    self.view.backgroundColor = BACKCOLOR(238,238,238,1);
    [self configNavigationItem];
}


- (void)getSensitivitySetting{
    
    _netSDK = [NetSDK sharedInstance];
    [SVProgressHUD showWithStatus:@"Loading..."];
    
    __weak typeof(self) weakSelf = self;
    CMD_GetAudioAlarmReq *req = [CMD_GetAudioAlarmReq new];
    [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[req requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        
        if (result == 0) {
            weakSelf.audioAlarmData = [CMD_AudioAlarm yy_modelWithJSON:dict];
            weakSelf.tempReq = [CMD_AudioAlarm yy_modelWithJSON:dict];
        }else{
            weakSelf.audioAlarmData = [CMD_AudioAlarm new];
            weakSelf.tempReq = [CMD_AudioAlarm new];
        }
        [weakSelf dealWithGetOperationResultWithResult:result];
    }];
    
}

- (void)dealWithGetOperationResultWithResult:(int)result{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        if (result!=0) {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Get_data_failed")];
        }else{
            [SVProgressHUD dismiss];
        }
    });
}

- (void)sendAudioSensitivitySettingRequestWithValue:(float)value{
    
    _audioAlarmData.un_sensitivity = value;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)dealWithOperationResultWithResult:(int)result{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        if (result!=0) {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
        }else{
            [SVProgressHUD dismiss];
        }
    });
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
