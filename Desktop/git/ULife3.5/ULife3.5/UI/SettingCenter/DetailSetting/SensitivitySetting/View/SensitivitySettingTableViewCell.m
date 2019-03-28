//
//  SensitivitySettingTableViewCell.m
//  ULife3.5
//
//  Created by zhuochuncai on 4/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "SensitivitySettingTableViewCell.h"

@interface SensitivitySettingTableViewCell(){
    
}

@property(nonatomic,strong)SliderValueChangeBlock sliderValueChangeBlock;
@end

@implementation SensitivitySettingTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self configUI];
}

- (void)configUI{
    
    [self configSlider];
}

- (void)sliderValueChangeCallback:(SliderValueChangeBlock)block{
    _sliderValueChangeBlock = block;
}

- (void)configSlider{
    self.slider.maximumTrackTintColor = [UIColor clearColor];
    self.slider.minimumTrackTintColor = [UIColor clearColor];
    self.slider.continuous = NO;
    [self.slider addTarget:self action:@selector(didEndDragingSlider:) forControlEvents:UIControlEventValueChanged];

//    [self.slider addTarget:self action:@selector(didEndDragingSlider:) forControlEvents:UIControlEventTouchDragExit];
    //Setting_SliderTrack
}

- (void)didEndDragingSlider:(id)sender
{
    CGFloat value = _slider.value;
    int selectPostion = (int)(value*4); // <1/4(0)  >1/4&&<3/4  (1/2)
    if (selectPostion < 1) {
        [_slider setValue:0*0.5 animated:YES];
    }
    else if (selectPostion <3){
        [_slider setValue:1*0.5 animated:YES];
    }
    else {
        [_slider setValue:2*0.5 animated:YES];
    }
    
    if (_sliderValueChangeBlock) {
        _sliderValueChangeBlock(self.tag, (selectPostion+1)/2);
    }
}

- (void)sliderChange_Five_one:(int)value{
    
    int selectPostion = (int)(value/0.125); // <1/8(0)  >1/8&&<2/8  (1/4)
    if (selectPostion < 1) {
        [_slider setValue:0*0.25 animated:YES];
    }
    else if (selectPostion <3){
        [_slider setValue:1*0.25 animated:YES];
    }
    else if (selectPostion < 5){
        [_slider setValue:2*0.25 animated:YES];
    }
    else if (selectPostion < 7){
        [_slider setValue:3*0.25 animated:YES];
    }else{
        [_slider setValue:4*0.25 animated:YES];
    }
    if (_sliderValueChangeBlock) {
        _sliderValueChangeBlock(self.tag, (selectPostion+1)/2);
    }

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
