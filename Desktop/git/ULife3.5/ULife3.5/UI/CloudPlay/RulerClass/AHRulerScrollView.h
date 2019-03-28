//
//  CloudPlayViewController.m
//  TestAli
//
//  Created by AnDong on 2017/10/9.
//  Copyright © 2017年 AnDong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CloudVideoModel.h"
#import "CloudAlarmModel.h"
#import "SDCloudVideoModel.h"
#import "SDCloudAlarmModel.h"

//每一个格子的大小枚举
typedef NS_ENUM(NSInteger, rulerAverageType) {
    rulerAverageTypeOne = 0, //0.5h
    rulerAverageTypeTwo , //10min
    rulerAverageTypeThree , //5min
    rulerAverageTypeFour , //1min
    rulerAverageTypeFive ,  //30s
    rulerAverageTypeSix , //10s
};


#define DISTANCELEFTANDRIGHT 0.f // 标尺左右距离
#define MYDISTANCEVALUE (30.0f * self.currentZoomScale)
#define DISTANCEVALUE 30.0f// 每隔刻度实际长度
#define DISTANCETOPANDBOTTOM 80 // 标尺上下距离

@interface AHRulerScrollView : UIScrollView

@property (nonatomic,assign) rulerAverageType rulerAverageType;

@property (nonatomic,assign) NSUInteger rulerHeight;

@property (nonatomic,assign) NSUInteger rulerWidth;

@property (nonatomic,assign) CGFloat rulerValue;

//移动侦测时间段数组
@property (nonatomic,strong)NSArray *moveDetectArray;

//录制了视频时间段数组
@property (nonatomic,strong)NSArray *videoArray;


//SD卡移动侦测时间段数组
@property (nonatomic,strong)NSArray *SDMoveDetectArray;

//SD卡录制了视频时间段数组
@property (nonatomic,strong)NSArray *SDVideoArray;

//当前选中的日期 用于参照，绘制计算
@property (nonatomic,strong)NSDate *selectDate;

//放大倍数 -- 从1到1.5
@property (nonatomic,assign)CGFloat currentZoomScale;

@property (nonatomic,assign)BOOL canScroll;
@property (nonatomic,assign)BOOL pinching;

- (void)drawRuler;

//滑动渲染 -- 提高性能
- (void)scrollDraw;
- (void)drawCurrentIndicatorWithValue:(NSInteger)value withScroll:(BOOL)isScrolling;
- (void)playViewDrawCurrentIndicatorWithValue:(NSInteger)value withScroll:(BOOL)isScrolling;
- (void)playViewTimeIntervalDrawCurrentIndicatorWithValue:(NSInteger)value withScroll:(BOOL)isScrolling;
- (void)handlePinches:(UIPinchGestureRecognizer *)paramSender;
- (void)setRulerContentSizeWithValue:(NSInteger)value;
- (void)setCanScrollDelayEnableIsGes:(BOOL)isGes;
- (void)zoomToMAX;

//初始化到默认状态
- (void)initialized;

@end
