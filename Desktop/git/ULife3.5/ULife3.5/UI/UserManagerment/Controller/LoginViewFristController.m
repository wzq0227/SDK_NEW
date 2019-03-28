
//  LoginViewController.m
//  gaoscam
//
//  Created by goscam_sz on 17/4/19.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "LoginViewFristController.h"
#import "Header.h"
#import "SVProgressHUD.h"
#import "NSString+Common.h"
#import "SaveDataModel.h"
#import "SaveDataModel.h"
#import "MainNavigationController.h"
#import "RegisterFristViewController.h"
#import "FogetFristViewController.h"
#import "iRouterInterface.h"
#import "NetSDK.h"
#import "DeviceListViewController.h"
#import "MPSCommand.h"
#import "DevPushManagement.h"
#import "CMSCommand.h"
#import "YYModel.h"
#import "UIColor+YYAdd.h"
#import "NetCheckViewController.h"
#import "CheckNetViewController.h"

@interface LoginViewFristController () <pushNextViewDelegate,RESideMenuDelegate>
@property(nonatomic,strong) LoginView * myLoginView;

@property(nonatomic,strong)NetSDK *netSDK;

@property(nonatomic,assign)int count;

/**CBSA地址已存在 */
@property (assign, nonatomic)  BOOL CGSAExistBefore;

@end

@implementation LoginViewFristController


