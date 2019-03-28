//
//  CloudPlayViewController.m
//  TestAli
//
//  Created by AnDong on 2017/10/9.
//  Copyright © 2017年 AnDong. All rights reserved.
//

#import "AHRulerScrollView.h"


#define HOMECOLOR [UIColor colorWithRed:53/255.0 green:153/255.0 blue:54/255.0 alpha:1]


@interface AHRulerScrollView ()

@property (nonatomic,strong)UIPinchGestureRecognizer *pinchGes;
@property (nonatomic,strong)CAShapeLayer *shapeLayer1;
@property (nonatomic,strong)CAShapeLayer *shapeLayer2;
@property (nonatomic,strong)NSMutableArray *labelArray;
@property (nonatomic,strong)NSMutableArray *layerArray;



//存在录制视频的数组
@property (nonatomic,strong)NSMutableArray *videoViewArray;

//报警View的数组
@property (nonatomic,strong)NSMutableArray *alarmViewArray;

@property (nonatomic,strong)CAShapeLayer *indicatorLayer;

@property (nonatomic,assign)CGFloat gesZoomScale;


//绘制的左边
@property (atomic,assign)int drawLeft;

//已经绘制的右边
@property (atomic,assign)int drawRight;

//@property (nonatomic,strong)NSDate *currentTimeDate;

@end

@implementation AHRulerScrollView

- (instancetype)init{
    if (self = [super init]) {
        _currentZoomScale = 1.0f;
        _gesZoomScale = 1.0f;
        _canScroll = YES;
        _pinching = NO;
    }
    return self;
}


- (void)setRulerValue:(CGFloat)rulerValue{
    _rulerValue = rulerValue;
}

