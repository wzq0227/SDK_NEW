//
//  NvrInfoViewController.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/24.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "NvrInfoViewController.h"
#import "NvrInfoTableViewCell.h"
#import "NetSDK.h"
#import "BaseCommand.h"
#import "DeviceNameSettingViewController.h"
#import "CBSCommand.h"


/** NVR 设备信息 TableView 高度 */
#define NVR_INFO_TB_CELL_HEIGHT 44.0f

/** NVR 设备信息 TableView 项数（总行数）*/
#define NVR_INFO_TB_ROW_NUM 5

/** NVR 设备信息 TableView 分类（总section数）*/
#define NVR_info_TB_SECTION_NUM 3


@interface NvrInfoViewController () <
                                        UITableViewDataSource,
                                        UITableViewDelegate
                                    >

@property (weak, nonatomic) IBOutlet UITableView *infoTableView;

/** 设备数据 model */
@property (nonatomic, strong) DeviceDataModel *devDataModel;

/** TUTK 平台 ID （长度：20）*/
@property (nonatomic, copy) NSString *tutkDevId;

/** 3.5 平台 ID （长度：28）*/
@property (nonatomic, copy) NSString *platformDevId;

/** NVR 设置 TableView 数据源  */
@property (nonatomic, strong) NSMutableDictionary *nvrInfoDataDict;

@property(nonatomic, strong) CMD_GetDevInfoResp *getDevInfoResp;

@end

@implementation NvrInfoViewController


- (instancetype)initWithDevDataModel:(DeviceDataModel *)devDataModel
{
    if (self = [super init])
    {
        self.devDataModel  = devDataModel;
        self.tutkDevId     = [devDataModel.DeviceId substringFromIndex:8]; // 截取掉下标7之后的字符串;
        self.platformDevId = devDataModel.DeviceId;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = DPLocalizedString(@"Setting_DeviceInfo");
    self.view.backgroundColor = [UIColor colorWithRed:238.0f/255.0f
                                                green:238.0f/255.0f
                                                 blue:238.0f/255.0f
                                                alpha:1.0f];
    [self configTableView];
    
    [self initInfoData];
    
    [self obtainNvrDeviceInfo];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)dealloc
{
    NSLog(@"----------- NvrInfoViewController dealloc -----------");
}


#pragma mark -- 设置 TableView
- (void)configTableView
{
//    self.automaticallyAdjustsScrollViewInsets = false;
    self.automaticallyAdjustsScrollViewInsets = YES;
    self.navigationController.navigationBar.translucent = NO;
    self.infoTableView.scrollEnabled          = NO;
    self.infoTableView.rowHeight              = NVR_INFO_TB_CELL_HEIGHT;
    self.infoTableView.sectionHeaderHeight    = 1.0f;
    self.infoTableView.sectionFooterHeight    = 1.0f;
}


#pragma mark -- 获取 NVR 设备信息
- (void)obtainNvrDeviceInfo
{
    [SVProgressHUD showWithStatus:@"Loading..."];
    
    __weak typeof(self) weakSelf = self;
    CMD_GetDevInfoReq *getDevInfoReq = [CMD_GetDevInfoReq new];
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:self.devDataModel.DeviceId
                                              requestData:[getDevInfoReq requestCMDData]
                                                  timeout:5000
                                            responseBlock:^(int result, NSDictionary *dict) {
                                                
                                                __strong typeof(weakSelf)strongSelf = weakSelf;
                                                if (!strongSelf)
                                                {
                                                    NSLog(@"对象丢失，无法处理 NVR 设备信息结果！");
                                                    return ;
                                                }
                                                if (0 == result)
                                                {
                                                    strongSelf.getDevInfoResp = [CMD_GetDevInfoResp yy_modelWithDictionary:dict];
                                                }
                                                [strongSelf handleObtainInfoRespWithResult:result];
                                            }];
}


