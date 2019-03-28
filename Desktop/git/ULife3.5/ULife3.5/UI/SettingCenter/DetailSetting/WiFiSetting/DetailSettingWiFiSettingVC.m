//
//  DetailSettingWiFiSettingVC.m
//  ULife3.5
//
//  Created by zhuochuncai on 3/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "DetailSettingWiFiSettingVC.h"
#import "WiFiSettingSelectSSIDVC.h"
#import "WiFiSettingConnectWiFiVC.h"

@interface DetailSettingWiFiSettingVC ()<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewHeightConstraint;
@property (assign, nonatomic)  int numberOfRows;
@end

@implementation DetailSettingWiFiSettingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self configTableView];
    [self configUI];
}

- (void)configUI{
    self.title = DPLocalizedString(@"Setting_WiFiSetting");
    self.view.backgroundColor = BACKCOLOR(238,238,238,1);
}

- (void)configTableView{
    self.automaticallyAdjustsScrollViewInsets = NO;
    _tableView.scrollEnabled = NO;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    
    self.numberOfRows = [self deviceSupportOffLineConfigWithUID:self.model.DeviceId ]? 2 : 1;
    
    self.tableViewHeightConstraint.constant = self.numberOfRows==1?50:100;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}


#pragma mark ==<TableViewDelegate>

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.numberOfRows;
}

- (BOOL)deviceSupportOffLineConfigWithUID:(NSString*)UID{
    GosDetailedDeviceType detailType = [DeviceDataModel detailedDeviceTypeWithString:[self.model.DeviceId substringWithRange:NSMakeRange(3, 2)]];
    return detailType!=GosDetailedDeviceType_T5100ZJ && detailType!=GosDetailedDeviceType_T5200HCA;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(20, 10, 250, 30)];
    label.font = [UIFont fontWithName:@"PingFangSC-Regular" size:15];
    label.textAlignment = NSTextAlignmentLeft;
    
    if (indexPath.row == 1) {
        label.text = DPLocalizedString(@"WiFiSetting_DeviceOffLine");
    }else{
        label.text = DPLocalizedString(@"WiFiSetting_DeviceOnLine");
    }
    [cell addSubview:label];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.row == 1) {
        WiFiSettingConnectWiFiVC *vc = [[WiFiSettingConnectWiFiVC alloc] init];
        vc.model                     = _model;
        [self.navigationController pushViewController:vc animated:YES];
    }else{
        WiFiSettingSelectSSIDVC *vc = [[WiFiSettingSelectSSIDVC alloc] init];
        vc.model = _model;
        [self.navigationController pushViewController:vc animated:YES];
    }

}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0;
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
