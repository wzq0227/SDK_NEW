//
//  NetCheckViewController.m
//  ULife3.5
//
//  Created by AnDong on 2018/7/10.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "NetCheckViewController.h"
#import "Definition.h"
#import "drawView.h"
#import "CBSCommand.h"
#import "CMSCommand.h"
#import "NetSDK.h"


@interface NetCheckViewController ()

@property (nonatomic) drawView * drawview;

@property (nonatomic,strong)UILabel *progress;
//@property (nonatomic,strong)UILabel *cmsiPLabel;
//
//@property (nonatomic,strong)UILabel *cgsLabel;
//@property (nonatomic,strong)UILabel *cgsIPLabel;
//
//@property (nonatomic,strong)UILabel *upsLabel;
//@property (nonatomic,strong)UILabel *upsIPLabel;

@property (nonatomic,strong)UIButton *netCheckBtn;

//是否在诊断
@property (nonatomic,assign)BOOL isChecking;

@end

@implementation NetCheckViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = myColor;
    self.title = DPLocalizedString(@"NetCheckTitle");
    
    self.drawview = [[drawView alloc]initWithFrame:CGRectMake((kScreen_Width - 250)/2, 100, 250, 250)];
    self.drawview.backgroundColor = myColor;
    self.drawview.progressLabel.text = @"";
    [self.view addSubview:self.drawview];
    [self.view addSubview:self.netCheckBtn];
}


- (void)netCheckAction{
    //开始诊断
    if (_isChecking) {
        //如果在检测直接返回
        return;
    }
    self.drawview.progress = 0.0f;
    [_netCheckBtn setTitle:DPLocalizedString(@"netcheckCurrent") forState:UIControlStateNormal];
    _isChecking = YES;
    [self getCBS_PORT];
    
    
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
    req.UserName = @"test";
    req.Password = @"test123";
    req.ServerType = @[@2,@3,@4];
    self.drawview.progressLabel.text = DPLocalizedString(@"NetcheckCMSCurrent");
    [[NetSDK sharedInstance] net_getCBSPortWithIP:ipconfig port:6001 data:[req requestCMDData] responseBlock:^(int result, NSDictionary *dict) {
        NSString *criptkey = dict[@"CryptKey"];
        [mUserDefaults setObject:criptkey forKey:@"CryptKey"];
        [[NetSDK sharedInstance] setcriptKey:criptkey];
        if (result ==0 || result == -106) {
            //第一步成功
            NSArray *serverList = dict[@"ServerList"];
            for (NSDictionary *addressDict in serverList) {
                ServerAddress *serverAddr = [ServerAddress yy_modelWithDictionary:addressDict];
                switch (serverAddr.Type) {
                    case 2:
                        [mUserDefaults setObject:addressDict forKey:@"MPSAddress"];
                        break;
                    case 3:
                        [mUserDefaults setObject:addressDict forKey:kCGSA_ADDRESS];
                        [[NetSDK sharedInstance] setCBSAddress:addressDict[@"Address"] port:[addressDict[@"Port"] intValue]];
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
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.drawview.progress = 0.33;
                self.drawview.progressLabel.text = DPLocalizedString(@"NetchekCMSSuc");
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self checkUPSAddress];
                });
            });
            
        }else{
            //CMS检测连接失败
            dispatch_async(dispatch_get_main_queue(), ^{
                _isChecking = NO;
                self.drawview.progressLabel.text = DPLocalizedString(@"Netcheckerror");
                [_netCheckBtn setTitle:DPLocalizedString(@"NetcheckReload") forState:UIControlStateNormal];
            });

        }
        
    }];
}


- (void)checkUPSAddress{
    self.drawview.progressLabel.text = DPLocalizedString(@"NetcheckUPSCurrent");
    ServerAddress *upsAddr = [ServerAddress yy_modelWithDictionary:[mUserDefaults objectForKey:@"UPSAddress"]];

    NSString *bundid = [NSString stringWithFormat:@"%@.ios",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]];
    
    NSString *appName = [NSString stringWithFormat:@"%@ios",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"]];
    
    NSDictionary *requestDict = @{
                                  @"MessageType":@"GetAppNewestFromUPSRequest",
                                  @"Body":@{@"AppName":appName,
                                            @"PackageName":bundid}
                                  };
    [[NetSDK sharedInstance] net_queryAPPVersionWithIP:upsAddr.Address port:upsAddr.Port data:requestDict responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            //连接成功
            dispatch_async(dispatch_get_main_queue(), ^{
                self.drawview.progress = 0.66f;
                self.drawview.progressLabel.text = DPLocalizedString(@"NetcheckUPSSuc");
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self checkCBSAddress];
                });
            });
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                _isChecking = NO;
                self.drawview.progressLabel.text = DPLocalizedString(@"Netcheckerror");
                [_netCheckBtn setTitle:DPLocalizedString(@"NetcheckReload") forState:UIControlStateNormal];
            });
        }
    }];
}


//做了个假的
- (void)checkCBSAddress{
    self.drawview.progressLabel.text = DPLocalizedString(@"NetcheckCBSCurrent");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.drawview.progressLabel.text = DPLocalizedString(@"NetcheckCBSSuc");
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.drawview.progressLabel.text = DPLocalizedString(@"NetcheckSuc");
        _isChecking = NO;
        self.drawview.progress = 1.0f;
         [_netCheckBtn setTitle:DPLocalizedString(@"NetcheckReload") forState:UIControlStateNormal];
    });
}



- (UIButton *)netCheckBtn{
    if (!_netCheckBtn) {
        _netCheckBtn = [[UIButton alloc]initWithFrame:CGRectMake((kScreen_Width - 150)/2, kScreen_Height - 60 -150, 150, 60)];
        [_netCheckBtn setTitle:DPLocalizedString(@"Netcheckstart") forState:UIControlStateNormal];
        [_netCheckBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_netCheckBtn addTarget:self action:@selector(netCheckAction) forControlEvents:UIControlEventTouchUpInside];
        _netCheckBtn.titleLabel.font = [UIFont systemFontOfSize:18.0f];
        _netCheckBtn.layer.masksToBounds = YES;
        _netCheckBtn.layer.cornerRadius = 5.0f;
        _netCheckBtn.layer.borderWidth = 1.0f;
        _netCheckBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    }
    return _netCheckBtn;
}


@end
