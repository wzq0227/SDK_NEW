//
//  LoginView.m
//  gaoscam
//
//  Created by goscam_sz on 17/4/19.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "LoginView.h"
#import "NSString+Common.h"
#import "SVProgressHUD.h"
#import "TPKeyboardAvoidingTableView.h"
#import "SaveDataModel.h"
#import <Masonry.h>
#import "UIColor+YYAdd.h"

@interface LoginView ()

@property(nonatomic,copy) NSString * AcountString;

@property(nonatomic,copy) NSString * PasswordString;

@property(nonatomic,assign) BOOL isRemember;

@end

@implementation LoginView







-(UIView *)footerView
{
    if (nil == _footerView)
    {
        UIColor *color = [UIColor clearColor];
        _footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 240)];
        [_footerView setBackgroundColor:color];
        [_footerView addSubview:self.deleteBtn];
        [_footerView addSubview:self.forgetBtn];
        [_footerView addSubview:self.changeVersionBtn];
        __weak typeof(self)weakSelf = self;
        CGFloat height =40;
    
        
        [self.deleteBtn mas_updateConstraints:^(MASConstraintMaker *make) {
            
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                return ;
            }
            make.top.equalTo(strongSelf.footerView.mas_top).offset(60);
            make.left.equalTo(strongSelf.footerView.mas_left).offset(30);
            make.right.equalTo(strongSelf.footerView.mas_right).offset(-30);
            make.height.mas_equalTo(height);
        }];

     
  
        
        [self.forgetBtn mas_updateConstraints:^(MASConstraintMaker *make) {
            
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                return ;
            }
            make.top.equalTo(strongSelf.deleteBtn.mas_bottom).offset(21);
            make.centerX.equalTo(strongSelf.footerView);
            make.width.mas_equalTo(150);
//            make.left.equalTo(strongSelf.footerView.mas_left).offset(142.5);
//            make.right.equalTo(strongSelf.footerView.mas_right).offset(-142.5);
            make.height.mas_equalTo(height);
        }];

        [self.changeVersionBtn mas_updateConstraints:^(MASConstraintMaker *make) {
            
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                return ;
            }
            make.bottom.equalTo(strongSelf.footerView.mas_bottom).offset((SCREEN_WIDTH<321)?-30: -20);
            make.centerX.equalTo(strongSelf.footerView);
            make.width.mas_equalTo(250);
            make.height.mas_equalTo(height);
        }];
    }
    return _footerView;
}



-(void)awakeFromNib
{
    [super awakeFromNib];
    [self.myTableView registerNib:[UINib nibWithNibName:@"LoginTableViewCell" bundle:nil ] forCellReuseIdentifier:@"cell"];
    [self.myTableView registerNib:[UINib nibWithNibName:@"RegisterTableViewCell" bundle:nil ] forCellReuseIdentifier:@"cell2"];
    _myTableView.separatorStyle=UITableViewCellSeparatorStyleNone;
    _myTableView.tableFooterView = self.footerView;
    _myTableView.delegate=self;
    _myTableView.dataSource=self;
}



-(UIButton *)deleteBtn
{
    if (nil == _deleteBtn)
    {
        UIColor *color = [UIColor colorWithRed:171/255.0 green:229/255.0 blue:236/255.0 alpha:1.0];
        CGFloat btnHeight = 40.0f;
        CGFloat fontSize = 18.0f;
        CGFloat cornerRadiusSize = 20.0f;
        _deleteBtn = [[UIButton alloc]init];
//        _deleteBtn = [[UIButton alloc] initWithFrame:CGRectMake(30, 74, SCREEN_WIDTH/360.0*300, 40)];
        [_deleteBtn setTitle:DPLocalizedString(@"Register_login")forState:UIControlStateNormal];
        _deleteBtn.titleLabel.font = [UIFont systemFontOfSize:fontSize];
        _deleteBtn.layer.cornerRadius = cornerRadiusSize;
        [_deleteBtn setBackgroundColor:color];
    }
    return _deleteBtn;
}



