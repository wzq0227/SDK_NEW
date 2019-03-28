//
//  DeviceListTableViewCell_5200.m
//  ULife3.5
//
//  Created by Goscam on 2018/3/16.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "DeviceListTableViewCell_5200.h"
#import "MediaManager.h"

#define MCellIdentifier (@"SubDeviceTableViewCell")

@interface DeviceListTableViewCell_5200(){
    
}
@property (strong, nonatomic)  SubDevCellClickActionBlock clickCallback;
@end

@implementation DeviceListTableViewCell_5200

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    [self configUI];
    [self configTableView];
}

- (void)configUI{
    self.stationNameLabel.textColor = [UIColor darkGrayColor];
    self.stationNameLabel.font = [UIFont systemFontOfSize:15];
    
    [self.stationSettingBtn setTitle:@"● ● ●" forState:0];
    [self.stationSettingBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    self.stationSettingBtn.titleLabel.font = [UIFont systemFontOfSize:10];
    
    [self.stationIconImgView setImage:[UIImage imageNamed:@"devList_station_stationIcon"]];
    
    self.bellStatusImgView.image = [UIImage imageNamed:@"devList_station_bell_disable"];
    
    self.cloudStatusImgView.image = [UIImage imageNamed:@"devList_station_cloud_disable"];
    
    self.tfCardStatusImgView.image = [UIImage imageNamed:@"devList_station_tf_disable"];
    
    self.tfCardStatusImgView.hidden = self.cloudStatusImgView.hidden = self.bellStatusImgView.hidden = YES;
    
}

- (void)configTableView{
    self.subDevicesTableView.dataSource = self;
    self.subDevicesTableView.delegate = self;
    self.subDevicesTableView.scrollEnabled = NO;
    
    [self.subDevicesTableView registerNib:[UINib nibWithNibName:MCellIdentifier bundle:nil] forCellReuseIdentifier:MCellIdentifier];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.subDevices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    SubDeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MCellIdentifier];
    SubDevInfoModel *model = self.subDevices[indexPath.row];
    cell.devNameLabel.text = model.ChanName;
    cell.disOnLineView.hidden = model.Status==1;
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.covertImageView.image = [[MediaManager shareManager] coverWithDevId:model.devAndSubDevID
                                                                    fileName:nil
                                                                  deviceType:GosDeviceIPC
                                                                    position:PositionMain];;
    
    __weak typeof(self) weakSelf = self;
    [cell subDeviceClickCallback:^(SubDevCellAction actionType,int index) {
        if (weakSelf.clickCallback) {
            weakSelf.clickCallback(actionType,(int)indexPath.row);
        }
    }];
    return cell;
}

- (void)subDeviceClickCallback:(SubDevCellClickActionBlock)clickCallback{
    self.clickCallback = clickCallback;
}


#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return (40+SCREEN_WIDTH*9/16);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 1;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return nil;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    return nil;
}


#pragma mark - Model
- (void)setCellData:(DeviceDataModel *)cellData
{
    if (!cellData){
        return;
    }
    _cellData = cellData;
    _subDevices = cellData.SubDevice;
    _stationNameLabel.text = cellData.DeviceName;
    
    self.bellStatusImgView.image = [UIImage imageNamed:cellData.stationModel.bellRingOn?@"devList_station_bell_normal":@"devList_station_bell_disable"];
    
    self.cloudStatusImgView.image = [UIImage imageNamed:cellData.stationModel.csValid?@"devList_station_cloud_normal":@"devList_station_cloud_disable"];
    
    self.tfCardStatusImgView.image = [UIImage imageNamed:cellData.stationModel.tfCardInserted?@"devList_station_tf_normal":@"devList_station_tf_disable"];

    [self.subDevicesTableView reloadData];

}


/**
 设置是否在线显示 中继
 
 @param isOnline 是否在线
 */
- (void)setOnlineView:(GosDeviceStatus)isOnline{
    
}


/**
 设置封面
 
 @param cellData 设备数据 model
 */
- (UIImage *)covertImageWithData:(DeviceDataModel *)cellData{
    
    UIImage *coverImage = [[MediaManager shareManager] coverWithDevId:[cellData.DeviceId substringFromIndex:8]
                                                             fileName:nil
                                                           deviceType:cellData.DeviceType
                                                             position:PositionMain];
    
    return coverImage?:[UIImage imageNamed:@"defaultCovert.jpg"];
}



@end
