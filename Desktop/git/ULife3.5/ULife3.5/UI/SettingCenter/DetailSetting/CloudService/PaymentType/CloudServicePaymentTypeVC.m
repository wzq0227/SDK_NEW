//
//  CloudServicePaymentTypeVC.m
//  ULife3.5
//
//  Created by Goscam on 2017/9/13.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "CloudServicePaymentTypeVC.h"
#import "CloudServiceOrderInfoVC.h"
#import "PackageTotalPriceCell.h"
#import "PaymentTypeTableViewCell.h"
#import "Masonry.h"
#import "AFNetworking.h"
#import "Header.h"
#import "CSNetworkLib.h"
#import "SaveDataModel.h"
#import <AlipaySDK/AlipaySDK.h>
#import <BraintreeDropIn/BTDropInBaseViewController.h>

#import "BraintreeCore.h"
#import "BraintreeDropIn.h"
#import "BTPayPalDriver.h"
#import "SettingViewController.h"
#import "CloudPlayBackViewController.h"
#import "GOSLivePlayerVC.h"
#import "CSOrderDetailDeviceVC.h"

#define PriceTableViewFooterHeight 66
#define PriceTableViewHeaderHeight 44
#define PaymentTypeTableViewFooterHeight 100
#define PaymentTypeTableViewHeaderHeight 30

static NSString *kPriceTableViewCellIdentifier = @"PackageTotalPriceCell";
static NSString *kPaymentTypeTableViewCellIdentifier = @"PaymentTypeTableViewCell";

typedef NS_ENUM(NSUInteger, PaymentType) {
    PaymentTypeWeChat,
    PaymentTypeAliPay,
    PaymentTypePayPal,
};

typedef NS_ENUM(NSInteger, PaymentResult) {
    PaymentResultError=-1,
    PaymentResultSuccess,
};

@interface CloudServicePaymentTypeVC ()<UITableViewDelegate
,UITableViewDataSource
,NSURLSessionDelegate
,BTAppSwitchDelegate
,BTViewControllerPresentingDelegate
>
{
}

@property (nonatomic, strong) BTAPIClient *braintreeClient;
@property (nonatomic, strong) BTPayPalDriver *payPalDriver;

@property (strong, nonatomic)  UIView *priceTableFooterView;

@property (strong, nonatomic)  UIView *priceTableHeaderView;

@property (strong, nonatomic)  UIView *paymentTypeTableFooterView;

@property (strong, nonatomic)  UIView *paymentTypeTableHeaderView;


/**
 套餐单价
 */
@property (assign, nonatomic)  CGFloat packageUnitPrice;

/**
 套餐数量
 */
@property (assign, nonatomic)  NSInteger packageQuantity;

/**
 套餐总价
 */
@property (assign, nonatomic)  CGFloat packageTotalPrice;


/**
 付款方式
 */
@property (assign, nonatomic)  PaymentType paymentType;


/**
 商户订单号，用于查询订单的状态
 */
@property (strong, nonatomic)  NSString *orderID;


/**
 创建订单的返回信息
 */
@property (strong, nonatomic)  CSCreateOrderResp *orderInfo;

@property (strong, nonatomic)  NSString *token;

@property (strong, nonatomic)  NSString *payPalToken;

@property (strong, nonatomic)  CSNetworkLib *csNetworkLib;

@property (strong, nonatomic)  NSString *username;
@end



@implementation CloudServicePaymentTypeVC


+ (instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    static CloudServicePaymentTypeVC *instance;
    dispatch_once(&onceToken, ^{
        instance = [[CloudServicePaymentTypeVC alloc] init];
    });
    return instance;
}

