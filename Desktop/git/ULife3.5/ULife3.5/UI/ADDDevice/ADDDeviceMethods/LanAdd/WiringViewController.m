//
//  WiringViewController.m
//  goscamapp
//
//  Created by goscam_sz on 17/4/26.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "WiringViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "QRCodeReaderViewController.h"
#import "SVProgressHUD.h"
#import "Header.h"
#import "ResolveModel.h"
#import "WringConfigureViewController.h"
#import "SaveDataModel.h"
#import "CBSCommand.h"
#import "NetSDK.h"
#import "DeviceNameSettingViewController.h"
#import "DeviceManagement.h"
#import "ParseQRResult.h"


@interface WiringViewController () <QRCodeReaderDelegate,UITextFieldDelegate,ParseQRResultDelegate>

@property (nonatomic,assign) GosDeviceType   devtype;

@property(nonatomic,strong)QRCodeReaderViewController *reader;

@property(nonatomic,strong)NetSDK *netSDK;

@property(nonatomic,assign)BOOL isHaveCamera;

@end

@implementation WiringViewController

{
    int smartFlag; //smart 方式
    BOOL cIsRawID;  //是否是裸ID
}

- (void)viewWillAppear:(BOOL)animated
{
   
}

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
    
    BOOL ret = [SaveDataModel getWringAddState];
    if (ret) {
        self.showimageview.hidden=YES;
    }
    else{
        self.showimageview.hidden=NO;
    }
    
    self.title=DPLocalizedString(@"ADDDevice");
    self.MyDeviceName.delegate=self;
    
    self.deviceName.text = DPLocalizedString(@"ADDDevice_DeviceName");
    self.MyDeviceIdTextField.placeholder=DPLocalizedString(@"ADDDevice_scan");
    self.netSDK = [NetSDK sharedInstance];
    self.idView.layer.borderColor=[UIColor lightGrayColor].CGColor;
    self.idView.layer.borderWidth=1;
    self.idView.layer.masksToBounds=YES;
    
    self.deviceView.layer.borderColor=[UIColor lightGrayColor].CGColor;
    self.deviceView.layer.borderWidth=1;
    self.deviceView.layer.masksToBounds=YES;
    
    self.tipsLabel.text = DPLocalizedString(@"WireAdd_Tips_Add_new");
    
    [self getDeviceName];
    [self.nextBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.nextBtn setTitle:DPLocalizedString(@"ADDDevice_Next") forState:UIControlStateNormal];
    [self.nextBtn setBackgroundColor:myColor];
    self.nextBtn.layer.cornerRadius=20;
}

- (void)tapAction
{
    [self ScanQrCode:nil];
    [SaveDataModel SaveWringAddevice:YES];
    self.showimageview.hidden=YES;
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
        self.MyDeviceName.text =[NSString stringWithFormat:@"Camera%d",[result[result.count-1] intValue]+1];
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
        
        self.MyDeviceName.text = name;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:NO];
        });
    }];
    
    [self.navigationController pushViewController:view animated:NO];
    
    return NO;
}

#pragma mark 扫描二维码
- (IBAction)ScanQrCode:(id)sender {
    [SaveDataModel SaveWringAddevice:YES];
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
                                       addDeviceType:AddDeviceByWLAN];
    
    return;
//    ResolveModel * md = [[ResolveModel alloc]initWithResolveString:result];
//    NSString * str = [md getDevUid:WifiAdd];
//    smartFlag = [md getSmartFlag];
//    _devtype = md.devtype;
//
//    NSLog(@"smart 方式 ： %d ----- 设备ID： %@ ", smartFlag, str);
//    if (![str isEqualToString:@""]) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [SVProgressHUD showWithStatus:DPLocalizedString(@"Loading")];
//            [self findDevciceState:str];
//        });
//    }
//    else{
//        dispatch_async(dispatch_get_main_queue(), ^{
//           [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_sqr_erro")];
//            //             [self.navigationController popViewControllerAnimated:YES];
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
        NSLog(@"网线添加扫码失败：deviceId = %@, deviceType = %ld", deviceId, (long)deviceType);
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_sqr_erro")];
            [self.navigationController popViewControllerAnimated:YES];
        });
    }
    else
    {
        NSLog(@"网线添加扫码成功：deviceId = %@, deviceType = %ld", deviceId, (long)deviceType);
        smartFlag = smartConStyle;
        self.devtype = deviceType;
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                NSLog(@"对象丢失，无法查询'网线添加'设备绑定状态！");
                return ;
            }
            [strongSelf checkBindStatusWidhDevId:deviceId];
        });
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [SVProgressHUD showWithStatus:DPLocalizedString(@"Loading")];
            [self.navigationController popViewControllerAnimated:YES];
        });
    }
}


