//
//  TempAlarmDetailSettingVC.m
//  ULife3.5
//
//  Created by zhuochuncai on 26/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "TempAlarmDetailSettingVC.h"
#import "DeviceTemperaturehumidityTableViewCell.h"
#import "DevicePickerTableViewCell.h"
#import "NightVersionTableViewCell.h"
#import "NetSDK.h"

@interface TempAlarmDetailSettingVC ()<UITableViewDelegate,UITableViewDataSource>

//@property(nonatomic,strong) NightVersionTableViewCell *switchCell;
//@property(nonatomic,strong) DeviceTemperaturehumidityTableViewCell *mytemperatureCell;
@property(nonatomic,strong) DevicePickerTableViewCell *tempPickerTableViewCell;

@property(nonatomic,assign)BOOL isEditing;
@property(nonatomic,assign)BOOL selectedLowerLimit;
@property(nonatomic,strong)UIButton *rightBtn;
@property(nonatomic,strong)NetSDK *network;
@property(nonatomic,strong)FinishSavingCallback finishSavingCallback;
@property(nonatomic,strong)CMD_TempAlarm    *data;
@property(nonatomic,assign)BOOL isChanged;
@end

@implementation TempAlarmDetailSettingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChanged = NO;
    // Do any additional setup after loading the view from its nib.
    [self configTableView];
    [self configUI];
}

- (void)configUI{
    self.title = DPLocalizedString(@"Temperature_alarm");
    self.view.backgroundColor = BACKCOLOR(238,238,238,1);
    [self configModel];
    [self addSaveButton];
}

- (void)configModel{
    _network = [NetSDK sharedInstance];
    _data = [CMD_TempAlarm yy_modelWithDictionary:[_tempAlarmData yy_modelToJSONObject]];
}

- (void)configTableView{
    self.automaticallyAdjustsScrollViewInsets = NO;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.scrollEnabled = NO;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"NightVersionTableViewCell" bundle:nil] forCellReuseIdentifier:@"NightVersionTableViewCell"];
}

#pragma mark - 编辑模式

-(void)addSaveButton
{
    
    
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
    
    _rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_rightBtn setTitle:DPLocalizedString(@"Title_Save") forState:UIControlStateNormal];
    _rightBtn.frame = CGRectMake(0.0, 0.0, 40, 40);
    _rightBtn.titleLabel.font    = [UIFont systemFontOfSize: 13];
    [_rightBtn addTarget:self action:@selector(saveBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_rightBtn];
    temporaryBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.rightBarButtonItem = temporaryBarButtonItem;
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
    self.navigationController.navigationBar.userInteractionEnabled=NO;
    [SVProgressHUD showWithStatus:@"Loading...."];
    __weak typeof(self) weakSelf = self;
    CMD_SetTempAlarmReq *req = [CMD_SetTempAlarmReq new];
    _data.CMDType = req.CMDType;
    
    [_network net_sendBypassRequestWithUID:_deviceID requestData:[_data requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.navigationController.navigationBar.userInteractionEnabled=YES;
        });
        if (result == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tempAlarmData yy_modelSetWithDictionary:[weakSelf.data yy_modelToJSONObject]];
                if (weakSelf.finishSavingCallback) {
                    weakSelf.finishSavingCallback(0);
                }
                [SVProgressHUD dismiss];
            });
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.data yy_modelSetWithDictionary:[weakSelf.tempAlarmData yy_modelToJSONObject]];
                [weakSelf.tableView reloadData];
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
                 [weakSelf.navigationController popViewControllerAnimated:YES];
            });
        }
        
    }];
}



- (void)saveBtnClicked{
    [self sendTempAlarmSetting];
}

