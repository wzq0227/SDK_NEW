//
//  CSOrderDetailDeviceTopView.h
//  ULife3.5
//
//  Created by Goscam on 2018/4/23.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSOrderDeviceListCellModel.h"

typedef NS_ENUM(NSUInteger, CSAction) {
    CSAction_Playback,
    CSAction_RenewOrTransfer,
};

typedef void(^CSActionCallback)(CSAction csAction);

@interface CSOrderDetailDeviceTopView : UIView

@property (strong, nonatomic)  CSOrderDeviceListCellModel *csOrderModel;

- (void)clickCallback:(CSActionCallback)aCallbackBlcok;

@end