- (void)drawRuler{
    
    self.drawLeft = 0;
    self.drawRight = 0;
    
    //先移除 --重新绘制
    if (self.shapeLayer1) {
        [self.shapeLayer1 removeFromSuperlayer];
    }
    
    if (self.shapeLayer2) {
        [self.shapeLayer2 removeFromSuperlayer];
    }
    
    //移除label
    for (UILabel *label in self.labelArray) {
        [label removeFromSuperview];
    }
    
    //移除layer
    for (CAShapeLayer *layer in self.layerArray) {
        [layer removeFromSuperlayer];
    }
    [self.layerArray removeAllObjects];
    [self.labelArray removeAllObjects];
    
    CGMutablePathRef pathRef1 = CGPathCreateMutable();
    CGMutablePathRef pathRef2 = CGPathCreateMutable();
    
    CAShapeLayer *shapeLayer1 = [CAShapeLayer layer];
    shapeLayer1.strokeColor = [UIColor blackColor].CGColor;
    shapeLayer1.fillColor = [UIColor clearColor].CGColor;
    shapeLayer1.lineWidth = 1.f;
    shapeLayer1.lineCap = kCALineCapButt;
    
    CAShapeLayer *shapeLayer2 = [CAShapeLayer layer];
    shapeLayer2.strokeColor = [UIColor blackColor].CGColor;
    shapeLayer2.fillColor = [UIColor clearColor].CGColor;
    shapeLayer2.lineWidth = 1.f;
    shapeLayer2.lineCap = kCALineCapButt;
    
    self.shapeLayer1 = shapeLayer1;
    self.shapeLayer2 = shapeLayer2;
    
    
    CGFloat singleHrs; //定义好的，每一个格子的小时数
    int totalCout; //总共的格子数量
    
    if (self.rulerAverageType == rulerAverageTypeOne) {
        singleHrs = 0.5 * 360;
        totalCout = 24 * 2;
    }
    else if (self.rulerAverageType == rulerAverageTypeTwo){
        singleHrs = 1 / 6.0f * 360;
        totalCout = 24 * 6;
    }
    else if (self.rulerAverageType == rulerAverageTypeThree){
        singleHrs = 1 / 12.0f * 360;
        totalCout = 24 * 12;
    }
    else if (self.rulerAverageType == rulerAverageTypeFour){
        singleHrs = 1 / 60.0f* 360;
        totalCout = 24 * 60;
    }
    else if (self.rulerAverageType == rulerAverageTypeFive){
        singleHrs = 1 / 120.0f* 360;
        totalCout = 24 * 120;
    }
    else{
        singleHrs = 1 / 360.0f* 360;
        totalCout = 24 *360;
    }
    int nowValue = self.rulerValue/10/singleHrs;
    int left = nowValue >48 ? nowValue - 48 : 0;
    int right = nowValue + 48  < totalCout ? nowValue + 48  : totalCout;
    self.drawLeft = left;
    self.drawRight = right;
    for (int i = 0; i <= totalCout; i++) {
        //当前只绘制48个格子
        if (i <= right && i >=left) {
            UILabel *rule = [[UILabel alloc] init];
            //设置下标识符
            rule.tag = i;
            [self.labelArray addObject:rule];
            rule.font = [UIFont systemFontOfSize:12.0f];
            
            rule.textColor = [UIColor blackColor];
            rule.text = [self getTimeTextWithValue:i * 10 * singleHrs];
            CGSize textSize = [rule.text sizeWithAttributes:@{ NSFontAttributeName : rule.font }];
            if (i % 2 == 0) {
                CGPathMoveToPoint(pathRef2, NULL, DISTANCELEFTANDRIGHT + MYDISTANCEVALUE  * i + (self.rulerWidth / 2.0f), DISTANCETOPANDBOTTOM);
                CGPathAddLineToPoint(pathRef2, NULL, DISTANCELEFTANDRIGHT + MYDISTANCEVALUE * i+ (self.rulerWidth / 2.0f), DISTANCETOPANDBOTTOM + 20);
                rule.frame = CGRectMake(DISTANCELEFTANDRIGHT + MYDISTANCEVALUE * i - textSize.width / 2+ (self.rulerWidth / 2.0f), DISTANCETOPANDBOTTOM + 20 + 5, 0, 0);
                [rule sizeToFit];
                [self addSubview:rule];
            }
            else
            {
                CGPathMoveToPoint(pathRef1, NULL, DISTANCELEFTANDRIGHT + MYDISTANCEVALUE * i+ (self.rulerWidth / 2.0f) , DISTANCETOPANDBOTTOM);
                CGPathAddLineToPoint(pathRef1, NULL, DISTANCELEFTANDRIGHT + MYDISTANCEVALUE * i+ (self.rulerWidth / 2.0f), DISTANCETOPANDBOTTOM + 10);
            }
        }
    }
    shapeLayer1.path = pathRef1;
    shapeLayer2.path = pathRef2;
    [self.layer addSublayer:shapeLayer1];
    [self.layer addSublayer:shapeLayer2];
    self.frame = CGRectMake(0, 0, self.rulerWidth, self.rulerHeight);
    
    //纯计算
    self.contentOffset = CGPointMake(MYDISTANCEVALUE * (self.rulerValue / (singleHrs *10)), 0);
    CGFloat width = totalCout * MYDISTANCEVALUE + DISTANCELEFTANDRIGHT * 2.f + self.rulerWidth;
    CGFloat height = self.rulerHeight;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.contentSize = CGSizeMake(width,height);
    });
    
    //添加捏合手势
    if (!_pinchGes) {
        self.pinchGes = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinches:)];
        [self addGestureRecognizer:self.pinchGes];
    }
    
    //绘制当前时间指示器
    [self drawCurrentIndicatorWithValue:self.rulerValue withScroll:YES];
    
    
    if (self.SDMoveDetectArray || self.SDVideoArray) {
        [self drawSDAlarmView];
        [self drawSDVideoView];
    }
    else{
        [self drawAlarmView];
        [self drawVideoView];
    }
    

}


