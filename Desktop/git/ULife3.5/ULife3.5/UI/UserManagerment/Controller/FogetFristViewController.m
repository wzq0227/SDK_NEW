//
//  FogetFristViewController.m
//  ULife3.5
//
//  Created by goscam_sz on 2017/6/2.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "FogetFristViewController.h"
#import "ForgetView.h"
#import "NetSDK.h"
#import "SaveDataModel.h"
#import "CBSCommand.h"
#import "NSString+Common.h"
#import "iRouterInterface.h"
#import "CMSCommand.h"

@interface FogetFristViewController () <UIForgetViewDelegate>

@property(nonatomic,strong) ForgetView * myForgetView;

@property(nonatomic,strong) NetSDK *netSDK;

@property(nonatomic,strong) NSString *UserInfo;

@property(nonatomic,strong) NSString *NewPassword;

@property(nonatomic,strong) NSString *VerifyCode;

@property(nonatomic,assign) int count;

@end

@implementation FogetFristViewController



- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBar.hidden=NO;
}

- (void)viewWillDisappear:(BOOL)animated{
    
    [self.myForgetView invalidateTimers];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title=DPLocalizedString(@"Foget_password");
    self.view.backgroundColor=[UIColor whiteColor];
    self.myForgetView= [[NSBundle mainBundle]loadNibNamed:@"ForgetView" owner:self options:nil].lastObject;
    self.myForgetView.delegate=self;
    self.myForgetView.frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height);
    self.netSDK = [NetSDK sharedInstance];
    [self.view addSubview:_myForgetView];
    
}

#pragma mark 账号，验证码，密码代理回调
- (void)findPasswordAcount:(NSString *)acount Verificationcode:(NSString *)code FristPwd:(NSString *)fristpwd Secondpwd:(NSString *)secondpwd
{
    _count=1;
    if (![fristpwd isEqualToString:secondpwd]) {
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Register_password_don't_match")];
    }
    else{
        
        if (fristpwd.length < 8 || fristpwd.length >16) {
            
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Register_Password_length_between_8_to_16_characters")];
            return;
        }
        if (secondpwd.length < 8 || secondpwd.length >16) {
            
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Register_Password_length_between_8_to_16_characters")];
            return;
        }
        
        
        BOOL pwdValid = [secondpwd isPasswordValid];
        if ( pwdValid ) {
            _UserInfo=acount;
            _NewPassword=secondpwd;
            _VerifyCode=code;
            
            ServerAddress *upsAddr = [ServerAddress yy_modelWithDictionary:[mUserDefaults objectForKey:kCGSA_ADDRESS]];
            if (upsAddr) {
                //连接
                [self changeNewPasswordToCBSWithIP:upsAddr.Address port:upsAddr.Port];
            }else{
                [self getCBS_PORT];
            }
            
            [SVProgressHUD showWithStatus:DPLocalizedString(@"Loading")];
        }
        else{
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Register_lowercase_letters_must_include_at_least_two")];
        }
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
                [self changeNewPasswordToCBSWithIP:upsAddr.Address port:upsAddr.Port];
            }
        }else{
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"localizied_294")];
        }
        
    }];
    
}

