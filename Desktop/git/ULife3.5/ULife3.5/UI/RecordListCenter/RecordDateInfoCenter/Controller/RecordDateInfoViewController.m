//
//  RecordDateInfoViewController.m
//  goscamapp
//
//  Created by shenyuanluo on 2017/4/28.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "RecordDateInfoViewController.h"
#import "RecordDateInfoTableViewCell.h"
#import "RecordDateInfoTableViewCellModel.h"
#import "RecordImgListViewController.h"
#import "RecordVideoListViewController.h"

@interface RecordDateInfoViewController () <
                                                UITableViewDataSource,
                                                UITableViewDelegate
                                           >

/**
 *  录像列表’日期内容‘ tableView
 */
@property (weak, nonatomic) IBOutlet UITableView *recordDateInfoTableView;

/**
 *  存放数据模型的数组
 */
@property (nonatomic, strong) NSMutableArray <RecordDateInfoTableViewCellModel *> * recordDateInfoTableViewDataArray;
@end

@implementation RecordDateInfoViewController

#pragma mark - ViewController 生命周期
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initParameter];
    
    [self configUI];
    
    [self getRecordDateTableViewData:self.recordDateInfoTableViewDataArray];
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
    NSLog(@"录像日期内容页面 - dealloc");
}



#pragma mark - 初始化设置相关
#pragma mark -- 初始化参数
- (void)initParameter
{
    
}


#pragma mark -- 设置相关 UI
- (void)configUI
{
//    self.title = self.recordDateStr;
    [self configTitleWithStr:self.recordDateStr];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.recordDateInfoTableView.tableFooterView = [[UIView alloc] init];
    
    self.recordDateInfoTableView.rowHeight = 44.0f;
    if ([UIDevice currentDevice].isPad)
    {
        self.recordDateInfoTableView.rowHeight = 60.0f;
    }
}

- (void)configTitleWithStr:(NSString*)titleStr{
    CGSize titleSize =self.navigationController.navigationBar.bounds.size;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, titleSize.width/2,titleSize.height)];
    label.backgroundColor = [UIColor clearColor];
    label.font =  [UIFont boldSystemFontOfSize:18];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.text= titleStr;
    self.navigationItem.titleView = label;
}


#pragma mark -- 请求获取录像日期列表数据
- (void)getRecordDateTableViewData:(NSMutableArray *)dataArray
{
    if (!dataArray)
    {
        ULifeLog(@"录像日期列表数组不存在，无法获取相关数据");
        return;
    }
    
//    RecordDateInfoTableViewCellModel *tempModel = [[RecordDateInfoTableViewCellModel alloc] init];
//    tempModel.recordDateInfoStr = DPLocalizedString(@"Record_FileType_Picture");
//    [dataArray addObject:tempModel];
    
    RecordDateInfoTableViewCellModel *tempModel2 = [[RecordDateInfoTableViewCellModel alloc] init];
    tempModel2.recordDateInfoStr = DPLocalizedString(@"Record_FileType_Video");
    [dataArray addObject:tempModel2];
}


#pragma mark - 懒加载
#pragma mark -- 数据源模型数组
- (NSMutableArray<RecordDateInfoTableViewCellModel *> *)recordDateInfoTableViewDataArray
{
    if (!_recordDateInfoTableViewDataArray)
    {
        _recordDateInfoTableViewDataArray = [[NSMutableArray alloc] initWithCapacity:0];
    }
    
    return _recordDateInfoTableViewDataArray;
}


#pragma mark - Table View Delegate and DataSource
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return self.recordDateInfoTableViewDataArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (0 >= self.recordDateInfoTableViewDataArray.count)
    {
        return nil;
    }
    static NSString *recordDateInfoCellId = @"recordDateInfoCellIdentify";
    NSInteger rowIndex = indexPath.row;
    
    RecordDateInfoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:recordDateInfoCellId];
    if (!cell)
    {
        NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"RecordDateInfoTableViewCell"
                                                          owner:self
                                                        options:nil];
        cell = nibArray[0];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (self.recordDateInfoTableViewDataArray.count > rowIndex)
    {
        cell.recordDateInfoTableViewCellData = [self.recordDateInfoTableViewDataArray objectAtIndex:rowIndex];
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger rowIndex = indexPath.row;
    if (self.recordDateInfoTableViewDataArray.count <= rowIndex)
    {
        return ;
    }
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
//    if (0 == rowIndex)
//    {
//        RecordImgListViewController *recordImgVC = [[RecordImgListViewController alloc] init];
//        if (recordImgVC)
//        {
//            recordImgVC.deviceId      = self.deviceId;
//            recordImgVC.recordDateStr = self.recordDateStr;
//            [self.navigationController pushViewController:recordImgVC
//                                                 animated:YES];
//        }
//
//    }
//    else
    if (0 == rowIndex)
    {
        RecordVideoListViewController *recordVideoVC = [[RecordVideoListViewController alloc] init];
        if (recordVideoVC)
        {
            recordVideoVC.deviceId      = self.deviceId;
            recordVideoVC.recordDateStr = self.recordDateStr;
            [self.navigationController pushViewController:recordVideoVC
                                                 animated:YES];
        }
    }
}


#pragma mark - 横竖屏切换相关
#pragma mark -- 是否允许横竖屏
-(BOOL)shouldAutorotate
{
    return NO;
}


#pragma mark -- 横竖屏方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
