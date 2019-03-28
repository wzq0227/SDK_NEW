//
//  ThirdPartyAccessTableViewCell.h
//  ULife3.5
//
//  Created by Goscam on 2018/6/22.
//  Copyright © 2018 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ThirdPartyAccessTableViewCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UIView *bgView;


@property (weak, nonatomic) IBOutlet UIImageView *iconImgView;


@property (weak, nonatomic) IBOutlet UIButton *settingGuideBtn;


@property (weak, nonatomic) IBOutlet UIButton *jumpToThirdPartyBtn;

@end