//MARK:LifeCycle
- (void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    if ([SVProgressHUD isVisible]) {
        [SVProgressHUD dismiss];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    
//    [self showPaymentResult:PaymentResultSuccess];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self configUI];
    
    [self configModel];
    
    [self addActions];
}

- (void)configUI{
    [self configNaviBar];
    [self configTableView];
    [self registerTableViewCell];
}

- (void)configNaviBar{
//    self.title = DPLocalizedString(@"PackageOrder");
    self.navigationItem.titleView = [CommonlyUsedFounctions titleLabelWithStr:DPLocalizedString(@"PackageOrder")];
}

- (void)configModel{
    self.token = [mUserDefaults objectForKey:USER_TOKEN];
    self.packageTotalPrice = [self.packageInfo.price floatValue]*self.packageCount*1;
    self.username = [SaveDataModel getUserName];
}

- (void)setDeviceModel:(DeviceDataModel *)deviceModel{
    _deviceModel = deviceModel;
    _deviceId = deviceModel.DeviceId;
}

- (void)addActions{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(weChatPayCallback:) name:WECHAT_PAY_CALL_BACK object:nil];
}

- (void)registerTableViewCell{
    [self.priceTableView registerNib:[UINib nibWithNibName:kPriceTableViewCellIdentifier bundle:nil] forCellReuseIdentifier: kPriceTableViewCellIdentifier];
    
    [self.paymentTypeTableView registerNib:[UINib nibWithNibName:kPaymentTypeTableViewCellIdentifier bundle:nil] forCellReuseIdentifier: kPaymentTypeTableViewCellIdentifier];

}


- (void)configTableView{
    self.priceTableView.delegate = self;
    self.priceTableView.dataSource = self;
    self.priceTableView.scrollEnabled = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.priceTableView.separatorStyle = UITableViewCellSelectionStyleNone;

    self.paymentTypeTableView.delegate = self;
    self.paymentTypeTableView.dataSource = self;
    self.paymentTypeTableView.scrollEnabled = NO;
    self.paymentTypeTableView.separatorStyle = UITableViewCellSelectionStyleNone;
}

/**
 * 需支付：￥8
 */
- (UIView *)priceTableFooterView{
    
    if (!_priceTableFooterView) {
        _priceTableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, PriceTableViewFooterHeight)];
        
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(15, 10, 120, 30)];
        label.textAlignment = NSTextAlignmentRight;
        label.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        label.text = [NSString stringWithFormat:@"%@ %.2f", DPLocalizedString(@"PackageNeedToPay"),self.packageTotalPrice] ;
        
        [_priceTableFooterView addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_priceTableFooterView).offset(11);
            make.trailing.equalTo(_priceTableFooterView).offset(-30);
        }];
    }
    return _priceTableFooterView;
}

/**
 * 3天云存储单月包
 */
- (UIView *)priceTableHeaderView{
    if (!_priceTableHeaderView) {
        _priceTableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, PriceTableViewHeaderHeight)];
        
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(15, 10, 120, 30)];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16];
        label.text = self.packageName;
        
        [_priceTableHeaderView addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_priceTableHeaderView);
            make.centerX.equalTo(_priceTableHeaderView);
        }];
        
        UIView *separatorLineView = [[UIView alloc]initWithFrame:CGRectMake(20, 0, 300, 1)];
        separatorLineView.backgroundColor = BACKCOLOR(190, 190, 190, 1);
        [_priceTableHeaderView addSubview:separatorLineView];
        [separatorLineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_priceTableHeaderView).offset(20);
            make.centerX.equalTo(_priceTableHeaderView);
            make.bottom.equalTo(_priceTableHeaderView).offset(-1);
            make.height.equalTo(@(0.5));
        }];
    }
    return _priceTableHeaderView;
}



/**
 * 确认订单付款
 */
