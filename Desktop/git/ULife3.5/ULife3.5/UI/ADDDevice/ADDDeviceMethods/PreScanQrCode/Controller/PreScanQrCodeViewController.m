//
//  PreScanQrCodeViewController.m
//  ULife3.5
//
//  Created by Goscam on 2017/10/9.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "PreScanQrCodeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "QRCodeReaderViewController.h"
#import "SVProgressHUD.h"
#import "qrcode_tools.h"
#import "QrcodeSetingViewController.h"
#import "Header.h"
#import "ResolveModel.h"
#import "SaveDataModel.h"
#import "NetSDK.h"
#import "CBSCommand.h"
#import "DeviceNameSettingViewController.h"
#import "DeviceManagement.h"
#import "AddDeviceViewController.h"
#import "UIColor+YYAdd.h"
#import "ParseQRResult.h"

@interface PreScanQrCodeViewController ()<QRCodeReaderDelegate,UITextFieldDelegate, ParseQRResultDelegate>
{
    SmartConnectStyle smartStyle; //smart 方式
    BOOL cIsRawID;  //是否是裸ID
}
@property (nonatomic,assign) GosDeviceType devtype;

@property(nonatomic,strong)QRCodeReaderViewController *reader;

@property (assign, nonatomic)  QRCodeGenerateStyle qrCodeType;

@property(nonatomic,strong)NetSDK * netSDK;

@property(nonatomic,assign)BOOL isHaveCamera;

@property (nonatomic,assign)BOOL isHasEnthnet; //是否支持网卡

@property (strong, nonatomic) IBOutlet UILabel *HeadLabel;
@property (strong, nonatomic) IBOutlet UILabel *DeviceName;

@end

@implementation PreScanQrCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self configUI];
    
    [self setupModel];
    
    [self addActions];
}

- (void)configUI{
    
    [self configView];
}

- (void)configView{
    
    self.title=DPLocalizedString(@"ADDDevice");

    self.HeadLabel.text= DPLocalizedString(@"ADDDevice_PreScanQrCodeTip");
    self.DeviceName.text = DPLocalizedString(@"ADDDevice_DeviceName");
    self.MyDeviceName.delegate=self;
    self.MyDeviceIdTextField.placeholder=DPLocalizedString(@"ADDDevice_scan");
    
    self.idView.layer.borderColor=[UIColor lightGrayColor].CGColor;
    self.idView.layer.borderWidth=1;
    self.idView.layer.masksToBounds=YES;
    
    self.deviceView.layer.borderColor=[UIColor lightGrayColor].CGColor;
    self.deviceView.layer.borderWidth=1;
    self.deviceView.layer.masksToBounds=YES;
    
    [self getDeviceName];
    [self.nextBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.nextBtn setTitle:DPLocalizedString(@"Qrcode_Title_Confirm") forState:UIControlStateNormal];
    [self.nextBtn setBackgroundColor:myColor];
    self.nextBtn.layer.cornerRadius=20;
}


- (void)setupModel{
    self.netSDK= [NetSDK sharedInstance];
}

- (void)addActions{
    [self.nextBtn addTarget:self action:@selector(next:) forControlEvents:UIControlEventTouchUpInside];
    UITapGestureRecognizer *tap =[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction)];
    tap.numberOfTapsRequired =1;
    tap.numberOfTouchesRequired =1;
    [self.showImage addGestureRecognizer:tap];
    BOOL ret = [SaveDataModel getScanQraddState];
    if (ret) {
        self.showImage.hidden=YES;
    }
    else{
        self.showImage.hidden=NO;
    }
    //    [self. addTarget:self action:@selector(next:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)tapAction
{
    [self ScanQrCode:nil];
    [SaveDataModel SaveScanQrAddevice:YES];
    self.showImage.hidden=YES;
}

