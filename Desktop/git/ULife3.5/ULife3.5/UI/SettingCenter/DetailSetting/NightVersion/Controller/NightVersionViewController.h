//
//  NightVersionViewController.h
//  ULife3.5
//
//  Created by zhuochuncai on 3/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"

@interface NightVersionViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property(nonatomic,strong)DeviceDataModel *model;

@end
