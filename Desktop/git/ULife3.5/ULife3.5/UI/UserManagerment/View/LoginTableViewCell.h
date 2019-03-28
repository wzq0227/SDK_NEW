//
//  LoginTableViewCell.h
//  gaoscam
//
//  Created by goscam_sz on 17/4/19.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef  void(^Passwordblock)(BOOL);

@interface LoginTableViewCell : UITableViewCell


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *txtTrailingToContainer;



@property (strong, nonatomic) IBOutlet UIImageView *HeaderImageView;



@property (strong, nonatomic) IBOutlet UITextField *HeaderTextfied;


@property (strong, nonatomic) IBOutlet UIButton *headerButton;


@property (nonatomic,strong)  Passwordblock mycellPasswordBlock;


@property (strong, nonatomic) IBOutlet UIView *line;

@end
