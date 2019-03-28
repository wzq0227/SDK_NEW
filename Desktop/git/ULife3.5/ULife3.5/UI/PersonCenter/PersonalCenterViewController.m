//
//  PersonalCenterViewController.m
//  gaoscam
//
//  Created by goscam_sz on 17/4/18.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "PersonalCenterViewController.h"
#import "Header.h"
#import "DeviceListViewController.h"
#import "PushMsgViewController.h"
#import "MainNavigationController.h"
#import "SaveDataModel.h"
#import "NetSDK.h"
#import "ChangePassWordViewController.h"
#import "DeviceManagement.h"
#import "FeedBackViewController.h"
#import "AboutViewController.h"
#import "UIColor+YYAdd.h"
#import "ExperienceCenterViewController.h"
#import "UserGuideViewController.h"
#import "CSOrderDeviceList.h"

#import "AboutWebViewController.h"

#import "UIImage+RenderFunc.h"

@interface PersonalCenterViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, readwrite, nonatomic) UITableView *tableView;

@property(nonatomic, strong) UIView   *footerView;

@property(nonatomic, strong) UIButton *deleteBtn;

@property(nonatomic, strong) NetSDK   * netSDK;

@property (nonatomic, strong)UIView   *topView;

@property (nonatomic, strong)UIImageView   *topGrayView;

@property (nonatomic, strong)UIButton  *headerBtn;

@property (nonatomic, strong)UILabel   *headerLabel;

@property(nonatomic,strong)NSMutableArray *titlesArray;

@property(nonatomic,strong)NSMutableArray *imageNamesArray;

@property (nonatomic,strong)UIButton *logoutBtn;

@property (nonatomic,strong)UIView *logoutBGView;

@end

@implementation PersonalCenterViewController

/*
-(UIView *)footerView
{
    if (nil == _footerView)
    {
        UIColor *color = [UIColor clearColor];
        _footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 40)];
        [_footerView setBackgroundColor:color];
        [_footerView addSubview:self.deleteBtn];
    }
    return _footerView;
}

-(UIButton *)deleteBtn
{
    if (nil == _deleteBtn)
    {
        UIColor *color = [UIColor colorWithRed:76/255.0 green:182/255.0 blue:174/255.0 alpha:1.0];
        CGFloat btnHeight = 40.0f;
        CGFloat fontSize = 14.0f;
        CGFloat cornerRadiusSize = 20.0f;
        _deleteBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH-70, 40)];
        _deleteBtn.titleLabel.font = [UIFont systemFontOfSize:fontSize];
        _deleteBtn.layer.cornerRadius = cornerRadiusSize;
        [_deleteBtn addTarget:self action:@selector(loginView) forControlEvents:UIControlEventTouchUpInside];
        [_deleteBtn setBackgroundColor:color];
    }
    return _deleteBtn;
}

-(void)loginView
{
    LoginViewFristController * view = [[LoginViewFristController alloc]init];
    [self presentViewController:view animated:NO completion:nil];
}
*/

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView = ({
        //(self.view.frame.size.height - 54 * 6) / 2.0f
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0,130, self.view.frame.size.width, 54 * self.titlesArray.count) style:UITableViewStylePlain];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.opaque = NO;
        tableView.backgroundColor = [UIColor whiteColor];
        tableView.backgroundView = nil;
        tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        tableView.bounces = NO;
        //        tableView.tableFooterView=self.footerView;
        tableView;
    });
    _netSDK = [NetSDK sharedInstance];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.topView];
    
    [self.view addSubview:self.logoutBGView];
    [self.logoutBGView addSubview:self.logoutBtn];
    
    self.view.backgroundColor = UIColorFromRGBA(238, 238, 238, 1.0f);
}

#pragma mark UITableView Datasource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    return self.titlesArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell                                = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.backgroundColor                = [UIColor clearColor];
        cell.textLabel.font                 = [UIFont fontWithName:@"HelveticaNeue" size: CGRectGetWidth([UIScreen mainScreen].bounds)<=321?14:16 ];
        cell.textLabel.numberOfLines        = 0;
        cell.textLabel.textColor            = [UIColor blackColor];
        cell.textLabel.highlightedTextColor = [UIColor lightGrayColor];
        cell.selectedBackgroundView = [[UIView alloc] init];
    }
    
    cell.textLabel.text = DPLocalizedString( self.titlesArray[indexPath.row] );
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UIImage *tempImage = [UIImage imageWithName:self.imageNamesArray[indexPath.row]];
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.imageView.image = tempImage;
            [cell setNeedsLayout];
            [cell layoutIfNeeded];
        });
    });
    return cell;
}

- (NSMutableArray*)imageNamesArray{
    if (!_imageNamesArray) {
        NSArray *images = @[@"myCamera", @"messageCenter",@"CSOrderList", @"resetPsw",@"faq",@"about"];//@"experienceCenter",@"feedback",
        _imageNamesArray = [images mutableCopy];
    }
    return _imageNamesArray;
}

