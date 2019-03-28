//
//  NvrPBPlayView.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/21.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol NvrPBPlayViewDelegate <NSObject>

/**
 重新加载数据（重新拉流）
 
 */
- (void)reloadData;

@end



@interface NvrPBPlayView : UIView

@property (nonatomic, weak) id <NvrPBPlayViewDelegate> delegate;

/**
 开启 Activity 动画
 */
- (void)startActivityAnimation;

/**
 停止 Activity 动画
 */
- (void)stopActivityAnimation;


/**
 设置‘重新加载’按钮是否隐藏

 @param isHidden 是否隐藏
 */
- (void)configReloadBtnHidden:(BOOL)isHidden;

@end
