//
//  TsButton.m
//  QQI
//
//  Created by goscam on 16/5/9.
//  Copyright © 2016年 yuanx. All rights reserved.
//

#import "TsButton.h"
#import "UIColor+YYAdd.h"

@implementation TsButton



//当.nib文件被加载的时候，会发送一个awakeFromNib的消息到.nib文件中的每个对象
-(void)awakeFromNib
{
    [super awakeFromNib];
    
    // 默认圆角
    CGFloat cornerRadiusSize = 6.0f;

    self.layer.cornerRadius = cornerRadiusSize;
    
    // 默认背景颜色
    self.backgroundColor = myColor;
    
    // 设置 Button 点击背景样式
//    __weak typeof (self)weakSelf = self;
//    [self addTarget:weakSelf
//             action:@selector(btnBGColorHighlighted:)
//   forControlEvents:UIControlEventTouchDown];
//    [self addTarget:weakSelf
//             action:@selector(btnBGColorNormal:)
//   forControlEvents:UIControlEventTouchUpInside];
    
    // 设置 Button title 样式
    [self setTitleColor:[UIColor whiteColor]
               forState:UIControlStateNormal];
//    [self setTitleColor:[ConfigureFile getConfigColor:@"BUTTON_BG_COLOR"]
//               forState:UIControlStateHighlighted];
}


//#pragma mark -- UIButton 普通状态下的背景色
//- (void)btnBGColorNormal:(UIButton *)sender
//{
//    sender.backgroundColor = [ConfigureFile getConfigColor:@"BUTTON_BG_COLOR"];
//}
//
//#pragma mark -- UIButton 高亮状态下的背景色
//- (void)btnBGColorHighlighted:(UIButton *)sender
//{
//    sender.backgroundColor = [UIColor whiteColor];
//}

@end
