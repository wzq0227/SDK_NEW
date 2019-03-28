//
//  NvrCenterView.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/14.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NvrCenterViewDelegate <NSObject>


/**
 NVR 录像列表 按钮事件
 */
- (void)nvrRecordListAction;


/**
 NVR 全屏播放 按钮事件
 */
- (void)nvrFullScreenAction;

@end


@interface NvrCenterView : UIView

@property (nonatomic, weak) id<NvrCenterViewDelegate>delegate;


/**
 设置日期 Label 显示文本

 @param dateStr 日期字符串
 */
- (void)configDateLabelWithStr:(NSString *)dateStr;


/**
 是否隐藏日期 Label（横屏全屏模式下）

 @param isHidden 是否隐藏
 */
- (void)configDateLabelHidden:(BOOL)isHidden;

@end
