//
//  PlayListViewController.m
//  ULife3.5
//
//  Created by 广东省深圳市 on 2017/6/15.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "PlayListViewController.h"
#import "UIColor+YYAdd.h"
#import "RecordVideoTableViewCell.h"
#import "RecordImgTableViewCell.h"
#import "RecordImageShowViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "EnlargeClickButton.h"
#import <Masonry.h>
#import "PanoramaLivePlayerVC.h"
#import "MediaManager.h"

#define MEDIA_LIST_CELL_HEIGHT 68.0f

static NSString *const videoCellResu = @"recordVideoCellIdentify";
static NSString *const imgCellResu = @"recordImgCellIdentify";


//选中的模式
typedef NS_ENUM(NSUInteger, selectType) {
    selectTypeVideo,
    selectTypeImage
};

typedef NS_ENUM(NSUInteger, editType) {
    editTypeNormal,
    editTypeSelect
};

@interface PlayListViewController ()<UITableViewDelegate,UITableViewDataSource>


@property (nonatomic,strong)UITableView *mainTableView;

@property (nonatomic,strong)UIView *bottomView;

@property (nonatomic,strong)UIView *editBottomView;

@property (nonatomic,strong)EnlargeClickButton *videoBtn;

@property (nonatomic,strong)EnlargeClickButton *imageBtn;

@property (nonatomic,strong)UIButton *deleteBtn;

@property (nonatomic,strong)UIButton *allSelectBtn;

@property (nonatomic,strong)UILabel *videoLabel;

@property (nonatomic,strong)UILabel *photoLabel;

@property (nonatomic,strong)UIButton *rightNavButton;

@property (nonatomic,strong)NSMutableArray <MediaFileModel *>*dataArray;

/** 视频列表数据 */
@property (nonatomic, strong) NSMutableArray <MediaFileModel *>*videoArray;

/** 图片列表数据 */
@property (nonatomic, strong) NSMutableArray <MediaFileModel *>*imageArray;

@property (nonatomic,assign)selectType selectType;

@property (nonatomic,assign)editType editType;



@end

@implementation PlayListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = DPLocalizedString(@"Setting_PhotoAlbum");
    
    [self initparam];
    
    [self configNavItem];
    
    [self setupUI];
    
    [SVProgressHUD showWithStatus:@"loading ..."];
    __weak typeof(self)weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        __strong typeof(self)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        [strongSelf retrieveMediaFile];
    });
}


#pragma mark - 初始化参数
- (void)initparam
{
    self.editType   = editTypeNormal;
    self.selectType = selectTypeVideo;
}

#pragma mark - UI Setup
- (void)setupUI
{
    self.mainTableView.rowHeight = MEDIA_LIST_CELL_HEIGHT;
    
    [self.view addSubview:self.mainTableView];
    [self.view addSubview:self.bottomView];
    [self.view addSubview:self.editBottomView];
    
    [self.bottomView addSubview:self.videoBtn];
    [self.bottomView addSubview:self.videoLabel];
    
    [self.bottomView addSubview:self.imageBtn];
    [self.bottomView addSubview:self.photoLabel];
    
    [self.editBottomView addSubview:self.allSelectBtn];
    [self.editBottomView addSubview:self.deleteBtn];
    
    //设置bottomView约束
    
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
        make.height.equalTo(@48);
    }];
    
    [self.editBottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
        make.height.equalTo(@48);
    }];
}


#pragma mark -- 初始化获取录像文件
- (void)retrieveMediaFile
{
    self.videoArray = [self getVideoArray];
    self.imageArray = [self getImageArray];
    
    self.dataArray  = self.videoArray;
    
    if (self.dataArray.count == 0)
    {
        [self showNoDataMessage];
        return;
    }
    [SVProgressHUD dismiss];
    [self.mainTableView reloadData];
}


