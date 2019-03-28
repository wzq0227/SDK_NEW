//
//  CSOrderDetailDeviceVC.m
//  ULife3.5
//
//  Created by Goscam on 2018/4/23.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "CSOrderDetailDeviceVC.h"
#import "CSOrderDetailDeviceTopView.h"
#import "CSOrderDetailDeviceBottomView.h"
#import "CSPackageTypeVC.h"
#import "CSNetworkLib.h"

#import "CloudPlayBackViewController.h"

#import "PopUpTableViewManager.h"
#import "DeviceDataModel.h"
#import "SaveDataModel.h"
#import "CommonlyUsedFounctions.h"
#import "DeviceManagement.h"
#import "PushMessageManagement.h"

#import "CBSCommand.h"
#import "NetSDK.h"


@interface CSOrderDetailDeviceVC ()<UIAlertViewDelegate>
{
    
}

@property (strong, nonatomic)  CSOrderDetailDeviceBottomView *bottomView;

@property (strong, nonatomic)  CSOrderDetailDeviceTopView *topView;

@property (strong, nonatomic)  PopUpTableViewManager *popupTableManager;

@property (strong, nonatomic)  NSMutableArray <PopupTableCellModel*>*devicesArray;

@property (strong, nonatomic)  NSMutableArray <PopupTableCellModel*>*subdevicesArray;

@property (strong, nonatomic)  NSString *destDevId;
@end

@implementation CSOrderDetailDeviceVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self queryServiceListOfDevice];
    
    [self configUI];
    
    [self configModel];
}

//MARK: - init
- (void)configUI{
    
    self.title = self.csOrderModel.devName;
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview: self.topView];
    [self.view addSubview: self.bottomView];
    
    [self.topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.height.mas_equalTo(168);
    }];
    
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.top.equalTo(self.topView.mas_bottom);
        make.bottom.equalTo(self.view);
    }];
    
    self.topView.csOrderModel = self.csOrderModel;
    [self.bottomView selectCellCallback:^(NSInteger index) {
        //
    }];
}

- (void)setCsOrderModel:(CSOrderDeviceListCellModel *)csOrderModel{
    _csOrderModel = csOrderModel;
    _deviceId = csOrderModel.devId;
    _status = _csOrderModel.orderStatus;
}

- (void)configModel{
    
    __weak typeof(self) wSelf = self;
    [self.topView clickCallback:^(CSAction csAction) {
        dispatch_async_on_main_queue(^{
            if (csAction == CSAction_Playback) {
                if (wSelf.status == CSOrderStatusInUse || wSelf.status == CSOrderStatusUnbind) {
                    
                    [wSelf configSubDevList];
                }
            }else{
                if (wSelf.status == CSOrderStatusUnbind) {//Transfer
                    [wSelf  showPopUpTableView];
                }else{//renew
                    
                    CSPackageTypeVC *vc = [CSPackageTypeVC new];
                    vc.deviceModel = wSelf.devDataModel;
                    [wSelf.navigationController pushViewController:vc animated:YES];
                }
            }
        });
    }];
}

//MARK: - 选择云存储回放的子设备
// 云存储套餐正在使用可以查到是否为一拖四；已解绑只能去服务器查

- (void)configSubDevList{
    
    if (self.status == CSOrderStatusInUse) {
        if (self.devDataModel.devCapModel.four_channel_flag == 0) {//一拖一不管，兼容之前的
            CloudPlayBackViewController *vc = [CloudPlayBackViewController new];
            vc.deviceModel = self.devDataModel;
            [self.navigationController pushViewController:vc animated:YES];
        }else{//一拖四,APP缓存的设备列表中有
            [self showSubDevListWithArray:self.subdevicesArray];
        }
    }else{
        //已解绑去查询子设备列表
        [self reqSubDevList];
    }
}