#pragma mark -- 发送修改名称请求
- (void)requestChangeDevForName:(NSString*)name
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.navigationController popViewControllerAnimated:YES];
        [SVProgressHUD showWithStatus:@"Loading..."];
    });
    
    CBS_ModifyAttrRequest *modifyAttrreq = [CBS_ModifyAttrRequest new];
    BodyModifyAttrRequest *body          = [BodyModifyAttrRequest new];
    body.DeviceId                        = self.devDataModel.DeviceId;
    body.DeviceName                      = name;
    body.StreamUser                      = self.devDataModel.StreamUser;
    body.StreamPassword                  = self.devDataModel.StreamPassword;
    
    __weak typeof(self) weakSelf = self;
    [[NetSDK sharedInstance] net_sendCBSRequestMsgType:modifyAttrreq.MessageType
                                              bodyData:[body yy_modelToJSONObject]
                                               timeout:8000
                                         responseBlock:^(int result, NSDictionary *dict) {
                                             
                                             __strong typeof(weakSelf)strongSelf = weakSelf;
                                             if (!strongSelf)
                                             {
                                                 NSLog(@"对象丢失，无法处理修 NVR 改名称结果！");
                                                 return ;
                                             }
                                             if (result == 0)
                                             {
                                                 strongSelf.devDataModel.DeviceName = name;
                                             }
                                             [strongSelf handleChangeDevNameRespWithResult:result];
                                         }];
}


#pragma mark -- 处理 获取 NVR 设备信息请求结果
- (void)handleObtainInfoRespWithResult:(int)result
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法处理 NVR 设备信息结果！");
            return ;
        }
        [self initInfoData];
        [strongSelf.infoTableView reloadData];
        if (0 != result)
        {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Get_data_failed")];
        }
        else
        {
            [SVProgressHUD dismiss];
        }
    });
}


#pragma mark -- 处理 获取 NVR 设备名称修改请求结果
- (void)handleChangeDevNameRespWithResult:(int)result
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法处理 NVR 设备名称修改结果！");
            return ;
        }
        [strongSelf.infoTableView reloadData];
        if (0 != result)
        {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
        }
        else
        {
            [SVProgressHUD dismiss];
        }
    });
}

#pragma mark -- 初始化数据
- (void)initInfoData
{
    if (!_nvrInfoDataDict)
    {
        _nvrInfoDataDict = [NSMutableDictionary dictionaryWithCapacity:NVR_INFO_TB_ROW_NUM];
    }
    [self.nvrInfoDataDict removeAllObjects];
    
    for (int i = 0; i < NVR_INFO_TB_ROW_NUM; i++)
    {
        NvrInfoCellDataModel *dataModel = [[NvrInfoCellDataModel alloc] init];
        if (0 == i)         // 系统固件
        {
            dataModel.cellStyle    = NvrInfoCellSysFirmware;
            dataModel.infoKeyStr   = DPLocalizedString(@"system_firmware");
            dataModel.infoValueStr = self.getDevInfoResp ? self.getDevInfoResp.a_software_version : @"";
            [self.nvrInfoDataDict setObject:dataModel
                                     forKey:[NSNumber numberWithInteger:NvrInfoCellSysFirmware]];
        }
        else if (1 == i)    // 应用固件
        {
            dataModel.cellStyle    = NvrInfoCellAppFirmware;
            dataModel.infoKeyStr   = DPLocalizedString(@"firmware_version");
            dataModel.infoValueStr = self.getDevInfoResp ? self.getDevInfoResp.a_hardware_version : @"";
            [self.nvrInfoDataDict setObject:dataModel
                                     forKey:[NSNumber numberWithInteger:NvrInfoCellAppFirmware]];
        }
        else if (2 == i)    // 设备型号
        {
            dataModel.cellStyle    = NvrInfoCellDevModel;
            dataModel.infoKeyStr   = DPLocalizedString(@"DevInfo_DevModelNum");
            dataModel.infoValueStr = self.getDevInfoResp ? self.getDevInfoResp.a_type : @"";
            [self.nvrInfoDataDict setObject:dataModel
                                     forKey:[NSNumber numberWithInteger:NvrInfoCellDevModel]];
        }
        else if (3 == i)    // 设备 ID
        {
            dataModel.cellStyle    = NvrInfoCellDevId;
            dataModel.infoKeyStr   = DPLocalizedString(@"DevInfo_DevID");
            dataModel.infoValueStr = self.devDataModel.DeviceId;
            [self.nvrInfoDataDict setObject:dataModel
                                     forKey:[NSNumber numberWithInteger:NvrInfoCellDevId]];
        }
        else if (4 == i)    // WiFi 名称
        {
            dataModel.cellStyle    = NvrInfoCellWiFiName;
            dataModel.infoKeyStr   = DPLocalizedString(@"DevInfo_WiFiName");
            dataModel.infoValueStr = self.getDevInfoResp ? self.getDevInfoResp.a_SSID : @"";
            [self.nvrInfoDataDict setObject:dataModel
                                     forKey:[NSNumber numberWithInteger:NvrInfoCellWiFiName]];
        }
    }
}


