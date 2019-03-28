//
//  LightDurationTableViewCell.h
//  ULife3.5
//
//  Created by zhuochuncai on 5/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LightDurationTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UILabel *detailLabel;


@property (weak, nonatomic) IBOutlet UISwitch *cellSwitch;

@end
