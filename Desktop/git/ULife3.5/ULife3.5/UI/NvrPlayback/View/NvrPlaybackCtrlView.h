//
//  NvrPlaybackCtrlView.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/21.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

/** ‘播放/暂停’按钮图标样式类型枚举 */
typedef NS_ENUM(NSInteger, PlayOrPauseBtnStyle) {
    PlayOrPauseBtnNoUse             = 0,        // 无视频流，不可操作按钮
    PlayOrPauseBtnPlay              = 1,        // 播放状态
    PlayOrPauseBtnPause             = 2,        // 暂停状态
};


@protocol NvrPlaybackCtrlViewDelegate <NSObject>

/**
 播放/暂停 按钮事件代理回调
 */
- (void)playOrPauseBtnAction;

/**
 拍照 按钮事件代理回调
 */
- (void)snapshotBtnAction;

@end

@interface NvrPlaybackCtrlView : UIView

@property (nonatomic, weak) id<NvrPlaybackCtrlViewDelegate>delegate;

- (void)showFileName:(NSString *)fileName;

/**
 修改‘播放/暂停’按钮图标

 @param playOrPauseBtnStyle 按钮样式，参见‘PlayOrPauseBtnStyle’
 */
- (void)updatePlayButtonWithStyle:(PlayOrPauseBtnStyle)playOrPauseBtnStyle;

/**
 修改‘拍照’按钮图片

 @param isPlaying 是否正在播放，YES：正在播放，NO：没有播放
 */
- (void)updateSnapshotBtn:(BOOL)isPlaying;

@end
