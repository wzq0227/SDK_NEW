//
//  ScanGuideViewController.m
//  ULife3.5
//
//  Created by AnDong on 2017/10/27.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "ScanGuideViewController.h"
#import <Masonry.h>
#import "Header.h"
#import "QrcodeSetingViewController.h"
#import "WifiSettingViewController.h"
#import "ScanTwoViewController.h"
#import "ConfigurationWiFiViewController.h"


@interface ScanGuideViewController ()

@property (nonatomic,strong)UIImageView *topImageView;

@property (nonatomic,strong)UILabel *noticeLabel;

@property (nonatomic,strong)UIButton *nextBtn;


@end

@implementation ScanGuideViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = DPLocalizedString(@"Setting_Camera");
    [self setupUI];
    [self makeConstraints];
}


- (void)setupUI{
    self.view.backgroundColor = [UIColor whiteColor];
    self.topImageView = [[UIImageView alloc]init];
    self.topImageView.image = [UIImage imageNamed:@"addDev_qr_wifi_tag"];
    [self.view addSubview:self.topImageView];
    
    self.noticeLabel = [[UILabel alloc]init];
    self.noticeLabel.text = DPLocalizedString(@"ADDDevice_Set");
    self.noticeLabel.textColor = [UIColor blackColor];
    self.noticeLabel.font = [UIFont systemFontOfSize:15.0f];
    self.noticeLabel.textAlignment = NSTextAlignmentCenter;
    self.noticeLabel.numberOfLines = 0;
    [self.view addSubview:self.noticeLabel];
    
    self.nextBtn = [[UIButton alloc]init];
    [self.nextBtn addTarget:self action:@selector(nextClick) forControlEvents:UIControlEventTouchUpInside];
    self.nextBtn.backgroundColor = myColor;
    self.nextBtn.layer.cornerRadius = 20;
    self.nextBtn.clipsToBounds = YES;
    [self.nextBtn setTitleColor:[UIColor whiteColor] forState:0];
    [self.nextBtn setTitle:DPLocalizedString(@"ADDDevice_Next") forState:0];
    [self.view addSubview:self.nextBtn];
}


//添加约束
- (void)makeConstraints{
    [self.topImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).mas_offset(30);
        make.left.equalTo(self.view).mas_offset(20);
        make.right.equalTo(self.view).mas_offset(-20);
        make.height.equalTo(self.topImageView.mas_width).multipliedBy(0.6);
    }];
    
    [self.noticeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topImageView.mas_bottom).offset(10);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
        make.height.equalTo(@40);
    }];
    
    [self.nextBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-50);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
        make.height.equalTo(@40);
    }];
}

//下一步点击
- (void)nextClick{
    if (self.addMethodType == ADDMethodsTypeWifi) {
        
        if (!_addDevInfo) {
            _addDevInfo = [InfoForAddingDevice new];
        }
        _addDevInfo.smartStyle      = self.dataModel.smartStyle;
        _addDevInfo.devId           = self.dataModel.DeviceId;
        _addDevInfo.deviceType      = self.dataModel.DeviceType;
        _addDevInfo.devName         = self.dataModel.DeviceName;
        _addDevInfo.devWifiName     = self.wifiStr;
        _addDevInfo.devWifiPassWord = self.wifiPWD;
        _addDevInfo.addDeviceMode   = AddDeviceByWiFi;
        
        ConfigurationWiFiViewController   * view =[[ConfigurationWiFiViewController alloc]init];
        view.addDevInfo = _addDevInfo;
        [self.navigationController pushViewController:view animated:NO];
    }
    else if (self.addMethodType == ADDMethodsTypeQrcode){
        ScanTwoViewController * view = [[ScanTwoViewController alloc]init];
        view.wifiPWD = self.wifiPWD;
        view.wifiStr = self.wifiStr;
        view.deviceID= self.dataModel.DeviceId;
        view.devName = self.dataModel.DeviceName;
        view.deviceType = self.dataModel.DeviceType;
        view.scanType = scanTypeQRCode;
        [self.navigationController pushViewController:view animated:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
