

//
//  AboutWebViewController.m
//  ULife3.5
//
//  Created by 广东省深圳市 on 2017/8/2.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "AboutWebViewController.h"

@interface AboutWebViewController ()<UIWebViewDelegate>

@end

@implementation AboutWebViewController

- (instancetype)initWithTitle:(NSString*)title urlStr:(NSString*)urlStr{
    if (self = [super init]) {
        self.title = title;
        self.loadUrl = urlStr;
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addLeftBarButtonItem];
    
    UIWebView *webView= [[UIWebView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 64.0)];
    webView.delegate = self;
    [self.view addSubview:webView];
    
    
    if (self.loadUrl) {
       [SVProgressHUD showWithStatus:DPLocalizedString(@"loading")];
        NSURLRequest *request = [[NSURLRequest alloc]initWithURL:[NSURL URLWithString:self.loadUrl]];
        [webView loadRequest:request];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    [SVProgressHUD dismiss];
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    [SVProgressHUD dismiss];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -- 添加左 item
- (void)addLeftBarButtonItem
{
    UIImage *image = [UIImage imageNamed:@"addev_back"];
    EnlargeClickButton *button = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 70, 40);
    button.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 50);
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self
               action:@selector(presentLeftMenuViewController:)
     forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    leftBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
}

@end
