//
//  CheckNetViewController.m
//  ULife3.5
//
//  Created by AnDong on 2018/8/29.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "CheckNetViewController.h"
#import "CheckNetTableViewCell.h"
#import "CBSCommand.h"
#import "CMSCommand.h"
#import "NetSDK.h"

typedef enum checkStatus {
    IsChecking,
    CheckWaiting,
    CheckSuccess,
    CheckFailed
} CheckStatus;

static const NSString *successIP = @"34.213.109.255";
static const NSString *failedIP = @"0.0.0.0";
static const int defaultPort = 6001;

@interface CheckNetViewController () <UITableViewDataSource, UITableViewDelegate> {
    NSMutableArray *arrayM;
}

@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UIImageView *rotateImage;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIButton *checkBtn;
@property (weak, nonatomic) IBOutlet UIButton *checkFailedBtn;

@end

@implementation CheckNetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = DPLocalizedString(@"NetCheckTitle");
    self.topLabel.text = DPLocalizedString(@"NetCheckTopTip");
    self.topLabel.hidden = YES;
    self.label.text = DPLocalizedString(@"NetCheckSuccessfulTip");
    [self.checkBtn setTitle:DPLocalizedString(@"NetcheckReload") forState:UIControlStateNormal];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    arrayM = [@[] mutableCopy];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self reloadCheckDataSource];
    [self updateCheckUIWithCheckStatus:IsChecking];
    [self getCBS_PORT];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return arrayM.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CheckNetTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CheckTableViewCell"];
    if (!cell)
        cell = [[NSBundle mainBundle] loadNibNamed:@"CheckNetTableViewCell" owner:self options:nil].lastObject;

    NSDictionary *dic = arrayM[indexPath.row];
    cell.dic = dic;

    return cell;
}

#pragma mark - Check事件
- (void)getCBS_PORT
{
    NSString *ipconfig;
    
    if(isENVersion)
    {
        ipconfig = enCBS_IP;
    }
    else
    {
        ipconfig = kCBS_IP;
    }
    
    CMD_AppGetBSAddressRequest *req = [CMD_AppGetBSAddressRequest new];
    req.UserName = @"test";
    req.Password = @"test123";
    req.ServerType = @[@3,@4];
    [[NetSDK sharedInstance] net_getCBSPortWithIP:ipconfig port:6001 data:[req requestCMDData] responseBlock:^(int result, NSDictionary *dict) {
        NSString *criptkey = dict[@"CryptKey"];
        [mUserDefaults setObject:criptkey forKey:@"CryptKey"];
        [[NetSDK sharedInstance] setcriptKey:criptkey];
        if (result == 0) {
            //第一步成功
            [self changeCheckNetDefaultIPWithStatus:CheckSuccess];
            
            NSArray *serverList = dict[@"ServerList"];
            for (NSDictionary *addressDict in serverList) {
                ServerAddress *serverAddr = [ServerAddress yy_modelWithDictionary:addressDict];
                switch (serverAddr.Type) {
                    case 2:
                        [mUserDefaults setObject:addressDict forKey:@"MPSAddress"];
                        [self dataSourceAddDicWithIp:addressDict[@"Address"] port:[addressDict[@"Port"] intValue]];
                        [self checkNetWithIp:addressDict[@"Address"] :[addressDict[@"Port"] intValue] status:CheckSuccess];
                        break;
                    case 3:
                        [mUserDefaults setObject:addressDict forKey:kCGSA_ADDRESS];
                        [[NetSDK sharedInstance] setCBSAddress:addressDict[@"Address"] port:[addressDict[@"Port"] intValue]];
                        [self dataSourceAddDicWithIp:addressDict[@"Address"] port:[addressDict[@"Port"] intValue]];
                        [self checkNetWithIp:addressDict[@"Address"] :[addressDict[@"Port"] intValue] status:IsChecking];
                        [self checkCBSAddress:addressDict[@"Address"] port:[addressDict[@"Port"] intValue]];
                        break;
                    case 4:
                    {
                        [mUserDefaults setObject:addressDict forKey:@"UPSAddress"];
                        [self dataSourceAddDicWithIp:addressDict[@"Address"] port:[addressDict[@"Port"] intValue]];
                        [self checkNetWithIp:addressDict[@"Address"] :[addressDict[@"Port"] intValue] status:IsChecking];
                        break;
                    }
                    default:
                        break;
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self checkUPSAddress];
                });
            });
            
        }else{
            //CMS检测连接失败
            [self changeCheckNetDefaultIPWithStatus:CheckFailed];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateCheckUIWithCheckStatus:CheckFailed];
            });
        }
        
    }];
}

- (void)checkNetWithIp:(NSString *)ip :(int)port status:(CheckStatus)status {
    NSString *targetStr = [self getNewIPWith:ip :port];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for (int i = 0; i < arrayM.count; ++i) {
            if (![arrayM[i][@"ip"] isEqualToString:targetStr])
                continue;
            
            arrayM[i][@"status"] = @(status);
        }
        
        [self.tableView reloadData];
    });
}

- (void)changeCheckNetDefaultIPWithStatus:(CheckStatus)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *ip = status == CheckSuccess ? [self getNewIPWith:(NSString *)successIP :defaultPort] : [self getNewIPWith:(NSString *)failedIP :defaultPort];
        [arrayM removeAllObjects];
        NSMutableDictionary *dic = [@{@"ip" : ip,
                                      @"status" : @(status)
                                      } mutableCopy];
        [arrayM addObject:dic];
        [self.tableView reloadData];
    });
}

