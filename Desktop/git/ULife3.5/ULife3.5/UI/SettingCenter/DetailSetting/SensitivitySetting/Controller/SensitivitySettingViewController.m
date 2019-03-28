//
//  SensitivitySettingViewController.m
//  ULife3.5
//
//  Created by zhuochuncai on 4/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "SensitivitySettingViewController.h"
#import "MoniterAreaTableViewCell.h"
#import "SensitivitySettingTableViewCell.h"
#import "MoniterAreaFooterView.h"
#import "NetSDK.h"

@interface SensitivitySettingViewController ()<UITableViewDataSource,UITableViewDelegate>
@property(nonatomic,strong)CMD_MotionDetect *motionDetectData;
@property(nonatomic,strong)CMD_AudioAlarm   *audioAlarmData;
@property(nonatomic,strong)NetSDK *netSDK;
@end

@implementation SensitivitySettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configUI];
    [self configureTableView];
    [self getSensitivitySetting];
}

- (void)configureTableView{
    
    [self.tableView registerNib:[UINib nibWithNibName:@"MoniterAreaTableViewCell" bundle:nil] forCellReuseIdentifier:@"MoniterAreaTableViewCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"SensitivitySettingTableViewCell" bundle:nil] forCellReuseIdentifier:@"SensitivitySettingTableViewCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MoniterAreaFooterView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"MoniterAreaFooterView"];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)configUI{
    self.title = DPLocalizedString(@"Setting_DetectSensitiivty");
    self.view.backgroundColor = BACKCOLOR(238,238,238,1);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)getSensitivitySetting{
    
    _netSDK = [NetSDK sharedInstance];
    [SVProgressHUD showWithStatus:@"Loading..."];
    if (!_getAllParamResp) {
        __weak typeof(self) weakSelf = self;
        CMD_GetAudioAlarmReq *req = [CMD_GetAudioAlarmReq new];
        [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[req requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
            
            if (result == 0) {
                weakSelf.audioAlarmData = [CMD_AudioAlarm yy_modelWithJSON:dict];
                [weakSelf getMotionDetectSetting];
            }
        }];
    }else{
        [SVProgressHUD showWithStatus:@"Loading..."];
        [self getMotionDetectSetting];
    }
}


- (void)getMotionDetectSetting{
    __weak typeof(self) weakSelf = self;
    CMD_GetMotionDetectReq *req = [CMD_GetMotionDetectReq new];
    [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[req requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        
        if (result == 0) {
            weakSelf.motionDetectData = [CMD_MotionDetect yy_modelWithJSON:dict];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
            });
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


#pragma mark ==<TableViewDelegate>

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return 1;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 3;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.section) {
        case 0:
        case 1:
            return 71;
            break;
        case 2:
            return SCREEN_WIDTH*9/16;
        case 3:
            return 123;
        default:
            break;
    }
    return 50;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return 40;
        case 1:
        case 2:
            return 35;
        case 3:
            return 0;
        default:
            break;
    }
    return 0;
}



- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
   
    return section ==2 ? 123: 0;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSString *title = nil;
    switch (section) {
        case 0:
            title = @"Setting_VoiceSensitiivty";
            break;
        case 1:
            title = @"Setting_MotionSensitiivty";
            break;
        case 2:
            title = @"Setting_MoniterArea";
            break;
        case 3:
            title = @"";
            break;
        default:
            break;
    }
    return DPLocalizedString(title);
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    __weak typeof(self) weakSelf = self;
    if (indexPath.section ==0 || indexPath.section == 1) {
        SensitivitySettingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SensitivitySettingTableViewCell" forIndexPath:indexPath];
        cell.tag = indexPath.section;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if (indexPath.section == 1) {
            cell.slider.value = _getAllParamResp ? (3- _getAllParamResp.motion_detect_sensitivity/30)*0.5 : (_motionDetectData? (3 - _motionDetectData.c_sensitivity/30)*0.5 : 0.5 );
        }
        
        if (indexPath.section == 0 ) {
            cell.slider.value = _getAllParamResp ? (_getAllParamResp.audio_alarm_sensitivity-1)*0.5 : (_audioAlarmData?(_audioAlarmData.un_sensitivity - 1 ) *0.5:0.5);
        }
        [cell sliderValueChangeCallback:^(int sectionIndex, int selectPosition) {
            [weakSelf sendSensitivitySettingRequestWithType:sectionIndex positionValue:selectPosition];
        }];
        return cell;
    }else{
        MoniterAreaTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MoniterAreaTableViewCell" forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        NSLog(@"selectedArea______________________________________________:%x",_motionDetectData.un_enable);
        cell.selectedArea = _motionDetectData.un_enable;
        [cell selectMoniterAreaCallback:^(int selectPosition) {
            [weakSelf sendMoniterAreaSettingRequestWithPostion: selectPosition];
        }];
        [cell.collectionView reloadData];
        return cell;
    }
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (section ==2) {
        MoniterAreaFooterView *footerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"MoniterAreaFooterView"];
        [footerView.selectAllBtn addTarget:self action:@selector(selectAllBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        return footerView;
    }
    return nil;
}