#pragma mark 密码格式校验
-(int)checkIsHaveNumAndLetter:(NSString*)password{
    //数字条件
    NSRegularExpression *tNumRegularExpression = [NSRegularExpression regularExpressionWithPattern:@"[0-9]" options:NSRegularExpressionCaseInsensitive error:nil];
    
    //符合数字条件的有几个字节
    NSUInteger tNumMatchCount = [tNumRegularExpression numberOfMatchesInString:password
                                                                       options:NSMatchingReportProgress
                                                                         range:NSMakeRange(0, password.length)];
    //大写字母文字条件
    NSRegularExpression *capitallettersRegularExpression = [NSRegularExpression regularExpressionWithPattern:@"[A-Z]" options:NSRegularExpressionCaseInsensitive error:nil];
    
    //符合英文字条件的有几个字节
    NSUInteger capitalLetterMatchCount = [capitallettersRegularExpression numberOfMatchesInString:password options:NSMatchingReportProgress range:NSMakeRange(0, password.length)];
    
    //小写字母文字条件
    NSRegularExpression *LowercaselettersRegularExpression = [NSRegularExpression regularExpressionWithPattern:@"[a-z]" options:NSRegularExpressionCaseInsensitive error:nil];
    
    //符合英文字条件的有几个字节
    NSUInteger LowercaseLetterMatchCount = [LowercaselettersRegularExpression numberOfMatchesInString:password options:NSMatchingReportProgress range:NSMakeRange(0, password.length)];
    
    if (tNumMatchCount == password.length) {
        //全部符合数字，表示沒有英文
        return 1;
    } else if (capitalLetterMatchCount == password.length){
        NSLog(@"全部大写");
        return 2;
    } else if (LowercaseLetterMatchCount == password.length){
        NSLog(@"全部小写");
        return 3;
    } else if (tNumMatchCount + capitalLetterMatchCount == password.length || tNumMatchCount + capitalLetterMatchCount +LowercaseLetterMatchCount == password.length || tNumMatchCount +LowercaseLetterMatchCount == password.length || capitalLetterMatchCount + LowercaseLetterMatchCount == password.length ) {
        //符合英文和符合数字条件的相加等于密码长度
        return 4;
    } else {
        return 5;
        //可能包含标点符号的情況，或是包含非英文的文字，这里再依照需求详细判断想呈现的错误
    }
}


#pragma mark 设置新密码
- (void)changeNewPasswordToCBSWithIP:(NSString*)ip port:(int)port
{
    __weak typeof(self) weakSelf = self;
    CMD_ModifyPasswordByVerifyRequest *req = [CMD_ModifyPasswordByVerifyRequest new];
    BodyModifyPasswordByVerifyRequest *body = [BodyModifyPasswordByVerifyRequest new];
    body.FindPasswordType = [_UserInfo isEmail]?2:3;
    body.UserInfo = _UserInfo;
    NSString *criptPassword ;
    if (_NewPassword.length >0) {
        criptPassword = [self.netSDK encodePassword:_NewPassword];
    }
    else{
        return;
    }
    body.NewPassword = criptPassword;
    body.VerifyCode = _VerifyCode;
    req.Body = body;
    NSData *reqData = [NSJSONSerialization dataWithJSONObject:[req requestCMDData] options:0 error:nil];

    [_netSDK net_sendSyncRequestWithIP:ip port:port data:reqData timeout:5000 responseBlock:^(int result, NSDictionary *dict) {
        
            if (result==0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIView animateWithDuration:0.1 animations:^{
                        [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Foget_Reset_password_success")];
                        [weakSelf.netSDK net_closeCBSConnect];
                        [SaveDataModel SaveCBSNetWorkState:NO];
                    } completion:^(BOOL finished) {
                        [weakSelf.navigationController popViewControllerAnimated:NO];
                    }];
                });
            }
            else{
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (result == IROUTER_VERIFY_CODE_TIMEOUT){
                        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Register_Captcha_failed")];
                    }
                    else if (result == IROUTER_VERIFY_CODE_GETCODE_FIRST){
                        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Register_get_the_verification_code_again")];
                    }
                    else if (result == IROUTER_VERIFY_CODE_ERROR){
                        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Register_Verification_code_error")];
                    }
                    else{
                        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
                    }
                });
            }
    }];
}


#pragma mark 强制不旋屏
- (BOOL)shouldAutorotate
{
    //NSLog(@"shouldAutorotate . %ld", (long)[[AppInfomation sharedInstance] isPlayerViewShown]);
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}


-(void)viewDidDisappear:(BOOL)animated
{
    _netSDK=nil;
}
@end
