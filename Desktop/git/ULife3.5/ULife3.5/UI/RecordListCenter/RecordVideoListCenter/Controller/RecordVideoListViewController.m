//
//  RecordVideoListViewController.m
//  goscamapp
//
//  Created by shenyuanluo on 2017/4/28.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "RecordVideoListViewController.h"
#import "RecordVideoTableViewCellModel.h"
#import "RecordVideoTableViewCell.h"
#import "RecordVideoPlayViewController.h"
#import "NetSDK.h"
#import "NetAPISet.h"
#import "BaseCommand.h"
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>

#import "CNPPopupController.h"
#import "ASProgressPopUpView.h"
#import "MJRefresh.h"
#import "Masonry.h"
#import "ACVideoDecoder.h"
#import "DeviceDataModel.h"

#define SECTION_HEIGHT 17.0f

#define CELL_HEIGHT 50.0f
#define SELECT_ALL_BUTTON_WIDTH 120.0f
#define DELETE_BUTTON_WIDTH 120.0f
#define BUTTON_MARGIN 20.0f

#define BOTTOM_VIEW_ANIMATION_DURATION 0.25f

static NSString *const ConvertMP4Notification = @"ConvertMP4Notification";


@interface RecordVideoListViewController ()<CNPPopupControllerDelegate>

/**
 *  录像'视频列表' tableView
 */
@property (weak, nonatomic) IBOutlet UITableView *recordVideoTableView;

/**
 *  存放数据模型的数组
 */
@property (nonatomic, strong) NSMutableArray <RecordVideoTableViewCellModel *> * recordVideoTableViewDataArray;

@property (nonatomic, strong) CNPPopupController *popupController;
@property (nonatomic, strong)ASProgressPopUpView *progressView;
@property (nonatomic, strong)CNPPopupButton *button;

@property(nonatomic,strong)UILabel *titleLabel;
@property(nonatomic,strong)UIImageView *imageView;
@property(nonatomic,strong)UILabel *FiletitleLabel;
@property(nonatomic,strong)NSString *curDownloadingFilePath;
@property(nonatomic,assign)int  selectedIndex;

@property (nonatomic,strong) NSIndexPath              *clickedIndexPathInDownloading;
@property (nonatomic,strong) ACCaptureVideoDecoder    *videoDecoder;
@property (nonatomic,strong) NetAPISet                *network;
@property (nonatomic,strong) NetSDK                   *netSDK;
@property (nonatomic,strong) CMD_GetRecFileOneDayResp *getOneDayRecFileResp;
@property (nonatomic,strong) CMD_GetRecFileOneDayReq  *getOneDayRecFileReq;
@property (nonatomic,strong) CMD_DeleteRecordFileReq  *deleteRecFileCmd;

@property(nonatomic,copy)UIActivityIndicatorView *activityViewIndicator;
@property(nonatomic,copy)UITableViewCell *activityCell;
@property(nonatomic,copy)UILabel *noMoreDataLabel;
@property(nonatomic,strong)UIView *OpRecordFileView;

@property(nonatomic,assign)BOOL isEditing;
@property(nonatomic,assign)BOOL selectedAll;
@property(nonatomic,assign)BOOL hasMoreDataFlag;
/**
 *  编辑删除 view
 */
@property (nonatomic, strong) UIView *bottomDeleteView;

/**
 *  '编辑/取消' 按钮
 */
@property (nonatomic, strong) UIButton *rightBarButton;

/**
 *  '全选/反全选' 按钮
 */
@property (nonatomic, strong) UIButton *selectAllButton;

/**
 *  '删除' 按钮
 */
@property (nonatomic, strong) UIButton *deleteButton;

@end

@implementation RecordVideoListViewController

{
    BOOL isSectect;
}

#pragma mark - ViewController 生命周期
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initParameter];
    
    [self configUI];
    
    [self addEvents];
    
    [self getRecordVideoTableViewData:self.recordVideoTableViewDataArray];
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
    NSLog(@"录像视频列表页面 - dealloc");
}



#pragma mark - 初始化设置相关
#pragma mark -- 初始化参数
- (void)initParameter
{
    _netSDK = [NetSDK sharedInstance];
    _network = [NetAPISet sharedInstance];
    
    self.recordVideoTableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self
                                                                           refreshingAction:@selector(pulldownToRefresh:)];
    self.recordVideoTableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingTarget:self
                                                                           refreshingAction:@selector(pullupToLoadMore:)];
}

- (void)addEvents{
    
    _videoDecoder = [[ACCaptureVideoDecoder alloc] init];
    
    //添加裁剪完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSuccess:) name:ConvertMP4Notification object:nil];
}

- (void)captureSuccess:(NSNotification *)notify{
    NSDictionary *dict = notify.userInfo;
    NSNumber *number = dict[@"result"];
    
    if (number.intValue == 1) {
        NSLog(@" 裁剪视频成功 ");
    }else{
        NSLog(@" 裁剪视频失败 ");
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.recordVideoTableView reloadRowsAtIndexPaths:@[_clickedIndexPathInDownloading] withRowAnimation:UITableViewRowAnimationLeft];
        [self.popupController dismissPopupControllerAnimated:YES];
    });
}

