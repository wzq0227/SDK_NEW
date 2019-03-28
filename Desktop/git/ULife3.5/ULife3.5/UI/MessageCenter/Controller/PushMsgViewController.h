//
//  PushMsgViewController.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/12.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PushMsgViewController : UIViewController

@property (nonatomic,assign)BOOL isPushedIn;

//指定设备的推送消息
@property (nonatomic,copy)NSString *deviceID;

@property (nonatomic,copy)NSString *subId;

@end
