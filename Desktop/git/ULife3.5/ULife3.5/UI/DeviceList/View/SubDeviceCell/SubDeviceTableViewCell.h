//
//  SubDeviceTableViewCell.h
//  ULife3.5
//
//  Created by Goscam on 2018/3/16.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"


typedef enum : NSUInteger {
    SubDevCellActionPlayLiveStream,
    SubDevCellActionShowMsgCenter,
    SubDevCellActionShowCloudPlayback,
    SubDevCellActionShowTFCardPlayback,
    SubDevCellActionShowSettings,
} SubDevCellAction;

typedef void(^SubDevCellClickActionBlock)(SubDevCellAction actionType,int subDevIndex);


@interface SubDeviceTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *covertImageView;              // IPC 封面

@property (weak, nonatomic) IBOutlet EnlargeClickButton *playTipBtn;

@property (weak, nonatomic) IBOutlet UIView *disOnLineView;



@property (weak, nonatomic) IBOutlet UILabel *devNameLabel;                     // 设备昵称

@property (weak, nonatomic) IBOutlet  EnlargeClickButton *msgCenterBtn;

@property (weak, nonatomic) IBOutlet  EnlargeClickButton *cloudPlaybackBtn;

@property (weak, nonatomic) IBOutlet  EnlargeClickButton *tfCardPlaybackBtn;

@property (weak, nonatomic) IBOutlet  EnlargeClickButton *settingBtn;


- (void)subDeviceClickCallback:(SubDevCellClickActionBlock)clickCallback;


@property (nonatomic, strong) DeviceDataModel *devListTableViewCellData;

@end
