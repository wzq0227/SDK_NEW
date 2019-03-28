//
//  PushSettingTableViewCell.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/12.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PushDevSetingStateModel.h"

@class DeviceDataModel;

@interface PushSettingTableViewCell : UITableViewCell

@property (nonatomic, strong) DeviceDataModel *pushSettingCellData;

- (void)freshenWith:(PushDevSetingStateModel *)md;

@end
