//
//  NvrPlaybackPlayViewController.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/21.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NvrPlaybackListModel.h"
#import "DeviceDataModel.h"


@interface NvrPlaybackPlayViewController : UIViewController

- (instancetype)initWithModel:(NvrPlaybackListModel *)listModel
                    tutkDevId:(NSString *)tutkDevId;

/** 设备数据模型 */
@property (nonatomic, strong) DeviceDataModel *devDataModel;

@property (nonatomic, assign) PositionType positionType;

@end
