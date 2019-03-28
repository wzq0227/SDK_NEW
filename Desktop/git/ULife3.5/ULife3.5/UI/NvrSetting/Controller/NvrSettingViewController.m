//
//  NvrSettingViewController.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/23.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "NvrSettingViewController.h"
#import "NvrSettingDataModel.h"
#import "nvrSettingTableViewCell.h"
#import "ShareWithFriendsViewController.h"
#import "CBSCommand.h"
#import "SaveDataModel.h"
#import "NetSDK.h"
#import "NvrInfoViewController.h"
#import "NetAPISet.h"

/** NVR 设置 TableView 高度 */
#define NVR_SETTING_TB_CELL_HEIGHT 44.0f

/** NVR 设置 TableView 项数（行数）*/
#define NVR_SETTING_TB_ROW_NUM 2

@interface NvrSettingViewController ()  <
                                            UITableViewDataSource,
                                            UITableViewDelegate
                                        >
/** NVR 设置信息 TableView */
@property (weak, nonatomic) IBOutlet UITableView *nvrSettingTableView;

/** NVR 删除设备 Button */
@property (weak, nonatomic) IBOutlet UIButton *nvrDeleteDevBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewHeightConstraint;

/** 设备数据 model */
@property (nonatomic, strong) DeviceDataModel *devDataModel;

/** TUTK 平台 ID （长度：20）*/
@property (nonatomic, copy) NSString *tutkDevId;

/** 3.5 平台 ID （长度：28）*/
@property (nonatomic, copy) NSString *platformDevId;

/** NVR 设置 TableView 数据源  */
@property (nonatomic, strong) NSMutableArray <NvrSettingDataModel *>*nvrSettingDataArray;

@end

@implementation NvrSettingViewController


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
    
    self.navigationItem.title = DPLocalizedString(@"Setting_Setting");
    self.view.backgroundColor = [UIColor colorWithRed:238.0f/255.0f
                                                green:238.0f/255.0f
                                                 blue:238.0f/255.0f
                                                alpha:1.0f];
    [self configTableView];
    
    [self initSettingData];
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
    NSLog(@"----------- NvrSettingViewController dealloc -----------");
}


#pragma mark -- 设置 TableView 
- (void)configTableView
{
    self.automaticallyAdjustsScrollViewInsets = YES;
    self.navigationController.navigationBar.translucent = NO;
    self.nvrSettingTableView.scrollEnabled    = NO;
    self.nvrSettingTableView.rowHeight        = NVR_SETTING_TB_CELL_HEIGHT;
    if (GosDeviceShare == self.devDataModel.DeviceOwner)
    {
        self.tableViewHeightConstraint.constant = (NVR_SETTING_TB_ROW_NUM - 1) * 44.0f;
    }
    
    [self.nvrDeleteDevBtn setTitle:DPLocalizedString(@"Setting_DeleteDevice")
                          forState:UIControlStateNormal];
}


#pragma mark -- 初始化数据
- (void)initSettingData
{
    if (!_nvrSettingDataArray)
    {
        _nvrSettingDataArray = [NSMutableArray arrayWithCapacity:NVR_SETTING_TB_ROW_NUM];
    }
    for (int i = 0; i < NVR_SETTING_TB_ROW_NUM; i++)
    {
        NvrSettingDataModel *dataModel = [[NvrSettingDataModel alloc] init];
        if (0 == i)     // 设备信息
        {
            dataModel.cellStyle = NvrSettingCellDevInfo;
            dataModel.cellContent = DPLocalizedString(@"Setting_DeviceInfo");
            [self.nvrSettingDataArray addObject:dataModel];
        }
        else if (1 == i
                 && GosDeviceOwner == self.devDataModel.DeviceOwner)    // 分享二维码
        {
            dataModel.cellStyle = NvrSettingCellShareQr;
            dataModel.cellContent = DPLocalizedString(@"Setting_ShareWithFriends");
            [self.nvrSettingDataArray addObject:dataModel];
        }
    }
}

