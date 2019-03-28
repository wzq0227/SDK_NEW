//
//  NvrSinglePlayViewController.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/15.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MediaHeader.h"
#import "DeviceDataModel.h"

@interface NvrSinglePlayViewController : UIViewController

- (instancetype)initWithDevModel:(DeviceDataModel *)devDataModel
                      onPosition:(PositionType)positionType;

/** 是否已停止子码流 */
@property (nonatomic, assign, getter=isStopNvrSubStream) BOOL stopNvrSubStream;

/** NVR 四画面是否全屏 */
@property (nonatomic, assign, getter=isFourViewFullScreen) BOOL fourViewFullScreen;

@end