- (void)scrollDraw{
    
    if (self.drawRight == 0 && self.drawLeft == 0) {
        return;
    }
    
    CGFloat singleHrs; //定义好的，每一个格子的小时数
    int totalCout; //总共的格子数量f
    
    if (self.rulerAverageType == rulerAverageTypeOne) {
        singleHrs = 0.5 * 360;
        totalCout = 24 * 2;
    }
    else if (self.rulerAverageType == rulerAverageTypeTwo){
        singleHrs = 1 / 6.0f * 360;
        totalCout = 24 * 6;
    }
    else if (self.rulerAverageType == rulerAverageTypeThree){
        singleHrs = 1 / 12.0f * 360;
        totalCout = 24 * 12;
    }
    else if (self.rulerAverageType == rulerAverageTypeFour){
        singleHrs = 1 / 60.0f* 360;
        totalCout = 24 * 60;
    }
    else if (self.rulerAverageType == rulerAverageTypeFive){
        singleHrs = 1 / 120.0f* 360;
        totalCout = 24 * 120;
    }
    else{
        singleHrs = 1 / 360.0f* 360;
        totalCout = 24 *360;
    }
    
    //获取当前格子数
    int currentCount =  self.rulerValue/10/singleHrs;
    
    //获取当前格子数的左右边界 -- 使用12格子判断
    int left = currentCount >24 ? currentCount - 24 : 0;
    int right = (currentCount + 24)  < totalCout ? currentCount + 24  : totalCout;
    
    
    if (left >= self.drawLeft && right <= self.drawRight) {
        return;
    }
    
    left = currentCount >48 ? currentCount - 48 : 0;
    right = (currentCount + 48)  < totalCout ? currentCount + 48 : totalCout;
    
    //查找缺值
    int exsitLeft = self.drawLeft;
    int exsitRight = self.drawRight;
    
    //重新设置边界
    self.drawLeft = MIN(left, self.drawLeft);
    self.drawRight = MAX(right,self.drawRight);
    
    CGMutablePathRef pathRef1 = CGPathCreateMutable();
    CGMutablePathRef pathRef2 = CGPathCreateMutable();
    
    CAShapeLayer *shapeLayer1 = [CAShapeLayer layer];
    shapeLayer1.strokeColor = [UIColor blackColor].CGColor;
    shapeLayer1.fillColor = [UIColor clearColor].CGColor;
    shapeLayer1.lineWidth = 1.f;
    shapeLayer1.lineCap = kCALineCapButt;
    
    CAShapeLayer *shapeLayer2 = [CAShapeLayer layer];
    shapeLayer2.strokeColor = [UIColor blackColor].CGColor;
    shapeLayer2.fillColor = [UIColor clearColor].CGColor;
    shapeLayer2.lineWidth = 1.f;
    shapeLayer2.lineCap = kCALineCapButt;
    for (int i = left; i < exsitLeft;  i++) {
        UILabel *rule = [[UILabel alloc] init];
        //设置下标识符
        rule.tag = i;
        [self.labelArray addObject:rule];
        rule.font = [UIFont systemFontOfSize:12.0f];
        rule.textColor = [UIColor blackColor];
        rule.text = [self getTimeTextWithValue:i * 10 * singleHrs];
        CGSize textSize = [rule.text sizeWithAttributes:@{ NSFontAttributeName : rule.font }];
        if (i % 2 == 0) {
            CGPathMoveToPoint(pathRef2, NULL, DISTANCELEFTANDRIGHT + MYDISTANCEVALUE * i + (self.rulerWidth / 2.0f), DISTANCETOPANDBOTTOM);
            CGPathAddLineToPoint(pathRef2, NULL, DISTANCELEFTANDRIGHT + MYDISTANCEVALUE * i+ (self.rulerWidth / 2.0f), DISTANCETOPANDBOTTOM + 20);
            rule.frame = CGRectMake(DISTANCELEFTANDRIGHT + MYDISTANCEVALUE * i - textSize.width / 2+ (self.rulerWidth / 2.0f), DISTANCETOPANDBOTTOM + 20 + 5, 0, 0);
            [rule sizeToFit];
            [self addSubview:rule];
        }
        else
        {
            CGPathMoveToPoint(pathRef1, NULL, DISTANCELEFTANDRIGHT + MYDISTANCEVALUE * i+ (self.rulerWidth / 2.0f) , DISTANCETOPANDBOTTOM);
            CGPathAddLineToPoint(pathRef1, NULL, DISTANCELEFTANDRIGHT + MYDISTANCEVALUE * i+ (self.rulerWidth / 2.0f), DISTANCETOPANDBOTTOM + 10);
        }
    }
    
    for (int i = exsitRight + 1; i <= right;  i++) {
        UILabel *rule = [[UILabel alloc] init];
        //设置下标识符
        rule.tag = i;
        [self.labelArray addObject:rule];
        rule.font = [UIFont systemFontOfSize:12.0f];
        rule.textColor = [UIColor blackColor];
        rule.text = [self getTimeTextWithValue:i * 10 * singleHrs];
        CGSize textSize = [rule.text sizeWithAttributes:@{ NSFontAttributeName : rule.font }];
        if (i % 2 == 0) {
            CGPathMoveToPoint(pathRef2, NULL, DISTANCELEFTANDRIGHT + MYDISTANCEVALUE * i + (self.rulerWidth / 2.0f), DISTANCETOPANDBOTTOM);
            CGPathAddLineToPoint(pathRef2, NULL, DISTANCELEFTANDRIGHT + MYDISTANCEVALUE * i+ (self.rulerWidth / 2.0f), DISTANCETOPANDBOTTOM + 20);
            rule.frame = CGRectMake(DISTANCELEFTANDRIGHT + MYDISTANCEVALUE * i - textSize.width / 2+ (self.rulerWidth / 2.0f), DISTANCETOPANDBOTTOM + 20 + 5, 0, 0);
            [rule sizeToFit];
            [self addSubview:rule];
        }
        else
        {
            CGPathMoveToPoint(pathRef1, NULL, DISTANCELEFTANDRIGHT + MYDISTANCEVALUE * i+ (self.rulerWidth / 2.0f) , DISTANCETOPANDBOTTOM);
            CGPathAddLineToPoint(pathRef1, NULL, DISTANCELEFTANDRIGHT + MYDISTANCEVALUE * i+ (self.rulerWidth / 2.0f), DISTANCETOPANDBOTTOM + 10);
        }
    }
    
    shapeLayer1.path = pathRef1;
    shapeLayer2.path = pathRef2;
    [self.layer addSublayer:shapeLayer1];
    [self.layer addSublayer:shapeLayer2];
    [self.layerArray addObject:shapeLayer1];
    [self.layerArray addObject:shapeLayer2];
    
}

