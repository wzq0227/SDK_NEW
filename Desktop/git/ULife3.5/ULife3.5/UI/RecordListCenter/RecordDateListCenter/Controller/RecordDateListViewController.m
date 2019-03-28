//
//  RecordDateListViewController.m
//  goscamapp
//
//  Created by shenyuanluo on 2017/4/27.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "RecordDateListViewController.h"
#import "RecordDateListTableViewCell.h"
#import "RecordDateTableViewCellModel.h"
#import "RecordDateInfoViewController.h"
#import "RecordNoSDCardView.h"
#import "BaseCommand.h"
#import "NetSDK.h"
#import "Masonry.h"

@interface RecordDateListViewController () <
                                                UITableViewDataSource,
                                                UITableViewDelegate
                                           >

/**
 *  录像列表’日期‘ tableView
 */
@property (weak, nonatomic) IBOutlet UITableView *recordDateListTableView;

/**
 *  存放数据模型的数组
 */
@property (nonatomic, strong) NSMutableArray <RecordDateTableViewCellModel *> * recordDateTableViewDataArray;

@property(nonatomic,strong)NetSDK *netSDK;
@property(nonatomic,strong)CMD_GetRecFileOneMonthResp *getAllRecFileResp;
@property(nonatomic,strong)RecordNoSDCardView *noSDCardView;
@property(nonatomic,strong)UIView             *noSDCardViewBg;
@end

@implementation RecordDateListViewController

#pragma mark - ViewController 生命周期
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initParameter];
    
    [self configUI];
    
    [self getRecordDateTableViewData:self.recordDateTableViewDataArray];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

- (void)createDownloaFolderPath{
    
    BOOL b;
    NSString *path = [mDocumentPath stringByAppendingPathComponent:mRecordFileFolderName];
    if (![mFileManager fileExistsAtPath:path isDirectory:&b]) //判断文件夹是否存在，不存在，创建
    {
        if(![mFileManager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil])
        {
            return ;
        }else{
            NSLog(@"__________________________failed_createDirectoryAtPath:%@",path);
        }
    }
    else	//
    {
        NSLog(@"____________________________________downloadFolder_already_exist________");
    }

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if ([SVProgressHUD isVisible]) {
        [SVProgressHUD dismiss];
    }
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
    NSLog(@"录像日期列表页面 - dealloc");
}



#pragma mark - 初始化设置相关
#pragma mark -- 初始化参数
- (void)initParameter
{
    [self createDownloaFolderPath];
}


#pragma mark -- 设置相关 UI
- (void)configUI
{
//    self.title = DPLocalizedString(@"Record_Playback") ;
    [self addBackBtn];
    [self configTitleWithStr:DPLocalizedString(@"Record_Playback")];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.recordDateListTableView.tableFooterView = [[UIView alloc] init];
    
    self.recordDateListTableView.rowHeight = 44.0f;
    if ([UIDevice currentDevice].isPad)
    {
        self.recordDateListTableView.rowHeight = 60.0f;
    }
}
-(void)addBackBtn
{
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(-10, 0, 20, 20);
    [backButton setImage:[UIImage imageNamed:@"PlayWhiteBack"] forState:UIControlStateNormal];

    [backButton addTarget:self action:@selector(backToPreView) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    temporaryBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.leftBarButtonItem = temporaryBarButtonItem;
}
-(void)backToPreView
{
    NSLog(@"backToPreView");
    [self.navigationController popViewControllerAnimated:YES];
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
    [self getRecordFileList];
}

- (void)getRecordFileList{
    
    _netSDK = [NetSDK sharedInstance];
    __weak typeof(self) weakSelf = self;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [SVProgressHUD showWithStatus:@"Loading..."];
    });
    
    NSDictionary *reqData = [[CMD_GetRecFileOneMonthReq new] requestCMDData];
    
    [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:reqData timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            weakSelf.getAllRecFileResp = [CMD_GetRecFileOneMonthResp yy_modelWithDictionary:dict];
            [weakSelf refreshRecordFileList];
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                [weakSelf.recordDateListTableView reloadData];
            });
        }else{
            [weakSelf showErrorInfoWithResult:result];
        }

    }];
}

- (void)refreshRecordFileList{
    
    NSArray *tempArray = [_getAllRecFileResp.page_data componentsSeparatedByString:@"|"];
    NSArray *dateArray = [tempArray sortedArrayUsingComparator:^NSComparisonResult(NSString*  _Nonnull obj1, NSString*  _Nonnull obj2) {
        return [obj1 longLongValue] < [obj2 longLongValue];
    }];
    NSMutableArray *listArray = [NSMutableArray arrayWithCapacity:0];
    for (NSString *fileName in dateArray) {
        if (fileName.length>=8) {
            RecordDateTableViewCellModel*model = [RecordDateTableViewCellModel new];
            model.recordDateStr = [NSString stringWithFormat:@"%@/%@/%@",[fileName substringToIndex:4],[fileName substringWithRange:NSMakeRange(4, 2)],[fileName substringWithRange:NSMakeRange(6, 2)]];
            int ret =[[fileName substringWithRange:NSMakeRange(8, 4)] intValue];
            
            NSLog(@"文件数量 %d",ret);
            
            if (ret!=0) {
                [listArray addObject:model];

            }
        }
    }
    if (listArray.count >0) {
        [_recordDateTableViewDataArray addObjectsFromArray:listArray];
    }
}

