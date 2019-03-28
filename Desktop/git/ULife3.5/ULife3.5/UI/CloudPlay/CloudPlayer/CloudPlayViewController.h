//
//  CloudPlayViewController.h
//  TestAli
//
//  Created by AnDong on 2017/10/9.
//  Copyright © 2017年 AnDong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CloudPlayViewController : UIViewController

//设备id
@property (nonatomic,copy)NSString *deviceId;

- (void)convertMP4WithStartValue:(NSInteger)startValue totalValue:(NSInteger)totalValue fileName:(NSString *)fileName;

@end
