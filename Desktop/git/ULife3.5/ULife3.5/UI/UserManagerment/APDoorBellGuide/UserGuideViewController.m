//
//  UserGuideViewController.m
//  ULife3.5
//
//  Created by Goscam on 2017/12/6.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "UserGuideViewController.h"
#import "LoginViewFristController.h"
#import "RegisterFristViewController.h"
#import "SaveDataModel.h"

@interface UserGuideViewController ()
{
    
}
@property (strong, nonatomic)  RegisterFristViewController *registerVC;

@property (nonatomic, assign)  BOOL hideChangeVersionBtn;
@end

@implementation UserGuideViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self configUI];
    
    [self addActions];
    
    [self checkDirectlyLogin];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.loginBtn setTitle:DPLocalizedString(@"APDoorbell_Guide_Login") forState:UIControlStateNormal];
    [self.registerBtn setTitle:DPLocalizedString(@"APDoorbell_Guide_NewUser") forState:UIControlStateNormal];
    self.registeredTipLabel.text = DPLocalizedString(@"APDoorbell_Guide_Registered");
    
    [self configChangeVersionBtn];
    
}

- (void)viewDidAppear:(BOOL)animated{
    
//    [self configSVProgress];
}


- (void)addTapAction{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action: @selector(showChangeVersionBtn) ];
    tap.numberOfTapsRequired = 5;
    [self.view addGestureRecognizer:tap];
}

- (void)showChangeVersionBtn{
    if (self.changeVersionBtn.hidden) {
        self.changeVersionBtn.hidden = NO;
    }
}

- (void)checkDirectlyLogin{
    NSString *username = [SaveDataModel getUserName];
    NSString *pwd = [SaveDataModel isGetUserPassword];
    if (username.length!=0 && pwd.length!=0) {
        [self loginBtnAction:nil];
    }
}

- (void)configUI{
    
    [self configView];
    
}

- (void)configSVProgress{
    
}

- (void)addActions{
    [self.loginBtn addTarget:self action:@selector(loginBtnAction:) forControlEvents:UIControlEventTouchUpInside ];
    
    [self.registerBtn addTarget:self action:@selector(registerBtnAction:) forControlEvents:UIControlEventTouchUpInside ];
    
    [self addTapAction];
}

- (void)loginBtnAction:(id)sender{
    NSLog(@"登录");
    [self hideStatusBar:NO];
    [self.navigationController pushViewController:[[LoginViewFristController alloc]init] animated:NO];
}

- (void)registerBtnAction:(id)sender{
    NSLog(@"注册");
    [self hideStatusBar:NO];
    self.registerVC = [[RegisterFristViewController alloc]init];
    __weak typeof(self) weakSelf = self;
    [self.registerVC registerResultCabllbackFunc:^(int result) {
        if (result ==0 ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.navigationController popViewControllerAnimated:NO];
        
                [weakSelf loginBtnAction:nil];
            });
        }
    }];
    [self.navigationController pushViewController:self.registerVC animated:NO];
}

-(BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)hideStatusBar:(BOOL)hidden{
    [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:NO];
    [self.navigationController setNavigationBarHidden:hidden animated:NO];
    [[UIApplication sharedApplication] setStatusBarHidden:hidden];
}

- (void)configView{
    
    [self hideStatusBar:YES];

    [self.loginBtn setTitleEdgeInsets: UIEdgeInsetsMake(8, 0, 0, 0)];
    
    [self.loginBtn setTitle:DPLocalizedString(@"APDoorbell_Guide_Login") forState:UIControlStateNormal];
    [self.registerBtn setTitle:DPLocalizedString(@"APDoorbell_Guide_NewUser") forState:UIControlStateNormal];
    
    self.registeredTipLabel.text = DPLocalizedString(@"APDoorbell_Guide_Registered");
    
    [self configChangeVersionBtn];

    _hideChangeVersionBtn = YES;
    
    self.changeVersionBtn.hidden = _hideChangeVersionBtn;
    self.changeVersionBtn.titleLabel.textAlignment = NSTextAlignmentRight;
    [self.changeVersionBtn addTarget:self action:@selector(changeVersionBtnAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)configChangeVersionBtn{
    if ([mUserDefaults integerForKey:IsBetaVersion]==1) {
        [self.changeVersionBtn setTitle:DPLocalizedString(@"AppVersion_Beta") forState:UIControlStateNormal];
    }else{
        [self.changeVersionBtn setTitle:DPLocalizedString(@"AppVersion_Release") forState:UIControlStateNormal];
    }
}

- (void)changeVersionBtnAction:(id)sender{
    if (![mUserDefaults integerForKey:IsBetaVersion]) {
        [mUserDefaults setInteger:1 forKey:IsBetaVersion];
    }else{
        [mUserDefaults setInteger:0 forKey:IsBetaVersion];
    }
    [mUserDefaults removeObjectForKey:kCGSA_ADDRESS];
    [mUserDefaults synchronize];
    [[NetSDK sharedInstance] setcriptKey:nil];
    [self configChangeVersionBtn];
}

@end
