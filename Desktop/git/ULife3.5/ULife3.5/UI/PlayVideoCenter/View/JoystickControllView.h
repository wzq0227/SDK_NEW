//
//  JoystickControllView.h
//  goscamapp
//
//  Created by shenyuanluo on 2017/4/28.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JoystickControllView : UIView

/**
 *  ‘向上移动’ Button
 */
@property (strong, nonatomic)  UIButton *moveUpBtn;

/**
 *  ‘向右移动’ Button
 */
@property (strong, nonatomic)  UIButton *moveRightBtn;

/**
 *  ‘向左移动’ Button
 */
@property (strong, nonatomic)  UIButton *moveLeftBtn;

/**
 *  ‘向下移动’ Button
 */
@property (strong, nonatomic)  UIButton *moveDownBtn;

/**
 *  ‘摇杆’ label
 */
@property (strong, nonatomic)  UILabel *joyStickLabel;

@end
