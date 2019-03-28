//
//  LightDurationViewController.m
//  ULife3.5
//
//  Created by zhuochuncai on 5/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "LightDurationViewController.h"
#import "LightDurationTableViewCell.h"
#import "LightDurationFooterView.h"
#import "BaseCommand.h"
#import "NetSDK.h"
#import "LightDurationOnOffTimeSettingVC.h"

@interface LightDurationViewController ()<UITableViewDelegate,UITableViewDataSource>
@property(nonatomic,strong)CMD_LightDuration *lightDurationData;
@property(nonatomic,strong)CMD_LightDuration *tempReq;
@property(nonatomic,strong)NetSDK             *netSDK;
@end

@implementation LightDurationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configUI];
    [self configTableView];
    [self getLightDurationSetting];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if ([SVProgressHUD isVisible]) {
        [SVProgressHUD dismiss];
    }
}


- (void)configUI{
    self.title = DPLocalizedString(@"Setting_LightDuration");
    self.view.backgroundColor = BACKCOLOR(238,238,238,1);
    [self configNavigationItem];
}

- (void)configTableView{
    self.tableView.dataSource = self;
    self.tableView.delegate   = self;
    [self.tableView registerNib:[UINib nibWithNibName:@"LightDurationTableViewCell" bundle:nil] forCellReuseIdentifier:@"LightDurationTableViewCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"LightDurationFooterView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"LightDurationFooterView"];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
}


