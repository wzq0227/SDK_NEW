//
//  PushMsgTableViewCell.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/12.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "PushMsgTableViewCell.h"
#import "EnlargeClickButton.h"

#define DELETE_IMAGE_LEFT_MARGIN 48.0f      // 删除时 左边距
#define DEFAULT_IMAGE_LEFT_MARGIN 15.0f     // 常规下 左边距


@interface PushMsgTableViewCell ()
{
    /**
     *  是否显示选择按钮
     */
    BOOL _isShowDeleteButton;
    /**
     *  是否选择删除
     */
    BOOL _isSelectDelete;
    
    PushMessageModel *_pushMsgData;
}
@property (weak, nonatomic) IBOutlet UIImageView *msgIconImageView;
@property (weak, nonatomic) IBOutlet UIImageView *readStateImageView;
@property (weak, nonatomic) IBOutlet UILabel *devNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *msgTimeLabel;
@property (weak, nonatomic) IBOutlet EnlargeClickButton *deleteButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageLeftConstraints;

@end

@implementation PushMsgTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}


- (void)setPushMsgCellData:(PushMessageModel *)pushMsgCellData
{
    if (!pushMsgCellData)
    {
        return;
    }
    _pushMsgData = pushMsgCellData;
    [self configIconWithType:pushMsgCellData.apnsMsgType];
    [self configReadStateWithStatus:pushMsgCellData.apnsMsgReadState];
    self.devNameLabel.text = pushMsgCellData.deviceName;
    self.msgTimeLabel.text = pushMsgCellData.pushTime;
    [self showDeleteButton:pushMsgCellData.isShowDelete];
    [self setDeleteButtonImage:pushMsgCellData.isSelectDelete];
}


#pragma mark -- 设置消息图标
- (void)configIconWithType:(APNSMsgType)msgType
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法设置消息类型图标");
            return ;
        }
        switch (msgType)
        {
            case APNSMsgMove:                       // 移动侦测
            {
                strongSelf.msgIconImageView.image = [UIImage imageNamed:@"btn-Motion detection-disabled.png"];
            }
                break;
                
            case APNSMsgGuard:                      //
            {
                strongSelf.msgIconImageView.image = [UIImage imageNamed:@"btn-Motion detection-disabled.png"];
            }
                break;
                
            case APNSMsgPir:                        // PIR 侦测
            {
                strongSelf.msgIconImageView.image = [UIImage imageNamed:@"btn-Infrared-detection-disabled.png"];
            }
                break;
                
            case APNSMsgTemperatureUpperLimit:      // 温度上限
            {
                strongSelf.msgIconImageView.image = [UIImage imageNamed:@"Setting_TempAlarmSetting"];
            }
                break;
                
            case APNSMsgTemperatureLowerLimit:      // 温度下限
            {
                strongSelf.msgIconImageView.image = [UIImage imageNamed:@"Setting_TempAlarmSetting"];
            }
                break;
                
            case APNSMsgVoice:                      // 声音
            {
                strongSelf.msgIconImageView.image = [UIImage imageNamed:@"btn-Sound detection-disabled"];
            }
                break;
                
            case APNSMsgLowBattery:                      // 低电量
            {
                strongSelf.msgIconImageView.image = [UIImage imageNamed:@"pushMsgTypeLowBattery"];
            }
                break;
                
            case APNSMsgBellRing:                      // 按铃
            {
                strongSelf.msgIconImageView.image = [UIImage imageNamed:@"pushMsgTypeBellRing"];
            }
                break;

            default:
                break;
        }
    });
}


#pragma mark -- 设置未读标识图标
- (void)configReadStateWithStatus:(APNSMsgReadState)readState
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法设置消息类型图标");
            return ;
        }
        switch (readState)
        {
            case APNSMsgReadNo:                     // 未读
            {
                strongSelf.readStateImageView.hidden = NO;
            }
                break;
                
            case APNSMsgReading:                    // 正在读
            {
                strongSelf.readStateImageView.hidden = NO;
            }
                break;
                
            case APNSMsgReaded:                     // 已读
            {
                strongSelf.readStateImageView.hidden = YES;
            }
                break;
                
            default:
                break;
        }
    });
}


#pragma mark -- 显示/隐藏 删除操作 view
- (void)showDeleteButton:(BOOL)isShow
{
    _isShowDeleteButton = isShow;
    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:0.1f
                     animations:^
    {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法设置消息类型图标");
            return ;
        }
        if (NO == isShow)       // 隐藏
        {
            strongSelf.imageLeftConstraints.constant = DEFAULT_IMAGE_LEFT_MARGIN;
        }
        else                    // 显示
        {
            strongSelf.imageLeftConstraints.constant = DELETE_IMAGE_LEFT_MARGIN;
        }
        strongSelf.deleteButton.hidden = !isShow;
    }];
}


#pragma mark -- 选择删除按钮事件
- (IBAction)deleteButtonAction:(id)sender
{
    _isSelectDelete = !_isSelectDelete;
    [self setDeleteButtonImage:_isSelectDelete];
    //更改数据源
    _pushMsgData.isSelectDelete = _isSelectDelete;
}


#pragma mark -- 设置选择删除按钮背景图片
- (void)setDeleteButtonImage:(BOOL)isSelect
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法设置消息类型图标");
            return ;
        }
        if (NO == isSelect)    // 未选择
        {
            [strongSelf.deleteButton setImage:[UIImage imageNamed:@"deleteBtnNormal.png"]
                                     forState:UIControlStateNormal];
        }
        else    // 已选择
        {
            [strongSelf.deleteButton setImage:[UIImage imageNamed:@"deleteBtnHeighLight.png"]
                                     forState:UIControlStateNormal];
        }
    });
    _isSelectDelete = isSelect;
}

@end
