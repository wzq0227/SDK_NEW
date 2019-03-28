//
//  GosTFCardViewController.h
//  ULife3.5
//
//  Created by zz on 2018/12/25.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"

@interface GosTFCardViewController : UIViewController

@property (nonatomic, assign) int channel;
@property (nonatomic, strong) DeviceDataModel *deviceModel;
- (void)refreshListActionForDelete;
@end
