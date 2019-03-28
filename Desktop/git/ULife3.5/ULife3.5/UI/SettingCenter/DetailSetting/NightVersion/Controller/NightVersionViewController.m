//
//  NightVersionViewController.m
//  ULife3.5
//
//  Created by zhuochuncai on 3/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "NightVersionViewController.h"
#import "NightVersionTableViewCell.h"
#import "BaseCommand.h"
#import "NetSDK.h"

@interface NightVersionViewController ()<UITableViewDelegate,UITableViewDataSource>
@property(nonatomic,strong)NetSDK *netSDK;
@property(nonatomic,strong)CMD_Device_Night *devNightVersionData;
@property(nonatomic,strong)CMD_SetDeviceNightSwitchReq *setRequest;
@end

@implementation NightVersionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self configUI];
    [self configureTableView];
    [self getDeviceNightVersion];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if ([SVProgressHUD isVisible]) {
        [SVProgressHUD dismiss];
    }
}

- (void)configureTableView{
    
    [self.tableView registerNib:[UINib nibWithNibName:@"NightVersionTableViewCell" bundle:nil] forCellReuseIdentifier:@"NightVersionTableViewCell"];
    
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.tableView.scrollEnabled = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)configUI{
    self.title = DPLocalizedString(@"Setting_NightVersion");
    self.view.backgroundColor = BACKCOLOR(238,238,238,1);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark ==<TableViewDelegate>

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return 2;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NightVersionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NightVersionTableViewCell" forIndexPath:indexPath];
    
    if (indexPath.row == 0) {
        cell.titleLabel.text = DPLocalizedString(@"NightVersion_Switch");
        cell.cellSwitch.on = _devNightVersionData ? _devNightVersionData.un_day_night : NO;
    }else{
        cell.titleLabel.text = DPLocalizedString(@"NightVersion_Auto");
        cell.cellSwitch.on = _devNightVersionData ? _devNightVersionData.un_auto : NO;
    }
    
    [cell.cellSwitch setTag:indexPath.row];
    [cell.cellSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)switchValueChanged:(id)sender{
    UISwitch *mySwitch = (UISwitch*)sender;
    _setRequest = [CMD_SetDeviceNightSwitchReq new];
    _setRequest.channel = (int)_model.avChnnelNum;
    if (mySwitch.tag == 0) {
        _setRequest.un_day_night = mySwitch.on;
        _setRequest.un_auto = !mySwitch.on;
    }else{
        _setRequest.un_auto = mySwitch.on;
        _setRequest.un_day_night = !mySwitch.on;
    }
    [self sendChangeNightVersionCmd];
}

#pragma mark== <Network>
- (void)getDeviceNightVersion{
    _netSDK = [NetSDK sharedInstance];
    CMD_GetDeviceNightSwitchReq *req = [CMD_GetDeviceNightSwitchReq new];
    req.channel = (int)_model.avChnnelNum;
    __weak typeof(self) weakSelf = self;
    
    [SVProgressHUD showWithStatus:@"Loading..."];
    [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[req requestCMDData] timeout:5000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            weakSelf.devNightVersionData = [CMD_GetDeviceNightSwitchResp yy_modelWithDictionary:dict];
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


#pragma mark ==<Events>
- (void)sendChangeNightVersionCmd{
    
    __weak typeof(self) weakSelf = self;
    
    [SVProgressHUD showWithStatus:@"Loading..."];
    [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[_setRequest requestCMDData] timeout:5000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            weakSelf.devNightVersionData.un_auto = weakSelf.setRequest.un_auto;
            weakSelf.devNightVersionData.un_day_night = weakSelf.setRequest.un_day_night;
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
