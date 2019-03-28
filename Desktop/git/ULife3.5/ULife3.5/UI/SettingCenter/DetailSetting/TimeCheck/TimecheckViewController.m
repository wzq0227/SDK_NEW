//
//  TimecheckViewController.m
//  QQI
//
//  Created by goscam_sz on 16/8/3.
//  Copyright © 2016年 yuanx. All rights reserved.
//

#import "TimecheckViewController.h"

#import "NetSDK.h"
#import "BaseCommand.h"
#include <sys/time.h>


@interface TimecheckViewController ()

@property (nonatomic,assign) NSUInteger timecount;
@property (nonatomic,strong) CMD_NTPTimeParam *timeParam;
@property(nonatomic,strong)NetSDK *network;
@property(nonatomic,strong)UIImage *failedImage;
@property(nonatomic,strong)UIImage *succeededImage;
@end

@implementation TimecheckViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _network = [NetSDK sharedInstance];
    
    [self configUI];
    [self addBackBtn];
    [self getTimeData];
}

- (void)configUI{
    self.title= DPLocalizedString(@"CameraTimeCheck_Btn_Title");
    self.opResultView.hidden = YES;
    self.timeCheckBtn.layer.cornerRadius = 20;
    [self.timeCheckBtn setTitle:DPLocalizedString(@"CameraTimeCheck_Btn_Title") forState:UIControlStateNormal];
    
    self.timeCheckTipsLabel.text = DPLocalizedString(@"CameraTimeCheck_Tips_Title");
    self.view.backgroundColor = BACKCOLOR(238,238,238,1);
}

-(void)addBackBtn
{
    EnlargeClickButton *backButton = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(0, 0, 70, 40);
    backButton.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 50);
    [backButton setImage:[UIImage imageNamed:@"addev_back"] forState:UIControlStateNormal];
    
    [backButton addTarget:self action:@selector(backToPreView) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    temporaryBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.leftBarButtonItem = temporaryBarButtonItem;
}


-(void)getTimeData
{
    [SVProgressHUD showWithStatus:@"Loading...."];

    __weak  TimecheckViewController* weakSelf = self;

    CMD_GetNTPTimeParamReq *req = [CMD_GetNTPTimeParamReq new];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_network net_sendBypassRequestWithUID:_deviceID requestData:[req requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
            if (result == 0) {
                weakSelf.timeParam = [CMD_GetNTPTimeParamResp yy_modelWithDictionary:dict];
                time_t seconds = time((time_t *)NULL);
                NSTimeZone *zone = [NSTimeZone systemTimeZone];
                NSInteger timeOff = [zone secondsFromGMT];
                
                static char str_time[100];
                struct tm *local_time = NULL;
                
                local_time = localtime(&seconds);
                strftime(str_time, sizeof(str_time), "%Y-%m-%d,%H:%M:%S", local_time);
                
                weakSelf.timeParam.AppTimeSec = (unsigned int)seconds;
                weakSelf.timeParam.un_TimeZone = (int)timeOff/3600;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (result != 0) {
                    [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Get_data_failed")];
                }else{
                    [SVProgressHUD dismiss];
                }
            });
        }];
        
    });
}

-(UIImage*)convertViewToImage:(UIView*)v{
    
    CGSize s = v.bounds.size;
    // 下面方法，第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
    UIGraphicsBeginImageContextWithOptions(s, NO, [UIScreen mainScreen].scale);
    [v.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage*image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

-(UIImage *)succeededImage{
    if (!_succeededImage) {
        
        UIImageView *view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 12, 24, 24)];
        view.backgroundColor = BACKCOLOR(238,238,238,1);
        view.image = [UIImage imageNamed:@"Setting_TimeCheckOk"];

        _succeededImage = [self convertViewToImage:view];
    }
    return _succeededImage;
}

-(UIImage *)failedImage{
    if (!_failedImage) {
        
        UIImageView *view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 12, 24, 24)];
        view.backgroundColor = BACKCOLOR(238,238,238,1);
        view.image = [UIImage imageNamed:@"Setting_TimeCheckFailed"];

        _failedImage = [self convertViewToImage:view];
    }
    return _failedImage;
}

- (void)configOpResultLabelWithResult:(int)result{
    
    self.opResultView.hidden = NO;

    NSString *resultStr = result ==0? DPLocalizedString(@"CameraTimeCheck_OpResult_Succeeded") :DPLocalizedString(@"CameraTimeCheck_OpResult_Failed");
    
    CGSize maxSize = CGSizeMake(200, 1000);
    
    NSDictionary *attr=@{NSFontAttributeName:_opResultLabel.font};
    
    CGSize labelSize = [resultStr boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:attr context:nil].size;
    
    NSLog(@"_________________________________size:%@",NSStringFromCGSize(labelSize));
    
    CGFloat faceImagePosX = SCREEN_WIDTH/2.0 - (labelSize.width+40)/2.0;
    CGFloat labelPosX = faceImagePosX + 40;
    
    CGRect faceImageFrame = _opResultFace.frame;
    CGRect labelFrame = _opResultLabel.frame;
    
    faceImageFrame.origin.x = faceImagePosX;
    labelFrame.origin.x     = labelPosX;
    
    self.opResultFace.frame = faceImageFrame;
    self.opResultLabel.frame = labelFrame;
    
    self.opResultLabel.text = resultStr;
    self.opResultFace.image = [UIImage imageNamed: result !=0? @"Setting_TimeCheckFailed":@"Setting_TimeCheckOk"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.opResultView.hidden = YES;
    });
}

-(void)backToPreView
{
    NSLog(@"backback");
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.navigationController popViewControllerAnimated:YES];
}



- (BOOL)shouldAutorotate {
    return NO;
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;;
}


- (void)viewWillDisappear:(BOOL)animated
{
    [SVProgressHUD dismiss];
    [[self class] cancelPreviousPerformRequestsWithTarget:self];
}


- (IBAction)timecheck:(id)sender {
    
    if (self.timeParam.AppTimeSec<=0) {
        return;
    }
    [SVProgressHUD showWithStatus:@"Loading...."];

    CMD_SetNTPTimeParamReq *req = [CMD_SetNTPTimeParamReq new];
    _timeParam.CMDType = req.CMDType;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_network net_sendBypassRequestWithUID:_deviceID requestData:[_timeParam requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                [self configOpResultLabelWithResult:result];

            });
        }];
    });
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
