//
//  PushMsgCtrlTableViewCell.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/12.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "PushMsgCtrlTableViewCell.h"

@interface PushMsgCtrlTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end

@implementation PushMsgCtrlTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.nameLabel.text = DPLocalizedString(@"set_push");
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

@end