- (void)viewWillAppear:(BOOL)animated
{
//    self.navigationController.navigationBar.hidden=YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UIView * view = [[UIView alloc]initWithFrame:CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,20)];
    view.backgroundColor=myColor;

    [self configNav];
    
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
    self.view.backgroundColor=[UIColor whiteColor];
    self.myLoginView= [[NSBundle mainBundle]loadNibNamed:@"LoginView" owner:self options:nil].lastObject;
    self.myLoginView.frame = CGRectMake(0,20,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height);
    [self.view addSubview:_myLoginView];
    [self.myLoginView.deleteBtn addTarget:self action:@selector(login)forControlEvents:UIControlEventTouchUpInside];
    [self.myLoginView.forgetBtn addTarget:self action:@selector(forget)forControlEvents:UIControlEventTouchUpInside];
    [self.myLoginView.changeVersionBtn addTarget:self action:@selector(changeVersionBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    if (SCREEN_WIDTH < 321) {
        self.myLoginView.topToSuperOfLogo.constant = 5;
    }
//    self.myLoginView.topToSuperOfLogo.constant = 40*SCREEN_WIDTH/375;
    
    self.myLoginView.delegate=self;
    _netSDK = [NetSDK sharedInstance];
    
    self.acount = [SaveDataModel getUserName];
    self.password = [SaveDataModel isGetUserPassword];
    if (self.acount.length!=0 && self.password.length!=0) {
        [self login];
    }
}

- (void)changeVersionBtnClicked:(id)sender{
    
    UserChosenVersion chosenVersion = [mUserDefaults integerForKey:mUserChosenVersion];
    UserChosenVersion changeToVersion;
    
    if (isENVersion) {
        
//        switch (chosenVersion) {
//            case UserChosenVersionDomestic:
//            {
//                changeToVersion = UserChosenVersionOverseas;
//                break;
//            }
//            case UserChosenVersionOverseas:
//            {
//                changeToVersion = UserChosenVersionDomestic;
//                break;
//            }
//            default:
//                changeToVersion = UserChosenVersionDomestic;
//                break;
//        }
    }else{
        
        switch (chosenVersion) {
            case UserChosenVersionDomestic:
            {
                changeToVersion = UserChosenVersionOverseas;
                break;
            }
            case UserChosenVersionOverseas:
            {
                changeToVersion = UserChosenVersionDomestic;
                break;
            }
            default:
                changeToVersion = UserChosenVersionOverseas;
                break;
        }
    }
    
    [mUserDefaults setInteger:changeToVersion forKey:mUserChosenVersion];
    [mUserDefaults synchronize];
    
    
    [mUserDefaults removeObjectForKey:kCGSA_ADDRESS];
    [mUserDefaults synchronize];
    [[NetSDK sharedInstance] setcriptKey:nil];
    
//    ServerAddress *tempCGSAAddr = [ServerAddress yy_modelWithDictionary:[mUserDefaults objectForKey:kCGSA_ADDRESS]];
//    [mUserDefaults setObject: tempCGSAAddr.Address forKey:@"kCBS_IP"];
//    [mUserDefaults setObject:[NSNumber numberWithInteger:tempCGSAAddr.Port] forKey:@"CBS_PORT"];
//    [mUserDefaults synchronize];
//
//    [[NetSDK sharedInstance] setcriptKey:nil];
//    [[NetSDK sharedInstance] setCBSAddress:tempCGSAAddr.Address port: tempCGSAAddr.Port];

    [self.myLoginView refreshTitles];
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

- (void)startReister
{
    NSLog(@"注册");
    [self.navigationController pushViewController:[[RegisterFristViewController alloc]init] animated:NO];
}

-(BOOL)isStringChecking:(NSString *)str
{
    if (str == nil) {
        return NO;
    }
    else
    {
        if ([str length] == 0) {
            return NO;
        }
    }
    return YES;
}

-(void)login
{
    NSLog(@"登录");
    
    if (![self isStringChecking:self.acount])
    {
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_The_user_account_or_password_format_error")];
        return;
    }
    else
    {
        if([self.acount length] > 128)
        {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_The_user_account_or_password_format_error")];
            return;
        }
        else
        {
            if ([self.acount isMetacharacter]) {
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_The_user_account_or_password_format_error")];
                return;
            }
        }
    }
    if (![self isStringChecking:self.password]) {
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_The_user_account_or_password_format_error")];
        return;
    }
    else
    {
        if ([self.password isMetacharacter]) {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_The_user_account_or_password_format_error")];
            return;
        }
        
        if ([self.password length] < 8 ) {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_The_user_account_or_password_format_error")];
            return;
        }
        else if([self.password length] > 128)
        {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_The_user_account_or_password_format_error")];
            return;
        }
    }
    
    [SVProgressHUD showWithStatus:DPLocalizedString(@"loading")];
    
//    ServerAddress *upsAddr = [ServerAddress yy_modelWithDictionary:[mUserDefaults objectForKey:kCGSA_ADDRESS]];
//    if (upsAddr) {
//
//        self.CGSAExistBefore = YES;
//
//        //存在这个就存在加密key
//        NSString *criptKey = [mUserDefaults objectForKey:@"CryptKey"];
//        [_netSDK setcriptKey:criptKey];
//        [mUserDefaults synchronize];
//
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//
//            [self loginWithIP:upsAddr.Address port:upsAddr.Port ];
//        });
//
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (1 * NSEC_PER_SEC)), dispatch_get_global_queue(0,0), ^{
//            [self getCBS_PORT];
//        });
//    }
//    else
    {
        self.CGSAExistBefore = NO;
        [self getCBS_PORT];
    }
    
}





#pragma mark -- 登录推送服务器
- (void)net_loginToMPSWithName:(NSString*)userName password:(NSString *)pwd{
}


#pragma mark 与CBS建立连接


#pragma mark 获取端口 （8000）

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
    req.UserName = self.acount;
    req.Password = self.password;
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
//            [weakself.netSDK setPort:upsAddr.Port];
            
            if ( upsAddr ) {
                
                if( !self.CGSAExistBefore ){
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        [self loginWithIP:upsAddr.Address port:upsAddr.Port ];
                    });
                }
                self.CGSAExistBefore = YES;
            }else{
                self.CGSAExistBefore = NO;
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    
                    [self getCBS_PORT];
                });
            }
        }else{
            NSLog(@"_____________________________获取CGSA地址失败");
            if( !self.CGSAExistBefore ){
//                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showCheckNetworkAlert];
                });
            }
        }
        
    }];
}
#pragma mark 在CBS登录
-(void)loginWithIP:(NSString*)mIP port:(int)mPort
{
    __weak typeof(self) weakSelf = self;
    
    
    NSString *securePwd;
    if (self.password.length >0) {
        securePwd = [_netSDK encodePassword:self.password];
    }
    else{
        return;
    }
//    [SVProgressHUD showWithStatus:mIP];
//    [NSThread sleepForTimeInterval:2];
    NSLog(@"net_loginWithIP:%@ port:%d",mIP,mPort);
    
    [weakSelf.netSDK net_loginWithIP:mIP port:mPort userName:_acount password:securePwd timeout:9000 result:^(int result, NSDictionary *dict) {
        
        if (result == 0) {

            [SaveDataModel SaveUsrInforUserName:self.acount];
            [SaveDataModel SaveUsrInforPassWord:self.password];
            [SaveDataModel SaveUserToken:dict[@"Body"][@"UserToken"]];
            [SaveDataModel SaveloginState:YES];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                [self NextDeviceListView];
            });
            
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"*********************登录失败*************code:%d",result);
                
                if (result == IROUTER_USER_NOEXIST || result == IROUTER_LOGIN_USERNAME_ERROR) {
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_AccountDoesNotExist")];
                    
                }else if (result == IROUTER_LOGIN_PASSWORD_ERROR){
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_Passwordmistake")];
                }else if(result == IROUTER_NETWORK_TIMEOUT){
//                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
                    
                    [self showCheckNetworkAlert];
                }else{
//                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
                    [self showCheckNetworkAlert];
                }
            });
        }
    }];
}