- (IBAction)nvrDeleteDevBtnAction:(id)sender
{
    NSLog(@"删除 NVR 设备 ！");
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showWithStatus:@"Loading..."];
    });
    
    BodyUnbindRequest *body = [BodyUnbindRequest new];
    CBS_UnbindRequest *req  = [CBS_UnbindRequest new];
    body.DeviceId           = self.devDataModel.DeviceId;
    body.UserName           = [SaveDataModel getUserName];
    body.DeviceOwner        = self.devDataModel.DeviceOwner;
    req.Body = body;
    
    __weak typeof(self) weakSelf = self;
    [[NetSDK sharedInstance] net_sendCBSRequestMsgType:req.MessageType
                                              bodyData:[body yy_modelToJSONObject]
                                               timeout:12000
                                         responseBlock:^(int result, NSDictionary *dict) {
                                             
                                             if (0 != result)
                                             {
                                                 NSLog(@"解绑 NVR 设备失败！");
                                                 [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
                                                 return ;
                                             }
                                             NSLog(@"解绑 NVR 设备成功！");
                                             __strong typeof(weakSelf)strongSelf = weakSelf;
                                             if (!strongSelf)
                                             {
                                                 NSLog(@"对象丢失，解绑 NVR 设备 !");
                                                 return;
                                             }
                                             [strongSelf handleUnbingSuccess];
                                         }];
}


#pragma mark -- 解绑成功处理
- (void)handleUnbingSuccess
{
    [[NetAPISet sharedInstance] nvrDeleteWithDeviceId:self.tutkDevId
                                         avChannelNum:self.devDataModel.avChnnelNum];
     __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，解绑 NVR 设备 !");
            return;
        }
        [SVProgressHUD dismiss];
        [strongSelf.navigationController popToRootViewControllerAnimated:YES];
        [[NSNotificationCenter defaultCenter]postNotificationName:REFRESH_DEV_LIST_NOTIFY
                                                           object:nil];
    });
}


#pragma mark -- TableView delegate & datasource
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    if (!self.nvrSettingDataArray)
    {
        return 0;
    }
    else
    {
        return self.nvrSettingDataArray.count;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *nvrSettingCellId = @"NVRSettingCellId";
    NSInteger rowIndex = indexPath.row;
    nvrSettingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nvrSettingCellId];
    if (!cell)
    {
        NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"nvrSettingTableViewCell"
                                                          owner:self
                                                        options:nil];
        cell = nibArray[0];
    }
    cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
    if (self.nvrSettingDataArray.count > rowIndex)
    {
        cell.nvrSettingCellData = [self.nvrSettingDataArray objectAtIndex:rowIndex];
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.nvrSettingDataArray.count > indexPath.row)
    {
        NvrSettingDataModel *dataModel = [self.nvrSettingDataArray objectAtIndex:indexPath.row];
        if (!dataModel)
        {
            return;
        }
        [self handleSelectedCellOnStyle:dataModel.cellStyle];
    }
}


#pragma mark - nvrSettingTableViewCellDelegate
- (void)handleSelectedCellOnStyle:(NvrSettingCellStyle)cellStyle
{
    switch (cellStyle)
    {
        case NvrSettingCellDevInfo:     // 设备信息
        {
            NvrInfoViewController *nvrInfoVC = [[NvrInfoViewController alloc] initWithDevDataModel:self.devDataModel];
            if (nvrInfoVC)
            {
                [self.navigationController pushViewController:nvrInfoVC
                                                     animated:YES];
            }
        }
            break;
            
        case NvrSettingCellShareQr:     // 二维码分享
        {
            ShareWithFriendsViewController *shareQrVC = [[ShareWithFriendsViewController alloc] init];
            shareQrVC.model = self.devDataModel;
            if (shareQrVC)
            {
                [self.navigationController pushViewController:shareQrVC
                                                     animated:YES];
            }
        }
            break;
            
        default:
            break;
    }
}

@end
