//
//  DeviceInfoViewController.m
//  ULife3.5
//
//  Created by zhuochuncai on 2/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "DeviceInfoViewController.h"
#import "DeviceInfoTableViewCell.h"
#import "FlashPreventionViewController.h"
#import "DeviceNameSettingViewController.h"
#import "DeviceInfoFooterView.h"
#import "BaseCommand.h"
#import "CBSCommand.h"
#import "CMSCommand.h"
#import "SaveDataModel.h"
#import "NetSDK.h"
#import "DeviceUpdateView.h"
#import "DeviceUpdateTipsView.h"
#import "Masonry.h"
#import "UISettingManagement.h"
#import "ModifyDevicePswViewController.h"




@interface DeviceInfoViewController ()<UITableViewDelegate,UITableViewDataSource,UIAlertViewDelegate>{
    
    BOOL needToUpdate;
    __block CMD_QueryNewerVersionResp *queryUpdateResp;
    DeviceUpdateView *updateView;
    UIView *updateViewBg;
    
    DeviceUpdateTipsView *updateTipsView;
}
@property(nonatomic,strong)NetSDK *netSDK;
@property(nonatomic,strong)CMD_GetDevInfoResp *getDevInfoResp;
@property(nonatomic,strong)CMD_FormatSDCardResp *formatSDCardResp;

@property(nonatomic,strong)UIAlertView *updateAlertView;
@property(nonatomic,assign)UpdateStage updateStage;
@property(nonatomic,strong)NSTimer     *updateProgressTimer;
@property(nonatomic,strong)NSTimer     *autoUpdateProgressTimer;

@property(nonatomic,strong)UIImage *hasNewVersionImage;

@property(nonatomic,strong)UIAlertView *formatSDAlertView;
@property(nonatomic,strong)UISettingModel *settingModel;

/**
 设备端下载完升级包后，开始写Flash等操作(需要44S)，此时进度由App显示
 进度显示为30+count/22 *(98-30)
 */
@property(nonatomic,assign)int timerCountAfterUpdateThirdStage;//30+count/22 *(98-30)
@property(nonatomic,assign)int shareByFriend;
@end

@implementation DeviceInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.settingModel = [[UISettingManagement sharedInstance] getSettingModel:self.model.DeviceId];
    [self configureTableView];
    [self configUI];
    [self getDeviceInfo];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if ([SVProgressHUD isVisible]) {
        [SVProgressHUD dismiss];
    }
}

#pragma mark== <UI>
- (void)configUI{
    self.title = DPLocalizedString(@"Setting_DeviceInfo");
    self.view.backgroundColor = BACKCOLOR(238,238,238,1);
    
    [self configForPermission];
}

- (void)configForPermission{
    _shareByFriend = _model.DeviceOwner == GosDeviceShare;
    
}

- (void)configureTableView{
    
    [self.devInfoTableView registerNib:[UINib nibWithNibName:@"DeviceInfoTableViewCell" bundle:nil] forCellReuseIdentifier:@"DeviceInfoTableViewCell"];
    
    [self.devInfoTableView registerNib:[UINib nibWithNibName:@"DeviceInfoFooterView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"DeviceInfoFooterView"];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.devInfoTableView.scrollEnabled = YES;
    self.devInfoTableView.delegate = self;
    self.devInfoTableView.dataSource = self;
}


#pragma mark== <Network>
- (void)getDeviceInfo{
    _netSDK = [NetSDK sharedInstance];
    CMD_GetDevInfoReq *req = [CMD_GetDevInfoReq new];
    __weak typeof(self) weakSelf = self;
    
    [SVProgressHUD showWithStatus:@"Loading..."];
    [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[req requestCMDData] timeout:5000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            weakSelf.getDevInfoResp = [CMD_GetDevInfoResp yy_modelWithDictionary:dict];
        }
        [weakSelf dealWithGetOperationResultWithResult:result];
    }];
}


- (void)dealWithGetOperationResultWithResult:(int)result{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.devInfoTableView reloadData];
        if (result!=0) {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Get_data_failed")];
        }else{
            [SVProgressHUD dismiss];
        }
    });
}


- (void)dealWithOperationResultWithResult:(int)result{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.devInfoTableView reloadData];
        if (result!=0) {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
        }else{
            [SVProgressHUD dismiss];
        }
    });
}


#pragma mark ==<Events>
- (void)formatSDCardBtnClicked:(id)sender{
    
    [self showAlertWithTitle:nil Message:DPLocalizedString(@"Format_SD_card")  cancelTitle:DPLocalizedString(@"Setting_Cancel") confirmTitle:DPLocalizedString(@"Title_Confirm")];
}

- (void)sendFormatSDCardRequest{
    CMD_FormatSDCardReq *req = [CMD_FormatSDCardReq new];
    __weak typeof(self) weakSelf = self;
    
    [SVProgressHUD showWithStatus:@"Loading..."];
    [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[req requestCMDData] timeout:25000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            weakSelf.formatSDCardResp = [CMD_FormatSDCardResp yy_modelWithDictionary:dict];
            weakSelf.getDevInfoResp.a_used_size = weakSelf.formatSDCardResp.a_used_size;
            weakSelf.getDevInfoResp.a_free_size = weakSelf.formatSDCardResp.a_free_size;
            
            dispatch_async_on_main_queue(^{
                [weakSelf.devInfoTableView reloadData];
                [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Format_SD_card_success")];
                [SVProgressHUD dismissWithDelay:1.5];
            });
        }
        else{
            dispatch_async_on_main_queue(^{
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Format_SD_card_unsuccess")];
            });
        }
        //        [weakSelf dealWithOperationResultWithResult:result];
    }];
}

