//
//  PlayListViewController.h
//  ULife3.5
//
//  Created by 广东省深圳市 on 2017/6/15.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"
#import "MediaManager.h"

@interface PlayListViewController : UIViewController

@property (nonatomic,copy) NSString *deviceID;

@property (strong, nonatomic)  DeviceDataModel *model;

/** 视频 画面位置枚举 */
@property (nonatomic, assign) PositionType positionType;


@end
