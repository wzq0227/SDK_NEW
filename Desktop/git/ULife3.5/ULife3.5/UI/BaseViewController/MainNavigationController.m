//
//  MainNavigationController.m
//  goscamapp
//
//  Created by goscam_sz on 17/5/6.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "MainNavigationController.h"



@interface MainNavigationController ()

@end

@implementation MainNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
//{
//    return [[AppInfomation sharedInstance] isPlayerViewShown];
//}

-(BOOL)shouldAutorotate{
    return self.topViewController.shouldAutorotate;
}


- (NSUInteger)supportedInterfaceOrientations
{
    return self.topViewController.supportedInterfaceOrientations;
    //UIInterfaceOrientationMaskAllButUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    NSLog(@"1 preferredInterfaceOrientationForPresentation");
    return UIInterfaceOrientationPortrait;
}

@end