- (void)showAlertWithTitle:(NSString*)title Message:(NSString*)msg cancelTitle:(NSString*)cancelTitle
              confirmTitle:(NSString*)confirmTitle{
    
    if( IOS_VERSION < 9 ){
        
        _formatSDAlertView = [[UIAlertView alloc]initWithTitle:title message:msg delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:confirmTitle, nil];
        _formatSDAlertView.delegate = self;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [_formatSDAlertView show];
        });
    }else{
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addAction:[UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            //
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:confirmTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            [self sendFormatSDCardRequest];
        }]];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self presentViewController:alertController animated:YES completion:nil];
        });
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == _updateAlertView) {
        if (buttonIndex == 0) {
            [self startToUpdateDevice];
        }
    }else if(alertView == _formatSDAlertView){
        if (buttonIndex == 1) {
            [self sendFormatSDCardRequest];
        }
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController popToRootViewControllerAnimated:YES];
        });
    }
}

#pragma mark ==<TableViewDelegate>

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    
    if (self.settingModel.ability_stream_passwd_flag) {
        switch (section) {
            case 0:
                return 1;
            case 1:
                return 1;
            case 2:
                return 2;
            case 3:
                return 4;
            case 4:
                return 2;
        }
    }
    else if(self.model.devCapModel.four_channel_flag == 1) {
        switch (section) {
            case 0:
                return 1;
            case 1:
                return 4;
            case 2:
                return 2;
        }
    }
    else{
        switch (section) {
            case 0:
                return 1;
            case 1:
                return 2;
            case 2:
                return 4;
            case 3:
                return 2;
        }
    }
    return 1;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (self.settingModel.ability_stream_passwd_flag) {
        return 5;
    }
    else if(self.model.devCapModel.four_channel_flag == 1) {
        //一拖四的话隐藏摄像头信息
        return 3;
    }else{
        return 4;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    int formatBtnSectionIndex = 0;
    if (self.settingModel.ability_stream_passwd_flag) {
        formatBtnSectionIndex = 4;
    }
    else if(self.model.devCapModel.four_channel_flag == 1) {
        formatBtnSectionIndex = 2;
    }else{
        formatBtnSectionIndex = 3;
    }
        
    return section == formatBtnSectionIndex ? 115: 1;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (self.settingModel.ability_stream_passwd_flag) {
        if (section != 4) {
            return nil;
        }
    }
    else if(self.model.devCapModel.four_channel_flag == 1) {
        if (section != 2) {
            return nil;
        }
    }
    else{
        if (section != 3) {
            return nil;
        }
    }
    DeviceInfoFooterView *footerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"DeviceInfoFooterView" ];
    
    [footerView.formatSDCardBtn setTitle:DPLocalizedString(@"Format") forState:UIControlStateNormal];
    [footerView.formatSDCardBtn addTarget:self action:@selector(formatSDCardBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    footerView.formatSDCardBtn.hidden = _shareByFriend || _getDevInfoResp.a_sd_status<0 ;
    return footerView;
}


-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 35;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    
    if (self.settingModel.ability_stream_passwd_flag) {
        switch (section) {
            case 0:
                return DPLocalizedString(@"DevInfo_DevName");
            case 1:
                return @"设备密码";
            case 2:
                return DPLocalizedString(@"DevInfo_CameraVersion");
            case 3:
                return [self isWiFiDoorBell] ? DPLocalizedString(@"DevInfo_gatewayInfo"): DPLocalizedString(@"DevInfo_CameraInfo");
            case 4:
                return DPLocalizedString(@"DevInfo_SDCard");
        }
    }
    else if(self.model.devCapModel.four_channel_flag == 1) {
        switch (section) {
            case 0:
                return DPLocalizedString(@"DevInfo_DevName");
            case 1:
                return [self isWiFiDoorBell] ? DPLocalizedString(@"DevInfo_gatewayInfo"): DPLocalizedString(@"DevInfo_CameraInfo");
            case 2:
                return DPLocalizedString(@"DevInfo_SDCard");
        }
    }
    else{
        switch (section) {
            case 0:
                return DPLocalizedString(@"DevInfo_DevName");
            case 1:
                return DPLocalizedString(@"DevInfo_CameraVersion");
            case 2:
                return [self isWiFiDoorBell] ? DPLocalizedString(@"DevInfo_gatewayInfo"): DPLocalizedString(@"DevInfo_CameraInfo");
            case 3:
                return DPLocalizedString(@"DevInfo_SDCard");
        }
    }
    
    
    return nil;
}