- (void)pulldownToRefresh:(id)sender{
    
    if (_isEditing) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showInfoWithStatus:DPLocalizedString(@"please_quit_editing")];
            [self.recordVideoTableView.mj_header endRefreshing];
        });
        return;
    }
    RecordVideoTableViewCellModel *model = self.recordVideoTableViewDataArray.firstObject;
    NSString *filename = model.recordVideoFileNameStr;
    
    _getOneDayRecFileReq.filename = filename;
    _getOneDayRecFileReq.page_num = 1;
    _getOneDayRecFileReq.direction = 0;
    _getOneDayRecFileReq.file_type = 0;
    _getOneDayRecFileReq.a_day = [_recordDateStr stringByReplacingOccurrencesOfString:@"/" withString:@""];
    
    __weak typeof(self) weakSelf = self;
    NSDictionary *reqData2 = [_getOneDayRecFileReq requestCMDData];
    [_netSDK net_sendBypassRequestWithUID:_deviceId requestData:reqData2 timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            weakSelf.getOneDayRecFileResp = [CMD_GetRecFileOneDayResp yy_modelWithDictionary:dict];
            [weakSelf refreshRecordFileListByInsertingFiles:YES];
        }
        else if ( result == 2){
            NSLog(@"pulldownTo________________loadData____________: NoData");
        }else{
            NSLog(@"loadMoreData_____result________:%d",result);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.recordVideoTableView.mj_header endRefreshing];
        });
    }];

}

- (void)pullupToLoadMore:(id)sender{
    if (_isEditing) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_recordVideoTableView.mj_footer endRefreshing];
            [SVProgressHUD showInfoWithStatus:DPLocalizedString(@"please_quit_editing")];
        });
        return;
    }
    
    RecordVideoTableViewCellModel *model = self.recordVideoTableViewDataArray.lastObject;
    NSString *filename = model.recordVideoFileNameStr;
    
    _getOneDayRecFileReq.filename = filename;
    _getOneDayRecFileReq.page_num = self.recordVideoTableViewDataArray.count>0 ? 1 :0;
    _getOneDayRecFileReq.direction = 1;
    _getOneDayRecFileReq.file_type = 0;
    _getOneDayRecFileReq.a_day = [_recordDateStr stringByReplacingOccurrencesOfString:@"/" withString:@""];
    
    __weak typeof(self) weakSelf = self;
    NSDictionary *reqData2 = [_getOneDayRecFileReq requestCMDData];
    [_netSDK net_sendBypassRequestWithUID:_deviceId requestData:reqData2 timeout:10000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            weakSelf.getOneDayRecFileResp = [CMD_GetRecFileOneDayResp yy_modelWithDictionary:dict];
            [weakSelf refreshRecordFileListByInsertingFiles:NO];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_recordVideoTableView.mj_footer endRefreshing];
            });
        }
        else if ( result == 2){
            _hasMoreDataFlag = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                [_recordVideoTableView.mj_footer endRefreshingWithNoMoreData];
            });
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [_recordVideoTableView.mj_footer endRefreshing];
            });
            NSLog(@"loadMoreData_____result________:%d",result);
        }
    }];

}

#pragma mark -- 设置相关 UI
- (void)configUI
{
//    self.title = DPLocalizedString(@"Video");
    [self configTitleWithStr:DPLocalizedString(@"Record_FileType_Video")];

    self.automaticallyAdjustsScrollViewInsets = NO;
    self.recordVideoTableView.tableFooterView = [[UIView alloc] init];
    
    [self.recordVideoTableView registerClass:[RecordVideoTableViewCell class ] forCellReuseIdentifier:@"cell"];
    
    self.recordVideoTableView.rowHeight = 80.0f;
    if ([UIDevice currentDevice].isPad)
    {
        self.recordVideoTableView.rowHeight = 100.0f;
    }
    self.recordVideoTableView.allowsMultipleSelectionDuringEditing = YES;
    
    [self configNavigationItem];
    [self addBottomDeleteView];
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

#pragma mark <Delete>删除
- (void)configNavigationItem{
    //
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.rightBarButton];
    
    [self configNavLeftBar];
}

- (void)configNavLeftBar{
    
    UIImage *image = [UIImage imageNamed:@"addev_back"];
    EnlargeClickButton *button = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 70, 40);
    button.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 50);
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self
               action:@selector(navBack)
     forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    leftBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
    
}


- (void)navBack{
    
    [self.videoDecoder ac_uninit];
    self.videoDecoder = nil;
    [self removeCacheFile];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.navigationController popViewControllerAnimated:YES];
}

//清除cache文件夹中的缓存
- (void)removeCacheFile{
    NSString *extension1 = @"H264";
    NSString *extension2 = @"jpg";
    NSString *extension3 = @"mp4";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];
    NSEnumerator *enumerator = [contents objectEnumerator];
    NSString *filename;
    while ((filename = [enumerator nextObject])) {
        if ([[filename pathExtension] isEqualToString:extension1]
            || [[filename pathExtension] isEqualToString:extension2]
            || [[filename pathExtension] isEqualToString:extension3]) {
            [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:filename] error:nil];
        }
    }
}

#pragma mark -- 添加底部删除操作 view
- (void)addBottomDeleteView
{
    [self.bottomDeleteView addSubview:self.selectAllButton];
    [self.bottomDeleteView addSubview:self.deleteButton];
    [self.view addSubview:self.bottomDeleteView];
    
    __weak typeof(self)weakSelf = self;
    [self.bottomDeleteView mas_updateConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        make.height.mas_equalTo(CELL_HEIGHT);
        make.left.equalTo(strongSelf.view.mas_left);
        make.right.equalTo(strongSelf.view.mas_right);
        make.bottom.equalTo(strongSelf.view.mas_bottom).offset(CELL_HEIGHT);
    }];
    
    [self.selectAllButton mas_updateConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        
        make.left.equalTo(strongSelf.bottomDeleteView.mas_left).offset(BUTTON_MARGIN);
        make.top.equalTo(strongSelf.bottomDeleteView.mas_top);
        make.bottom.equalTo(strongSelf.bottomDeleteView.mas_bottom);
        make.width.mas_equalTo(SELECT_ALL_BUTTON_WIDTH);
    }];
    
    [self.deleteButton mas_updateConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        
        make.right.equalTo(strongSelf.bottomDeleteView.mas_right).offset(-BUTTON_MARGIN);
        make.top.equalTo(strongSelf.bottomDeleteView.mas_top);
        make.bottom.equalTo(strongSelf.bottomDeleteView.mas_bottom);
        make.width.mas_equalTo(DELETE_BUTTON_WIDTH);
    }];
}

