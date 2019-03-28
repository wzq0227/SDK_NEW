//
//  AddDeviceViewController.m
//  goscamapp
//
//  Created by goscam_sz on 17/4/21.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "AddDeviceViewController.h"
#import "Header.h"
#import "AddDeviceTableViewCell.h"
#import "WifiAddDeviceViewController.h"
#import "ScanQrViewController.h"
#import "WiringViewController.h"
#import "AddFriendShareViewController.h"
#import "APModeConfigTipsVC.h"
#import "WifiSettingViewController.h"
#import "QrcodeSetingViewController.h"
#import "UIColor+YYAdd.h"
#import "Header.h"
#import "APModeConfigTipsVC.h"
#import "WringConfigureViewController.h"
#import "AcousticConfigTipsVC.h"
#import "ScanGuideViewController.h"
#import "UILabel+GosLayoutAdd.h"

@interface AddDeviceViewController ()<UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate>
@property (strong, nonatomic)  NSMutableArray *addStyleModelArray;
@end

@implementation AddDeviceViewController

//typedef NS_ENUM(NSInteger, SmartConnectStyle) {
//    SmartConnectNotSurportSmart     = 0,                // 不支持 Smart
//    SmartConnect1                   = 1,                // 7601
//    SmartConnect2                   = 2,                // 8188
//    SmartConnectUploadWiFi          = 3,                // 6212  上报 WiFi 名称和密码
//    SmartConnect4                   = 4,
//    SmartConnect5                   = 5,
//    SmartConnect6                   = 6,
//    SmartConnect7                   = 7,
//    SmartConnect8                   = 8,
//    SmartConnectNotSurportQRScan    = 9,                // 不支持二维码扫描
//    SmartConnectOnlySurportQRScan   = 10,               // 只支持二维码扫描
//    SmartConnect11                  = 11,               // 代表二维码扫描 +7601smart
//    SmartConnect12                  = 12,               // 代表二维码扫描 +8188smart
//    SmartConnect13                  = 13,               // 代表二维码扫描 +ap6212smart
//    SmartConnect14                  = 14,               // 代表 AP添加
//    SmartConnect15                  = 15,               // 代表 AP模式加8188smart
//    SmartConnect16                  = 16,               //代表AP模式 门铃项目
//    
//};

- (NSMutableArray *)arr
{
    if (_arr==nil) {
        if (_devModel.DeviceType == GosDeviceNVR) {
            _arr=[[NSMutableArray alloc]initWithObjects:@"ADDDevice_Wiring", nil]; //,@"ADDDevice_share"
        }else if (_devModel.DeviceType == GosDevice360){
            _arr=[[NSMutableArray alloc]initWithObjects:@"ADDDevice_WiFi",@"ADDDevice_APMode", nil]; //,@"ADDDevice_share"
        }else{//IPC
            
            
            _arr = [NSMutableArray array];
            
            SmartConnectStyle smartConStyle = self.devModel.smartStyle;
            //支持二维码
            if ( SmartConnectOnlySurportQRScan == smartConStyle
                || SmartConnect11 == smartConStyle
                || SmartConnect12 == smartConStyle
                || SmartConnect13 == smartConStyle) {
                [_arr addObject:@"ADDDevice_Qrcode"];
            }
            

            //支持smart
            if (SmartConnect1 == smartConStyle
                || SmartConnect2 == smartConStyle
                || SmartConnectUploadWiFi == smartConStyle
                || SmartConnectNotSurportQRScan == smartConStyle
                || SmartConnect11 == smartConStyle
                || SmartConnect12 == smartConStyle
                || SmartConnect13 == smartConStyle) {
                [_arr addObject:@"ADDDevice_WiFi"];
            }
           
            
            //支持AP模式
            if (SmartConnect14 == smartConStyle
                || SmartConnect15 == smartConStyle
                || SmartConnect16 == smartConStyle) {
                [_arr addObject:@"ADDDevice_APMode"];
            }
            

            //支持声波配网
            if (SmartConnect17 == smartConStyle) {
                [_arr addObject:@"ADDDevice_Voice"];
            }
        
            //支持网线添加
            if (self.devModel.isHasEnthnet) {
                [_arr addObject:@"ADDDevice_Wiring"];
            }
            
            //默认支持好友分享
//            [_arr addObject:@"ADDDevice_share"];

        }
    }
    return _arr;
}


