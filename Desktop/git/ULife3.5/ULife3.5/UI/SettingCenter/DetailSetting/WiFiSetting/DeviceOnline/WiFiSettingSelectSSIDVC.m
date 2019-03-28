//
//  WiFiSettingSelectSSIDVC.m
//  ULife3.5
//
//  Created by zhuochuncai on 12/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "WiFiSettingSelectSSIDVC.h"
#import "NetSDK.h"
#import "BaseCommand.h"
#import "Masonry.h"

@interface WiFiSettingSelectSSIDVC ()<UITableViewDataSource,UITableViewDelegate>
@property(nonatomic,strong)CMD_GetDeviceSSIDListResp   *getSSIDInfoResp;
@property(nonatomic,strong)NetSDK *netSDK;
@end

@implementation WiFiSettingSelectSSIDVC

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [SVProgressHUD dismiss];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configTableView];
    [self configUI];

    [self getSSIDInfoList];
}

- (void)configUI{
    self.title = DPLocalizedString(@"WiFi_setting_online");
    self.view.backgroundColor = BACKCOLOR(238,238,238,1);
}

- (void)configTableView{
    self.automaticallyAdjustsScrollViewInsets = NO;
    _tableView.scrollEnabled = YES;
    _tableView.dataSource = self;
    _tableView.delegate = self;
}


#pragma mark ==<Network>
- (void)getSSIDInfoList{
    _netSDK = [NetSDK sharedInstance];
    [SVProgressHUD showWithStatus:@"Loading..."];
    
    __weak typeof(self) weakSelf = self;
    CMD_GetDeviceSSIDListReq *req = [CMD_GetDeviceSSIDListReq new];
    [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[req requestCMDData] timeout:32000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            weakSelf.getSSIDInfoResp = [CMD_GetDeviceSSIDListResp yy_modelWithJSON:dict];
            NSArray *tempArray = [weakSelf.getSSIDInfoResp.ssid_info sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *_Nonnull obj1, NSDictionary *_Nonnull obj2) {
                return [obj1[@"un_signal_level"]intValue] < [obj2[@"un_signal_level"]intValue] ;
            }];
            weakSelf.getSSIDInfoResp.ssid_info = tempArray;
        }
        [weakSelf dealWithGetOperationResultWithResult:result];
    }];
}

- (void)sendSetWifiInfoRequestWithWifiName:(NSString*)wifiName password:(NSString*)pwd{

    [SVProgressHUD showWithStatus:@"Loading..."];
    
    __weak typeof(self) weakSelf = self;
    CMD_SetWifiInfoReq *req = [CMD_SetWifiInfoReq new];
    req.a_SSID              = wifiName;
    req.a_passwd            = pwd;
    
    [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[req requestCMDData] timeout:12000 responseBlock:^(int result, NSDictionary *dict) {
        
        [weakSelf dealWithOperationResultWithResult:result];
        if (result == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.navigationController popToRootViewControllerAnimated:YES];
            });
        }
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
    int count = _getSSIDInfoResp.ssid_info.count;
    _tableView.hidden = count==0;
    return count;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    CMD_SSIDInfo *info = [CMD_SSIDInfo yy_modelWithDictionary: (self.getSSIDInfoResp.ssid_info[indexPath.row])];
    
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(15, 10, 120, 30)];
    label.textAlignment = NSTextAlignmentLeft;
    label.font = [UIFont fontWithName:@"PingFangSC-Regular" size:17];
    label.text = info.a_SSID;
    
    [cell addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(cell);
        make.leading.equalTo(cell).offset(15);
    }];
    
    int level = ((info.un_signal_level+10)/30)%4;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 10, 30, 30)];
    imageView.image        =  [UIImage imageNamed:[NSString stringWithFormat:@"WiFiSignal_Level_%d.png",level]];
    [cell addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(cell);
        make.trailing.equalTo(cell).offset(-15);
        make.height.mas_equalTo(15);
        make.width.equalTo(imageView.mas_height);
    }];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    CMD_SSIDInfo *info = [CMD_SSIDInfo yy_modelWithDictionary:self.getSSIDInfoResp.ssid_info[indexPath.row]];
    [self showAlertWithName:info.a_SSID];
}

- (void)showAlertWithName:(NSString*)name{
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: DPLocalizedString(@"WiFi_setting")
                                                                              message: nil
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = name;
        textField.userInteractionEnabled = NO;
//        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = DPLocalizedString(@"iRouter_password");
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [textField becomeFirstResponder];
//        textField.secureTextEntry = YES;
    }];
    
    [alertController addAction:[UIAlertAction actionWithTitle:DPLocalizedString(@"Setting_Cancel") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    }]];
    __weak typeof(self) weakSelf = self;

    [alertController addAction:[UIAlertAction actionWithTitle:DPLocalizedString(@"Setting_Setting") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray * textfields = alertController.textFields;
        
        UITextField * namefield = textfields[0];
        UITextField * passwordfiled = textfields[1];
        NSLog(@"%@:%@",namefield.text,passwordfiled.text);
        [weakSelf sendSetWifiInfoRequestWithWifiName:namefield.text password:passwordfiled.text];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}
//CMD_SetWifiInfoReq

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
