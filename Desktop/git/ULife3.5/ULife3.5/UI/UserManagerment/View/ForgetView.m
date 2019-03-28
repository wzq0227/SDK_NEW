//
//  ForgetView.m
//  ULife3.5
//
//  Created by goscam_sz on 2017/6/2.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "ForgetView.h"
#import "UITableView+FDTemplateLayoutCell.h"
#import <Masonry.h>
#import "SaveDataModel.h"
#import "NSString+Common.h"
#import "iRouterInterface.h"
#import "CBSCommand.h"
#import "UIColor+YYAdd.h"
#import "Header.h"
#import "CMSCommand.h"

@interface ForgetView()<UITextFieldDelegate>

@property (nonatomic, strong)  UIButton *getCodeBtn;

@property (nonatomic, strong)  NSTimer *countDownTimer;

@property (nonatomic, assign)  NSInteger repeatCount;

@end

@implementation ForgetView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
{
    int count;
}


-(void)awakeFromNib
{
    [super awakeFromNib];
    
    count=1;
    _netSDK = [NetSDK sharedInstance];
    [self myForgetView];
    [self setUI];
}

-(void)myForgetView
{
    [self.myForgetTableView registerNib:[UINib nibWithNibName:@"LoginTableViewCell" bundle:nil ] forCellReuseIdentifier:@"cell"];
    [self.myForgetTableView registerNib:[UINib nibWithNibName:@"SecondRegistrerTableViewCell" bundle:nil] forCellReuseIdentifier:@"cell2"];
    _myForgetTableView.separatorStyle=UITableViewCellSeparatorStyleNone;
    _myForgetTableView.delegate=self;
    _myForgetTableView.dataSource=self;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row==4) {
        return [tableView fd_heightForCellWithIdentifier:@"cell2" configuration:^(SecondRegistrerTableViewCell *cell) {
            cell.fd_enforceFrameLayout = NO;
            [cell refresh:DPLocalizedString(@"Foget_Format")];
        }];
    }
    else{
        return 50;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    _myForgetCell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    _labelCell    = [tableView dequeueReusableCellWithIdentifier:@"cell2"];
    _labelCell.fd_enforceFrameLayout = NO; 
    if (indexPath.row==4) {
        _labelCell.selectionStyle=UITableViewCellSelectionStyleNone;
        [_labelCell refresh:DPLocalizedString(@"Foget_Format")];
        return _labelCell;
    }
    else if(indexPath.row==0){
        _myForgetCell.headerButton.hidden=YES;
        _myForgetCell.selectionStyle=UITableViewCellSelectionStyleNone;
        _myForgetCell.HeaderImageView.image=[UIImage imageNamed:@"account"];
        _myForgetCell.HeaderTextfied.placeholder=DPLocalizedString(@"Foget_acount");
        _myForgetCell.HeaderTextfied.font = [UIFont systemFontOfSize:11];

        [_myForgetCell.HeaderTextfied addTarget:self action:@selector(changeAcount:) forControlEvents:UIControlEventEditingChanged];
        
        _myForgetCell.txtTrailingToContainer.constant = 132;

        UIButton * btn = [UIButton new];
        [btn setTitle:DPLocalizedString(@"Foget_get_the_verification_code") forState:UIControlStateNormal];
        
        [btn.titleLabel setNumberOfLines:0];
        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        btn.titleLabel.font = [UIFont systemFontOfSize:12];
        [btn setBackgroundImage:[UIImage imageNamed:@"Register_GetVerifyCodeBg"] forState:0];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(getCode) forControlEvents:UIControlEventTouchUpInside];
        [_myForgetCell.contentView addSubview:btn];
        __weak typeof(self)weakSelf = self;
        [btn mas_updateConstraints:^(MASConstraintMaker *make) {
            
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                return ;
            }
            make.bottom.equalTo(strongSelf.myForgetCell.contentView.mas_bottom).offset(-5);
            
            make.right.equalTo(strongSelf.myForgetCell.contentView.mas_right).offset(-30);
            make.height.mas_equalTo(30);
            make.width.mas_equalTo(100);
        }];
        
        _getCodeBtn = btn;
        
        return _myForgetCell;
        
    }
    else if(indexPath.row==1){
        _myForgetCell.headerButton.hidden=YES;
        _myForgetCell.selectionStyle=UITableViewCellSelectionStyleNone;
        _myForgetCell.HeaderImageView.image=[UIImage imageNamed:@"forget_verifyCode_icon"];
        _myForgetCell.HeaderTextfied.placeholder=DPLocalizedString(@"Foget_verification_code");
        _myForgetCell.HeaderTextfied.font = [UIFont systemFontOfSize:11];

        _myForgetCell.HeaderTextfied.delegate = self;
        [_myForgetCell.HeaderTextfied addTarget:self action:@selector(changeEamilVerificationcode:) forControlEvents:UIControlEventEditingChanged];
        return _myForgetCell;
    }
    else if(indexPath.row==2){
        _myForgetCell.headerButton.hidden=YES;
        _myForgetCell.selectionStyle=UITableViewCellSelectionStyleNone;
        _myForgetCell.HeaderImageView.image=[UIImage imageNamed:@"password"];
        
        _myForgetCell.HeaderTextfied.secureTextEntry = YES;
        _myForgetCell.HeaderTextfied.placeholder=DPLocalizedString(@"Foget_new_password");
        _myForgetCell.HeaderTextfied.font = [UIFont systemFontOfSize:11];

        _myForgetCell.HeaderTextfied.secureTextEntry = YES;
        [_myForgetCell.HeaderTextfied addTarget:self action:@selector(ChangeNewPassWord:) forControlEvents:UIControlEventEditingChanged];
        return _myForgetCell;
    }
    else{
        _myForgetCell.headerButton.hidden=YES;
        _myForgetCell.selectionStyle=UITableViewCellSelectionStyleNone;
        _myForgetCell.HeaderImageView.image=[UIImage imageNamed:@"password"];
        
        _myForgetCell.HeaderTextfied.secureTextEntry = YES;
        _myForgetCell.HeaderTextfied.placeholder=DPLocalizedString(@"Foget_enter_new_password");
        _myForgetCell.HeaderTextfied.font = [UIFont systemFontOfSize:11];
        _myForgetCell.HeaderTextfied.secureTextEntry = YES;
        [_myForgetCell.HeaderTextfied addTarget:self action:@selector(ChangeSecondPassWord:) forControlEvents:UIControlEventEditingChanged];
        return _myForgetCell;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if ([textField.placeholder isEqualToString:DPLocalizedString(@"Foget_verification_code")]) {
        NSInteger strLength = textField.text.length - range.length + string.length;
        return (strLength <= 6);
    }
    return true;
}

