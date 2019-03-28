//
//  settingCell.h
//  goscamapp
//
//  Created by goscam_sz on 17/5/6.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "settingMode.h"

@interface settingCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *nameLabel;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *headImageView;

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

@property (weak, nonatomic) IBOutlet UISwitch *settingSwitch;

@property (weak, nonatomic) IBOutlet UIImageView *settingArrow;

@property (weak, nonatomic) IBOutlet UILabel *detailLabel;

@property (weak, nonatomic) IBOutlet UIImageView *detailImageView;


@property(nonatomic,strong) dataModel *model;
-(void)refreshUIWithModel:(dataModel *)model;

@end