#pragma mark - 发送设置指令
-(void)sendTempAlarmSetting
{
    self.navigationController.navigationBar.userInteractionEnabled=NO;
    
    [SVProgressHUD showWithStatus:@"Loading...."];
    
    __weak typeof(self) weakSelf = self;
    
    CMD_SetTempAlarmReq *req = [CMD_SetTempAlarmReq new];
    _data.CMDType = req.CMDType;
    
    [_network net_sendBypassRequestWithUID:_deviceID requestData:[_data requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.navigationController.navigationBar.userInteractionEnabled=YES;
        });
        if (result == 0) {
            weakSelf.isChanged = NO;
        }
        [weakSelf dealWithSetOperationResultWithResult:result];
    }];
}

- (void)didFinishSavingWithCallback:(FinishSavingCallback)callbackBlock{
    _finishSavingCallback = callbackBlock;
}

- (void)dealWithSetOperationResultWithResult:(int)result{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (result!=0) {
            
            [_data yy_modelSetWithDictionary:[_tempAlarmData yy_modelToJSONObject]];
            [self.tableView reloadData];
            
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
        }else{
            
            [_tempAlarmData yy_modelSetWithDictionary:[_data yy_modelToJSONObject]];
            
            if (_finishSavingCallback) {
                _finishSavingCallback(0);
            }
            [SVProgressHUD dismiss];
        }
    });
}

