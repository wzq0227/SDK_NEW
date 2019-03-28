//
//  ModifyDevicePswViewController.m
//  ULife3.5
//
//  Created by AnDong on 2017/11/7.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "ModifyDevicePswViewController.h"
#import "Header.h"
#import "BaseCommand.h"
#import "NetSDK.h"

@interface ModifyDevicePswViewController ()

@property (nonatomic,strong)UIImageView *psdImgView1;
@property (nonatomic,strong)UIImageView *psdImgView2;

@property (nonatomic,strong)UIView *lineView1;
@property (nonatomic,strong)UIView *lineView2;

@property (nonatomic,strong)UITextField *oldTf;
@property (nonatomic,strong)UITextField *nowTf;

@property (nonatomic,strong)UIButton *saveBtn;

@end

@implementation ModifyDevicePswViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = DPLocalizedString(@"DevicePasswordModify");
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupUI];
}


- (void)setupUI{
    [self.view addSubview:self.psdImgView1];
    [self.view addSubview:self.psdImgView2];
    [self.view addSubview:self.lineView1];
    [self.view addSubview:self.lineView2];
    [self.view addSubview:self.oldTf];
    [self.view addSubview:self.nowTf];
    [self.view addSubview:self.saveBtn];
}

- (void)save{
    
    if (self.oldTf.text.length > 0 && self.nowTf.text.length >0) {
        [SVProgressHUD showWithStatus:DPLocalizedString(@"loading")];
        CMD_SetDevicePassword *req = [[CMD_SetDevicePassword alloc]init];
        req.newpasswd = self.nowTf.text;
        req.oldpasswd = self.oldTf.text;
        [[NetSDK sharedInstance] net_sendBypassRequestWithUID:self.deviceId requestData:[req yy_modelToJSONObject] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
            if (result == 0) {
                [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Operation_Succeeded")];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.navigationController popViewControllerAnimated:YES];
                });
            }
            else{
                dispatch_async_on_main_queue(^{
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
                });
            }
        }];
    }
    else{
        
    }
    
   
}


#pragma mark - Getter
- (UIImageView *)psdImgView1{
    if (!_psdImgView1) {
        _psdImgView1 = [[UIImageView alloc]initWithFrame:CGRectMake(20, 60, 24, 24)];
        _psdImgView1.image = [UIImage imageNamed:@"password"];
    }
    return _psdImgView1;
}

- (UIImageView *)psdImgView2{
    if (!_psdImgView2) {
        _psdImgView2 = [[UIImageView alloc]initWithFrame:CGRectMake(20, 60 + 40, 24, 24)];
        _psdImgView2.image = [UIImage imageNamed:@"password"];
    }
    return _psdImgView2;
}

- (UIView *)lineView1{
    if (!_lineView1) {
        _lineView1 = [[UIView alloc]initWithFrame:CGRectMake(20, 85, kScreen_Width - 40, 1)];
        _lineView1.backgroundColor = BACKCOLOR(197,197,197, 1.0f);
    }
    return _lineView1;
}


- (UIView *)lineView2{
    if (!_lineView2) {
        _lineView2 = [[UIView alloc]initWithFrame:CGRectMake(20, 125, kScreen_Width - 40, 1)];
        _lineView2.backgroundColor = BACKCOLOR(197,197,197, 1.0f);
    }
    return _lineView2;
}

- (UITextField *)oldTf{
    if (!_oldTf) {
        _oldTf = [[UITextField alloc]initWithFrame:CGRectMake(50, 60, kScreen_Width - 85, 24)];
        _oldTf.placeholder = DPLocalizedString(@"DevicePasswordInputOld");
    }
    return _oldTf;
}

- (UITextField *)nowTf{
    if (!_nowTf) {
        _nowTf = [[UITextField alloc]initWithFrame:CGRectMake(50, 60 + 40, kScreen_Width - 85, 24)];
        _nowTf.placeholder = DPLocalizedString(@"DevicePasswordInputNew");
    }
    return _nowTf;
}

- (UIButton *)saveBtn{
    if (!_saveBtn) {
        _saveBtn = [[UIButton alloc]initWithFrame:CGRectMake(20, 200, kScreen_Width - 40, 40)];
        [_saveBtn setBackgroundColor:myColor];
        [_saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _saveBtn.layer.cornerRadius=20.f;
        [_saveBtn setTitle:DPLocalizedString(@"Title_Save") forState:UIControlStateNormal];
        [_saveBtn addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
    }
    return _saveBtn;
}


@end
