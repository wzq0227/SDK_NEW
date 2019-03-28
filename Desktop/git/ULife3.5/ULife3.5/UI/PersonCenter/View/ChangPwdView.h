//
//  ChangPwdView.h
//  ULife3.5
//
//  Created by goscam_sz on 2017/6/14.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginTableViewCell.h"
#import "SecondRegistrerTableViewCell.h"
#import "TPKeyboardAvoidingTableView.h"
@protocol UIChangPwdViewDelegate <NSObject>


@required

- (void)getOldPassWord:(NSString *)oldPassword;

- (void)getFristNewPassWord:(NSString *)newPassword;

- (void)getSecondNewPassWord:(NSString *)newPassword;

- (void)SveNewPassword;

@end



@interface ChangPwdView : UIView <UITableViewDelegate,UITableViewDataSource,SecondRegisterTableViewCellDelegate>

@property (nonatomic,weak)   id<UIChangPwdViewDelegate> delegate;

@property (nonatomic,strong) LoginTableViewCell           * myCell;

@property (nonatomic,strong) SecondRegistrerTableViewCell * labelCell;

@property (strong, nonatomic) IBOutlet TPKeyboardAvoidingTableView *myTableView;


@property (strong, nonatomic) IBOutlet UIButton           * NextBtn;

@property (nonatomic,copy)    NSString                    * account;

- (void)refreshAccount:(NSString *)str;

@end