- (void)showErrorInfoWithResult:(int)result {
    
    if (result == 3){//无卡
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            [self configureForNoSDCardView];
            [self addNoSDCardViewIntoKeyWindow];
        });
    }
    else if(result == 2){
        [self dismissLoadingAnimationAndShowErrorMsg:DPLocalizedString(@"Record_NoRecordFile")];
    }
    else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showErrorWithStatus: DPLocalizedString(@"Get_data_failed")];
        });
    }
}

- (void)dismissLoadingAnimationAndShowErrorMsg:(NSString*)msg{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showSuccessWithStatus:msg];
    });
}

- (void)okBtnClicked:(id)sender{
    [self removeNoSDCardViewFromKeywindow];
}

- (void)removeNoSDCardViewFromKeywindow{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_noSDCardView removeFromSuperview];
        [_noSDCardViewBg removeFromSuperview];
        
        [self.navigationController popViewControllerAnimated:YES];
    });
}


#pragma mark = NoSDCard

- (void)configureForNoSDCardView {
    
    _noSDCardView = [[[NSBundle mainBundle] loadNibNamed:@"RecordNoSDCardView" owner:self options:nil] objectAtIndex:0];
    _noSDCardView.layer.cornerRadius = 10;

    _noSDCardView.noSDCardTitle.text = DPLocalizedString(@"NoSDCard_Tips_Title");
    _noSDCardView.sdCardAutoDetect.text = DPLocalizedString(@"NoSDCard_Tips_InsertSDCardAutoRecording");
    _noSDCardView.sdCardSupportedType.text = DPLocalizedString(@"NoSDCard_Tips_MaxStorageSupport");
    _noSDCardView.sdCardUnrecognized.text = DPLocalizedString(@"NoSDCard_Tips_SDCardUnrecognized");
    _noSDCardView.sdCardFAT32.text = DPLocalizedString(@"NoSDCard_Tips_SDCardFormat");

    _noSDCardViewBg = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    _noSDCardViewBg.backgroundColor = [UIColor blackColor];
    _noSDCardViewBg.alpha = 0.5;
}

- (void)addNoSDCardViewIntoKeyWindow{
    
    if (!_noSDCardView.superview) {
        [[UIApplication sharedApplication].keyWindow addSubview:_noSDCardViewBg];
        [[UIApplication sharedApplication].keyWindow addSubview: _noSDCardView];
        [_noSDCardView.okBtn setTitle:DPLocalizedString(@"camera_check_time_ok") forState:0];
        [_noSDCardView.okBtn addTarget:self action:@selector(okBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_noSDCardView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_noSDCardViewBg);
            make.leading.equalTo(_noSDCardViewBg).offset(10);
            make.width.equalTo(_noSDCardView.mas_height).multipliedBy(300/420.0);
        }];
    }
}


#pragma mark - 懒加载
#pragma mark -- 数据源模型数组
- (NSMutableArray<RecordDateTableViewCellModel *> *)recordDateTableViewDataArray
{
    if (!_recordDateTableViewDataArray)
    {
        _recordDateTableViewDataArray = [[NSMutableArray alloc] initWithCapacity:0];
    }
    
    return _recordDateTableViewDataArray;
}


#pragma mark - Table View Delegate and DataSource
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return self.recordDateTableViewDataArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (0 >= self.recordDateTableViewDataArray.count)
    {
        return nil;
    }
    static NSString *recordDateCellId = @"recordDateCellIdentify";
    NSInteger rowIndex = indexPath.row;
    
    RecordDateListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:recordDateCellId];
    if (!cell)
    {
        NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"RecordDateListTableViewCell"
                                                          owner:self
                                                        options:nil];
        cell = nibArray[0];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (self.recordDateTableViewDataArray.count > rowIndex)
    {
        cell.recordDateTableViewCellData = [self.recordDateTableViewDataArray objectAtIndex:rowIndex];
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger rowIndex = indexPath.row;
    if (self.recordDateTableViewDataArray.count <= rowIndex)
    {
        return ;
    }
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
    RecordDateInfoViewController *dateInfoVC = [[RecordDateInfoViewController alloc] init];
    if (dateInfoVC)
    {
        dateInfoVC.deviceId      = _model.DeviceId;
        dateInfoVC.recordDateStr = [self.recordDateTableViewDataArray objectAtIndex:rowIndex].recordDateStr;
        [self.navigationController pushViewController:dateInfoVC
                                             animated:YES];
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
