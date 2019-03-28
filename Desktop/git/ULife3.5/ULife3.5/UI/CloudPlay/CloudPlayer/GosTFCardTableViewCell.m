//
//  GosTFCardTableViewCell.m
//  ULife3.5
//
//  Created by AnDong on 2018/12/25.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "GosTFCardTableViewCell.h"
@interface GosTFCardTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *deviceNameLabel;
@property (weak, nonatomic) IBOutlet UIButton *typeButton;
@property (weak, nonatomic) IBOutlet UIImageView *placeholderImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *timeLabelRightConstraint;
@property (weak, nonatomic) IBOutlet UIButton *selectButton;

@end
@implementation GosTFCardTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setModel:(SDCloudVideoModel *)model {
    _model = model;
    
    _selectButton.hidden = !model.isEditing;
    _selectButton.selected = model.isSelected;
    
    _timeLabelRightConstraint.constant = _selectButton.hidden ? 23 : 68;
    
    _timeLabel.text = model.startTime;
    _deviceNameLabel.text = model.deviceName;
    _placeholderImageView.image = model.placeholderImage?:[UIImage imageNamed:@"img_events_playback_default"];
    [_typeButton setImage:model.AT==12?[UIImage imageNamed:@"icon_bell"]:[UIImage imageNamed:@"icon_motion"] forState:UIControlStateNormal];
//    [_typeButton setImage:model.type == 0 ? [UIImage imageNamed:@"icon_motion"] : [UIImage imageNamed:@"icon_bell"] forState:UIControlStateNormal];
}
@end
