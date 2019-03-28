//
//  AddStationAndSubDeviceVC.h
//  ULife3.5
//
//  Created by Goscam on 2018/3/20.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"
#import "InfoForAddingDevice.h"

@interface AddStationAndSubDeviceVC : UIViewController

@property (weak, nonatomic) IBOutlet  UITableView *addDevTableView;

@property (assign, nonatomic)  BOOL isDevListEmpty;

@property (nonatomic, strong)  DeviceDataModel *devModel;

@property (strong, nonatomic)  InfoForAddingDevice *addDevInfo;
@end