- (void)queryUpdateStateWithVersion:(NSString*)version cell:(DeviceInfoTableViewCell*)cell{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        __weak typeof(DeviceInfoTableViewCell*) weakCell = cell;
        
        NSArray *arr = [version componentsSeparatedByString:@"."];
        CMD_QueryNewerVersionReq *req = [CMD_QueryNewerVersionReq new];
        req.DeviceId = _model.DeviceId;
        req.FwVersion = arr[2];
        req.AppVersion = arr[3];
        req.DevType = arr[1];
        req.CustomType = arr[0];
        req.HardWareVersion = _getDevInfoResp.a_hardware_version;
        
        NSData *data = [NSJSONSerialization dataWithJSONObject:[req requestCMDData] options:0 error:nil ];
        ServerAddress *upsAddr = [ServerAddress yy_modelWithDictionary:[mUserDefaults objectForKey:@"UPSAddress"]];
        if (!upsAddr) {
            [self connectToCMSAndGetUPSAddress];
            return ;
        }else if (_updateStage == UpdateStageDownloading || _updateStage ==UpdateStageUpdating){
            return;
        }
        NSString *ipAddress = upsAddr.Address;
        int       port      = upsAddr.Port;
        [_netSDK net_queryDeviceVersionWithIP:ipAddress port:port data:data responseBlock:^(int result, NSDictionary *dict) {
            if (result == 0) {
                __strong typeof(weakCell) strongCell = weakCell;
                queryUpdateResp = [CMD_QueryNewerVersionResp yy_modelWithJSON:dict];
                if(queryUpdateResp.HasNewer==1){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        needToUpdate = YES;
                        
                        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:cell.titleLabel.text];
                        NSTextAttachment *attch = [[NSTextAttachment alloc] init];
                        attch.image = self.hasNewVersionImage;
                        
                        NSAttributedString *string = [NSAttributedString attributedStringWithAttachment:attch];
                        [attrStr insertAttributedString:string atIndex:cell.titleLabel.text.length];
                        
                        strongCell.selectionStyle = UITableViewCellSelectionStyleDefault;
                        strongCell.titleLabel.attributedText = attrStr;
                    });
                }
                else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        needToUpdate = NO;
                        strongCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    });
                }
            }
        }];
    });
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    DeviceInfoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceInfoTableViewCell" forIndexPath:indexPath];
    cell.hasNewVersionView.hidden = YES;
    cell.contentLabel.text = @"";
    cell.detailInfoLabel.text = @"";
    
    int i = 0;
    if (self.settingModel.ability_stream_passwd_flag) {
        i = 1;
    }
    
    cell.hasNextPageArrow.hidden = ((indexPath.section==0 && indexPath.row ==0)||(indexPath.section==2 + i && indexPath.row ==2) || (indexPath.section==0 + i && indexPath.row ==0))?NO:YES;
    cell.selectionStyle = cell.hasNextPageArrow.hidden ? UITableViewCellSelectionStyleNone:UITableViewCellSelectionStyleDefault;
    
    
    if (i) {
        switch ( indexPath.section ) {
            case 0:
            {
                cell.titleLabel.text = _model ? _model.DeviceName : @"";
                if (_shareByFriend) {
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.hasNextPageArrow.hidden = YES;
                }
                break;
            }
            case 1:
            {
                cell.titleLabel.text = @"修改设备密码";
                break;
            }
            case 2:
            {
                switch (indexPath.row) {
                    case 0:
                    {
                        cell.titleLabel.text = DPLocalizedString(@"firmware_version");
                        cell.contentLabel.text = _getDevInfoResp ? _getDevInfoResp.a_hardware_version : @"";
                        break;
                    }
                    case 1:
                    {
                        cell.titleLabel.text = DPLocalizedString(@"system_firmware");
                        cell.contentLabel.text = _getDevInfoResp ? _getDevInfoResp.a_software_version : @"";
                        
                        if (_getDevInfoResp.a_software_version.length > 0 && _shareByFriend==0 && (![self isWiFiDoorBell])) {
                            [self queryUpdateStateWithVersion:_getDevInfoResp.a_software_version cell:cell];
                        }
                        break;
                    }
                    default:
                        break;
                }
                break;
            }
            case 3:
            {
                switch (indexPath.row) {
                    case 0:
                    {
                        cell.titleLabel.text = DPLocalizedString(@"DevInfo_DevModelNum");
                        cell.contentLabel.text =  _getDevInfoResp.a_type;
                        break;
                    }
                    case 1:
                    {
                        cell.titleLabel.text = DPLocalizedString(@"DevInfo_DevID");
                        cell.contentLabel.text = _model.DeviceId;
                        break;
                    }
                    case 2:
                    {
                        if ([self isWiFiDoorBell]) {
                            cell.titleLabel.text = DPLocalizedString(@"DevInfo_gatewayVersion");
                            cell.contentLabel.text = _getDevInfoResp.a_gateway_version;
                            if (_getDevInfoResp.a_gateway_version.length > 0 && _shareByFriend==0){
                                [self queryUpdateStateWithVersion:_getDevInfoResp.a_gateway_version cell:cell];
                            }
                        }else{
                            cell.titleLabel.text = DPLocalizedString(@"DevInfo_FlashPrevention");
                            NSString *hzStr = _getDevInfoResp.Hz == 0 ?DPLocalizedString(@"NightVersion_Auto"):[NSString stringWithFormat:@"%dHZ",_getDevInfoResp.Hz];
                            
                            if (_getDevInfoResp.Hz == 0) {//自动
                                cell.contentLabel.text = hzStr;
                            }else{
                                cell.detailInfoLabel.text = hzStr;
                            }
                        }
                        
                        cell.hasNextPageArrow.hidden = _getDevInfoResp.Hz == 0;
                        cell.selectionStyle = cell.hasNextPageArrow.hidden ? UITableViewCellSelectionStyleNone:UITableViewCellSelectionStyleDefault;
                        break;
                    }
                    case 3:
                    {
                        cell.titleLabel.text = DPLocalizedString(@"DevInfo_WiFiName");
                        cell.contentLabel.text = _getDevInfoResp.a_SSID;
                        break;
                    }
                    default:
                        break;
                }
                
                break;
            }
                
            case 4:
            {
                switch (indexPath.row) {
                    case 0:
                    {
                        NSString *usedSizeStr = _getDevInfoResp ? [NSString stringWithFormat:@"%.1fGB",_getDevInfoResp.a_used_size/1024.0]:@"";
                        cell.titleLabel.text = DPLocalizedString(@"used_storage");
                        cell.contentLabel.text = usedSizeStr;
                        break;
                    }
                    case 1:
                    {
                        NSString *freeSizeStr = _getDevInfoResp ? [NSString stringWithFormat:@"%.1fGB",_getDevInfoResp.a_free_size/1024.0]:@"";
                        cell.titleLabel.text = DPLocalizedString(@"free_storage");
                        cell.contentLabel.text = freeSizeStr;
                        break;                }
                    default:
                        break;
                }
                break;
            }
            default:
                break;
        }
    }
    else if (self.model.devCapModel.four_channel_flag == 1){
        switch (indexPath.section)
        {
            case 0:
                {
                    cell.titleLabel.text = _model ? _model.DeviceName : @"";
                    if (_shareByFriend) {
                        cell.selectionStyle = UITableViewCellSelectionStyleNone;
                        cell.hasNextPageArrow.hidden = YES;
                    }
                    break;
                }
            case 1:
                {
                    
                    switch (indexPath.row) {
                        case 0:
                        {
                            cell.titleLabel.text = DPLocalizedString(@"DevInfo_DevModelNum");
                            cell.contentLabel.text =  _getDevInfoResp.a_type;
                            break;
                        }
                        case 1:
                        {
                            cell.titleLabel.text = DPLocalizedString(@"DevInfo_DevID");
                            cell.contentLabel.text = _model.DeviceId;
                            break;
                        }
                        case 2:
                        {
                            if ([self isWiFiDoorBell]) {
                                cell.titleLabel.text = DPLocalizedString(@"DevInfo_gatewayVersion");
                                cell.contentLabel.text = _getDevInfoResp.a_gateway_version;
                                if (_getDevInfoResp.a_gateway_version.length > 0 && _shareByFriend==0){
                                    [self queryUpdateStateWithVersion:_getDevInfoResp.a_gateway_version cell:cell];
                                }
                            }else{
                                cell.titleLabel.text = DPLocalizedString(@"DevInfo_FlashPrevention");
                                NSString *hzStr = _getDevInfoResp.Hz == 0 ?DPLocalizedString(@"NightVersion_Auto"):[NSString stringWithFormat:@"%dHZ",_getDevInfoResp.Hz];
                                
                                if (_getDevInfoResp.Hz == 0) {//自动
                                    cell.contentLabel.text = hzStr;
                                }else{
                                    cell.detailInfoLabel.text = hzStr;
                                }
                            }
                            
                            cell.hasNextPageArrow.hidden = _getDevInfoResp.Hz == 0;
                            cell.selectionStyle = cell.hasNextPageArrow.hidden ? UITableViewCellSelectionStyleNone:UITableViewCellSelectionStyleDefault;
                            break;
                        }
                        case 3:
                        {
                            cell.titleLabel.text = DPLocalizedString(@"DevInfo_WiFiName");
                            cell.contentLabel.text = _getDevInfoResp.a_SSID;
                            break;
                        }
                        default:
                            break;
                    }
                    
                    break;
                }
                
            case 2:
                {
                    switch (indexPath.row) {
                        case 0:
                        {
                            NSString *usedSizeStr = _getDevInfoResp ? [NSString stringWithFormat:@"%.1fGB",_getDevInfoResp.a_used_size/1024.0]:@"";
                            cell.titleLabel.text = DPLocalizedString(@"used_storage");
                            cell.contentLabel.text = usedSizeStr;
                            break;
                        }
                        case 1:
                        {
                            NSString *freeSizeStr = _getDevInfoResp ? [NSString stringWithFormat:@"%.1fGB",_getDevInfoResp.a_free_size/1024.0]:@"";
                            cell.titleLabel.text = DPLocalizedString(@"free_storage");
                            cell.contentLabel.text = freeSizeStr;
                            break;                }
                        default:
                            break;
                    }
                    break;
                }
            default:
                break;
        }
    }
    else{
        switch ( indexPath.section ) {
            case 0:
            {
                cell.titleLabel.text = _model ? _model.DeviceName : @"";
                if (_shareByFriend) {
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.hasNextPageArrow.hidden = YES;
                }
                break;
            }
            case 1:
            {
                switch (indexPath.row) {
                    case 0:
                    {
                        cell.titleLabel.text = DPLocalizedString(@"firmware_version");
                        cell.contentLabel.text = _getDevInfoResp ? _getDevInfoResp.a_hardware_version : @"";
                        break;
                    }
                    case 1:
                    {
                        cell.titleLabel.text = DPLocalizedString(@"system_firmware");
                        cell.contentLabel.text = _getDevInfoResp ? _getDevInfoResp.a_software_version : @"";
                        
                        if (_getDevInfoResp.a_software_version.length > 0 && _shareByFriend==0 && (![self isWiFiDoorBell]) ){
                            [self queryUpdateStateWithVersion:_getDevInfoResp.a_software_version cell:cell];
                        }
                        break;
                    }
                    default:
                        break;
                }
                break;
            }
            case 2:
            {
                switch (indexPath.row) {
                    case 0:
                    {
                        cell.titleLabel.text = DPLocalizedString(@"DevInfo_DevModelNum");
                        cell.contentLabel.text =  _getDevInfoResp.a_type;
                        break;
                    }
                    case 1:
                    {
                        cell.titleLabel.text = DPLocalizedString(@"DevInfo_DevID");
                        cell.contentLabel.text = _model.DeviceId;
                        break;
                    }
                    case 2:
                    {
                        if ([self isWiFiDoorBell]) {
                            cell.titleLabel.text = DPLocalizedString(@"DevInfo_gatewayVersion");
                            cell.contentLabel.text = _getDevInfoResp.a_gateway_version;
                            if (_getDevInfoResp.a_gateway_version.length > 0 && _shareByFriend==0){
                                [self queryUpdateStateWithVersion:_getDevInfoResp.a_gateway_version cell:cell];
                            }
                        }else{
                            cell.titleLabel.text = DPLocalizedString(@"DevInfo_FlashPrevention");
                            NSString *hzStr = _getDevInfoResp.Hz == 0 ?DPLocalizedString(@"NightVersion_Auto"):[NSString stringWithFormat:@"%dHZ",_getDevInfoResp.Hz];
                            
                            if (_getDevInfoResp.Hz == 0) {//自动
                                cell.contentLabel.text = hzStr;
                            }else{
                                cell.detailInfoLabel.text = hzStr;
                            }
                        }
                        
                        cell.hasNextPageArrow.hidden = _getDevInfoResp.Hz == 0;
                        cell.selectionStyle = cell.hasNextPageArrow.hidden ? UITableViewCellSelectionStyleNone:UITableViewCellSelectionStyleDefault;
                        break;
                    }
                    case 3:
                    {
                        cell.titleLabel.text = DPLocalizedString(@"DevInfo_WiFiName");
                        cell.contentLabel.text = _getDevInfoResp.a_SSID;
                        break;
                    }
                    default:
                        break;
                }
                
                break;
            }
                
            case 3:
            {
                switch (indexPath.row) {
                    case 0:
                    {
                        NSString *usedSizeStr = _getDevInfoResp ? [NSString stringWithFormat:@"%.1fGB",_getDevInfoResp.a_used_size/1024.0]:@"";
                        cell.titleLabel.text = DPLocalizedString(@"used_storage");
                        cell.contentLabel.text = usedSizeStr;
                        break;
                    }
                    case 1:
                    {
                        NSString *freeSizeStr = _getDevInfoResp ? [NSString stringWithFormat:@"%.1fGB",_getDevInfoResp.a_free_size/1024.0]:@"";
                        cell.titleLabel.text = DPLocalizedString(@"free_storage");
                        cell.contentLabel.text = freeSizeStr;
                        break;                }
                    default:
                        break;
                }
                break;
            }
            default:
                break;
        }
    }
    
    
    return cell;
}


