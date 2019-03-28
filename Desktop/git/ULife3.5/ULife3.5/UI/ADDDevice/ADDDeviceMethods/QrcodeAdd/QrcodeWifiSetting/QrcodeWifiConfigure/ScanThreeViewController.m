//
//  ScanThreeViewController.m
//  UI——update
//
//  Created by goscam_sz on 16/6/30.
//  Copyright © 2016年 goscam_sz. All rights reserved.
//

#import "ScanThreeViewController.h"
#import "CustomWindow.h"

#import "SmartClass.h"
#import "UlifeUdpSearcher.h"
#import "iRouterInterface.h"
#import "QrcodeSetingViewController.h"
#import "AddDeviceViewController.h"
#import "CBSCommand.h"
#import "NetSDK.h"
#import "SmartLink.h"
#import "SaveDataModel.h"
#import "DeviceListViewController.h"
#import "WiFiSettingConnectWiFiVC.h"

@interface ScanThreeViewController ()<UISmartLinkDelegate>
{
    CustomWindow *customWindow;
    BOOL wringAction;
    int changge;
    int _icount;
    UlifeUdpSearcher *localCamerSearcher;
    NSTimer *searchLocalCamareTimer;
}

@property (nonatomic ,strong)SmartClass       *smartconfig;
@property (nonatomic ,strong)NSString         *infoString;
@property (nonatomic ,strong)SmartLink        *smart;
@property (weak, nonatomic) IBOutlet UILabel  *scanThreeViewTipsLabel;
@property (weak, nonatomic) IBOutlet UIButton *redLightButton;
@property (nonatomic ,strong)NetSDK           *netSDK;


@end

@implementation ScanThreeViewController



- (void)viewDidLoad {
    [super viewDidLoad];

    self.title =DPLocalizedString(@"Qrcode_ScanThreeView");
    self.scanThreeViewTipsLabel.text = DPLocalizedString(@"Qrcode_scanThreeViewTipsLabel");
    [self.redLightButton setTitle:DPLocalizedString(@"Qrcode_redLightButton")
                         forState:UIControlStateNormal];
    
    SmartLinkModel * model = [[SmartLinkModel alloc]init];
    model.devUid = self.UID;
    _smart = [[SmartLink alloc]initWithSmartModel:model];
    _smart.delegate=self;
    _netSDK= [NetSDK sharedInstance];
    [_smart startSearchLocalCamre];
    
    [self addBackBtn];
}

-(void)addBackBtn
{
    EnlargeClickButton *backButton = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(0, 0, 70, 40);
    backButton.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 50);
    [backButton setImage:[UIImage imageNamed:@"addev_back"] forState:UIControlStateNormal];
    //    [backButton setImage:[UIImage imageNamed:@"POEback_btn_pressed.png"] forState:UIControlStateHighlighted];
    [backButton addTarget:self action:@selector(backToPreView) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    temporaryBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.leftBarButtonItem = temporaryBarButtonItem;
}

-(void)backToPreView{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)RedLightBtn:(id)sender
{
    [self showTipsView];
}

- (void)showTipsView
{
    
    if (self.scanType == scanTypeWiFiSetting) {
        //wifi设置
        
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CustomView" owner:self options:nil];
        UIView *tmpContentView = [nib objectAtIndex:3];
        tmpContentView.layer.cornerRadius=12;
        UILabel *tipTitle = (UILabel    *)[tmpContentView viewWithTag:4000];
//        UILabel *errLabel = (UILabel    *)[tmpContentView viewWithTag:4003];
        UITextView * view = (UITextView *)[tmpContentView viewWithTag:4001];
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = 8;// 字体的行间距
        
        NSDictionary *attributes = @{
                                     NSFontAttributeName:[UIFont systemFontOfSize:14],
                                     NSParagraphStyleAttributeName:paragraphStyle
                                     };
        view.attributedText = [[NSAttributedString alloc]
                               initWithString:DPLocalizedString(@"Configure_show_tip")
                               attributes:attributes];
        
        UIButton *WifiButton = (UIButton *)[tmpContentView viewWithTag:4002];
        UIButton *IpcButton  = (UIButton *)[tmpContentView viewWithTag:4004];
        [WifiButton addTarget:self
                       action:@selector(returnWifi:)
             forControlEvents:UIControlEventTouchUpInside];
        
        [IpcButton  addTarget:self
                       action:@selector(returnIpc:)
             forControlEvents:UIControlEventTouchUpInside];
        
        tipTitle.text = DPLocalizedString(@"Configure_show_tip2");
//        errLabel.text = DPLocalizedString(@"Configure_show_tip3");
        [WifiButton setTitle:DPLocalizedString(@"Configure_back")
                    forState:UIControlStateNormal];
        [IpcButton  setTitle:DPLocalizedString([self rootIsAddDevVC]?@"Configure_add":@"Configure_BackToDevListVC")
                    forState:UIControlStateNormal];
        customWindow = [[CustomWindow alloc]initWithView:tmpContentView];
        [customWindow show];
    }
    else{
        
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CustomView" owner:self options:nil];
        UIView *tmpContentView = [nib objectAtIndex:2];
        tmpContentView.layer.cornerRadius=12;
        UILabel *tipTitle = (UILabel    *)[tmpContentView viewWithTag:4000];
        UILabel *errLabel = (UILabel    *)[tmpContentView viewWithTag:4003];
        UITextView * view = (UITextView *)[tmpContentView viewWithTag:4001];
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = 8;// 字体的行间距
        
        NSDictionary *attributes = @{
                                     NSFontAttributeName:[UIFont systemFontOfSize:14],
                                     NSParagraphStyleAttributeName:paragraphStyle
                                     };
        view.attributedText = [[NSAttributedString alloc]
                               initWithString:DPLocalizedString(@"Configure_show_tip")
                               attributes:attributes];
        
        UIButton *WifiButton = (UIButton *)[tmpContentView viewWithTag:4002];
        UIButton *IpcButton  = (UIButton *)[tmpContentView viewWithTag:4004];
        [WifiButton addTarget:self
                       action:@selector(returnWifi:)
             forControlEvents:UIControlEventTouchUpInside];
        
        [IpcButton  addTarget:self
                       action:@selector(returnIpc:)
             forControlEvents:UIControlEventTouchUpInside];
        
        tipTitle.text = DPLocalizedString(@"Configure_show_tip2");
        errLabel.text = DPLocalizedString(@"Configure_show_tip3");
        [WifiButton setTitle:DPLocalizedString(@"Configure_back")
                    forState:UIControlStateNormal];
        [IpcButton  setTitle:DPLocalizedString([self rootIsAddDevVC]?@"Configure_add":@"Configure_BackToDevListVC")
                    forState:UIControlStateNormal];
        customWindow = [[CustomWindow alloc]initWithView:tmpContentView];
        [customWindow show];
    }
    
    
    
}