- (void)reqSubDevList{
    
    [SVProgressHUD showWithStatus:@"Loading..."];
    
    BodyGetSubDevListAfterForceUnbindingReq *body = [BodyGetSubDevListAfterForceUnbindingReq new];
    body.DeviceId = _deviceId;
    body.UserName = [SaveDataModel getUserName];
    
    CBS_GetSubDevListAfterForceUnbindingReq *req = [CBS_GetSubDevListAfterForceUnbindingReq new];
    req.Body = body;
    
    __weak typeof(self) weakSelf = self;
    [[NetSDK sharedInstance] net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result == 0) {
                [SVProgressHUD dismiss];
                CBS_GetSubDevListAfterForceUnbindingResp *getSubDevListResp = [CBS_GetSubDevListAfterForceUnbindingResp yy_modelWithDictionary:dict];

                NSMutableArray<PopupTableCellModel*> *subdevicesArray = [NSMutableArray arrayWithCapacity:1];
                NSMutableArray<SubDevInfoModel*> *subDevices = [NSMutableArray arrayWithCapacity:1];

                for (NSDictionary *tempDict in getSubDevListResp.Body.SubDevList) {
                    
                    SubDevInfoModel * subInfo = [SubDevInfoModel new];
                    subInfo.DeviceId          = weakSelf.deviceId;
                    subInfo.SubId             = tempDict[@"SubDevId"]?:tempDict[@"SubId"];
                    subInfo.ChanName          = tempDict[@"ChanName"];
                    [subDevices addObject: subInfo];
                    
                    PopupTableCellModel *cellModel = [PopupTableCellModel new];
                    cellModel.deviceId             = subInfo.SubId;
                    cellModel.deviceName           = subInfo.ChanName;
                    [subdevicesArray addObject:cellModel];
                }
                weakSelf.devDataModel.SubDevice = subDevices;
                
                DeviceCapModel *cap = [DeviceCapModel capWithString:getSubDevListResp.Body.DeviceCap];
                
                /*
                 子设备列表为空有两种情况：1）不支持一拖四  2）支持一拖四，但是中继下面没有子设备，
                 
                 */
                
                dispatch_async_on_main_queue(^{
                    if (subdevicesArray.count == 0) {
                        if ( cap.four_channel_flag == 1 ) {
                            [SVProgressHUD showInfoWithStatus:MLocalizedString(CSOrder_Playback_NoSubDev_Tip)];
                        }else{
                            CloudPlayBackViewController *vc = [CloudPlayBackViewController new];
                            vc.deviceModel = weakSelf.devDataModel;
                            [weakSelf.navigationController pushViewController:vc animated:YES];
                        }
                    }else{
                        [weakSelf showSubDevListWithArray:subdevicesArray];
                    }
                });
            }else{
                [GOSUIManager showGetOperationResult:result];
            }
        });
    }];
}


- (BOOL)supportAddSubDevice{
    GosDetailedDeviceType detailType = [DeviceDataModel detailedDeviceTypeWithString:[self.deviceId substringWithRange:NSMakeRange(3, 2)]];
    return detailType == GosDetailedDeviceType_T5200HCA; //detailType==GosDetailedDeviceType_T5100ZJ ||
}


- (void)showSubDevListWithArray:(NSArray<PopupTableCellModel*>*)subDevArray{
    if (!_popupTableManager) {
        __weak typeof(self) wSelf = self;
        _popupTableManager = [[PopUpTableViewManager alloc] initWithFrame:[UIScreen mainScreen].bounds ];
        _popupTableManager.tableHeaderStr = MLocalizedString(CSOrder_Playback_ChooseSubDev_Title);
        
        [_popupTableManager selectCellCallback:^(NSInteger index) {
            
            __strong typeof(wSelf) strongSelf = wSelf;
            [strongSelf dismissTableView];
            
            NSString *subID = subDevArray[index].deviceId;
            

            for (SubDevInfoModel *subInfo in strongSelf.devDataModel.SubDevice) {
                if ([subInfo.SubId isEqualToString: subID] ) {
                    strongSelf.devDataModel.selectedSubDevInfo = subInfo;
                    break;
                }
            }
            

            CloudPlayBackViewController *vc = [CloudPlayBackViewController new];
            vc.deviceModel = strongSelf.devDataModel;
            [wSelf.navigationController pushViewController:vc animated:YES];
            
        }];
        _popupTableManager.devicesArray = subDevArray;
    }
    
    if (!_popupTableManager.superview) {
        [[UIApplication sharedApplication].keyWindow addSubview:_popupTableManager];
    }
}

//MARK: - UIEvents to Model

- (void)showPopUpTableView{
    if (self.devicesArray.count <= 0) {
        [SVProgressHUD showInfoWithStatus:MLocalizedString(CSOrder_NoCameraToConvertCS)];
        return;
    }
    
    if (!_popupTableManager) {
        __weak typeof(self) wSelf = self;
        _popupTableManager = [[PopUpTableViewManager alloc] initWithFrame:[UIScreen mainScreen].bounds ];
        [_popupTableManager selectCellCallback:^(NSInteger index) {
            
            wSelf.destDevId = wSelf.devicesArray[index].deviceId;
            NSString *destDevName = wSelf.devicesArray[index].deviceName;
            
            [wSelf dismissTableView];
            NSString *alertTitle = [NSString stringWithFormat:@"%@%@",DPLocalizedString(@"CSOrder_Transfer_ConfirmTitle"),destDevName];
            [wSelf showAlertWithTitle:alertTitle  Msg:MLocalizedString(CSOrder_Transfer_WipeData_Tip)];
        }];
        _popupTableManager.devicesArray = self.devicesArray;
    }
    
    if (!_popupTableManager.superview) {
        [[UIApplication sharedApplication].keyWindow addSubview:_popupTableManager];
//        [_popupTableManager mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.edges.equalTo(self.view);
//        }];
    }
}

- (void)dismissTableView{
    
    [UIView transitionWithView:self.view duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        [_popupTableManager removeFromSuperview];
                    }
                    completion:^(BOOL finished) {
                        if (finished) {
                            _popupTableManager = nil;
                        }
                    }];
}

