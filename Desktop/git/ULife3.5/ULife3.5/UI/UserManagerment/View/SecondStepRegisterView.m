//
//  SecondStepRegisterView.m
//  goscamapp
//
//  Created by goscam_sz on 17/5/9.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "SecondStepRegisterView.h"
#import "UITableView+FDTemplateLayoutCell.h"
#import "NSString+Common.h"
#import "SVProgressHUD.h"
#import <Masonry.h>

typedef NS_ENUM(NSInteger, FDSimulatedCacheMode) {
    FDSimulatedCacheModeNone = 0,
    FDSimulatedCacheModeCacheByIndexPath,
    FDSimulatedCacheModeCacheByKey
};

@implementation SecondStepRegisterView
{
    CGFloat cellHight;
    NSString * oldPassWord;
    NSString * newPassWord;
}

- (void)myTableViewUI
{
    self.myTableView.delegate=self;
    self.myTableView.dataSource=self;
    self.myTableView.separatorStyle=UITableViewCellSeparatorStyleNone;
    [self.myTableView registerNib:[UINib nibWithNibName:@"LoginTableViewCell" bundle:nil] forCellReuseIdentifier:@"cell"];
    [self.myTableView registerNib:[UINib nibWithNibName:@"SecondRegistrerTableViewCell" bundle:nil] forCellReuseIdentifier:@"cell2"];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self myTableViewUI];
    [self.myTableView reloadData];
    UIColor *color = [UIColor colorWithRed:114/255.0 green:112/255.0 blue:111/255.0 alpha:1.0];
    self.NextBtn.layer.cornerRadius=20;
    self.NextBtn.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [self.NextBtn setBackgroundColor:color];
    [self.NextBtn setTitle:DPLocalizedString(@"Register") forState:UIControlStateNormal];
    
    [self.NextBtn  mas_updateConstraints:^(MASConstraintMaker *make) {
         __weak typeof(self)weakSelf = self;
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        make.top.equalTo(strongSelf.myTableView.mas_bottom).offset(78.5);
        make.left.equalTo(strongSelf.mas_left).offset(30);
        make.right.equalTo(strongSelf.mas_right).offset(-30);
        make.height.mas_equalTo(40);
    }];
}





- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    _myCell   = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    _labelCell= [tableView dequeueReusableCellWithIdentifier:@"cell2"];
    _labelCell.delegate=self;
    _labelCell.fd_enforceFrameLayout = NO;
    
    if (indexPath.row==3) {
        _labelCell.selectionStyle=UITableViewCellSelectionStyleNone;
        [_labelCell refresh:DPLocalizedString(@"Foget_Format")];
        return _labelCell;
    }
    else if(indexPath.row==0){
        _myCell.headerButton.hidden=YES;
        _myCell.selectionStyle=UITableViewCellSelectionStyleNone;
        _myCell.HeaderImageView.image=[UIImage imageNamed:@"account"];
        _myCell.HeaderTextfied.text= self.account;
        _myCell.HeaderTextfied.userInteractionEnabled=NO;
//        [_myCell.HeaderTextfied addTarget:self action:@selector(ChangeOldPassWord:) forControlEvents:UIControlEventEditingChanged];
        return _myCell;
    }
    else if(indexPath.row==1){
        _myCell.headerButton.hidden=YES;
        _myCell.selectionStyle=UITableViewCellSelectionStyleNone;
        _myCell.HeaderImageView.image=[UIImage imageNamed:@"password"];
        _myCell.HeaderTextfied.placeholder=DPLocalizedString(@"login_password");
        _myCell.HeaderTextfied.secureTextEntry=YES;
        [_myCell.HeaderTextfied addTarget:self action:@selector(ChangeOldPassWord:) forControlEvents:UIControlEventEditingChanged];
        return _myCell;
    }
    else {
        _myCell.headerButton.hidden=YES;
        _myCell.selectionStyle=UITableViewCellSelectionStyleNone;
        _myCell.HeaderImageView.image=[UIImage imageNamed:@"password"];
        _myCell.HeaderTextfied.secureTextEntry=YES;
        [_myCell.HeaderTextfied addTarget:self action:@selector(ChangeNewPassWord:) forControlEvents:UIControlEventEditingChanged];
         _myCell.HeaderTextfied.placeholder=DPLocalizedString(@"login_once_again_password");
        return _myCell;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

-  (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row==0 || indexPath.row==1 || indexPath.row==2){
        return 50;
    }
    else{
        return [tableView fd_heightForCellWithIdentifier:@"cell2" configuration:^(SecondRegistrerTableViewCell *cell) {
            cell.fd_enforceFrameLayout = NO;
            [cell refresh:DPLocalizedString(@"Foget_Format")];
        }];
    }
}




- (void)refreshAccount:(NSString *)str
{
    self.account=str;
    [self.myTableView reloadData];
}

//  把密码传给上层
- (void)ChangeOldPassWord:(UITextField *)fd
{
    NSString *value = fd.text;
    if (![value isEqualToString:@""]) {
        if ([value isMetacharacter])
        {
            [SVProgressHUD showInfoWithStatus:DPLocalizedString(@"Login_have_SpecialCharacter")];
            fd.text=oldPassWord;
        }
        oldPassWord=fd.text;
    if (self.delegate && [self.delegate respondsToSelector:@selector(getOldPassWord:)]) {
        [self.delegate getOldPassWord:fd.text];
    }
    }
}

//
- (void)ChangeNewPassWord:(UITextField *)fd
{
    NSString *value = fd.text;
    if (![value isEqualToString:@""]) {
        if ([value isMetacharacter])
        {
            [SVProgressHUD showInfoWithStatus:DPLocalizedString(@"Login_have_SpecialCharacter")];
            fd.text=newPassWord;
        }
        newPassWord=fd.text;
        if (self.delegate && [self.delegate respondsToSelector:@selector(getNewPassWord:)]) {
            [self.delegate getNewPassWord:fd.text];
        }
    }
}

- (IBAction)RegisterBtn:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(RegisterNewAccount)]) {
        [self.delegate RegisterNewAccount];
    }
}
@end