- (void)dataSourceAddDicWithIp:(NSString *)ip port:(int)port {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableDictionary *dic = [@{@"ip" : [self getNewIPWith:ip :port],
                                      @"status" : @(CheckWaiting)
                                      } mutableCopy];
        [arrayM addObject:dic];
        [self.tableView reloadData];
    });
}

- (void)checkCBSAddress:(NSString *)ip port:(int)port {
    
    CBS_GetDevListRequest *req  = [CBS_GetDevListRequest new];
    BodyGetDevListRequest *body = [BodyGetDevListRequest new];
    body.UserName = @"CheckNetTest";
    
    NSDictionary *dic = @{@"MessageType":req.MessageType, @"Body":[body yy_modelToJSONObject]};
    [[NetSDK sharedInstance] checkNet:ip port:port data:dic responseBlock:^(int result) {
        if (result == 0) {
            [self checkNetWithIp:ip :port status:CheckSuccess];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateCheckUIWithCheckStatus:CheckSuccess];
            });
        }
        else {
            [self checkNetWithIp:ip :port status:CheckFailed];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateCheckUIWithCheckStatus:CheckFailed];
            });
        }
    }];
}

- (void)checkUPSAddress{
    ServerAddress *upsAddr = [ServerAddress yy_modelWithDictionary:[mUserDefaults objectForKey:@"UPSAddress"]];
    
    NSString *bundid = [NSString stringWithFormat:@"%@.ios",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]];
    
    NSString *appName = [NSString stringWithFormat:@"%@ios",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"]];
    
    NSDictionary *requestDict = @{
                                  @"MessageType":@"GetAppNewestFromUPSRequest",
                                  @"Body":@{@"AppName":appName,
                                            @"PackageName":bundid}
                                  };
    [[NetSDK sharedInstance] checkNet:upsAddr.Address port:upsAddr.Port data:requestDict responseBlock:^(int result) {
        if (result == 0) {
            [self checkNetWithIp:upsAddr.Address :upsAddr.Port status:CheckSuccess];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateCheckUIWithCheckStatus:CheckSuccess];
            });
        }
        else {
            [self checkNetWithIp:upsAddr.Address :upsAddr.Port status:CheckFailed];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateCheckUIWithCheckStatus:CheckFailed];
            });
        }
    }];
}

- (void)updateCheckUIWithCheckStatus:(CheckStatus)status {
    
    switch (status) {
        case IsChecking:
            [self startAnimation];
            self.topLabel.hidden = YES;
            self.label.hidden = NO;
            self.checkBtn.hidden = YES;
            self.label.text = DPLocalizedString(@"NetCheckSuccessfulTip");
            self.label.textAlignment = NSTextAlignmentCenter;
            self.checkFailedBtn.hidden = YES;
            self.rotateImage.hidden = NO;
            break;
        
        case CheckSuccess:
            [self endAnimation];
            self.topLabel.hidden = NO;
            self.checkBtn.hidden = YES;
            self.label.hidden = YES;
            self.checkFailedBtn.hidden = NO;
            [self.checkFailedBtn setTitle:@"PASS" forState:UIControlStateNormal];
            [self.checkFailedBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [self.checkFailedBtn setBackgroundImage:[UIImage imageNamed:@"CheckNetFailWhiteBtn"] forState:UIControlStateNormal];
            self.rotateImage.hidden = YES;
            break;
            
        case CheckFailed:
            [self endAnimation];
            self.topLabel.hidden = NO;
            self.checkBtn.hidden = NO;
            self.label.hidden = NO;
            self.label.text = DPLocalizedString(@"NetCheckFailedTip");
            self.label.textAlignment = NSTextAlignmentLeft;
            self.checkFailedBtn.hidden = NO;
            [self.checkFailedBtn setTitle:@"FAIL" forState:UIControlStateNormal];
            [self.checkFailedBtn setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal];
            [self.checkFailedBtn setBackgroundImage:[UIImage imageNamed:@"CheckNetFailBtn"] forState:UIControlStateNormal];
            self.rotateImage.hidden = YES;
            
        default:
            break;
    }
}

- (IBAction)checkBtnDidClick:(id)sender {
    [self reloadCheckDataSource];
    [self updateCheckUIWithCheckStatus:IsChecking];
    [self getCBS_PORT];
}

- (void)reloadCheckDataSource {
    [arrayM removeAllObjects];
    
    NSMutableDictionary *dic = [@{@"ip" : [self getNewIPWith:(NSString *)@"" :defaultPort],
                                  @"status" : @(IsChecking)
                                  } mutableCopy];
    [arrayM addObject:dic];
    [self.tableView reloadData];
}

- (NSString *)getNewIPWith:(NSString *)ip :(int)port {
    if ([ip isEqualToString:(NSString *)failedIP])
        return [NSString stringWithFormat:@"%@:%d", ip, port];
    
    NSArray *tmp = [ip componentsSeparatedByString:@"."];
    if (tmp.count < 4)
        return @"x.x.x.x";
    
    return [NSString stringWithFormat:@"x.x.%@.%@:%d", tmp[2], tmp[3], port];
}

- (void)startAnimation
{
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat:M_PI * 2.0];
    rotationAnimation.duration = 2;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount =ULLONG_MAX;
    rotationAnimation.removedOnCompletion=NO;
    [self.rotateImage.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)endAnimation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.rotateImage.layer removeAllAnimations];
    });
}
@end
