//
//  DeviceListTableViewCell_5200.h
//  ULife3.5
//
//  Created by Goscam on 2018/3/16.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SubDeviceTableViewCell.h"


@interface DeviceListTableViewCell_5200 : UITableViewCell
<UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *topContainerView;

@property (weak, nonatomic) IBOutlet UIImageView *stationIconImgView;

@property (weak, nonatomic) IBOutlet UIImageView *cloudStatusImgView;

@property (weak, nonatomic) IBOutlet UIImageView *tfCardStatusImgView;

@property (weak, nonatomic) IBOutlet UIImageView *bellStatusImgView;

@property (weak, nonatomic) IBOutlet UIButton *stationSettingBtn;

@property (weak, nonatomic) IBOutlet UILabel *stationNameLabel;


@property (weak, nonatomic) IBOutlet UITableView *subDevicesTableView;

@property (nonatomic, strong) DeviceDataModel *cellData;

@property (strong, nonatomic)  NSMutableArray<SubDevInfoModel*> *subDevices;

- (void)subDeviceClickCallback:(SubDevCellClickActionBlock)clickCallback;

/**
 设置是否在线显示
 
 @param isOnline 是否在线
 */
- (void)setOnlineView:(GosDeviceStatus)isOnline;


/**
 设置封面
 
 @param cellData 设备数据 model
 */
- (void)setCovertImageWithData:(DeviceDataModel *)cellData;

@end