- (UIView *)paymentTypeTableFooterView{
    if (!_paymentTypeTableFooterView) {
        _paymentTypeTableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, PaymentTypeTableViewFooterHeight)];
        
        UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(15, 10, 120, 40)];
        [btn setTitleColor:[UIColor whiteColor] forState:0];
        [btn setTitle:DPLocalizedString(@"PackageConfirmPay") forState:0];
        [btn addTarget:self action:@selector(confirmPaymentBtnAction:) forControlEvents: UIControlEventTouchUpInside];
        [btn setBackgroundColor: myColor];
        btn.layer.cornerRadius = 20;
        
        [_paymentTypeTableFooterView addSubview:btn];
        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_paymentTypeTableFooterView).offset(55);
            make.trailing.equalTo(_paymentTypeTableFooterView).offset(-20);
            make.centerX.equalTo(_paymentTypeTableFooterView);
            make.height.equalTo(@(40));
        }];
    }
    return _paymentTypeTableFooterView;
}

- (void)createOrder{
    
    if (_orderInfo) {//订单已经存在不再创建
        [self invokeThirdPartyPayments];
        return;
    }
    
    _csNetworkLib = [CSNetworkLib sharedInstance];
    
    CSCreateOrderReq *req = [CSCreateOrderReq new];
    req.total_price       = [NSString stringWithFormat:@"%.2f",self.packageTotalPrice] ;
    req.token             = self.token;
    req.count             = @"1";//[@(self.packageCount*(_packageValidTime==PackageValidTimeAYear?12:1)) stringValue];
    req.plan_id           = self.packageInfo.planId;
    req.device_id         = self.deviceId;
    req.username          = [SaveDataModel getUserName];
    
    NSString *reqParamStr = [req requestParamStr];
    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api/pay/pay-service/inland/cloudstore/order/create%@", kCloud_IP,reqParamStr];
    
    __weak typeof(self) weakSelf = self;
    [_csNetworkLib requestWithURLStr:urlStr method:@"POST" result:^(int result, NSData *data) {
        if (!data) {
            [weakSelf showPaymentResult:PaymentResultError];
            return ;
        }
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        if (result == 0) {
            NSLog(@"createOrder:%@",dict);
            weakSelf.orderInfo = [CSCreateOrderResp yy_modelWithDictionary: dict[@"data"] ];
            if (weakSelf.orderInfo.status ==0) {//待支付
                [weakSelf invokeThirdPartyPayments];
            }
            NSLog(@"CSCreateOrderResp:%@",weakSelf.orderInfo);
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@",dict[@"message"]] ];
            });
        }
    }];
}

- (void)confirmPaymentBtnAction:(id)sender{
    
    [self createOrder];
}

- (void)invokeThirdPartyPayments{
    NSLog(@"confirmPaymentBtnAction");
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showWithStatus:DPLocalizedString(@"loading")];
    });
    
    //    self.orderID = @"vCetOhNGQQxVE6LyS0";
//        [self queryPaymentResult];
    
    switch (_paymentType) {
        case PaymentTypeAliPay:
            [self goToAliPay];
            break;
        case PaymentTypeWeChat:
            [self goToWeChatPay];
            break;
        case PaymentTypePayPal:
            [self goToPayPal];
            break;
        default:
            break;
    }
}

/**
 调起微信支付，支付结果通过Delegate+Protocol回调
 回调之后再查询后台确认订单状态
 */
