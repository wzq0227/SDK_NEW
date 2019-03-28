//
//  LoginView.h
//  gaoscam
//
//  Created by goscam_sz on 17/4/19.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//
#import "Header.h"
#import <UIKit/UIKit.h>
#import "TPKeyboardAvoidingTableView.h"

@protocol pushNextViewDelegate <NSObject>

@required

- (void)startReister;

- (void)loginAcount:(NSString *)acount;

- (void)loginPassword:(NSString *)password;

@end

typedef  void(^registerBlock)(BOOL);

@interface LoginView : UIView <UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, weak) id <pushNextViewDelegate> delegate;

@property (strong, nonatomic) IBOutlet TPKeyboardAvoidingTableView *myTableView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topToSuperOfLogo;


@property (nonatomic,copy)  NSMutableArray * arr;

@property (nonatomic,strong)LoginTableViewCell *mycell;

@property (nonatomic,strong)RegisterTableViewCell * registecCell;

@property(nonatomic, strong) UIView *footerView;

@property(nonatomic, strong) UIButton *deleteBtn;

@property(nonatomic, strong) UIButton *forgetBtn;

@property(nonatomic, strong) UIButton *changeVersionBtn;

@property(nonatomic, strong) registerBlock block;

@property(nonatomic, copy) NSString *account;

@property(nonatomic, copy) NSString *password;


- (void)refreshTitles;

@end
