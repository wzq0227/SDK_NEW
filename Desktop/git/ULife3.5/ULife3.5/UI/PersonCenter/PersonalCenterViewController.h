//
//  PersonalCenterViewController.h
//  gaoscam
//
//  Created by goscam_sz on 17/4/18.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UIPersonalCenterViewControllerDelegate <NSObject>

@required



#pragma mark - 注销

-(void)logout;


@end

@interface PersonalCenterViewController : UIViewController

@property (nonatomic, weak) id <UIPersonalCenterViewControllerDelegate> delegate;

- (void)backToFirstView;
@end