#pragma mark - UITableViewDelegate && UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    if (!self.dataArray)
    {
        return 0;
    }
    return self.dataArray.count;
}


#pragma mark - 取消☑️按钮事件，通过点击整个cell来决定选中与否
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger rowIndex = indexPath.row;
    __weak typeof(self) weakSelf = self;
    if (self.selectType == selectTypeVideo)
    {
        RecordVideoTableViewCell *videoCell = [tableView dequeueReusableCellWithIdentifier:videoCellResu];
        if (!videoCell)
        {
            videoCell = [[RecordVideoTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                        reuseIdentifier:videoCellResu];
        }
        //取消☑️按钮事件
        [videoCell setSelectBtnEnabled: NO];

        if (self.editType == editTypeSelect)
        {
            videoCell.isEditStyle = YES;
        }
        else
        {
            videoCell.isEditStyle = NO;
        }
        
        [videoCell setStatusImgViewHidden:YES];
        
        videoCell.selectBlock = ^(BOOL isSelect, RecordVideoTableViewCell *cell) {
            
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                return ;
            }
            //取消全选按钮
            [strongSelf endAllSelect];
        };
        if (self.dataArray.count > rowIndex)
        {
            videoCell.mediaFileCellData = self.dataArray[rowIndex];
        }
        
        return videoCell;
    }
    else
    {
        RecordImgTableViewCell *imgCell = [tableView dequeueReusableCellWithIdentifier:imgCellResu];
        if (!imgCell)
        {
            imgCell = [[RecordImgTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                    reuseIdentifier:imgCellResu];
        }
        //取消☑️按钮事件
        [imgCell setSelectBtnEnabled: NO];
        
        if (self.editType == editTypeSelect)
        {
            imgCell.isEditStyle = YES;
        }
        else
        {
            imgCell.isEditStyle = NO;
        }
        
        [imgCell setStatusImgViewHidden:YES];
        imgCell.selectBlock = ^(BOOL isSelect, RecordImgTableViewCell *cell) {
            
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                return ;
            }
            //取消全选按钮
            [strongSelf endAllSelect];
        };
        if (self.dataArray.count > rowIndex)
        {
            imgCell.mediaFileCellData = self.dataArray[rowIndex];
        }
        
        return imgCell;
    }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editType == editTypeSelect)
    {
        self.dataArray[indexPath.row].selected = !self.dataArray[indexPath.row].isSelected;
        [self.mainTableView reloadData];
        return;
    }
    
    if (self.selectType == selectTypeImage)
    {
        [self playRecordImageWithModel:self.dataArray[indexPath.row]];
    }
    else
    {
        MediaFileModel *mediaFile = self.dataArray[indexPath.row];
        
        [self playRecordVideoWithPath:mediaFile.filePath];
    }
}


- (void)playRecordImageWithModel:(MediaFileModel *)mediaFile
{    
    if ( self.model.DeviceType == GosDevice360) {//VR360
//        PanoramaLivePlayerVC *vc = [[PanoramaLivePlayerVC alloc] init];
//        vc.curPanoramaType = PanoramaTypeImage;
//        [self.navigationController pushViewController:vc animated:YES];
//        return;
    }
    
    RecordImageShowViewController *recordImgShowVC = [[RecordImageShowViewController alloc] init];
    if (recordImgShowVC)
    {
        recordImgShowVC.recordImgFileName = mediaFile.fileName;
        recordImgShowVC.recordImgFilePath = mediaFile.filePath;
        [self.navigationController pushViewController:recordImgShowVC
                                             animated:YES];
    }
}


#pragma mark -- 设 Cell 是否可编辑
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    //选中状态下不能删除
    if (self.editType == editTypeSelect)
    {
        return NO;
    }
    return YES;
}
#pragma mark -- 定义编辑样式
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

