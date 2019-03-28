//
//  RegisterView.m
//  goscamapp
//
//  Created by goscam_sz on 17/5/8.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "RegisterView.h"
#import "UITableView+FDTemplateLayoutCell.h"
#import <Masonry.h>
#import "SaveDataModel.h"
#import "NSString+Common.h"
#import "CBSCommand.h"
#import "iRouterInterface.h"
#import "UIColor+YYAdd.h"
#import "CMSCommand.h"

@interface RegisterView()<UITextFieldDelegate>

@property (nonatomic, strong)  UIButton *getCodeBtn;

@property (nonatomic, strong)  NSTimer *countDownTimer;

@property (nonatomic, assign)  NSInteger repeatCount;

@end

@implementation RegisterView
int count;

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    UIColor *color = myColor;
    _NextButon.layer.cornerRadius=20;
    [_NextButon setBackgroundColor:color];
    
    count=1;
    _netSDK = [NetSDK sharedInstance];
    
    [self mytableView];
    [self setUI];

}

- (void)mytableView
{
    [self.myRegisterTableView registerNib:[UINib nibWithNibName:@"LoginTableViewCell" bundle:nil ] forCellReuseIdentifier:@"cell"];
    [self.myRegisterTableView registerNib:[UINib nibWithNibName:@"SecondRegistrerTableViewCell" bundle:nil ] forCellReuseIdentifier:@"cell2"];

    _myRegisterTableView.separatorStyle=UITableViewCellSeparatorStyleNone;
    _myRegisterTableView.delegate=self;
    _myRegisterTableView.dataSource=self;
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
    _myRegisterCell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    _labelCell    = [tableView dequeueReusableCellWithIdentifier:@"cell2"];
    _labelCell.fd_enforceFrameLayout = NO;
    if (indexPath.row==4) {
        _labelCell.selectionStyle=UITableViewCellSelectionStyleNone;
        [_labelCell refresh:DPLocalizedString(@"Foget_Format")];
        return _labelCell;
    }
    else if(indexPath.row==0){
        _myRegisterCell.headerButton.hidden=YES;
        _myRegisterCell.selectionStyle=UITableViewCellSelectionStyleNone;
        _myRegisterCell.HeaderImageView.image=[UIImage imageNamed:@"account"];
        _myRegisterCell.HeaderTextfied.placeholder=DPLocalizedString(@"Foget_acount");
        _myRegisterCell.HeaderTextfied.font = [UIFont systemFontOfSize:11];

        [_myRegisterCell.HeaderTextfied addTarget:self action:@selector(changeAcount:) forControlEvents:UIControlEventEditingChanged];
        
        _myRegisterCell.txtTrailingToContainer.constant = 132;
        
        UIButton * btn = [UIButton new];
        [btn setTitle:DPLocalizedString(@"Foget_get_the_verification_code") forState:UIControlStateNormal];
        
        [btn.titleLabel setNumberOfLines:0];
        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        btn.titleLabel.font = [UIFont systemFontOfSize:12];
        [btn setBackgroundImage:[UIImage imageNamed:@"Register_GetVerifyCodeBg"] forState:0];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(getCode) forControlEvents:UIControlEventTouchUpInside];
        [_myRegisterCell.contentView addSubview:btn];
        __weak typeof(self)weakSelf = self;
        [btn mas_updateConstraints:^(MASConstraintMaker *make) {
            
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                return ;
            }
            make.bottom.equalTo(strongSelf.myRegisterCell.contentView.mas_bottom).offset(-5);
            
            make.right.equalTo(strongSelf.myRegisterCell.contentView.mas_right).offset(-30);
            make.height.mas_equalTo(30);
            make.width.mas_equalTo(100);
        }];
        
        _getCodeBtn = btn;
        
        return _myRegisterCell;
        
    }
    else if(indexPath.row==1){
        _myRegisterCell.headerButton.hidden=YES;
        _myRegisterCell.selectionStyle=UITableViewCellSelectionStyleNone;
        _myRegisterCell.HeaderImageView.image=[UIImage imageNamed:@"forget_verifyCode_icon"];
        _myRegisterCell.HeaderTextfied.placeholder=DPLocalizedString(@"Foget_verification_code");
        _myRegisterCell.HeaderTextfied.font = [UIFont systemFontOfSize:11];

        _myRegisterCell.HeaderTextfied.delegate = self;
        [_myRegisterCell.HeaderTextfied addTarget:self action:@selector(changeEamilVerificationcode:) forControlEvents:UIControlEventEditingChanged];
        return _myRegisterCell;
    }
    else if(indexPath.row==2){
        _myRegisterCell.headerButton.hidden=YES;
        _myRegisterCell.selectionStyle=UITableViewCellSelectionStyleNone;
        _myRegisterCell.HeaderImageView.image=[UIImage imageNamed:@"password"];
        
        _myRegisterCell.HeaderTextfied.secureTextEntry=YES;
        _myRegisterCell.HeaderTextfied.placeholder=DPLocalizedString(@"Foget_Please_enter_the_password");
        _myRegisterCell.HeaderTextfied.font = [UIFont systemFontOfSize:11];

        [_myRegisterCell.HeaderTextfied addTarget:self action:@selector(ChangeNewPassWord:) forControlEvents:UIControlEventEditingChanged];
        _myRegisterCell.HeaderTextfied.secureTextEntry = YES;
        return _myRegisterCell;
    }
    else{
        _myRegisterCell.headerButton.hidden=YES;
        _myRegisterCell.selectionStyle=UITableViewCellSelectionStyleNone;
        _myRegisterCell.HeaderImageView.image=[UIImage imageNamed:@"password"];
        
        _myRegisterCell.HeaderTextfied.secureTextEntry = YES;
        _myRegisterCell.HeaderTextfied.placeholder=DPLocalizedString(@"Register_once_again");
        _myRegisterCell.HeaderTextfied.font = [UIFont systemFontOfSize:11];

        _myRegisterCell.HeaderTextfied.secureTextEntry = YES;
        [_myRegisterCell.HeaderTextfied addTarget:self action:@selector(ChangeSecondPassWord:) forControlEvents:UIControlEventEditingChanged];
        return _myRegisterCell;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if ([textField.placeholder isEqualToString:DPLocalizedString(@"Foget_verification_code")]) {
        NSInteger strLength = textField.text.length - range.length + string.length;
        return (strLength <= 6);
    }
    return true;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}


