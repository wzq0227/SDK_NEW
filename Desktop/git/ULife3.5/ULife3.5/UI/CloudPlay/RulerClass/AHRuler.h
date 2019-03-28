//
//  CloudPlayViewController.m
//  TestAli
//
//  Created by AnDong on 2017/10/9.
//  Copyright © 2017年 AnDong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AHRulerScrollView.h"


@protocol AHRrettyRulerDelegate <NSObject>

- (void)ahRuler:(AHRulerScrollView *)rulerScrollView;

- (void)ahRulerEndDrag:(AHRulerScrollView *)rulerScrollView;

@end

@interface AHRuler : UIView <UIScrollViewDelegate>

@property (nonatomic,assign) id <AHRrettyRulerDelegate> rulerDeletate;

@property (nonatomic,strong) AHRulerScrollView *rulerScrollView;

@property (nonatomic,strong) UIButton *jumpToNowButton;


/*
 *  @param rulerAverageType      刻度类型枚举
 *  @param currentValue 当前时刻值，默认是24 * 60 * 60
 */
- (void)showRulerScrollViewWithAverage:(rulerAverageType)rulerAverageType
                          currentValue:(CGFloat)currentValue;


- (void)setContentOffSetWithValue:(NSInteger)value;

- (void)setFrame:(CGRect)frame; 

@end

