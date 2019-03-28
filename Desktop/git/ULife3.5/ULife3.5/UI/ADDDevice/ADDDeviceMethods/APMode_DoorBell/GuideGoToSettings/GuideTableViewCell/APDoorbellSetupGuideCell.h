//
//  APDoorbellSetupGuideCell.h
//  ULife3.5
//
//  Created by Goscam on 2017/12/5.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface APDoorbellSetupGuideCell : UITableViewCell
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *spacingBetweenImgAndLabel;

@property (weak, nonatomic) IBOutlet UIButton *tipImageBtn;

@property (weak, nonatomic) IBOutlet UILabel *tipTitleLabel;

@end