#pragma mark -- 进入编辑模式，按下出现的编辑按钮后,进行删除操作
- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle != UITableViewCellEditingStyleDelete)
    {
        return;
    }
    NSInteger rowIndex = indexPath.row;
    if (self.dataArray.count <= rowIndex)
    {
        return;
    }
    if (NO == [self removeFileWithPath:self.dataArray[rowIndex].filePath])
    {
        return;
    }
    
    [self.dataArray removeObjectAtIndex:indexPath.row];
    if (self.dataArray.count == 0)
    {
        [self showNoDataMessage];
    }
    [self.mainTableView reloadData];
}

#pragma mark -- 修改编辑按钮文字
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return DPLocalizedString(@"Title_Delete");
}


- (void)playRecordVideoWithPath:(NSString*)filePath
{
    if (!filePath || 0 >= filePath
        || NO == [self isFileExistAtPath:filePath])
    {
        return;
    }
    MPMoviePlayerViewController *mediaVC = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:filePath]];
    [self presentViewController:mediaVC animated:YES completion:^{
        
    }];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(movieFinishedCallback:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:mediaVC.moviePlayer];
}

-(void)movieFinishedCallback:(NSNotification*)notify
{
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationPortrait] forKey:@"orientation"];
    
    MPMoviePlayerController* theMovie = [notify object];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:theMovie];
    [theMovie.view removeFromSuperview];
}

#pragma mark -- 设置导航栏按钮
-(void)configNavItem
{
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    infoButton.frame = CGRectMake(0.0, 0.0, 75, 40);
    infoButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
//    infoButton.titleLabel.textAlignment = NSTextAlignmentRight;
    [infoButton setTitle:DPLocalizedString(@"editor")
                forState:UIControlStateNormal];
    [infoButton setTitleColor:[UIColor whiteColor]
                     forState:UIControlStateNormal];
    [infoButton addTarget:self
                   action:@selector(editStyle)
         forControlEvents:UIControlEventTouchUpInside];
    infoButton.exclusiveTouch = YES;
    UIBarButtonItem *infotemporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
    infotemporaryBarButtonItem.style = UIBarButtonItemStylePlain;
    self.rightNavButton = infoButton;
    self.navigationItem.rightBarButtonItem = infotemporaryBarButtonItem;
}



#pragma mark - Event Handle
- (void)editStyle
{
    if (self.editType == editTypeNormal)
    {
        if (self.dataArray.count == 0)
        {
            //没有数据，不进入编辑状态
            return;
        }
        [self enterEditingStyle];
    }
    else
    {
        //刷新数据
        for (MediaFileModel *model in self.dataArray)
        {
            model.selected = NO;
        }
        [self endEditingStyle];
    }
    [self.mainTableView reloadData];
}


- (void)enterEditingStyle
{
    //进入编辑状态
    self.editType = editTypeSelect;
    [self.rightNavButton setTitle:DPLocalizedString(@"Setting_edit_Cancel")
                         forState:UIControlStateNormal];
    self.editBottomView.hidden = NO;
}

- (void)endEditingStyle
{
    //结束编辑状态
    self.editType = editTypeNormal;
    [self.rightNavButton setTitle:DPLocalizedString(@"editor")
                         forState:UIControlStateNormal];
    self.editBottomView.hidden = YES;
}


- (void)allSelect
{
    self.allSelectBtn.selected = !self.allSelectBtn.selected;
    if (self.allSelectBtn.selected)
    {
        //全选
        [_allSelectBtn setTitleColor:[UIColor blackColor]
                            forState:UIControlStateNormal];
        [_allSelectBtn setTitle:DPLocalizedString(@"UnSelectAll")
                       forState:UIControlStateNormal];
        for (MediaFileModel *model in self.dataArray)
        {
            model.selected = YES;
        }
        [self.mainTableView reloadData];
    }
    else
    {
        //全不选
        [_allSelectBtn setTitleColor:[UIColor blackColor]
                            forState:UIControlStateNormal];
        [_allSelectBtn setTitle:DPLocalizedString(@"select_all")
                       forState:UIControlStateNormal];
        for (MediaFileModel *model in self.dataArray)
        {
            model.selected = NO;
        }
        [self.mainTableView reloadData];
    }
}


