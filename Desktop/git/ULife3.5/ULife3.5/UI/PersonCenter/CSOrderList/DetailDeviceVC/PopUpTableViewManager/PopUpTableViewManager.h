//
//  PopUpTableViewManager.h
//  ULife3.5
//
//  Created by Goscam on 2018/4/23.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^SelectCellCallbackBlock)(NSInteger index);

typedef void(^ExitSelectingBlock)(void);

@interface PopupTableCellModel:NSObject
@property (strong, nonatomic)  NSString *deviceName;
@property (strong, nonatomic)  NSString *deviceId;
@end


@interface PopUpTableViewManager : UIView

@property (nonatomic, strong,readwrite)  NSString * tableHeaderStr;

@property (strong, nonatomic) NSArray <PopupTableCellModel *>* devicesArray;

- (void)selectCellCallback:(SelectCellCallbackBlock)aCallbackBlock;


- (void)exitSelectingCallback:(ExitSelectingBlock)exitCallback;

@end
