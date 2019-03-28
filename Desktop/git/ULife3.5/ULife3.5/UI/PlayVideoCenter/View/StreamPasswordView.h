//
//  StreamPasswordView.h
//  ULife3.5
//
//  Created by AnDong on 2017/11/3.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StreamPasswordView : UIView

@property (nonatomic,strong)UITextField *pswTf;

@property (nonatomic,strong)UIButton *confirmBtn;

+ (instancetype)passwordView;

- (void)show;

- (void)dismiss;

@end
