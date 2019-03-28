//
//  
//  云存储套餐类型选择
//


#import "CSPackageTypeVC.h"
#import "CSNetworkLib.h"
#import "Masonry.h"
#import "SaveDataModel.h"
#import "CloudServicePaymentTypeVC.h"

#define TableViewHeaderHeight 30
#define MCellIdentifier (@"CSPackageTypeTableCell")
#define HeightForStatusBarAndNaviBar (SYName_iPhone_X == [SYDeviceInfo syDeviceName]?88:64)


@interface CSPackageTypeTableCell:UITableViewCell
/** ☑️图标 */
@property (strong, nonatomic)  UIImageView *checkImageView;

/** 数据保存时间 Label */
@property (strong, nonatomic)  UILabel *dataLifeLabel;

/** 套餐有效期 Label */
@property (strong, nonatomic)  UILabel *serviceLifeLabel;

/** 套餐原价格 Label */
@property (strong, nonatomic)  UILabel *originalPriceLabel;

/** 套餐价格 Label */
@property (strong, nonatomic)  UILabel *priceLabel;

@property (strong, nonatomic)  UIButton *promotionBtn;

- (void)makeConstraints;
@end

@implementation CSPackageTypeTableCell

- (void)makeConstraints{
    [self addSubview: self.checkImageView];
    [self addSubview: self.dataLifeLabel];
    [self addSubview: self.serviceLifeLabel];
    [self addSubview: self.originalPriceLabel];
    [self addSubview: self.priceLabel];
    [self addSubview: self.promotionBtn];


    [self.checkImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.leading.equalTo(self).offset(20);
        make.width.height.mas_equalTo(20);
    }];
    
    [self.dataLifeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.leading.equalTo(self.checkImageView.mas_trailing).offset(4);
        make.width.mas_equalTo(120);
    }];
    
    [self.serviceLifeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.mas_equalTo(120);
    }];
    
    [self.promotionBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self);
        make.trailing.equalTo(self).offset(-10);
        make.width.mas_equalTo(30);
        make.height.mas_equalTo(28);
    }];
    
    [self.priceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(9);
        make.trailing.equalTo(self.promotionBtn.mas_leading).offset(0);
        make.width.mas_equalTo(60);
    }];
    
    [self.originalPriceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.priceLabel.mas_bottom).offset(3);
        make.centerX.equalTo(self.priceLabel);
        make.width.mas_equalTo(60);
    }];
    
}


- (UIImageView*)checkImageView{
    if (!_checkImageView) {
        _checkImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    }
    return _checkImageView;
}