#pragma mark - 懒加载
- (UIView *)bottomDeleteView
{
    if (!_bottomDeleteView)
    {
        _bottomDeleteView = [[UIView alloc] init];
        _bottomDeleteView.backgroundColor = UIColorFromRGBA(220.0f, 220.0f, 220.0f, 1.0f);
    }
    return _bottomDeleteView;
}

#pragma mark -- ’编辑/取消‘按钮事件
- (void)rightBarButtonAction
{
    _isEditing = !_isEditing;

    for (int i =0; i<self.recordVideoTableViewDataArray.count; i++) {
        RecordVideoTableViewCellModel *md =self.recordVideoTableViewDataArray[i];
        md.isSelect=NO;
        [self.recordVideoTableViewDataArray replaceObjectAtIndex:i withObject:md];
    }
    [self.recordVideoTableView reloadData];
    [self showBottomDeleteView:_isEditing];
    
    [self changeRightBarTitle:_isEditing];
    
}

#pragma mark -- 显示/隐藏 删除操作 view
- (void)showBottomDeleteView:(BOOL)isShow
{
    __weak typeof(self)weakSelf = self;
    if (NO == isShow)   // 隐藏
    {
        [self.bottomDeleteView mas_updateConstraints:^(MASConstraintMaker *make) {
            
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                return ;
            }
            make.bottom.equalTo(strongSelf.view.mas_bottom).offset(CELL_HEIGHT);
        }];
        
        
        
        // 更新约束
        [UIView animateWithDuration:BOTTOM_VIEW_ANIMATION_DURATION
                         animations:^{
                             
                             __strong typeof(weakSelf)strongSelf = weakSelf;
                             if (!strongSelf)
                             {
                                 return ;
                             }
                             [strongSelf.view layoutIfNeeded];
                         }];
    }
    else    // 显示
    {
        [self.bottomDeleteView mas_updateConstraints:^(MASConstraintMaker *make) {
            
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                return ;
            }
            make.bottom.equalTo(strongSelf.view.mas_bottom).offset(0);
        }];
        
        
        // 更新约束
        [UIView animateWithDuration:BOTTOM_VIEW_ANIMATION_DURATION
                         animations:^{
                             
                             __strong typeof(weakSelf)strongSelf = weakSelf;
                             if (!strongSelf)
                             {
                                 return ;
                             }
                             [strongSelf.view layoutIfNeeded];
                         }];
    }
}


- (UIButton *)rightBarButton
{
    if (!_rightBarButton)
    {
        _rightBarButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _rightBarButton.frame = CGRectMake(0.0, 0.0, 75, 40);
        [_rightBarButton setTitle:DPLocalizedString(@"editor")
                         forState:UIControlStateNormal];
        _rightBarButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        [_rightBarButton addTarget:self
                            action:@selector(rightBarButtonAction)
                  forControlEvents:UIControlEventTouchUpInside];
    }
    return _rightBarButton;
}

- (UIButton *)selectAllButton
{
    if (!_selectAllButton)
    {
        _selectAllButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_selectAllButton setTitle:DPLocalizedString(@"select_all")
                          forState:UIControlStateNormal];
        [_selectAllButton setTitleColor:[UIColor blackColor]
                               forState:UIControlStateNormal];
         _selectAllButton.titleLabel.font = [UIFont systemFontOfSize:10];
        _selectAllButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_selectAllButton addTarget:self
                             action:@selector(selectAllButtonAction)
                   forControlEvents:UIControlEventTouchUpInside];
    }
    return _selectAllButton;
}


