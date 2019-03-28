//
//  ExperienceCenterViewController.m
//  ULife3.5
//
//  Created by zhuochuncai on 05/08/2017.
//  Copyright © 2017 GosCam. All rights reserved.
//

#import "ExperienceCenterViewController.h"
#import "DemoVideoTableViewCell.h"
#import "PanoramaLivePlayerVC.h"
#import "UIImage+YYAdd.h"
#import "EnlargeClickButton.h"
#import "CommonlyUsedFounctions.h"

/**
 体验中心视频类型
 - ExpCenterVideoType360: 360吊装视频
 - ExpCenterVideoType180: 180侧装视频
 */
typedef NS_ENUM(NSUInteger, ExpCenterVideoType) {
    ExpCenterVideoType360,
    ExpCenterVideoType180,
};


@interface ExperienceCenterViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *demoVideoTableView;

@property(nonatomic,strong)NSArray *videoNames;

@property(nonatomic,strong)NSMutableArray *playedTimesArray;

@property (strong, nonatomic)  CABasicAnimation *vr360Anim;

@property (strong, nonatomic)  CABasicAnimation *vr180Anim;

@end

@implementation ExperienceCenterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self configUI];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.demoVideoTableView reloadData];
}

- (void)configUI{
    [self configNaviBar];
    [self configTableView];
}

- (void)configNaviBar{
    self.view.backgroundColor = BACKCOLOR(238,238,238,1);
    self.title = DPLocalizedString(@"ExperienceCenter");
    [self configNavigationItem];
    
    if (!_pushedFromDevListVC) {
        [self customLeftBarButtonItem];
    }
}

- (void)configTableView{
    
    self.demoVideoTableView.backgroundColor = BACKCOLOR(238,238,238,1);
    self.demoVideoTableView.dataSource = self;
    self.demoVideoTableView.delegate = self;
    
    [self.demoVideoTableView registerNib:[UINib nibWithNibName:@"DemoVideoTableViewCell" bundle:nil] forCellReuseIdentifier:@"DemoVideoTableViewCell"];
}

- (void)configNavigationItem{
    EnlargeClickButton *refreshBtn = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
    refreshBtn.frame     = CGRectMake(0, 0, 20, 20);
    [refreshBtn setBackgroundImage:[UIImage imageNamed:@"btn_experience_refresh_normal"] forState:0];
    
    [refreshBtn addTarget:self action:@selector(refreshBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:refreshBtn];
}

#pragma mark -- 添加左 item
- (void)customLeftBarButtonItem
{
    UIImage *image = [UIImage imageNamed:@"addev_back"];
    EnlargeClickButton *button = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 70, 40);
    button.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 50);
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self
               action:@selector(presentLeftMenuViewController:)
     forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    leftBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
}

- (void)refreshBtnClicked:(id)sender{
    
    UIButton *btn = (UIButton*)sender;
    btn.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.5 animations:^{
        btn.transform = CGAffineTransformMakeRotation(M_PI);
    } completion:^(BOOL finished) {
        btn.transform = CGAffineTransformIdentity;
        btn.userInteractionEnabled = YES;
    }];
}

#pragma mark =videoNames
- (NSArray*)videoNames{
    if (!_videoNames) {
        _videoNames = @[@"VR-360",@"VR-180"];//,@"NVR-720P",@"IPC-200W"
    }
    return _videoNames;
}

- (NSMutableArray*)playedTimesArray{
    if (!_playedTimesArray) {
        _playedTimesArray = [NSMutableArray arrayWithCapacity:1];
        for (NSInteger i=0; i<self.videoNames.count; i++) {
            [_playedTimesArray addObject:@(1288)];
        }
    }
    return _playedTimesArray;
}

#pragma mark ==<TableViewDelegate>

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return 1;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.videoNames.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return (SCREEN_WIDTH-20)*9/16;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 10;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 1;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    DemoVideoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DemoVideoTableViewCell" forIndexPath:indexPath];
    
    cell.separatorInset  = UIEdgeInsetsMake(0, 0, 0, SCREEN_WIDTH);
    
    ExpCenterVideoType type = indexPath.section ==0 ? ExpCenterVideoType360 : ExpCenterVideoType180;
    UIImage *tempImg = [self screenShotImgWithVideoType:type];
    if (!tempImg) {
        tempImg = [UIImage imageNamed:@"defaultCovert.jpg"];
    }
    //得到800*800的正方形图片
    CGRect tempRect = CGRectMake(tempImg.size.width/2-400, tempImg.size.height/2-400, 800, 800);
    UIImage *clipRectImage = [CommonlyUsedFounctions clipToRectImageFromImage:tempImg inRect:tempRect];
    
    //裁剪圆角
    CGRect roundTmpRect = CGRectMake(0, 0, 800, 800);
    cell.iconImage.image = [CommonlyUsedFounctions clipToRoundImageWithRect:roundTmpRect image:clipRectImage];
    
    [self addRotateAnimationInView: cell.iconImage videoType: type];
    
    cell.videoTypeName.text = self.videoNames[indexPath.section];
    cell.playedTimes.text =  [NSString stringWithFormat:@"%@：%@",DPLocalizedString(@"PlayedTimes"),self.playedTimesArray[indexPath.section]];
    
    return cell;
}

- (void)addRotateAnimationInView:(UIView*)aView videoType:(ExpCenterVideoType)type{
    CABasicAnimation *anim = nil;
    if (type == ExpCenterVideoType180) {
        if (!_vr180Anim) {
            _vr180Anim = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        }
        anim = _vr180Anim;
    }else if (type == ExpCenterVideoType360){
        if (!_vr360Anim) {
            _vr360Anim = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        }
        anim = _vr360Anim;
    }
    //addRotateAnimationInView
    
    anim.fromValue = @(0);
    anim.toValue = @(2*M_PI);
    anim.repeatCount = MAXFLOAT;
    anim.duration = 7.2;
    anim.removedOnCompletion = NO;
    [aView.layer removeAllAnimations];
    
    [aView.layer addAnimation:anim forKey:@"transform.rotation.z"];
}

/**
 根据视频类型生成预览视频最后一帧的保留画面
 */
- (UIImage *)screenShotImgWithVideoType:(ExpCenterVideoType)type{
    NSString *screenShotImgName = @"ExpCenter_VR_180";
    if (type == ExpCenterVideoType180) {
        screenShotImgName = @"ExpCenter_VR_180";
    }else{
        screenShotImgName = @"ExpCenter_VR_360";
    }
    
    NSString *screenShotFilePath = [mDocumentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg",screenShotImgName]];
    return [UIImage imageWithContentsOfFile:screenShotFilePath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    switch (indexPath.section) {
        case 0:  //360
        {
            PanoramaLivePlayerVC *panoramaLivePlayerVC = [[PanoramaLivePlayerVC alloc]init];
            panoramaLivePlayerVC.curPanoramaType = PanoramaType360;
            panoramaLivePlayerVC.titleName = self.videoNames[indexPath.section];
            [self.navigationController pushViewController:panoramaLivePlayerVC animated:YES];
            break;
        }
        case 1:  //180
        {
            PanoramaLivePlayerVC *panoramaLivePlayerVC = [[PanoramaLivePlayerVC alloc]init];
            panoramaLivePlayerVC.curPanoramaType = PanoramaType180;
            panoramaLivePlayerVC.titleName = self.videoNames[indexPath.section];
            [self.navigationController pushViewController:panoramaLivePlayerVC animated:YES];
            break;
        }
        case 2:  //NVR
        {
            
            break;
        }
        case 3:  //IPC
        {
            
            break;
        }
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}



@end
