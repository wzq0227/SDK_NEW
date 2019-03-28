//
//  PanoramaLivePlayerVC.h
//  ULife3.5
//
//  Created by zhuochuncai on 03/08/2017.
//  Copyright © 2017 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"


/**
 全景视频类型

 - PanoramaTypeLive: 实时流
 - PanoramaType360: 演示视频360
 - PanoramaType180: 演示视频180
 */
typedef NS_ENUM(NSUInteger, PanoramaType) {
    PanoramaTypeLive,
    PanoramaType360,
    PanoramaType180,
};

//@[@"asteroid",@"cylinder",wideAngle,@"twoView",@"fourView"]
//小行星，桶形状,广角，二画面，四画面

/**
 视频显示模式
 水平吊装的有 默认，小行星，桶形状,二画面，四画面5种
 垂直侧装的有 默认，小行星，广角3 种模式
 - DisplayModeDefault: 默认显示模式
 - DisplayModeAsteroid: 小行星
 - DisplayModeCylinder: 桶形状
 - DisplayModeWideAngle: 广角
 - DisplayModeTwoView: 二画面
 - DisplayModeFourView: 四画面
 - DisplayModeVerticalAsteroid: 侧装小行星
 - DisplayModeVerticalWideAngle 侧装广角
 */
typedef NS_ENUM(NSInteger, DisplayMode) {
    DisplayModeDefault =-1,
    DisplayModeAsteroid,
    DisplayModeCylinder,
    DisplayModeWideAngle,
    DisplayModeTwoView,
    DisplayModeFourView,
    DisplayModeVerticalAsteroid,
    DisplayModeVerticalWideAngle,
};

@interface PanoramaLivePlayerVC : UIViewController

@property(nonatomic,assign)PanoramaType curPanoramaType;


/**
 导航栏标题名称
 */
@property(nonatomic,strong)NSString *titleName;

/**
 *  设备TUTK平台UID
 */
@property (nonatomic, copy) NSString *deviceId;

/**
 *  设备名称
 */
@property (nonatomic, copy) NSString *deviceName;

/**
 *  设备Model
 */
@property (nonatomic, strong)DeviceDataModel *deviceModel;


-(void)getLiveStreamData;

/**
 播放器容器视图
 */
@property (weak, nonatomic) IBOutlet UIView *playerView;


/**
 控制操作视频 视图
 */
@property (weak, nonatomic) IBOutlet UIView *controlViewBg;

/**
 控制操作视频滚动视图
 */
@property (weak, nonatomic) IBOutlet UIScrollView *controlScrollView;



/**
 分割线
 */
@property (weak, nonatomic) IBOutlet UIView *separatorView;

/**
 底部录像、对讲、拍照视图容器
 */
@property (weak, nonatomic) IBOutlet UIView *bottomView;


/**
 对讲
 */
@property (weak, nonatomic) IBOutlet UIButton *talkBtn;


/**
 拍照
 */
@property (weak, nonatomic) IBOutlet UIButton *snapshotBtn;


/**
 录像
 */
@property (weak, nonatomic) IBOutlet UIButton *recordingBtn;

/**
 对讲文本
 */
@property (weak, nonatomic) IBOutlet UILabel *talkLabel;

/**
 拍照文本
 */
@property (weak, nonatomic) IBOutlet UILabel *snapshotLabel;

/**
 录像文本
 */
@property (weak, nonatomic) IBOutlet UILabel *recordingLabel;


/**
 显示当前选中页面图标
 */
@property (weak, nonatomic) IBOutlet UIImageView *pageNumberIndicator;


@property(nonatomic,strong)UIImageView *displayVerticalView;


@property(nonatomic,strong)UIImageView *displayHorizontalView;

@property(nonatomic,strong)UIButton *displayModeBtn;

@property(nonatomic,strong)UIButton *installModeBtn;


- (IBAction)recordingAction:(id)sender;


- (IBAction)snapshotAction:(id)sender;

@end