- (void)selectAllBtnClicked:(id)sender{
    
    if (_motionDetectData.un_enable != 0xffff) {
        [self sendMoniterAreaSettingRequestWithValue:0xffff];
    }else{
        [self sendMoniterAreaSettingRequestWithValue:0];
    }
    NSLog(@"____________selectAllBtnClicked______________:");
}


#pragma mark <MoniterAreaSetting>
- (void)sendMoniterAreaSettingRequestWithValue:(int)selectValue{
    CMD_SetMotionDetectReq *req = [CMD_SetMotionDetectReq new];
    if (_motionDetectData) {
        req.c_sensitivity = _motionDetectData.c_sensitivity;
        req.c_switch = _motionDetectData.c_switch;
        req.un_enable = selectValue;
    }
    __weak typeof(self) weakSelf = self;
    [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[req requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            weakSelf.motionDetectData.un_enable = req.un_enable;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationNone];
            });
        }
        [weakSelf dealWithOperationResultWithResult:result];
    }];
}


- (void)sendMoniterAreaSettingRequestWithPostion:(int )selectPosition{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showWithStatus:@"Loading..."];
    });
    BOOL hasSelectedPosition = (_motionDetectData.un_enable >> selectPosition) & 1;
    int  selectValue = hasSelectedPosition ? (_motionDetectData.un_enable & (~(1 << selectPosition))) : (_motionDetectData.un_enable | (1 << selectPosition)) ;
    [self sendMoniterAreaSettingRequestWithValue:selectValue];
}



#pragma mark <SensitivitySetting>
- (void)sendSensitivitySettingRequestWithType:(int)type positionValue:(float)value{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showWithStatus:@"Loading..."];
    });
    
    if (type == 0) {
        [self sendAudioSensitivitySettingRequestWithValue:value+1];
    }else{
        [self sendMotionDetectSensitivitySettingRequestWithValue: (90 - value*30 )];
    }
}


- (void)sendAudioSensitivitySettingRequestWithValue:(float)value{
    
    CMD_SetAudioAlarmReq *req = [CMD_SetAudioAlarmReq new];
    req.un_sensitivity = value;
    __weak typeof(self) weakSelf = self;

    [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[req requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        
        if (result == 0) {
            if (weakSelf.getAllParamResp) {
                weakSelf.getAllParamResp.audio_alarm_sensitivity = value;
            }else{
                weakSelf.audioAlarmData = req;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
            });
        }
        [weakSelf dealWithOperationResultWithResult:result];
    }];
    
}


- (void)sendMotionDetectSensitivitySettingRequestWithValue:(float)value{
    //0,30,60,90
    CMD_SetMotionDetectReq *req = [CMD_SetMotionDetectReq new];
    req.c_sensitivity = value;
    __weak typeof(self) weakSelf = self;
    [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[req requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            if (weakSelf.getAllParamResp) {
                weakSelf.getAllParamResp.motion_detect_sensitivity = value;
            }else{
                weakSelf.motionDetectData.c_sensitivity = req.c_sensitivity;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
            });
        }
        [weakSelf dealWithOperationResultWithResult:result];
    }];
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
