//
//  SensitivitySettingViewController.h
//  ULife3.5
//
//  Created by zhuochuncai on 4/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"
#import "BaseCommand.h"

@interface SensitivitySettingViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property(nonatomic,strong)DeviceDataModel *model;
@property(nonatomic,strong)CMD_GetAllParamResp *getAllParamResp;
@end