- (UIButton *)deleteButton
{
    if (!_deleteButton)
    {
        _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_deleteButton setTitle:DPLocalizedString(@"Title_Delete")
                       forState:UIControlStateNormal];
        [_deleteButton setTitleColor:[UIColor blackColor]
                            forState:UIControlStateNormal];
         _deleteButton.titleLabel.font = [UIFont systemFontOfSize:10];
        _deleteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        [_deleteButton addTarget:self
                          action:@selector(deleteButtonAction)
                forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteButton;
}

#pragma mark -- ’全选/取消全选‘按钮事件
- (void)selectAllButtonAction
{
    _selectedAll = !_selectedAll;
    if (_selectedAll) {
        isSectect=YES;
        for (RecordVideoTableViewCellModel *model in self.recordVideoTableViewDataArray) {
            model.isSelect = YES;
        }
        
        [self.recordVideoTableView reloadData];

    }else{
        for (RecordVideoTableViewCellModel *model in self.recordVideoTableViewDataArray) {
            model.isSelect = NO;
        }
        [self.recordVideoTableView reloadData];
    }
    NSLog(@"’全选/取消全选‘按钮事件");
}


#pragma mark -- ’删除‘按钮事件
- (void)deleteButtonAction
{
    
//    NSArray *selectedIndexPaths = [self.recordVideoTableView indexPathsForSelectedRows];
    NSMutableArray <NSDictionary*>*deletedFilesArr = [NSMutableArray arrayWithCapacity:1];
    
    for (RecordVideoTableViewCellModel *model in self.recordVideoTableViewDataArray) {
        if (model.isSelect) {
            [deletedFilesArr addObject:@{@"a_file_name": model.recordVideoFileNameStr}];
        }
    }
    
    if (deletedFilesArr.count <= 0) {
        return;
    }
//    for (NSIndexPath *index in selectedIndexPaths) {
//        RecordVideoTableViewCellModel *model = _recordVideoTableViewDataArray[index.row];
//        
//        [deletedFilesArr addObject:@{@"a_file_name": model.recordVideoFileNameStr}];
//    }
    
//    BOOL deleteAllFlag = selectedIndexPaths.count == _recordVideoTableViewDataArray.count;
    CMD_DeleteRecordFileReq *req = [CMD_DeleteRecordFileReq new];
    req.file_name_list = deletedFilesArr;

    NSDictionary *reqData = [req requestCMDData];
    [SVProgressHUD showWithStatus:@"Loading...."];
    __weak typeof(self) weakSelf = self;
    
    [_netSDK net_sendBypassRequestWithUID:_deviceId requestData:reqData timeout:25000 responseBlock:^(int result, NSDictionary *dict) {
        
        NSString *str = [NSString stringWithFormat:@"%@",DPLocalizedString(result==0?@"delete_file_success":@"delete_file_unsuccess")];
        
        if (result == 0) {
            
            for (NSInteger i= deletedFilesArr.count-1; i>=0; i--) {
                for (NSInteger j=weakSelf.recordVideoTableViewDataArray.count-1; j>=0; j-- ) {
                    RecordVideoTableViewCellModel *model = weakSelf.recordVideoTableViewDataArray[j];
                    if ([deletedFilesArr[i][@"a_file_name"] isEqualToString:model.recordVideoFileNameStr] ) {
                        NSString *filePath = [[mDocumentPath stringByAppendingPathComponent:mRecordFileFolderName]stringByAppendingPathComponent:model.recordVideoFileNameStr];
                        if ([[NSFileManager defaultManager] fileExistsAtPath: filePath]){
                            [[NSFileManager defaultManager] removeItemAtPath: filePath error:nil];
                        }
                        [weakSelf.recordVideoTableViewDataArray removeObjectAtIndex:j];
                        break;
                    }
                }
            }
           
        }
        dispatch_async_on_main_queue(^{
            //退出编辑模式
            [self rightBarButtonAction];
            [weakSelf.recordVideoTableView reloadData];
            if (weakSelf.recordVideoTableViewDataArray.count ==0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.recordVideoTableView.mj_footer beginRefreshing];
                    [weakSelf pullupToLoadMore:nil];
                });
            }
            [SVProgressHUD dismiss];
            if (result == 0) {
                [SVProgressHUD showSuccessWithStatus:str];
            }
            else{
                [SVProgressHUD showErrorWithStatus:str];
            }
        });

//        [weakSelf showOperationResultWithMsg:str result:result indexPaths:selectedIndexPaths];
    }];

    
    NSLog(@"’删除‘按钮事件");
}

#pragma mark -- 修改按钮标题
- (void)changeRightBarTitle:(BOOL)isEditTitle
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        if (NO == isEditTitle)
        {
            [self.rightBarButton setTitle:DPLocalizedString(@"editor")
                                 forState:UIControlStateNormal];
        }
        else
        {
            [self.rightBarButton setTitle:DPLocalizedString(@"Setting_edit_Cancel")
                                 forState:UIControlStateNormal];
        }
    });
}


- (UIView*)OpRecordFileView{
    if (!_OpRecordFileView) {
        _OpRecordFileView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 40)];
    }
    return _OpRecordFileView;
}

#pragma mark -- 请求获取录像日期列表数据
- (void)getRecordVideoTableViewData:(NSMutableArray *)dataArray
{
    if (!dataArray)
    {
        ULifeLog(@"录像日期列表数组不存在，无法获取相关数据");
        return;
    }
    
    [self getOneDayRecFileFunc];
    //TODO: 添加获取数据源实现
    
//    RecordVideoTableViewCellModel *tempModel = [[RecordVideoTableViewCellModel alloc] init];
//    tempModel.recordVideoDateStr             = @"20170428";
//    tempModel.recordVideoTimeStr             = @"13:26:34";
//    tempModel.recordVideoFileNameStr         = @"20170428001.mp4";
//    tempModel.recordVideoFileSizeStr         = @"512KB";
//    tempModel.isDownload                   = NO;
//    [dataArray addObject:tempModel];

}


#pragma mark - 懒加载
#pragma mark -- 数据源模型数组
- (NSMutableArray<RecordVideoTableViewCellModel *> *)recordVideoTableViewDataArray
{
    if (!_recordVideoTableViewDataArray)
    {
        _recordVideoTableViewDataArray = [[NSMutableArray alloc] initWithCapacity:0];
    }
    
    return _recordVideoTableViewDataArray;
}

-(void)getOneDayRecFileFunc
{
    [SVProgressHUD showWithStatus:@"Loading...."];
    
    __weak typeof(self) weakSelf = self;
    _getOneDayRecFileReq = [[CMD_GetRecFileOneDayReq alloc]init];
    _getOneDayRecFileReq.page_num = 0;
    _getOneDayRecFileReq.a_day = [_recordDateStr stringByReplacingOccurrencesOfString:@"/" withString:@""];
    _getOneDayRecFileReq.file_type = 0;
    NSDictionary *reqData = [_getOneDayRecFileReq requestCMDData];
    
    [_netSDK net_sendBypassRequestWithUID:_deviceId requestData:reqData timeout:10000 responseBlock:^(int result, NSDictionary *dict) {
        if (result ==0){
            weakSelf.getOneDayRecFileResp = [CMD_GetRecFileOneDayResp yy_modelWithDictionary:dict];
            if (weakSelf.getOneDayRecFileResp.page_data.length <= 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Record_NoRecordFile")];
                    [SVProgressHUD dismissWithDelay:3];
                });
                return ;
            }
            [weakSelf refreshRecordFileListByInsertingFiles:NO];
        }
        else if(result == 2){
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Record_NoRecordFile")];
                [SVProgressHUD dismissWithDelay:3];
            });
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"data_unsuceess")];
                [SVProgressHUD dismissWithDelay:3];
            });
        }

    }];
}


