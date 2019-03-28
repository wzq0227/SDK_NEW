//
//  nvrSettingTableViewCell.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/23.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NvrSettingDataModel.h"


@interface nvrSettingTableViewCell : UITableViewCell

@property (nonatomic, strong) NvrSettingDataModel *nvrSettingCellData;

/**
 显示新版本提示 View
 */
- (void)showNewVersionView;

@end
