//
//  PushMsgViewController.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/12.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "PushMsgViewController.h"
#import "PushMessageModel.h"
#import "PushMsgTableViewCell.h"
#import "PushMsgCtrlTableViewCell.h"
#import "PushSettingViewController.h"
#import "PushMessageManagement.h"
#import "MJPhotoBrowser.h"
#import <Masonry.h>
#import <RESideMenu.h>
#import "PersonalCenterViewController.h"
#import "APNSManager.h"
#import "DeviceManagement.h"
#import "CloudServiceOrderInfoVC.h"
#import <AFNetworking.h>
#import "CloudPlayBackViewController.h"
#import "CloudSDCardViewController.h"
#import "DeviceDataModel.h"
#import "SaveDataModel.h"
#import "GOSLivePlayerVC.h"

#define SECTION_HEIGHT 17.0f

#define CELL_HEIGHT 50.0f
#define SELECT_ALL_BUTTON_WIDTH 120.0f
#define DELETE_BUTTON_WIDTH 120.0f
#define BUTTON_MARGIN 20.0f

#define BOTTOM_VIEW_ANIMATION_DURATION 0.25f


@interface PushMsgViewController () <
                                        UITableViewDelegate,
                                        UITableViewDataSource
                                    >
{
    BOOL _isHiddenEtditButton;          // 没有推送消息时，隐藏编辑按钮
    /**
     *  是否‘编辑’模式下 （编辑 <--->常态）
     */
    BOOL _isEditModel;
    
    /**
     *  是否全选
     */
    BOOL _isSelectAll;
    
    /**
     *  是否正在执行删除操作
     */
    BOOL _isDeleting;
    
    BOOL _isAddRightBarItem;
}

@property (weak, nonatomic) IBOutlet UITableView *pushMsgTableView;

@property (nonatomic, strong) NSMutableArray <PushMessageModel *>*pushMsgArray;

///**
// *  选择删除按钮数组(根据推送时间判断删除)
// */
//@property (nonatomic, strong) NSMutableArray <PushMessageModel *>*selectDeleteBtnArray;

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

/**云存储服务是否在有效期内*/
@property(nonatomic,assign) BOOL csValid;

/** 请求CS状态失败 重新请求 */
@property(nonatomic,assign) BOOL requestCSStatusSuccesfully;

@end

@implementation PushMsgViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = DPLocalizedString(@"Message");
    
    _isHiddenEtditButton = NO;
    
    [self getPushDataFromDB];
    
    [self configTableView];
    
    __weak typeof(self)weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        [strongSelf addBarButtonItems];
        
        [strongSelf addBottomDeleteView];
        
        [strongSelf addNewPushMsgNotify];
    });
    
    [self addLeftBarButtonItem];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.pushMsgTableView reloadData];

    _isEditModel = NO;
    _isSelectAll = NO;
    _isDeleting  = NO;
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}


