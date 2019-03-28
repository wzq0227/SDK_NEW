//
//  PIRSliderView.h
//  ULife3.5
//
//  Created by Goscam on 2018/5/8.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^SliderValueChangeBlock)(int value);


@interface PIRSliderView : UIView


/**
 根据frame和titles返回自定义的slider
 @param frame 视图frame
 @return slider实例
 */
- (instancetype)initWithFrame:(CGRect)frame ;


/** 距离两侧的边距 */
@property (assign, nonatomic)  float leadingSpace;


@property (strong, nonatomic)  UISlider *sliderForPirValueSetting;


@property (strong, nonatomic)  NSArray <NSString*> *titlesArray;

- (void)sliderValueChangeCallback:(SliderValueChangeBlock)valueChangeBlock;

@end
