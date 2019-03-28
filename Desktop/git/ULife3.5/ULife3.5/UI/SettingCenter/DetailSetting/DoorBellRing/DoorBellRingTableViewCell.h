//
//  DoorBellRingTableViewCell.h
//  ULife3.5
//
//  Created by AnDong on 2018/8/27.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^sliderValueChanged)(int v);

@interface DoorBellRingTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *rightLabel;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UILabel *leftLabel;

@property (nonatomic, copy) sliderValueChanged blk;
@end