#pragma mark 跳转到设备列表
-(void)NextDeviceListView
{
    MainNavigationController *navigationController = [[MainNavigationController alloc] initWithRootViewController:[[DeviceListViewController alloc] init]];
    PersonalCenterViewController *leftMenuViewController = [[PersonalCenterViewController alloc] init];
    RESideMenu *sideMenuViewController = [[RESideMenu alloc] initWithContentViewController:navigationController
                                                                    leftMenuViewController:leftMenuViewController
                                                                   rightMenuViewController:nil];
    sideMenuViewController.menuPreferredStatusBarStyle = 1; // UIStatusBarStyleLightContent
    sideMenuViewController.delegate = self;
    sideMenuViewController.contentViewShadowColor   = [UIColor blackColor];
    sideMenuViewController.contentViewShadowOffset  = CGSizeMake(0, 0);
    sideMenuViewController.contentViewShadowOpacity = 0.6;
    sideMenuViewController.contentViewShadowRadius  = 12;
    sideMenuViewController.contentViewShadowEnabled = YES;
    sideMenuViewController.bouncesHorizontally = NO;
    sideMenuViewController.parallaxEnabled = NO;
    [UIApplication sharedApplication].keyWindow.rootViewController = sideMenuViewController;
}

- (void)refreshTitles{
    
}


-(void)forget
{
    NSLog(@"忘记密码");
    [self.navigationController pushViewController:[[FogetFristViewController alloc]init] animated:NO];
}

-(void)loginAcount:(NSString *)acount
{
    self.acount=acount;
    
    BOOL enable = self.acount.length >0 && self.password.length>=8;
    
    if (enable) {
        [self.myLoginView.deleteBtn setBackgroundColor:[UIColor colorWithRed:46/255.0 green:188/255.0 blue:208/255.0 alpha:1.0]];
    }
    else{
        [self.myLoginView.deleteBtn setBackgroundColor:[UIColor colorWithRed:171/255.0 green:229/255.0 blue:236/255.0 alpha:1.0]];
    }
    
    self.myLoginView.deleteBtn.userInteractionEnabled = enable;
}

-(void)loginPassword:(NSString *)password
{
    self.password=password;
    
    BOOL enable = self.acount.length >0 && self.password.length>=8;
    
    if (enable) {
        [self.myLoginView.deleteBtn setBackgroundColor:[UIColor colorWithRed:46/255.0 green:188/255.0 blue:208/255.0 alpha:1.0]];
    }
    else{
        [self.myLoginView.deleteBtn setBackgroundColor:[UIColor colorWithRed:171/255.0 green:229/255.0 blue:236/255.0 alpha:1.0]];
    }
    
    self.myLoginView.deleteBtn.userInteractionEnabled =  enable;
}

- (BOOL)shouldAutorotate
{
    //NSLog(@"shouldAutorotate . %ld", (long)[[AppInfomation sharedInstance] isPlayerViewShown]);
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)showCheckNetworkAlert {
    [SVProgressHUD dismiss];
    
    UIAlertController *vc = [UIAlertController alertControllerWithTitle:nil message:DPLocalizedString(@"Login_NetworkRequestTimeout") preferredStyle:UIAlertControllerStyleAlert];
    [vc addAction:[UIAlertAction actionWithTitle:DPLocalizedString(@"Setting_Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [vc addAction:[UIAlertAction actionWithTitle:DPLocalizedString(@"NetCheckShort") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        CheckNetViewController *vc = [[CheckNetViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }]];
    [self presentViewController:vc animated:YES completion:nil];
}
@end
