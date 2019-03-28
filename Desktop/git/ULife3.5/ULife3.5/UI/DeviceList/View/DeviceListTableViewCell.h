//
//  DeviceListTableViewCell.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/2.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"

@interface DeviceListTableViewCell : UITableViewCell

@property (nonatomic, strong) DeviceDataModel *devListTableViewCellData;

@property (weak, nonatomic) IBOutlet UIView *bottomContainerView;

@property (weak, nonatomic) IBOutlet UIButton *playTipBtn;

@property (strong, nonatomic)  UIButton *settingBtn;

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