- (void)refreshRecordFileListByInsertingFiles:(BOOL)isInserting{
    
    if (_getOneDayRecFileResp.page_data.length <= 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if ([_recordVideoTableView.mj_footer isRefreshing]) {
                [_recordVideoTableView.mj_footer endRefreshing];
            }
            if ([_recordVideoTableView.mj_header isRefreshing]) {
                [_recordVideoTableView.mj_header endRefreshing];
            }

        });
        return;
    }
    
    NSArray * tempArray = [_getOneDayRecFileResp.page_data componentsSeparatedByString:@"|"];
    NSMutableArray *listArray = [self fileModelListFromArray:tempArray];
    
    if ([listArray count] > 0) {
        if (isInserting) {
            [self.recordVideoTableViewDataArray insertObjects:listArray atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, listArray.count)]];
        }else{
            [self.recordVideoTableViewDataArray addObjectsFromArray:listArray];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            [self.recordVideoTableView reloadData];
        });
    }
}

-(NSMutableArray *)fileModelListFromArray:(NSArray *)listArray;
{
    if (!listArray || listArray.count==0) {
        return nil;
    }
    NSMutableArray *fileArray = [[NSMutableArray alloc]init];
    for (int i=0;i<listArray.count-1;i++)
    {
        NSString *fileStr = listArray[i];
        if (fileStr != nil)
        {
            NSArray *strArray = [fileStr componentsSeparatedByString:@"@"];
            if ([strArray count] > 0)
            {
                if ([strArray[0] length] > 14)
                {
                    NSString *dateStr = [strArray[0] substringWithRange:NSMakeRange(0,14)];
                    NSString *timeStr = [self getFormatedTimeFromStr:dateStr];
                    RecordVideoTableViewCellModel *model = [[RecordVideoTableViewCellModel alloc]init];
                    model.recordVideoFileNameStr = strArray[0];
                    model.recordVideoDateStr = timeStr;
                    model.recordFilePath     = [[mDocumentPath stringByAppendingPathComponent:mRecordFileFolderName]stringByAppendingPathComponent: model.recordVideoFileNameStr];
                    if ([mFileManager fileExistsAtPath:model.recordFilePath]) {
                        model.isDownload = YES;
                    }else{
                        model.isDownload = NO;
                    }
                    model.recordVideoFileSizeStr =  [NSString stringWithFormat:@"%@MB",[strArray[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
                    [fileArray addObject:model];
                }
            }
        }
    }
    return fileArray;
}

-(NSString *)getFormatedTimeFromStr:(NSString *)strTime;
{
    NSString *year = [strTime substringToIndex:4];
    NSString *month = [strTime substringWithRange:NSMakeRange(4, 2)];
    NSString *day = [strTime substringWithRange:NSMakeRange(6, 2)];
    
    NSString *time = [strTime substringWithRange:NSMakeRange(8, 2)];
    NSString *minute = [strTime substringWithRange:NSMakeRange(10,2)];
    NSString *seconds = [strTime substringWithRange:NSMakeRange(12,2)];
    NSString *dateTime = [NSString stringWithFormat:@"%@/%@/%@ %@:%@:%@",year,month,day,time,minute,seconds];
    return dateTime;
}


-(UIActivityIndicatorView*)activityViewIndicator{
    if (!_activityViewIndicator) {
        _activityViewIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        
        _activityViewIndicator.color = UIColor.darkGrayColor;
        _activityViewIndicator.frame = CGRectMake(self.view.frame.size.width/2-_activityViewIndicator.frame.size.width/2, 10, _activityViewIndicator.frame.size.width, _activityViewIndicator.frame.size.height);
        [_activityViewIndicator startAnimating];
    }
    return _activityViewIndicator;
}

-(UITableViewCell *)activityCell{
    if (!_activityCell) {
        _activityCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ActivityCell"];
        _activityCell.separatorInset = UIEdgeInsetsMake(0, 0, 0, _activityCell.bounds.size.width);
        [_activityCell addSubview:self.activityViewIndicator];
        _activityCell.userInteractionEnabled = NO;
    }
    return _activityCell;
}

- (UILabel*)noMoreDataLabel{
    if (!_noMoreDataLabel) {
        _noMoreDataLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.view.frame.size.width/2-90, 10, 180, 20)];
//        _noMoreDataLabel.text = @"没有更多数据了";
        _noMoreDataLabel.textAlignment = NSTextAlignmentCenter;
        _noMoreDataLabel.font = [UIFont systemFontOfSize:15];
    }
    return _noMoreDataLabel;
}

//- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
//    if(self.recordVideoTableView.contentOffset.y<0){
//        //it means table view is pulled down like refresh
//        return;
//    }
//    else if(self.recordVideoTableView.contentOffset.y >= (self.recordVideoTableView.contentSize.height - self.recordVideoTableView.bounds.size.height)) {
//        NSLog(@"eneter_bottom!");
//        [self loadMoreData];
//    }
//}


- (void)loadMoreData{
    
    if (_isEditing) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showInfoWithStatus:DPLocalizedString(@"please_quit_editing")];
        });
        return;
    }
    
    RecordVideoTableViewCellModel *model = self.recordVideoTableViewDataArray.lastObject;
    NSString *filename = model.recordVideoFileNameStr;
    
    _getOneDayRecFileReq.filename = filename;
    _getOneDayRecFileReq.page_num = 1;
    _getOneDayRecFileReq.direction = 1;
    _getOneDayRecFileReq.file_type = 0;
    _getOneDayRecFileReq.a_day = [_recordDateStr stringByReplacingOccurrencesOfString:@"/" withString:@""];

    __weak typeof(self) weakSelf = self;
    NSDictionary *reqData2 = [_getOneDayRecFileReq requestCMDData];
    [_netSDK net_sendBypassRequestWithUID:_deviceId requestData:reqData2 timeout:10000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            weakSelf.getOneDayRecFileResp = [CMD_GetRecFileOneDayResp yy_modelWithDictionary:dict];
            [weakSelf refreshRecordFileListByInsertingFiles:NO];
        }
        else if ( result == 2){
            _hasMoreDataFlag = YES;
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self.activityViewIndicator removeFromSuperview];
//                [self.activityCell addSubview:self.noMoreDataLabel];
//            });
        }else{
            NSLog(@"loadMoreData_____result________:%d",result);
        }
    }];
}