- (void)dealloc
{
    NSLog(@"PushMsgViewController --- dealloc ---");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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


- (UIButton *)rightBarButton
{
    if (!_rightBarButton)
    {
        _rightBarButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _rightBarButton.frame = CGRectMake(0, 0, 120, 40);
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
        _deleteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        [_deleteButton addTarget:self
                          action:@selector(deleteButtonAction)
                forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteButton;
}


#pragma mark -- 选择删除按钮数组
//- (NSMutableArray <PushMessageModel *>*)selectDeleteBtnArray
//{
//    if (!_selectDeleteBtnArray)
//    {
//        _selectDeleteBtnArray = [[NSMutableArray alloc] initWithCapacity:0];
//    }
//    
//    return _selectDeleteBtnArray;
//}


#pragma mark -- 从数据库读取推送消息
- (void)getPushDataFromDB
{
    NSMutableArray *pushMessageArray = [[PushMessageManagement sharedInstance] pushMessageArray];
    //筛选数据--只留下当前设备的数据
    NSMutableArray *currentPushArray = [NSMutableArray array];
    for (PushMessageModel *model in pushMessageArray) {
        NSLog(@"_______push_devName:%@",model.deviceName);
        BOOL isExist = NO;
        for (DeviceDataModel *dataModel in [[DeviceManagement sharedInstance] deviceListArray]) {
            if ([dataModel.DeviceId isEqualToString:model.deviceId] ) {
                
                if ( self.subId.length > 0 ) {
                    isExist = [self.subId isEqualToString: model.subDeviceID];
                }else{
                    isExist = YES;
                }
                
                //刷新名字，没有子设备则代表之前的5100 中继
                if ( dataModel.SubDevice.count > 0 ) {
                    for (SubDevInfoModel *subInfo in dataModel.SubDevice ) {
                        if ([subInfo.SubId isEqualToString:model.subDeviceID]) {
                            
                            model.deviceName = subInfo.ChanName;
                        }
                    }
                }else{
                    model.deviceName = dataModel.DeviceName;
                }
                break;
            }
        }
        if (isExist) {
            if (self.deviceID) {
                if ([self.deviceID isEqualToString:model.deviceId]) {
                    [currentPushArray addObject:model];;
                }
            }else{
                [currentPushArray addObject:model];
            }

        }
    }
    self.pushMsgArray = currentPushArray;
    
}


- (void)addBarButtonItems
{
    [self addLeftBarButtonItem];
    
    if (0 < self.pushMsgArray.count)
    {
        [self addRightBarButtonItem];
        _isAddRightBarItem = YES;
    }
}


#pragma mark -- 添加左 item
- (void)addLeftBarButtonItem
{
    UIImage *image = [UIImage imageNamed:@"addev_back"];
    EnlargeClickButton *button = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 70, 40);
    button.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 50);
    [button setImage:image forState:UIControlStateNormal];
    if (self.isPushedIn) {
        [button addTarget:self
                   action:@selector(navback)
         forControlEvents:UIControlEventTouchUpInside];
    }
    else{
        [button addTarget:self
                   action:@selector(presentLeftMenuViewController:)
         forControlEvents:UIControlEventTouchUpInside];
    }

    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    leftBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
}

- (void)navback{
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark -- 添加右 item
- (void)addRightBarButtonItem
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法添加 rightBarItem ！");
            return ;
        }
        UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:strongSelf.rightBarButton];
        rightBarButtonItem.style = UIBarButtonItemStylePlain;
        strongSelf.navigationItem.rightBarButtonItem = rightBarButtonItem;
    });
}


#pragma mark - 按钮事件
#pragma mark -- ’编辑/取消‘按钮事件
- (void)rightBarButtonAction
{
    _isEditModel = !_isEditModel;
    
    [self showBottomDeleteView:_isEditModel];
    
    [self changeRightBarTitle:_isEditModel];
    
    [self showDeleteButtonn:_isEditModel WithTableView:self.pushMsgTableView];
    
    [self setDeleteButtonShow:_isEditModel];
    
    [self changeSelectAllButtonTitle:YES];
    
    if (NO == _isEditModel)
    {
        [self selectAllMsgToDelete:NO];
        _isSelectAll = NO;
    }
}


#pragma mark -- ’全选/取消全选‘按钮事件
- (void)selectAllButtonAction
{
    _isSelectAll = !_isSelectAll;
    [self selectAllMsgToDelete:_isSelectAll];
    [self changeSelectAllButtonTitle:!_isSelectAll];
}


#pragma mark -- ’删除‘按钮事件
- (void)deleteButtonAction
{

    NSMutableArray *selectDeleteBtnArray = [NSMutableArray array];
    for (PushMessageModel *model in self.pushMsgArray) {
        if (model.isSelectDelete) {
            [selectDeleteBtnArray addObject:model];
        }
    }
    
    //没选中不删除的不操作
    if (selectDeleteBtnArray.count == 0) {
        return;
    }
    
    _isDeleting = YES;
    __weak typeof(self)weskSelf = self;
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:DPLocalizedString(@"tip")
                                                                       message:DPLocalizedString(@"DeletePushMsgTipMsg")
                                                                preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *deleteActin = [UIAlertAction actionWithTitle:DPLocalizedString(@"Title_Delete")
                                                          style:UIAlertActionStyleDestructive
                                                        handler:^(UIAlertAction * _Nonnull action) {
                                                            
                                                            __strong typeof(weskSelf)strongSelf = weskSelf;
                                                            if (!strongSelf)
                                                            {
                                                                NSLog(@"对象丢失，无法删除推送消息！");
                                                                return ;
                                                            }
                                                            [strongSelf deleteSelectedPushMsg];
                                                            //取消编辑模式
                                                            [self rightBarButtonAction];
                                                        }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:DPLocalizedString(@"Setting_Cancel")
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             
                                                             __strong typeof(weskSelf)strongSelf = weskSelf;
                                                             if (!strongSelf)
                                                             {
                                                                 NSLog(@"对象丢失，无法删除推送消息！");
                                                                 return ;
                                                             }
                                                             strongSelf->_isDeleting = NO;
                                                         }];
    [alertView addAction:deleteActin];
    [alertView addAction:cancelAction];
    [self presentViewController:alertView
                       animated:YES
                     completion:nil];
}


