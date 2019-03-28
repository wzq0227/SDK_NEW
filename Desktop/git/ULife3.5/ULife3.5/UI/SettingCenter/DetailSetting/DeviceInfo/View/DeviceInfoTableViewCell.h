//
//  DeviceInfoTableViewCell.h
//  ULife3.5
//
//  Created by zhuochuncai on 2/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DeviceInfoTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UILabel *contentLabel;

@property (weak, nonatomic) IBOutlet UILabel *detailInfoLabel;

@property (weak, nonatomic) IBOutlet UIView *hasNewVersionView;

@property (weak, nonatomic) IBOutlet UIImageView *hasNextPageArrow;
@end