#pragma mark - Table View Delegate and DataSource

//-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return  (UITableViewCellEditingStyleDelete|UITableViewCellEditingStyleInsert|UITableViewCellEditingStyleNone);
//}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    long count = self.recordVideoTableViewDataArray.count;
    return count>0 ?count :0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.recordVideoTableViewDataArray.count>0 ? 1 : 0 ;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 68;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.row == _recordVideoTableViewDataArray.count) {
        self.activityCell.hidden = _recordVideoTableView.contentSize.height-50 < SCREEN_HEIGHT;
        return self.activityCell;
    }
    
    if (0 >= self.recordVideoTableViewDataArray.count)
    {
        return nil;
    }
    static NSString *recordVideoCellId = @"recordVideoCellIdentify";
    NSInteger rowIndex = indexPath.row;
    
    RecordVideoTableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
    cell = [tableView dequeueReusableCellWithIdentifier:recordVideoCellId];
  
    if (!cell) {
        cell = [[RecordVideoTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:recordVideoCellId];
    }
    
    cell.myStateBlock=^(BOOL state){
        isSectect = state;
        
        RecordVideoTableViewCellModel * md = [self.recordVideoTableViewDataArray objectAtIndex:rowIndex];
        md.isSelect=state;
        [self.recordVideoTableViewDataArray replaceObjectAtIndex:rowIndex withObject:md];
    };

        
    if (self.recordVideoTableViewDataArray.count > rowIndex)
    {
            cell.recordVideoTableViewCellData = [self.recordVideoTableViewDataArray objectAtIndex:rowIndex];
    }
    

    cell.isEditStyle = _isEditing;
    cell.tintColor = BACKCOLOR(36, 33, 33, 1);
    
    
    return cell;
}

