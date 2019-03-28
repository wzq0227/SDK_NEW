//
//  CloudPlayViewController.m
//  TestAli
//
//  Created by AnDong on 2017/10/9.
//  Copyright © 2017年 AnDong. All rights reserved.
//

#import "AHRuler.h"
#import <Masonry.h>

#define SHEIGHT 8 // 中间指示器顶部闭合三角形高度
#define INDICATORCOLOR [UIColor blueColor].CGColor // 中间指示器颜色

@interface AHRuler()

@property (nonatomic,strong)CAShapeLayer *lineShapeLayer;

@property (nonatomic,strong)CAShapeLayer *indicatorShapeLayer;

@end

@implementation AHRuler{
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        _rulerScrollView = [self getRulerScrollView];
        _rulerScrollView.rulerHeight = frame.size.height;
        _rulerScrollView.rulerWidth = frame.size.width;
        [self addSubview:self.jumpToNowButton];
        [self.jumpToNowButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-15);
            make.top.equalTo(self).offset(14);
            make.width.height.mas_equalTo(52);
        }];
    }
    return self;
}



- (void)showRulerScrollViewWithAverage:(rulerAverageType)rulerAverageType
                          currentValue:(CGFloat)currentValue{
    _rulerScrollView.rulerAverageType = rulerAverageType;
    _rulerScrollView.rulerValue = currentValue;
    [self addSubview:_rulerScrollView];
    [_rulerScrollView drawRuler];
    [self bringSubviewToFront:self.jumpToNowButton];
    [self drawRacAndLine];

}


- (AHRulerScrollView *)getRulerScrollView {
    AHRulerScrollView * rScrollView = [AHRulerScrollView new];
    rScrollView.delegate = self;
    rScrollView.showsHorizontalScrollIndicator = NO;
    rScrollView.bounces = NO;
    return rScrollView;
}


#pragma mark - ScrollView Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    self.rulerScrollView.canScroll = NO;
}

- (void)scrollViewDidScroll:(AHRulerScrollView *)scrollView {
    
    if (!self.rulerScrollView.pinching) {
        CGFloat offSetX = scrollView.contentOffset.x  - DISTANCELEFTANDRIGHT;
        CGFloat ruleValue = (offSetX/DISTANCEVALUE/2);
        CGFloat scaleValue; //定义好的，每一个格子的小时数
        int currentType = scrollView.rulerAverageType;
        if (currentType == rulerAverageTypeOne) {
            scaleValue = 3600;
        }
        else if (currentType == rulerAverageTypeTwo){
            scaleValue = 1200;
        }
        else if (currentType == rulerAverageTypeThree){
            scaleValue = 600;
        }
        else if (currentType == rulerAverageTypeFour){
            scaleValue = 120;
        }
        else if (currentType == rulerAverageTypeFive){
            scaleValue = 60;
        }
        else{
            scaleValue = 20;
        }
        ruleValue = ruleValue * scaleValue;
        NSLog(@"[%s] ruler: %.2f; before: %.2f", __PRETTY_FUNCTION__, ruleValue, scrollView.rulerValue);
        scrollView.rulerValue = ruleValue;
        
        //获取到rulerValue --开始滑动渲染
        [scrollView scrollDraw];
        if (self.rulerDeletate) {
            [self.rulerDeletate ahRuler:scrollView];
        }
    }
}


- (void)drawRacAndLine {
    
    if (self.lineShapeLayer) {
        [self.lineShapeLayer removeFromSuperlayer];
    }
    
    if (self.indicatorShapeLayer) {
        [self.indicatorShapeLayer removeFromSuperlayer];
    }
    
    //直线
    CAShapeLayer *solidShapeLayer = [CAShapeLayer layer];
    self.lineShapeLayer = solidShapeLayer;
    CGMutablePathRef solidShapePath =  CGPathCreateMutable();
    [solidShapeLayer setFillColor:[[UIColor clearColor] CGColor]];
    [solidShapeLayer setStrokeColor:[[UIColor blackColor] CGColor]];
    solidShapeLayer.lineWidth = 1.0f ;
    CGPathMoveToPoint(solidShapePath, NULL, 0, 80);
    CGPathAddLineToPoint(solidShapePath, NULL, self.frame.size.width,80);
    [solidShapeLayer setPath:solidShapePath];
    CGPathRelease(solidShapePath);
    
    // 渐变
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.bounds;
    
    gradient.colors = @[(id)[[UIColor whiteColor] colorWithAlphaComponent:1.f].CGColor,
                        (id)[[UIColor whiteColor] colorWithAlphaComponent:0.0f].CGColor,
                        (id)[[UIColor whiteColor] colorWithAlphaComponent:1.f].CGColor];
    
    gradient.locations = @[[NSNumber numberWithFloat:0.0f],
                           [NSNumber numberWithFloat:0.6f]];
    
    gradient.startPoint = CGPointMake(0, .5);
    gradient.endPoint = CGPointMake(1, .5);
    
    
    [self.layer addSublayer:solidShapeLayer];
    //俩边渐变效果
    //    [self.layer addSublayer:gradient];
    
    // 蓝色指示器
    CAShapeLayer *shapeLayerLine = [CAShapeLayer layer];
    self.indicatorShapeLayer = shapeLayerLine;
    shapeLayerLine.strokeColor = [UIColor blackColor].CGColor;
    shapeLayerLine.fillColor = INDICATORCOLOR;
    shapeLayerLine.lineWidth = 1.0f;
    shapeLayerLine.lineCap = kCALineCapSquare;
    
    CGMutablePathRef pathLine = CGPathCreateMutable();
    CGPathMoveToPoint(pathLine, NULL, self.frame.size.width / 2, DISTANCETOPANDBOTTOM);
    CGPathAddLineToPoint(pathLine, NULL, self.frame.size.width / 2, 0);
    shapeLayerLine.path = pathLine;
    [self.layer addSublayer:shapeLayerLine];
}


