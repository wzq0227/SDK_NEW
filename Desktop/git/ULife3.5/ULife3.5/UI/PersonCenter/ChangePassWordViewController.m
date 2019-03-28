//
//  ChangePassWordViewController.m
//  ULife3.5
//
//  Created by goscam_sz on 2017/6/14.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "ChangePassWordViewController.h"
#import "ChangPwdView.h"
#import "Header.h"
#import "NetSDK.h"
#import "CBSCommand.h"
#import "SaveDataModel.h"
#import "MainNavigationController.h"

@interface ChangePassWordViewController () <UIChangPwdViewDelegate,RESideMenuDelegate>

@property(nonatomic,strong) ChangPwdView * myChangePwdView;

@property(nonatomic,strong) NetSDK *netSDK;

@property(nonatomic, strong) NSString * oldpwd;

@property(nonatomic, strong) NSString * fristNewPwd;

@property(nonatomic, strong) NSString * secondNewPwd;

@end

@implementation ChangePassWordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = DPLocalizedString(@"Personal_changePassWord_title");
    self.netSDK = [NetSDK sharedInstance];
    self.myChangePwdView= [[NSBundle mainBundle]loadNibNamed:@"ChangPwdView" owner:self options:nil].lastObject;
    self.myChangePwdView.delegate=self;
    self.myChangePwdView.frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height);
    [self.view addSubview:_myChangePwdView];
    [self addbackbtn];
}

- (void)addbackbtn
{
    UIImage* img=[UIImage imageNamed:@"addev_back"];
    EnlargeClickButton *btn = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 0, 70, 40);
    btn.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 50);
    [btn setImage:img forState:UIControlStateNormal];
    [btn addTarget: self action: @selector(presentLeftMenuViewController:) forControlEvents: UIControlEventTouchUpInside];
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    temporaryBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.leftBarButtonItem=temporaryBarButtonItem;
}

- (void)getOldPassWord:(NSString *)oldPassword
{
    _oldpwd = oldPassword;
}

- (void)getFristNewPassWord:(NSString *)newPassword
{
    _fristNewPwd = newPassword;
}

- (void)getSecondNewPassWord:(NSString *)newPassword
{
    _secondNewPwd = newPassword;
}

- (void)SveNewPassword
{
    NSString *originalPwd = [SaveDataModel getUserPassword];
    if (![originalPwd isEqualToString:_oldpwd]) {
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Personal_Old_pwd_erro")];
        return;
    }
    
    if (_fristNewPwd.length < 8 || _fristNewPwd.length >16) {
        
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Register_Password_length_between_8_to_16_characters")];
        return;
    }
    if (_secondNewPwd.length < 8 || _secondNewPwd.length >16) {
        
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Register_Password_length_between_8_to_16_characters")];
        return;
    }
    
    BOOL pwdValid = [_fristNewPwd isPasswordValid];
    if (pwdValid) {
        if ([_fristNewPwd isEqualToString:_secondNewPwd]) {
            
            [SVProgressHUD showWithStatus:DPLocalizedString(@"Loading")];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
              
                [self changPwdToCBS];
                });
        }
        else {
              [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Personal_two_PWD_ERRO")];
        }
    }
    else{
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Register_lowercase_letters_must_include_at_least_two")];
    }
}

-(void)changPwdToCBS
{
    CBS_ModifyUserPwdRequest *req = [CBS_ModifyUserPwdRequest new];
    BodyModifyUserPwdRequest *body = [BodyModifyUserPwdRequest new];
    body.NewPassword = _fristNewPwd;
    body.OldPassword = _oldpwd;
    body.UserName = [SaveDataModel getUserName];
    
    if (_fristNewPwd.length >0) {
        body.NewPassword = [self.netSDK encodePassword:_fristNewPwd];
    }
    else{
        return;
    }
    
    if (_oldpwd.length >0) {
        body.OldPassword = [self.netSDK encodePassword:_oldpwd];
    }
    else{
        return;
    }

    [_netSDK net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:7000 responseBlock:^(int result, NSDictionary *dict) {
        if (result !=0) {
            dispatch_async(dispatch_get_main_queue(),^{
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
            });
        }
        else 
        if ([dict[@"MessageType"]isEqualToString:@"ModifyUserPasswordResponse"]) {
            if (result ==0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [UIView animateWithDuration:0.1 animations:^{
                        [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Personal_change_success")];
                        
                    } completion:^(BOOL finished) {
                        
                        [SaveDataModel SaveUsrInforPassWord:@""];
                        [SaveDataModel SaveCBSNetWorkState:NO];
                        [_netSDK net_closeCBSConnect];
                        [UIApplication sharedApplication].keyWindow.rootViewController = [[MainNavigationController alloc]initWithRootViewController:[[LoginViewFristController alloc]init]];
                    }];
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Personal_Operation_Failed")];
                });
            }
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

- (void)viewDidDisappear:(BOOL)animated
{
    [SVProgressHUD dismiss];
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
