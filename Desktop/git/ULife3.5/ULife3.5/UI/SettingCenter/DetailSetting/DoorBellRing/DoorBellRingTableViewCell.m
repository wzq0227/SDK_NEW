//
//  DoorBellRingTableViewCell.m
//  ULife3.5
//
//  Created by AnDong on 2018/8/27.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "DoorBellRingTableViewCell.h"

@implementation DoorBellRingTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
}


- (IBAction)sliderValueDidChanged:(UISlider *)s {
    if (self.blk)
        self.blk(s.value);
}
@end
