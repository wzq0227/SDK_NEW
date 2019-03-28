//
//  DeviceUpdateView.h
//  ULife2
//
//  Created by zhuochuncai on 16/5/17.
//  Copyright © 2017年 zhuochuncai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DeviceUpdateView : UIView
@property (weak, nonatomic) IBOutlet UITextView *updateTipsTxtView;

@property (weak, nonatomic) IBOutlet UILabel *updateTitleLabel;


@property (weak, nonatomic) IBOutlet UIProgressView *updateProgressView;


@property (weak, nonatomic) IBOutlet UILabel *updateProgressLabel;


@property (weak, nonatomic) IBOutlet UIButton *cancelUpdateBtn;

@end