- (void)showAlertWithTitle:(NSString*)title Msg:(NSString *)msg{
    UIAlertView *msgAlert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:DPLocalizedString(@"Setting_Cancel") otherButtonTitles:DPLocalizedString(@"Title_Confirm"), nil];
    [msgAlert show];
}


-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {//ok
        [self transferCSOrder];
    }
}



//MARK: - Model to View

- (void)queryServiceListOfDevice{
    
    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api/cloudstore/cloudstore-service/service/list",kCloud_IP];
    
    NSString *urlStrWithParams = [NSString stringWithFormat:@"%@?device_id=%@&token=%@&username=%@&version=1.0",urlStr,self.deviceId,[mUserDefaults objectForKey:USER_TOKEN],[SaveDataModel getUserName]];
    
    [SVProgressHUD showWithStatus:@"Loading..."];

    __weak typeof(self) wSelf = self;
    [[CSNetworkLib sharedInstance] requestWithURLStr:urlStrWithParams method:@"GET" result:^(int result, NSData *data) {
        
        [SVProgressHUD dismiss];

        NSDictionary  *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        if (result == 0 ) {
            if (!dict[@"data"]) {
                return ;
            }

            __strong typeof(wSelf) strongSelf = wSelf;

            NSMutableArray *dataArray = [NSMutableArray array];
            for (NSDictionary *testDict in dict[@"data"]) {
                CSQueryCurServiceResp *resp = [CSQueryCurServiceResp yy_modelWithDictionary:testDict];
                PurchasedPackageInfo *info = [PurchasedPackageInfo new];
                if ( resp ) {
                    info.dataLife = [NSString stringWithFormat:@"%d%@",resp.dateLife,MLocalizedString(CSOrder_CS_Days)] ;
                    info.validTime = [NSString stringWithFormat:@"%@：%@",MLocalizedString(CSOrder_ValidityPeriod),[CommonlyUsedFounctions convertedValidTimeWithSartTime:resp.startTime endTime:resp.preinvalidTime]];
                    
                    [dataArray addObject:info];
                }
            }
            if (dataArray.count > 0) {
                strongSelf.bottomView.purchasedPackages = dataArray;
            }
        }
    }];
}

//transfer cs
- (void)transferCSOrder{
    
    [SVProgressHUD showWithStatus:@"Loading..."];

    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api/cloudstore/cloudstore-service/manage/device/migrate",kCloud_IP];
    
    NSString *urlStrWithParams = [NSString stringWithFormat:@"%@?ori_device=%@&dist_device=%@&token=%@&username=%@&version=1.0",urlStr,self.deviceId,self.destDevId,[mUserDefaults objectForKey:USER_TOKEN],[SaveDataModel getUserName]];
    
    __weak typeof(self) wSelf = self;
    [[CSNetworkLib sharedInstance] requestWithURLStr:urlStrWithParams method:@"POST" result:^(int result, NSData *data) {
        [wSelf showOperationResult:result];
    }];
}

- (void)showOperationResult:(int)result{
    
    dispatch_async_on_main_queue(^{
        if (result == 0) {
            [SVProgressHUD dismiss];
            [self.navigationController popViewControllerAnimated:YES];
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [[PushMessageManagement sharedInstance]deletePushMsgsOfDevice:self.deviceId];
            });

        }else{
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
        }
    });
}


//MARK: - getters
- (CSOrderDetailDeviceTopView*)topView{
    if (!_topView) {
        _topView = [[CSOrderDetailDeviceTopView alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
    }
    return _topView;
}

- (CSOrderDetailDeviceBottomView*)bottomView{
    if (!_bottomView) {
        _bottomView = [[CSOrderDetailDeviceBottomView alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
    }
    return _bottomView;
}

- (NSArray<PopupTableCellModel*>*)devicesArray{
    if (!_devicesArray) {
        _devicesArray = [NSMutableArray arrayWithCapacity:1 ];
        for (DeviceDataModel *model in [[DeviceManagement sharedInstance] deviceListArray]) {
            PopupTableCellModel *cellModel = [PopupTableCellModel new];
            cellModel.deviceId = model.DeviceId;
            cellModel.deviceName = model.DeviceName;
            [_devicesArray addObject:cellModel];
        }
    }
    return _devicesArray;
}

- (NSArray<PopupTableCellModel*>*)subdevicesArray{
    if (!_subdevicesArray) {
        _subdevicesArray = [NSMutableArray arrayWithCapacity:1 ];
        for ( SubDevInfoModel *subInfo in self.devDataModel.SubDevice ) {
            PopupTableCellModel *cellModel = [PopupTableCellModel new];
            cellModel.deviceId = subInfo.SubId;
            cellModel.deviceName = subInfo.ChanName;
            [_subdevicesArray addObject:cellModel];
        }
    }
    return _subdevicesArray;
}

@end
