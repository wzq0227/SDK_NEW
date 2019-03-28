//
//  PIRSliderView.m
//  ULife3.5
//
//  Created by Goscam on 2018/5/8.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "PIRSliderView.h"
#import "SliderBgFenceView.h"

@interface PIRSliderView(){
    
}
@property (strong, nonatomic)  SliderBgFenceView *pirFenceView;

@property (nonatomic, strong)  SliderValueChangeBlock sliderChangeBlock;

@end

@implementation PIRSliderView


- (void)sliderValueChangeCallback:(SliderValueChangeBlock)valueChangeBlock{
    _sliderChangeBlock = valueChangeBlock;
    
    [self addTapGesture];
}

- (void)addTapGesture{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesFunc:)];
    [self addGestureRecognizer:tap];
    
}

- (void)tapGesFunc:(UITapGestureRecognizer*)tapGes{

    CGPoint touchP = [tapGes locationInView:self];
    
    
    int sections = ((int)_titlesArray.count -1)*2; //转换后的选择区间数等于原区间数的两倍
    int selectPostion = (int)( touchP.x / self.width *sections); 
    
    for (int i=1; i< sections; i+=2) {
        if (selectPostion < i) {
            [_sliderForPirValueSetting setValue:(i-1)*1.0/(sections) animated:NO];
            break;
        }
    }
    
    if (selectPostion >= sections - 1) {
        [_sliderForPirValueSetting setValue:(1.0) animated:NO];
    }
    
    _pirFenceView.curPosition = (selectPostion+1)/2;
    
    !self.sliderChangeBlock?:self.sliderChangeBlock(_pirFenceView.curPosition);
    
    NSLog(@"tapGesFunc_selectPostion:%d ",_pirFenceView.curPosition);
    
    [_pirFenceView  setNeedsDisplay];
    [_pirFenceView layoutIfNeeded];
}


- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        _leadingSpace = 32;
        
    }
    return self;
}

- (void)setTitlesArray:(NSArray<NSString *> *)titlesArray{
    self.backgroundColor = [UIColor clearColor];
    
    _titlesArray = titlesArray;
    [self configSubviews];
}

- (void)setLeadingSpace:(float)leadingSpace{
    _leadingSpace = leadingSpace;
}

- (void)configSubviews{
    
    _pirFenceView = [[SliderBgFenceView alloc] initWithFrame:self.bounds];
    
    [self addSubview:_pirFenceView];
    
    [_pirFenceView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).mas_offset(5);
        make.leading.trailing.equalTo(self);
        make.height.mas_equalTo(13);
    }];
    _pirFenceView.backgroundColor = [UIColor clearColor];

//    [_pirFenceView  setNeedsDisplay];
//    [_pirFenceView layoutIfNeeded];
    
    _pirFenceView.sections = _titlesArray.count-1;

    [self addSubview:self.sliderForPirValueSetting];
    [self.sliderForPirValueSetting mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self.pirFenceView);
        make.leading.equalTo(self.pirFenceView).offset(20);
        make.centerX.equalTo(self.pirFenceView);
    }];
    
    [self configSliderValuesLabel];
}

- (void)configSliderValuesLabel{
    
    
    CGFloat itemSpacing = (SCREEN_WIDTH-2*_leadingSpace)/(_titlesArray.count -1 ) - 2*(_titlesArray.count-1);
    
    for (int i=0; i< _titlesArray.count ; i++) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.font = [UIFont systemFontOfSize:9];
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        label.text = _titlesArray[i];
        [self addSubview:label];
        
        //equalTo(@(32+i*itemSpacing))

        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(100);
            make.height.mas_equalTo(30);
       
            make.centerX.equalTo(self.mas_leading).offset(i == 0 ? _leadingSpace+i*itemSpacing+10: _leadingSpace+i*itemSpacing);
            make.centerY.equalTo(self).mas_offset(-5);
        }];
    }
//    [self setNeedsDisplay];
//    [self layoutIfNeeded];
}

- (void)sliderValueChanged:(id)sender{
    
    int sections = (_titlesArray.count -1)*2; //转换后的选择区间数等于原区间数的两倍
    int selectPostion = (int)(_sliderForPirValueSetting.value*sections); // <1/4(0)  >1/4&&<3/4  (2/4)
    
//    NSLog(@"selectPostion:%d value:%5.3f",selectPostion,_sliderForPirValueSetting.value);

    for (int i=1; i< sections; i+=2) {
        if (selectPostion < i) {
            [_sliderForPirValueSetting setValue:(i-1)*1.0/(sections) animated:NO];
            break;
        }
    }
    
    if (selectPostion >= sections - 1) {
        [_sliderForPirValueSetting setValue:(1.0) animated:NO];
    }
    
    
    _pirFenceView.curPosition = (selectPostion+1)/2;
    
    !self.sliderChangeBlock?:self.sliderChangeBlock(_pirFenceView.curPosition);

    NSLog(@"slider_selectPostion:%d ",_pirFenceView.curPosition);

    [_pirFenceView  setNeedsDisplay];
    [_pirFenceView layoutIfNeeded];
}

- (UISlider *)sliderForPirValueSetting{
    if (!_sliderForPirValueSetting) {
        _sliderForPirValueSetting = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 30)];
        [_sliderForPirValueSetting setThumbImage:[UIImage imageNamed:@"SubDev_MDSetting_Slider_thumb"] forState:UIControlStateNormal];
        [_sliderForPirValueSetting addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        _sliderForPirValueSetting.minimumTrackTintColor = [UIColor clearColor];
        _sliderForPirValueSetting.maximumTrackTintColor = [UIColor clearColor];
        _sliderForPirValueSetting.continuous = NO;
    }
    return _sliderForPirValueSetting;
}

@end