- (BOOL)isWiFiDoorBell{
    GosDetailedDeviceType detailType = [DeviceDataModel detailedDeviceTypeWithString:[self.model.DeviceId substringWithRange:NSMakeRange(3, 2)]];
    return detailType==GosDetailedDeviceType_T5100ZJ || detailType == GosDetailedDeviceType_T5200HCA;
}

- (void)connectToCMSAndGetUPSAddress{
    //    if(!_netSDK){
    //        _netSDK = [NetSDK sharedInstance];
    //    }
    //
    //    [_netSDK net_connectToCMSWithAddress:@"119.23.130.8" nport:6001  resultBlock:^(int result) {
    //        if (result==0) {
    //            [self getUPSAddress];
    //        }else{
    //            NSLog(@"connectToCMS__________________________________________error");
    //        }
    //    }];
}


- (void)getUPSAddress
{
    //    CMD_AppGetBSAddressRequest *req = [CMD_AppGetBSAddressRequest new];
    //    req.UserName = [SaveDataModel getUserName];
    //    req.Password = [SaveDataModel getUserPassword];
    //    req.ServerType = @[@2,@3,@4];
    //
    //    if (!_netSDK) {
    //        _netSDK = [NetSDK sharedInstance];
    //    }
    //    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    //        [_netSDK net_sendCMSRequestWithData:[req requestCMDData] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
    //            if (result ==0) {
    //                NSArray *serverList = dict[@"ServerList"];
    //                if( serverList.count >0 && serverList.count<5){
    //                }
    //                for (NSDictionary *addressDict in serverList) {
    //                    ServerAddress *serverAddr = [ServerAddress yy_modelWithDictionary:addressDict];
    //                    switch (serverAddr.Type) {
    //                        case 2:
    //                            [mUserDefaults setObject:addressDict forKey:@"MPSAddress"];
    //                            break;
    //                        case 3:
    //                            [mUserDefaults setObject:addressDict forKey:kCGSA_ADDRESS];
    //                                                        break;
    //                        case 4:
    //                        {
    //                            [mUserDefaults setObject:addressDict forKey:@"UPSAddress"];
    //                            dispatch_async(dispatch_get_main_queue(), ^{
    //                                [self.devInfoTableView reloadData];
    //                            });
    //                            break;
    //                        }
    //
    //                        default:
    //                            break;
    //                    }
    //                }
    //                [mUserDefaults synchronize];
    //            }else{
    //                NSLog(@"getUPSAddress__________________________________________error");
    //            }
    //        }];
    //    });
}




