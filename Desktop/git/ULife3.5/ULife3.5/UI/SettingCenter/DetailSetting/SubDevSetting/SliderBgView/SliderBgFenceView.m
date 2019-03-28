//
//  SliderBgFenceView.m
//  ULife3.5
//
//  Created by Goscam on 2018/3/22.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "SliderBgFenceView.h"

#define LeadingSpace (32)

@implementation SliderBgFenceView

- (instancetype)initWithFrame:(CGRect)frame{
    self =[super initWithFrame:frame];
    if (self) {
        [self preSetSlider];
    }
    return self;
}

- (void)awakeFromNib{
    [super awakeFromNib];
    
    [self preSetSlider];
}


- (void)drawRect:(CGRect)rect {
    
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, self.trackColor.CGColor);
    
    CGFloat itemSpacing = (self.bounds.size.width-64)/_sections;
    CGFloat H = self.bounds.size.height;
    
    //画|    (i==_sections-1?-5:1)*1
    for (int i=0; i<=_sections; i++) {
        if (i == 1)
            continue;
        
        
        if (i<_curPosition) {
            CGContextSetStrokeColorWithColor(context, self.thumbTintColor.CGColor);
            CGContextSetLineWidth(context, 1.0);
        }else{
            CGContextSetStrokeColorWithColor(context, self.trackColor.CGColor);
            CGContextSetLineWidth(context, 1.0);
        }
        CGPoint startP = CGPointMake(LeadingSpace+i*itemSpacing, 0) ;
        CGPoint endP = CGPointMake(LeadingSpace+i*itemSpacing, H) ;

        CGContextMoveToPoint(context, startP.x, startP.y);
        CGContextAddLineToPoint(context, endP.x, endP.y);
        
        CGContextStrokePath(context);
    }
    //画横线
    if (_curPosition>0) {
        CGContextSetStrokeColorWithColor(context, self.thumbTintColor.CGColor);
        CGContextSetLineWidth(context, 1.0);
        
        CGPoint startP = CGPointMake(LeadingSpace, H/2) ;
        CGPoint endP = CGPointMake(LeadingSpace+_curPosition*itemSpacing, H/2) ;
        
        CGContextMoveToPoint(context, startP.x, startP.y);
        CGContextAddLineToPoint(context, endP.x, endP.y);
        
        CGContextStrokePath(context);
    }
    
    if (_curPosition < _sections) {
        CGContextSetStrokeColorWithColor(context, self.trackColor.CGColor);
        CGContextSetLineWidth(context, 1.0);
        
        CGPoint startP = CGPointMake(LeadingSpace+_curPosition*itemSpacing, H/2) ;
        CGPoint endP = CGPointMake(LeadingSpace+_sections*itemSpacing, H/2) ;
        
        CGContextMoveToPoint(context, startP.x, startP.y);
        CGContextAddLineToPoint(context, endP.x, endP.y);
        
        CGContextStrokePath(context);
    }
 
    // Drawing code
}

- (void)preSetSlider{
    _trackColor = [UIColor blackColor];
    _thumbTintColor = [UIColor blackColor];//myColor;
    _sections = 5;
}

- (void)setSections:(int)sections{
    _sections = sections;
    [self setNeedsDisplay];
}

@end