-(UIButton *)forgetBtn
{
    if (nil == _forgetBtn)
    {
        CGFloat btnHeight = 40.0f;
        CGFloat fontSize = 14.0f;
        CGFloat cornerRadiusSize = 20.0f;
        
        _forgetBtn = [[UIButton alloc] init];
        [_forgetBtn setTitle:DPLocalizedString(@"Foget_password")forState:UIControlStateNormal];
        [_forgetBtn setTitleColor:myColor forState:UIControlStateNormal];
        _forgetBtn.titleLabel.font = [UIFont systemFontOfSize:fontSize];
        _forgetBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        _forgetBtn.layer.cornerRadius = cornerRadiusSize;
    }
    return _forgetBtn;
}

//changeVersionBtn
-(UIButton *)changeVersionBtn
{
    if (nil == _changeVersionBtn)
    {
        CGFloat fontSize = 14.0f;

        _changeVersionBtn = [[UIButton alloc] init];
        
        _changeVersionBtn.hidden = isENVersion;//
        [_changeVersionBtn setTitle:[self changeVersionTitleStr] forState:UIControlStateNormal];
        [_changeVersionBtn setTitleColor:myColor forState:UIControlStateNormal];
        _changeVersionBtn.titleLabel.font = [UIFont systemFontOfSize:fontSize];
        _changeVersionBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _changeVersionBtn;
}

//系统语言为中文则加个切换按钮，系统为英文则不改变
- (NSString *)changeVersionTitleStr{
    UserChosenVersion chosenVersion = [mUserDefaults integerForKey:mUserChosenVersion];
    NSString *changeVersionTitle = nil;
    
//    if (isENVersion) {
//
//        switch (chosenVersion) {
//            case UserChosenVersionDomestic:
//            {
//                changeVersionTitle = DPLocalizedString(@"APDoorbell_VersionOverseas");
//                break;
//            }
//            case UserChosenVersionOverseas:
//            {
//                changeVersionTitle = DPLocalizedString(@"APDoorbell_VersionDomestic");
//                break;
//            }
//            default:
//                changeVersionTitle = DPLocalizedString(@"APDoorbell_VersionDomestic");
//                break;
//        }
//    }else
    {
        
        switch (chosenVersion) {
            case UserChosenVersionDomestic:
            {
                changeVersionTitle = DPLocalizedString(@"APDoorbell_VersionOverseas");
                break;
            }
            case UserChosenVersionOverseas:
            {
                changeVersionTitle = DPLocalizedString(@"APDoorbell_VersionDomestic");
                break;
            }
            default:
                changeVersionTitle = DPLocalizedString(@"APDoorbell_VersionOverseas");
                break;
        }
    }
    return changeVersionTitle;
}

- (void)refreshTitles{
    
    [_forgetBtn setTitle:DPLocalizedString(@"Foget_password")forState:UIControlStateNormal];
    [_deleteBtn setTitle:DPLocalizedString(@"Register_login")forState:UIControlStateNormal];
    [_changeVersionBtn setTitle:[self changeVersionTitleStr] forState:UIControlStateNormal];

    [self.myTableView reloadData];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    __block LoginView *blockSelf = self;
    
    _mycell.selectionStyle=UITableViewCellSelectionStyleNone;
    
    if (indexPath.row==0 || indexPath.row==1) {
        _mycell=[tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
        _mycell.selectionStyle=UITableViewCellSelectionStyleNone;
        if (indexPath.row==0) {
            _mycell.HeaderImageView.image=[UIImage imageNamed:@"account"];
            _mycell.HeaderTextfied.placeholder=DPLocalizedString(@"Foget_Email");
            _mycell.headerButton.hidden=YES;
            [_mycell.HeaderTextfied addTarget:self action:@selector(changeAcount:) forControlEvents:UIControlEventEditingChanged];
            
            NSString * str= [SaveDataModel getUserName];
            if (str!=nil) {
                _mycell.HeaderTextfied.text = str;
                if (self.delegate
                    && [self.delegate respondsToSelector:@selector(loginAcount:)])
                {
                    [self.delegate loginAcount:_mycell.HeaderTextfied.text];
                }
            }
            else{
                _mycell.HeaderTextfied.text =@"";
            }
        }
        if (indexPath.row==1) {
            
            _mycell.HeaderImageView.image=[UIImage imageNamed:@"password"];
            _mycell.HeaderTextfied.placeholder=DPLocalizedString(@"login_password");
            _mycell.headerButton.hidden=NO;
            _mycell.HeaderTextfied.secureTextEntry=YES;
            
            [_mycell.HeaderTextfied addTarget:self action:@selector(changePassword:) forControlEvents:UIControlEventEditingChanged];
           
            self.PasswordString=[SaveDataModel isGetUserPassword];
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(loginPassword:)])
            {
                [self.delegate loginPassword:self.PasswordString];
            }

            _mycell.HeaderTextfied.text=self.PasswordString;
            _mycell.mycellPasswordBlock=^(BOOL isaction){
                blockSelf->_mycell.HeaderTextfied.secureTextEntry=isaction;
            };
        }
        return _mycell;
    }
    else{
        _registecCell=[tableView dequeueReusableCellWithIdentifier:@"cell2" forIndexPath:indexPath];
        _registecCell.selectionStyle=UITableViewCellSelectionStyleNone;
        
#pragma mark - 去掉注册
        _registecCell.registerBtn.hidden = YES;
        [_registecCell.registerBtn setTitle:DPLocalizedString(@"Register") forState:0];
        _registecCell.rememberPwdLabel.text = DPLocalizedString(@"Login_RememberPwd");
        [_registecCell.registerBtn addTarget:self action:@selector(registerAcount) forControlEvents:UIControlEventTouchUpInside];
        [_registecCell.passWordBtn addTarget:self action:@selector(rememberPassword:) forControlEvents:UIControlEventTouchUpInside];
        
        
        NSString * str = [SaveDataModel isGetUserPassword];
        if (str==nil) {
            [_registecCell.passWordBtn setImage:[UIImage imageNamed:@"unRememberPassword"] forState:UIControlStateNormal];
        }
        else{
            [_registecCell.passWordBtn setImage:[UIImage imageNamed:@"rememberPassword"] forState:UIControlStateNormal];
            [SaveDataModel isSaveUsername:YES];
        }
        return _registecCell;
    }
}