- (void)goToWeChatPay{
    
    if (![WXApi isWXAppInstalled]) {
        [SVProgressHUD showErrorWithStatus:@"PleaseInstallWechatFirst"];
        return;
    }
    
    //============================================================
    NSString *urlString   = [NSString stringWithFormat:@"http://%@/api/pay/pay-service/wechat/order/prepare/gosbell",kCloud_IP];
    
    NSString *urlStrWithParams = [NSString stringWithFormat:@"%@?order_no=%@&token=%@&username=%@",urlString,self.orderInfo.orderNo,self.token,self.username];
    
    [_csNetworkLib requestWithURLStr:urlStrWithParams method:@"POST" result:^(int result, NSData *data) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        if (result == 0) {
            if(dict != nil){
                NSDictionary *dataDict = [dict objectForKey:@"data"];

                    NSMutableString *stamp  = [dataDict objectForKey:@"timestamp"];
                    
                    //调起微信支付
                    PayReq* req             = [[PayReq alloc] init];
                    req.partnerId           = [dataDict objectForKey:@"partnerid"];
                    req.prepayId            = [dataDict objectForKey:@"prepayid"];
                    req.nonceStr            = [dataDict objectForKey:@"noncestr"];
                    req.timeStamp           = stamp.intValue;
                    req.package             = [dataDict objectForKey:@"package"];
                    req.sign                = [dataDict objectForKey:@"sign"];
                    
                    //[dict objectForKey:@"appid"];
                    [WXApi sendReq:req];
                    //日志输出
                    NSLog(@"appid=%@\npartid=%@\nprepayid=%@\nnoncestr=%@\ntimestamp=%ld\npackage=%@\nsign=%@",[dict objectForKey:@"appid"],req.partnerId,req.prepayId,req.nonceStr,(long)req.timeStamp,req.package,req.sign );
            }else{
                [self showErrorWithMsg:dict[@"message"]];
            }
        }else{
            [self showErrorWithMsg:dict[@"message"]];
        }
    }];
}


- (void)showErrorWithMsg:(NSString*)msg{
    NSLog(@"error:%@",msg);
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"network_error") ];
    });
}

- (void)weChatPayCallback:(NSNotification*)notification{
    NSDictionary *userInfo = notification.userInfo;
    if ([userInfo[@"PaymentResult"] intValue]==0) {
        [self queryPaymentResult];
    }else{
        [self showPaymentResult:PaymentResultError];
    }
}

- (void)queryPaymentResult {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![SVProgressHUD isVisible]) {
            [SVProgressHUD showWithStatus:DPLocalizedString(@"loading")];
        }
    });
    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api/pay/pay-service/inland/cloudstore/payment/query",kCloud_IP];
    NSString *urlStrWithParams = [NSString stringWithFormat:@"%@?order_no=%@&token=%@&username=%@",urlStr,self.orderInfo.orderNo,self.token,self.username];
    
    [_csNetworkLib requestWithURLStr:urlStrWithParams method:@"POST" result:^(int result, NSData *data) {
        NSDictionary  *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        if (result == 0) {
            if ([dict[@"data"][@"status"] intValue]== 1) {
                
                [self showPaymentResult:PaymentResultSuccess];
            }else{
                [self showPaymentResult:PaymentResultError];
            }
        }else{
            [self showPaymentResult:PaymentResultError];
        }
    }];
}

