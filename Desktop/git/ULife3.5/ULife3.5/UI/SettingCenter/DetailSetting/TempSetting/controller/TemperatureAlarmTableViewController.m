//
//  TemperatureAlarmTableViewController.m
//  QQI
//
//  Created by goscam_sz on 16/7/29.
//  Copyright © 2016年 yuanx. All rights reserved.
//

#import "TemperatureAlarmTableViewController.h"
#import "DeviceTemperatureTableViewCell.h"
#import "DeviceTemperaturehumidityTableViewCell.h"
#import "DevicePickerTableViewCell.h"
#import "NetSDK.h"
#import "BaseCommand.h"
#import "TempAlarmDetailSettingVC.h"

@interface TemperatureAlarmTableViewController ()<UITableViewDataSource,UITableViewDelegate>

@property(nonatomic,strong) DeviceTemperatureTableViewCell *mycell;
@property(nonatomic,strong) DeviceTemperaturehumidityTableViewCell *mytemperatureCell;
@property(nonatomic,strong) DevicePickerTableViewCell *mytevicePickerTableViewCell;
@property(nonatomic,assign) double maxCount;
@property(nonatomic,assign) double minCount;
@property(nonatomic,assign) BOOL isHuaShi;
@property(nonatomic,assign) BOOL isSelectMax;
@property(nonatomic,assign) BOOL isSelectMin;
@property(nonatomic,strong) UIButton *rightbtn;
@property(nonatomic,strong) EnlargeClickButton *backBtn;
@property(nonatomic,assign) BOOL isEditor;
@property(nonatomic,assign) BOOL isChooseMax;

@property(nonatomic,strong)NetSDK *network;
@property(nonatomic,strong)CMD_TempAlarm *tempAlarmData;
@end

@implementation TemperatureAlarmTableViewController
{
    UIRefreshControl* _refreshControl;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = DPLocalizedString(@"Temperature_alarm");//  @"温度报警";
    self.tableView.backgroundColor = mCustomBgColor;
    self.tableView.indicatorStyle = UIScrollViewIndicatorStyleDefault;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.scrollEnabled = NO;
    _network = [NetSDK sharedInstance];
    [self getTemptureData];
    [self addEditButton];
    [self addBackBtn];
}


#pragma mark - 编辑模式

-(void)addEditButton
{
    _rightbtn = [UIButton buttonWithType:UIButtonTypeCustom];
    if (!_isEditor) {
        [_rightbtn setTitle:DPLocalizedString(@"editor") forState:UIControlStateNormal];
    }
    _rightbtn.frame = CGRectMake(0.0, 0.0, 40, 40);
    _rightbtn.titleLabel.font    = [UIFont systemFontOfSize: 13];
    [_rightbtn addTarget:self action:@selector(editBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_rightbtn];
    temporaryBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.rightBarButtonItem = temporaryBarButtonItem;
}



- (void)editBtnClicked
{
    TempAlarmDetailSettingVC *vc = [[TempAlarmDetailSettingVC alloc] init];
    if (!_tempAlarmData) {
        _tempAlarmData = [CMD_TempAlarm new];
    }
    vc.tempAlarmData    =   _tempAlarmData;
    vc.deviceID         =   _deviceID;
    
    __weak typeof(self) weakSelf = self;
    [vc didFinishSavingWithCallback:^(CMD_TempAlarm* alarmData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
            [weakSelf.tableView reloadData];
        });
    }];
    [self.navigationController pushViewController:vc animated:YES];
    return;
    
//    if (!_isEditor) {
//
//        [_rightbtn setTitle:DPLocalizedString(@"Setting_Done") forState:UIControlStateNormal];
//
//        [_backBtn setImage:nil forState:UIControlStateNormal];
//        _backBtn.frame = CGRectMake(0.0, 0, 40, 40);
//        [_backBtn setTitle:DPLocalizedString(@"Setting_Cancel") forState:UIControlStateNormal];
//        _backBtn.titleLabel.font    = [UIFont systemFontOfSize: 13];
//        _backBtn.titleLabel.textAlignment = NSTextAlignmentRight;
//
//        _isEditor = YES;
//
//        _isChooseMax=YES;
//        [self.tableView reloadData];
//    }
//    else{
//    
//        [self sendtemptureData];
//    }
}


