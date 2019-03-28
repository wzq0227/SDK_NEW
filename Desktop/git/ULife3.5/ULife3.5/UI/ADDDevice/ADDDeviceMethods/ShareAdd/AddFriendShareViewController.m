//
//  AddFriendShareViewController.m
//  goscamapp
//
//  Created by goscam_sz on 17/4/26.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "AddFriendShareViewController.h"
#import "QRCodeReaderViewController.h"
#import "SVProgressHUD.h"
#import "Header.h"
#import "ResolveModel.h"
#import "CBSCommand.h"
#import "SaveDataModel.h"
#import "NetSDK.h"
#import "DeviceListViewController.h"
#import "ParseQRResult.h"

@interface AddFriendShareViewController ()<QRCodeReaderDelegate, ParseQRResultDelegate>

@property(nonatomic,strong)QRCodeReaderViewController *reader;

@property(nonatomic,strong) NetSDK *netSDK;

@end

@implementation AddFriendShareViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UITapGestureRecognizer *tap =[[UITapGestureRecognizer alloc]initWithTarget:self     action:@selector(tapAction)];
    //配置属性
    //轻拍次数
    tap.numberOfTapsRequired =1;
    //轻拍手指个数
    tap.numberOfTouchesRequired =1;
    //讲手势添加到指定的视图上
    [self.showimageview addGestureRecognizer:tap];
    
    BOOL ret = [SaveDataModel getFriendAddState];
    if (ret) {
        self.showimageview.hidden=YES;
    }
    else{
        self.showimageview.hidden=NO;
    }
    
    self.title=DPLocalizedString(@"ADDDevice");
    self.MyDeviceIdTextField.placeholder=DPLocalizedString(@"ADDDevice_scan");
    _netSDK= [NetSDK sharedInstance];
    self.idView.layer.borderColor=[UIColor lightGrayColor].CGColor;
    self.idView.layer.borderWidth=1;
    self.idView.layer.masksToBounds=YES;
    
    self.scanTipLabel.text = DPLocalizedString(@"ADDDevice_ShareQrCodeScanTip");
    
    [self.nextBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.nextBtn setTitle:DPLocalizedString(@"ADDDevice_Next") forState:UIControlStateNormal];
    [self.nextBtn setBackgroundColor:myColor];
    self.nextBtn.layer.cornerRadius=20;
    self.nextBtn.hidden = YES;
}

- (void)tapAction
{
    [self ScanQrCode:nil];
    [SaveDataModel SaveFriendAddevice:YES];
    self.showimageview.hidden=YES;
}

#pragma mark 扫描二维码
- (IBAction)ScanQrCode:(id)sender {
    [SaveDataModel SaveFriendAddevice:YES];
    self.showimageview.hidden=YES;
    if ([self initCodeReader]) {
        if ([QRCodeReader supportsMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]]) {
            //            [self presentViewController:self.reader animated:YES completion:NULL];
            [self.navigationController pushViewController:self.reader animated:NO];
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:DPLocalizedString(@"ADDDevice_Error") message:DPLocalizedString(@"ADDDevice_Reader_not_supported_by_the_current_device") delegate:nil cancelButtonTitle:DPLocalizedString(@"ADDDevice_OK") otherButtonTitles:nil];
            [alert show];
        }
    }
}

-(BOOL)initCodeReader
{
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    
    if (self.reader == nil) {
        self.reader = [QRCodeReaderViewController new];
        self.reader.delegate = self;
    }
    return YES;
}

#pragma mark 解析二维码
#pragma mark 解析二维码
- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result
{
    [ParseQRResult shareQRParser].delegate = self;
    [[ParseQRResult shareQRParser] parseWithQRString:result
                                       addDeviceType:AddDeviceByShare];
    
    return;
    
    
//    ResolveModel * md = [[ResolveModel alloc]initWithResolveString:result];
//    NSString * str = [md getDevUid:FriendAdd];
//    _deviceType = md.devtype;
//
// 
//    if (![str isEqualToString:@""]) {
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [SVProgressHUD showWithStatus:DPLocalizedString(@"Loading")];
//            [self findDevciceState:str];
//        });
//    }
//    else{
//        dispatch_async(dispatch_get_main_queue(), ^{
//             [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_sqr_erro")];
//        });
//    }
//    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark -- ParseQRResultDelegate
- (void)isParseSuccess:(BOOL)isSuccess
         smartConStyle:(SmartConnectStyle)smartConStyle
              deviceId:(NSString *)deviceId
            deviceType:(GosDeviceType)deviceType
            qrCodeType:(QRCodeGenerateStyle)qrCodeType
            isHaveEthernet:(BOOL)isHaveEthernet
     
{
    if (NO == isSuccess)
    {
        NSLog(@"分享 添加扫码失败：deviceId = %@, deviceType = %ld", deviceId, (long)deviceType);
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_sqr_erro")];
            [self.navigationController popViewControllerAnimated:YES];
        });
    }
    else
    {
        NSLog(@"分享 添加扫码成功：deviceId = %@, deviceType = %ld", deviceId, (long)deviceType);
        self.deviceType = deviceType;
        [self findDevciceState:deviceId];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [SVProgressHUD showWithStatus:DPLocalizedString(@"Loading")];
            [self.navigationController popViewControllerAnimated:YES];
        });
    }
}