- (UILabel*)dataLifeLabel{
    if (!_dataLifeLabel) {
        _dataLifeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
        _dataLifeLabel.font = [UIFont systemFontOfSize:18];
        _dataLifeLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _dataLifeLabel;
}

- (UILabel*)serviceLifeLabel{
    if (!_serviceLifeLabel) {
        _serviceLifeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
        _serviceLifeLabel.font = [UIFont systemFontOfSize:18];
        _serviceLifeLabel.textAlignment = NSTextAlignmentCenter;

    }
    return _serviceLifeLabel;
}

- (UILabel*)priceLabel{
    if (!_priceLabel) {
        _priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
        _priceLabel.font = [UIFont systemFontOfSize:15];
        _priceLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _priceLabel;
}

- (UILabel*)originalPriceLabel{
    if (!_originalPriceLabel) {
        _originalPriceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
        _originalPriceLabel.font = [UIFont systemFontOfSize:15];
        _originalPriceLabel.textColor = [UIColor lightGrayColor];
        _originalPriceLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _originalPriceLabel;
}

- (UIButton*)promotionBtn{
    if (!_promotionBtn) {
        _promotionBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        _promotionBtn.userInteractionEnabled = NO;
        _promotionBtn.titleLabel.font = [UIFont systemFontOfSize:13];
        _promotionBtn.titleLabel.numberOfLines = 0;
        _promotionBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
//        [_promotionBtn setTitle:DPLocalizedString(@"CS_PackageType_Promotion") forState:UIControlStateNormal];
        [_promotionBtn setBackgroundImage:[UIImage imageNamed:@"CS_PackageType_PromotionIcon"] forState:UIControlStateNormal];
    }
    return _promotionBtn;
}
@end

@interface CSPackageTypeVC ()
<UITableViewDelegate,UITableViewDataSource,UITextViewDelegate
>
{
    
}

#pragma mark - Property_Declare

@property (strong, nonatomic)  UITableView *packageTypeTableView;

@property (assign, nonatomic)  NSInteger selectedIndex;

@property (strong, nonatomic)  CSPackageInfo *packageInfo;

@property (strong, nonatomic)  CSNetworkLib *csNetworkLib;

@property (strong, nonatomic)  NSString *csToken;

@property (strong, nonatomic)  NSMutableArray *packageTypeArray;

@property (strong, nonatomic)  UIButton *tryFreePackageBtn;

@property (strong, nonatomic)  UIButton *payBtn;

@property (strong, nonatomic)  UITextView *csAgreementTextView;

//免费套餐
@property (strong, nonatomic)  CSQueryFreePackageResp *queryFreePackageResp;

@property (strong, nonatomic)  CSCreateFreePackageResp *createFreePackageResp;

@end

@implementation CSPackageTypeVC



- (void)viewWillDisappear:(BOOL)animated  {
    
    [super viewWillDisappear:animated];
    
    [SVProgressHUD dismiss];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configUI];
    
    [self configModel];
}

- (void)configUI{
    
    [self configNaviBar];
    
    [self addSubviews];
    
    [self makeConstraints];
}

- (void)configModel{
    [self loadPackageTypes];
    
    [self queryFreePackageAvailable];
}

- (void)setDeviceModel:(DeviceDataModel *)deviceModel{
    _deviceModel = deviceModel;
    _deviceId = deviceModel.DeviceId;
}

- (void)addSubviews{
    [self.view addSubview:self.packageTypeTableView];
}

- (void)configNaviBar{
    self.navigationItem.titleView = [CommonlyUsedFounctions titleLabelWithStr:DPLocalizedString(@"Setting_CloudService")];

    self.view.backgroundColor = mCustomBgColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[UIButton alloc]initWithFrame:CGRectMake(0, 0, 50, 40)]];
}

-(BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange{
    if ([[URL scheme] isEqualToString:@"CSAgreementURL"]) {
        NSURL *url = [NSURL URLWithString:@"http://www.ulifecam.com/common/cloud-storage-agreements.html"];
        if ([[UIApplication sharedApplication]canOpenURL:url]) {
            [[UIApplication sharedApplication]openURL:url];
        }
        return NO;
    }
    return YES;
}



#pragma mark - Property_LazilyLoad
- (UITableView*)packageTypeTableView{
    if (!_packageTypeTableView) {
        _packageTypeTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        [_packageTypeTableView registerClass:[CSPackageTypeTableCell class] forCellReuseIdentifier: MCellIdentifier ];
        
        _packageTypeTableView.delegate = self;
        _packageTypeTableView.dataSource = self;
        _packageTypeTableView.backgroundColor = mCustomBgColor;
    }
    return _packageTypeTableView;
}

- (UIButton*)tryFreePackageBtn{
    if (!_tryFreePackageBtn) {
        _tryFreePackageBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
        _tryFreePackageBtn.layer.cornerRadius = 5;
        _tryFreePackageBtn.backgroundColor = [UIColor colorWithHexString:@"#F08519"];
        _tryFreePackageBtn.titleLabel.numberOfLines = 0;
        _tryFreePackageBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        _tryFreePackageBtn.hidden = YES;
        [_tryFreePackageBtn setTitle:DPLocalizedString(@"CS_PackageType_FreeTryTitle") forState:UIControlStateNormal];
        [_tryFreePackageBtn addTarget:self action:@selector(createFreePackage:) forControlEvents: UIControlEventTouchUpInside];
    }
    return _tryFreePackageBtn;
}


- (UITextView*)csAgreementTextView{
    if (!_csAgreementTextView) {
        _csAgreementTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 200, 20)];
        
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString: DPLocalizedString(@"CS_Agree_CSAgreement")];
        
        [attributedString addAttribute:NSLinkAttributeName
                                 value:@"CSAgreementURL://"
                                 range:[[attributedString string] rangeOfString:DPLocalizedString(@"CS_CSAgreement")]];
        
        [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14] range:NSMakeRange(0, attributedString.length)];
        _csAgreementTextView.attributedText = attributedString;
        _csAgreementTextView.backgroundColor = [UIColor clearColor];
        _csAgreementTextView.editable = NO;
        _csAgreementTextView.scrollEnabled = NO;
        _csAgreementTextView.delegate = self;
        _csAgreementTextView.textAlignment = NSTextAlignmentCenter;
        _csAgreementTextView.linkTextAttributes = @{NSForegroundColorAttributeName: myColor,
                                                          NSUnderlineColorAttributeName: [UIColor lightGrayColor],
                                                          NSUnderlineStyleAttributeName: @(NSUnderlinePatternSolid)};

    }
    return _csAgreementTextView;
}