-(void)addBackBtn
{
    _backBtn = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];

    _backBtn.frame = CGRectMake(0, 0, 70, 40);
    _backBtn.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 50);
    [_backBtn setImage:[UIImage imageNamed:@"addev_back"] forState:UIControlStateNormal];

    [_backBtn addTarget:self action:@selector(backToPreView) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_backBtn];
    temporaryBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.leftBarButtonItem = temporaryBarButtonItem;
    
}


-(void)backToPreView
{

    if (!_isEditor) {
        [self.navigationController popViewControllerAnimated:YES];
    }else{
        _isEditor = NO;
        
        [_rightbtn setTitle:DPLocalizedString(@"editor") forState:UIControlStateNormal];
        _backBtn.frame = CGRectMake(0, 5, 30, 30);
        [_backBtn setImage:[UIImage imageNamed:@"POEback_btn.png"] forState:UIControlStateNormal];

        [self.tableView reloadData];
    }
}

-(void)stopGetDeviceAll:(NSString*)cmd;
{
    if ([cmd isEqualToString:@"setCMD"]) {
        _isEditor = YES;
    }
}

#pragma mark - 获取温度数据
-(void)getTemptureData
{
    __weak  TemperatureAlarmTableViewController* weakSelf = self;
    [SVProgressHUD showWithStatus:@"Loading...."];

    CMD_GetTempAlarmReq *req = [CMD_GetTempAlarmReq new];
    [_network net_sendBypassRequestWithUID:_deviceID requestData:[req requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            weakSelf.tempAlarmData = [CMD_TempAlarm yy_modelWithJSON:dict];
            weakSelf.isHuaShi = weakSelf.tempAlarmData.temperature_type;
            
            if (weakSelf.isHuaShi) {
                weakSelf.maxCount=(int)[[NSString stringWithFormat:@"%f",weakSelf.tempAlarmData.max_alarm_value] floatValue];
                weakSelf.minCount=(int)[[NSString stringWithFormat:@"%f",weakSelf.tempAlarmData.min_alarm_value] floatValue];
                NSLog(@"最高华氏摄氏度 %.1f",weakSelf.maxCount);
            }
            else{
                weakSelf.maxCount=(int)weakSelf.tempAlarmData.max_alarm_value;
                weakSelf.minCount=(int)weakSelf.tempAlarmData.min_alarm_value;
            }
            
            if (weakSelf.tempAlarmData.alarm_enale==0) {
                self.isSelectMax=NO;
                self.isSelectMin=NO;
            }
            if (weakSelf.tempAlarmData.alarm_enale==1) {
                self.isSelectMax=YES;
                self.isSelectMin=NO;
            }
            if (weakSelf.tempAlarmData.alarm_enale==2) {
                self.isSelectMax=NO;
                self.isSelectMin=YES;
            }
            if (weakSelf.tempAlarmData.alarm_enale==3) {
                self.isSelectMax=YES;
                self.isSelectMin=YES;
            }
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
        }
    });
}


#pragma mark - 获取开关参数

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



#pragma mark - 发送设置指令
-(void)sendtemptureData
{
    self.navigationController.navigationBar.userInteractionEnabled=NO;

    [SVProgressHUD showWithStatus:@"Loading...."];

    __weak  TemperatureAlarmTableViewController* weakSelf = self;

    _tempAlarmData.alarm_enale = [self getAlarm_enaleAndisSelectMax:_isSelectMax AndisSelectMin:_isSelectMin];
    _tempAlarmData.min_alarm_value = _minCount;
    _tempAlarmData.max_alarm_value = _maxCount;
    
    CMD_SetTempAlarmReq *req = [CMD_SetTempAlarmReq new];
    _tempAlarmData.CMDType = req.CMDType;
    
    [_network net_sendBypassRequestWithUID:_deviceID requestData:[req requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.navigationController.navigationBar.userInteractionEnabled=YES;
        });
        if (result==0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.isEditor = NO;
                if (!weakSelf.isEditor) {
                    [weakSelf.rightbtn setTitle:DPLocalizedString(@"editor")
                                       forState:UIControlStateNormal];
                    weakSelf.backBtn.frame = CGRectMake(0, 5, 30, 30);
                    [weakSelf.backBtn setImage:[UIImage imageNamed:@"POEback_btn.png"] forState:UIControlStateNormal];
                }
            });
        }else{
            weakSelf.isEditor = YES;
        }
        [weakSelf dealWithGetOperationResultWithResult:result];
    }];
}









