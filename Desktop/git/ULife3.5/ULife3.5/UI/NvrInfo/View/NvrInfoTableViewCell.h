//
//  NvrInfoTableViewCell.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/24.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NvrInfoCellDataModel.h"

@interface NvrInfoTableViewCell : UITableViewCell

@property (nonatomic, strong) NvrInfoCellDataModel *infoCellData;


/**
 显示新版本提示 View
 */
- (void)showUpdateVersionView;

@end