- (void)drawCurrentIndicatorWithValue:(NSInteger)value withScroll:(BOOL)isScrolling{
    
    if (self.indicatorLayer) {
        [self.indicatorLayer removeFromSuperlayer];
    }

    CGFloat singleHrs; //定义好的，每一个格子的小时数
    int totalCout; //总共的格子数量

    if (self.rulerAverageType == rulerAverageTypeOne) {
        singleHrs = 0.5 * 360;
        totalCout = 24 * 2;
    }
    else if (self.rulerAverageType == rulerAverageTypeTwo){
        singleHrs = 1 / 6.0f * 360;
        totalCout = 24 * 6;
    }
    else if (self.rulerAverageType == rulerAverageTypeThree){
        singleHrs = 1 / 12.0f * 360;
        totalCout = 24 * 12;
    }
    else if (self.rulerAverageType == rulerAverageTypeFour){
        singleHrs = 1 / 60.0f* 360;
        totalCout = 24 * 60;
    }
    else if (self.rulerAverageType == rulerAverageTypeFive){
        singleHrs = 1 / 120.0f* 360;
        totalCout = 24 * 120;
    }
    else{
        singleHrs = 1 / 360.0f* 360;
        totalCout = 24 *360;
    }
//
//    // 蓝色指示器
//    self.indicatorLayer = [CAShapeLayer layer];
//    self.indicatorLayer.strokeColor = [UIColor blueColor].CGColor;
//    self.indicatorLayer.fillColor = [UIColor blueColor].CGColor;
//    self.indicatorLayer.lineWidth = 1.0f;
//    self.indicatorLayer.lineCap = kCALineCapSquare;
//    
//    CGMutablePathRef pathLine = CGPathCreateMutable();
//    CGPathMoveToPoint(pathLine, NULL, [self getXFromScrollViewWithAccuracyStamp:value], DISTANCETOPANDBOTTOM);
//    CGPathAddLineToPoint(pathLine, NULL, [self getXFromScrollViewWithAccuracyStamp:value] , DISTANCETOPANDBOTTOM - 8);
//    CGPathAddLineToPoint(pathLine, NULL, [self getXFromScrollViewWithAccuracyStamp:value] - 5, DISTANCETOPANDBOTTOM);
//    CGPathMoveToPoint(pathLine, NULL, [self getXFromScrollViewWithAccuracyStamp:value], DISTANCETOPANDBOTTOM - 8);
//    CGPathAddLineToPoint(pathLine, NULL, [self getXFromScrollViewWithAccuracyStamp:value], 0);
//    self.indicatorLayer.path = pathLine;
//    [self.layer addSublayer:self.indicatorLayer];
    
    if (isScrolling && _canScroll) {
        self.rulerValue = value;
//        [self setContentOffset:CGPointMake(MYDISTANCEVALUE * (self.rulerValue / (singleHrs *10)), 0) animated:YES];
        self.contentOffset = CGPointMake(MYDISTANCEVALUE * (self.rulerValue / (singleHrs *10)), 0);
    }

}