- (UIButton*)payBtn{
    if (!_payBtn) {
        _payBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
        _payBtn.layer.cornerRadius = 23;
        _payBtn.backgroundColor = myColor;
        [_payBtn setTitle:DPLocalizedString(@"CS_Package_Pay") forState:UIControlStateNormal];
        [_payBtn addTarget:self action:@selector(payBtnAction:) forControlEvents: UIControlEventTouchUpInside];
    }
    return _payBtn;
}

- (void)payBtnAction:(id)sender{
    
    CSPackageInfo *info = _selectedIndex<self.packageTypeArray.count?self.packageTypeArray[_selectedIndex]:nil;
    
    CloudServicePaymentTypeVC *vc = [CloudServicePaymentTypeVC new];
    vc.deviceModel                = _deviceModel;
    vc.deviceId                   = _deviceId;
    vc.packageInfo                = info;
    
    vc.packageName                = [NSString stringWithFormat:@"%@%@%@%@%@",info.dataLife,DPLocalizedString(@"CS_PackageType_Days"),DPLocalizedString(@"CS_PackageType_CS"),[self convertedServiceLifeStr: info.serviceLife],DPLocalizedString(@"CS_PackageType_Package")];
    
    vc.packageCount           = 1;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - View_Layout
- (void)makeConstraints{
    
    [self.packageTypeTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.top.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.packageTypeArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    CSPackageTypeTableCell *cell = [tableView dequeueReusableCellWithIdentifier:MCellIdentifier];
    
    [cell makeConstraints];

    CSPackageInfo *info = self.packageTypeArray[indexPath.row];
    
    cell.checkImageView.image = [UIImage imageNamed: indexPath.row==_selectedIndex?@"CS_PackageType_Check":@"CS_PackageType_UnCheck"];
    
    NSString *prefix =   isENVersionNew?@"$":@"¥";
    cell.priceLabel.text = [NSString stringWithFormat:@"%@%@",prefix,info.price];
    cell.originalPriceLabel.text = [NSString stringWithFormat:@"%@%@",prefix,info.originalPrice];
    
    cell.originalPriceLabel.attributedText =  [[NSAttributedString alloc] initWithString: cell.originalPriceLabel.text attributes:@{NSStrikethroughStyleAttributeName:[NSNumber numberWithInteger:NSUnderlineStyleSingle]}];

    cell.dataLifeLabel.text = [NSString stringWithFormat:@"%@%@",info.dataLife,DPLocalizedString(@"CS_PackageType_Days")] ;
    cell.serviceLifeLabel.text = [self convertedServiceLifeStr: info.serviceLife] ;

    cell.promotionBtn.hidden = [info.price floatValue]< 0.001 || (isENVersionNew);

    return cell;
}

- (NSString*)convertedServiceLifeStr:(NSString*)serviceLife{
    NSInteger months = serviceLife.integerValue/30;
    NSInteger years = months/12;
    NSString *suffixStr = DPLocalizedString(years>0?@"CS_PackageType_Year":@"CS_PackageType_Month");
    
    NSString *sufStrs = @"";
    if (isENVersionNew) {
        if (years>1) {
            sufStrs = @"s";
        }else if (years==0 && months > 1){
            sufStrs = @"s";
        }
    }
    return [NSString stringWithFormat:@"%@%@%@",@(years>0?years:months), suffixStr,sufStrs];
}


#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;//SCREEN_WIDTH/375*46;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return TableViewHeaderHeight;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return SCREEN_HEIGHT-HeightForStatusBarAndNaviBar-TableViewHeaderHeight - 50*self.packageTypeArray.count;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, TableViewHeaderHeight)];
    view.backgroundColor = mCustomBgColor;
    
    UILabel *titleForDataLife = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
    titleForDataLife.textAlignment = NSTextAlignmentLeft;
    titleForDataLife.font = [UIFont systemFontOfSize:14];
    titleForDataLife.text = DPLocalizedString(@"CS_PackageType_DataLife");
    
    UILabel *titleForPackageType = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
    titleForPackageType.textAlignment = NSTextAlignmentCenter;
    titleForPackageType.font = [UIFont systemFontOfSize:14];
    titleForPackageType.text = DPLocalizedString(@"CS_PackageType_PackageType");

    UILabel *titleForPrice = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
    titleForPrice.textAlignment = NSTextAlignmentCenter;
    titleForPrice.font = [UIFont systemFontOfSize:14];
    titleForPrice.text = DPLocalizedString(@"CS_PackageType_Price");

    [view addSubview:titleForDataLife];
    [view addSubview:titleForPackageType];
    [view addSubview:titleForPrice];
    
    [titleForDataLife mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.offset(10);
        make.centerY.equalTo(view);
    }];
    
    [titleForPackageType mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(view);
    }];
    
    [titleForPrice mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(view);
        make.trailing.equalTo(view).offset(-54);
    }];
    
    return view;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    CGFloat footerViewHeight = SCREEN_HEIGHT-HeightForStatusBarAndNaviBar-TableViewHeaderHeight - 50*self.packageTypeArray.count;
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, footerViewHeight)];
    view.backgroundColor = mCustomBgColor;
    
    [view addSubview:self.tryFreePackageBtn];
    [view addSubview:self.payBtn];
