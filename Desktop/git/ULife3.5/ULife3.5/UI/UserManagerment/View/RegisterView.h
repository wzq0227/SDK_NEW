//
//  RegisterView.h
//  goscamapp
//
//  Created by goscam_sz on 17/5/8.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TPKeyboardAvoidingTableView.h"
#import "LoginTableViewCell.h"
#import "SecondRegistrerTableViewCell.h"
#import "NetSDK.h"
#import "Header.h"


@protocol UIRegisterViewDelegate <NSObject>

@required

- (void)emilString:(NSString *)str;


- (void)registerWithAcount:(NSString *)acount
          Verificationcode:(NSString *)code
                  FristPwd:(NSString *)fristpwd
                 Secondpwd:(NSString *)secondpwd;

@end




@interface RegisterView : UIView <UITableViewDataSource,UITableViewDelegate,UITextViewDelegate>

@property (nonatomic,weak) id <UIRegisterViewDelegate> delegate;

@property (strong, nonatomic) IBOutlet TPKeyboardAvoidingTableView *myRegisterTableView;

@property (strong, nonatomic) IBOutlet UIButton *NextButon;

@property (weak, nonatomic) IBOutlet UILabel *helpLabel;



@property (nonatomic,strong) SecondRegistrerTableViewCell * labelCell;

@property (nonatomic,strong) LoginTableViewCell * myRegisterCell;


@property (nonatomic, strong) NetSDK * netSDK;

@property (nonatomic, copy) NSString * acount;

@property (nonatomic, copy) NSString * Verificationcode;

@property (nonatomic, copy) NSString * FristPwd;

@property (nonatomic, copy) NSString * SecondPwd;

@property (strong, nonatomic) IBOutlet UITextView *UserProtocolsTextView;

@property (strong, nonatomic) IBOutlet UIButton *agreeBtn;

@property (nonatomic,assign) BOOL  isAgree;

- (void)invalidateTimers;

@end