- (void)setUI
{

    self.UserProtocolsTextView.delegate = self;
    self.UserProtocolsTextView.editable = NO;
    self.UserProtocolsTextView.scrollEnabled = NO;
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString: DPLocalizedString(@"Register_ReadAndAgreeUserAgreement")];
    
    [attributedString addAttribute:NSLinkAttributeName
                             value:@"jianhang://"
                             range:[[attributedString string] rangeOfString:DPLocalizedString(@"Register_UserAgreement")]];
    
    
    
    [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14] range:NSMakeRange(0, attributedString.length)];
     self.UserProtocolsTextView.attributedText = attributedString;
     self.UserProtocolsTextView.linkTextAttributes = @{NSForegroundColorAttributeName: BACKCOLOR(49,55,123,1),
                                       NSUnderlineColorAttributeName: [UIColor lightGrayColor],
                                       NSUnderlineStyleAttributeName: @(NSUnderlinePatternSolid)};

    
    
    self.helpLabel.hidden=YES;
    [self.NextButon setBackgroundColor:myColor];
    [self.NextButon setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.NextButon.layer.cornerRadius=20.f;
    [self.NextButon setTitle:DPLocalizedString(@"Register") forState:UIControlStateNormal];
    [self.NextButon addTarget:self action:@selector(next:) forControlEvents:UIControlEventTouchUpInside];
    self.NextButon.userInteractionEnabled = NO;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if ([[URL scheme] isEqualToString:@"jianhang"]) {
        NSLog(@"建行支付---------------");
        
        NSURL *url = [NSURL URLWithString:@"http://ulifecam.com/common/user-agreements.html"];
        if ([[UIApplication sharedApplication]canOpenURL:url]) {
            [[UIApplication sharedApplication]openURL:url];
        }
       
        return NO;
    }
//    } else if ([[URL scheme] isEqualToString:@"checkbox"]) {
//        self.isSelect = !self.isSelect;
//        [self protocolIsSelect:self.isSelect];
//        return NO;
//    }
    return YES;
}


- (void)configNextButon{
    self.NextButon.userInteractionEnabled = _acount.length>0 && _Verificationcode.length>0 && _FristPwd.length>0 && _SecondPwd.length>0;
}

#pragma mark 账号框值改变
- (void)changeAcount:(UITextField *)field
{
    self.acount = field.text;
    [self configNextButon];
    NSLog(@"账号 :%@ ",self.acount );
}

#pragma mark 邮箱框值改变
- (void)changeEamilVerificationcode:(UITextField *)field
{
    self.Verificationcode = field.text;
    [self configNextButon];
    NSLog(@"验证码 :%@",self.Verificationcode);
}

#pragma mark 新密码框改变
- (void)ChangeNewPassWord:(UITextField *)field
{
    self.FristPwd = field.text;
    [self configNextButon];
    NSLog(@"新密码 :%@",self.FristPwd);
}

#pragma mark 第二输入密码框值改变
- (void)ChangeSecondPassWord:(UITextField *)field
{
    self.SecondPwd = field.text;
    [self configNextButon];
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

#pragma mark 与CBS建立连接 236656


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
    body.VerifyWay = 1;
    CMD_GetVerifyCodeRequest *req = [CMD_GetVerifyCodeRequest new];
    req.Body = body;
    NSData *reqData = [NSJSONSerialization dataWithJSONObject:[req requestCMDData] options:0 error:nil];

    __weak typeof(self) wSelf = self;
    [_netSDK net_sendSyncRequestWithIP:ip port:port data:reqData timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        if (result==0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                wSelf.getCodeBtn.userInteractionEnabled = NO;
                [wSelf.countDownTimer setFireDate:[NSDate distantPast]];
                
                self.helpLabel.hidden=NO;
                [SVProgressHUD showSuccessWithStatus: DPLocalizedString(body.FindPasswordType==3?@"Foget_verification_code_iphone_success":@"Foget_verification_code_emil_success")];
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.helpLabel.hidden=YES;
                if(result == IROUTER_USER_EXIST){
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Register_account_exist_error")];
                }else{
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Foget_send_unsuccess")];
                }
            });
        }
    }];
}

- (IBAction)next:(id)sender {
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(registerWithAcount:
                                                       Verificationcode:
                                                       FristPwd:
                                                       Secondpwd:)])
    {
        if (_isAgree) {
                 [self.delegate registerWithAcount:_acount Verificationcode:_Verificationcode FristPwd:_FristPwd Secondpwd:_SecondPwd];
        }
        else{
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Register_AgreeUserAgreement") ];
        }
    }
}

- (IBAction)agreeUserProtocol:(id)sender {
    if (!_isAgree) {
        [_agreeBtn setImage:[UIImage imageNamed:@"addev_action_light"] forState:UIControlStateNormal];
    }
    else{
         [_agreeBtn setImage:[UIImage imageNamed:@"addev_action_normal"] forState:UIControlStateNormal];
    }
    _isAgree =!_isAgree;
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
