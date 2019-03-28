//
//  PaymentTypeTableViewCell.h
//  ULife3.5
//
//  Created by Goscam on 2017/9/15.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EnlargeClickButton.h"
@interface PaymentTypeTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconImage;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet EnlargeClickButton *selectBtn;

@property (weak, nonatomic) IBOutlet UIView *separatorLine;

@end
