//
//  UIAlertController+Window.m
//  ULife3.5
//
//  Created by Goscam on 2018/5/2.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "UIAlertController+Window.h"
#import <objc/runtime.h>

@interface UIAlertController(private)
@property (strong, nonatomic)  UIWindow *alertWindow;
@end

@implementation UIAlertController(private)
@dynamic alertWindow;

- (void)setAlertWindow:(UIWindow *)alertWindow{
    objc_setAssociatedObject(self, @selector(alertWindow), alertWindow, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIWindow*)alertWindow{
    return objc_getAssociatedObject(self, @selector(alertWindow));
}

@end



@implementation UIAlertController (Window)

- (void)show {
    [self show:YES];
}

- (void)show:(BOOL)animated {
    self.alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.alertWindow.rootViewController = [UIViewController new];
    
    id<UIApplicationDelegate> delegate = [UIApplication sharedApplication].delegate;
    if ([delegate respondsToSelector:@selector(window)]) {
        self.alertWindow.tintColor = delegate.window.tintColor;
    }
    
    UIWindow *topWindow = [UIApplication sharedApplication].windows.lastObject;
    self.alertWindow.windowLevel = topWindow.windowLevel + 1;
    
    [self.alertWindow makeKeyAndVisible];
    [self.alertWindow.rootViewController presentViewController:self animated:animated completion:nil];
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // precaution to ensure window gets destroyed
    self.alertWindow.hidden = YES;
    self.alertWindow = nil;
}

@end
