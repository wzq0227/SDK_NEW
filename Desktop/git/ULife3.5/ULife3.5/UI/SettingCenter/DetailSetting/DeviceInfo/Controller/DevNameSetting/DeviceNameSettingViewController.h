//
//  DeviceNameSettingViewController.h
//  ULife3.5
//
//  Created by zhuochuncai on 12/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"

typedef void(^ChangeNameBlock)(NSString *name);

@interface DeviceNameSettingViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;


@property (nonatomic, strong)  NSString *subDevName;

@property(nonatomic,strong)DeviceDataModel *model;

- (void)didChangeDevNameCallback:(ChangeNameBlock)block;
@end