#pragma mark -- 删除已选择推送消息
- (void)deleteSelectedPushMsg
{
    NSMutableArray *selectDeleteBtnArray = [NSMutableArray array];
    for (PushMessageModel *model in self.pushMsgArray) {
        if (model.isSelectDelete) {
            [selectDeleteBtnArray addObject:model];
        }
    }
    NSMutableArray <NSIndexPath *>*indexPathArray = [[NSMutableArray alloc] initWithCapacity:0];
    for (int i = 0; i < selectDeleteBtnArray.count; i++)
    {
        PushMessageModel *deleteMsgModel = selectDeleteBtnArray[i];
        for (int j = 0; j < self.pushMsgArray.count; j++)
        {
            PushMessageModel *sourceMsgModel = self.pushMsgArray[j];
            if (![deleteMsgModel.pushTime isEqualToString:sourceMsgModel.pushTime])
            {
                continue;
            }
            [indexPathArray addObject:[NSIndexPath indexPathForRow:j
                                                         inSection:1]];
            [[PushMessageManagement sharedInstance] deletePushMessage:sourceMsgModel];
            break;
        }
    }
    [self.pushMsgArray removeObjectsInArray:selectDeleteBtnArray];
    [selectDeleteBtnArray removeAllObjects];
    
    //直接重新刷新
    [self.pushMsgTableView reloadData];
    _isDeleting = NO;
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
            [strongSelf.rightBarButton setTitle:DPLocalizedString(@"editor")
                                       forState:UIControlStateNormal];
        }
        else
        {
            [strongSelf.rightBarButton setTitle:DPLocalizedString(@"Setting_edit_Cancel")
                                       forState:UIControlStateNormal];
        }
    });
}


#pragma mark -- 修改按钮标题‘全选/反全选’
- (void)changeSelectAllButtonTitle:(BOOL)isSelectAll
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        if (NO == isSelectAll)
        {
            [strongSelf.selectAllButton setTitle:DPLocalizedString(@"UnSelectAll")
                                        forState:UIControlStateNormal];
        }
        else
        {
            [strongSelf.selectAllButton setTitle:DPLocalizedString(@"select_all")
                                        forState:UIControlStateNormal];
        }
    });
}


#pragma mark -- 全选/反全选
- (void)selectAllMsgToDelete:(BOOL)isSelectAll
{    
    [self setAllCellIsDelete:isSelectAll];
}





#pragma mark -- 设置全部按钮是否选择删除
- (void)setAllCellIsDelete:(BOOL)isDelete
{
    for (int i = 0; i < self.pushMsgArray.count; i++)
    {
        PushMessageModel *tempModel = [self.pushMsgArray objectAtIndex:i];
        tempModel.isSelectDelete = isDelete;
        [self.pushMsgTableView reloadData];
    }
}


#pragma mark -- 添加新推送通知
- (void)addNewPushMsgNotify
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(insertNewPushMsg:)
                                                 name:NEW_APNS_NOTIFY
                                               object:nil];
}


- (void)insertNewPushMsg:(NSNotification *)pushData
{
    if (YES == _isDeleting)
    {
        NSLog(@"正在执行删除操作，新推送消息不展示！");
        return;
    }
    if (NO == _isAddRightBarItem)
    {
        [self addRightBarButtonItem];
        _isAddRightBarItem = YES;
    }
    PushMessageModel *newPushMsg = (PushMessageModel *)pushData.object;
    newPushMsg.isShowDelete   = _isEditModel;
    newPushMsg.isSelectDelete = _isSelectAll;
    
    if (self.deviceID) {
        // 非当前中继器或子设备时 都跳过
        if (![newPushMsg.deviceId isEqualToString:self.deviceID]
            || ![newPushMsg.subDeviceID isEqualToString:self.subId]) {
            return;
        }
    }

    
    NSLog(@"新推送通知：%@", newPushMsg.pushUrl);
    [self.pushMsgArray insertObject:newPushMsg
                            atIndex:0];
    
    [NSThread sleepForTimeInterval:0.1];
    
    //直接重新刷新
    [self.pushMsgTableView reloadData];
    if (YES == _isHiddenEtditButton)
    {
        [self addRightBarButtonItem];
    }
}


