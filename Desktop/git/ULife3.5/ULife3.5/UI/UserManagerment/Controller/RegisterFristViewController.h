//
//  RegisterFristViewController.h
//  goscamapp
//
//  Created by goscam_sz on 17/5/8.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TPKeyboardAvoidingTableView.h"
#import "LoginTableViewCell.h"
#import "NetSDK.h"
#import "SecondRegistrerTableViewCell.h"

typedef void(^RegisterResultCabllback)(int result);

@interface RegisterFristViewController : UIViewController


@property (nonatomic,strong) LoginTableViewCell * myForgetCell;

@property (nonatomic,strong) SecondRegistrerTableViewCell * labelCell;

@property (nonatomic, strong) NetSDK * netSDK;

@property (nonatomic, copy) NSString * acount;

@property (nonatomic, copy) NSString * Verificationcode;

@property (nonatomic, copy) NSString * FristPwd;

@property (nonatomic, copy) NSString * SecondPwd;

-(void)registerResultCabllbackFunc:(RegisterResultCabllback)result;

@end
