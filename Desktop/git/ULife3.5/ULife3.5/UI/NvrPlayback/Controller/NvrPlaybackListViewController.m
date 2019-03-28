//
//  NvrPlaybackListViewController.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/21.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "NvrPlaybackListViewController.h"
#import "NetAPISet.h"
#import "NvrPlaybackListModel.h"
#import "NvrPlaybackPlayViewController.h"


/** 列表 cell 高度*/
#define NVR_PALYBACK_LIST_CELL_HEIGHT 44.0f

/** 等待 NVR 设备 停止播放历史流响应超时时间 */
#define WAITE_RESP_TIME_OUT 10.0f


@interface NvrPlaybackListViewController () <
                                                UITableViewDelegate,
                                                UITableViewDataSource,
                                                GDNetworkSourceDelegate
                                            >
{
    /** 当前插入的行 index */
    NSUInteger _currentInsertRowIndex;
    
    /** 录像文件总数 */
    uint32_t _fileTotalCount;
    
    /** 是否跳转至播放页面 */
    BOOL _isGoToPlayingView;
    
    /** 是否收到上一文件停止播放的响应 （收到了才可以播放下一个文件）*/
    BOOL _isRespEndUpPlay;
    
    /** 监听响应超时次数 */
    int _monitorRespTimeoutCount;
    
    /** 刷新列表定时器 */
    NSTimer *_refreshListTimer;
}

/** 搜索中 Activity */
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *searchActivity;

/** 搜索结果数 Label */
@property (weak, nonatomic) IBOutlet UILabel *resultCountLabel;

/** 搜索结果 TableView */
@property (weak, nonatomic) IBOutlet UITableView *searchListTableView;

/** 回放文件列表数组 */
@property (nonatomic, strong) NSMutableArray <NvrPlaybackListModel *>*nvrPlaybackListArray;

/** 回放文件列表数组（临时存放，用于缓存刷新速度） */
@property (nonatomic, strong) NSMutableArray <NvrPlaybackListModel *>*tempPlaybackListArray;

@end

@implementation NvrPlaybackListViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = DPLocalizedString(@"VR360_playback");
    
    [self initParam];
    [self monitorEndUpPlayCB];
    [self configTableView];
    
    __weak typeof(self)weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法搜索 NVR Playback！");
            return ;
        }
        [strongSelf startSearchNvrPlayback];
        
        [strongSelf startRefreshTimer];
    });
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _isGoToPlayingView = NO;
    
    [self setApiNetDelegate];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self removeApiNetDelegate];
    
    if (NO == _isGoToPlayingView)
    {
         [self stopRefreshTimer];
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
    NSLog(@"----------- NvrPlaybackListViewController dealloc -----------");
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"EndUpPlayNvrPBCallBack"
                                                  object:nil];
}


- (void)initParam
{
    _isRespEndUpPlay         = YES;
    _currentInsertRowIndex   = 0;
    _monitorRespTimeoutCount = 0;
}



#pragma mark - 懒加载
- (NSMutableArray<NvrPlaybackListModel *> *)nvrPlaybackListArray
{
    if (!_nvrPlaybackListArray)
    {
        _nvrPlaybackListArray = [NSMutableArray arrayWithCapacity:0];
    }
    return _nvrPlaybackListArray;
}


- (NSMutableArray<NvrPlaybackListModel *> *)tempPlaybackListArray
{
    if (!_tempPlaybackListArray)
    {
        _tempPlaybackListArray = [NSMutableArray arrayWithCapacity:0];
    }
    return _tempPlaybackListArray;
}


#pragma mark - 监听回放页面‘停止回放视频流的响应’通知
- (void)monitorEndUpPlayCB
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleEndUpPlayCallBack)
                                                 name:@"EndUpPlayNvrPBCallBack"
                                               object:nil];
}


- (void)handleEndUpPlayCallBack
{
    NSLog(@"--- NvrPlaybackListViewController -- 接收 -- EndUpPlayNvrPBCallBack 通知");
    _isRespEndUpPlay = YES;
    // 收到前一次播放页面的停止播放响应后，在发通知，此时才可以拉取新的回放视频流
    // 此处逻辑有点绕：由于 NVR 设备的回放 AV 通道固定一个，而且是一个回放新启一个线程，如果前一次回放没有停止成功，又马上进行播放新的回放文件，就会有两个线程网同一个 AV 通道传输视频流数据，就会出现‘串流’的现象，所有 APP 端需要做：在接收到上一次回放的停止拉流的响应后，才可进行下一次的回放拉流操作。
    [self notifyRespEndUpPlay];
}


#pragma mark -- 发送接收到‘停止回放视频流的响应’通知
- (void)notifyRespEndUpPlay
{
    NSLog(@"--- NvrPlaybackListViewController -- 发送 -- DidRespEndUpPlayNvrPB 通知");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DidRespEndUpPlayNvrPB"
                                                        object:nil];
}