#pragma mark - UI 约束
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
        
        [self.pushMsgTableView mas_updateConstraints:^(MASConstraintMaker *make) {
            
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
        
        [self.pushMsgTableView mas_updateConstraints:^(MASConstraintMaker *make) {
            
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                return ;
            }
            make.bottom.equalTo(strongSelf.view.mas_bottom).offset(-CELL_HEIGHT);
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



#pragma mark -- 显示/隐藏选择按钮
#pragma mark -- 隐藏所有删除按钮图标
- (void)showDeleteButtonn:(BOOL)isShow
            WithTableView:(UITableView *)tableView
{
    if (!tableView)
    {
        return;
    }
    NSInteger rows =  [tableView numberOfRowsInSection:1];
    for (int rowIndex = 0; rowIndex < rows; rowIndex++)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIndex
                                                    inSection:1];
        PushMsgTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [cell showDeleteButton:isShow];
    }
}


#pragma mark -- 设置数据源选择删除按钮是否显示
- (void)setDeleteButtonShow:(BOOL)isShow
{
    for (int i = 0; i < self.pushMsgArray.count; i++)
    {
        PushMessageModel *tempModel = [self.pushMsgArray objectAtIndex:i];
        tempModel.isShowDelete = isShow;
        [self.pushMsgArray replaceObjectAtIndex:i
                                     withObject:tempModel];
    }
}


#pragma mark -- 设置 TableView 约束
- (void)configTableViewUI
{
    __weak typeof(self)weakSelf = self;
    [self.pushMsgTableView mas_updateConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        make.left.equalTo(strongSelf.view.mas_left);
        make.top.equalTo(strongSelf.view.mas_top);
        make.right.equalTo(strongSelf.view.mas_right);
        make.bottom.equalTo(strongSelf.view.mas_bottom).offset(0);
    }];
}


#pragma mark -- 设置 tableView
- (void)configTableView
{
    // 设置约束
    [self configTableViewUI];
    
    // 删除tableView多余分割线
    [self.pushMsgTableView setTableFooterView:[[UIView alloc]initWithFrame:CGRectZero]];
    
    self.pushMsgTableView.backgroundColor = UIColorFromRGBA(238.0f, 238.0f, 238.0f, 1.0f);
    
    [self setRowHeight];
}


#pragma mark -- 设置 cell 高度
- (void)setRowHeight
{
    self.pushMsgTableView.rowHeight = CELL_HEIGHT;
}



#pragma mark -- TaleView delegate && datasource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (0 == section)
    {
        return 1;
    }
    else
    {
        return self.pushMsgArray.count;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (0 == section)
    {
        return SECTION_HEIGHT;
    }
    else
    {
        return 0.0f;
    }
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (0 == section)
    {
        UIView * view =[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, SECTION_HEIGHT)];
        view.backgroundColor = UIColorFromRGBA(238.0f, 238.0f, 238.0f, 1.0f);
        return view;
    }
    else
    {
        return nil;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionIndex = indexPath.section;
    NSInteger rowIdex      = indexPath.row;
    if (0 == sectionIndex)
    {
        NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([PushMsgCtrlTableViewCell class])
                                                          owner:self
                                                        options:nil];
        PushMsgCtrlTableViewCell *cell = nibArray[0];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        
        return cell;
    }
    else
    {
        static NSString *pushMsgListCellId = @"pushMsgListCellIdentify";
        
        PushMsgTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:pushMsgListCellId];
        if (!cell)
        {
            NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([PushMsgTableViewCell class])
                                                              owner:self
                                                            options:nil];
            cell = nibArray[0];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
//        if (rowIdex < self.pushMsgArray.count)
//        {
            cell.pushMsgCellData = [self.pushMsgArray objectAtIndex:rowIdex];
