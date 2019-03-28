//
//  RegistrtSecondController.m
//  goscamapp
//
//  Created by goscam_sz on 17/5/9.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "RegistrtSecondController.h"
#import "SecondStepRegisterView.h"
#import "QQIGetDeviceListSocket.h"
#import "SVProgressHUD.h"
#import "LoginViewFristController.h"
#import "CBSCommand.h"
#import "NetSDK.h"
#import "SaveDataModel.h"
#import "iRouterInterface.h"
#import "CMSCommand.h"


@interface RegistrtSecondController ()<SecondStepRegisterViewDelegate>

@property (nonatomic,strong) SecondStepRegisterView * mySecondStepRegisterView;

@property(nonatomic,strong)NetSDK *netSDK;

@end

@implementation RegistrtSecondController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self  addMySecondStepRegisterView];
    [self  addLoginBtn];
    _netSDK = [NetSDK sharedInstance];
    self.title=DPLocalizedString(@"Register_Quick_registration");
    
}

- (void)addMySecondStepRegisterView
{
    self.mySecondStepRegisterView= [[NSBundle mainBundle]loadNibNamed:@"SecondStepRegisterView" owner:self options:nil].lastObject;
    self.mySecondStepRegisterView.delegate=self;
    self.mySecondStepRegisterView.frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height);
    [self.view addSubview:_mySecondStepRegisterView];
    [self.mySecondStepRegisterView refreshAccount:self.account];
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

- (void)login
{
    for (UIViewController *controller in self.navigationController.viewControllers) {
        if ([controller isKindOfClass:[LoginViewFristController class]]) {
            [self.navigationController popToViewController:controller animated:NO];
        }
    }
}

- (void)getOldPassWord:(NSString *)oldPassword
{
    NSLog(@"更改了旧密码");
    _accountOldPassWord=oldPassword;
}

- (void)getNewPassWord:(NSString *)newPassword
{
    NSLog(@"更改了新密码");
    _accountNewPassword=newPassword;
}

- (void)RegisterNewAccount
{
    if (_accountNewPassword.length < 8 || _accountNewPassword.length >16) {
        
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Register_Password_length_between_8_to_16_characters")];
        return;
    }
    
    int ret = [self checkIsHaveNumAndLetter:_accountOldPassWord];
    if (ret==4) {
        if ([_accountOldPassWord isEqualToString:_accountNewPassword]) {
            
            BOOL ret= [SaveDataModel isCbsNetWorkSate];
            if (ret) {
                 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                     [self RegisterToCBS];
                 });
            }
            else
            {
                 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                     [self connectToCBS];
                 });
            }
            
            [SVProgressHUD showWithStatus:DPLocalizedString(@"Loading")];
        }
        else {
        
        }
    }
    else{
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Register_lowercase_letters_must_include_at_least_two")];
    }
}

#pragma mark  CBS注册账号
-(void)RegisterToCBS
{
    CBS_RegisterRequest *req = [CBS_RegisterRequest new];
    BodyRegisterRequest *body = [BodyRegisterRequest new];
    body.UserName  = _account;
    body.Password  = _accountNewPassword;
    body.EmailAddr = _account;
    body.RegisterWay =2;
    body.PhoneNumber = @"";
    body.AreaId = @"000001";
    
    __weak typeof(self) weakSelf = self;
            [weakSelf.netSDK net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject]  timeout:5000 responseBlock:^(int result, NSDictionary *dict) {
                if (result !=0) {
                    dispatch_async(dispatch_get_main_queue(),^{
                        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
                    });
                }
                else 
                if ([dict[@"MessageType"]isEqualToString:@"UserRegisterResponse"]) {
                    if (result == 0){
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [SVProgressHUD dismiss];
                            [_netSDK  net_closeCBSConnect];
                            [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Register_succeess")];
                            [SaveDataModel SaveCBSNetWorkState:NO];
                            [weakSelf login];
                        });
                    }
                    else if (result == IROUTER_USER_EXIST){
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Register_account_exist_error")];
                        });
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Register_account_not_exist_error")];
                        });
                    }
                }
            }];
}

#pragma mark 与CBS建立连接
-(void)connectToCBS
{
    __weak typeof(self) weakSelf = self;
    ServerAddress *upsAddr = [ServerAddress yy_modelWithDictionary:[mUserDefaults objectForKey:kCGSA_ADDRESS]];
    
    if (!upsAddr) {
        [self getCBS_PORT];
        return;
    }
    [_netSDK net_connectToCBSWithAddress:upsAddr.Address nport:upsAddr.Port resultBlock:^(int result) {
        if (result==0) {
            [SaveDataModel SaveCBSNetWorkState:YES];
            [weakSelf RegisterToCBS];
        }
        else{
//            [SaveDataModel SaveCBSNetWorkState:NO];
        }
    }];
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
                [self connectToCBS];
            }
        }else{
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"localizied_294")];
        }
        
    }];
    
}

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
