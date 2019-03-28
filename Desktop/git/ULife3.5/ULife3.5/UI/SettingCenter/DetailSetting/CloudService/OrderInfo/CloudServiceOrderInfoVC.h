//
//  CloudServiceOrderInfoVC.h
//  ULife3.5
//
//  Created by Goscam on 2017/9/13.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSNetworkLib.h"
#import "DeviceDataModel.h"

@interface CloudServiceOrderInfoVC : UIViewController


/**
 续费按钮
 */
@property (strong, nonatomic)  UIButton *renewBtn;


@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic)  CSQueryCurServiceResp *curServiceResp;

@property (strong, nonatomic)  NSString *deviceId;

@property (strong, nonatomic)  DeviceDataModel *deviceModel;
@end