- (void)getDeviceName
{
    _isHaveCamera=NO;
    NSMutableArray * MaxArr =  [[NSMutableArray alloc]init];
    NSMutableArray * arr    =  [[DeviceManagement sharedInstance]deviceListArray];
    for ( DeviceDataModel  * md  in arr ) {
        if (md.DeviceName.length>6) {
            NSString * str =[md.DeviceName  substringToIndex:6];
            NSLog(@"前面 6 位  ：%@",str);
            if ([str isEqualToString:@"Camera"]) {
                NSString * numberStr = [md.DeviceName substringFromIndex:6];
                NSLog(@"后面的 %@",numberStr);
                numberStr = [NSString stringWithFormat:@"%d",[numberStr intValue]];
                
                if ([self deptNumInputShouldNumber:numberStr]){
                    [MaxArr addObject:numberStr];
                }
            }
        }
        else if (md.DeviceName.length == 6){
            if ([md.DeviceName isEqualToString:@"Camera"]) {
                _isHaveCamera=YES;
            }
        }
    }
    NSArray *result = [MaxArr sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        NSLog(@"%@~%@",obj1,obj2);
        
        return [obj1 compare:obj2]; //升序
        
    }];
    
    NSLog(@"result=%@",result);
    if (result.count==0){
        if (_isHaveCamera ) {
            self.MyDeviceName.text=[NSString stringWithFormat:@"%@1",DPLocalizedString(@"ADDDevice_devName")];;
        }
        else{
            self.MyDeviceName.text=DPLocalizedString(@"ADDDevice_devName");
        }
    }
    else{
        self.MyDeviceName.text =[NSString stringWithFormat:@"%@%d",DPLocalizedString(@"ADDDevice_devName"),[result[result.count-1] intValue]+1];
    }
}

- (BOOL) deptNumInputShouldNumber:(NSString *)str   //判断是否为数字组成
{
    NSString *regex = @"[0-9]*";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
    if ([pred evaluateWithObject:str]) {
        return YES;
    }
    return NO;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    DeviceNameSettingViewController * view = [[DeviceNameSettingViewController alloc]init];
    DeviceDataModel  * md = [[DeviceDataModel alloc]init];
    md.DeviceName =textField.text;
    view.model = md;
    
    [view didChangeDevNameCallback:^(NSString *name) {
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _MyDeviceName.text = name;
            [self.navigationController popViewControllerAnimated:NO];
        });
    }];
    
    [self.navigationController pushViewController:view animated:NO];
    
    return NO;
}


#pragma mark 扫描二维码
- (IBAction)ScanQrCode:(id)sender {
    [SaveDataModel SaveScanQrAddevice:YES];
    self.showImage.hidden=YES;
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

#pragma mark -- 二维码解析 delegate
- (void)isParseSuccess:(BOOL)isSuccess
         smartConStyle:(SmartConnectStyle)smartConStyle
              deviceId:(NSString *)deviceId
            deviceType:(GosDeviceType)deviceType
            qrCodeType:(QRCodeGenerateStyle)qrCodeType
        isHaveEthernet:(BOOL)isHaveEthernet
     
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_sqr_erro")];
        [self.navigationController popViewControllerAnimated:YES];
    });
    if (NO == isSuccess)
    {
        NSLog(@"扫码 添加扫码失败：deviceId = %@, deviceType = %ld", deviceId, (long)deviceType);
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_sqr_erro")];
    }
    else
    {
        NSLog(@"扫码 添加扫码成功：deviceId = %@, deviceType = %ld smartStyle=%ld", deviceId, (long)deviceType,(long)smartConStyle);
        smartStyle   = smartConStyle;
        self.devtype = deviceType;
        self.qrCodeType = qrCodeType;
        self.isHasEnthnet = isHaveEthernet;
        [SVProgressHUD showWithStatus:DPLocalizedString(@"Loading")];
        if (self.qrCodeType == QRCodeGenerateByShare) {
            //如果是好友分享，直接添加好友分享
            [self AddSharefindDevciceState:deviceId];
        }
        else{
            [self findDevciceState:deviceId];//@"A9996100BJ4XF655ZV35RWFF111A"
        }
    }
}


