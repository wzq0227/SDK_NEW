//
//  BlackLineCustomView.m
//  ULife3.5
//
//  Created by zhuochuncai on 7/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "BlackLineCustomView.h"

@implementation BlackLineCustomView

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.

- (void)drawRect:(CGRect)rect {

    CGContextRef context = UIGraphicsGetCurrentContext();
    
    
    CGContextSetStrokeColorWithColor(context, (BACKCOLOR(90,90,90,1)).CGColor);
    CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 1.0);
    
    CGFloat W = self.bounds.size.width;
    CGFloat H = self.bounds.size.height;
    
    // Draw them with a 2.0 stroke width so they are a bit more visible.
    CGContextSetLineWidth(context, 1.0);
    
    for(int idx = 0; idx < 10; idx++)
    {
        if (idx < 2) {
            
            if (idx ==0 || idx == 1 ) {//排除边框半个像素差
                CGContextMoveToPoint(context, 0, idx*H + (idx == 0 ?1:-1)*0.5);
                CGContextAddLineToPoint(context, W, idx*H + (idx == 0 ?1:-1)*0.5);
            }
        }else{
            if (idx ==2 || idx == 9 ) {
                CGContextMoveToPoint(context, (idx-2)*W/7 + (idx == 2 ?1:-1)*0.5, 0);
                CGContextAddLineToPoint(context, (idx-2)*W/7 + (idx == 2 ?1:-1)*0.5,H);
                
            }else{
                CGContextMoveToPoint(context, (idx-2)*W/7, 0 );
                CGContextAddLineToPoint(context,  (idx-2)*W/7,H);
            }
        }
    }
    
    CGContextStrokePath(context);
}

@end
