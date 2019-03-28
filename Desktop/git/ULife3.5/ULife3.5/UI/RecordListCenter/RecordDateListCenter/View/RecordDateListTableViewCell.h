//
//  RecordDateListTableViewCell.h
//  goscamapp
//
//  Created by shenyuanluo on 2017/4/28.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RecordDateTableViewCellModel.h"

@interface RecordDateListTableViewCell : UITableViewCell

/**
 *  RecordDateListTableView cell 数据对象
 */
@property (strong, nonatomic) RecordDateTableViewCellModel *recordDateTableViewCellData;

@end