-(void)rememberPassword:(UIButton *)btn
{
    if (!_isRemember) {
        [btn setImage:[UIImage imageNamed:@"rememberPassword"] forState:UIControlStateNormal];
        [SaveDataModel isSaveUsername:YES];
    }
    else{
        [btn setImage:[UIImage imageNamed:@"unRememberPassword"] forState:UIControlStateNormal];
        [SaveDataModel isSaveUsername:NO];
    }
    _isRemember=!_isRemember;
}

-(void)changeAcount:(UITextField *)field
{
    NSString *value = field.text;
//    if (![value isEqualToString:@""]) {
        self.AcountString=field.text;
        
        if (self.delegate
            && [self.delegate respondsToSelector:@selector(loginAcount:)])
        {
            [self.delegate loginAcount:_AcountString];
        }
        
//    }
//    NSLog(@"账号:%@",field.text);
}

-(void)changePassword:(UITextField *)field
{
//    NSLog(@"密码:%@",field.text);
    NSString *value = field.text;

    if ( ![value isEqualToString:@""] && [value isMetacharacter])
    {
        [SVProgressHUD showInfoWithStatus:DPLocalizedString(@"Login_have_SpecialCharacter")];
        field.text=self.PasswordString;
    }
    self.PasswordString=field.text;
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(loginPassword:)])
    {
        [self.delegate loginPassword:self.PasswordString];
    }
//    NSLog(@"账号:%@",field.text);
}

-(void)registerAcount
{
    [self pushReisterView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row==2) {
        return 50;
    }
    else{
        return 50;
    }
}

-(void)pushReisterView
{
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(startReister)])
    {
        [self.delegate startReister];
    }
}


@end