//        }
        
        return cell;
    }
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
    NSInteger sectionIndex = indexPath.section;
    NSInteger rowIdex      = indexPath.row;
    if (_isEditModel) {
        if (sectionIndex == 1) {
            int row = (int)(indexPath.row);
            PushMessageModel *model = self.pushMsgArray[row];
            model.isSelectDelete = !model.isSelectDelete;
            [tableView reloadData];
            return;
        }
    }


    if (0 == sectionIndex && 0 == rowIdex)
    {
        
        if (_isEditModel) {
            //退出编辑模式
            [self rightBarButtonAction];
        }
        
        PushSettingViewController *pushSettingVC = [[PushSettingViewController alloc] init];
        if (pushSettingVC)
        {
            [self.navigationController pushViewController:pushSettingVC
                                                 animated:YES];
        }
    }
    else if (1 == sectionIndex)
    {
        if (rowIdex >= [self.pushMsgArray count])
        {
            NSLog(@"数据越界，推送消息无法查看！");
            return;
        }
        PushMessageModel *pushMsgModel = self.pushMsgArray[rowIdex];
        pushMsgModel.apnsMsgReadState = APNSMsgReaded;
        [[PushMessageManagement sharedInstance] updateReadState:pushMsgModel];
        RESideMenu *resideMenu = (RESideMenu *)[UIApplication sharedApplication].keyWindow.rootViewController;
        if ([resideMenu isKindOfClass:[RESideMenu class]]) {
            PersonalCenterViewController *personVC = (PersonalCenterViewController *)resideMenu.leftMenuViewController;
            if ([personVC isKindOfClass:[PersonalCenterViewController class]]) {
                APNSManager *apnsManager = [APNSManager shareManager];
                apnsManager.pushDeviceModel = pushMsgModel;
                //回首页

                DeviceDataModel *devModel = [self getCurDevModelWithPushMsg:pushMsgModel];
                if (devModel) { //devModel.hasCloudPlay门铃全部支持云存储不判断
                    
                    if (pushMsgModel.apnsMsgType == APNSMsgBellRing &&[self isBellRingEventRealWithTime:[self timeWithTimeStr:pushMsgModel.pushTime]]  ) {
                        GOSLivePlayerVC *playerVC = [[GOSLivePlayerVC alloc] init];
                        playerVC.deviceModel = devModel;
                        [self.navigationController pushViewController:playerVC animated:YES];
                    }else{
                        [self getCSStatusWithDevID:pushMsgModel.deviceId];
                    }
//                    [self getCSStatusWithDevID:pushMsgModel.deviceId];
                }
                else{
                    //老设备
                    [personVC backToFirstView];
                }

            }
            else{
                return;
            }
        }
    }
}

- (void)getCSStatusWithDevID:(NSString*)devID{
    
    [SVProgressHUD showWithStatus:@"Loading..."];
    
    NSString *getUrl = [NSString stringWithFormat:@"http://%@/api/cloudstore/cloudstore-service/service/data-valid",kCloud_IP];
    [[AFHTTPSessionManager manager] GET:getUrl parameters:@{@"token" : [mUserDefaults objectForKey:USER_TOKEN],@"device_id" :devID ,@"username":[SaveDataModel getUserName],@"version":@"1.0" } progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //获取套餐时长数据
        NSArray *dataArray = responseObject[@"data"];
        if ([dataArray isKindOfClass:[NSArray class]]) {
            if (dataArray.count >0) {
                self.csValid = YES;
            }
            else{
                self.csValid = NO;
            }
        }
        else{
            self.csValid = NO;
        }
        self.requestCSStatusSuccesfully = YES;
        [self showOperationResult];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        //TODO:添加重新加载按钮
        self.requestCSStatusSuccesfully = NO;
        [self showOperationResult];
    }];
}

- (void)showOperationResult{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.requestCSStatusSuccesfully) {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"network_error")];
            return ;
        }else{
            [SVProgressHUD dismiss];
        }
        
        
        PushMessageModel *pushModel = [APNSManager shareManager].pushDeviceModel;
        NSTimeInterval time = [self timeWithTimeStr: pushModel.pushTime];
        DeviceDataModel *devModel = [self getCurDevModelWithPushMsg:pushModel];
        [APNSManager shareManager].pushDeviceModel = nil; //置空
        
        if (!devModel) {
            return;
        }
        
        
        if (self.csValid) {//CS
            CloudPlayBackViewController *vc = [CloudPlayBackViewController new];
            vc.deviceModel                  = devModel;
            vc.alarmMsgTime                 = time;
            [self.navigationController pushViewController:vc animated:YES];
        }else{//TF
            CloudSDCardViewController *vc   = [CloudSDCardViewController new];
            vc.deviceModel                  = devModel;
            vc.alarmMsgTime                 = time;
            [self.navigationController pushViewController:vc animated:YES];
        }
    });
}