//    [view addSubview:self.csAgreementTextView];
    
    CGFloat scaleFactor = pow(SCREEN_WIDTH/375, 5);
    
    [self.tryFreePackageBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(view).offset(26*scaleFactor);
        make.centerX.equalTo(view);
        make.leading.equalTo(view).offset(60);
        make.height.mas_equalTo(46);
    }];
    
    [self.payBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tryFreePackageBtn.mas_bottom).offset(26*scaleFactor);
        make.centerX.equalTo(view);
        make.leading.equalTo(view).offset(25);
        make.height.mas_equalTo(46);
    }];
    
//    [self.csAgreementTextView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.centerX.equalTo(view);
//        make.leading.equalTo(view).offset(25);
//        make.bottom.equalTo(view).offset(-6*scaleFactor);
//    }];
    
    return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    _selectedIndex = indexPath.row;
    [self.packageTypeTableView reloadData];
}


#pragma mark - Model
#pragma mark 加载套餐ID和价格
- (void)loadPackageTypes{
    
    self.csToken = [mUserDefaults objectForKey:USER_TOKEN];
    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api/cloudstore/cloudstore-service/plan?token=%@&username=%@", kCloud_IP,self.csToken,[SaveDataModel getUserName]];
    __weak typeof(self) wSelf = self;
    [[CSNetworkLib sharedInstance] requestWithURLStr:urlStr method:@"POST" result:^(int result, NSData *data) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        if (result == 0) {
            NSArray *tempArray = dict[@"data"];
            for (int i=0; i<tempArray.count; i++) {
                CSPackageInfo *info = [CSPackageInfo yy_modelWithDictionary:tempArray[i]];
                if (!wSelf.packageTypeArray) {
                    wSelf.packageTypeArray = [NSMutableArray arrayWithCapacity:1];
                }
                [wSelf.packageTypeArray addObject:info];
            }
            [wSelf.packageTypeTableView reloadData];
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@",dict[@"message"]] ];
            });
        }
    }];
}

#pragma mark 查询免费套餐
- (void)queryFreePackageAvailable{
    
    self.csToken = [mUserDefaults objectForKey:USER_TOKEN];

    CSQueryFreePackageReq *req = [CSQueryFreePackageReq new];
    req.token                  = self.csToken ;
    req.device_id              = self.deviceId;
    req.username               = [SaveDataModel getUserName];
    
    NSString *reqParamStr = [req requestParamStr];
    
    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api/cloudstore/cloudstore-service/free-plan%@", kCloud_IP,reqParamStr];
    __weak typeof(self) wSelf = self;
    [[CSNetworkLib sharedInstance] requestWithURLStr:urlStr method:@"GET" result:^(int result, NSData *data) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        if (result == 0) {
            NSDictionary *tempDict = dict[@"data"];
            wSelf.queryFreePackageResp = [CSQueryFreePackageResp yy_modelWithDictionary:tempDict];
            wSelf.tryFreePackageBtn.hidden = wSelf.queryFreePackageResp==nil;
            [wSelf.tryFreePackageBtn setTitle:[wSelf titleForTryFreePackge] forState:0];
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@",dict[@"message"]] ];
            });
        }
    }];
}