#pragma mark - 搜索指定条件的录像
- (void)startSearchNvrPlayback
{
    if (IS_STRING_EMPTY(self.nvrDeviceId)
        || IS_STRING_EMPTY(self.searchDate)
        || IS_STRING_EMPTY(self.startTime)
        || IS_STRING_EMPTY(self.endTime))
    {
        NSLog(@"搜索 NVR 回放失败，nvrDeviceId = %@, searchDate = %@, startTime = %@, endTime = %@", self.nvrDeviceId, self.searchDate, self.startTime, self.endTime);
        
        return ;
    }
    
    [self.tempPlaybackListArray removeAllObjects];
    [self.nvrPlaybackListArray removeAllObjects];
    [self.searchListTableView reloadData];
    [self configActivityAnimation:YES];
    
    _currentInsertRowIndex = 0;
    
    NSLog(@"==== 准备发送获取 NVR 录像列表 channelMast = %d date = %@ ", self.channelMask, self.searchDate);
    __weak typeof(self)weakSelf = self;
    [[NetAPISet sharedInstance] nvrGetVideoListWithDeviceId:self.nvrDeviceId
                                                channelMask:self.channelMask
                                                   typeMask:self.videoType
                                                       date:self.searchDate
                                                  startTime:self.startTime
                                                    endTime:self.endTime
                                                resultBlock:^(BOOL isSuccess,
                                                              NSString *nvrDeviceId,
                                                              NSString *fileName,
                                                              NSString *startTime,
                                                              NSString *endTime,
                                                              unsigned int length,
                                                              unsigned int frames,
                                                              unsigned short channelMask,
                                                              unsigned short recordType,
                                                              unsigned int fileTotalNumbers) {
                                                    
                                                    __strong typeof(weakSelf)strongSelf = weakSelf;
                                                    if (!strongSelf)
                                                    {
                                                        NSLog(@"对象丢失，无法处理 NVR 录像返回的结果！");
                                                        return ;
                                                    }
                                                    if (0 >= fileTotalNumbers)
                                                    {
                                                        [strongSelf configActivityAnimation:NO];
                                                        return;
                                                    }
                                                    strongSelf->_fileTotalCount = fileTotalNumbers;
                                                    [strongSelf pareseVideoListData:nvrDeviceId
                                                                           fileName:fileName
                                                                          startTime:startTime
                                                                            endTime:endTime
                                                                             length:length
                                                                             frames:frames
                                                                        channelMask:channelMask
                                                                         recordType:recordType];
                                                }];
}


#pragma mark -- 解析文件提取时间串信息
- (void)pareseVideoListData:(NSString *)deviceId
                   fileName:(NSString *)fileName
                  startTime:(NSString *)startTime
                    endTime:(NSString *)endTime
                     length:(uint32_t)length
                     frames:(uint32_t)frames
                channelMask:(uint16_t)channelMask
                 recordType:(uint16_t)recordType
{
    if (IS_STRING_EMPTY(fileName)
        || IS_STRING_EMPTY(startTime)
        || IS_STRING_EMPTY(endTime))
    {
        NSLog(@"更新录像列表数据失败，fileName = %@, startTime = %@, endTime = %@", fileName, startTime, endTime);
        
        return ;
    }
    
    NvrPlaybackListModel *listModel = [[NvrPlaybackListModel alloc] init];
    listModel.deviceId    = deviceId;
    listModel.fileName    = fileName;
    listModel.startTime   = startTime;
    listModel.endTime     = endTime;
    listModel.length      = length;
    listModel.frames      = frames;
    listModel.channelMask = channelMask;
    listModel.recordType  = recordType;
    
    [self.tempPlaybackListArray addObject:listModel];
}


#pragma mark -- 开启刷新列表定时器（从临时缓存复制到模型数组）
- (void)startRefreshTimer
{
    if (!_refreshListTimer)
    {
        _refreshListTimer = [NSTimer scheduledTimerWithTimeInterval:0.05f
                                                             target:self
                                                           selector:@selector(refreshListData)
                                                           userInfo:nil
                                                            repeats:YES];
        _refreshListTimer.fireDate = [NSDate distantPast];
        [[NSRunLoop mainRunLoop] addTimer:_refreshListTimer
                                  forMode:NSDefaultRunLoopMode];
        [[NSRunLoop mainRunLoop] addTimer:_refreshListTimer
                                  forMode:UITrackingRunLoopMode];
    }
}


- (void)stopRefreshTimer
{
    if (_refreshListTimer)
    {
        [_refreshListTimer invalidate];
        _refreshListTimer = nil;
    }
}


#pragma mark -- 刷新列表
- (void)refreshListData
{
    if (0 < _fileTotalCount
        && _fileTotalCount== _currentInsertRowIndex)
    {
        NSLog(@"数据已经加载完成！");
        [self configActivityAnimation:NO];
        
        [self stopRefreshTimer];
        
        return ;
    }
    [self configActivityAnimation:YES];
    
    if (0 >= self.tempPlaybackListArray.count)
    {
        return;
    }
    
    NvrPlaybackListModel *listModel = [self.tempPlaybackListArray objectAtIndex:0];
    [self.tempPlaybackListArray removeObjectAtIndex:0];
    [self.nvrPlaybackListArray addObject:listModel];
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        strongSelf.resultCountLabel.text = [NSString stringWithFormat:@"%@:%lu", DPLocalizedString(@"SearchResult"), (unsigned long)strongSelf->_currentInsertRowIndex + 1];
        [strongSelf.searchListTableView beginUpdates];
        [strongSelf.searchListTableView insertRowsAtIndexPaths:@[
                                                                 [NSIndexPath indexPathForRow:_currentInsertRowIndex++
                                                                                    inSection:0]
                                                                 ]
                                              withRowAnimation:UITableViewRowAnimationAutomatic];
        [strongSelf.searchListTableView endUpdates];
        if (_fileTotalCount == _currentInsertRowIndex)
        {
            [strongSelf configActivityAnimation:NO];
        }
    });

}


