//
//  AboutViewController.m
//  ULife3.5
//
//  Created by 广东省深圳市 on 2017/7/20.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "AboutViewController.h"
#import "AboutWebViewController.h"

@interface AboutViewController ()
@property (weak, nonatomic) IBOutlet UIButton *aboutBtn;
@property (weak, nonatomic) IBOutlet UIImageView *aboutImgView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imgWidth;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@property (weak, nonatomic) IBOutlet UILabel *aboutLabel;
@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addLeftBarButtonItem];
    
    self.title = DPLocalizedString(@"Personal_about");
    
    // 由info.plist中获取版本号
    self.versionLabel.text = [NSString stringWithFormat:@"V%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    
    if (isENVersion) {
        self.aboutImgView.image = [UIImage imageNamed:@"ic_company_infoEN"];
        self.imgWidth.constant = 142;
    }
    self.aboutBtn.hidden = self.aboutLabel.hidden = self.aboutImgView.hidden = YES;
    
    self.aboutLabel.text = DPLocalizedString(@"Register_UserAgreement");
    // Do any additional setup after loading the view from its nib.
    [self.aboutBtn addTarget:self action:@selector(openAgreeMent) forControlEvents:UIControlEventTouchUpInside];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)openAgreeMent{
    AboutWebViewController *webViewController = [[AboutWebViewController alloc]initWithTitle:DPLocalizedString(@"Register_UserAgreement") urlStr:@"http://ulifecam.com/common/user-agreements.html"];
    [self.navigationController pushViewController:webViewController animated:YES];

//    NSURL *url = [NSURL URLWithString:@"http://ulifecam.com/common/user-agreements.html"];
//    if ([[UIApplication sharedApplication]canOpenURL:url]) {
//        [[UIApplication sharedApplication]openURL:url];
//    }
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
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
