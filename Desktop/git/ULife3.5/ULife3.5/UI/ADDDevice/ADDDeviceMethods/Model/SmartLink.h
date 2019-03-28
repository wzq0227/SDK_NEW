//
//  SmartLink.h
//  QQI
//
//  Created by goscam_sz on 17/5/12.
//  Copyright © 2017年 yuanx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SmartLinkModel.h"

@protocol  UISmartLinkDelegate<NSObject>

@required

- (void)startSmartLink;

- (void)SmartLinkSuccessful;

- (void)SmartLinkFailure;

@end




@interface SmartLink : NSObject

@property (nonatomic,weak) id<UISmartLinkDelegate> delegate;



- (instancetype)initWithSmartModel:(SmartLinkModel *)smartModel;

//开始搜索
-(void)startSearchLocalCamre;

//停止搜索
-(void)destroySearchTimer;


@end