#pragma mark 从CBS查询设备是否被绑定
-(void)findDevciceState:(NSString*)UID
{
    
    __weak typeof(self) weakSelf = self;
    
    CBS_QueryBindRequest *req = [CBS_QueryBindRequest new];
    BodyQueryBindRequest *body = [BodyQueryBindRequest new];
    body.DeviceId = UID;
    body.UserName = [SaveDataModel getUserName];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [_netSDK net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:5000 responseBlock:^(int result, NSDictionary *dict) {
            
            if(result == -10095){
                dispatch_async(dispatch_get_main_queue(),^{
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_Device_Not_Exist")];
                    weakSelf.MyDeviceIdTextField.text=@"";
                });
            }
            else if (result !=0) {
                dispatch_async(dispatch_get_main_queue(),^{
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
                });
            }
            else {
                
                NSString * ret = dict[@"Body"][@"BindStatus"];
                
                switch (ret.integerValue)
                {
                        
                    case 0:   // 未绑定IROUTER_DEVICE_BIND_NOEXIST
                    {
                        
                        dispatch_async(dispatch_get_main_queue(),^{
                            
                            [SVProgressHUD dismiss];
                            weakSelf.MyDeviceIdTextField.text=UID;
                            [weakSelf next:nil];
                        });
                    }
                        break;
                        
                    case 1:    // 已被本账号以拥有方式绑定 IROUTER_DEVICE_BIND_DUPLICATED
                    {
                        dispatch_async(dispatch_get_main_queue(),^{
                            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_we_bind")];
                            weakSelf.MyDeviceIdTextField.text=@"";
                        });
                    }
                        break;
                    case 2:    // 已被本账号以分享方式绑定
                    {
                        dispatch_async(dispatch_get_main_queue(),^{
                            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_Already_Added")];
                            weakSelf.MyDeviceIdTextField.text=@"";
                        });
                    }
                        break;
                        
                    case 3:     // 被其他账号绑定 IROUTER_DEVICE_BIND_INUSE
                    {
                        dispatch_async(dispatch_get_main_queue(),^{
                            
                            [SVProgressHUD dismiss];
                            weakSelf.MyDeviceIdTextField.text=UID;
                            [weakSelf next:nil];
                        });
                    }
                        break;
                    default:
                        dispatch_async(dispatch_get_main_queue(),^{
                             [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
                        });
                        break;
                }
            }
        }];
    });
}


#pragma mark 扫描“chancel”回调
- (void)readerDidCancel:(QRCodeReaderViewController *)reader
{
    [self.navigationController popViewControllerAnimated:NO];
}

- (int)getDeviceTypeWithUID:(NSString*)uid{
    int devType = 1;
    NSString *typeStr = [uid substringWithRange:NSMakeRange(3, 2)];
    if ([typeStr isEqualToString:@"66"]) { //1 IPC 2 NVR 3 VR360
        devType = 3;
    }else if ([typeStr isEqualToString:@"E6"]){
        devType = 2;
    }else{
        devType =1;
    }
    return devType;
}

#pragma mark 跳转下个界面
- (IBAction)next:(id)sender {
    
    NSString *password = @"goscam123";
    CBS_BindRequest *req = [CBS_BindRequest new];
    BodyBindRequest *body = [BodyBindRequest new];
    body.DeviceId = _MyDeviceIdTextField.text;
    body.DeviceName = @"";
    body.DeviceType = self.deviceType;
    body.DeviceOwner = 0;
    body.AreaId  = @"000001";
    body.StreamUser = @"admin";
    body.UserName = [SaveDataModel getUserName];
    body.StreamPassword = password;
    [SVProgressHUD showWithStatus:@"loading....."];
    
    if ([body.DeviceId hasPrefix:@"A"]) {
        
        if ( isENVersionNew) {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"DeviceSupportEN")];
            self.MyDeviceIdTextField.text = @"";
            //中文版
            return;
        }
  
    }
    else if ([body.DeviceId hasPrefix:@"Z"]){
        //英文版
        if (! isENVersionNew) {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"DeviceSupportCN")];
            self.MyDeviceIdTextField.text = @"";
            //中文版
            return;
        }
    }
    else{
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"DeviceSupportNO")];
        self.MyDeviceIdTextField.text = @"";
        //不支持
        return;
    }
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [_netSDK net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:10000 responseBlock:^(int result, NSDictionary *dict) {
            
            if(result == -10095){
                dispatch_async(dispatch_get_main_queue(),^{
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_Device_Not_Exist")];
                });
            }
            else if (result !=0) {
                dispatch_async(dispatch_get_main_queue(),^{
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
                });
            }
            else{
                if (result == 0) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSNotification *notification =[NSNotification notificationWithName:REFRESH_DEV_LIST_NOTIFY object:nil];
                        [[NSNotificationCenter defaultCenter] postNotification:notification];
                        
                        
                        [UIView animateWithDuration:0.1 animations:^{
                            [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Configure_success")];
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
                    });
                }            
            }
        }];
    });
}

@end