#pragma mark <保存>
- (void)configNavigationItem{
    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    saveBtn.frame     = CGRectMake(0, 0, 60, 40);
    [saveBtn setTitle:DPLocalizedString(@"Title_Save") forState:0];
    [saveBtn addTarget:self action:@selector(saveBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:saveBtn];
}

- (void)saveBtnClicked:(id)sender{
    
    [SVProgressHUD showWithStatus:@"Loading..."];

    CMD_SetLightDurationReq *req = [CMD_SetLightDurationReq new];
    _tempReq.CMDType = _lightDurationData.CMDType = req.CMDType;
    
    __weak typeof(self) weakSelf = self;
    [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[_lightDurationData requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        if (result != 0) {
            weakSelf.lightDurationData = [CMD_SetLightDurationReq yy_modelWithDictionary:[weakSelf.tempReq yy_modelToJSONObject]];
        }else{
            weakSelf.tempReq = [CMD_SetLightDurationReq yy_modelWithDictionary:[weakSelf.lightDurationData yy_modelToJSONObject]];
        }
        [weakSelf dealWithOperationResultWithResult:result];
    }];

}

#pragma mark ==<Network>
- (void)getLightDurationSetting{
    _netSDK = [NetSDK sharedInstance];
    CMD_GetLightDurationReq *req = [CMD_GetLightDurationReq new];
    __weak typeof(self) weakSelf = self;
    [SVProgressHUD showWithStatus:@"Loading..."];

    [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[req requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            weakSelf.lightDurationData = [CMD_GetLightDurationResp yy_modelWithJSON:dict];
            weakSelf.tempReq           = [CMD_GetLightDurationResp yy_modelWithJSON:dict];
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

#pragma mark ==<TableViewDelegate>

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return 3; //section == 0 ? 1 : 3
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1; //2
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellReuseIdentifier = @"LightDurationTableViewCell";
    
    LightDurationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    
    switch (indexPath.section+indexPath.row) {
        case 0:
            cell.titleLabel.text = DPLocalizedString(@"LightDuration_WholeDayOff");
            cell.cellSwitch.on   = (_lightDurationData.un_wday_switch&0x7f)==0;
            break;
        case 1:
            cell.titleLabel.text = DPLocalizedString(@"LightDuration_OnTime");
            cell.detailLabel.text = !_lightDurationData?@"19:00":[NSString stringWithFormat:@"%02d:%02d",_lightDurationData.un_on_hour,_lightDurationData.un_on_min];
            break;
        case 2:
            cell.titleLabel.text = DPLocalizedString(@"LightDuration_OffTime");
            cell.detailLabel.text = !_lightDurationData?@"07:00":[NSString stringWithFormat:@"%02d:%02d",_lightDurationData.un_off_hour,_lightDurationData.un_off_min];
            break;
        default:
            break;
    }
    
    if (indexPath.section ==0 && indexPath.row > 0) {
        BOOL isSwitchOn = (_lightDurationData.un_wday_switch&0x7f)==0;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.cellSwitch.hidden = YES;
        cell.selectionStyle = isSwitchOn  ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;
    
        cell.titleLabel.textColor = isSwitchOn ?[UIColor grayColor]:[UIColor blackColor];
        cell.detailLabel.textColor = isSwitchOn ?[UIColor grayColor]:[UIColor blackColor];
    }else{
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.detailLabel.hidden = YES;
    }
    [cell.cellSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    return cell;
}

- (void)switchValueChanged:(id)sender{
    
    UISwitch *cellSwitch = (UISwitch*)sender;

    if ( cellSwitch.isOn ) {
        [self sendSelectWeekdaysRequestWithValue:0 ];
    }else{
        [self sendSelectWeekdaysRequestWithValue:0x7f ];
    }
    NSLog(@"____________switchValueChanged______________:");
}



- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    
    return 160;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    return 40;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSString *title = nil;
    switch (section) {
        case 0:
            title = @"LightDuration_ManualOnDuration";
            break;
        case 1:
            title = @"";
            break;
        case 2:
            title = @"";
            break;
        case 3:
            title = @"";
            break;
        default:
            break;
    }
    return DPLocalizedString(title);
}

-(UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (section == 0) {
        LightDurationFooterView *footerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"LightDurationFooterView" ];
        footerView.selectedWeekdays = _lightDurationData.un_wday_switch;
        
        [footerView.collectionView reloadData];
        footerView.blackLineView.userInteractionEnabled = NO;
        
        __weak typeof(self) weakSelf = self;
        [footerView selectWeekdaysCallback:^(int selectedDays) {
            [weakSelf sendSelectWeekdaysRequestWithDay:selectedDays];
        }];
        return footerView;
    }
    return nil;
}

- (void)sendSelectWeekdaysRequestWithDay:(int)day{
    
    BOOL hasSelectedPosition = (_lightDurationData.un_wday_switch >> day) & 1;
    int  selectValue = hasSelectedPosition ? (_lightDurationData.un_wday_switch & (~(1 << day))) : (_lightDurationData.un_wday_switch | (1 << day)) ;
    [self sendSelectWeekdaysRequestWithValue:selectValue];
}


- (void)sendSelectWeekdaysRequestWithValue:(int)selectValue{
    
    _lightDurationData.un_wday_switch = selectValue;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    BOOL isSwitchOn = (_lightDurationData.un_wday_switch&0x7f)==0;
    if (isSwitchOn) {
        return;
    }
    
    if (indexPath.row > 0) {

        __weak typeof(self) weakSelf = self;
        LightDurationOnOffTimeSettingVC *vc = [[LightDurationOnOffTimeSettingVC alloc] init];
        vc.hour = indexPath.row==1 ? _lightDurationData.un_on_hour : _lightDurationData.un_off_hour;
        vc.min  = indexPath.row==1 ? _lightDurationData.un_on_min : _lightDurationData.un_off_min ;
        
        [vc selectTimeCallback:^(int hour, int min) {
            [weakSelf sendSelectOnOffTimeRequestWithHour:hour min:min isOnSetting:indexPath.row==1];
        }];
        [self.navigationController pushViewController:vc animated:YES];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)sendSelectOnOffTimeRequestWithHour:(int)hour min:(int)min isOnSetting:(BOOL)onSetting{

    if (onSetting) {
        _lightDurationData.un_on_min =  min;
        _lightDurationData.un_on_hour = hour;
    }else{
        _lightDurationData.un_off_min = min;
        _lightDurationData.un_off_hour = hour;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        [self.navigationController popViewControllerAnimated:NO];
    });
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
