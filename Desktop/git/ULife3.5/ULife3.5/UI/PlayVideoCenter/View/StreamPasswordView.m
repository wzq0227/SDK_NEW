//
//  StreamPasswordView.m
//  ULife3.5
//
//  Created by AnDong on 2017/11/3.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "StreamPasswordView.h"
#import <Masonry.h>
#import "Header.h"

@interface StreamPasswordView ()<UITextFieldDelegate>

@property (nonatomic,strong)UIView *centerView;

@property (nonatomic,strong)UILabel *titleLabel;

@property (nonatomic,strong)UILabel *subLabel;

@property (nonatomic,strong)UIView *pswdView;

@property (nonatomic,strong)UIImageView *iconView;

@property (nonatomic,strong)UIButton *securityBtn;

@property (nonatomic,strong)UIView *lineView;

@end

@implementation StreamPasswordView

+ (instancetype)passwordView{
    StreamPasswordView *psdView = [[StreamPasswordView alloc]initWithFrame:CGRectMake(0, 64, kScreen_Width, kScreen_Height-64)];
    [psdView setUI];
    [psdView makeConstraints];
    return psdView;
}


- (void)setUI{
    self.backgroundColor = BACKCOLOR(197, 197, 197,0.7);
    [self addSubview:self.centerView];
    [self.centerView addSubview:self.titleLabel];
    [self.centerView addSubview:self.subLabel];
    [self.centerView addSubview:self.lineView];
    [self.centerView addSubview:self.pswdView];
    [self.pswdView addSubview:self.pswTf];
    [self.pswdView addSubview:self.iconView];
    [self.pswdView addSubview:self.securityBtn];
    [self.centerView addSubview:self.confirmBtn];
}

//添加约束
- (void)makeConstraints{
    [self.centerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(30);
        make.right.equalTo(self).offset(-30);
        make.top.equalTo(self).offset(36);
        make.height.equalTo(@200);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.centerView);
        make.width.equalTo(@200);
        make.top.equalTo(self.centerView).offset(5);
        make.height.equalTo(@20);
    }];
    
    [self.lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.centerView).offset(10);
        make.right.equalTo(self.centerView).offset(-10);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(10);
        make.height.equalTo(@1);
    }];
    
    [self.subLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.centerView).offset(10);
        make.right.equalTo(self.centerView).offset(-10);
        make.top.equalTo(self.lineView.mas_bottom).offset(10);
        make.height.equalTo(@40);
    }];
    
    [self.pswdView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.centerView).offset(10);
        make.right.equalTo(self.centerView).offset(-10);
        make.top.equalTo(self.subLabel.mas_bottom).offset(5);
        make.height.equalTo(@40);
    }];
    
    [self.iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.pswdView).offset(8);
        make.top.equalTo(self.pswdView).offset(8);
        make.height.width.equalTo(@24);
    }];
    
    [self.pswTf mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.pswdView).offset(32);
        make.right.equalTo(self.pswdView).offset(-30);
        make.top.bottom.equalTo(self.pswdView);
        
    }];
    
    [self.securityBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.pswdView).offset(-8);
        make.top.equalTo(self.pswdView).offset(8);
        make.height.width.equalTo(@24);
    }];
    
    [self.confirmBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.centerView);
        make.bottom.equalTo(self.centerView).offset(-20);
        make.height.equalTo(@30);
        make.width.equalTo(@100);
    }];
    
}

- (void)show{
    self.pswTf.text = @"";
    [[UIApplication sharedApplication].keyWindow addSubview:self];
}

- (void)dismiss{
    [self removeFromSuperview];
}


- (void)securityBtnClick{
    self.securityBtn.selected = !self.securityBtn.selected;
    if (self.securityBtn.selected) {
         [_securityBtn setBackgroundImage:[UIImage imageNamed:@"unshowPassword"] forState:UIControlStateNormal];
        self.pswTf.secureTextEntry = NO;
    }
    else{
        [_securityBtn setBackgroundImage:[UIImage imageNamed:@"showPassword"] forState:UIControlStateNormal];
         self.pswTf.secureTextEntry = YES;
    }
}

#pragma mark - UItextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if (textField.text.length == 0) {
        self.confirmBtn.userInteractionEnabled = NO;
    }
    else{
        self.confirmBtn.userInteractionEnabled = YES;
    }
    return YES;
}

#pragma mark - Getter

- (UIButton *)confirmBtn{
    if (!_confirmBtn) {
        _confirmBtn = [[UIButton alloc]init];
        [_confirmBtn setBackgroundColor:myColor];
        [_confirmBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _confirmBtn.layer.cornerRadius=10.f;
        _confirmBtn.layer.masksToBounds = YES;
        [_confirmBtn setTitle:DPLocalizedString(@"Foget_submit") forState:UIControlStateNormal];
    }
    return _confirmBtn;
}

- (UITextField *)pswTf{
    if (!_pswTf) {
        _pswTf = [[UITextField alloc]init];
        _pswTf.placeholder = @"Input password";
        _pswTf.secureTextEntry = YES;
    }
    return _pswTf;
}

- (UIView *)centerView{
    if (!_centerView) {
        _centerView = [[UIView alloc]init];
        _centerView.backgroundColor = [UIColor whiteColor];
        _centerView.layer.masksToBounds = YES;
        _centerView.layer.cornerRadius = 10.0f;
    }
    return _centerView;
}

- (UIView *)lineView{
    if (!_lineView) {
        _lineView = [[UIView alloc]init];
        _lineView.backgroundColor = BACKCOLOR(197, 197,197, 1.0);
    }
    return _lineView;
}



- (UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.textColor = [UIColor blackColor];
        _titleLabel.text = DPLocalizedString(@"DevicePasswordConfirm");
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    return _titleLabel;
}

- (UILabel *)subLabel{
    if (!_subLabel) {
        _subLabel = [[UILabel alloc]init];
        _subLabel.textColor = [UIColor blackColor];
        _subLabel.textAlignment = NSTextAlignmentCenter;
        _subLabel.text = DPLocalizedString(@"DevicePasswordConfirmTitle");
        _subLabel.numberOfLines = 0;
        _subLabel.font = [UIFont systemFontOfSize:14.0f];
    }
    return _subLabel;
}

- (UIView *)pswdView{
    if (!_pswdView) {
        _pswdView = [[UIView alloc]init];
        _pswdView.layer.cornerRadius = 5.0f;
        _pswdView.layer.masksToBounds = YES;
        _pswdView.layer.borderColor = BACKCOLOR(197, 197, 197, 1.0f).CGColor;
        _pswdView.layer.borderWidth = 1.0f;
    }
    return _pswdView;
}

- (UIImageView *)iconView{
    if (!_iconView) {
        _iconView = [[UIImageView alloc]init];
        _iconView.image = [UIImage imageNamed:@"password"];
    }
    return _iconView;
}

- (UIButton *)securityBtn{
    if (!_securityBtn) {
        _securityBtn = [[UIButton alloc]init];
        [_securityBtn setBackgroundImage:[UIImage imageNamed:@"showPassword"] forState:UIControlStateNormal];
        [_securityBtn addTarget:self action:@selector(securityBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _securityBtn;
}

@end
