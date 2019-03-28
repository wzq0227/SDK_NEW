//
//  NvrPlayView.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/14.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MediaHeader.h"

@protocol NvrPlayViewDelegate <NSObject>


/**
 单击手势代理回调

 @param positionType 单击手势位置
 */
- (void)singleTapOnPosition:(PositionType)positionType;

/**
 双击手势代理回调
 
 @param positionType 双击击手势位置
 */
- (void)doubleTapOnPosition:(PositionType)positionType;


/**
 重新加载数据（重新拉流）

 @param positionType 画面位置
 */
- (void)reloadDataOnPosition:(PositionType)positionType;

/**
 '不在线'按钮事件代理回调
 */
- (void)offlineButtonAction;

@end

@interface NvrPlayView : UIView

@property (nonatomic, weak) id<NvrPlayViewDelegate>delegate;

/** NVR：左上角播放 View */
@property (nonatomic, strong) UIView *topLeftPlayView;

/** NVR：右上角播放 View */
@property (nonatomic, strong) UIView *topRightPlayView;

/** NVR：左下角播放 View */
@property (nonatomic, strong) UIView *bottomLeftPlayView;

/** NVR：右下角播放 View */
@property (nonatomic, strong) UIView *bottomRightPlayView;


#pragma mark -- 开启 Activity 动画
/**
 开启 Activity 动画
 */
- (void)startActivityAnimationOnPosition:(PositionType)positionType;


#pragma mark -- 停止 Activity 动画
/**
 停止 Activity 动画
 */
- (void)stopActivityAnimationOnPosition:(PositionType)positionType;

/**
 设置‘重新加载’按钮是否隐藏

 @param isHidden 是否隐藏
 @param positionType 画面位置
 */
- (void)configReloadBtnHidden:(BOOL)isHidden
                   onPosition:(PositionType)positionType;

/**
 设置‘不在线’按钮是否隐藏

 @param isHidden 是否隐藏
 */
- (void)configOfflineBtnHidden:(BOOL)isHidden;

@end
