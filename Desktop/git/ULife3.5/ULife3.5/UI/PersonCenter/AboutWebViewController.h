//
//  AboutWebViewController.h
//  ULife3.5
//
//  Created by 广东省深圳市 on 2017/8/2.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AboutWebViewController : UIViewController

@property (nonatomic,copy)NSString *loadUrl;

- (instancetype)initWithTitle:(NSString*)title urlStr:(NSString*)urlStr;
    


@end