#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
//    if (_isEditor) {
//        return 2;
//    }
//    else{
//        return 2;
//    }
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return 2;
//    if (section == 0) {
//        return 2;
//    }
//    else{
//        if (_isEditor) {
//            return 1;
//        }
//        else{
//            return 2;
//        }
//    }
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    DeviceTemperatureTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceTemperatureTableViewCell"];
    if (!cell) {
        cell = [[NSBundle mainBundle] loadNibNamed:@"CameraInfoView" owner:self options:nil][0];
    }
    
    cell.chooseBtn.hidden=YES;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.temperatureText.text = DPLocalizedString(indexPath.row==0?@"ceiling_temperature":@"floor_temperature");
    
    NSString *tempTypeStr = _tempAlarmData.temperature_type == 0? @"°C" : @"°F";
    
    NSString *titleStr = [NSString stringWithFormat:@"%@%@",@(indexPath.row==0?_tempAlarmData.max_alarm_value:_tempAlarmData.min_alarm_value),tempTypeStr];
    
    [cell.temperatureBtn setTitle:titleStr forState:0];

    
    return cell;
    
    
//    NSInteger section = [indexPath section];
//    static NSString *MailCellIdentifier = @"DeviceInfoTableViewCell";
//    static NSString *MailCellIdentifier2 = @"DeviceTemperaturehumidityTableViewCell";
//    self.mycell= [tableView dequeueReusableCellWithIdentifier:MailCellIdentifier];
//    self.mytemperatureCell= [tableView dequeueReusableCellWithIdentifier:MailCellIdentifier2];
//    if (!_isEditor) {
//        
//        if(section == 0){
//            
//            [self settingCellandSection:section AndIndexPath:indexPath.row];
//            [self.mytemperatureCell DataRefresh:indexPath.row AndState:_isHuaShi AndMaxtempture:_maxCount AndMintempture:_minCount];
//            return self.mytemperatureCell;
//        }
//        
//        else {
//            
//            [self settingCellandSection:section AndIndexPath:indexPath.row ] ;
//            self.mycell._uidstr=self.deviceID;
//            [self.mycell DataRefresh:indexPath.row AndisHuaShi:_isHuaShi AndTemptureCount:(float)_maxCount withMinTempture:(float)_minCount AndChoose:_isSelectMax AndChoose:_isSelectMin AndIsEditor:_isEditor];
//            return self.mycell;
//        }
//    }
//    else{
//        if (section==0) {
//            [self settingCellandSection:section+1 AndIndexPath:indexPath.row ] ;
//            self.mycell._uidstr=self.deviceID;
//            [self.mycell DataRefresh:indexPath.row AndisHuaShi:_isHuaShi AndTemptureCount:(float)_maxCount withMinTempture:(float)_minCount AndChoose:_isSelectMax AndChoose:_isSelectMin AndIsEditor:_isEditor];
//            return self.mycell;
//        }
//        else{
//             [self settingCellandSection:section+1 AndIndexPath:indexPath.row ] ;
//            _mytevicePickerTableViewCell.ismax=_isChooseMax;
//            if (_isChooseMax) {
//                _mytevicePickerTableViewCell.row=_maxCount-_minCount;
//                [_mytevicePickerTableViewCell DataRefreshPickView:_isHuaShi withcount:_minCount];
//                [_mytevicePickerTableViewCell.myPickView reloadAllComponents];
//            }
//            else{
//                _mytevicePickerTableViewCell.row=_minCount;
//                [_mytevicePickerTableViewCell DataRefreshPickView:_isHuaShi withcount:_maxCount];
//                
//                [_mytevicePickerTableViewCell.myPickView reloadAllComponents];
//            }
//            return _mytevicePickerTableViewCell;
//
//        }
//    }
}



