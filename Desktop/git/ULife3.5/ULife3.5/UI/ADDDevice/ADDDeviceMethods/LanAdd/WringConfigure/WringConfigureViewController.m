//
//  WringConfigureViewController.m
//  ULife3.5
//
//  Created by goscam_sz on 2017/6/8.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "WringConfigureViewController.h"
#import "Header.h"
#import "SmartLink.h"
#import "NetSDK.h"
#import "CBSCommand.h"
#import "SaveDataModel.h"
#import "DeviceListViewController.h"

@interface WringConfigureViewController ()<UISmartLinkDelegate>
@property (weak, nonatomic) IBOutlet UILabel *noticeLabel;

@property (nonatomic,strong) SmartLink * smart;

@property (nonatomic,strong) NetSDK * netSDK;

@end

@implementation WringConfigureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self setUI];
    SmartLinkModel * md = [[SmartLinkModel alloc]init];
    md.devUid = self.deviceID;
    _smart = [[SmartLink alloc]initWithSmartModel:md];
    _smart.delegate=self;
    _netSDK = [NetSDK sharedInstance];
    [_smart startSearchLocalCamre];
}

- (void)setUI
{
    self.title = DPLocalizedString(@"WireAdd_AddDeviceID");
    [self.nextTbn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.nextTbn setTitle:DPLocalizedString(@"WireAdd_Reconnect") forState:UIControlStateNormal];
    [self.nextTbn setBackgroundImage:[self imageWithColor:myLightColor] forState:(UIControlStateNormal)];
    self.nextTbn.layer.cornerRadius=20;
    self.nextTbn.userInteractionEnabled=NO;
   
     self.tiltleLabel.text=DPLocalizedString(@"WiFi_wait");
    self.noticeLabel.text = DPLocalizedString(@"Lan_Notice");
}

//[btn setBackgroundImage:[self imageWithColor:[UIColor redColor]] forState:(UIControlStateNormal)];
//[btn setBackgroundImage:[self imageWithColor:[UIColor yellowColor]] forState:(UIControlStateHighlighted)];

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


//开始搜索
- (void)startSmartLink
{
    NSLog(@"smartlink  正在连接");
    _nextTbn.userInteractionEnabled=NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showWithStatus:@"loading..."];
    });
}

//搜索超时
- (void)SmartLinkFailure
{
    NSLog(@"smartlink  失败");
    _nextTbn.userInteractionEnabled=YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_WireAdd_Error")];
        self.nextTbn.userInteractionEnabled=YES;
        [self.nextTbn  setBackgroundImage:[self imageWithColor:myClickColor] forState:(UIControlStateNormal)];
        [SVProgressHUD dismissWithDelay:2];
    });
}

//搜索成功
- (void)SmartLinkSuccessful
{
    NSLog(@"smartlink  成功");
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showWithStatus:DPLocalizedString(@"WireAdd_Succeeded")];
        [self BindDevice];
    });
}

- (void)BindDevice
{
    NSString *password = @"goscam123";
    CBS_BindRequest *req = [CBS_BindRequest new];
    BodyBindRequest *body = [BodyBindRequest new];
    body.DeviceId = _deviceID;
    body.DeviceName = self.deviceName;
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
    body.AreaId  = @"000001";
    body.StreamUser = @"admin";
    body.UserName = [SaveDataModel getUserName];
    body.StreamPassword = password;
    [SVProgressHUD showWithStatus:@"loading....."];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [_netSDK net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:10000 responseBlock:^(int result, NSDictionary *dict) {
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
                        
                        
                        [UIView animateWithDuration:0.1 animations:^{
                            [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"WireAdd_AddSucceeded")];
                        } completion:^(BOOL finished) {
                            for (UIViewController *controller in self.navigationController.viewControllers) {
                                if ([controller isKindOfClass:[DeviceListViewController class]]) {
                                    [self.navigationController popToViewController:controller animated:NO];
                                }
                            }
                        }];
                    });
                }
                else
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_addFailed")];
                        self.nextTbn.userInteractionEnabled=YES;
                        [self.nextTbn  setBackgroundImage:[self imageWithColor:myClickColor] forState:(UIControlStateNormal)];
                    });
                }
            }
        }];
    });
}

- (IBAction)next:(id)sender {
    self.nextTbn.userInteractionEnabled=NO;
    [self.nextTbn setBackgroundImage:[self imageWithColor:myLightColor] forState:(UIControlStateNormal)];
    [_smart startSearchLocalCamre];
}

-(void)viewWillAppear:(BOOL)animated
{
    NSLog(@"网线连接  设备UID ============ %@",self.deviceID);
}

-(void)viewWillDisappear:(BOOL)animated
{
    [SVProgressHUD dismiss];
    [_smart destroySearchTimer];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}
@end
