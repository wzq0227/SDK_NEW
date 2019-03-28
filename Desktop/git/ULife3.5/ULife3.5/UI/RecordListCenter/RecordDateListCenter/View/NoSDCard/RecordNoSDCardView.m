//
//  RecordNoSDCardView.m
//  ULife3.5
//
//  Created by zhuochuncai on 13/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "RecordNoSDCardView.h"

@implementation RecordNoSDCardView

-(void)awakeFromNib{
    [super awakeFromNib];
    for (UIView *view in self.noSDCardIconArray) {
        view.layer.cornerRadius = 5;
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