#pragma mark - NetAPISet
#pragma mark -- 设置全局NetAPI代理
- (void)setApiNetDelegate
{
    [NetAPISet sharedInstance].sourceDelegage = self;
}


#pragma mark -- 移除全局NetAPI代理
- (void)removeApiNetDelegate
{
    [NetAPISet sharedInstance].sourceDelegage = nil;
}


#pragma mark -- 设置 Activity 动画
- (void)configActivityAnimation:(BOOL)isAnimate
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
       
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法设置 Activity 动画!");
            return ;
        }
        if (NO == isAnimate)    // 停止动画
        {
            [strongSelf.searchActivity stopAnimating];
            strongSelf.searchActivity.hidden = YES;
        }
        else    // 开启动画
        {
            strongSelf.searchActivity.hidden = NO;
            [strongSelf.searchActivity startAnimating];
        }
    });
}


#pragma mark -- 设置 TableView
- (void)configTableView
{
    self.searchListTableView.rowHeight = NVR_PALYBACK_LIST_CELL_HEIGHT;
    self.resultCountLabel.text = [NSString stringWithFormat:@"%@:0", DPLocalizedString(@"SearchResult")];
    [self.searchListTableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
}


#pragma mark - TableView delegate & datasource
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    if (!self.nvrPlaybackListArray)
    {
        return 0;
    }
    else
    {
        return self.nvrPlaybackListArray.count;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *nvrPlaybackListCellId = @"nvrPlaybackListCellId";
    NSInteger rowIndex = indexPath.row;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nvrPlaybackListCellId];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:nvrPlaybackListCellId];
    }
    if (rowIndex < self.nvrPlaybackListArray.count)
    {
        NvrPlaybackListModel *listModel = self.nvrPlaybackListArray[rowIndex];
        NSString *fileStartTime = [listModel.startTime substringFromIndex:10];
        NSString *fileEndTime = [listModel.endTime substringFromIndex:10];
        NSString *fileTime = [NSString stringWithFormat:@"%@-%@", fileStartTime, fileEndTime];
        cell.textLabel.text = fileTime;
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger rowIndex = indexPath.row;
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
    if (self.nvrPlaybackListArray.count <= rowIndex)
    {
        NSLog(@"无法播放录像，rowIndex = %ld, self.videoListArray.count = %lu", (long)rowIndex, (unsigned long)self.nvrPlaybackListArray.count);
        
        return ;
    }
    
    NvrPlaybackListModel *playbackListModel = self.nvrPlaybackListArray[rowIndex];

    [SVProgressHUD showWithStatus:@"Loading..."];
    
    tableView.userInteractionEnabled = NO;
    _monitorRespTimeoutCount = 0;
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法播放！");
            return ;
        }
        [strongSelf pushToPlayVCWithModel:playbackListModel];
    });
}


- (void)pushToPlayVCWithModel:(NvrPlaybackListModel *)listModel
{
    if (!listModel)
    {
        NSLog(@"模型为空，无法进行回放！");
        [SVProgressHUD dismiss];
        return;
    }
    while (NO == _isRespEndUpPlay) // 循环等待上一次的停流操作响应
    {
//        NSLog(@"--- NvrPlaybackListViewController --- 等待停止回放视频流的响应！");
        _monitorRespTimeoutCount++;
        if (100 == _monitorRespTimeoutCount)
        {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"localizied_294")];
            self.searchListTableView.userInteractionEnabled = YES;
            _isRespEndUpPlay = YES;
            return;
        }
        [NSThread sleepForTimeInterval:0.1];
    }
    
    NvrPlaybackPlayViewController *pbPlayVC = [[NvrPlaybackPlayViewController alloc] initWithModel:listModel
                                                                                         tutkDevId:self.nvrDeviceId];
    self.searchListTableView.userInteractionEnabled = YES;
    [SVProgressHUD dismiss];
    if (pbPlayVC)
    {
        pbPlayVC.devDataModel  = self.devDataModel;
        pbPlayVC.positionType  = self.channelMask;
        _isGoToPlayingView     = YES;
        _isRespEndUpPlay       = NO;
        __weak typeof(self)weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                NSLog(@"对象丢失，无法播放！");
                return ;
            }
            [strongSelf.navigationController pushViewController:pbPlayVC
                                                 animated:YES];
        });
    }
}


#pragma mark - 横竖屏切换相关
#pragma mark -- 是否允许横竖屏
-(BOOL)shouldAutorotate
{
    return NO;
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


@end
