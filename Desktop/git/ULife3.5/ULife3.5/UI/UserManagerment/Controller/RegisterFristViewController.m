//
//  RegisterFristViewController.m
//  goscamapp
//
//  Created by goscam_sz on 17/5/8.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "RegisterFristViewController.h"
#import "RegisterView.h"
#import "NSString+Common.h"
#import "iRouterInterface.h"
#import "LoginViewFristController.h"
#import "Masonry.h"
#import "UITableView+FDTemplateLayoutCell.h"
#import "SaveDataModel.h"
#import "CBSCommand.h"
#import "CMSCommand.h"

@interface RegisterFristViewController ()<UIRegisterViewDelegate>{
    
}

@property(nonatomic,strong) RegisterView * myRegisterView;

@property(nonatomic,strong) NSString *UserInfo;

@property(nonatomic,strong) NSString *NewPassword;

@property(nonatomic,strong) NSString *VerifyCode;

@property(nonatomic,assign)int count;

@property (strong, nonatomic)  RegisterResultCabllback registerCallbackBlock;
@end

@implementation RegisterFristViewController

- (void)viewWillAppear:(BOOL)animated
{
//    self.navigationController.navigationBar.hidden=NO;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [self.myRegisterView invalidateTimers];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title=DPLocalizedString(@"Register_Quick_registration");
    self.view.backgroundColor=[UIColor whiteColor];
    self.myRegisterView= [[NSBundle mainBundle]loadNibNamed:@"RegisterView" owner:self options:nil].lastObject;
    self.myRegisterView.delegate=self;
    self.myRegisterView.frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height);
    [self.view addSubview:_myRegisterView];
    _netSDK = [NetSDK sharedInstance];
    [self configNav];
}

- (void)emilString:(NSString *)str
{
    _acount=str;
}

- (void)addLoginBtn
{
    UIButton *RightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    RightButton.frame = CGRectMake(0.0, 0, 40, 40);
    RightButton.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [RightButton setTitle:DPLocalizedString(@"Register_login") forState:UIControlStateNormal];
    [RightButton addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:RightButton];        temporaryBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.rightBarButtonItem = temporaryBarButtonItem;
}

- (void)configNav{
    
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem itemWithFrame:CGRectMake(0, 0, 70, 40)
                                                                    target:self
                                                                    action:@selector(navBack)
                                                                     image:[UIImage imageNamed:@"addev_back"]
                                                           imageEdgeInsets:UIEdgeInsetsMake(10, 0, 10, 50)];
    
}

- (void)navBack{
    [self hideStatusBar:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)hideStatusBar:(BOOL)hidden{
    [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:NO];
    [self.navigationController setNavigationBarHidden:hidden animated:NO];
    [[UIApplication sharedApplication] setStatusBarHidden:hidden];
}


-(void)registerResultCabllbackFunc:(RegisterResultCabllback)result{
    self.registerCallbackBlock = result;
}

#pragma mark - 注册完成跳到登录界面
- (void)login
{
    if(self.registerCallbackBlock){
        self.registerCallbackBlock(0);
    }
}


#pragma mark 
- (void)registerWithAcount:(NSString *)acount Verificationcode:(NSString *)code FristPwd:(NSString *)fristpwd Secondpwd:(NSString *)secondpwd{
    _count=1;
    if (![fristpwd isEqualToString:secondpwd]) {
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Register_password_don't_match")];
    }
    else{
        
        if (fristpwd.length < 8 || fristpwd.length >16) {
            
            [SVProgressHUD showErrorWithStatus:DPLocalizedString (@"Register_Password_length_between_8_to_16_characters")];
            return;
        }
        if (secondpwd.length < 8 || secondpwd.length >16) {
            
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Register_Password_length_between_8_to_16_characters")];
            return;
        }
        
        
        BOOL pwdValid = [secondpwd isPasswordValid];
        if (pwdValid) {
            _UserInfo=acount;
            _NewPassword=secondpwd;
            _VerifyCode=code;
            ServerAddress *upsAddr = [ServerAddress yy_modelWithDictionary:[mUserDefaults objectForKey:kCGSA_ADDRESS]];
            if (upsAddr) {
                //连接
                [self RegisterToCBSWithIP:upsAddr.Address port:upsAddr.Port];
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


#pragma mark 与CBS建立连接
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
                [self RegisterToCBSWithIP:upsAddr.Address port:upsAddr.Port];
            }
        }else{
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"localizied_294")];
        }
    }];
}


#pragma mark  CBS注册账号
-(void)RegisterToCBSWithIP:(NSString*)ip port:(int)port
{
    CBS_RegisterRequest *req = [CBS_RegisterRequest new];
    BodyRegisterRequest *body = [BodyRegisterRequest new];
    body.UserName  = _UserInfo;
    body.Password  = _NewPassword;
    body.EmailAddr = [_UserInfo isEmail]?_UserInfo:@"";
    body.RegisterWay = [_UserInfo isEmail]?2:3;
    body.PhoneNumber = [_UserInfo isEmail]?@"":_UserInfo;
    body.AreaId = @"000001";
    body.UserType = 9;
    body.VerifyCode = _VerifyCode;
    req.Body = body;

    NSString *criptPassword;
    if (_NewPassword.length >0) {
        criptPassword = [self.netSDK encodePassword:_NewPassword];
        body.Password = criptPassword;
    }
    else{
        return;
    }

    __weak typeof(self) weakSelf = self;
    NSData *reqData = [NSJSONSerialization dataWithJSONObject:[req requestCMDData] options:0 error:nil];
    [weakSelf.netSDK net_sendSyncRequestWithIP:ip port:port data:reqData timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        
        if (result == 0){
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Register_succeess")];
                [SaveDataModel SaveUsrInforUserName:weakSelf.UserInfo];
                [SaveDataModel SaveCBSNetWorkState:NO];
                [weakSelf login];
            });
        }
        else if (result == IROUTER_USER_EXIST){
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Register_account_exist_errorr")];
            });
        }
        else if (result == IROUTER_VERIFY_CODE_ERROR){
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Register_Verification_code_error")];
            });
        }
        else if (result == IROUTER_VERIFY_CODE_TIMEOUT){
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Register_Captcha_failed")];
            });
        }
        else if (result == IROUTER_VERIFY_CODE_GETCODE_FIRST){
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Register_get_the_verification_code_again")];
            });
        }
        
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
                //                        [SaveDataModel SaveCBSNetWorkState:NO];
            });
        }
    }];
    
}


#pragma mark 提交注册
- (void)next
{
    //
}


- (BOOL)shouldAutorotate
{
    //NSLog(@"shouldAutorotate . %ld", (long)[[AppInfomation sharedInstance] isPlayerViewShown]);
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