// 判断网络状态
- (NSString *)checkNetState
{
    UIApplication *app = [UIApplication sharedApplication];
    NSArray *children = [[[app valueForKeyPath:@"statusBar"] valueForKeyPath:@"foregroundView"] subviews];
    int type = 0;
    for (id child in children) {
        if ([child isKindOfClass:NSClassFromString(@"UIStatusBarDataNetworkItemView")]) {
            type = [[child valueForKeyPath:@"dataNetworkType"] intValue];
        }
    }
    switch (type) {
        case 1:
            return @"2G";
        case 2:
            return @"3G";
        case 3:
            return @"4G";
        case 5:
            return @"WIFI";
        default:
            return @"NO-WIFI";//代表未知网络
    }
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _clickedIndexPathInDownloading = indexPath;
    
    NSString * str = [self checkNetState];
    
    NSLog(@"当前网络状态:============ %@",str);
    
    if ([str isEqualToString:@"WIFI"]) {
        
        NSInteger rowIndex = indexPath.row;
        if (self.recordVideoTableViewDataArray.count <= rowIndex)
        {
            return ;
        }
        [tableView deselectRowAtIndexPath:indexPath
                                 animated:YES];

        RecordVideoTableViewCellModel *model = _recordVideoTableViewDataArray[indexPath.row];
        
        if (_isEditing) {
            model.isSelect = !model.isSelect;
            [self.recordVideoTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            return;
        }
        
        _curDownloadingFilePath = model.recordFilePath;
        if (model.isDownload) {
            [self playRecordVideoWithPath:model.recordFilePath];
        }
        else
        {
            NSString *imageName = @"Record_VideoIcon@2x.png";
            [self downloadFileWithIndexPath:indexPath andimageName:imageName];
        }
    }
    else{
        
        RecordVideoTableViewCellModel *model = _recordVideoTableViewDataArray[indexPath.row];
        
        if (_isEditing) {
            model.isSelect = !model.isSelect;
            [self.recordVideoTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            return;
        }
        
        if (model.isDownload) {
            [self playRecordVideoWithPath:model.recordFilePath];
            return;
        }
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:DPLocalizedString(@"Celular_Download") preferredStyle:UIAlertControllerStyleAlert];
        
        // 添加按钮
        __weak typeof(alert) weakAlert = alert;
        [alert addAction:[UIAlertAction actionWithTitle:DPLocalizedString(@"WiFi_sure") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            NSLog(@"点击了确定按钮--%@-%@", [weakAlert.textFields.firstObject text], [weakAlert.textFields.lastObject text]);
            NSInteger rowIndex = indexPath.row;
            if (self.recordVideoTableViewDataArray.count <= rowIndex || _isEditing)
            {
                return ;
            }
            [tableView deselectRowAtIndexPath:indexPath
                                     animated:YES];
            
            RecordVideoTableViewCellModel *model = _recordVideoTableViewDataArray[indexPath.row];
            
            if (_isEditing) {
                model.isSelect = !model.isSelect;
                [self.recordVideoTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                return;
            }
            
            _curDownloadingFilePath = model.recordFilePath;
            if (model.isDownload) {
                [self playRecordVideoWithPath:model.recordFilePath];
            }
            else
            {
                NSString *imageName = @"Record_VideoIcon@2x.png";
                [self downloadFileWithIndexPath:indexPath andimageName:imageName];
            }

            
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:DPLocalizedString(@"Setting_Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            NSLog(@"点击了取消按钮");
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}






- (void)playRecordVideoWithPath:(NSString*)path{
    
    MPMoviePlayerViewController *mediaVC = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:path] ];
    [self presentViewController:mediaVC animated:YES completion:^{
        
    }];
    [[NSNotificationCenter defaultCenter] addObserver:self
     
                                             selector:@selector(movieFinishedCallback:)
     
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
     
                                               object:mediaVC.moviePlayer];
//    RecordVideoPlayViewController *videoPlayVC = [[RecordVideoPlayViewController alloc] init];
//    if (videoPlayVC)
//    {
//        videoPlayVC.recordVideoFilePath = path;
//        [self presentViewController:videoPlayVC
//                           animated:YES
//                         completion:nil];
//    }

}

-(void)movieFinishedCallback:(NSNotification*)notify {
    
//    _shouldAutoRotate = NO;
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationPortrait] forKey:@"orientation"];
    
    MPMoviePlayerController* theMovie = [notify object];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
     
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
     
                                                  object:theMovie];
    [theMovie.view removeFromSuperview];
}

#pragma mark == <PopupView>
- (void)showPopupWithStyle:(CNPPopupStyle)popupStyle andFileName:(NSString *)fileName andImageName:(NSString *)imgName
{
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSAttributedString *title = [[NSAttributedString alloc] initWithString:DPLocalizedString(@"download_file") attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:20],NSForegroundColorAttributeName : [UIColor blackColor],NSParagraphStyleAttributeName : paragraphStyle}];
    
    NSAttributedString *FiLelTitle = [[NSAttributedString alloc] initWithString:fileName attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:12],NSForegroundColorAttributeName : [UIColor blackColor],NSParagraphStyleAttributeName : paragraphStyle}];
    
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.attributedText = title;
    }
    
    if (_imageView == nil) {
        _imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 40, 40)];
    }
    _imageView.image = [UIImage imageNamed:imgName];
    
    float width = self.view.frame.size.width;
    if (_FiletitleLabel == nil) {
        _FiletitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width,15)];
    }
    _FiletitleLabel.attributedText = FiLelTitle;
    
    if (_progressView == nil) {
        _progressView = [[ASProgressPopUpView alloc] initWithFrame:CGRectMake(0, 0, width, 30)];
        _progressView.popUpViewCornerRadius = 12.0;
        _progressView.font = [UIFont fontWithName:@"Futura-CondensedExtraBold" size:12];
        [_progressView setTrackTintColor:[ConfigureFile getConfigColor:@"COLOR_REMOTE_NAV_BAR"]];
        _progressView.popUpViewAnimatedColors = @[[UIColor greenColor]];
    }
    [_progressView showPopUpViewAnimated:NO];
    self.progressView.progress = 0.0f;
    self.progressView.hidden = NO;

    __weak typeof(self) weakSelf = self;

    if (_button == nil) {
        _button = [[CNPPopupButton alloc] initWithFrame:CGRectMake(0, 0, width-150, 30)];
        [_button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _button.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        [_button setTitle:DPLocalizedString(@"complete_end") forState:UIControlStateNormal];
        _button.backgroundColor = [ConfigureFile getConfigColor:@"COLOR_REMOTE_NAV_BAR"];
        _button.layer.cornerRadius = 4;
        
        _button.selectionHandler = ^(CNPPopupButton *button){
            [weakSelf.network StopVideoListFileDownload:cmdModel_VIDEOLIST andParam:Camera_VIDEOLIST_DOWNLOADFILE_START_REQ andUID:weakSelf.deviceId];
            [weakSelf dismissDownloadingAnimationWithMsg:@"download_unsuccess"];
            NSLog(@"Block for button: %@", button.titleLabel.text);
        };
    }
    
    if (_popupController == nil) {
        self.popupController = [[CNPPopupController alloc] initWithContents:@[_titleLabel,_imageView,_FiletitleLabel,_progressView,_button]];
        self.popupController.theme = [CNPPopupTheme defaultTheme];
        self.popupController.theme.popupStyle = popupStyle;
        self.popupController.theme.shouldDismissOnBackgroundTouch = NO;
        self.popupController.delegate = self;
    }
    [self.popupController presentPopupControllerAnimated:YES];
}



-(void)downloadFileWithIndexPath:(NSIndexPath *)indexPath andimageName:(NSString*)imgName;
{
    RecordVideoTableViewCellModel *model = _recordVideoTableViewDataArray[indexPath.row];
    
    NSString *recoderpath = [NSString stringWithFormat:@"%@/%@/%@",mDocumentPath,mRecordFileFolderName,model.recordVideoFileNameStr];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:recoderpath])
    {
        [self playRecordVideoWithPath:model.recordFilePath];
    }
    else
    {
        [self showPopupWithStyle:CNPPopupStyleCentered andFileName:model.recordVideoFileNameStr andImageName:imgName];

        __weak typeof(self) weakSelf = self;

        [_network StartVideoListFileDownload:cmdModel_VIDEOLIST andParam:Camera_VIDEOLIST_DOWNLOADFILE_START_REQ andUID:_deviceId andFileName:model.recordVideoFileNameStr andFilePath:recoderpath andBlock:^(int result, float progress,NSString*uid) {
            
            if (![_deviceId containsString:uid]) {
                return ;
            }
            if (result == 0) {
                if (progress >= 2.0f) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (!model.isDownload) {
                            
                            unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:recoderpath error:nil] fileSize];
                            
                            NSLog(@"________________________________fileName:%@ beforeSize:%ld afterSize:%lld",model.recordVideoFileNameStr,_network.downloadFileSize,fileSize);
                            
                            
                            if (fileSize == _network.downloadFileSize && fileSize > 0) {
                                model.isDownload = YES;
                                model.recordFilePath = recoderpath;
                                if ([weakSelf isWiFiDoorBell]) {
                                    [weakSelf convertMP4WithOrignalPath:recoderpath];
                                }else{
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [weakSelf.recordVideoTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
                                        [weakSelf.popupController dismissPopupControllerAnimated:YES];
                                    });
                                }
                            }else{
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"File size unequal")];
                                    [weakSelf.popupController dismissPopupControllerAnimated:YES];
                                });
                                model.isDownload = NO;
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                    [[NSFileManager defaultManager] removeItemAtPath:recoderpath error:nil];
                                });
                            }
                        }
                    });
                }
                else
                {
                    [weakSelf updateProgress:progress];
                }
            }
            else{
                if ([mFileManager fileExistsAtPath:recoderpath]){
                    [mFileManager removeItemAtPath:recoderpath error:nil];
                }
                if(result == -1)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"File Not Exist")];
                        [self.popupController dismissPopupControllerAnimated:YES];
                    });
                }
                else if(result == -2)
                {
                    [self dismissDownloadingAnimationWithMsg:@"Cannot download two files concurrently"];
                }
                else
                {
                    [self dismissDownloadingAnimationWithMsg:@"download_unsuccess"];
                }
            }
        }];
    }
}