//按铃是否是180S以内发生的实时事件
- (BOOL)isBellRingEventRealWithTime:(NSTimeInterval)alarmEventTime{
    BOOL isReal = NO;
    
    NSDate *date = [NSDate date];
    NSTimeInterval curTime = [date timeIntervalSince1970];
    NSLog(@"isBellRingEventRealWithTime:%f",curTime - alarmEventTime );
    
    isReal = curTime - alarmEventTime < 180;
    return isReal;
}

-(DeviceDataModel*)getCurDevModelWithPushMsg:(PushMessageModel*)pushMsg{
    for (DeviceDataModel *dataModel in [[DeviceManagement sharedInstance] deviceListArray]) {
        if ([dataModel.DeviceId isEqualToString:pushMsg.deviceId]) {
            
            if (dataModel.SubDevice.count > 0) {
                for (SubDevInfoModel *subInfo in dataModel.SubDevice) {
                    if ([subInfo.SubId isEqualToString: pushMsg.subDeviceID] || subInfo.ChanNum== pushMsg.subChannel ) {
                        dataModel.selectedSubDevInfo = subInfo;
                        break;
                    }
                }
            }
            
            return dataModel;
        }
    }
    return nil;
}

- (NSTimeInterval)timeWithTimeStr:(NSString*)timeStr{

    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [format setTimeZone:[NSTimeZone defaultTimeZone]];
    NSDate *date = [format dateFromString:timeStr];
    
    return [date timeIntervalSince1970];
}

#pragma mark -- 删除推送消息
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (_isEditModel) {
        return NO;
    }
    
    NSInteger sectionIndex = indexPath.section;
    if (0 == sectionIndex)
    {
        return NO;
    }
    else if (1 == sectionIndex)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionIndex = indexPath.section;
    if (0 == sectionIndex)
    {
        return UITableViewCellEditingStyleNone;
    }
    else if (1 == sectionIndex)
    {
        return UITableViewCellEditingStyleDelete;
    }
    else
    {
        return UITableViewCellEditingStyleNone;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionIndex = indexPath.section;
    if (0 == sectionIndex)
    {
        return nil;
    }
    else if (1 == sectionIndex)
    {
        return DPLocalizedString(@"Title_Delete");
    }
    else
    {
        return nil;
    }
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionIndex = indexPath.section;
    NSInteger rowIdex      = indexPath.row;
    if (1 != sectionIndex)
    {
        return;
    }
    if (UITableViewCellEditingStyleDelete == editingStyle)
    {
        if (rowIdex >= self.pushMsgArray.count)
        {
            NSLog(@"删除推送消息数组越界，无法删除！");
            return;
        }
        PushMessageModel *deleteModel = self.pushMsgArray[rowIdex];
        [self.pushMsgArray removeObjectAtIndex:rowIdex];
        [[PushMessageManagement sharedInstance] deletePushMessage:deleteModel];
        [tableView deleteRowsAtIndexPaths:@[indexPath]
                         withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


- (void)showPushPhotoWithModel:(PushMessageModel *)pushMsgModel
{
    if (!pushMsgModel || IS_STRING_EMPTY(pushMsgModel.pushUrl))
    {
        NSLog(@"无法查看推送消息");
        return;
    }
    
    NSMutableArray *photoArray = [NSMutableArray array];
    MJPhotoBrowser *photoBrowser = [[MJPhotoBrowser alloc] init];
    MJPhoto *photo = [[MJPhoto alloc] init];
    NSString *imageURL = pushMsgModel.pushUrl;
    photo.url = [NSURL URLWithString:imageURL];
    [photoArray addObject:photo];
    photoBrowser.photos = photoArray;
    photoBrowser.currentPhotoIndex = 0;
    [photoBrowser show];
}


- (BOOL)shouldAutorotate
{
    return NO;
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


@end
