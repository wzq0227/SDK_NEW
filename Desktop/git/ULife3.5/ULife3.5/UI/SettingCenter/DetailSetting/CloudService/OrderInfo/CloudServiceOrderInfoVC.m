//
//  CloudServiceOrderInfoVC.m
//  ULife3.5
//
//  Created by Goscam on 2017/9/13.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "CloudServiceOrderInfoVC.h"
#import "Masonry.h"
#import "CSPackageTypeVC.h"
#import "CloudRecordingServiceInfoVC.h"
#import "SettingViewController.h"
#import "SaveDataModel.h"
#import "CloudServicePackageInfo.h"
#import "Header.h"

@interface CustomCell : UITableViewCell
@property (strong, nonatomic)  UILabel * titleLabel;
@property (strong, nonatomic)  UILabel *contentLabel;
@end

@implementation CustomCell

-(id)init{
    self = [super init];
    if (self) {
        [self customSubviews];
    }
    return self;
}

- (void)customSubviews{
    
    self.titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 10, 120, 30)];
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
    self.titleLabel.numberOfLines = 0;

    self.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
    
    [self addSubview: self.titleLabel];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.width.equalTo(self).multipliedBy(0.5).offset(-15);
        make.leading.equalTo(self).offset(15);
    }];
    

    self.contentLabel = [[UILabel alloc]initWithFrame:CGRectMake(200, 10, 120, 30)];
    self.contentLabel.textAlignment = NSTextAlignmentRight;
    self.contentLabel.numberOfLines = 0;
    self.contentLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
    
    [self addSubview: self.contentLabel];
    
    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.width.equalTo(self).multipliedBy(0.5).offset(-15);
        make.trailing.equalTo(self).offset(-15);
    }];
}

@end


@interface CloudServiceOrderInfoVC ()<UITableViewDelegate,UITableViewDataSource>
{
    
}


/**
 视频保留时间: 3，7，30天
 */
@property (assign, nonatomic)  NSInteger videoReservedTime;


/**
 套餐有效期
 */
@property (strong, nonatomic)  NSString* packageValidTimeStr;

/**
 套餐状态
 */
@property (assign, nonatomic)  PackageState packageState;

@property (assign, nonatomic)  PackageType packageType;

@property (strong, nonatomic)  NSString *token;


/** 已经购买了的服务 */
@property (strong, nonatomic)  NSArray *orderedServices;
@end

@implementation CloudServiceOrderInfoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self configUI];
}


- (void)viewWillAppear:(BOOL)animated{

    [self needToLoadCSPackageInfo];
}

- (void)configUI{
    [self configTableView];
    
    [self configNavigationBar];
    self.title = DPLocalizedString(@"PackageOrder");
    
    self.renewBtn.layer.cornerRadius = 20;
    self.renewBtn.backgroundColor = myColor;
    [self.renewBtn setTitle:DPLocalizedString(@"PackageRenew") forState:0];
    [self.renewBtn addTarget:self action:@selector(gotoPaymentVC:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)configNavigationBar{
    [self customLeftBarButtonItem];
}

#pragma mark -- 添加左 item
- (void)customLeftBarButtonItem
{
//    UIImage *image = [UIImage imageNamed:@"addev_back"];
//    EnlargeClickButton *button = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
//    button.frame = CGRectMake(0, 0, 70, 40);
//    button.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 50);
//    [button setImage:image forState:UIControlStateNormal];
//    [button addTarget:self
//               action:@selector(backBtnAction:)
//     forControlEvents:UIControlEventTouchUpInside];
//    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
//    leftBarButtonItem.style = UIBarButtonItemStylePlain;
//    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
}

//1.Setting -> OrderInfo  2.Setting->PackageInfo->PaymentType -> OrderInfo
- (void)backBtnAction:(id)sender{
    __weak typeof(UIViewController*) weakVC = nil;

    for (UIViewController *vc in self.navigationController.viewControllers) {
        if([vc isKindOfClass:[SettingViewController class]]){
            weakVC = vc;
            break;
        }
    }
    if (weakVC) {
        [self.navigationController popToViewController:weakVC animated:YES];
    }else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)needToLoadCSPackageInfo{
    [self queryServiceListOfDevice];
}

- (void)queryServiceListOfDevice{
    
    self.token = [mUserDefaults objectForKey:USER_TOKEN];
    [SVProgressHUD showWithStatus:@"loading..."];
    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api/cloudstore/cloudstore-service/service/list",kCloud_IP];
    
    NSString *urlStrWithParams = [NSString stringWithFormat:@"%@?device_id=%@&token=%@&username=%@&version=1.0",urlStr,self.deviceId,self.token,[SaveDataModel getUserName]];
    
    __weak typeof(self) wSelf = self;
    [[CSNetworkLib sharedInstance] requestWithURLStr:urlStrWithParams method:@"GET" result:^(int result, NSData *data) {
        NSDictionary  *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        if (result == 0 ) {
            
            if (!dict[@"data"]) {
                [wSelf.navigationController popViewControllerAnimated:NO];
                return ;
            }
            //0 正在用 1200 云存储服务已过期
            NSMutableArray *dataArray = [NSMutableArray array];
            for (NSDictionary *testDict in dict[@"data"]) {
                CSServiceStatus status = [testDict[@"status"]intValue];
                if ((status == CSServiceStatusInUse || status == CSServiceStatusUnused) &&testDict ) {
                    [dataArray addObject:testDict];
                }
            }
            if (dataArray.count > 0) {
                wSelf.orderedServices = dataArray;
                wSelf.tableView.hidden = NO;
                [wSelf.tableView reloadData];
            }else{
                //显示一个最近已过期的
                NSUInteger latestExpiredTime = 0;
                NSDictionary *latestPackageInfo = nil;
                for (NSDictionary *testDict in dict[@"data"]) {
                    CSServiceStatus status = [testDict[@"status"]intValue];
                    if (status == CSServiceStatusExpired  ) {
                        NSUInteger dataExpiredTime = [testDict[@"dataExpiredTime"]integerValue];
                        if (dataExpiredTime>latestExpiredTime) {
                            latestExpiredTime = dataExpiredTime;
                            latestPackageInfo = testDict;
                        }
                    }
                }
                if (!latestPackageInfo) {
                    [wSelf.navigationController popViewControllerAnimated:NO];
                    return ;
                }
                
                [dataArray addObject:latestPackageInfo];
                wSelf.orderedServices = dataArray;
                wSelf.tableView.hidden = NO;
                [wSelf.tableView reloadData];
                
//                [wSelf gotoPaymentVC:nil];
            }
            
        }else if(result == 1204){ //1204 服务不可用（未开通或已过期）
        }
        [wSelf showQueryResult:result];
    }];
}

- (void)showQueryResult:(int)result{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( result==0 ) {
            [SVProgressHUD dismiss];
        }else{
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Get_data_failed")];
        }
    });
}

