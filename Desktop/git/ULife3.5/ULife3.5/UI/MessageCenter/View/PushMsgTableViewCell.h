//
//  PushMsgTableViewCell.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/12.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PushMessageModel.h"


typedef void(^DeleteButtonActionBlock)(PushMessageModel *pushMsgModel, BOOL isSelect);


@interface PushMsgTableViewCell : UITableViewCell

@property (nonatomic, strong) PushMessageModel *pushMsgCellData;

/**
 *  删除按钮事件 Block
 */
@property (nonatomic, copy) DeleteButtonActionBlock deleteVideoBlock;


- (void)configReadStateWithStatus:(APNSMsgReadState)readState;


/**
 设置选择删除按钮是否显示

 @param isShow YES：显示，NO：隐藏
 */
- (void)showDeleteButton:(BOOL)isShow;

- (void)setDeleteButtonImage:(BOOL)isSelect;

@end
