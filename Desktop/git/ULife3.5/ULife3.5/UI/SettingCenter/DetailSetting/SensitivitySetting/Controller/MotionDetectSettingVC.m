//
//  MotionDetectSettingVC.m
//  ULife3.5
//
//  Created by zhuochuncai on 12/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "MotionDetectSettingVC.h"
#import "MoniterAreaTableViewCell.h"
#import "SensitivitySettingTableViewCell.h"
#import "NightVersionTableViewCell.h"
#import "settingCell.h"
#import "MoniterAreaFooterView.h"
#import "NetSDK.h"
#import "Header.h"
#import "MediaManager.h"

@interface MotionDetectSettingVC ()<UITableViewDataSource,UITableViewDelegate>
@property(nonatomic,strong)CMD_MotionDetect *motionDetectData;
@property(nonatomic,strong)CMD_MotionDetect *tempReq;
@property(nonatomic,strong)CMD_AudioAlarm   *audioAlarmData;
@property(nonatomic,strong)MoniterAreaTableViewCell *moniterAreaCell;
@property(nonatomic,strong)NetSDK *netSDK;
@property(nonatomic,assign)BOOL isChanged;
@end

@implementation MotionDetectSettingVC

- (void)viewDidLoad {
    _isChanged = NO;
    [super viewDidLoad];
    [self configUI];
    [self configureTableView];
    [self getMotionDetectSetting];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if ([SVProgressHUD isVisible]) {
        [SVProgressHUD dismiss];
    }
}

- (void)configureTableView{
    
    [self.tableView registerNib:[UINib nibWithNibName:@"MoniterAreaTableViewCell" bundle:nil] forCellReuseIdentifier:@"MoniterAreaTableViewCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"SensitivitySettingTableViewCell" bundle:nil] forCellReuseIdentifier:@"SensitivitySettingTableViewCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MoniterAreaFooterView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"MoniterAreaFooterView"];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"settingCell" bundle:nil] forCellReuseIdentifier:@"cell"];
    
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)configUI{
    self.title = DPLocalizedString(@"Setting_MotionDetection");
    self.view.backgroundColor = BACKCOLOR(238,238,238,1);
    [self configNavigationItem];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)getSensitivitySetting{
    
}