- (void)createFreePackage:(id)sender{
    
    [SVProgressHUD showWithStatus:@"Loading..."];
    
    self.csToken = [mUserDefaults objectForKey:USER_TOKEN];
    
    CSCreateFreePackageReq *req = [CSCreateFreePackageReq new];
    req.plan_id                 = self.queryFreePackageResp.planId;
    req.token                   = self.csToken ;
    req.device_id               = self.deviceId;
    req.username               = [SaveDataModel getUserName];
    
    NSString *reqParamStr = [req requestParamStr];
    
    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api/pay/pay-service/inland/cloudstore/free-order/create%@", kCloud_IP,reqParamStr];
    __weak typeof(self) wSelf = self;
    [[CSNetworkLib sharedInstance] requestWithURLStr:urlStr method:@"POST" result:^(int result, NSData *data) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        if (result == 0) {
            NSDictionary *tempDict = dict[@"data"];
            wSelf.createFreePackageResp = [CSCreateFreePackageResp yy_modelWithDictionary:tempDict];
            [wSelf payFreePackage];
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@",dict[@"message"]] ];
            });
        }
    }];
}

- (void)payFreePackage{
    
    self.csToken = [mUserDefaults objectForKey:USER_TOKEN];
    
    CSPayFreePackageReq *req = [CSPayFreePackageReq new];
    req.order_no             = self.createFreePackageResp.orderNo;
    req.token                = self.csToken ;
    req.username               = [SaveDataModel getUserName];
    
    NSString *reqParamStr = [req requestParamStr];
    
    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api/pay/pay-service/inland/cloudstore/payment-free%@", kCloud_IP,reqParamStr];
    __weak typeof(self) wSelf = self;
    [[CSNetworkLib sharedInstance] requestWithURLStr:urlStr method:@"POST" result:^(int result, NSData *data) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        if (result == 0) {
                //支付免费订单成功，返回套餐列表界面
            [wSelf gotoOrderInfoVC];
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@",dict[@"message"]] ];
            });
        }
    }];
}

- (void)gotoOrderInfoVC{
    
    [SVProgressHUD dismiss];
    
    [self.navigationController popViewControllerAnimated:YES];
    
}

- (NSString*)titleForTryFreePackge{
    NSString *titleStr = DPLocalizedString(@"CS_PackageType_FreeTryTitle2");
    
    NSInteger months = self.queryFreePackageResp.serviceLife.integerValue/30;
    NSInteger years = months/12;
    
    NSString *yearStr = DPLocalizedString(@"CS_PackageType_Year");
    NSString *monthStr = DPLocalizedString(@"CS_PackageType_Month");
    
    NSString *suffixStr = @"";
    if (years>1) {
        suffixStr = [NSString stringWithFormat:@"%ld%@%@%@",(long)years,(isENVersionNew?@" ":@""),[yearStr lowercaseString],(isENVersionNew?@"s":@"")];
    }else if (years>0){
        suffixStr = [NSString stringWithFormat:@"%ld%@%@",(long)years,(isENVersionNew?@" ":@""),[yearStr lowercaseString]];
    }else if (months>1){
        suffixStr = [NSString stringWithFormat:@"%ld%@%@%@",(long)months,(isENVersionNew?@" ":@""),[monthStr lowercaseString],(isENVersionNew?@"s":@"")];

    }else{
        suffixStr = [NSString stringWithFormat:@"%ld%@%@",(long)months,(isENVersionNew?@" ":@""),[monthStr lowercaseString]];
    }
    
    NSString *tempStr = [NSString stringWithFormat:titleStr,self.queryFreePackageResp.dataLife.intValue,suffixStr];
    return titleStr;
}

@end