//取消全选状态
- (void)endAllSelect
{
    self.allSelectBtn.selected = NO;
    [self.allSelectBtn setTitleColor:[UIColor blackColor]
                            forState:UIControlStateNormal];
}


- (void)deleteAction
{
    int selectCount = 0;
    //删除操作
    for (MediaFileModel *model in self.dataArray)
    {
        if (model.isSelected)
        {
//            [self removeFileWithPath:model.filePath];
            selectCount++;
        }
    }
    
    //没选中删除不删除
    if (selectCount == 0)
    {
        return;
    }
    
    __weak typeof(self)weakSelf = self;
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:DPLocalizedString(@"tip")
                                                                       message:DPLocalizedString(@"DeleteFileTipMsg")
                                                                preferredStyle:UIAlertControllerStyleAlert];
    
    
    UIAlertAction *deleteActin = [UIAlertAction actionWithTitle:DPLocalizedString(@"Title_Delete")
                                                          style:UIAlertActionStyleDestructive
                                                        handler:^(UIAlertAction * _Nonnull action) {
                                                            
                                                            __strong typeof(weakSelf)strongSelf = weakSelf;
                                                            if (!strongSelf)
                                                            {
                                                                return ;
                                                            }
                                                            [strongSelf confirmDeleteAction];
                                                        }];
    
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:DPLocalizedString(@"Setting_Cancel")
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             
                                                         }];
    [alertView addAction:deleteActin];
    [alertView addAction:cancelAction];
    [self presentViewController:alertView
                       animated:YES
                     completion:nil];
}


- (void)confirmDeleteAction
{
    int selectCount = 0;
    //删除操作
    for (MediaFileModel *model in self.dataArray)
    {
        if (model.isSelected)
        {
            [self removeFileWithPath:model.filePath];
            selectCount++;
        }
    }
    
    if (selectCount > 0)
    {
        [self endEditingStyle];
        [self endAllSelect];
        
        //刷新数据
        if (selectTypeImage == self.selectType)
        {
            self.imageArray = [self getImageArray];
            self.dataArray  = self.imageArray;
        }
        else
        {
            self.videoArray = [self getVideoArray];
            self.dataArray  = self.videoArray;
        }
        
        if (self.dataArray.count == 0)
        {
            [self showNoDataMessage];
        }
        
        [self.mainTableView reloadData];
        
        [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"delete_file_success")];
    }
}


- (void)videoAction
{
    //切换到Video列表
    if (!self.videoBtn.selected)
    {
        self.selectType = selectTypeVideo;
        self.videoBtn.selected = YES;
        self.imageBtn.selected = NO;
        [_videoBtn setBackgroundImage:[UIImage imageNamed:@"btn_video_pressed"]
                             forState:UIControlStateNormal];
        [_imageBtn setBackgroundImage:[UIImage imageNamed:@"btn_picture_normal"]
                             forState:UIControlStateNormal];
        self.dataArray = self.videoArray;
        
        if (self.dataArray.count == 0)
        {
            [self showNoDataMessage];
        }
        [self.mainTableView reloadData];
    }
}


- (void)imageAction
{
    //切换到Image列表
    if (!self.imageBtn.selected)
    {
        self.videoBtn.selected = NO;
        self.selectType = selectTypeImage;
        self.imageBtn.selected = YES;
        [_videoBtn setBackgroundImage:[UIImage imageNamed:@"btn_video_normal"]
                             forState:UIControlStateNormal];
        [_imageBtn setBackgroundImage:[UIImage imageNamed:@"btn_picture_pressed"]
                             forState:UIControlStateNormal];
        self.dataArray = self.imageArray;
        if (self.dataArray.count == 0)
        {
            [self showNoDataMessage];
        }
        [self.mainTableView reloadData];
    }
}