- (BOOL)isWiFiDoorBell{
    GosDetailedDeviceType detailType = [DeviceDataModel detailedDeviceTypeWithString:[self.deviceId substringWithRange:NSMakeRange(3, 2)]];
    return detailType==GosDetailedDeviceType_T5100ZJ || detailType == GosDetailedDeviceType_T5200HCA;
}

- (void)convertMP4WithOrignalPath:(NSString*)originalPath{
    
    NSString *cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]  stringByAppendingPathComponent:[originalPath lastPathComponent]];
    
//    RecordVideoTableViewCellModel *model = _recordVideoTableViewDataArray[_clickedIndexPathInDownloading.row];
//
//    NSString *tempPath = [ [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:model.recordFilePath.lastPathComponent];
    NSError *error;
    unsigned long long fileSize = [[mFileManager attributesOfItemAtPath:originalPath error:nil] fileSize];
    NSLog(@"originalPathSize:%lld    ",fileSize);

    if ([mFileManager moveItemAtPath:originalPath toPath:cachePath error:&error]) {
        unsigned long long fileSize = [[mFileManager attributesOfItemAtPath:cachePath error:nil] fileSize];
        NSLog(@"cachePathFileSize:%lld    ",fileSize);
        
    }else{
        NSLog(@"moveItemToPath_______error:%@",error.description);
    }
    
    [self.videoDecoder initVideoDecoderWithDataCallBack:^(PDecodedFrameParam frameParam) {
        
    }];
    [_videoDecoder ac_captureMP4WithOrgFileName:cachePath destinaFileName:originalPath startTime:0 totalTime:-1];
}

- (void)updateProgress:(float)floatValue{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressView.progress = floatValue;
        if (ABS(floatValue - 1.0) < 0.0001) { //已完成
            [self.progressView hidePopUpViewAnimated:NO];
            self.progressView.hidden = YES;
        }else{
            self.progressView.hidden = NO;
        }

    });
}



- (void)dismissDownloadingAnimationWithMsg:(NSString*)msg{
    
    NSString *recoderpath = _curDownloadingFilePath;
    if ([[NSFileManager defaultManager] fileExistsAtPath:recoderpath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:recoderpath error:nil];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(msg)];
        [self.popupController dismissPopupControllerAnimated:YES];
    });
    
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 
    if (_isEditing) {
        return NO;
    }
    
    return indexPath.row != self.recordVideoTableViewDataArray.count ;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        RecordVideoTableViewCellModel *model = _recordVideoTableViewDataArray[indexPath.row];
        if (model != nil) {
            
            _deleteRecFileCmd = [CMD_DeleteRecordFileReq new];
            
            NSArray *tempArray = [NSArray arrayWithObject:@{@"a_file_name":model.recordVideoFileNameStr}];
            _deleteRecFileCmd.file_name_list = tempArray;
            
            NSDictionary *reqData = [_deleteRecFileCmd requestCMDData];
            [SVProgressHUD showWithStatus:@"Loading...."];
            __weak typeof(self) weakSelf = self;
            
            [_netSDK net_sendBypassRequestWithUID:_deviceId requestData:reqData timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
                
                NSString *str = [NSString stringWithFormat:@"%@",DPLocalizedString(result==0?@"delete_file_success":@"delete_file_unsuccess")];
                
                if (result == 0) {
                    [weakSelf.recordVideoTableViewDataArray removeObjectAtIndex:indexPath.row];
                    NSString *filePath = [[mDocumentPath stringByAppendingPathComponent:mRecordFileFolderName]stringByAppendingPathComponent:model.recordVideoFileNameStr];
                    if ([[NSFileManager defaultManager] fileExistsAtPath: filePath]){
                        [[NSFileManager defaultManager] removeItemAtPath: filePath error:nil];
                    }
                }
                [weakSelf showOperationResultWithMsg:str result:result indexPaths:@[indexPath]];
            }];
        }
    }
}

- (void)showOperationResultWithMsg:(NSString*)msg result:(int)result indexPaths:(NSArray*)indexPaths{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (result == 0) {
            if (_recordVideoTableViewDataArray.count == 0) {
                [self.recordVideoTableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
                
            }else{
                [self.recordVideoTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationLeft];
            }
            [SVProgressHUD showSuccessWithStatus:msg];
        }else{
            [self.recordVideoTableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
            [SVProgressHUD showErrorWithStatus:msg];
        }
    });
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