- (void)getMotionDetectSetting{
    
    _netSDK = [NetSDK sharedInstance];
    [SVProgressHUD showWithStatus:@"Loading..."];

    __weak typeof(self) weakSelf = self;
    CMD_GetMotionDetectReq *req = [CMD_GetMotionDetectReq new];
    [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[req requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        
        if (result == 0) {
            weakSelf.motionDetectData = [CMD_MotionDetect yy_modelWithJSON:dict];
            weakSelf.tempReq          = [CMD_MotionDetect yy_modelWithJSON:dict];
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

- (void)dealWithOperationResultWithResult:(int)result{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        if (result!=0) {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
        }else{
            [SVProgressHUD dismiss];
            [self.navigationController popViewControllerAnimated:YES];
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
            return 50;
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
        case 1:
            return 0;
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
    
    switch (section) {
        case 0:
            return 0;
        case 1:
            return 20;
        case 2:
            return 123;
        case 3:
            return 0;
    }
    return 0;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSString *title = nil;
    switch (section) {
        case 0:
            title = @"";
            break;
        case 1:
            title = @"Setting_MotionSensitivity";
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

- (void)switchValueChanged:(id)sender{
    _isChanged = YES;
    UISwitch *mySwitch = (UISwitch*)sender;
    BOOL isON = mySwitch.on;
    
    _motionDetectData.c_switch = (int)isON;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    __weak typeof(self) weakSelf = self;
    
    if (indexPath.section == 0) {
        settingCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
        [cell.settingSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
        cell.settingSwitch.on = (_motionDetectData.c_switch == 1);
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.settingArrow.hidden = cell.detailLabel.hidden = YES;
        cell.iconImageView.image = [UIImage imageNamed:@"Setting_MotionDetection"];
        cell.nameLabel.text = DPLocalizedString(@"Setting_MotionDetection");
        return cell;
    }
    
    else if ( indexPath.section == 1 ) {
        SensitivitySettingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SensitivitySettingTableViewCell" forIndexPath:indexPath];
        
        cell.lowLabel.text = DPLocalizedString(@"Setting_Sensitivity_Low");
        cell.defaultLabel.text = DPLocalizedString(@"Setting_Sensitivity_Default");
        cell.highLabel.text = DPLocalizedString(@"Setting_Sensitivity_High");

        cell.tag = indexPath.section;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if (indexPath.section == 1) {
            cell.slider.value =  (_motionDetectData? (3 - _motionDetectData.c_sensitivity/30)*0.5 : 0.5 );
        }
        
        [cell sliderValueChangeCallback:^(int sectionIndex, int selectPosition) {
            weakSelf.isChanged = YES;
            [weakSelf sendSensitivitySettingRequestWithType:sectionIndex positionValue:selectPosition];
        }];
        return cell;
    }else{
        if (!_moniterAreaCell) {
            _moniterAreaCell = [tableView dequeueReusableCellWithIdentifier:@"MoniterAreaTableViewCell" forIndexPath:indexPath];
        }

        _moniterAreaCell.selectionStyle = UITableViewCellSelectionStyleNone;
        NSLog(@"selectedArea______________________________________________:%x",_motionDetectData.un_enable);
        _moniterAreaCell.selectedArea = _motionDetectData.un_enable;
        
        _moniterAreaCell.redBlueLineView.hidden  = YES; //不使用自定义画线宽,使用CollectionViewCell自带的边框
//        _moniterAreaCell.redBlueLineView.selectedArea = _moniterAreaCell.selectedArea;
//        [_moniterAreaCell.redBlueLineView setNeedsDisplay];
        
        UIImage *previewImg = [[MediaManager shareManager] coverWithDevId: [_model.DeviceId substringFromIndex:8] fileName:nil deviceType: _model.DeviceType position:PositionMain];
        
        if (!previewImg) {
            _moniterAreaCell.bgImageView.image = [UIImage imageNamed:@"defaultCovert.jpg"];
        }else{
            _moniterAreaCell.bgImageView.image = previewImg;
        }
        
        [_moniterAreaCell selectMoniterAreaCallback:^(int selectPosition) {
            weakSelf.isChanged = YES;
            [weakSelf sendMoniterAreaSettingRequestWithPostion: selectPosition];
        }];
        [_moniterAreaCell.collectionView reloadData];
        return _moniterAreaCell;
    }
    return nil;
}

//-  (NSString *)cameraScreenShotPathWithUID:(NSString*)uid{
//    return [mDocumentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"MyDeviceIcons/%@.jpg",uid]];
//}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (section ==2) {
        MoniterAreaFooterView *footerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"MoniterAreaFooterView"];
        
        footerView.selectAreaLabel.text = DPLocalizedString(@"Setting_MoniterArea_SelectArea");
        footerView.selectAreaReminderLabel.text = DPLocalizedString(@"Setting_MoniterArea_SelectAreaReminder");

        [footerView.selectAllBtn addTarget:self action:@selector(selectAllBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [footerView.selectAllBtn setTitle:DPLocalizedString(_motionDetectData.un_enable!=0xffff?@"select_all":@"UnSelectAll") forState:0];
        return footerView;
    }
    return nil;
}

- (void)selectAllBtnClicked:(id)sender{
    _isChanged = YES;
    if (_motionDetectData.un_enable != 0xffff) {
        [self sendMoniterAreaSettingRequestWithValue:0xffff];
    }else{
        [self sendMoniterAreaSettingRequestWithValue:0];
    }
    NSLog(@"____________selectAllBtnClicked______________:");
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
    CMD_SetMotionDetectReq *req = [CMD_SetMotionDetectReq new];
    _tempReq.CMDType = _motionDetectData.CMDType = req.CMDType;
    _motionDetectData.un_mode = 1;
    _motionDetectData.un_submode = 3;
    
    __weak typeof(self) weakSelf = self;
    [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[_motionDetectData requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        if (result != 0) {
            weakSelf.motionDetectData = [CMD_SetMotionDetectReq yy_modelWithDictionary:[weakSelf.tempReq yy_modelToJSONObject]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
                 [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
                 [weakSelf.navigationController popViewControllerAnimated:YES];
            });
            
        }else{
            weakSelf.isChanged = NO,
            weakSelf.tempReq = [CMD_SetMotionDetectReq yy_modelWithDictionary:[weakSelf.motionDetectData yy_modelToJSONObject]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
                [weakSelf.navigationController popViewControllerAnimated:YES];
                [SVProgressHUD dismiss];
            });
        }
    }];
    
}

- (void)saveBtnClicked:(id)sender{
    [SVProgressHUD showWithStatus:@"Loading..."];
    CMD_SetMotionDetectReq *req = [CMD_SetMotionDetectReq new];
    _tempReq.CMDType = _motionDetectData.CMDType = req.CMDType;
    _motionDetectData.un_mode = 1;
    _motionDetectData.un_submode = 3;
    
    __weak typeof(self) weakSelf = self;
    [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[_motionDetectData requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        if (result != 0) {
            weakSelf.motionDetectData = [CMD_SetMotionDetectReq yy_modelWithDictionary:[weakSelf.tempReq yy_modelToJSONObject]];
        }else{
           weakSelf.isChanged = NO,
            weakSelf.tempReq = [CMD_SetMotionDetectReq yy_modelWithDictionary:[weakSelf.motionDetectData yy_modelToJSONObject]];
        }
        [weakSelf dealWithOperationResultWithResult:result];
    }];
    
}


#pragma mark <MoniterAreaSetting>
- (void)sendMoniterAreaSettingRequestWithValue:(int)selectValue{
    
    _motionDetectData.un_enable = selectValue;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}


- (void)sendMoniterAreaSettingRequestWithPostion:(int )selectPosition{
    
    BOOL hasSelectedPosition = (_motionDetectData.un_enable >> selectPosition) & 1;
    int  selectValue = hasSelectedPosition ? (_motionDetectData.un_enable & (~(1 << selectPosition))) : (_motionDetectData.un_enable | (1 << selectPosition)) ;
    [self sendMoniterAreaSettingRequestWithValue:selectValue];
}



#pragma mark <SensitivitySetting>
- (void)sendSensitivitySettingRequestWithType:(int)type positionValue:(float)value{
    
    [self sendMotionDetectSensitivitySettingRequestWithValue: (90 - value*30 )];
}


- (void)sendMotionDetectSensitivitySettingRequestWithValue:(float)value{
    //0,30,60,90
    _motionDetectData.c_sensitivity = value;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
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