- (NSMutableArray *)ImageArr
{
    if (_ImageArr==nil) {
        if (_devModel.DeviceType == GosDeviceNVR) {
            _ImageArr=[[NSMutableArray alloc]initWithObjects:@"addev_Ethernetcable", nil];//,@"addev_FriendsShare"
        }else if (_devModel.DeviceType == GosDevice360){
            _ImageArr=[[NSMutableArray alloc]initWithObjects:@"addev_WiFi",@"addDev_Mode_APMode", nil];//,@"addev_FriendsShare"
        }else{//IPC
            _ImageArr = [NSMutableArray array];
            SmartConnectStyle smartConStyle = self.devModel.smartStyle;
            //支持wifi
            if ( SmartConnectOnlySurportQRScan == smartConStyle
                || SmartConnect11 == smartConStyle
                || SmartConnect12 == smartConStyle
                || SmartConnect13 == smartConStyle) {
                [_ImageArr addObject:@"addev_ScanQrCode"];
            }
            
            
            //支持smart
            if (SmartConnect1 == smartConStyle
                || SmartConnect2 == smartConStyle
                || SmartConnectUploadWiFi == smartConStyle
                || SmartConnectNotSurportQRScan == smartConStyle
                || SmartConnect11 == smartConStyle
                || SmartConnect12 == smartConStyle
                || SmartConnect13 == smartConStyle) {
                [_ImageArr addObject:@"addev_WiFi"];
            }
            
            
            //支持AP模式
            if (SmartConnect14 == smartConStyle
                || SmartConnect15 == smartConStyle
                || SmartConnect16 == smartConStyle) {
                [_ImageArr addObject:@"addDev_Mode_APMode"];
            }
            
            
            //支持声波配网
            if ( SmartConnect17 == smartConStyle) {
                [_ImageArr addObject:@"addDev_Voice_showIcon"];
            }
            
            //支持网线添加
            if (self.devModel.isHasEnthnet) {
                [_ImageArr addObject:@"addev_Ethernetcable"];
            }
            
            //默认支持好友分享
//            [_ImageArr addObject:@"addev_FriendsShare"];
            
//            _ImageArr=[[NSMutableArray alloc]initWithObjects:@"addev_ScanQrCode",@"addev_WiFi",@"addev_Ethernetcable",@"addev_FriendsShare", nil];
        }
    }
    return _ImageArr;
}