- (UIImage *)hasNewVersionImage{
    if (!_hasNewVersionImage) {
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(4, 4, 10, 10)];
        view.backgroundColor = [UIColor redColor];
        view.layer.cornerRadius = 5;
        
        UIView *bgView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 18, 18)];
        [bgView addSubview:view];
        
        _hasNewVersionImage = [self convertViewToImage:bgView];
    }
    return _hasNewVersionImage;
}

-(UIImage*)convertViewToImage:(UIView*)v{
    
    CGSize s = v.bounds.size;
    // 下面方法，第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
    UIGraphicsBeginImageContextWithOptions(s, NO, [UIScreen mainScreen].scale);
    [v.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage*image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (_shareByFriend) {
        return;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    
    int i = 0;
    
    if (self.settingModel.ability_stream_passwd_flag) {
        i = 1;
    }else if (self.model.devCapModel.four_channel_flag == 1){
        i = -1;
    }
    
    if ( i==1 && indexPath.section == 1 && indexPath.row == 0) {
        //推出修改密码
        ModifyDevicePswViewController *psdVC = [[ModifyDevicePswViewController alloc]init];
        psdVC.deviceId = self.model.DeviceId;
        [self.navigationController pushViewController:psdVC animated:YES];
    }
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        
        __weak typeof(self) weakSelf = self;
        DeviceNameSettingViewController *vc = [[DeviceNameSettingViewController alloc] init];
        [vc didChangeDevNameCallback:^(NSString *name) {
            [weakSelf sendChangeDevNameRequestWithName:name];
        } ];
        vc.model = _model;
        [self.navigationController pushViewController:vc animated:YES];
        
    }
    if (indexPath.section == 2 + i && indexPath.row == 2) {
        
        if ([self isWiFiDoorBell]) {
            if(needToUpdate){
                [self showUpdateAlertView];
            }
        }else{
            if (_getDevInfoResp.Hz == 0 || _shareByFriend) {
                return;
            }
            __weak typeof(self) weakSelf = self;
            FlashPreventionViewController *vc = [[FlashPreventionViewController alloc] init];
            [vc didFinishSettingNTSCWithCallback:^(int result) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.getDevInfoResp.Hz = result;
                    [weakSelf.navigationController popViewControllerAnimated:YES];
                    [weakSelf.devInfoTableView reloadData];
                });
            }];
            vc.hz = _getDevInfoResp.Hz;
            vc.model = _model;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
    if ((indexPath.section == 1 + i && indexPath.row == 1) && (![self isWiFiDoorBell]) ) {
        if(needToUpdate){
            [self showUpdateAlertView];
        }
    }
}

