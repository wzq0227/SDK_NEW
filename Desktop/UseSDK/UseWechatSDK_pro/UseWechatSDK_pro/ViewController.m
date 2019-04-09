//
//  ViewController.m
//  UseWechatSDK_pro
//
//  Created by AnDong on 2019/4/9.
//  Copyright © 2019年 zz. All rights reserved.
//

#import "ViewController.h"
#import <WechatPaySDK/WechatPaySDK.h>
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    WechatSpay * pay = [[WechatSpay alloc]init];
    [pay spay:1000000];
}


@end
