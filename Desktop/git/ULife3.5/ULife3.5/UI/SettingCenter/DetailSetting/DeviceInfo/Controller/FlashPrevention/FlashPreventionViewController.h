//
//  FlashPreventionViewController.h
//  ULife3.5
//
//  Created by zhuochuncai on 12/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"

typedef void(^NTSCSettingResultBlock)(int result);

@interface FlashPreventionViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property(nonatomic,assign)int hz;
@property(nonatomic,strong)DeviceDataModel *model;

- (void)didFinishSettingNTSCWithCallback:(NTSCSettingResultBlock)resultBlock;

@end