- (void)sendChangeDevNameRequestWithName:(NSString*)name{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:YES];
        [SVProgressHUD showWithStatus:@"Loading..."];
    });
    CBS_ModifyAttrRequest *req = [CBS_ModifyAttrRequest new];
    BodyModifyAttrRequest *body = [BodyModifyAttrRequest new];
    body.DeviceId = _model.DeviceId;
    body.DeviceName = name;
    body.StreamUser = _model.StreamUser;
    body.StreamPassword = _model.StreamPassword;
    __weak typeof(self) weakSelf = self;
    [_netSDK net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            weakSelf.model.DeviceName = name;
        }
        [weakSelf dealWithOperationResultWithResult:result];
    }];
}

#pragma mark <UpdateDevice>升级

- (void)startToUpdateDevice{
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showWithStatus:@"Loading..."];
    });
    
    CMD_UpdateDeviceReq *req = [CMD_UpdateDeviceReq new];
    req.a_ipaddr = queryUpdateResp.UpsIp;
    req.un_port  = queryUpdateResp.UpsPort;
    req.cancelFlag = 0;
    
    [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[req requestCMDData] timeout:12000 responseBlock:^(int result, NSDictionary *dict) {
        CMD_UpdateDeviceResp *resp = [CMD_UpdateDeviceResp yy_modelWithDictionary:dict];
        
        if (result == 0) {
            [weakSelf showUpdateStateWithResult:resp.result];
        }
        
        [weakSelf dealWithOperationResultWithResult:result];
    }];
}

- (void)showUpdateStateWithResult:(int)result{
    if( result == 0 ){
        [self showUpdatingDeviceView];
    }else if( result >= 100 && result<=200 ){
        
        if (result >= 130 ) {
            _updateStage = UpdateStageUpdating;
            if (!_autoUpdateProgressTimer) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _autoUpdateProgressTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(autoUpdateProgressTimerFunc) userInfo:nil repeats:YES];
                });
            }
        }else{
            [self updateViewWithProgress:(result-100)];
        }
        
    }else if(result == 3){
        if (_updateStage == UpdateStageDownloading || _updateStage == UpdateStageUpdating) {
            [self showUpdateErrorInfo];
            //            [self updateViewWithProgress:0];
            //            [self showUpdateErrorAndTryAgain];
        }
    }
    else if(result == 4 || result ==5){
        
        [self updateViewWithProgress:100];
        _updateStage = UpdateStageSucceeded;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissUpdateDeviceViewAndShowThirdStage];
        });
    }else if(result <= 2){ ////1->请求下载失败，申请内存失败 //2->请求下载失败,设备端创建线程失败
        [self showUpdateErrorInfo];
    }
}

