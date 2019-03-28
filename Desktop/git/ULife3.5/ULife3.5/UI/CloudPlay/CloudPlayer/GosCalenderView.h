//
//  GosCalenderView.h
//  dddd
//
//  Created by zz on 2018/12/25.
//  Copyright © 2018年 zz. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^GosCalenderSelect)(NSDate *);

@interface GosCalenderExternalView : UIView
/// 左右控制是否响应
@property (nonatomic, assign, getter=isEnableControl) BOOL enableControl;
/// 当前时间
@property (nonatomic, strong) NSDate *currentDate;
/// 事件数组
@property (nonatomic) NSArray<NSDate *> *hasVideoArray;
/// 日期切换回调
@property (nonatomic, copy) GosCalenderSelect blk;
/// 中间日期按钮
@property (nonatomic, strong) UIButton *calendarButton;
@end

@interface GosCalenderView : UIView

/**
 初始化

 @param attachFrame 依附控件Frame
 @param selectedDate 选择的日期，不赋值则默认当前日期
 @param hasVideoArray 时间数组
 @param callback 选择日期回调
 */
+ (void)showCalendarViewWithAttachFrame:(CGRect)attachFrame
                           selectedDate:(NSDate *)selectedDate
                          hasVideoArray:(NSArray<NSDate *> *)hasVideoArray
                         selectCallback:(GosCalenderSelect)callback;
@end
