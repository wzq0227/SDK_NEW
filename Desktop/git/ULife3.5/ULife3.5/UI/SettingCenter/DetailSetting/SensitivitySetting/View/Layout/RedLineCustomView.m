//
//  RedLineCustomView.m
//  ULife3.5
//
//  Created by zhuochuncai on 7/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "RedLineCustomView.h"

@interface RedLineCustomView(){
    
}
@property(nonatomic,strong)NSMutableArray *posArray;
@end

@implementation RedLineCustomView

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {

    self.clipsToBounds = NO;
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetShouldAntialias(context, NO);
    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
    CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
    
    CGFloat W = self.bounds.size.width;
    CGFloat H = self.bounds.size.height;
    
    // Draw them with a 2.0 stroke width so they are a bit more visible.
    
//    for(int idx = 0; idx < 10; idx++){
//        if (idx < 5) {
//            
//            if (idx ==0 || idx == 4 ) {//排除边框半个像素差
//                CGContextSetLineWidth(context, 1.0);
//
//                CGContextMoveToPoint(context, 0, idx*H/4 + (idx == 0 ?1:-1)*0.5);
//                CGContextAddLineToPoint(context, W, idx*H/4 + (idx == 0 ?1:-1)*0.5);
//                
//                CGContextStrokePath(context);
//            }else{
//                CGContextSetLineWidth(context, 2.0);
//
//                CGContextMoveToPoint(context, 0, idx*H/4);
//                CGContextAddLineToPoint(context, W, idx*H/4);
//                
//                CGContextStrokePath(context);
//            }
//        }else{
//            if (idx ==5 || idx == 9 ) {
//                CGContextSetLineWidth(context, 1.0);
//
//                CGContextMoveToPoint(context, (idx-5)*W/4 + (idx == 5 ?1:-1)*0.5, 0);
//                CGContextAddLineToPoint(context, (idx-5)*W/4 + (idx == 5 ?1:-1)*0.5,H);
//                
//                CGContextStrokePath(context);
//            }else{
//                CGContextSetLineWidth(context, 2.0);
//
//                CGContextMoveToPoint(context, (idx-5)*W/4, 0 );
//                CGContextAddLineToPoint(context,  (idx-5)*W/4,H);
//                
//                CGContextStrokePath(context);
//            }
//        }
//    }

    //startP= n+n/4 endP= startP + 6; 从左上角开始，沿着顺时针画框
    for (int i =0; i<16; i++) {
        BOOL isSelected = (self.selectedArea >> i)&1;
        int     pos1 = i/4 + i;
        CGPoint startP = CGPointFromString(self.posArray[pos1]) ;
        CGPoint endP = CGPointFromString(self.posArray[pos1+6]) ;
        
        //            CGFloat sX = startP.x;
        //            CGFloat sY = startP.y;
        CGFloat eX = endP.x;
        CGFloat eY = endP.y;
        if (eX < W-0.5) {//起始点位置不变,每个框的终点(右下角那个点)X和Y都减一
            eX-=0.5;
        }
        if (eY < H -0.5) {
            eY-=0.5;
        }

        if (isSelected) {
            CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
            CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 1.0);
            CGContextSetLineWidth(context, 1.0);
        }else{
            CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
            CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
            CGContextSetLineWidth(context, 1.0);
        }
        CGContextMoveToPoint(context, startP.x, startP.y);
        CGContextAddLineToPoint(context, eX, startP.y);
        
        CGContextAddLineToPoint(context, eX, eY);
        
        CGContextAddLineToPoint(context, startP.x, eY);
        
        CGContextAddLineToPoint(context, startP.x, startP.y);
        CGContextStrokePath(context);
    }
    
//    CGContextStrokePath(context);
}

- (NSMutableArray *)posArray{
    if (!_posArray) {
        CGFloat W = self.bounds.size.width;
        CGFloat H = self.bounds.size.height;

        _posArray = [NSMutableArray arrayWithCapacity:1];
        for (int i =0; i<5; i++) {
            for (int j=0; j<5; j++) {
                CGFloat posX = (j*W/4) ;
                CGFloat posY = (i*H/4) ;
                if (j==0|| j==4) {
                    posX += j==0? 0.5 : -0.5;
                }
                if (i==0 || i==4) {
                    posY += i==0? 0.5 : -0.5;
                }
                CGPoint point = CGPointMake(posX, posY);
                [_posArray addObject:NSStringFromCGPoint(point)];
            }
        }
    }
    return _posArray;
}

@end