- (void)setUI
{
    self.helpLabel.hidden=YES;
    [self.NextBtn setBackgroundColor:myColor];
    [self.NextBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.NextBtn.layer.cornerRadius=20.f;
    [self.NextBtn setTitle:DPLocalizedString(@"Foget_submit") forState:UIControlStateNormal];
    [self.NextBtn addTarget:self action:@selector(next) forControlEvents:UIControlEventTouchUpInside];
    self.NextBtn.userInteractionEnabled = NO;
}

- (void)configNextBtn{
    self.NextBtn.userInteractionEnabled = _acount.length>0 && _Verificationcode.length>0 && _FristPwd.length>0 && _SecondPwd.length>0;
}

#pragma mark 账号框值改变
- (void)changeAcount:(UITextField *)field
{
    self.acount = field.text;
    [self configNextBtn];
    NSLog(@"账号 :%@ ",self.acount );
}

#pragma mark 邮箱框值改变
- (void)changeEamilVerificationcode:(UITextField *)field
{
    self.Verificationcode = field.text;
    [self configNextBtn];
    NSLog(@"验证码 :%@",self.Verificationcode);
}

#pragma mark 新密码框改变
- (void)ChangeNewPassWord:(UITextField *)field
{
    self.FristPwd = field.text;
    [self configNextBtn];
    NSLog(@"新密码 :%@",self.FristPwd);
}

#pragma mark 第二输入密码框值改变
- (void)ChangeSecondPassWord:(UITextField *)field
{
    self.SecondPwd = field.text;
    [self configNextBtn];
    NSLog(@"第二次确认密码 :%@",self.SecondPwd);
}

#pragma mark 点击获取验证码按钮
- (void)getCode
{
    count=1;
    if ([_acount isAccountValid ]) {
        
        NSString *str = [_acount isEmail]?[NSString stringWithFormat:DPLocalizedString(@"Foget_find_verification_code_emil"),self.acount]:[NSString stringWithFormat:DPLocalizedString(@"Foget_find_verification_code_iphone"),self.acount];
         self.helpLabel.text = str;
        ServerAddress *upsAddr = [ServerAddress yy_modelWithDictionary:[mUserDefaults objectForKey:kCGSA_ADDRESS]];
        if (upsAddr) {
            //存在这个就存在加密key
            NSString *criptKey = [mUserDefaults objectForKey:@"CryptKey"];
            [_netSDK setcriptKey:criptKey];
            //连接
            [self getVerificationcodeToCBSWithIP:upsAddr.Address port:upsAddr.Port];
        }else{
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                [self getCBS_PORT];
            });
        }
        
    }
    else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Foget_Format_erro")];
        });
    }
}