#pragma mark ==<TableViewDelegate>

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return section == 3 ? 1 : 2;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 4;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 3) {
        CGFloat scrollViewH = SCREEN_HEIGHT - (64+44*6+30+15*2+30);
        return scrollViewH;
    }else{
        return 44;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = 0;
    switch (section) {
        case 0:
            height = 30;
            break;
        case 1:
        case 2:
            height = 15;
            break;
        case 3:
            height = 30;
            break;
        default:
            height = 1;
            break;
    }
    return height;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *CellIdentifier2 = @"DeviceTemperaturehumidityTableViewCell";

    switch (indexPath.section) {
        case 0:
        {
            DeviceTemperaturehumidityTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
            if (!cell) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"CameraInfoView" owner:self options:nil] objectAtIndex:1];
            }
            cell.temperaturelabel.text = indexPath.row == 0 ? @"°C" : @"°F";

            [cell.chooseBtn setTag:indexPath.row+indexPath.section];
            [cell.chooseBtn addTarget:self action:@selector(chooseBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
            
            if (_data.temperature_type == 0) {//celcius
                [cell.chooseBtn setBackgroundImage:[UIImage imageNamed: indexPath.row==0?@"Setting_Temp_Selected": @"Setting_Temp_Deselected"] forState:0];
            }else{
                [cell.chooseBtn setBackgroundImage:[UIImage imageNamed:indexPath.row==1?@"Setting_Temp_Selected": @"Setting_Temp_Deselected"] forState:0];
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
            break;
        }
        case 1:
        {
            if (indexPath.row == 0) {
                NightVersionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NightVersionTableViewCell" forIndexPath:indexPath];
                cell.cellSwitch.on = _data.alarm_enale%2!=0;
                [cell.cellSwitch setTag:indexPath.section];
                [cell.cellSwitch addTarget:self action:@selector(cellSwitchClicked:) forControlEvents:UIControlEventTouchUpInside];
                
                cell.titleLabel.text = DPLocalizedString(@"ceiling_temperature");
                cell.selectionStyle = UITableViewCellSelectionStyleNone;

                return cell;
            }
            else{
                DeviceTemperaturehumidityTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
                if (!cell) {
                    cell = [[[NSBundle mainBundle] loadNibNamed:@"CameraInfoView" owner:self options:nil] objectAtIndex:1];
                }
                
                
                NSString *valueStr = nil;
                if (_data.temperature_type == 0 ) {
                    valueStr = [NSString stringWithFormat:@"%d°C", (int)_data.max_alarm_value];
                }else{
                    valueStr = [NSString stringWithFormat:@"%.1f°F", _data.max_alarm_value];
                }
                cell.temperaturelabel.text = valueStr;
                
                
                [cell.chooseBtn setTag:indexPath.row+indexPath.section];
                [cell.chooseBtn addTarget:self action:@selector(chooseBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
                [cell.chooseBtn setBackgroundImage:[UIImage imageNamed: !_selectedLowerLimit?@"Setting_Temp_Selected": @"Setting_Temp_Deselected"] forState:0];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;

                return cell;
            }
            break;
        }
        case 2:
        {
            if (indexPath.row == 0) {
                NightVersionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NightVersionTableViewCell" forIndexPath:indexPath];
                cell.cellSwitch.on = _data.alarm_enale>1;
                [cell.cellSwitch setTag:indexPath.section];
                [cell.cellSwitch addTarget:self action:@selector(cellSwitchClicked:) forControlEvents:UIControlEventTouchUpInside];
                cell.titleLabel.text = DPLocalizedString(@"floor_temperature");
                cell.selectionStyle = UITableViewCellSelectionStyleNone;

            }
            else{
                DeviceTemperaturehumidityTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
                if (!cell) {
                    cell = [[[NSBundle mainBundle] loadNibNamed:@"CameraInfoView" owner:self options:nil] objectAtIndex:1];
                }
                
                NSString *valueStr = nil;
                if (_data.temperature_type == 0 ) {
                    valueStr = [NSString stringWithFormat:@"%d°C", (int)_data.min_alarm_value];
                }else{
                    valueStr = [NSString stringWithFormat:@"%.1f°F", _data.min_alarm_value];
                }
                cell.temperaturelabel.text = valueStr;
                
                [cell.chooseBtn setTag:indexPath.row+indexPath.section];
                [cell.chooseBtn addTarget:self action:@selector(chooseBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
                
                [cell.chooseBtn setBackgroundImage:[UIImage imageNamed: _selectedLowerLimit?@"Setting_Temp_Selected": @"Setting_Temp_Deselected"] forState:0];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;

                return cell;
            }
            break;
        }
        case 3:
        {
            if (_tempPickerTableViewCell==nil) {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CameraInfoView" owner:self options:nil];
                self.tempPickerTableViewCell = nib[2];
            }
            _tempPickerTableViewCell.ismax= !_selectedLowerLimit;
            _tempPickerTableViewCell.tittlelabel.text = DPLocalizedString(_selectedLowerLimit?@"floor_temperature_settings":@"ceiling_temperature_setting");
            if (!_selectedLowerLimit) {//上限设置
                
                int selectedRow = _data.temperature_type==0?(_data.max_alarm_value-_data.min_alarm_value):((int)((_data.max_alarm_value-32)/1.8) - (int)((_data.min_alarm_value-32)/1.8));
                
                int count = _data.temperature_type==0?(_data.min_alarm_value):(_data.min_alarm_value-32)/1.8;
                
                _tempPickerTableViewCell.row = selectedRow;//
                [_tempPickerTableViewCell DataRefreshPickView: _data.temperature_type==1 withcount:count];
                
                [_tempPickerTableViewCell.myPickView reloadAllComponents];
            }
            else{
                
                int selectedRow = _data.temperature_type==0?(_data.min_alarm_value+10): [self celciusFromFahrenheit:_data.min_alarm_value]+10;
                
                int count = _data.temperature_type==0?(_data.max_alarm_value): [self celciusFromFahrenheit:_data.max_alarm_value];
                
                _tempPickerTableViewCell.row = selectedRow ;
                [_tempPickerTableViewCell DataRefreshPickView: _data.temperature_type==1 withcount: count];
                [_tempPickerTableViewCell.myPickView reloadAllComponents];
            }
            
            __weak typeof(self) weakSelf = self;

            self.tempPickerTableViewCell.pickintblock=^(int obj){
                
                weakSelf.isChanged = YES;
                
                NSIndexPath *index = [NSIndexPath indexPathForRow:1 inSection:weakSelf.selectedLowerLimit?2:1];
                
                if (weakSelf.selectedLowerLimit) {
                    weakSelf.data.min_alarm_value = weakSelf.data.temperature_type==0?obj: ((int)((obj*1.8+32)*10)/10.0);
                }else{
                    weakSelf.data.max_alarm_value = weakSelf.data.temperature_type==0?obj:((int)((obj*1.8+32)*10)/10.0);
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.tableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationNone];
                });
            };
            _tempPickerTableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;

            return _tempPickerTableViewCell;
            break;
        }
        default:
            break;
    }
    UITableViewCell *cell = [UITableViewCell new];
    return cell;
}

-(int)celciusFromFahrenheit:(double)value{
    int celcius = ((value*10)-320) / 18.0;
    NSLog(@"celciusFromFahrenheit___________________________________:%d",celcius);
    return celcius;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section==3 ||(indexPath.row==0 &&(indexPath.section==1||indexPath.section==2))) {
        return;
    }
    
    _isChanged = YES;
    
    [self configChooseBtnsWithTag: indexPath.row + indexPath.section];

    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}


#pragma mark <点击事件>
- (void)chooseBtnClicked:(id)sender{
    _isChanged = YES;
    UIButton *btn = (UIButton*)sender;
    int tag = btn.tag;
    [self configChooseBtnsWithTag:tag];
}


- (void)configChooseBtnsWithTag:(int)tag{
    if (tag<2) { //温度类型切换
        
        if (tag == _data.temperature_type) {
            return;
        }
        
        //更新默认选择的温度
        if (!_selectedLowerLimit) {//tag=1,之前是摄氏
            int selectedRow = tag==1?(_data.max_alarm_value-_data.min_alarm_value):((int)((_data.max_alarm_value-32)/1.8) - (int)((_data.min_alarm_value-32)/1.8));
            _tempPickerTableViewCell.row = selectedRow;
        }else{
            int selectedRow = tag==1?(_data.min_alarm_value+10):(int)([self celciusFromFahrenheit:_data.min_alarm_value]+10) ;
            _tempPickerTableViewCell.row = selectedRow ;
        }
        
        if (tag == 0 && _data.temperature_type ==1) {//0:摄氏
            _data.max_alarm_value = (int)((_data.max_alarm_value-32)/1.8);
            _data.min_alarm_value = (int)((_data.min_alarm_value-32)/1.8);
        }else{
            _data.max_alarm_value = (int)((_data.max_alarm_value*1.8+32)*10)/10.0;
            _data.min_alarm_value = (int)((_data.min_alarm_value*1.8+32)*10)/10.0;
        }
        
        _data.temperature_type = tag;
        [self.tableView reloadData];
        
    }else{ //上下限切换
        if ((tag==2 && !_selectedLowerLimit) || (tag==3 && _selectedLowerLimit) ) {
            return;
        }
        _selectedLowerLimit = !_selectedLowerLimit;
        [self.tableView reloadData];
    }

}

//
- (void)cellSwitchClicked:(id)sender{
    _isChanged = YES;
    UISwitch *switchCtrl = (UISwitch*)sender;
    int tag = switchCtrl.tag;
    int onState = switchCtrl.isOn;
    
    if (tag == 1) {//upper
        _data.alarm_enale = [self getAlarm_enaleAndisSelectMax:onState AndisSelectMin:_data.alarm_enale>1];
    }else{
        _data.alarm_enale = [self getAlarm_enaleAndisSelectMax:_data.alarm_enale%2==1 AndisSelectMin:onState];
    }
}

-(int)getAlarm_enaleAndisSelectMax:(BOOL)isopenMax AndisSelectMin:(BOOL)isopenMin
{
    if (isopenMax==NO && isopenMin==NO) {
        return 0;
    }
    if (isopenMax==YES && isopenMin==NO) {
        return 1;
    }
    if (isopenMax==NO && isopenMin==YES) {
        return 2;
    }
    if (isopenMax==YES && isopenMin==YES) {
        return 3;
    }
    else{
        return 10086;
    }
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
