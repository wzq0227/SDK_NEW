//
//  IpcFourPlayView.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/9/21.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MediaHeader.h"
#import "DeviceDataModel.h"


@protocol IpcFourPlayViewDelegate <NSObject>

/**
 添加设备
 
 @param positionType 画面位置
 */
- (void)addDevActionOnPosition:(PositionType)positionType;


/**
 删除设备
 
 @param positionType 画面位置
 */
- (void)deleteDevActionOnPosition:(PositionType)positionType;


/**
 设备重连

 @param PositionType 画面位置
 */
- (void)reconnOnPosition:(PositionType)PositionType;


/**
 单击手势代理回调
 
 @param positionType 单击手势位置
 */
- (void)singleTapActionOnPosition:(PositionType)positionType;

/**
 双击手势代理回调
 
 @param positionType 双击击手势位置
 */
- (void)doubleTapActionOnPosition:(PositionType)positionType;


/**
 添加设备

 @param devDataModel 设备数据模型
 @param positionType 画面位置
 */
- (void)addDevModel:(DeviceDataModel *)devDataModel
        onPostition:(PositionType)positionType;


@end


@interface IpcFourPlayView : UIView

@property (nonatomic, weak) id <IpcFourPlayViewDelegate> delegate;

/** IPC 四画面：左上角(top-left)播放 View */
@property (nonatomic, strong) UIView *tlPlayView;

/** IPC 四画面：右上角(top-right)播放 View */
@property (nonatomic, strong) UIView *trPlayView;

/** IPC 四画面：左下角(bottom-left)播放 View */
@property (nonatomic, strong) UIView *blPlayView;

/** IPC 四画面：右下角(bottom-right)播放 View */
@property (nonatomic, strong) UIView *brPlayView;

/** 设备列表数组模型 */
@property (nonatomic, strong) NSMutableArray <DeviceDataModel *>*devListArray;

/** 已添加设备(0 下标不用) */
@property (nonatomic, strong) NSMutableArray <DeviceDataModel *>*addedDevArray;


#pragma mark -- 开启 Activity 动画
/**
 开启 Activity 动画
 */
- (void)startActivityOnPosition:(PositionType)positionType;


#pragma mark -- 停止 Activity 动画
/**
 停止 Activity 动画
 */
- (void)stopActivityOnPosition:(PositionType)positionType;


- (void)configTableViewHidden:(BOOL)isHidden;

#pragma mark -- 配置边框是否显示

/**
 配置边框是否显示

 @param isHidden 是否隐藏
 @param position 画面位置
 */
- (void)configBorderHidden:(BOOL)isHidden
                onPosition:(PositionType)position;


- (void)autoHiddenBorderOnPosition:(NSNumber *)position;


#pragma mark -- 设置‘添加设备’按钮是否隐藏
/**
 设置‘添加设备’按钮是否隐藏
 
 @param isHidden 是否隐藏
 @param positionType 画面位置
 */
- (void)configAddDevBtnHidden:(BOOL)isHidden
                   onPosition:(PositionType)positionType;


#pragma mark -- 设置‘删除设备’按钮是否隐藏
/**
 设置‘删除设备’按钮是否隐藏
 
 @param isHidden 是否隐藏
 @param positionType 画面位置
 */
- (void)configDeleteDevBtnHidden:(BOOL)isHidden
                      onPosition:(PositionType)positionType;

#pragma mark -- 设置‘离线’按钮是否隐藏
/**
 设置‘离线’按钮是否隐藏
 
 @param isHidden 是否隐藏
 @param positionType 画面位置
 */
- (void)configOfflineBtnHidden:(BOOL)isHidden
                    onPosition:(PositionType)positionType;

@end