- (void)playViewDrawCurrentIndicatorWithValue:(NSInteger)value withScroll:(BOOL)isScrolling{
    
    if (self.indicatorLayer) {
        [self.indicatorLayer removeFromSuperlayer];
    }
    
    CGFloat singleHrs; //定义好的，每一个格子的小时数
    int totalCout; //总共的格子数量
    
    if (self.rulerAverageType == rulerAverageTypeOne) {
        singleHrs = 0.5 * 360;
        totalCout = 24 * 2;
    }
    else if (self.rulerAverageType == rulerAverageTypeTwo){
        singleHrs = 1 / 6.0f * 360;
        totalCout = 24 * 6;
    }
    else if (self.rulerAverageType == rulerAverageTypeThree){
        singleHrs = 1 / 12.0f * 360;
        totalCout = 24 * 12;
    }
    else if (self.rulerAverageType == rulerAverageTypeFour){
        singleHrs = 1 / 60.0f* 360;
        totalCout = 24 * 60;
    }
    else if (self.rulerAverageType == rulerAverageTypeFive){
        singleHrs = 1 / 120.0f* 360;
        totalCout = 24 * 120;
    }
    else{
        singleHrs = 1 / 360.0f* 360;
        totalCout = 24 *360;
    }
    if (isScrolling) {
        self.rulerValue = value;
//        [self setContentOffset:CGPointMake(MYDISTANCEVALUE * (self.rulerValue / (singleHrs *10)), 0) animated:YES];
        self.contentOffset = CGPointMake(MYDISTANCEVALUE * (self.rulerValue / (singleHrs *10)), 0);
    }
    
}


- (void)playViewTimeIntervalDrawCurrentIndicatorWithValue:(NSInteger)value withScroll:(BOOL)isScrolling{
    
    if (self.indicatorLayer) {
        [self.indicatorLayer removeFromSuperlayer];
    }
    
    CGFloat singleHrs; //定义好的，每一个格子的小时数
    int totalCout; //总共的格子数量
    
    if (self.rulerAverageType == rulerAverageTypeOne) {
        singleHrs = 0.5 * 360;
        totalCout = 24 * 2;
    }
    else if (self.rulerAverageType == rulerAverageTypeTwo){
        singleHrs = 1 / 6.0f * 360;
        totalCout = 24 * 6;
    }
    else if (self.rulerAverageType == rulerAverageTypeThree){
        singleHrs = 1 / 12.0f * 360;
        totalCout = 24 * 12;
    }
    else if (self.rulerAverageType == rulerAverageTypeFour){
        singleHrs = 1 / 60.0f* 360;
        totalCout = 24 * 60;
    }
    else if (self.rulerAverageType == rulerAverageTypeFive){
        singleHrs = 1 / 120.0f* 360;
        totalCout = 24 * 120;
    }
    else{
        singleHrs = 1 / 360.0f* 360;
        totalCout = 24 *360;
    }
    if (isScrolling && _canScroll) {
        self.rulerValue = value;
        [self setContentOffset:CGPointMake(MYDISTANCEVALUE * (self.rulerValue / (singleHrs *10)), 0) animated:YES];
//        self.contentOffset = CGPointMake(MYDISTANCEVALUE * (self.rulerValue / (singleHrs *10)), 0);
    }
    
}

- (void)setRulerContentSizeWithValue:(NSInteger)value{
    CGFloat singleHrs; //定义好的，每一个格子的小时数
    int totalCout; //总共的格子数量
    
    if (self.rulerAverageType == rulerAverageTypeOne) {
        singleHrs = 0.5 * 360;
        totalCout = 24 * 2;
    }
    else if (self.rulerAverageType == rulerAverageTypeTwo){
        singleHrs = 1 / 6.0f * 360;
        totalCout = 24 * 6;
    }
    else if (self.rulerAverageType == rulerAverageTypeThree){
        singleHrs = 1 / 12.0f * 360;
        totalCout = 24 * 12;
    }
    else if (self.rulerAverageType == rulerAverageTypeFour){
        singleHrs = 1 / 60.0f* 360;
        totalCout = 24 * 60;
    }
    else if (self.rulerAverageType == rulerAverageTypeFive){
        singleHrs = 1 / 120.0f* 360;
        totalCout = 24 * 120;
    }
    else{
        singleHrs = 1 / 360.0f* 360;
        totalCout = 24 *360;
    }
   self.contentSize = CGSizeMake(MYDISTANCEVALUE * (24 *3600 / (singleHrs *10)) + DISTANCELEFTANDRIGHT * 2.f + self.rulerWidth, self.rulerHeight);
}