- (void)showPaymentResult:(PaymentResult)result{

    dispatch_async(dispatch_get_main_queue(), ^{
        if (result == PaymentResultSuccess) {
            [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Payment_Succeeded")];
            
            NSNotification *notification =[NSNotification notificationWithName:ORDER_CS_SUCCESSFULLY object:nil];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
            
            //CSOrderInfo 之前不在导航栈里面则push一个新的VC，否则pop到栈里面的CSOrderInfoVC
            
            __weak typeof(UIViewController*) csOrderInfoVC = nil;
            __weak typeof(UIViewController*) settingVC = nil;
            __weak typeof(GOSLivePlayerVC*) gosLivePlayerVC = nil;
            __weak typeof(CSOrderDetailDeviceVC*) csOrderDetailDeviceVC = nil;
            __weak typeof(CloudPlayBackViewController*) cloudPlaybackVC = nil;


            for (UIViewController *vc in self.navigationController.viewControllers.reverseObjectEnumerator.allObjects) {
                if([vc isKindOfClass:[CloudServiceOrderInfoVC class]]){
                    csOrderInfoVC = vc;
                    break;
                }
                if ([vc isKindOfClass:[SettingViewController class]]) {
                    settingVC = vc;
                    break;
                }
                if ([vc isKindOfClass:[CloudPlayBackViewController class]]) {
                    cloudPlaybackVC = vc;
                    break;
                }
                if ([vc isKindOfClass:[GOSLivePlayerVC class]]) {
                    gosLivePlayerVC = vc;
                    break;
                }
                
                if ([vc isKindOfClass:[CSOrderDetailDeviceVC class]]) {
                    csOrderDetailDeviceVC = vc;
                    break;
                }
            }
            
            if (csOrderInfoVC) {
                
                [self.navigationController popToViewController:csOrderInfoVC animated:NO];
            }else{
                
                CloudServiceOrderInfoVC *vc = [CloudServiceOrderInfoVC new];
                vc.deviceModel                 = self.deviceModel;
                if (gosLivePlayerVC) {
                    
                    [self.navigationController popToViewController:gosLivePlayerVC animated:NO];
                    [gosLivePlayerVC.navigationController pushViewController:vc animated:YES];

                }else if (cloudPlaybackVC) {
                    
                    [self.navigationController popToViewController:cloudPlaybackVC animated:NO];
                    [cloudPlaybackVC.navigationController pushViewController:vc animated:YES];

                }else if (csOrderDetailDeviceVC) {
                    
                    [self.navigationController popToViewController:csOrderDetailDeviceVC animated:NO];
                    [csOrderDetailDeviceVC.navigationController pushViewController:vc animated:YES];
                }
                else{
                    [self.navigationController popToViewController:settingVC animated:NO];
                    [settingVC.navigationController pushViewController:vc animated:YES];
                }
                
            }
            
        }else{
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Payment_Failed")];
        }
    });
}

/**
 调起支付宝支付，支付结果通过Block回调
 */
- (void)goToAliPay{
    
    NSString *urlString   = [NSString stringWithFormat:@"http://%@/api/pay/pay-service/alipay/order/sign",kCloud_IP];
    
    NSString *urlStrWithParams = [NSString stringWithFormat:@"%@?order_no=%@&token=%@&username=%@",urlString,self.orderInfo.orderNo,self.token,self.username];
    
    __weak typeof(self) weakSelf = self;
    [_csNetworkLib requestWithURLStr:urlStrWithParams method:@"POST" result:^(int result, NSData *data) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        if (result == 0) {
            if(dict != nil){
                __strong typeof(weakSelf) strongSelf = weakSelf;
                NSMutableString *signParam = dict[@"data"][@"signParam"];
                [[AlipaySDK defaultService] payOrder:signParam fromScheme:@"gosbell" callback:^(NSDictionary *resultDic) {
                    [strongSelf processAlipayPaymentResult:resultDic];
                }];
            }else{
                [self showErrorWithMsg:dict[@"message"]];
            }
        }else{
            [self showErrorWithMsg:dict[@"message"]];
        }
    }];
}

- (void)processAlipayPaymentResult:(NSDictionary *)resultDict{
    
    //resultStatus=9000 && success="true"
    if ( [resultDict[@"resultStatus"] intValue] != 9000) {
        [self showPaymentResult:PaymentResultError];
        return;
    }
    
    CSAliPayCheckReq *req = [CSAliPayCheckReq new];
    
    //最外层
    req.resultStatus = resultDict[@"resultStatus"];
    req.memo         = resultDict[@"memo"];

    //第二层
//    NSData *resultData = [resultDict[@"result"] dataUsingEncoding:NSUTF8StringEncoding];
//    NSDictionary *tempDict = [NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error:nil];
//    NSDictionary *payResp = tempDict[@"alipay_trade_app_pay_response"];
//    req.sign         = tempDict[@"sign"];
//    req.sign_type    = tempDict[@"sign_type"];
//
//    //最里层
//    req.code         = payResp[@"code"];
//    req.msg          = payResp[@"msg"];
//    req.app_id       = payResp[@"app_id"];
//    req.charset      = payResp[@"charset"];
//    req.timestamp    = payResp[@"timestamp"];
//    req.total_amount = payResp[@"total_amount"];
//    req.trade_no     = payResp[@"trade_no"];
//    req.seller_id    = payResp[@"seller_id"];
//    req.out_trade_no = payResp[@"out_trade_no"];

    req.token        = self.token;
    req.username     = self.username;
    
    NSString *tempStr = resultDict[@"result"];
    //
    NSString *encodedString = [self UrlValueEncode:tempStr];//
    
    NSString *reqParamsStr = [NSString stringWithFormat:@"%@&content-params=%@",[req requestParamStr],encodedString] ;

    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api/pay/pay-service/alipay/payment/check%@", kCloud_IP,reqParamsStr];
    
    [_csNetworkLib requestWithURLStr:urlStr method:@"POST" result:^(int result, NSData *data) {
        if (result == 0) {
            [self queryPaymentResult];
        }else{
            [self showPaymentResult:PaymentResultError];
        }
    }];
}

