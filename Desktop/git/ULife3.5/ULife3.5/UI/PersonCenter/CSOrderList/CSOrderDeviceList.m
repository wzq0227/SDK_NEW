//
//  CSOrderDeviceList.m
//  ULife3.5
//
//  Created by Goscam on 2018/4/20.
//  Copyright © 2018年 GosCam. All rights reserved.
//

//云服务订阅设备列表
#import "CSOrderDeviceList.h"
#import "CSOrderViewManager.h"
#import "CSOrderDetailDeviceVC.h"
#import "SaveDataModel.h"
#import "CSOrderDataConverter.h"
#import "DeviceDataModel.h"
#import "DeviceManagement.h"

#import "NetSDK.h"
#import "CBSCommand.h"

@interface CSOrderDeviceList ()
{
}

@property (strong, nonatomic)  CSOrderViewManager  *viewManager;

@property (strong, nonatomic)  CSQueryOrderListResp *orderListResp;


@end

@implementation CSOrderDeviceList

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self configUI];
    
    
    [self configViewManager];
}

- (void)configUI{
    
    self.title = MLocalizedString(Personal_CSOrderList);
    self.view.backgroundColor = mCustomBgColor;
    [self addLeftBarButtonItem];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self queryOrderList];
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


//MARK: - Req Order list

- (void)queryForceUnbindDevList{
    BodyGetDevListAfterForceUnbindingReq *body = [BodyGetDevListAfterForceUnbindingReq new];
    body.UserName = [SaveDataModel getUserName];
    
    CBS_GetDevListAfterForceUnbindingReq *req = [CBS_GetDevListAfterForceUnbindingReq new];
    req.Body = body;
    
    __weak typeof(self) weakSelf = self;
    [[NetSDK sharedInstance] net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:7000 responseBlock:^(int result, NSDictionary *dict) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray<ForceUnbindDevModel*>*tempDevList = nil;
            if (result == 0) {
                CBS_GetDevListAfterForceUnbindingResp *getDevListResp = [CBS_GetDevListAfterForceUnbindingResp yy_modelWithJSON:dict];
               tempDevList = [NSArray yy_modelArrayWithClass:[ForceUnbindDevModel class] json:getDevListResp.Body.ForceDevList];
                
            }
            [weakSelf refreshCSOrderTableViewWithForceUnbindDevList:tempDevList];
        });
    }];
}

- (void)queryOrderList{

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [SVProgressHUD showWithStatus:@"Loading..."];
    });

    CSQueryOrderListReq *req = [CSQueryOrderListReq new];
    req.token             = [mUserDefaults objectForKey:USER_TOKEN];
    req.username          = [SaveDataModel getUserName];
    
    NSString *reqParamStr = [req requestParamStr];

    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api/cloudstore/cloudstore-service/manage/service-list%@", kCloud_IP,reqParamStr];
    
    __weak typeof(self) weakSelf = self;
    [[CSNetworkLib sharedInstance] requestWithURLStr:urlStr method:@"GET" result:^(int result, NSData *data) {
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        NSLog(@"queryOrderList:%@",dict);

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (result == 0) {
                weakSelf.orderListResp = [CSQueryOrderListResp yy_modelWithDictionary: dict ];
                [weakSelf queryForceUnbindDevList];
            }else{
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@",dict[@"message"]] ];
            }
        });
    }];
}



- (void)refreshCSOrderTableViewWithForceUnbindDevList:(NSArray<ForceUnbindDevModel*>*)forceUnbindDevList{
    
    NSArray<CSOrderDeviceListCellModel *> *tempArray = [CSOrderDataConverter csOrderDeviceListFromCSDataArray:self.orderListResp.data withForceUnbindDevList:forceUnbindDevList];
    if (tempArray.count <=0 ) {
        [SVProgressHUD showInfoWithStatus:MLocalizedString(CSOrder_NO_Purchased_Record)];
    }else{
        [SVProgressHUD dismiss];
        self.viewManager.devicesArray = tempArray;
    }
}





- (void)configViewManager{
    self.viewManager = [[CSOrderViewManager alloc] initWithFrame:self.view.bounds];
    
    [self.view addSubview: self.viewManager];
    
    __weak typeof(self) wSelf = self;
    [self.viewManager selectCellCallback:^(NSInteger index) {
        [wSelf jumpToDetailDevicePage:index];
    }];
    
    [self.viewManager mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)jumpToDetailDevicePage:(NSInteger )index{
    
    CSOrderDeviceListCellModel *csOrderModel = self.viewManager.devicesArray[index];
    DeviceDataModel *devModel = [DeviceDataModel new];

    if (csOrderModel.orderStatus == CSOrderStatusUnbind ) {
        devModel.DeviceId = csOrderModel.devId;
        devModel.DeviceName = csOrderModel.devName;
    }else{
        for (DeviceDataModel *model in [[DeviceManagement sharedInstance] deviceListArray]) {
            if ([model.DeviceId isEqualToString: csOrderModel.devId]) {
                devModel = model;
                break;
            }
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CSOrderDetailDeviceVC *vc =[CSOrderDetailDeviceVC new];
        vc.csOrderModel = csOrderModel;
        vc.devDataModel = devModel;
        [self.navigationController pushViewController:vc animated:YES];
    });
}

@end