- (void)configTableView{
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.scrollEnabled = YES;
    self.tableView.hidden = YES;
}

- (void)gotoPaymentVC:(id)sender{
    
    CSPackageTypeVC *vc = [[CSPackageTypeVC alloc] init];
//    CloudRecordingServiceInfoVC *vc = [CloudRecordingServiceInfoVC new];
//    vc.orderedPlanId = self.curServiceResp.planId;
    vc.deviceModel      = self.deviceModel;
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)setDeviceModel:(DeviceDataModel *)deviceModel{
    _deviceModel = deviceModel;
    _deviceId = deviceModel.DeviceId;
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 3*self.orderedServices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    CustomCell *cell = [[CustomCell alloc] init];
    CSQueryCurServiceResp *service = [CSQueryCurServiceResp yy_modelWithDictionary:self.orderedServices[indexPath.row/3]];

    
    switch (indexPath.row%3) {
        case 0:
        {
            cell.titleLabel.text      = [NSString stringWithFormat:@"%d%@%@",service.dateLife,DPLocalizedString(@"CS_PackageType_Days"),DPLocalizedString(@"CS_PackageType_CS")];

            cell.contentLabel.textColor = [self packageStateColorWithValue:service.status];
            cell.contentLabel.text = [self packageStateStringWithValue:service.status];
            break;
        }
        case 1:
        {
            cell.titleLabel.text = DPLocalizedString(@"PackageValidTime");
            cell.contentLabel.text = [self convertedValidTimeWithSartTime:service.startTime endTime:service.preinvalidTime];
            break;
        }
        case 2:
        {
            cell.titleLabel.text = DPLocalizedString(@"VideoReservedTime");
            cell.contentLabel.text =  [NSString stringWithFormat:@"%d %@%@", service.dateLife ,DPLocalizedString(@"CloudService_Day"),(isENVersion==1&&service.dateLife>1)?@"s":@""]  ;
            break;
        }
        default:
            break;
    }
    cell.separatorInset = UIEdgeInsetsZero;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (NSString*)convertedServiceLife:(int)serviceLife{
    NSInteger months = serviceLife/30;
    NSInteger years = months/12;
    NSString *suffixStr = DPLocalizedString(years>0?@"CS_PackageType_Year":@"CS_PackageType_Month");
    
    return [NSString stringWithFormat:@"%@%@",@(years>0?years:months), suffixStr];
}

- (UIColor *)packageStateColorWithValue:(CSServiceStatus)status{
    switch (status) {
        case CSServiceStatusExpired:
        {
            return UIColor.grayColor;
        }
        case CSServiceStatusInUse:
        case CSServiceStatusUnused:
        {
            return myColor;
        }
        default:{
            return [UIColor blackColor];
        }
    }
    return [UIColor blackColor];
}

- (NSString*)packageStateStringWithValue:(CSServiceStatus)status{
    switch (status) {
        case CSServiceStatusExpired:
        {
            return DPLocalizedString(@"PackageStateExpired");
        }
        case CSServiceStatusInUse:
        {
            return DPLocalizedString(@"PackageStateInUse");
            break;
        }
        case CSServiceStatusUnused:
        {
            return DPLocalizedString(@"PackageStateUnused");
            break;
        }
        default:
            break;
    }
    return DPLocalizedString(@"PackageStateUnused");
}


- (NSString *)convertedValidTimeWithSartTime:(NSString *)startTime endTime:(NSString *)endTime {
    
    
    
    NSString *validTimeBegin = [[self dateStringWithTS:startTime ] substringToIndex:10];
    NSString *validTimeEnd   = [[self dateStringWithTS:endTime ] substringToIndex:10];
    
    return [NSString stringWithFormat:@"%@-%@", validTimeBegin , validTimeEnd];
}

- (NSString *)dateStringWithTS:(NSString*)timestamp{
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp.doubleValue];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"YYYY/MM/dd hh:mm:ss"];
    NSString *DateTime = [formatter stringFromDate:date];
    NSLog(@"___________________________________________dateStringConverted:%@",DateTime);
    return DateTime;
}


#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0.5;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 60)];
    [footerView addSubview:self.renewBtn];
    return footerView;
}

- (UIButton *)renewBtn{
    if (!_renewBtn) {
        _renewBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, SCREEN_WIDTH-40, 40)];
    }
    return _renewBtn;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 80;
}

@end