#pragma mark -- Delete 数据源
- (BOOL)removeFileWithPath:(NSString *)filePath
{
    if (!filePath || 0 >= filePath.length)
    {
        return NO;
    }
    if (NO == [self isFileExistAtPath:filePath])
    {
        return NO;
    }
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:filePath error:&error];
    if (nil == error)
    {
        return YES;
    }
    return NO;
}


#pragma mark -- 判断文件是否存在
- (BOOL)isFileExistAtPath:(NSString *)filePath
{
    if (!filePath || 0 >= filePath.length)
    {
        return NO;
    }
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (NO == [fileManager fileExistsAtPath:filePath
                                 isDirectory:&isDir])
    {
        return NO;
    }
    if (NO == isDir)
    {
        return YES;
    }
    return NO;
}


#pragma mark - 获取数据源
- (NSMutableArray <MediaFileModel *> *)getImageArray
{
    NSMutableArray <MediaFileModel *>*videoArray;
    videoArray = [[MediaManager shareManager] mediaArrayWithDevId:[_deviceID stringByAppendingString:_model.selectedSubDevInfo.SubId?:@""]
                                                        mediaType:GosMediaSnapshot
                                                       deviceType:self.model.DeviceType
                                                         position:self.positionType];
    [videoArray sortUsingComparator:^NSComparisonResult(MediaFileModel  * obj1, MediaFileModel  * obj2) {
        NSString *fileName2 = [obj2.createDate stringByAppendingString:obj2.createTime];
        NSString *fileName1 = [obj1.createDate stringByAppendingString:obj1.createTime];

        return [fileName2 compare:fileName1];
//        return [obj2.fileName compare:obj1.fileName];
    }];
    return videoArray;
}


- (NSMutableArray <MediaFileModel *> *)getVideoArray
{
    NSMutableArray <MediaFileModel *>*videoArray;
    videoArray = [[MediaManager shareManager] mediaArrayWithDevId:_deviceID
                                                        mediaType:GosMediaRecord
                                                       deviceType:self.model.DeviceType
                                                         position:self.positionType];
    [videoArray sortUsingComparator:^NSComparisonResult(MediaFileModel  * obj1, MediaFileModel  * obj2) {
        NSString *fileName2 = [obj2.createDate stringByAppendingString:obj2.createTime];
        NSString *fileName1 = [obj1.createDate stringByAppendingString:obj1.createTime];
        return [fileName2 compare:fileName1];
//        return [obj2.fileName compare:obj1.fileName];
    }];
    return videoArray;
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

#pragma mark - showMessage
- (void)showNoDataMessage
{
    dispatch_async_on_main_queue(^{
        
        [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Record_NoRecordFile")];
        [SVProgressHUD dismissWithDelay:1];
    });
}

#pragma mark - Getter && setter

- (UITableView *)mainTableView
{
    if (!_mainTableView) {
        _mainTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT- 48 - 64) style:UITableViewStylePlain];
        _mainTableView.backgroundColor = [UIColor clearColor];
        _mainTableView.backgroundView  = nil;
        _mainTableView.separatorStyle  = UITableViewCellSeparatorStyleSingleLine;
        _mainTableView.delegate        = self;
        _mainTableView.dataSource      = self;
        _mainTableView.tableFooterView = [UIView new];
    }
    return _mainTableView;
}

- (UIView *)bottomView
{
    if (!_bottomView)
    {
        _bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - 48, SCREEN_WIDTH, 48)];
        _bottomView.backgroundColor = UIColorFromRGBA(238, 238, 238, 1.0f);
    }
    return _bottomView;
}

- (UIView *)editBottomView
{
    if (!_editBottomView)
    {
        _editBottomView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - 48, SCREEN_WIDTH, 48)];
        _editBottomView.hidden = YES;
        _editBottomView.backgroundColor = UIColorFromRGBA(238, 238, 238, 1.0f);
    }
    return _editBottomView;
}