#pragma mark 从CBS查询设备是否被绑定
-(void)AddSharefindDevciceState:(NSString*)UID
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
            else
            if (result !=0) {
                dispatch_async(dispatch_get_main_queue(),^{
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
                });
            }
            else
            if ([dict[@"MessageType"]isEqualToString:@"QueryDeviceBindResponse"]) {
                
                NSString * ret = dict[@"Body"][@"BindStatus"];
                
                switch (ret.integerValue)
                {
                        
                    case 0:   // 未绑定IROUTER_DEVICE_BIND_NOEXIST
                    {
                        
                        dispatch_async(dispatch_get_main_queue(),^{
                            
                            [SVProgressHUD dismiss];
                            weakSelf.MyDeviceIdTextField.text=UID;
                            [weakSelf addFriendShareNext:nil];
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
                            [weakSelf addFriendShareNext:nil];
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


- (void)addFriendShareNext:(id)sender {
    
    NSString *password = @"goscam123";
    CBS_BindRequest *req = [CBS_BindRequest new];
    BodyBindRequest *body = [BodyBindRequest new];
    body.DeviceId = _MyDeviceIdTextField.text;
    body.DeviceName = @"";
    body.DeviceType = self.devtype;// [self getDeviceTypeWithUID: body.DeviceId];
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
                            [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Configure_success")];
                        } completion:^(BOOL finished) {
                             [self.navigationController popViewControllerAnimated:NO];
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
            if (result !=0) {
                dispatch_async(dispatch_get_main_queue(),^{
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
                });
            }
            else 
            if ([dict[@"MessageType"]isEqualToString:@"QueryDeviceBindResponse"]) {
                NSString * ret = dict[@"Body"][@"BindStatus"];
                
                switch (ret.integerValue)
                {
                        
                    case 0:   // 未绑定IROUTER_DEVICE_BIND_NOEXIST
                    {
                        dispatch_async(dispatch_get_main_queue(),^{
                            
                            if ([UID hasPrefix:@"A"]) {
                                
                                if ( isENVersionNew) {
                                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"DeviceSupportEN")];
                                    //中文版
                                    return;
                                }
                                
                            }
                            else if ([UID hasPrefix:@"Z"]){
                                //英文版
                                if (! isENVersionNew) {
                                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"DeviceSupportCN")];
                                    //中文版
                                    return;
                                }
                            }
                            else{
                                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"DeviceSupportNO")];
                                //不支持
                                return;
                            }
                            
                            [SVProgressHUD dismissWithDelay:1];
                            weakSelf.MyDeviceIdTextField.text=UID;
                            
                        });
                    }
                        break;
                        
                    case 1:    // 已被本账号以拥有方式绑定 IROUTER_DEVICE_BIND_DUPLICATED
                    {
                        dispatch_async(dispatch_get_main_queue(),^{
                            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_we_bind")];
                            weakSelf.MyDeviceIdTextField.text= @"";
                            //                        [weakSelf.navigationController popViewControllerAnimated:YES];
                        });
                    }
                        break;
                        
                    case 2:    // 已被本账号以分享方式绑定 DeviceShareBind IROUTER_DEVICE_BIND_DUPLICATED
                    {
                        dispatch_async(dispatch_get_main_queue(),^{
                            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_Already_Added")];
                            weakSelf.MyDeviceIdTextField.text=@"";
                            //                        [weakSelf.navigationController popViewControllerAnimated:YES];
                        });
                    }
                        break;
                        
                    case 3:     // 被其他账号绑定 IROUTER_DEVICE_BIND_INUSE
                    {
                        dispatch_async(dispatch_get_main_queue(),^{
                            if (self.qrCodeType == QRCodeGenerateByShare){
                                [SVProgressHUD dismissWithDelay:1];
                                weakSelf.MyDeviceIdTextField.text = UID;
                            }
                            else{
                                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_other_bind")];
                                weakSelf.MyDeviceIdTextField.text= @"";//;
                            }
//                     [weakSelf.navigationController popViewControllerAnimated:YES];
                        });
                    }
                        break;
                        
                    default:
                        dispatch_async(dispatch_get_main_queue(),^{
                            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];                            //                         [weakSelf.navigationController popViewControllerAnimated:YES];
                        });
                        break;
                }
            }else if (!dict){
                dispatch_async(dispatch_get_main_queue(),^{
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
                });
            }
        }];
    });
}

#pragma mark 解析二维码
- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result
{
    [ParseQRResult shareQRParser].delegate = self;
    [[ParseQRResult shareQRParser] parseWithQRString:result
                                       addDeviceType:AddDeviceByAll];
}

#pragma mark 扫描“chancel”回调
- (void)readerDidCancel:(QRCodeReaderViewController *)reader
{
    [self.navigationController popViewControllerAnimated:NO];
}

#pragma mark 跳转下个界面
- (IBAction)next:(id)sender {

    if (_MyDeviceIdTextField.text.length>0 && _MyDeviceName.text.length>0) {
        
        DeviceDataModel *model = [DeviceDataModel new];
        model.DeviceId         = _MyDeviceIdTextField.text;//@"A9996100BJ4XF655ZV35RWFF111A"
        model.DeviceName       = _MyDeviceName.text;
        model.DeviceType       = self.devtype;//GosDeviceIPC
        model.smartStyle       = smartStyle;//16
        model.isHasEnthnet     = self.isHasEnthnet;
        
        AddDeviceViewController * vc = [[AddDeviceViewController alloc]init];
        vc.devModel= model;
        
        [self.navigationController pushViewController:vc animated:NO];
    }
    else{
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_id_unull")];
    }
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
