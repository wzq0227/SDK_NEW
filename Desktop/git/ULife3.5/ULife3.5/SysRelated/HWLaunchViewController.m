//
//  HWLaunchViewController.m
//  EChannel
//
//  Created by sunwanwan on 16/9/28.
//  Copyright © 2016年 HuaWei. All rights reserved.
//

#import "HWLaunchViewController.h"
#import "MainNavigationController.h"
#import "LoginViewFristController.h"
#import "Header.h"

//存入沙盒的图片索引key
#define userLaunchImageKey  @"launchlist"
#define userLaunchImageLastKey  @"launchlist-last"

@interface HWLaunchViewController () <UIScrollViewDelegate>
{
    UIScrollView *mainScrollView;
    UIButton *timerButton;
    NSTimer *timer;
    
    NSInteger totalTime;
    
    NSInteger firstToSeconedPage;
}

@property (nonatomic, strong) NSMutableArray *mainDataSource;

@property (nonatomic, strong) UIPageControl *pageControl;

@end

@implementation HWLaunchViewController

+ (instancetype)hwLaunchViewController
{
    HWLaunchViewController *viewController = [[HWLaunchViewController alloc] initWithNibName:nil bundle:nil];
    return viewController;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.view addSubview:self.pageControl];
    
    self.pageControl.userInteractionEnabled = NO;
    self.pageControl.numberOfPages = self.mainDataSource.count;
    self.pageControl.tag = 101;
    self.pageControl.currentPage = 0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    totalTime = 3;
    firstToSeconedPage = 0;
    
    // Do any additional setup after loading the view.
    self.mainDataSource = [[NSMutableArray alloc] init];
    [self setUI];
//    [self requestList];
//    timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countDown) userInfo:nil repeats:YES];
}

#pragma mark - setUI

- (void)setUI
{
    mainScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT + 20)];
    mainScrollView.bounces = NO;
    mainScrollView.pagingEnabled = YES;
    mainScrollView.showsHorizontalScrollIndicator = NO;
    mainScrollView.delegate = self;
    [self.view addSubview:mainScrollView];
    
//     NSArray *array = [self getSanboxURLArray];
//    if (!array)
//    {
    NSArray *localArray = [NSArray array];
    if (isENVersion) {
        localArray = @[@"user_guide1EN.jpg", @"user_guide2EN.jpg", @"user_guide3EN.jpg"];
    }
    else{
        localArray = @[@"user_guide1.jpg", @"user_guide2.jpg", @"user_guide3.jpg"];
    }
    
        for (NSString *imageName in localArray)
        {
            
//            UIImage *image = [[UIImage alloc]init];
        UIImage  *  image = [UIImage imageNamed:imageName];
            [self.mainDataSource addObject:image];
        }
//    }
 
    for (int i = 0; i < self.mainDataSource.count; i ++)
    {
        UIImage *image = self.mainDataSource[i];
        UIImageView *imageView = [self imageViewHandleWithImage:image];
        
        UIView * contentView = [[UIView alloc] initWithFrame:CGRectMake(i * SCREEN_WIDTH, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        contentView.clipsToBounds = YES;
        [contentView addSubview:imageView];
        
        [mainScrollView addSubview:contentView];
    }

    mainScrollView.contentSize = CGSizeMake(mainScrollView.size.width * self.mainDataSource.count, mainScrollView.size.height );

//    UIImage *image = [UIImage imageNamed:@"pass"];
//    [self.view addSubview:timerButton];
    
    //添加一个按钮
    UIButton *skipBtn = [[UIButton alloc]initWithFrame:CGRectMake((SCREEN_WIDTH - 135)/2 + SCREEN_WIDTH *2.0f, kScreen_Height - 150, 135, 50)];
    [skipBtn setBackgroundImage:[UIImage imageNamed:@"LaunchBtnNormal"] forState:UIControlStateNormal];
    [skipBtn setBackgroundImage:[UIImage imageNamed:@"LaunchBtnSelect"] forState:UIControlStateSelected];
    [skipBtn addTarget:self action:@selector(passLaunch) forControlEvents:UIControlEventTouchUpInside];
    [skipBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [skipBtn setTitle:DPLocalizedString(@"Start Now") forState:UIControlStateNormal];
    skipBtn.titleLabel.font = [UIFont systemFontOfSize:17.0f];
    skipBtn.titleLabel.textAlignment = NSTextAlignmentLeft;
    [mainScrollView addSubview:skipBtn];
}

#pragma mark - loadData

-(void)requestList
{
    
}


- (void)passLaunch
{

    mainScrollView.scrollEnabled = NO;
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    window.rootViewController = [[MainNavigationController alloc]initWithRootViewController:[[LoginViewFristController alloc]init]];
    
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    int current = scrollView.contentOffset.x / SCREEN_WIDTH;
    UIPageControl *page = (UIPageControl *)[self.view viewWithTag:101];
    page.currentPage = current;
    
    firstToSeconedPage = (current == 0) ? 0 : firstToSeconedPage;

    if (page.currentPage == self.mainDataSource.count - 1)
    {
        firstToSeconedPage += 1;
        
        if (firstToSeconedPage == 2)
        {
            if (timer.valid)
            {
                
            }
            else
            {
                [self passLaunch];
            }
        }
    }
}

#pragma mark - 沙盒广告页面图片校验方法

// 图片处理
- (UIImageView *)imageViewHandleWithImage:(UIImage *)image
{
    CGFloat imgWidth = image.size.width;
    CGFloat imgHeight = image.size.height;
    
    CGFloat sW = SCREEN_WIDTH / imgWidth;
    CGFloat sH = SCREEN_HEIGHT / imgHeight;
    
    CGFloat nowImageWidth;
    CGFloat nowImageHeight;
    
    if (sW > sH)
    {
        nowImageWidth = imgWidth * sW;
        nowImageHeight = imgHeight *sW;
    }
    else
    {
        nowImageWidth = imgWidth *sH;
        nowImageHeight = imgHeight *sH;
    }
    
    CGFloat imageX = (SCREEN_WIDTH - nowImageWidth) / 2;
    CGFloat imageY = (SCREEN_HEIGHT - nowImageHeight) / 2;
    
    UIImageView *imageView = [[UIImageView alloc] init ];
    imageView.frame = CGRectMake(imageX, imageY, nowImageWidth, nowImageHeight);
    imageView.image = image;
    return imageView;
}

#pragma mark - setter and getter

- (UIPageControl *)pageControl
{
    if (!_pageControl)
    {
        _pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake((SCREEN_WIDTH - 50) / 2, (SCREEN_HEIGHT - 50), 50, 40)];
        _pageControl.hidesForSinglePage = YES;
    }
    return _pageControl;
}

@end
