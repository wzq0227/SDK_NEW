//
//  SecondRegistrerTableViewCell.m
//  goscamapp
//
//  Created by goscam_sz on 17/5/9.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "SecondRegistrerTableViewCell.h"

@implementation SecondRegistrerTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.contentView.bounds = [UIScreen mainScreen].bounds;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)refresh:(NSString *)str
{
    self.TextLabel.text= str;
    NSLog(@" 字符串：%@   高度 :%f",str,self.TextLabel.frame.size.height);
}

- (CGSize)sizeThatFits:(CGSize)size {
   
    CGSize maxSize = CGSizeMake(200, 1000);
    
    NSDictionary *attr=@{NSFontAttributeName:_TextLabel.font};
    
    CGSize labelSize = [_TextLabel.text boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:attr context:nil].size;

    return labelSize;
}

@end
