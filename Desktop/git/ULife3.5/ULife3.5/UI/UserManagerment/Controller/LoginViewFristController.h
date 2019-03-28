//
//  LoginViewController.h
//  gaoscam
//
//  Created by goscam_sz on 17/4/19.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewFristController : UIViewController <UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,copy) NSString * acount;

@property (nonatomic,copy) NSString * password;

@end
