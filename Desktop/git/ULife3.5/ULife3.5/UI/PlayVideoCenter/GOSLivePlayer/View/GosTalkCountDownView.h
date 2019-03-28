//
//  GosTalkCountDownView.h
//  ULife3.5
//
//  Created by Goscam on 2018/4/11.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GosTalkCountDownView : UIView

@property (assign, nonatomic)  NSUInteger totalSeconds;

@property (assign, nonatomic)  NSUInteger remainSeconds;

- (void)configView;
@end
