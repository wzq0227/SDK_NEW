//
//  NvrPushMsgTableViewCell.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/14.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "NvrPushMsgTableViewCell.h"


@interface NvrPushMsgTableViewCell ()

/** 时间轴 上半截 View*/
@property (weak, nonatomic) IBOutlet UIView *upLineView;

/** 时间轴 下半截 View*/
@property (weak, nonatomic) IBOutlet UIView *downLineView;

/** 消息类型 ImageView */
@property (weak, nonatomic) IBOutlet UIImageView *msgTypeImageView;

/** 消息时间 Label*/
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

/** 设备昵称 Label*/
@property (weak, nonatomic) IBOutlet UILabel *devNameLabel;

/** 消息类型 Label*/
@property (weak, nonatomic) IBOutlet UILabel *msgTypeLabel;

@end


@implementation NvrPushMsgTableViewCell

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
        NSLog(@"pushMsgCellData = nil");
        return;
    }
    self.timeLabel.text    = pushMsgCellData.pushTime;
    self.devNameLabel.text = pushMsgCellData.deviceName;
    [self configMsgLabelWithType:pushMsgCellData.apnsMsgType];
    [self configImageViewWithType:pushMsgCellData.apnsMsgType];
}


- (void)configMsgLabelWithType:(APNSMsgType)msgType
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法设置推送消息类型图标");
            return ;
        }
        switch (msgType)
        {
            case APNSMsgMove:                   // 移动侦测
            {
                strongSelf.msgTypeLabel.text = DPLocalizedString(@"NotifyMovePushMsg");
            }
                break;
                
            case APNSMsgGuard:
            {
                strongSelf.msgTypeLabel.text = DPLocalizedString(@"");
            }
                break;
                
            case APNSMsgPir:                    // PIR 侦测
            {
                strongSelf.msgTypeLabel.text = DPLocalizedString(@"NotifyPIRPushMsg");
            }
                break;
                
            case APNSMsgTemperatureUpperLimit:  // 温度上限
            {
                strongSelf.msgTypeLabel.text = DPLocalizedString(@"");
            }
                break;
                
            case APNSMsgTemperatureLowerLimit:  // 温度下限
            {
                strongSelf.msgTypeLabel.text = DPLocalizedString(@"");
            }
                break;
                
            case APNSMsgVoice:                  // 声音
            {
                strongSelf.msgTypeLabel.text = DPLocalizedString(@"");
            }
                break;
                
            default:
            {
                strongSelf.msgTypeLabel.text = DPLocalizedString(@"NotifyMovePushMsg");
            }
                break;
        }
    });
}


- (void)configImageViewWithType:(APNSMsgType)msgType
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法设置推送消息类型图标");
            return ;
        }
        switch (msgType)
        {
            case APNSMsgMove:                   // 移动侦测
            {
                strongSelf.msgTypeImageView.image = [UIImage imageNamed:@"NvrMovePush"];
            }
                break;
                
            case APNSMsgGuard:
            {
                strongSelf.msgTypeImageView.image = [UIImage imageNamed:@""];
            }
                break;
                
            case APNSMsgPir:                    // PIR 侦测
            {
                strongSelf.msgTypeImageView.image = [UIImage imageNamed:@"NvrPirPush"];
            }
                break;
                
            case APNSMsgTemperatureUpperLimit:  // 温度上限
            {
                strongSelf.msgTypeImageView.image = [UIImage imageNamed:@""];
            }
                break;
                
            case APNSMsgTemperatureLowerLimit:  // 温度下限
            {
                strongSelf.msgTypeImageView.image = [UIImage imageNamed:@""];
            }
                break;
                
            case APNSMsgVoice:                  // 声音
            {
                strongSelf.msgTypeImageView.image = [UIImage imageNamed:@""];
            }
                break;
                
            default:
            {
                strongSelf.msgTypeImageView.image = [UIImage imageNamed:@""];
            }
                break;
        }
    });
}


#pragma mark -- 隐藏/显示时间轴 上半截 View
- (void)upLineViewHidden:(BOOL)isHidden
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法设置推送消息类型图标");
            return ;
        }
        strongSelf.upLineView.hidden = isHidden;
    });
}


#pragma mark -- 隐藏/显示时间轴 下半截 View
- (void)downLineViewHidden:(BOOL)isHidden
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法设置推送消息类型图标");
            return ;
        }
        strongSelf.downLineView.hidden = isHidden;
    });
}

@end
