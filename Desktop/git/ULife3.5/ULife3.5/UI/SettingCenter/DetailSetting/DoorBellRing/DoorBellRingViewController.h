//
//  DoorBellRingViewController.h
//  ULife3.5
//
//  Created by AnDong on 2018/8/27.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DeviceDataModel.h"
#import "BaseCommand.h"

@interface DoorBellRingViewController : UIViewController

@property(nonatomic,strong)DeviceDataModel *model;
@property (nonatomic,strong) CMD_GetAllParamResp  *getAllParamResp;

@end
