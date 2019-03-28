//
//  StorageInfoTableViewCell.h
//  ULife3.5
//
//  Created by zhuochuncai on 3/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StorageInfoTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UILabel *storageUsedLabel;

@property (weak, nonatomic) IBOutlet UILabel *storageFreeLabel;

@end
