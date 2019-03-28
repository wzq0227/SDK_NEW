//
//  ForgetView.h
//  ULife3.5
//
//  Created by goscam_sz on 2017/6/2.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TPKeyboardAvoidingTableView.h>
#import "LoginTableViewCell.h"
#import "SecondRegistrerTableViewCell.h"
#import "NetSDK.h"


@protocol UIForgetViewDelegate <NSObject>

@required

- (void)findPasswordAcount:(NSString *)acount
                     Verificationcode:(NSString *)code
                  FristPwd:(NSString *)fristpwd
                 Secondpwd:(NSString *)secondpwd;

@end


@interface ForgetView : UIView <UITableViewDelegate,UITableViewDataSource>

@property (strong, nonatomic) IBOutlet TPKeyboardAvoidingTableView *myForgetTableView;

@property (nonatomic, weak) id <UIForgetViewDelegate> delegate;

@property (nonatomic,strong) LoginTableViewCell * myForgetCell;

@property (nonatomic,strong) SecondRegistrerTableViewCell * labelCell;

@property (strong, nonatomic) IBOutlet UIButton *NextBtn;

@property (strong, nonatomic) IBOutlet UILabel *helpLabel;

@property (nonatomic, strong) NetSDK * netSDK;

@property (nonatomic, copy) NSString * acount;

@property (nonatomic, copy) NSString * Verificationcode;

@property (nonatomic, copy) NSString * FristPwd;

@property (nonatomic, copy) NSString * SecondPwd;

- (void)invalidateTimers;

@end
