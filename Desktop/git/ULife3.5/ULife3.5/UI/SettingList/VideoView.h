//
//  VideoView.h
//  goscamapp
//
//  Created by goscam_sz on 17/4/20.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//


#import "Header.h"
#import "QQIGetDeviceListSocket.h"

#import <UIKit/UIKit.h>
@protocol pushNextViewAdDeviceDelegate <NSObject>

@required

#pragma mark -- 跳转到播放页面
- (void)startPushToPlayVideoView:(NSString *)deviceId
                      deviceName:(NSString *)deviceName;

#pragma mark - 跳转到体验视频界面
-(void)startPushExperienceVideoView;

-(void)startPushToAdDevice;

@end

@interface VideoView : UIView  <UITableViewDelegate,UITableViewDataSource,GetDeviceListDelegate>

@property (nonatomic,strong) VideoListTableViewCell * myVideoListCell;

@property (nonatomic, weak) id <pushNextViewAdDeviceDelegate> delegate;

@property (strong, nonatomic) IBOutlet UITableView *myVideoListTabbleView;

@property (strong, nonatomic) IBOutlet UIButton *FristBtn;

@property (strong, nonatomic) IBOutlet UIButton *SecondBtn;

@property (strong, nonatomic) IBOutlet UIButton *DeleteBtn;

@property (strong, nonatomic) IBOutlet UIView *tapView;

@property (nonatomic, copy) NSMutableArray * DevListArr;

@property (nonatomic,strong) UIRefreshControl* refreshControl;

@property (nonatomic,strong) QQIGetDeviceListSocket *getDeviceListSocket;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *scaling;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *hight;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *deleteWith;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *SecondWith;

-(void)loadListArr:(NSMutableArray *)arr;


@end
