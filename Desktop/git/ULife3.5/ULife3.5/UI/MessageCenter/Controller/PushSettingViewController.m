//
//  PushSettingViewController.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/12.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "PushSettingViewController.h"
#import "DeviceManagement.h"
#import "PushSettingTableViewCell.h"
#import "NetSDK.h"
#import "PushDevSetingStateModel.h"
#import "SaveDataModel.h"
#import "APNSManager.h"

@interface PushSettingViewController () <
                                            UITableViewDelegate,
                                            UITableViewDataSource
                                        >

@property (weak, nonatomic) IBOutlet UITableView *pushSettingTableView;

@property (nonatomic ,strong) NSMutableArray * devPushArr;

@end

@implementation PushSettingViewController

- (NSMutableArray *)devPushArr
{
    if (_devPushArr==nil) {
        _devPushArr=[[NSMutableArray alloc]init];
    }
    return _devPushArr;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = DPLocalizedString(@"set_push");
    [self getDevPushState];
    [self configTableView];
//    [self addLeftBarButtonItem];
}


- (void)getDevPushState
{
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    NSString *uuidStr = [SYDeviceInfo identifierForVender];
    NSDictionary *postDict = @{
                               @"MessageType":@"GetDevicePushStateRequest",
                               @"Body":
                                   @{
                                       @"Terminal":@"iphone", //终端系统类型
                                       @"UserName":[SaveDataModel getUserName],//app就填账户名，dev就填ID
                                       @"Token":@"test",  //对于APP没有token的就填写mac地址，对于camera写DEVICE ID,token是唯一的
                                       @"AppId":bundleId,//APP唯一表示符号
                                       @"UUID":uuidStr //手机唯一标识
                                       }
                               };
    
    //    NSData *reqData = [NSJSONSerialization dataWithJSONObject:postDict options:0 error:nil];
    
    [[NetSDK sharedInstance] net_sendCBSRequestWithData:postDict timeout:15000 responseBlock:^(int result, NSDictionary *dict) {
        NSLog(@"开关设置状态%@",dict[@"Body"][@"DeviceList"]);
        for (NSDictionary * dic in dict[@"Body"][@"DeviceList"] ) {
            PushDevSetingStateModel * md = [[PushDevSetingStateModel alloc]initWithDict:dic];
            [self.devPushArr addObject:md];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.pushSettingTableView reloadData];
        });
    }];
    
}



- (void)dealloc
{
    NSLog(@"PushSettingViewController --- dealloc ---");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

//#pragma mark -- 添加左 item
//- (void)addLeftBarButtonItem
//{
//    UIImage *image = [UIImage imageNamed:@"addev_back"];
//    EnlargeClickButton *button = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
//    button.frame = CGRectMake(0, 0, 70, 40);
//    button.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 50);
//    [button setImage:image forState:UIControlStateNormal];
//    [button addTarget:self
//               action:@selector(backToPreView)
//     forControlEvents:UIControlEventTouchUpInside];
//    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
//    leftBarButtonItem.style = UIBarButtonItemStylePlain;
//    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
//}
//
//-(void)backToPreView
//{
//    NSLog(@"backToPreView");
//    [self.navigationController popViewControllerAnimated:YES];
//}

- (void)configTableView
{
    // 删除tableView多余分割线
    [self.pushSettingTableView setTableFooterView:[[UIView alloc]initWithFrame:CGRectZero]];
    
    self.pushSettingTableView.backgroundColor = UIColorFromRGBA(238.0f, 238.0f, 238.0f, 1.0f);
    
    [self setRowHeight];
}


#pragma mark -- 设置 cell 高度
- (void)setRowHeight
{
    self.pushSettingTableView.rowHeight = 50.0f;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    return [[DeviceManagement sharedInstance] deviceListArray].count;
     return self.devPushArr.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger rowIdex = indexPath.row;
    static NSString *pushSettingCellId = @"pushSettingCellIdentify";
    
    PushSettingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:pushSettingCellId];
    if (!cell)
    {
        NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([PushSettingTableViewCell class])
                                                          owner:self
                                                        options:nil];
        cell = nibArray[0];
        cell.accessoryType  = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
//    if (rowIdex < [[DeviceManagement sharedInstance] deviceListArray].count)
//    {
//        cell.pushSettingCellData = [[[DeviceManagement sharedInstance] deviceListArray] objectAtIndex:rowIdex];
//    }
    PushDevSetingStateModel *md = self.devPushArr[indexPath.row];
    [cell freshenWith:md];
    
    return cell;
}

@end