//处理捏合手势
//-(void)handlePinches:(UIPinchGestureRecognizer *)paramSender{
//    if (paramSender.state == UIGestureRecognizerStateChanged) {
//        CGFloat zoomScale = paramSender.scale;
//        NSLog(@"zoomScale-------%f",zoomScale);
//        if (zoomScale > 1) {
//            //放大
//            NSLog(@"放大");
//            if (self.rulerAverageType == rulerAverageTypeSix) {
//                 self.currentZoomScale = self.currentZoomScale * zoomScale;
////                if (self.currentZoomScale >= 1.5) {
////                    self.currentZoomScale = 1.5;
////                }
//                //重新绘制
//                [self drawRuler];
//                //已经最大
//                return;
//            }
//            else{
//                self.currentZoomScale = self.currentZoomScale * zoomScale;
////                if (self.currentZoomScale >= 1.5) {
////                    self.currentZoomScale = 1.0f;
////                    self.rulerAverageType = self.rulerAverageType + 1;
////                    //重新绘制
////                    [self drawRuler];
////                }
////                else{
//                    [self drawRuler];
////                }
//            }
//        }
//
//        if (zoomScale < 1) {
//            //缩小一次
//            NSLog(@"缩小");
//            if (self.rulerAverageType == rulerAverageTypeOne) {
//                //已经最小
//                self.currentZoomScale = self.currentZoomScale * zoomScale;
//                if (self.currentZoomScale <= 1.0f) {
//                    self.currentZoomScale = 1.0f;
//                }
//                //重新绘制
//                [self drawRuler];
//            }
//            else{
//                self.currentZoomScale = self.currentZoomScale * zoomScale;
//                if (self.currentZoomScale < 1.0f) {
//                    self.currentZoomScale = 1.0f;
//                    self.rulerAverageType = self.rulerAverageType - 1;
//                    //重新绘制
//                    [self drawRuler];
//                }
//                else{
//                    [self drawRuler];
//                }
//            }
//        }
//    }
//}




//处理捏合手势
-(void)handlePinches:(UIPinchGestureRecognizer *)paramSender{
    if (paramSender.state == UIGestureRecognizerStateBegan) {
        //初始值是1.0f 更改百分之十执行放大缩小
        self.gesZoomScale = 1.0f;
        self.canScroll = NO;
        self.pinching = YES;
    }
    
    if (paramSender.state == UIGestureRecognizerStateEnded||paramSender.state == UIGestureRecognizerStateCancelled) {
        self.pinching = NO;
        [self setCanScrollDelayEnableIsGes:YES];
    }
    if (paramSender.state == UIGestureRecognizerStateChanged) {

        CGFloat zoomScale = paramSender.scale;
        CGFloat divValue = zoomScale / self.gesZoomScale;
        NSLog(@"zoomScale----------%f",zoomScale);
        if (divValue >= 1.1 || (divValue >= 1.05 && self.gesZoomScale >1.5f)) {
            self.gesZoomScale = zoomScale;
            //放大
            NSLog(@"放大");
            if (self.rulerAverageType == rulerAverageTypeSix) {
                //已经最大
                [self drawRuler];
                return;
            }
            else{
                self.rulerAverageType = self.rulerAverageType + 1;
                //重新绘制
                [self drawRuler];
            }
        }

        if ((divValue <= 0.95 && self.gesZoomScale >1.0f) || divValue <= 0.9f) {
            self.gesZoomScale = zoomScale;
            //缩小一次
            NSLog(@"缩小");
            if (self.rulerAverageType == rulerAverageTypeOne) {
                //已经最小
                return;
            }
            else{
                self.rulerAverageType = self.rulerAverageType - 1;
                //重新绘制
                [self drawRuler];

            }
        }
    }
}

-(void)zoomToMAX{
    self.rulerAverageType = rulerAverageTypeSix;
    [self drawRuler];
}


- (void)setCanScroll:(BOOL)canScroll{
    _canScroll = canScroll;
    
    //取消延时操作
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(enableSrollViewCanScroll) object:nil];
}

- (void)setCanScrollDelayEnableIsGes:(BOOL)isGes{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(enableSrollViewCanScroll) object:nil];
    if (isGes) {
        [self performSelector:@selector(enableSrollViewCanScroll) withObject:nil afterDelay:2];
    }
    else{
        [self performSelector:@selector(enableSrollViewCanScroll) withObject:nil afterDelay:5];
    }

}

