//
//  NvrSinglePlayView.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/16.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol NvrSinglePlayViewDelegate <NSObject>

/**
 重新加载数据（重新拉流）
 */
- (void)reloadDataButtonAction;

/**
 '不在线'按钮事件代理回调
 */
- (void)offlineButtonAction;

- (void)qualityChangeButtonAction;

@end


@interface NvrSinglePlayView : UIView

@property (nonatomic, weak) id <NvrSinglePlayViewDelegate> delegate;

/**
 开启 Activity 动画
 */
- (void)startActivityAnimation;

/**
 停止 Activity 动画
 */
- (void)stopActivityAnimation;

/**
 设置 正在录像 View 是否显示

 @param isHidden 是否显示，YES：显示，NO：隐藏
 */
- (void)configRecordingViewHidden:(BOOL)isHidden;

/**
 设置录像提示 Label 是否显示

 @param isHidden 是否显示，YES：显示，NO：隐藏
 */
- (void)configRecordTipLabelViewHidden:(BOOL)isHidden;

- (void)configQualityTitle:(BOOL)isHD;

- (void)configQualityBtnUsable:(BOOL)isUsable;

/**
 设置‘不在线’按钮是否隐藏
 
 @param isHidden 是否隐藏
 */
- (void)configOfflineBtnHidden:(BOOL)isHidden;

/**
 设置‘重新加载’按钮是否隐藏
 
 @param isHidden 是否隐藏
 */
- (void)configReloadBtnHidden:(BOOL)isHidden;

@end