- (void)getCBS_PORT
{
    NSString *ipconfig;
    
    if(isENVersion)
    {
        ipconfig = enCBS_IP;
    }
    else
    {
        ipconfig = kCBS_IP;
    }
    
    CMD_AppGetBSAddressRequest *req = [CMD_AppGetBSAddressRequest new];
    req.UserName = @"";
    req.Password = @"";
    req.ServerType = @[@2,@3,@4];
    //    __weak LoginViewFristController * weakself = self;
    //@"120.24.84.182"
    [_netSDK net_getCBSPortWithIP:ipconfig port:6001 data:[req requestCMDData] responseBlock:^(int result, NSDictionary *dict) {
        NSString *criptkey = dict[@"CryptKey"];
        [mUserDefaults setObject:criptkey forKey:@"CryptKey"];
        [_netSDK setcriptKey:criptkey];
        if (result ==0) {
            NSArray *serverList = dict[@"ServerList"];
            if( serverList.count >0 && serverList.count<5){
            }
            for (NSDictionary *addressDict in serverList) {
                ServerAddress *serverAddr = [ServerAddress yy_modelWithDictionary:addressDict];
                switch (serverAddr.Type) {
                    case 2:
                        [mUserDefaults setObject:addressDict forKey:@"MPSAddress"];
                        break;
                    case 3:
                        [mUserDefaults setObject:addressDict forKey:kCGSA_ADDRESS];
                        [self.netSDK setCBSAddress:addressDict[@"Address"] port:[addressDict[@"Port"] intValue]];
                        break;
                    case 4:
                    {
                        [mUserDefaults setObject:addressDict forKey:@"UPSAddress"];
                        break;
                    }
                        
                    default:
                        break;
                }
            }
            
            [mUserDefaults synchronize];
            ServerAddress *upsAddr = [ServerAddress yy_modelWithDictionary:[mUserDefaults objectForKey:kCGSA_ADDRESS]];
            if (upsAddr) {
                
                //连接
                [self getVerificationcodeToCBSWithIP:upsAddr.Address port:upsAddr.Port];
            }
        }else{
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"localizied_294")];
        }
    }];
}


#pragma mark 在CBS获取验证码
- (void)getVerificationcodeToCBSWithIP:(NSString*)ip port:(int)port
{
    __weak typeof(self) weakSelf = self;
    BodyGetVerifyCodePwdRequest *body = [BodyGetVerifyCodePwdRequest new];
    body.FindPasswordType = [_acount isEmail]?2:3;
    body.UserInfo = _acount;
    body.UserType = 9;
    body.VerifyWay = 2;
    CMD_GetVerifyCodeRequest *req = [CMD_GetVerifyCodeRequest new];
    req.Body = body;
    NSData *reqData = [NSJSONSerialization dataWithJSONObject:[req requestCMDData] options:0 error:nil];
    
    __weak typeof(self) wSelf = self;
    [_netSDK net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        
        count=0;
        if (result==0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                wSelf.getCodeBtn.userInteractionEnabled = NO;
                
                [wSelf.countDownTimer setFireDate:[NSDate distantPast]];

                self.helpLabel.hidden=NO;
                [SVProgressHUD showSuccessWithStatus:DPLocalizedString(body.FindPasswordType==3?@"Foget_verification_code_iphone_success":@"Foget_verification_code_emil_success")];
                [weakSelf.netSDK net_closeCBSConnect];
                [SaveDataModel SaveCBSNetWorkState:NO];
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (result == IROUTER_RECORD_NOT_EXIST) {//查询记录不存在
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Register_account_not_exist_error")];
                }else{
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Foget_send_unsuccess")];
                }
                self.helpLabel.hidden = YES;
            });
        }
    }];
}

#pragma mark 代理回调
- (void)next
{
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(findPasswordAcount:Verificationcode:FristPwd:Secondpwd:)])
    {
        [self.delegate findPasswordAcount:_acount Verificationcode:_Verificationcode FristPwd:_FristPwd Secondpwd:_SecondPwd];
    }
}

- (void)countDownTimerFunc:(id)sender{
    
    _repeatCount++;
    
    [_getCodeBtn setTitle:_repeatCount>=60?DPLocalizedString(@"Foget_get_the_verification_code"):[NSString stringWithFormat:MLocalizedString(GetCode_CountDown_60S), 60-_repeatCount]  forState:0 ];
    
    if (_repeatCount == 60 && [_countDownTimer isValid]) {
        [_countDownTimer invalidate];
        _countDownTimer = nil;
        
        _repeatCount = 0;
        self.getCodeBtn.userInteractionEnabled = YES;
        [self.getCodeBtn setBackgroundColor:myColor];
    }
}

- (void)invalidateTimers{
    if ( [_countDownTimer isValid]) {
        [_countDownTimer invalidate];
        _countDownTimer = nil;
    }
}


//MARK: - getters
- (NSTimer*)countDownTimer{
    if (!_countDownTimer) {
        _countDownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(countDownTimerFunc:) userInfo:nil repeats:YES];
        [_countDownTimer setFireDate:[NSDate distantFuture]];
    }
    return _countDownTimer;
}
@end
