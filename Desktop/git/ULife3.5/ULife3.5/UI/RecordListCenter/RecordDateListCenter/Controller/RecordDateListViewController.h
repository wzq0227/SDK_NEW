//
//  RecordDateListViewController.h
//  goscamapp
//
//  Created by shenyuanluo on 2017/4/27.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"

@interface RecordDateListViewController : UIViewController

/**
 *  设备ID
 */
@property (nonatomic, copy) NSString *deviceId;

@property(nonatomic,strong)DeviceDataModel *model;

@property (assign, nonatomic)  BOOL enterInFullScreenMode;

@end