- (NSMutableArray *)addStyleModelArray{
    if (!_addStyleModelArray) {
        if (_devModel.DeviceType == GosDeviceNVR) {
            _addStyleModelArray = [NSMutableArray arrayWithArray:@[@(AddDeviceByWLAN)]]; //, @(AddDeviceByShare)
        }else if (_devModel.DeviceType == GosDevice360){
            _addStyleModelArray = [NSMutableArray arrayWithArray:@[@(AddDeviceByWiFi), @(AddDeviceByAPMode)]];//, @(AddDeviceByShare)
        }else{//IPC
            
            _addStyleModelArray = [NSMutableArray array];
            SmartConnectStyle smartConStyle = self.devModel.smartStyle;
            //支持wifi
            if ( SmartConnectOnlySurportQRScan == smartConStyle
                || SmartConnect11 == smartConStyle
                || SmartConnect12 == smartConStyle
                || SmartConnect13 == smartConStyle) {
                [_addStyleModelArray addObject:@(AddDeviceByScanQR)];
            }
            
            
            //支持smart
            if (SmartConnect1 == smartConStyle
                || SmartConnect2 == smartConStyle
                || SmartConnectUploadWiFi == smartConStyle
                || SmartConnectNotSurportQRScan == smartConStyle
                || SmartConnect11 == smartConStyle
                || SmartConnect12 == smartConStyle
                || SmartConnect13 == smartConStyle) {
                [_addStyleModelArray addObject:@(AddDeviceByWiFi)];
            }
            
            
            //支持AP模式
            if (SmartConnect14 == smartConStyle
                || SmartConnect15 == smartConStyle
                || SmartConnect16 == smartConStyle) {
                [_addStyleModelArray addObject:@(AddDeviceByAPMode)];
            }
            
            
            //支持声波配网
            if (SmartConnect17 == smartConStyle) {
                [_addStyleModelArray addObject: @(AddDeviceByVoice)];
            }
            
            //支持网线添加
            if (self.devModel.isHasEnthnet) {
                [_addStyleModelArray addObject:@(AddDeviceByWLAN)];
            }
            
            //默认支持好友分享
//            [_addStyleModelArray addObject:@(AddDeviceByShare)];
            
//            _addStyleModelArray = @[@(AddDeviceByScanQR), @(AddDeviceByWiFi), @(AddDeviceByWLAN), @(AddDeviceByShare)];
        }
    }
    return _addStyleModelArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
  
    if ( self.devModel.smartStyle == SmartConnect17) {
        
        self.addev_advertisingImageView.image = [UIImage imageNamed:@"addev_advertising_doorbell"];
        self.waitForAcousticAddVoiceTipLabel.text = DPLocalizedString(@"AcousticAdd_waitForAcousticAddVoiceTip");
        self.topMarginToTableViewOfLabel.constant = 20 + self.arr.count *55;
        [self.waitForAcousticAddVoiceTipLabel setLinespacing:6];
    }else{
        self.waitForAcousticAddVoiceTipLabel.hidden = YES;
    }
    
    self.title=DPLocalizedString(@"ADDDevice");
    self.navigationController.navigationBar.translucent=NO;
    [_myTableView registerNib:[UINib nibWithNibName:@"AddDeviceTableViewCell" bundle:nil] forCellReuseIdentifier:@"cell"];
    _myTableView.delegate=self;
    _myTableView.dataSource=self;
    _myTableView.separatorStyle=UITableViewCellSeparatorStyleNone;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AddDeviceTableViewCell * cell =[tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.FristButton.tag=indexPath.row;
    cell.FristButton.layer.cornerRadius=20;
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    cell.headerImage.image=[UIImage imageNamed:[NSString stringWithFormat:@"%@",self.ImageArr[indexPath.row]]];
    [cell.FristButton setTitle:DPLocalizedString(self.arr[indexPath.row]) forState:UIControlStateNormal];
    [cell.FristButton setBackgroundColor:myColor];
    [cell.FristButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cell.FristButton addTarget:self action:@selector(action:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

-(void)action:(UIButton *)btn
{
    AddDeviceByStyle style = [self.addStyleModelArray[btn.tag] intValue];
    NSLog(@"AddDeviceByStyle_______________:%ld",(long)style);
    switch (style) {
//        case AddDeviceByScanQR:{
//            QrcodeSetingViewController *Qrvc = [[QrcodeSetingViewController alloc]init];
//            Qrvc.devModel = self.devModel;
//            [self.navigationController pushViewController:Qrvc animated:NO];
//        }
//            break;
//
//        case AddDeviceByWiFi:{
//            WifiSettingViewController *wifiSetVc = [[WifiSettingViewController alloc] init];
//            wifiSetVc.devModel = self.devModel;
//            [self.navigationController pushViewController:wifiSetVc animated:NO];
//        }
//
//            break;
            
        case AddDeviceByScanQR:{
            QrcodeSetingViewController *Qrvc = [[QrcodeSetingViewController alloc]init];
            Qrvc.devModel = self.devModel;
            [self.navigationController pushViewController:Qrvc animated:NO];

        }
            break;
            
        case AddDeviceByWiFi:{
            WifiSettingViewController *wifiSetVc = [[WifiSettingViewController alloc] init];
            wifiSetVc.devModel = self.devModel;
            [self.navigationController pushViewController:wifiSetVc animated:NO];
        }
            
            break;
            
            case AddDeviceByAPMode:
            {
                APModeConfigTipsVC *vc = [[APModeConfigTipsVC alloc]init];
                vc.devModel = self.devModel;
                [self.navigationController pushViewController:vc animated:NO];
                break;
            }
            
        case AddDeviceByWLAN:{
            WringConfigureViewController * view = [[WringConfigureViewController alloc]init];
            view.deviceID= self.devModel.DeviceId;
            view.deviceName = self.devModel.DeviceName;
            view.deviceType = self.devModel.DeviceType;
            [self.navigationController pushViewController:view animated:NO];
//            WiringViewController *wiringVc = [[WiringViewController alloc]init];
//            wiringVc.devModel = self.devModel;
//            [self.navigationController pushViewController:wiringVc animated:NO];
        }
            break;
            
        case AddDeviceByShare:
            [self.navigationController pushViewController:[[AddFriendShareViewController alloc]init] animated:NO];
            break;

            //声波配网
        case AddDeviceByVoice:
        {
            AcousticConfigTipsVC *vc = [AcousticConfigTipsVC new];
            vc.devModel = self.devModel;
            [self.navigationController pushViewController:vc animated:NO];
            break;
        }
            
            default:
            break;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.arr.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55.5;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientation{
    return UIInterfaceOrientationMaskPortrait;
}
@end