- (void)enableSrollViewCanScroll{
    self.canScroll = YES;
}




- (NSString *)getTimeTextWithValue:(NSUInteger)TimeValue{
    NSString *timeText;
    int hrs = (int)TimeValue / 3600;
    int totolSecond = (int)TimeValue % 3600;
    int min = (int)totolSecond / 60;
    int second = (int)totolSecond % 60;
    if (self.rulerAverageType == rulerAverageTypeSix) {
        //显示秒数
        timeText = [NSString stringWithFormat:@"%02d:%02d:%02d",hrs,min,second];
    }
    else{
        timeText = [NSString stringWithFormat:@"%02d:%02d",hrs,min];
    }
    //    timeText = [NSString stringWithFormat:@"%02d:%02d:%02d",hrs,min,second];
    return timeText;
}

- (void)drawVideoView{
    //开始绘制 -- 先移除旧的
    for (UIView *videoView in self.videoViewArray) {
        [videoView removeFromSuperview];
    }
    [self.videoViewArray removeAllObjects];
    _SDVideoArray = nil;
    _SDMoveDetectArray = nil;
    //开始绘制
    for (CloudVideoModel *videoModel in self.videoArray) {
        CGFloat left = [self getXFromScrollViewWithAccuracyStamp:videoModel.accuracyfirstStamp];
        CGFloat right = [self getXFromScrollViewWithAccuracyStamp:videoModel.accuracylastStamp];
        CGRect viewRect = CGRectMake(left, 0, right - left, 80);
        UIView *view = [[UIView alloc]initWithFrame:viewRect];
        if (videoModel.alarmType == 1) {
            //移动侦测
            view.backgroundColor = [UIColor orangeColor];
        }
        else if (videoModel.alarmType == 4){
            //声音侦测
            view.backgroundColor = [UIColor colorWithHexString:@"0xDA70D6"];
        }
        else if (videoModel.alarmType == 6 || videoModel.alarmType == 7){
            //温度报警 6,7
            view.backgroundColor = [UIColor colorWithHexString:@"0xFF0066"];
        }
        else{
            //灰色
            view.backgroundColor = [UIColor lightGrayColor];
        }
        
        [self addSubview:view];
        [self.videoViewArray addObject:view];
        //放在最下面
        [self insertSubview:view atIndex:0];
    }
}


- (void)drawAlarmView{
    //开始绘制 -- 先移除旧的
    for (UIView *alarmView in self.alarmViewArray) {
        [alarmView removeFromSuperview];
    }
    [self.alarmViewArray removeAllObjects];
    _SDVideoArray = nil;
    _SDMoveDetectArray = nil;
    //开始绘制
    for (CloudAlarmModel *alarmModel in self.moveDetectArray) {
        CGFloat left = [self getXFromScrollViewWithAccuracyStamp:alarmModel.accuracyTimeStamp];
        CGFloat right = [self getXFromScrollViewWithAccuracyStamp:alarmModel.accuracyTimeStamp + 20];
        CGRect viewRect = CGRectMake(left, 0, right - left, 80);
        UIView *view = [[UIView alloc]initWithFrame:viewRect];
        view.backgroundColor = [UIColor orangeColor];
        [self addSubview:view];
        [self.alarmViewArray addObject:view];
    }
}

- (void)drawSDVideoView{
    //开始绘制 -- 先移除旧的
    for (UIView *videoView in self.videoViewArray) {
        [videoView removeFromSuperview];
    }
    [self.videoViewArray removeAllObjects];
    _moveDetectArray = nil;
    _videoArray = nil;
    //开始绘制
    for (SDCloudVideoModel *videoModel in self.SDVideoArray) {
        CGFloat left = [self getXFromScrollViewWithAccuracyStamp:videoModel.accuracyfirstStamp];
        CGFloat right = [self getXFromScrollViewWithAccuracyStamp:videoModel.accuracylastStamp];
        CGRect viewRect = CGRectMake(left, 0, right - left, 80);
        UIView *view = [[UIView alloc]initWithFrame:viewRect];
        view.backgroundColor = [UIColor lightGrayColor];
        [self addSubview:view];
        [self.videoViewArray addObject:view];
        //放在最下面
        [self insertSubview:view atIndex:0];
    }
}


