//
//  NvrPushMsgView.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/14.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "NvrPushMsgView.h"
#import "NvrPushMsgTableViewCell.h"
#import <Masonry.h>

/** NVR 推送消息列表 cell 高度 */
#define NVR_PUSH_MSG_CELL_HEIGHT 60.0f


@interface NvrPushMsgView ()    <
                                    UITableViewDataSource
                                >
@property (nonatomic, strong) UIView *noPushMsgBGView;

@property (nonatomic, strong) UIImageView *noPushMsgImageView;

@property (nonatomic, strong) UILabel *noPushMsgLabel;

@end


@implementation NvrPushMsgView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.pushMsgTableView                = [[UITableView alloc] init];
        self.pushMsgTableView.rowHeight      = NVR_PUSH_MSG_CELL_HEIGHT;
        self.pushMsgTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.pushMsgTableView.dataSource     = self;
        
        self.noPushMsgBGView                 = [[UIView alloc] init];
        self.noPushMsgImageView              = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NoPushMsg"]];
        self.noPushMsgLabel                  = [[UILabel alloc] init];
        self.noPushMsgLabel.textAlignment    = NSTextAlignmentCenter;
        self.noPushMsgLabel.textColor        = [UIColor lightGrayColor];
        self.noPushMsgLabel.font             = [UIFont systemFontOfSize:16];
        self.noPushMsgLabel.text             = DPLocalizedString(@"NoPushMessage");
        
        [self addSubview:self.pushMsgTableView];
        [self addSubview:self.noPushMsgBGView];
        [self.noPushMsgBGView addSubview:self.noPushMsgImageView];
        [self.noPushMsgBGView addSubview:self.noPushMsgLabel];
        
        [self configPushMsgTableView];
        [self configNoPushMsgBGView];
        [self configNoPushMsgImageView];
        [self configNoPushMsgViewHidden:YES];
        [self configNoPushMsgLabel];
        
        [self addNewPushMsgNotify];
    }
    return self;
}


#pragma mark -- 懒加载
//- (NSMutableArray<PushMessageModel *> *)pushMsgDataArray
//{
//    if (!_pushMsgDataArray)
//    {
//        _pushMsgDataArray = [NSMutableArray arrayWithCapacity:0];
//    }
//    return _pushMsgDataArray;
//}


#pragma mark -- 适配 NVR 推送消息 TableView
- (void)configPushMsgTableView
{
    __weak typeof(self)weakSelf = self;
    [self.pushMsgTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NVR 推送消息 TableView");
            return ;
        }
        make.left.mas_equalTo(strongSelf.mas_left);
        make.top.mas_equalTo(strongSelf.mas_top);
        make.right.mas_equalTo(strongSelf.mas_right);
        make.bottom.mas_equalTo(strongSelf.mas_bottom);
    }];
}


#pragma mark -- 适配 NO push msg bg view
- (void)configNoPushMsgBGView
{
    __weak typeof(self)weakSelf = self;
    [self.noPushMsgBGView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NO push msg bg view");
            return ;
        }
        make.left.mas_equalTo(strongSelf.mas_left);
        make.top.mas_equalTo(strongSelf.mas_top);
        make.right.mas_equalTo(strongSelf.mas_right);
        make.bottom.mas_equalTo(strongSelf.mas_bottom);
    }];
}


#pragma mark -- 适配 NO push msg image view
- (void)configNoPushMsgImageView
{
    __weak typeof(self)weakSelf = self;
    [self.noPushMsgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NO push msg image view");
            return ;
        }
        make.centerX.mas_equalTo(strongSelf.noPushMsgBGView.mas_centerX);
        make.centerY.mas_equalTo(strongSelf.noPushMsgBGView.mas_centerY);
        make.width.mas_equalTo(strongSelf.noPushMsgBGView.mas_width).multipliedBy(0.3f);
        make.height.mas_equalTo(strongSelf.noPushMsgImageView.mas_width).multipliedBy(0.93f);
    }];
}


#pragma mark -- 适配 NO push msg label
- (void)configNoPushMsgLabel
{
    __weak typeof(self)weakSelf = self;
    [self.noPushMsgLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法适配 NVR 推送消息 TableView");
            return ;
        }
        make.centerX.mas_equalTo(strongSelf.noPushMsgBGView.mas_centerX);
        make.top.mas_equalTo(strongSelf.noPushMsgImageView.mas_bottom).offset(5);
        make.width.mas_equalTo(strongSelf.noPushMsgBGView.mas_width);
    }];
}


- (void)configNoPushMsgViewHidden:(BOOL)isHidden
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法设置录像提示 Label 是否显示！");
            return ;
        }
        strongSelf.noPushMsgBGView.hidden = isHidden;
    });
}


#pragma mark -- 添加新推送通知
- (void)addNewPushMsgNotify
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(insertNewPushMsg:)
                                                 name:NEW_APNS_NOTIFY
                                               object:nil];
}


#pragma mark -- 插入新推送
- (void)insertNewPushMsg:(NSNotification *)pushData
{
    PushMessageModel *newPushMsg = (PushMessageModel *)pushData.object;
    if (![self.deviceId isEqualToString:newPushMsg.deviceId])
    {
//        NSLog(@"新推送消息不是该设备的，不插入！");
        return;
    }
    NSLog(@"新推送通知：%@", newPushMsg.pushUrl);
    [self.pushMsgDataArray insertObject:newPushMsg
                            atIndex:0];
    
    [NSThread sleepForTimeInterval:0.05];
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        [strongSelf.pushMsgTableView beginUpdates];
        [strongSelf.pushMsgTableView insertRowsAtIndexPaths:@[
                                                              [NSIndexPath indexPathForRow:0
                                                                                 inSection:0]
                                                              ]
                                              withRowAnimation:UITableViewRowAnimationAutomatic];
        [strongSelf.pushMsgTableView endUpdates];
        
        NvrPushMsgTableViewCell *cell = [strongSelf.pushMsgTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1
                                                                                                              inSection:0]];
        [cell upLineViewHidden:NO];
    });
    [self configNoPushMsgViewHidden:YES];
}


#pragma mark -- UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    if (self.pushMsgDataArray)
    {
        return self.pushMsgDataArray.count;
    }
    else
    {
        return 0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *nvrPushMsgCellId = @"NvrPushMessageCellId";
    NSInteger rowIndex = indexPath.row;
    NvrPushMsgTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nvrPushMsgCellId];
    if (!cell)
    {
        NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"NvrPushMsgTableViewCell"
                                                          owner:self
                                                        options:nil];
        cell = nibArray[0];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (self.pushMsgDataArray.count > rowIndex)
    {
        cell.pushMsgCellData = [self.pushMsgDataArray objectAtIndex:rowIndex];
    }
    if (0 == rowIndex)  // 第一行
    {
        [cell upLineViewHidden:YES];
    }
    if (self.pushMsgDataArray.count == rowIndex + 1)    // 最后一行
    {
        [cell downLineViewHidden:YES];
    }
    return cell;
}


@end