-(void)settingCellandSection:(NSUInteger)section AndIndexPath:(NSUInteger)row
{
    __weak  TemperatureAlarmTableViewController* weakSelf = self;
    if (section==0) {
        if (_mytemperatureCell==nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CameraInfoView" owner:self options:nil];
            self.mytemperatureCell  = nib[1];
        }
        _mytemperatureCell.myTemptureBlock=^(float maxcont,float mincount, BOOL state){
            weakSelf.isHuaShi=state;
            _maxCount=maxcont;
            _minCount=mincount;
            [weakSelf sendtemptureData];
            [weakSelf.tableView reloadData];
        };
    }
    if (section==1) {
        if (_mycell==nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CameraInfoView" owner:self options:nil];
            self.mycell  = nib[0];
            if (!_isEditor) {
                self.mycell.chooseBtn.hidden=YES;
                [self.mycell addSubview:self.mycell.SWControl];
            }
        }
        _mycell.isChooseMaxSwithch=^(BOOL state){
            if (row==0) {
                _isSelectMax=state;
                [weakSelf sendtemptureData];
            }
            if (row==1) {
                _isSelectMin=state;
                [weakSelf sendtemptureData];
            }
        };
        _mycell.MaxBlock=^(BOOL state){
            
            weakSelf.isChooseMax=state;
            [weakSelf.tableView reloadData];
        };
        
        if (row==0) {
            
            if (_isChooseMax) {
                [self.mycell.chooseBtn setBackgroundImage:[UIImage imageNamed:@"Setting_Temp_Selected"] forState:UIControlStateNormal];
            }
            else{
                [self.mycell.chooseBtn setBackgroundImage:[UIImage imageNamed:@"Setting_Temp_Deselected"] forState:UIControlStateNormal];
            }
        }
        else{
            if (!_isChooseMax) {
                [self.mycell.chooseBtn setBackgroundImage:[UIImage imageNamed:@"Setting_Temp_Selected"] forState:UIControlStateNormal];
            }
            else{
                [self.mycell.chooseBtn setBackgroundImage:[UIImage imageNamed:@"Setting_Temp_Deselected"] forState:UIControlStateNormal];
            }
        }
    }
    if (section==2) {
        
        if (_mytevicePickerTableViewCell==nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CameraInfoView" owner:self options:nil];
            self.mytevicePickerTableViewCell = nib[2];
            
        }
        if (_isChooseMax) {
            _mytevicePickerTableViewCell.tittlelabel.text= DPLocalizedString(@"upperLimitTemperatureSet");
            self.mytevicePickerTableViewCell.pickintblock=^(int obj){
                
                
                weakSelf.maxCount=obj;
                [weakSelf.tableView reloadData];
            };
        }
        else{
            _mytevicePickerTableViewCell.tittlelabel.text= DPLocalizedString(@"lowerLimitTemperatureSet");
            
            self.mytevicePickerTableViewCell.pickintblock=^(int obj){
                //                _istakepickview=YES;
                //                weakSelf.pickcount =obj;
                weakSelf.minCount=obj;
                [weakSelf.tableView reloadData];
            };
        }
        
    }
}








- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (!_isEditor) {
        if (section==0) {
            UIView * sectionView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 20)];
            sectionView.backgroundColor = mCustomBgColor;
            return sectionView;
        }
        else {
            UIView * sectionView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44)];
            sectionView.backgroundColor = mCustomBgColor;
            UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(21, 21,[UIScreen mainScreen].bounds.size.width-21 ,21 )];
            label.textAlignment=NSTextAlignmentLeft;
            label.text= @""; //DPLocalizedString(@"temperatureAlarmSet");
            label.font=[UIFont systemFontOfSize:12];
            [sectionView addSubview:label];
            return sectionView;
        }
        
    }
    else{
        if (section==0) {
            UIView * sectionView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44)];
            sectionView.backgroundColor = mCustomBgColor;
            UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(21, 21,[UIScreen mainScreen].bounds.size.width-21 ,21 )];
            label.textAlignment=NSTextAlignmentLeft;
            label.text= @""; //DPLocalizedString(@"temperatureAlarmSet");
            label.font=[UIFont systemFontOfSize:12];
            [sectionView addSubview:label];
            return sectionView;
        }
        else{
            
            UIView * sectionView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 164)];
            sectionView.backgroundColor = mCustomBgColor;
            return sectionView;
        }
    }
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
//    if (indexPath.section==0) {
//        return 44;
//    }
//    else {
//        if (_isEditor) {
//            return [UIScreen mainScreen].bounds.size.height-44*2-50*2-20-44*2-64;
//            
//        }else{
//            
//            return 50;
//        }
//    }
}



-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section==0?20:1;
//    if (section == 0) {
//        if (_isEditor) {
//            return 44;
//        }else{
//            return 20;
//        }
//    }
//    else{
//        if (_isEditor) {
//            return 164;
//        }
//        return 44;
//    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 1;
}






- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;;
}

@end
