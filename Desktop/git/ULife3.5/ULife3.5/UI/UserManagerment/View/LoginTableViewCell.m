//
//  LoginTableViewCell.m
//  gaoscam
//
//  Created by goscam_sz on 17/4/19.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "LoginTableViewCell.h"

@implementation LoginTableViewCell
{
    BOOL  isAction;

}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
     [self.headerButton setImage:[UIImage imageNamed:@"unshowPassword"] forState:UIControlStateNormal];
     isAction =YES;
//    [self.headerButton setImage:[UIImage imageNamed:@"showPassword"] forState:UIControlStateNormal];
}



- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}






- (IBAction)actionPasswordBtn:(id)sender {
    
    if (isAction) {
        [self.headerButton setImage:[UIImage imageNamed:@"showPassword"] forState:UIControlStateNormal];
    }
    else{
        [self.headerButton setImage:[UIImage imageNamed:@"unshowPassword"] forState:UIControlStateNormal];
    }
    isAction=!isAction;
    self.mycellPasswordBlock(isAction);
}

@end