-(NSString*)UrlValueEncode:(NSString*)str
{
    NSString *result = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                             (CFStringRef)str,
                                                                                             NULL,
                                                                                             CFSTR("!$*'();:@&=+-$,./?%#[]_~"),
                                                                                             kCFStringEncodingUTF8));
    return result;
}

#pragma mark PayPal
/**
 调起PayPal支付
 */
- (void)goToPayPal{
    [self payPalTokenFromServer];
}


//paypal-step1
- (void)payPalTokenFromServer{
    NSString *urlString   = [NSString stringWithFormat:@"http://%@/api/pay/pay-service/paypal/check/client_token",kCloud_IP];
    
    NSString *urlStrWithParams = [NSString stringWithFormat:@"%@?order_no=%@&token=%@&username=%@",urlString,self.orderInfo.orderNo,self.token,self.username];
    
    __weak typeof(self) wSelf = self;
    [_csNetworkLib requestWithURLStr:urlStrWithParams method:@"POST" result:^(int result, NSData *data) {
        
        __strong typeof(wSelf) strongSelf = wSelf;
        if (!data) {
            [strongSelf showPaymentResult:PaymentResultError];
            return ;
        }
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        if (result == 0) {
            if(dict != nil){
                strongSelf.payPalToken = dict[@"data"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    
//                    [SVProgressHUD dismiss];

                    [strongSelf startCheckout:strongSelf.payPalToken];
//                    [weakSelf showDropIn:weakSelf.payPalToken];
                });
            }else{
                [self showErrorWithMsg:dict[@"message"]];
            }
        }else{
            [self showErrorWithMsg:dict[@"message"]];
        }
    }];
}

//paypal-step2
- (void)showDropIn:(NSString *)clientTokenOrTokenizationKey {
    __weak typeof(self) weakSelf = self;
    BTDropInRequest *request = [[BTDropInRequest alloc] init];
    BTDropInController *dropIn = [[BTDropInController alloc] initWithAuthorization:clientTokenOrTokenizationKey request:request handler:^(BTDropInController * _Nonnull controller, BTDropInResult * _Nullable result, NSError * _Nullable error) {
        if (error != nil) {
            [weakSelf showPaymentResult:PaymentResultError];
            NSLog(@"ERROR");
        } else if (result.cancelled) {
            [weakSelf showPaymentResult:PaymentResultError];
            NSLog(@"CANCELLED");
        } else {
            
            [weakSelf postNonceToServer:result.paymentMethod.nonce];
            // Use the BTDropInResult properties to update your UI
            // result.paymentOptionType
            // result.paymentMethod
            // result.paymentIcon
            // result.paymentDescription
        }
        [controller dismissViewControllerAnimated:YES completion:nil];
    }];
    [self presentViewController:dropIn animated:YES completion:nil];

}

