//
//  JumpWiFiTipsView.h
//  ULife3.5
//
//  Created by AnDong on 2018/9/18.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>



typedef void(^FinishBlock)(void);


@interface JumpWiFiTipsViewControl : UIControl
+ (void)showTip;

@end


@interface JumpWiFiTipsView : UIView
@property (nonatomic, copy) FinishBlock block;
@end
