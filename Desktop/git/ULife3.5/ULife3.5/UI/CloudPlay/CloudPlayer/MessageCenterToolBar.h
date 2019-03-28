//  MessageCenterToolBar.h
//  GosIPCs
//
//  Create by daniel.hu on 2018/12/3.
//  Copyright © 2018年 goscam. All rights reserved.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MessageCenterToolBar : UIView
/// 全选按钮，normal->全选,selected->取消全选
@property (weak, nonatomic) IBOutlet UIButton *checkAllButton;
/// 删除按钮
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

- (void)show;
- (void)hide;
@end

NS_ASSUME_NONNULL_END