- (NSMutableArray*)titlesArray{
    if (!_titlesArray) {
        _titlesArray = [NSMutableArray arrayWithCapacity:1];
        for (int i=0; i<self.imageNamesArray.count; i++) {
            [_titlesArray addObject:[@"Personal_" stringByAppendingString:self.imageNamesArray[i]]];
        }
    }
    return _titlesArray;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0:
            [self.sideMenuViewController setContentViewController:[[MainNavigationController alloc] initWithRootViewController:[[DeviceListViewController alloc] init]]
                                                         animated:YES];
            [self.sideMenuViewController hideMenuViewController];
            break;
        case 1:
        {
            [self.sideMenuViewController setContentViewController:[[MainNavigationController alloc] initWithRootViewController:[[PushMsgViewController alloc] init]]
                                                         animated:YES];
            [self.sideMenuViewController hideMenuViewController];
        }
            break;
            
        case 2:
            //云服务
            [self.sideMenuViewController setContentViewController:[[MainNavigationController alloc] initWithRootViewController:[[CSOrderDeviceList alloc]init]]
                                                         animated:YES];
            [self.sideMenuViewController hideMenuViewController];
            break;
        case 3:
            //修改密码
            [self.sideMenuViewController setContentViewController:[[MainNavigationController alloc] initWithRootViewController:[[ChangePassWordViewController alloc] init]]
                                                         animated:YES];
            [self.sideMenuViewController hideMenuViewController];
            break;

        case 4:
        {
            //faq
            NSString *titleStr = MLocalizedString(Personal_faq);
            NSString *urlStr = @"http://www.ulifecam.com/FAQ/index.htm";
            [self.sideMenuViewController setContentViewController:[[MainNavigationController alloc] initWithRootViewController:[[AboutWebViewController alloc] initWithTitle:titleStr urlStr:urlStr]]
                                                         animated:YES];
            [self.sideMenuViewController hideMenuViewController];
            break;
        }
            
        case 5:
            //关于
            [self.sideMenuViewController setContentViewController:[[MainNavigationController alloc] initWithRootViewController:  [[AboutViewController alloc]initWithNibName:@"AboutViewController" bundle:nil]]
                                                         animated:YES];
            [self.sideMenuViewController hideMenuViewController];
            break;
//        case 2:
//            //意见反馈
//            [self.sideMenuViewController setContentViewController:[[MainNavigationController alloc] initWithRootViewController:[[FeedBackViewController alloc]init]]
//                                                         animated:YES];
//            [self.sideMenuViewController hideMenuViewController];
//            break;

//        case 4:
//            //体验视频
//            [self.sideMenuViewController setContentViewController:[[MainNavigationController alloc] initWithRootViewController: [[ExperienceCenterViewController alloc] init]]
//                                                         animated:YES];
//            [self.sideMenuViewController hideMenuViewController];
//            break;
        default:
            
            break;
    }
}


- (void)logout{
    
    [SVProgressHUD showWithStatus:@"Loading..."];

    [[DeviceManagement sharedInstance] removeAllDevModelResult:^(int result) {
        if (result == 0 ) {
            //
            [SaveDataModel SaveUsrInforPassWord:@""];
            [SaveDataModel SaveCBSNetWorkState:NO];
            [_netSDK net_closeCBSConnect];
            
            [mUserDefaults setBool:YES forKey:SHOW_EXP_CENTER];
            [mUserDefaults synchronize];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                
                [UIApplication sharedApplication].keyWindow.rootViewController = [[MainNavigationController alloc]initWithRootViewController:[[UserGuideViewController alloc]init]];
            });
            
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"network_error")];
            });
        }
    }];
}

- (void)backToFirstView{
    [self.sideMenuViewController setContentViewController:[[MainNavigationController alloc] initWithRootViewController:[[DeviceListViewController alloc] init]]
                                                     animated:YES];
    [self.sideMenuViewController hideMenuViewController];
}

- (BOOL)shouldAutorotate
{
    //NSLog(@"shouldAutorotate . %ld", (long)[[AppInfomation sharedInstance] isPlayerViewShown]);
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (UIView *)topView{
    if (!_topView) {
        _topView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 130)];
        UIView *blackView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 20)];
        blackView.backgroundColor = myColor;
        [_topView addSubview:blackView];
        [_topView addSubview:self.topGrayView];
        [_topGrayView addSubview:self.headerBtn];
        [_topGrayView addSubview:self.headerLabel];
    }
    return _topView;
}

- (UIImageView *)topGrayView{
    if (!_topGrayView) {
        _topGrayView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 20, SCREEN_WIDTH, 110)];
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            UIImage *tempImage = [UIImage imageWithName:@"user_center_bg.png"];
            dispatch_async(dispatch_get_main_queue(), ^{
                _topGrayView.image = tempImage;
            });
        });
        
    }
    return _topGrayView;
}


- (UIButton *)headerBtn{
    if (!_headerBtn) {
        _headerBtn = [[UIButton alloc]initWithFrame:CGRectMake(12, 55, 40, 40)];

        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            UIImage *tempImage = [UIImage imageWithName:@"personCenter@2x.png"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_headerBtn setBackgroundImage:tempImage forState:UIControlStateNormal];
            });
        });
    }
    return _headerBtn;
}

- (UILabel *)headerLabel{
    if (!_headerLabel) {
        _headerLabel = [[UILabel alloc]initWithFrame:CGRectMake(62, 65, 200, 20)];
        _headerLabel.textAlignment = NSTextAlignmentLeft;
        _headerLabel.text = [SaveDataModel getUserName];
        _headerLabel.textColor = [UIColor blackColor];
    }
    return _headerLabel;
}


- (UIView *)logoutBGView{
    if (!_logoutBGView) {
        _logoutBGView = [[UIView alloc]initWithFrame:CGRectMake(0, 130 + 54 * 6 + 40, self.view.width, 54)];
        _logoutBGView.backgroundColor = [UIColor whiteColor];
    }
    return _logoutBGView;
}

- (UIButton *)logoutBtn{
    if (!_logoutBtn) {
        _logoutBtn = [[UIButton alloc]initWithFrame:CGRectMake((SCREEN_WIDTH * 0.35) - 40,7 ,80, 40)];
        [_logoutBtn addTarget:self action:@selector(logout) forControlEvents:UIControlEventTouchUpInside];
        [_logoutBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        _logoutBtn.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:20];
        [_logoutBtn setTitle:DPLocalizedString(@"Personal_logout") forState:UIControlStateNormal];
    }
    return _logoutBtn;
}

@end
