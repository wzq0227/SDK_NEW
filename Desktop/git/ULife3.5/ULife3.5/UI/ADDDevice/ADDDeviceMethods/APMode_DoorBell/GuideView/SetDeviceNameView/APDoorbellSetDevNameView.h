//
//  APDoorbellSetDevNameView.h
//  ULife3.5
//
//  Created by Goscam on 2017/12/6.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface APDoorbellSetDevNameView : UIView

@property (weak, nonatomic) IBOutlet UILabel *nameDevSubTipLabel;

@property (weak, nonatomic) IBOutlet UILabel *nameDevTipLabel;

@property (weak, nonatomic) IBOutlet UILabel *devNameLabel;

@property (weak, nonatomic) IBOutlet UITextField *devNameTxt;
@property (weak, nonatomic) IBOutlet UIButton *confirmBtn;

@end
