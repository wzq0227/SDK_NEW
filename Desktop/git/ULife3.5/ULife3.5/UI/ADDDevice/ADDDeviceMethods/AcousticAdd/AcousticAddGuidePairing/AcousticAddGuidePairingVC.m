//
//  AcousticAddGuidePairingVC.m
//  ULife3.5
//
//  Created by Goscam on 2017/11/16.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "AcousticAddGuidePairingVC.h"
#import "DeviceListViewController.h"
#import "Header.h"
#import "UILabel+GosLayoutAdd.h"

@interface AcousticAddGuidePairingVC ()

@end

@implementation AcousticAddGuidePairingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self configView];
    [self playGIFWithWebView];
    
    [self configBackBtn];
}

- (void)configView{
    
    [self configTitleWithStr: DPLocalizedString(@"AcousticAdd_addDoorbellCameraDevice")];

    self.view.backgroundColor = mCustomBgColor;

    self.pairingTimeLabel.hidden = YES;
    self.containerView.layer.cornerRadius = 10;
    self.containerView.clipsToBounds = YES;
    
    self.startToUseBtn.backgroundColor = myColor;
    self.startToUseBtn.layer.cornerRadius = 20;
    self.startToUseBtn.clipsToBounds = YES;
    
    [self.startToUseBtn setTitleColor:[UIColor whiteColor] forState:0];
    
    self.pairingTimeLabel.text = DPLocalizedString(@"AcousticAdd_pairingTimeTips");
    self.longPressMusicBtnLabel.text = DPLocalizedString(@"AcousticAdd_longPressMusicBtn");
    
    
    
    NSRange iconStringRange = [DPLocalizedString(@"AcousticAdd_longPressBellBtnInDevice") rangeOfString:@"%@"];
    NSString *txtStr = [DPLocalizedString(@"AcousticAdd_longPressBellBtnInDevice") stringByReplacingOccurrencesOfString:@"%@" withString:@""];
    
    self.longPressBellBtnInDeviceLabel.text = txtStr;
    [self.longPressBellBtnInDeviceLabel insertImage:[UIImage imageNamed:@"AcousticAdd_icon_doorbell"]
                                            atIndex:iconStringRange.location
                                             bounds:CGRectMake(0, -4, 18, 18)];
    
    
    
    NSRange iconStringRange2 = [DPLocalizedString(@"AcousticAdd_ringToHearVoiceFromStation") rangeOfString:@"%@"];
    NSString *txtStr2 = [DPLocalizedString(@"AcousticAdd_ringToHearVoiceFromStation") stringByReplacingOccurrencesOfString:@"%@" withString:@""];
    
    self.ringToHearVoiceFromStationLabel.text = txtStr2;
    [self.ringToHearVoiceFromStationLabel insertImage:[UIImage imageNamed:@"AcousticAdd_icon_doorbell"]
                                              atIndex:iconStringRange2.location
                                               bounds:CGRectMake(0, -4, 18, 18)];
    
    
    
    [self.startToUseBtn setTitle:DPLocalizedString(@"AcousticAdd_doneAndStartUse") forState:UIControlStateNormal];
    [self.startToUseBtn addTarget:self action:@selector(jumpToDevListVC:) forControlEvents: UIControlEventTouchUpInside];
}


- (void)configTitleWithStr:(NSString*)titleStr{
    CGSize titleSize =self.navigationController.navigationBar.bounds.size;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, titleSize.width/2,titleSize.height)];
    label.numberOfLines = 0;
    label.backgroundColor = [UIColor clearColor];
    label.font =  [UIFont boldSystemFontOfSize:16];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.text= titleStr;
    self.navigationItem.titleView = label;
}

- (void)configBackBtn{
    UIImage *image = [UIImage imageNamed:@"addev_back"];
    EnlargeClickButton *button = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 50, 40);
    button.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 30);
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self
               action:@selector(backToDevListVC:)
     forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    leftBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
}

- (void)backToDevListVC:(id)sender{
    
    UIViewController *target = nil;
    for (UIViewController * controller in self.navigationController.viewControllers) {
        if ([controller isKindOfClass:[DeviceListViewController class]]
             ) {
            target = controller;
            break;
        }
    }
    if (target) {
        [self.navigationController popToViewController:target animated:YES];
    }
}

- (void)jumpToDevListVC:(id)sender{
    
    NSNotification *notification =[NSNotification notificationWithName:REFRESH_DEV_LIST_NOTIFY object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}


- (void)playGIFWithWebView{
    
    
    // 读取gif图片数据
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.containerView.bounds];
    [self.containerView addSubview:webView];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"doorbell_pairing_guide" ofType:@"gif"];
    /*
     NSData *data = [NSData dataWithContentsOfFile:path];
     使用loadData:MIMEType:textEncodingName: 则有警告
     [webView loadData:data MIMEType:@"image/gif" textEncodingName:nil baseURL:nil];
     */
    NSURL *url = [NSURL URLWithString:path];
    webView.contentScaleFactor       = [UIScreen mainScreen].scale;
    webView.opaque                   = NO;
    webView.scalesPageToFit          = YES;
    webView.scrollView.scrollEnabled = NO;
    webView.backgroundColor          = [UIColor clearColor];
    [webView loadRequest:[NSURLRequest requestWithURL:url]];
    
}



@end