- (void)showUpdatingDeviceView{ //防止设备端在升级下载的1,2,3阶段，突然返回一个0
    
    if (_updateStage == UpdateStageDownloading || _updateStage == UpdateStageUpdating || _updateStage == UpdateStageSucceeded) {
        return;
    }
    _updateStage = UpdateStageDownloading;
    _timerCountAfterUpdateThirdStage = 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self configureForUpdateView];
        [self addUpdateViewIntoKeyWindow];
        
        [self startUpdateProgressTimer];
    });
}

- (void)startUpdateProgressTimer{
    
    if(!_updateProgressTimer){
        _updateProgressTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(updateProgressTiemrFunc:) userInfo:nil repeats:YES];
    }
}

- (void)stopProgressTimer{
    if([_updateProgressTimer isValid ]){
        [_updateProgressTimer invalidate];
        _updateProgressTimer = nil;
    }
}

- (void)updateProgressTiemrFunc:(id)sender{
    __weak typeof(self) weakSelf = self;
    
    
    CMD_UpdateDeviceReq *req = [CMD_UpdateDeviceReq new];
    req.a_ipaddr = queryUpdateResp.UpsIp;
    req.un_port  = queryUpdateResp.UpsPort;
    req.cancelFlag = 0;
    
    [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[req requestCMDData] timeout:12000 responseBlock:^(int result, NSDictionary *dict) {
        CMD_UpdateDeviceResp *resp = [CMD_UpdateDeviceResp yy_modelWithDictionary:dict];
        if (result == 0) {
            [weakSelf showUpdateStateWithResult:resp.result];
        }
    }];
}

- (void)showUpdateErrorAndTryAgain{
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showWithStatus:DPLocalizedString(@"Update_DownloadErrorTryAgain")];
        [SVProgressHUD dismissWithDelay:2];
    });
}


- (void)showUpdateErrorInfo{
    _updateStage = UpdateStageFailed;
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showWithStatus:DPLocalizedString(@"Update_UpdateError_TryAgainLater")];
        [SVProgressHUD dismissWithDelay:3];
        
        [updateView removeFromSuperview];
        updateView = nil;
        [updateViewBg removeFromSuperview];
        updateViewBg = nil;
    });
}

- (void)updateViewWithProgress:(int)progress{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if(!updateView){
            [self configureForUpdateView];
        }
        if(!updateView.superview){
            [self addUpdateViewIntoKeyWindow];
        }
        if(!_updateProgressTimer){
            _updateProgressTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(updateProgressTiemrFunc:) userInfo:nil repeats:YES];
        }
        updateView.updateProgressView.progress = progress*1.0/100;
        updateView.updateProgressLabel.text = [NSString stringWithFormat:@"%d/100",progress];
    });
}

- (void)autoUpdateProgressTimerFunc{
    
    if (_updateStage == UpdateStageSucceeded) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_autoUpdateProgressTimer invalidate];
            _autoUpdateProgressTimer = nil;
        });
        return;
    }
    
    if ( _timerCountAfterUpdateThirdStage++ > 440) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_autoUpdateProgressTimer invalidate];
            _autoUpdateProgressTimer = nil;
        });
    }
    int progress = 30 + _timerCountAfterUpdateThirdStage/440.0 *(99-30);
    if (progress>99) {
        progress = 99;
    }
    [self updateViewWithProgress:progress];
}

- (void)dismissUpdateDeviceViewAndShowThirdStage{
    
    _timerCountAfterUpdateThirdStage = 0;
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil message:DPLocalizedString(@"Update_Tips_DowloadComplete") delegate:nil cancelButtonTitle:DPLocalizedString(@"Title_Confirm") otherButtonTitles:nil];
    alert.delegate = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopProgressTimer];
        
        [updateView removeFromSuperview];
        updateView = nil;
        [updateViewBg removeFromSuperview];
        updateViewBg = nil;
        
        [alert show];
    });
    
    //移除能力集缓存
    [[UISettingManagement sharedInstance] removeSettingModel:self.model.DeviceId];
}

#pragma mark = 取消升级
- (void)cancelUpdateBtnClicked:(id)sender{
    CMD_CancelUpdateDeviceReq *req = [CMD_CancelUpdateDeviceReq new];
    req.a_ipaddr = queryUpdateResp.UpsIp;
    req.un_port  = queryUpdateResp.UpsPort;
    req.cancelFlag = 1;
    
    __weak typeof(self) weakSelf = self;
    
    [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[req requestCMDData] timeout:12000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            [weakSelf actionForCancelUpdate];
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showInfoWithStatus:DPLocalizedString(@"Operation_Failed")];
            });
        }
    }];
}

