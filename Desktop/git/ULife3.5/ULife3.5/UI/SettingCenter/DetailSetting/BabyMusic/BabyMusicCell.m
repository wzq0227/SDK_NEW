//
//  BabyMusicCell.m
//  ULife3.5
//
//  Created by AnDong on 2017/8/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "BabyMusicCell.h"
#import <Masonry.h>

@implementation BabyMusicCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self.contentView addSubview:self.myTitleLabel];
        [self.contentView addSubview:self.rightImgView];
        [self makeConstraints];
    }
    return self;
}

- (void)makeConstraints{
    
    [self.myTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(24.0f);
        make.top.equalTo(self.contentView).offset(20.0f);
        make.height.equalTo(@20);
        make.width.equalTo(@250);
    }];
    
    [self.rightImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-20.0f);
        make.top.equalTo(self.contentView).offset(22.5f);
        make.height.width.equalTo(@15);
    }];
}


- (UILabel *)myTitleLabel{
    if (!_myTitleLabel) {
        _myTitleLabel = [[UILabel alloc]init];
        _myTitleLabel.textAlignment = NSTextAlignmentLeft;
        _myTitleLabel.textColor = [UIColor blackColor];
        _myTitleLabel.font = [UIFont systemFontOfSize:16.0f];
    }
    return _myTitleLabel;
}


- (UIImageView *)rightImgView{
    if (!_rightImgView) {
        _rightImgView = [[UIImageView alloc]init];
    }
    return _rightImgView;
}


@end