- (UIButton *)allSelectBtn
{
    if (!_allSelectBtn)
    {
        _allSelectBtn = [[EnlargeClickButton alloc] initWithFrame:CGRectMake(45, 15, 80, 21)];
        [_allSelectBtn addTarget:self
                          action:@selector(allSelect)
                forControlEvents:UIControlEventTouchUpInside];
        [_allSelectBtn setTitle:DPLocalizedString(@"select_all")
                       forState:UIControlStateNormal];
        _allSelectBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
//        [_allSelectBtn setTitleColor:UIColorFromRGBA(185, 185, 185, 1.0f) forState:UIControlStateNormal];
        [_allSelectBtn setTitleColor:[UIColor blackColor]
                            forState:UIControlStateNormal];
    }
    return _allSelectBtn;
}

- (UIButton *)deleteBtn
{
    if (!_deleteBtn)
    {
        _deleteBtn = [[EnlargeClickButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 45 - 70, 15, 70, 21)];
        [_deleteBtn addTarget:self
                       action:@selector(deleteAction)
             forControlEvents:UIControlEventTouchUpInside];
        [_deleteBtn setTitle:DPLocalizedString(@"Title_Delete")
                    forState:UIControlStateNormal];
        _deleteBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_deleteBtn setTitleColor:[UIColor blackColor]
                         forState:UIControlStateNormal];
    }
    return _deleteBtn;
}

- (EnlargeClickButton *)videoBtn{
    if (!_videoBtn) {
        _videoBtn = [[EnlargeClickButton alloc] initWithFrame:CGRectMake(45, 5, 25, 21)];
        [_videoBtn addTarget:self
                      action:@selector(videoAction)
            forControlEvents:UIControlEventTouchUpInside];
        [_videoBtn setBackgroundImage:[UIImage imageNamed:@"btn_video_pressed"]
                             forState:UIControlStateNormal];
        _videoBtn.selected = YES;
    }
    return _videoBtn;
}

- (EnlargeClickButton *)imageBtn
{
    if (!_imageBtn)
    {
        _imageBtn = [[EnlargeClickButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 45 - 25 , 5, 25, 21)];
        [_imageBtn addTarget:self
                      action:@selector(imageAction)
            forControlEvents:UIControlEventTouchUpInside];
        [_imageBtn setBackgroundImage:[UIImage imageNamed:@"btn_picture_normal"]
                             forState:UIControlStateNormal];
        _imageBtn.selected = NO;
    }
    return _imageBtn;
}

- (UILabel *)videoLabel{
    if (!_videoLabel) {
        _videoLabel = [[UILabel alloc]initWithFrame:CGRectMake(45 - 12, 28, 50, 15)];
        _videoLabel.text          = DPLocalizedString(@"Video");
        _videoLabel.textColor     = [UIColor blackColor];
        _videoLabel.font          = [UIFont systemFontOfSize:12];
        _videoLabel.textAlignment = NSTextAlignmentCenter;
        UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(videoAction)];
        [_videoLabel addGestureRecognizer:tapGes];
    }
    return _videoLabel;
}

- (UILabel *)photoLabel
{
    if (!_photoLabel)
    {
        _photoLabel = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 45 - 25 - 12, 28, 50, 15)];
        _photoLabel.text          = DPLocalizedString(@"pic");
        _photoLabel.textColor     = [UIColor blackColor];
        _photoLabel.font          = [UIFont systemFontOfSize:12];
        _photoLabel.textAlignment = NSTextAlignmentCenter;
        UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(imageAction)];
        [_photoLabel addGestureRecognizer:tapGes];
    }
    return _photoLabel;
}


- (NSMutableArray <MediaFileModel *>*)dataArray
{
    if (!_dataArray)
    {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}

@end