//paypal-step2_new
- (void)startCheckout:(NSString*)clientTokenOrAuthorizationKey {
    // Example: Initialize BTAPIClient, if you haven't already
    self.braintreeClient = [[BTAPIClient alloc] initWithAuthorization: clientTokenOrAuthorizationKey];
    BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithAPIClient:self.braintreeClient];
    payPalDriver.viewControllerPresentingDelegate = self;
    payPalDriver.appSwitchDelegate = self; // Optional
    
    // Specify the transaction amount here. "2.32" is used in this example.
    BTPayPalRequest *request= [[BTPayPalRequest alloc] initWithAmount:self.orderInfo.totalPrice];
    request.currencyCode = @"USD"; // Optional; see BTPayPalRequest.h for other options
    
    __weak typeof(self) wSelf = self;
    [payPalDriver requestOneTimePayment:request completion:^(BTPayPalAccountNonce * _Nullable tokenizedPayPalAccount, NSError * _Nullable error) {
        __strong typeof(wSelf) strongSelf = wSelf;
        if (tokenizedPayPalAccount) {
            NSLog(@"Got a nonce: %@", tokenizedPayPalAccount.nonce);
            
            // Access additional information
            NSString *email = tokenizedPayPalAccount.email;
            NSString *firstName = tokenizedPayPalAccount.firstName;
            NSString *lastName = tokenizedPayPalAccount.lastName;
            NSString *phone = tokenizedPayPalAccount.phone;
            
            // See BTPostalAddress.h for details
            BTPostalAddress *billingAddress = tokenizedPayPalAccount.billingAddress;
            BTPostalAddress *shippingAddress = tokenizedPayPalAccount.shippingAddress;
            
            [strongSelf postNonceToServer:tokenizedPayPalAccount.nonce];

        } else if (error) {
            // Handle error here...
            [strongSelf showPaymentResult:PaymentResultError];
            NSLog(@"ERROR");
        } else {
            // Buyer canceled payment approval
            [strongSelf showPaymentResult:PaymentResultError];
            NSLog(@"CANCELLED");
        }
    }];
}



//paypal-step3
- (void)postNonceToServer:(NSString *)paymentMethodNonce {
    
    NSString *urlString   = [NSString stringWithFormat:@"http://%@/api/pay/pay-service/paypal/check/payment",kCloud_IP];
    
    NSString *urlStrWithParams = [NSString stringWithFormat:@"%@?payment_method_nonce=%@&amount=%@&order_no=%@&token=%@&username=%@",urlString,paymentMethodNonce,self.orderInfo.totalPrice,self.orderInfo.orderNo,self.token,self.username];
    [SVProgressHUD showWithStatus:@"loading"];
    __weak typeof(self) weakSelf = self;
    [_csNetworkLib requestWithURLStr:urlStrWithParams method:@"POST" result:^(int result, NSData *data) {
        if (result == 0) {
                [weakSelf queryPaymentResult];
        }else{
            [weakSelf showPaymentResult:PaymentResultError];
        }
    }];
}

#pragma mark - BTViewControllerPresentingDelegate

// Required
- (void)paymentDriver:(id)paymentDriver
requestsPresentationOfViewController:(UIViewController *)viewController {
    [self presentViewController:viewController animated:YES completion:nil];
}

// Required
- (void)paymentDriver:(id)paymentDriver
requestsDismissalOfViewController:(UIViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

/**
 * 选择付款方式：
 */
- (UIView *)paymentTypeTableHeaderView{
    if (!_paymentTypeTableHeaderView) {
        _paymentTypeTableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, PaymentTypeTableViewHeaderHeight)];
        
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(15, 10, 120, 30)];
        label.textAlignment = NSTextAlignmentLeft;
        label.font = [UIFont fontWithName:@"PingFangSC-Regular" size:17];
        label.text = DPLocalizedString(@"PackageChoosePaymentType");
        
        [_paymentTypeTableHeaderView addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_paymentTypeTableHeaderView);
            make.leading.equalTo(_paymentTypeTableHeaderView).offset(30);
        }];
        
        UIView *separatorLineView = [[UIView alloc]initWithFrame:CGRectMake(20, 0, 300, 1)];
        separatorLineView.backgroundColor = BACKCOLOR(190, 190, 190, 1);
        [_paymentTypeTableHeaderView addSubview:separatorLineView];
        [separatorLineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_paymentTypeTableHeaderView).offset(20);
            make.centerX.equalTo(_paymentTypeTableHeaderView);
            make.bottom.equalTo(_paymentTypeTableHeaderView).offset(-1);
            make.height.equalTo(@(0.5));
        }];
    }
    return _paymentTypeTableHeaderView;
}



