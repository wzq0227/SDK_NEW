//
//  LightDurationViewController.h
//  ULife3.5
//
//  Created by zhuochuncai on 5/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"

@interface LightDurationViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property(nonatomic,strong)DeviceDataModel *model;
@end
