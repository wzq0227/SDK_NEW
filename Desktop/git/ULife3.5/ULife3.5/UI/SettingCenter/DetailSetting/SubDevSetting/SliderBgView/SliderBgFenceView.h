//
//  SliderBgFenceView.h
//  ULife3.5
//
//  Created by Goscam on 2018/3/22.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SliderBgFenceView : UIView


/** 分成几段 */
@property (assign, nonatomic)  int sections;


/** 当前滑块在哪个位置 0-5*/
@property (assign, nonatomic)  int curPosition;

@property (strong, nonatomic)  UIColor *trackColor;

@property (strong, nonatomic)  UIColor *thumbTintColor;

@end
