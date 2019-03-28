//
//  NvrPushMsgView.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/14.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PushMessageModel.h"

@interface NvrPushMsgView : UIView

/** NVR 推送消息列表 */
@property (nonatomic, strong) UITableView *pushMsgTableView;

/** NVR 推送消息 数组 */
@property (nonatomic, strong) NSMutableArray <PushMessageModel *>*pushMsgDataArray;

/** 设备 ID (用于过滤实时推送消息的插入)*/
@property (nonatomic, copy) NSString *deviceId;


/**
 设置是否显示没有推送消息图

 @param isHidden 是否显示，YES：隐藏，NO：显示
 */
- (void)configNoPushMsgViewHidden:(BOOL)isHidden;

@end
