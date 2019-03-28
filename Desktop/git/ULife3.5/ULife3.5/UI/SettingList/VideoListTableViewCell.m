//
//  VideoListCell.m
//  goscamapp
//
//  Created by goscam_sz on 17/4/20.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "VideoListTableViewCell.h"

@implementation VideoListTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}



- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}



-(void)freshen:(VideoModel *)md
{
    self.headerImageView.image=[UIImage imageNamed:@"listDemo.jpg"];
    self.FirstLabel.text=md.devName;
    self.SecondLabel.text=md.devId;
}

@end
