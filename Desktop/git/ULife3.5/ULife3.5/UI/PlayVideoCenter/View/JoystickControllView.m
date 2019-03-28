//
//  JoystickControllView.m
//  goscamapp
//
//  Created by shenyuanluo on 2017/4/28.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "JoystickControllView.h"
#import <Masonry.h>
#import "UIColor+YYAdd.h"


@interface JoystickControllView ()

/**
 *  centerImageView
 */
@property (nonatomic,strong)  UIImageView *centerImgView;

@end


@implementation JoystickControllView

- (instancetype)init{
    if (self = [super init]) {
        [self setupUI];
        [self makeConstraints];
    }
    return self;
}


- (void)dealloc
{
    NSLog(@"控制杆 View - dealloc");
}


- (void)setupUI{
    [self addSubview:self.moveUpBtn];
    [self addSubview:self.moveDownBtn];
    [self addSubview:self.moveLeftBtn];
    [self addSubview:self.moveRightBtn];
    [self addSubview:self.centerImgView];
    [self addSubview:self.joyStickLabel];
}


- (void)makeConstraints{
    [self.centerImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(self);
        make.width.height.equalTo(@110);
    }];
    
    [self.moveUpBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.width.equalTo(@40);
        make.height.equalTo(@30);
        make.bottom.equalTo(self.centerImgView.mas_top).offset(-15);
    }];
    
    [self.moveDownBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.width.equalTo(@40);
        make.height.equalTo(@30);
        make.top.equalTo(self.centerImgView.mas_bottom).offset(15);
    }];
    
    [self.moveLeftBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.width.equalTo(@30);
        make.height.equalTo(@40);
        make.right.equalTo(self.centerImgView.mas_left).offset(-15);
    }];
    
    [self.moveRightBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.width.equalTo(@30);
        make.height.equalTo(@40);
        make.left.equalTo(self.centerImgView.mas_right).offset(15);
    }];
    
    [self.joyStickLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self.moveDownBtn.mas_bottom).offset(20);
        make.height.equalTo(@18);
        make.width.equalTo(@80);
    }];
}


#pragma mark - Getter && Setter

- (UIButton *)moveUpBtn{
    if (!_moveUpBtn) {
        _moveUpBtn = [[UIButton alloc]init];
        [_moveUpBtn setImage:[UIImage imageNamed:@"btn_up_normal"] forState:UIControlStateNormal];
        [_moveUpBtn setImage:[UIImage imageNamed:@"btn_up_pressed"] forState:UIControlStateHighlighted];
    }
    return _moveUpBtn;
}


- (UIButton *)moveRightBtn{
    if (!_moveRightBtn) {
        _moveRightBtn = [[UIButton alloc]init];
        [_moveRightBtn setImage:[UIImage imageNamed:@"btn_right_normal"] forState:UIControlStateNormal];
        [_moveRightBtn setImage:[UIImage imageNamed:@"btn_right_pressed"] forState:UIControlStateHighlighted];
    }
    return _moveRightBtn;
}


- (UIButton *)moveLeftBtn{
    if (!_moveLeftBtn) {
        _moveLeftBtn = [[UIButton alloc]init];
        [_moveLeftBtn setImage:[UIImage imageNamed:@"btn_left_normal"] forState:UIControlStateNormal];
        [_moveLeftBtn setImage:[UIImage imageNamed:@"btn_left_pressed"] forState:UIControlStateHighlighted];
    }
    return _moveLeftBtn;
}

- (UIButton *)moveDownBtn{
    if (!_moveDownBtn) {
        _moveDownBtn = [[UIButton alloc]init];
        [_moveDownBtn setImage:[UIImage imageNamed:@"btn_down_normal"] forState:UIControlStateNormal];
        [_moveDownBtn setImage:[UIImage imageNamed:@"btn_down_pressed"] forState:UIControlStateHighlighted];
    }
    return _moveDownBtn;
}


- (UIImageView *)centerImgView{
    if (!_centerImgView) {
        _centerImgView = [[UIImageView alloc]init];
        _centerImgView.image = [UIImage imageNamed:@"btn_shaft_normal"];
    }
    return _centerImgView;
}


- (UILabel *)joyStickLabel{
    if (!_joyStickLabel) {
        _joyStickLabel = [[UILabel alloc]init];
        _joyStickLabel.font = [UIFont systemFontOfSize:14.0f];
        _joyStickLabel.textColor = [UIColor colorWithHexString:@"0x242421"];
        _joyStickLabel.text = DPLocalizedString(@"play_Joystick");
        _joyStickLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _joyStickLabel;
}



@end
