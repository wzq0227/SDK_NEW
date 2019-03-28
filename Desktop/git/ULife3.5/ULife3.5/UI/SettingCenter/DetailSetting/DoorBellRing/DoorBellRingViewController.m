//
//  DoorBellRingViewController.m
//  ULife3.5
//
//  Created by AnDong on 2018/8/27.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "DoorBellRingViewController.h"
#import "BaseCommand.h"
#import "NetSDK.h"
#import "DoorBellRingTableViewCell.h"

@interface DoorBellRingViewController () <UITableViewDataSource, UITableViewDelegate> {
    __block int sliderValue;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *btn;

@end

@implementation DoorBellRingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = DPLocalizedString(@"Setting_BellRemind");
    [self.btn setTitle:DPLocalizedString(@"Setting_Done") forState:UIControlStateNormal];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [self getDoorBellVolume];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DoorBellRingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DoorBellRingCell"];
    if (!cell)
        cell = [[NSBundle mainBundle] loadNibNamed:@"DoorBellRingTableViewCell" owner:self options:nil].lastObject;
    
    if (indexPath.row == 0) {
        cell.imageView.image = [UIImage imageNamed:@"Setting_BellRemind"];
        cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
        cell.textLabel.text = DPLocalizedString(@"Setting_BellRemind");
        
        UISwitch *s = [[UISwitch alloc] initWithFrame:CGRectMake(SCREEN_WIDTH-61, 6, 51, 31)];
        [s addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventTouchUpInside];
        [cell addSubview:s];
        
        cell.leftLabel.hidden = YES;
        cell.rightLabel.hidden = YES;
        cell.slider.hidden = YES;
        s.on = self.getAllParamResp.doorbell_ring;
    }
    
    if (indexPath.row == 1) {
        cell.slider.value = 192-sliderValue;
        cell.blk = ^(int v) {
            sliderValue = v;
        };
    }
        
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 1)
        return 70.0;
    
    return 44.0;
}

- (void)switchValueChanged:(UISwitch *)s {
    CMD_SetDBBellRemindReq *reqCmd = [CMD_SetDBBellRemindReq new];
    reqCmd.doorbell_ring = s.on;
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:_model.DeviceId requestData:[reqCmd requestCMDData] timeout:10000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            self.getAllParamResp.doorbell_ring = reqCmd.doorbell_ring;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
    }];
}

- (IBAction)btnDidClick:(UIButton *)b {
    [self setDoorBellVolume:sliderValue];
}

- (void)getDoorBellVolume {
    [SVProgressHUD showWithStatus:@"Loading..."];
    CMD_GetDBBellVolumeReq *req = [CMD_GetDBBellVolumeReq new];
    
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:_model.DeviceId requestData:[req requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            CMD_GetDBBellVolumeResp *tmp = [CMD_GetDBBellVolumeResp yy_modelWithDictionary:dict];
            dispatch_async(dispatch_get_main_queue(), ^{
                sliderValue = tmp.Volume;
                [self.tableView reloadData];
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
           [SVProgressHUD dismiss];
        });
    }];
}

- (void)setDoorBellVolume:(int)v {
    CMD_SetDBBellVolumeReq *reqCmd = [CMD_SetDBBellVolumeReq new];
    reqCmd.Volume = 192-v;
    
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:self.model.DeviceId requestData:[reqCmd requestCMDData] timeout:10000 responseBlock:^(int result, NSDictionary *dict) {
        
    }];
    
    [self.navigationController popViewControllerAnimated:YES];
}
@end