#pragma mark -- 从CBS查询设备绑定状态
- (void)checkBindStatusWidhDevId:(NSString *)deviceId
{
    __weak typeof(self) weakSelf = self;
    CBS_QueryBindRequest *req  = [CBS_QueryBindRequest new];
    BodyQueryBindRequest *body = [BodyQueryBindRequest new];
    body.DeviceId              = deviceId;
    body.UserName              = [SaveDataModel getUserName];
    [_netSDK net_sendCBSRequestMsgType:req.MessageType
                              bodyData:[body yy_modelToJSONObject]
                               timeout:5000
                         responseBlock:^(int result, NSDictionary *dict) {
                             
                             __strong typeof(weakSelf)strongSelf = weakSelf;
                             if (!strongSelf)
                             {
                                 NSLog(@"对象丢失，无法处理'网线添加'设备绑定状态结果！");
                                 return ;
                             }
                             if (!dict || 0 >= dict.count
                                 || ![dict[@"MessageType"]isEqualToString:@"QueryDeviceBindResponse"])
                             {
                                 [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
                                 return ;
                             }
                             NSLog(@"'网线添加'扫码查询绑定结果：%@", dict);
                             
                             NSString *bindTag = dict[@"Body"][@"BindStatus"];
                             DeviceBindStatus devBindStatus = bindTag.integerValue;
                             [strongSelf handleDeviceId:deviceId
                                             bindStatus:devBindStatus];
                         }];
}


#pragma mark -- 处理绑定状态
- (void)handleDeviceId:(NSString *)deviceId
            bindStatus:(DeviceBindStatus)bindStatus
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法处理'网线添加'设备绑定状态！");
            return ;
        }
        switch (bindStatus)
        {
                
            case DeviceUnBind:          // 未被绑定（可以绑定）
            {
                if (![deviceId hasPrefix:@"A"]
                    && ![deviceId hasPrefix:@"Z"])
                {
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"DeviceSupportNO")];
                    
                    return;
                }
                if ([deviceId hasPrefix:@"A"]
                    &&  isENVersionNew)
                {
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"DeviceSupportEN")];
                    //中文版
                    return;
                }
                if ([deviceId hasPrefix:@"Z"]
                    && ! isENVersionNew)
                {
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"DeviceSupportCN")];
                    //中文版
                    return;
                }
                [SVProgressHUD dismissWithDelay:1];
                strongSelf.MyDeviceIdTextField.text = deviceId;
            }
                break;
                
            case DeviceOwnBind:         // 已被本账号‘主权限’绑定
            {
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_we_bind")];
                strongSelf.MyDeviceIdTextField.text = @"";
            }
                break;
                
            case DeviceShareBind:       // 已被本账号‘分享权限’绑定
            {
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_we_bind")];
                strongSelf.MyDeviceIdTextField.text = @"";
            }
                break;
                
            case DeviceOtherBind:       // 被其他账号绑定
            {
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_other_bind")];
                strongSelf.MyDeviceIdTextField.text = @"";
            }
                break;
                
            default:
            {
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
            }
                break;
        }
    });
}


#pragma mark 扫描“chancel”回调
- (void)readerDidCancel:(QRCodeReaderViewController *)reader
{
    [self.navigationController popViewControllerAnimated:NO];
}

#pragma mark 跳转下个界面
- (IBAction)next:(id)sender {
    
    if (_MyDeviceIdTextField.text.length>0 && _MyDeviceName.text.length>0) {
        WringConfigureViewController * view = [[WringConfigureViewController alloc]init];
        view.deviceID= _MyDeviceIdTextField.text;
        view.deviceName = self.MyDeviceName.text;
        view.deviceType = self.devtype;

        [self.navigationController pushViewController:view animated:NO];
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
