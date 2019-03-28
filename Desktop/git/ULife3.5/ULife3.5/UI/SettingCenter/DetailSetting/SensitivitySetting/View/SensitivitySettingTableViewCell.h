//
//  SensitivitySettingTableViewCell.h
//  ULife3.5
//
//  Created by zhuochuncai on 4/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void(^SliderValueChangeBlock) (int sectionIndex, int selectPosition);

@interface SensitivitySettingTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *lowLabel;
@property (weak, nonatomic) IBOutlet UILabel *defaultLabel;

@property (weak, nonatomic) IBOutlet UILabel *highLabel;
@property (weak, nonatomic) IBOutlet UISlider *slider;

- (void)sliderValueChangeCallback:(SliderValueChangeBlock)block;

@end
