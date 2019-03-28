//
//  NvrPushMsgTableViewCell.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/14.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PushMessageModel.h"

@interface NvrPushMsgTableViewCell : UITableViewCell

@property (nonatomic, strong) PushMessageModel *pushMsgCellData;

#pragma mark -- 隐藏/显示时间轴 上半截 View
/**
 隐藏/显示时间轴 上半截 View
 */
- (void)upLineViewHidden:(BOOL)isHidden;

#pragma mark -- 隐藏/显示时间轴 下半截 View
/**
 隐藏/显示时间轴 下半截 View
 */
- (void)downLineViewHidden:(BOOL)isHidden;

@end
