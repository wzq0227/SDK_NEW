//
//  DeviceInfoViewController.h
//  ULife3.5
//
//  Created by zhuochuncai on 2/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"

@interface DeviceInfoViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *devInfoTableView;
@property (weak, nonatomic) IBOutlet UIButton *formatSDCardBtn;

@property(nonatomic,strong)DeviceDataModel *model;

@end
