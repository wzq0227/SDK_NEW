//
//  EnlargeClickButton.m
//  WiFi
//
//  Created by shenyuanluo on 2017/5/22.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "EnlargeClickButton.h"

@implementation EnlargeClickButton

#pragma mark -- 扩大点击范围
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    //获取当前button的实际大小
    CGRect bounds = self.bounds;
    
    //若原热区小于44x44，则放大热区，否则保持原大小不变
    CGFloat widthDelta = MAX(44.0 - bounds.size.width, 0);
    CGFloat heightDelta = MAX(44.0 - bounds.size.height, 0);
    
    //扩大bounds
    bounds = CGRectInset(bounds, -0.5 * widthDelta, -0.5 * heightDelta);
    
    //如果点击的点 在 新的bounds里，就返回YES
    return CGRectContainsPoint(bounds, point);
}

@end