- (void)scrollViewDidEndDragging:(AHRulerScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
    //开启可以自动滚动
    [self.rulerScrollView setCanScrollDelayEnableIsGes:NO];
    
    CGFloat offSetX = scrollView.contentOffset.x  - DISTANCELEFTANDRIGHT;
    CGFloat ruleValue = (offSetX/DISTANCEVALUE/2/scrollView.currentZoomScale);
    CGFloat scaleValue; //定义好的，每一个格子的小时数
    int currentType = scrollView.rulerAverageType;
    if (currentType == rulerAverageTypeOne) {
        scaleValue = 3600;
    }
    else if (currentType == rulerAverageTypeTwo){
        scaleValue = 1200;
    }
    else if (currentType == rulerAverageTypeThree){
        scaleValue = 600;
    }
    else if (currentType == rulerAverageTypeFour){
        scaleValue = 120;
    }
    else if (currentType == rulerAverageTypeFive){
        scaleValue = 60;
    }
    else{
        scaleValue = 20;
    }
    ruleValue = ruleValue * scaleValue;
    scrollView.rulerValue = ruleValue;
    if (self.rulerDeletate) {
        [self.rulerDeletate ahRulerEndDrag:scrollView];
    }
}

- (void)setContentOffSetWithValue:(NSInteger)value{
    CGFloat scaleValue; //定义好的，每一个格子的小时数
    int currentType = self.rulerScrollView.rulerAverageType;
    if (currentType == rulerAverageTypeOne) {
        scaleValue = 3600;
    }
    else if (currentType == rulerAverageTypeTwo){
        scaleValue = 1200;
    }
    else if (currentType == rulerAverageTypeThree){
        scaleValue = 600;
    }
    else if (currentType == rulerAverageTypeFour){
        scaleValue = 120;
    }
    else if (currentType == rulerAverageTypeFive){
        scaleValue = 60;
    }
    else{
        scaleValue = 20;
    }
    
    CGFloat rulerValue = value / scaleValue;
    
    CGFloat contentX = rulerValue * 2 * DISTANCEVALUE + DISTANCELEFTANDRIGHT;
    
    [self.rulerScrollView setContentOffset:CGPointMake(contentX, 0)];
    
}


- (void)scrollViewDidEndDecelerating:(AHRulerScrollView *)scrollView {
    
    //    CGFloat offSetX = scrollView.contentOffset.x  - DISTANCELEFTANDRIGHT;
    //    CGFloat ruleValue = (offSetX/DISTANCEVALUE/2);
    //    CGFloat scaleValue; //定义好的，每一个格子的小时数
    //    int currentType = scrollView.rulerAverageType;
    //    if (currentType == rulerAverageTypeOne) {
    //        scaleValue = 3600;
    //    }
    //    else if (currentType == rulerAverageTypeTwo){
    //        scaleValue = 1200;
    //    }
    //    else if (currentType == rulerAverageTypeThree){
    //        scaleValue = 600;
    //    }
    //    else if (currentType == rulerAverageTypeFour){
    //        scaleValue = 120;
    //    }
    //    else if (currentType == rulerAverageTypeFive){
    //        scaleValue = 60;
    //    }
    //    else{
    //        scaleValue = 20;
    //    }
    //    ruleValue = ruleValue * scaleValue;
    //    scrollView.rulerValue = ruleValue;
    //    if (self.rulerDeletate) {
    //        [self.rulerDeletate ahRulerEndDrag:scrollView];
    //    }
    
}


- (void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    _rulerScrollView.rulerHeight = frame.size.height;
    _rulerScrollView.rulerWidth = frame.size.width;
    [self drawRacAndLine];
    [_rulerScrollView drawRuler];
}

#pragma mark - Getter
- (UIButton *)jumpToNowButton{
    if (!_jumpToNowButton) {
        _jumpToNowButton = [[UIButton alloc]init];
        _jumpToNowButton.hidden = YES;
//        [_jumpToNowButton setBackgroundImage:[UIImage imageNamed:@"btn_schedule_normal"] forState:UIControlStateNormal];
        [_jumpToNowButton setImage:[UIImage imageNamed:@"btn_schedule_normal"] forState:UIControlStateNormal];
        [_jumpToNowButton setImage:[UIImage imageNamed:@"btn_schedule_press"] forState:UIControlStateSelected];
    }
    return _jumpToNowButton;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view == nil) {
        for (UIView *subView in self.subviews) {
            CGPoint tp = [subView convertPoint:point fromView:self];
            if (CGRectContainsPoint(subView.bounds, tp)) {
                view = subView;
            }
        }
    }
    return view;
}


@end

