//
//  IpcFourViewDevListTableViewCell.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/9/21.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"


#define DEV_LIST_CELL_BG_COLOR  ([UIColor colorWithRed:0.5f green:0.5f blue:0.5f alpha:0.5f])


@interface IpcFourViewDevListTableViewCell : UITableViewCell

@property (nonatomic, strong) DeviceDataModel *devListCellData;

- (void)configLabelColor:(UIColor *)color;

- (void)configBackgroundColor:(UIColor *)color;

@end