-(BOOL)rootIsAddDevVC{

    for (UIViewController * controller in self.navigationController.viewControllers) {
        if ([controller isKindOfClass:[AddDeviceViewController class]]) {
            return YES;
        }
    }
    return NO;
}

-(void)returnWifi:(id)sender
{
    UIViewController *target = nil;
    for (UIViewController * controller in self.navigationController.viewControllers) {
        if ([controller isKindOfClass:[AddDeviceViewController class]]||
            [controller isKindOfClass:[QrcodeSetingViewController class]] || [controller isKindOfClass:[WiFiSettingConnectWiFiVC class]]) {
            target = controller;
        }
    }
    if (target) {
        [self.navigationController popToViewController:target animated:NO];
    }
}

-(void)returnIpc:(id)sender
{
    UIViewController *target = nil;
    for (UIViewController * controller in self.navigationController.viewControllers) {
        if ([controller isKindOfClass:[AddDeviceViewController class]]||
            [controller isKindOfClass:[DeviceListViewController class]]) {
            target = controller;
        }
    }
    if (target) {
        [self.navigationController popToViewController:target animated:NO]; //跳转
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [SVProgressHUD dismiss];
    [_smart destroySearchTimer];
}


//开始搜索
- (void)startSmartLink
{
    NSLog(@"smartlink  正在连接");
}

//搜索超时
- (void)SmartLinkFailure
{
    NSLog(@"smartlink  失败");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showTipsView];
    });
}

//搜索成功
- (void)SmartLinkSuccessful
{
    
    NSLog(@"smartlink  成功");
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([self rootIsAddDevVC]) {
            [self bind];
        }else{
            [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Configure_success")];
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    });
}

- (void)bind
{
    NSString *password = @"goscam123";
    CBS_BindRequest *req = [CBS_BindRequest new];
    BodyBindRequest *body = [BodyBindRequest new];
    body.DeviceId = _UID;
    body.DeviceName = _devName;
    body.DeviceType = self.deviceType;
//    switch (_deviceType) {
//        case DeviceQR_Zhong:
//            body.DeviceType = 1;
//            break;
//        case DeviceQR_NVR:
//            body.DeviceType = 2;
//            break;
//        case DeviceQR_360:
//            body.DeviceType = 3;
//            break;
//        default:
//            body.DeviceType = 1;
//            break;
//    }
    body.DeviceOwner = 1;
    body.AreaId  = @"";
    body.StreamUser = @"admin";
    body.UserName = [SaveDataModel getUserName];
    body.StreamPassword = password;
    [SVProgressHUD showWithStatus:@"loading....."];
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [_netSDK net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:30000 responseBlock:^(int result, NSDictionary *dict) {
            if (result !=0) {
                dispatch_async(dispatch_get_main_queue(),^{
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
                });
            }
            else 
            if ([dict[@"MessageType"]isEqualToString:@"BindSmartDeviceResponse"]) {
                if (result == 0) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSNotification *notification =[NSNotification notificationWithName:REFRESH_DEV_LIST_NOTIFY object:nil];
                        [[NSNotificationCenter defaultCenter] postNotification:notification];
                        
                        [UIView animateWithDuration:3 animations:^{
                            [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Configure_success")];
                            
                        } completion:^(BOOL finished) {
                            for (UIViewController *controller in self.navigationController.viewControllers) {
                                if ([controller isKindOfClass:[DeviceListViewController class]]) {
                                    [weakSelf.navigationController popToViewController:controller animated:NO];
                                }
                            }
                        }];
                    });
                }
                else
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [SVProgressHUD showErrorWithStatus:@"添加失败"];
                         [self showTipsView];
                    });
                }

            }

        }];
    });
}


- (BOOL)shouldAutorotate {
    return NO;
}
- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;;
}



@end