#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSInteger numRows = (isENVersionNew?1:3);
    return tableView==self.priceTableView ? 1: numRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView==self.priceTableView) {
        PackageTotalPriceCell *cell = [tableView dequeueReusableCellWithIdentifier:kPriceTableViewCellIdentifier forIndexPath:indexPath] ;
        float unitPrice = (self.packageInfo.price.floatValue*(_packageValidTime==PackageValidTimeAYear?12:1));
        cell.priceLabel.text = [NSString stringWithFormat:@"%@ %.2f",DPLocalizedString(@"PackageUnitPrice"),unitPrice];
        cell.countLabel.text = [NSString stringWithFormat:@"%@ %d",DPLocalizedString(@"PackageQuantity"),self.packageCount];
        cell.totalPriceLabel.text = [NSString stringWithFormat:@"%@ %.2f",DPLocalizedString(@"PackageTotalPrice"),self.packageTotalPrice];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        if (isENVersion) {
            cell.priceLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13];
            cell.countLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13];
            cell.totalPriceLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13];
        }
        return cell;
    }else{
        PaymentTypeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kPaymentTypeTableViewCellIdentifier forIndexPath:indexPath] ;
        PaymentType type = indexPath.row;
        if (isENVersionNew) {
            type = PaymentTypePayPal;
            _paymentType = PaymentTypePayPal;
        }
        switch (type) {
            case PaymentTypeWeChat:
            {
                cell.iconImage.image = [UIImage imageNamed:@"WeChat"];
                cell.titleLabel.text = DPLocalizedString(@"PaymentTypeWeChat");
                break;
            }
            case PaymentTypeAliPay:
            {
                cell.iconImage.image = [UIImage imageNamed:@"AliPay"];
                cell.titleLabel.text = DPLocalizedString(@"PaymentTypeAliPay");
                break;
            }
            case PaymentTypePayPal:
            {
                cell.iconImage.image = [UIImage imageNamed:@"PayPal"];
                cell.titleLabel.text = DPLocalizedString(@"PaymentTypePayPal");
                break;
            }
            default:
                break;
        }
        NSString *imageName = type==_paymentType?@"Record_FileSelected":@"Record_FileUnselected";
        [cell.selectBtn setTag:(indexPath.row+300)];
        [cell.selectBtn setBackgroundImage:[UIImage imageNamed:imageName] forState:0];
        [cell.selectBtn addTarget:self action:@selector(changePaymentType:) forControlEvents:UIControlEventTouchUpInside];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
}

- (void)changePaymentType:(id)sender{
    UIButton* btn = (UIButton *)sender;
    _paymentType = btn.tag -300;
    if(isENVersionNew){
        _paymentType = PaymentTypePayPal;
    }
    [self.paymentTypeTableView reloadData];
}


#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView==self.priceTableView) {
        return 50;
    }else{
        return 50;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (tableView==self.priceTableView) {
        return PriceTableViewHeaderHeight;
    }else{
        return PaymentTypeTableViewHeaderHeight;
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (tableView==self.priceTableView) {
        return PriceTableViewFooterHeight;
    }else{
        return PaymentTypeTableViewFooterHeight;
    }
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (tableView==self.priceTableView) {
        return self.priceTableHeaderView;
    }else{
        return self.paymentTypeTableHeaderView;
    }
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (tableView==self.priceTableView) {
        return self.priceTableFooterView;
    }else{
        return self.paymentTypeTableFooterView;
    }
}

@end
