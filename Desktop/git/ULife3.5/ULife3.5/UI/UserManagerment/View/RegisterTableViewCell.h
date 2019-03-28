//
//  RegisterTableViewCell.h
//  goscamapp
//
//  Created by goscam_sz on 17/4/19.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>





@interface RegisterTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIButton *registerBtn;

@property (strong, nonatomic) IBOutlet UIButton *passWordBtn;

@property (weak, nonatomic) IBOutlet UILabel *rememberPwdLabel;



@end