- (void)actionForCancelUpdate{
    _updateStage = UpdateStageCancelled;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (_autoUpdateProgressTimer) {
            [_autoUpdateProgressTimer invalidate];
            _autoUpdateProgressTimer  = nil;
        }
        
        if (_updateProgressTimer) {
            [_updateProgressTimer invalidate];
            _updateProgressTimer = nil;
        }
        
        [updateView removeFromSuperview];
        updateView = nil;
        [updateViewBg removeFromSuperview];
        updateViewBg = nil;
        
        [self.devInfoTableView reloadData];
        [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Update_CancelSucceeded")];
    });
}

- (void)configureForUpdateView {
    
    updateView = [[[NSBundle mainBundle] loadNibNamed:@"DeviceUpdateView" owner:self options:nil] objectAtIndex:0];
    updateView.layer.cornerRadius = 10;
    
    updateView.updateTipsTxtView.userInteractionEnabled = NO;
    updateView.updateTipsTxtView.text = DPLocalizedString(@"Update_Tips_Downloading");
    [updateView.updateTitleLabel setText:DPLocalizedString(@"Update_Downloading")];
    [updateView.cancelUpdateBtn setTitle:DPLocalizedString(@"Setting_Cancel") forState: UIControlStateNormal];
    [updateView.cancelUpdateBtn addTarget:self action:@selector(cancelUpdateBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    updateViewBg = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    updateViewBg.backgroundColor = [UIColor blackColor];
    updateViewBg.alpha = 0.5;
}

- (void)addUpdateViewIntoKeyWindow{
    
    if (!updateView.superview) {
        [[UIApplication sharedApplication].keyWindow addSubview:updateViewBg];
        [[UIApplication sharedApplication].keyWindow addSubview: updateView];
        [updateView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(updateViewBg);
            make.leading.equalTo(updateViewBg).offset(30);
            make.width.equalTo(updateView.mas_height).multipliedBy(28/20.0);
        }];
    }
}

- (void)showUpdateAlertView{
    
    updateTipsView = [[NSBundle mainBundle] loadNibNamed:@"DeviceUpdateTipsView" owner:self options:nil][0];
    updateTipsView.layer.cornerRadius = 10;
    
    //app = "308.app.E_900.tar.bz2";
    NSMutableArray *newVersionArray = [[queryUpdateResp.app componentsSeparatedByString:@"."] mutableCopy];
    NSMutableArray *oldVersionArray = [[ ([self isWiFiDoorBell]?_getDevInfoResp.a_gateway_version: _getDevInfoResp.a_software_version) componentsSeparatedByString:@"."] mutableCopy];
    
    if (newVersionArray.count>0 && oldVersionArray.count>=4) {
        oldVersionArray[3] = newVersionArray[0];
    }
    NSString *versionStr = [oldVersionArray componentsJoinedByString:@"."];
    
    updateTipsView.versionInfo.text = [NSString stringWithFormat:@"%@ %@",DPLocalizedString(@"Update_CanUpdateTo"),versionStr];
    
    updateTipsView.updateContentTxt.userInteractionEnabled = NO;
    updateTipsView.updateContentTxt.text = queryUpdateResp.Des[@"app"];
    updateTipsView.updateTipsTitle.text = DPLocalizedString(@"Update_FirmwareUpdate");
    
    [updateTipsView.updateNowBtn setTitle:DPLocalizedString(@"Update_UpdateRightNow") forState:0];
    [updateTipsView.updateNowBtn addTarget:self action:@selector(updateNowBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [updateTipsView.updateNextTimeBtn setTitle:DPLocalizedString(@"Update_UpdateNextTime") forState:0];
    [updateTipsView.updateNextTimeBtn addTarget:self action:@selector(updateNextTimeBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    
    updateViewBg = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    updateViewBg.backgroundColor = [UIColor blackColor];
    updateViewBg.alpha = 0.5;
    
    [self addUpdateTipsViewIntoKeyWindow];
}

- (void)updateNowBtnClicked:(id)sender{
    [self removeUpdateTipsView];
    [self startToUpdateDevice];
}

- (void)addUpdateTipsViewIntoKeyWindow{
    
    if (!updateTipsView.superview) {
        [[UIApplication sharedApplication].keyWindow addSubview:updateViewBg];
        [[UIApplication sharedApplication].keyWindow addSubview: updateTipsView];
        [updateTipsView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(updateViewBg);
            make.height.mas_equalTo(240);
            //            make.leading.equalTo(updateViewBg).offset(25);
            make.width.equalTo(updateTipsView.mas_height).multipliedBy(280/240.0);
        }];
    }
}

- (void)removeUpdateTipsView{
    dispatch_async(dispatch_get_main_queue(), ^{
        [updateTipsView removeFromSuperview];
        updateTipsView = nil;
        [updateViewBg removeFromSuperview];
        updateViewBg = nil;
    });
}

- (void)updateNextTimeBtnClicked:(id)sender{
    [self removeUpdateTipsView];
}


- (void)showUpdateAlertWithTitle:(NSString*)title Message:(NSString*)msg cancelTitle:(NSString*)cancelTitle
                    confirmTitle:(NSString*)confirmTitle{
    
    if( [[UIDevice currentDevice]systemVersion].floatValue < 8 ){
        
        _updateAlertView = [[UIAlertView alloc]initWithTitle:title message:msg delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:confirmTitle, nil];
        _updateAlertView.delegate = self;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_updateAlertView show];
        });
    }else{
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addAction:[UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self startToUpdateDevice];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:confirmTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:alertController animated:YES completion:nil];
        });
    }
}



@end