- (void)drawSDAlarmView{
    //开始绘制 -- 先移除旧的
    for (UIView *alarmView in self.alarmViewArray) {
        [alarmView removeFromSuperview];
    }
    [self.alarmViewArray removeAllObjects];
    _moveDetectArray = nil;
    _videoArray = nil;
    //开始绘制
    for (SDCloudAlarmModel *alarmModel in self.SDMoveDetectArray) {
        CGFloat left = [self getXFromScrollViewWithAccuracyStamp:alarmModel.accuracyfirstStamp];
        CGFloat right = [self getXFromScrollViewWithAccuracyStamp:alarmModel.accuracylastStamp];
        CGRect viewRect = CGRectMake(left, 0, right - left, 80);
        UIView *view = [[UIView alloc]initWithFrame:viewRect];
        if (alarmModel.AT == 1) {
            //移动侦测
            view.backgroundColor = [UIColor orangeColor];
        }
        else if (alarmModel.AT == 4){
            //声音侦测
            view.backgroundColor = [UIColor colorWithHexString:@"0xDA70D6"];
        }
        else{
            //温度报警6,7
            view.backgroundColor = [UIColor colorWithHexString:@"0xFF0066"];
        }
        
        [self addSubview:view];
        [self.alarmViewArray addObject:view];
    }
}

- (CGFloat)getXFromScrollViewWithAccuracyStamp:(long long)timeStamp{
    
    if (timeStamp > 24 * 3600) {
        timeStamp = 24 * 3600;
    }
    
    if (timeStamp < 0) {
        timeStamp = 0;
    }
    
    int totalCout; //总共的格子数量
    
    if (self.rulerAverageType == rulerAverageTypeOne) {
        totalCout = 24 * 2;
    }
    else if (self.rulerAverageType == rulerAverageTypeTwo){
        totalCout = 24 * 6;
    }
    else if (self.rulerAverageType == rulerAverageTypeThree){
        totalCout = 24 * 12;
    }
    else if (self.rulerAverageType == rulerAverageTypeFour){
        totalCout = 24 * 60;
    }
    else if (self.rulerAverageType == rulerAverageTypeFive){
        totalCout = 24 * 120;
    }
    else{
        totalCout = 24 *360;
    }
    
    float ratio = timeStamp/(24 * 3600.0f);
    CGFloat X = (ratio * totalCout * MYDISTANCEVALUE) + self.rulerWidth/2.0f;
    return X;
}

- (void)initialized{
    //初始化
    self.rulerAverageType = rulerAverageTypeOne;
    self.contentSize = CGSizeMake(48 * MYDISTANCEVALUE + DISTANCELEFTANDRIGHT * 2.f + self.rulerWidth, self.rulerHeight);
    self.rulerValue = 0;
}

#pragma mark - Getter && Setter
- (void)setVideoArray:(NSArray *)videoArray{
    _SDMoveDetectArray = nil;
    _SDVideoArray = nil;
    _videoArray = [videoArray mutableCopy];
    [self drawVideoView];
}


- (void)setMoveDetectArray:(NSArray *)moveDetectArray{
    _SDMoveDetectArray = nil;
    _SDVideoArray = nil;
    _moveDetectArray = [moveDetectArray mutableCopy];
    [self drawAlarmView];
}


- (void)setSDVideoArray:(NSArray *)SDVideoArray{
    _moveDetectArray = nil;
    _videoArray = nil;
    _SDVideoArray = [SDVideoArray mutableCopy];
    [self drawSDVideoView];
}


- (void)setSDMoveDetectArray:(NSArray *)SDMoveDetectArray{
    _moveDetectArray = nil;
    _videoArray = nil;
    _SDMoveDetectArray = [SDMoveDetectArray mutableCopy];
    [self drawSDAlarmView];
}

#pragma mark - Getter && Setter

- (NSMutableArray *)layerArray{
    if (!_layerArray) {
        _layerArray = [NSMutableArray array];
    }
    return _layerArray;
}

- (NSMutableArray *)labelArray{
    if (!_labelArray) {
        _labelArray = [NSMutableArray array];
    }
    return _labelArray;
}


- (NSMutableArray *)videoViewArray{
    if (!_videoViewArray) {
        _videoViewArray = [NSMutableArray array];
    }
    return _videoViewArray;
}


- (NSMutableArray *)alarmViewArray{
    if (!_alarmViewArray) {
        _alarmViewArray = [NSMutableArray array];
    }
    return _alarmViewArray;
}

@end

