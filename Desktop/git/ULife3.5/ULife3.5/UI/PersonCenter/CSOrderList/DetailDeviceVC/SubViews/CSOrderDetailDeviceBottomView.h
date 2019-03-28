//
//  CSOrderDetailDeviceBottomView.h
//  ULife3.5
//
//  Created by Goscam on 2018/4/24.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PurchasedPackageInfo:NSObject
@property (strong, nonatomic)  NSString *dataLife;

@property (strong, nonatomic)  NSString *validTime;

@end

typedef void(^SelectCellCallbackBlock)(NSInteger index);

@interface CSOrderDetailDeviceBottomView : UIView

@property (strong, nonatomic) NSArray <PurchasedPackageInfo *>* purchasedPackages;

- (void)selectCellCallback:(SelectCellCallbackBlock)aCallbackBlock;

@end
