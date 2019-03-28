//
//  ChangPwdView.m
//  ULife3.5
//
//  Created by goscam_sz on 2017/6/14.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "ChangPwdView.h"
#import "UITableView+FDTemplateLayoutCell.h"
#import "NSString+Common.h"
#import "SVProgressHUD.h"
#import <Masonry.h>
#import "Header.h"


typedef NS_ENUM(NSInteger, FDSimulatedCacheMode) {
    FDSimulatedCacheModeNone = 0,
    FDSimulatedCacheModeCacheByIndexPath,
    FDSimulatedCacheModeCacheByKey
};

@implementation ChangPwdView

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
    self.NextBtn.layer.cornerRadius=20;
    self.NextBtn.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [self.NextBtn setBackgroundColor:myColor];
    [self.NextBtn setTitle:DPLocalizedString(@"Title_Save") forState:UIControlStateNormal];
    
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
        _labelCell.fd_enforceFrameLayout = NO;
        return _labelCell;
    }
    else if(indexPath.row==0){
        _myCell.headerButton.hidden=YES;
        _myCell.selectionStyle=UITableViewCellSelectionStyleNone;
        _myCell.HeaderImageView.image=[UIImage imageNamed:@"password"];
        _myCell.HeaderTextfied.placeholder=DPLocalizedString(@"ChangePWD_EnterOldPwd");
        _myCell.HeaderTextfied.secureTextEntry=YES;
      [_myCell.HeaderTextfied addTarget:self action:@selector(ChangeOldPassWord:) forControlEvents:UIControlEventEditingChanged];
        return _myCell;
    }
    else if(indexPath.row==1){
        _myCell.headerButton.hidden=YES;
        _myCell.selectionStyle=UITableViewCellSelectionStyleNone;
        _myCell.HeaderImageView.image=[UIImage imageNamed:@"password"];
        _myCell.HeaderTextfied.placeholder=DPLocalizedString(@"ChangePWD_EnterNewPwd");
         _myCell.HeaderTextfied.secureTextEntry=YES;
        [_myCell.HeaderTextfied addTarget:self action:@selector(ChangeFristNewPassWord:) forControlEvents:UIControlEventEditingChanged];
        return _myCell;
    }
    else {
        _myCell.headerButton.hidden=YES;
        _myCell.selectionStyle=UITableViewCellSelectionStyleNone;
        _myCell.HeaderImageView.image=[UIImage imageNamed:@"password"];
        [_myCell.HeaderTextfied addTarget:self action:@selector(ChangeSecondNewPassWord:) forControlEvents:UIControlEventEditingChanged];
        _myCell.HeaderTextfied.placeholder=DPLocalizedString(@"ChangePWD_EnterNewPwdAgain");
         _myCell.HeaderTextfied.secureTextEntry=YES;
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
    else {
        return [tableView fd_heightForCellWithIdentifier:@"cell2" configuration:^(SecondRegistrerTableViewCell *cell) {
            cell.fd_enforceFrameLayout = NO;
            [cell refresh:DPLocalizedString(@"Foget_Format") ];
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
            [SVProgressHUD showInfoWithStatus:DPLocalizedString(@"ChangePWD_HaveSpecialCharacter")];
            fd.text=oldPassWord;
        }
        oldPassWord=fd.text;
        if (self.delegate && [self.delegate respondsToSelector:@selector(getOldPassWord:)]) {
            [self.delegate getOldPassWord:fd.text];
        }
    }
}

//
- (void)ChangeFristNewPassWord:(UITextField *)fd
{
    NSString *value = fd.text;
    if (![value isEqualToString:@""]) {
        if ([value isMetacharacter])
        {
            [SVProgressHUD showInfoWithStatus:DPLocalizedString(@"ChangePWD_HaveSpecialCharacter")];
            fd.text=newPassWord;
        }
        newPassWord=fd.text;
        if (self.delegate && [self.delegate respondsToSelector:@selector(getFristNewPassWord:)]) {
            [self.delegate getFristNewPassWord:fd.text];
        }
    }
}

- (void)ChangeSecondNewPassWord:(UITextField *)fd
{
    NSString *value = fd.text;
    if (![value isEqualToString:@""]) {
        if ([value isMetacharacter])
        {
            [SVProgressHUD showInfoWithStatus:DPLocalizedString(@"ChangePWD_HaveSpecialCharacter")];
            fd.text=newPassWord;
        }
        newPassWord=fd.text;
        if (self.delegate && [self.delegate respondsToSelector:@selector(getSecondNewPassWord:)]) {
            [self.delegate getSecondNewPassWord:fd.text];
        }
    }
}

- (IBAction)RegisterBtn:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(SveNewPassword)]) {
        [self.delegate SveNewPassword];
    }
}
@end
