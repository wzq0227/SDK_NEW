//
//  RecordImageShowViewController.m
//  goscamapp
//
//  Created by shenyuanluo on 2017/4/28.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "RecordImageShowViewController.h"

@interface RecordImageShowViewController ()

/**
 *  显示录像‘图片’ ImageView
 */
@property (weak, nonatomic) IBOutlet UIImageView *recordImageView;
@end

@implementation RecordImageShowViewController

#pragma mark - ViewController 生命周期
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initParameter];
    
    [self configUI];
    
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)dealloc
{
    NSLog(@"录像‘图片’查看页面 - dealloc");
}



#pragma mark - 初始化设置相关
#pragma mark -- 初始化参数
- (void)initParameter
{
    
}


#pragma mark -- 设置相关 UI
- (void)configUI
{
    self.title = self.recordImgFileName;
    
    UIImage *image = [UIImage imageWithContentsOfFile:self.recordImgFilePath];
    if (!image) {
        self.recordImageView.image = [UIImage imageNamed:@"defaultCovert.jpg"];
    }else{
        self.recordImageView.image = image;
    }
}





#pragma mark - 横竖屏切换相关
#pragma mark -- 是否允许横竖屏
-(BOOL)shouldAutorotate
{
    return NO;
}


#pragma mark -- 横竖屏方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
