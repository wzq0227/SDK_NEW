//
//  SecondStepRegisterView.h
//  goscamapp
//
//  Created by goscam_sz on 17/5/9.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginTableViewCell.h"
#import "SecondRegistrerTableViewCell.h"
#import "TPKeyboardAvoidingTableView.h"
@protocol SecondStepRegisterViewDelegate <NSObject>


@required

- (void)getOldPassWord:(NSString *)oldPassword;

- (void)getNewPassWord:(NSString *)newPassword;

- (void)RegisterNewAccount;

@end



@interface SecondStepRegisterView : UIView <UITableViewDelegate,UITableViewDataSource,SecondRegisterTableViewCellDelegate>

@property (nonatomic,weak)   id<SecondStepRegisterViewDelegate> delegate;

@property (nonatomic,strong) LoginTableViewCell           * myCell;

@property (nonatomic,strong) SecondRegistrerTableViewCell * labelCell;

@property (strong, nonatomic) IBOutlet TPKeyboardAvoidingTableView *myTableView;


@property (strong, nonatomic) IBOutlet UIButton           * NextBtn;

@property (nonatomic,copy)    NSString                    * account;

- (void)refreshAccount:(NSString *)str;

@end
