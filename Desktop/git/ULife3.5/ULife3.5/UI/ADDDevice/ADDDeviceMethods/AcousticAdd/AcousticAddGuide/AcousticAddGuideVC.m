//
//  AcousticAddGuideVC.m
//  ULife3.5
//
//  Created by Goscam on 2017/11/16.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "AcousticAddGuideVC.h"
#import <SDWebImage/UIImage+GIF.h>
#import "AcousticConfigConnectVC.h"
#import "Header.h"
#import "UILabel+GosLayoutAdd.h"

@interface AcousticAddGuideVC ()

@end

@implementation AcousticAddGuideVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self configView];
    [self playGIFWithWebView];
}

- (void)configView{
    self.title = DPLocalizedString(@"AcousticAdd_manuallyEnterAcousticPairing");
    self.view.backgroundColor = mCustomBgColor;
    
    self.gifContainerView.layer.cornerRadius = 10;
    self.gifContainerView.clipsToBounds = YES;
    
    self.haveHeardVoiceBtn.backgroundColor = myColor;
    self.haveHeardVoiceBtn.layer.cornerRadius = 20;
    self.haveHeardVoiceBtn.clipsToBounds = YES;
    
    [self.haveHeardVoiceBtn setTitleColor:[UIColor whiteColor] forState:0];
    
    [self.haveHeardVoiceBtn setTitle:DPLocalizedString(@"AcousticAdd_haveHeardVoiceTip") forState:UIControlStateNormal];
    
    NSRange iconStringRange = [DPLocalizedString(@"AcousticAdd_longPressSignalBtn") rangeOfString:@"%@"];
    NSString *txtStr = [DPLocalizedString(@"AcousticAdd_longPressSignalBtn") stringByReplacingOccurrencesOfString:@"%@" withString:@""];
    
    self.longPressSignalBtnTipsLabel.text = txtStr;
    [self.longPressSignalBtnTipsLabel insertImage:[UIImage imageNamed:@"AcousticAdd_icon_signal"]
                                          atIndex:iconStringRange.location
                                           bounds:CGRectMake(0, -2, 15, 13)];
    [self.haveHeardVoiceBtn addTarget:self action:@selector(gotoNextPage:) forControlEvents:UIControlEventTouchUpInside];
}



- (void)gotoNextPage:(id)sender{
    AcousticConfigConnectVC *pVC = [AcousticConfigConnectVC new];
    [self.navigationController pushViewController:pVC animated:YES];
}

- (void)playGIFWithWebView{
    
    
    // 读取gif图片数据
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.gifContainerView.bounds];
    [self.gifContainerView addSubview:webView];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:(self.gifType == AcousticGuideGIFType_StartAcousticAdd)? @"doorbell_startAcousticAdd_guide":@"doorbell_pairing_guide" ofType:@"gif"];
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

- (void)playGIFWithSDWebImage{
    NSString *path = [[NSBundle mainBundle] pathForResource:(self.gifType == AcousticGuideGIFType_StartAcousticAdd)? @"doorbell_startAcousticAdd_guide":@"doorbell_pairing_guide" ofType:@"gif"];
    NSData *gifData = [NSData dataWithContentsOfFile:path];
    UIImage *image = [UIImage sd_animatedGIFWithData:gifData];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.gifContainerView.bounds];
    imageView.image = image;
    [self.gifContainerView addSubview:imageView];
}

@end