#pragma mark -- TableView delegate & datasource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NVR_info_TB_SECTION_NUM;
}


- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    if (0 == section)
    {
        return 1;
    }
    else if (1 == section)
    {
        return 2;
    }
    else if (2 == section)
    {
        return 3;
    }
    else
    {
        return 0;
    }
}


- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section
{
    if (0 == section)
    {
        return DPLocalizedString(@"DevInfo_DevName");
    }
    else if (1 == section)
    {
        return DPLocalizedString(@"NvrVersion");
    }
    else if (2 == section)
    {
        return DPLocalizedString(@"Setting_DeviceInfo");
    }
    else
    {
        return nil;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *nvrInfoCellId = @"NVRInfoCellId";
    NSInteger sectionIndex = indexPath.section;
    NSInteger rowIndex     = indexPath.row;
    if (0 == sectionIndex)
    {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                       reuseIdentifier:nil];
        cell.textLabel.text = self.devDataModel.DeviceName;
        cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }
    else
    {
        NvrInfoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nvrInfoCellId];
        if (!cell)
        {
            NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"NvrInfoTableViewCell"
                                                              owner:self
                                                            options:nil];
            cell = nibArray[0];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType  = UITableViewCellAccessoryNone;
        if (self.nvrInfoDataDict.count <= rowIndex)
        {
            return [[UITableViewCell alloc] init];
            
        }
        if (1 == sectionIndex)
        {
            if (0 == rowIndex)
            {
                cell.infoCellData = [self.nvrInfoDataDict objectForKey:[NSNumber numberWithInteger:NvrInfoCellSysFirmware]];
            }
            else if (1 == rowIndex)
            {
                cell.infoCellData = [self.nvrInfoDataDict objectForKey:[NSNumber numberWithInteger:NvrInfoCellAppFirmware]];
            }
            else
            {
                return [[UITableViewCell alloc] init];
            }
        }
        else if (2 == sectionIndex)
        {
            if (0 == rowIndex)
            {
                cell.infoCellData = [self.nvrInfoDataDict objectForKey:[NSNumber numberWithInteger:NvrInfoCellDevModel]];
            }
            else if (1 == rowIndex)
            {
                cell.infoCellData = [self.nvrInfoDataDict objectForKey:[NSNumber numberWithInteger:NvrInfoCellDevId]];
            }
            else if (2 == rowIndex)
            {
                cell.infoCellData = [self.nvrInfoDataDict objectForKey:[NSNumber numberWithInteger:NvrInfoCellWiFiName]];
            }
            else
            {
                return [[UITableViewCell alloc] init];
            }
        }
        else
        {
            return [[UITableViewCell alloc] init];
        }
        return cell;
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (0 == indexPath.section
        && 0 == indexPath.row)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        __weak typeof(self) weakSelf = self;
        DeviceNameSettingViewController *setDevNameVC = [[DeviceNameSettingViewController alloc] init];
        [setDevNameVC didChangeDevNameCallback:^(NSString *name) {
            
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                NSLog(@"对象丢失，无法处理修改 NVR 名称！");
                return ;
            }
            [strongSelf requestChangeDevForName:name];
        } ];
        setDevNameVC.model = self.devDataModel;
        if (setDevNameVC)
        {
            [self.navigationController pushViewController:setDevNameVC
                                                 animated:YES];
        }
    }
}

@end
