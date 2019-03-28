//
//  DeviceTemperaturehumidityTableViewCell.m
//  QQI
//
//  Created by goscam_sz on 16/7/29.
//  Copyright © 2016年 yuanx. All rights reserved.
//

#import "DeviceTemperaturehumidityTableViewCell.h"

@implementation DeviceTemperaturehumidityTableViewCell
{
    BOOL  temperature;
    BOOL  isCellHuaShi;
}
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


-(BOOL)DataRefresh:(NSUInteger)nmuber AndState:(BOOL)isHuaShi AndMaxtempture:(float)Maxtemptur AndMintempture:(float)Mintempture
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    isCellHuaShi=isHuaShi;
    _maxTempture=Maxtemptur;
    _minTempture=Mintempture;
    
    if (nmuber==0) {
        self.temperaturelabel.text=@"°C";
        
        [self.chooseBtn addTarget:self action:@selector(choosetemperature) forControlEvents:UIControlEventTouchUpInside];
        if (!isHuaShi) {
            [self.chooseBtn setBackgroundImage:[UIImage imageNamed:@"Setting_Temp_Selected"] forState:UIControlStateNormal];
            
            return YES;
        }
        else{
            [self.chooseBtn setBackgroundImage:[UIImage imageNamed:@"Setting_Temp_Deselected"] forState:UIControlStateNormal];
            return NO;
        }
    }
    else{
        self.temperaturelabel.text=@"°F";
        [self.chooseBtn addTarget:self action:@selector(ChooseTemperature) forControlEvents:UIControlEventTouchUpInside];
        if (isHuaShi) {
            [self.chooseBtn setBackgroundImage:[UIImage imageNamed:@"Setting_Temp_Selected"] forState:UIControlStateNormal];
            return NO;
        }
        else{
            [self.chooseBtn setBackgroundImage:[UIImage imageNamed:@"Setting_Temp_Deselected"] forState:UIControlStateNormal];
            return YES;
        }
    }
}



-(void)choosetemperature
{
    if (isCellHuaShi) {
        [self.chooseBtn setBackgroundImage:[UIImage imageNamed:@"Setting_Temp_Selected"] forState:UIControlStateNormal];
        
        _maxTempture=(_maxTempture-32)/1.8;
        _minTempture=(_minTempture-32)/1.8;
        NSLog(@"%d=======%d",(int)_maxTempture,(int)_minTempture);
        self.myTemptureBlock(_maxTempture,_minTempture,NO);
    }
}



-(void)ChooseTemperature
{
    if (!isCellHuaShi) {
        [self.chooseBtn setBackgroundImage:[UIImage imageNamed:@"Setting_Temp_Selected"] forState:UIControlStateNormal];
        
        _maxTempture=(float)(_maxTempture*1.8)+32;
        _minTempture=(float)(_minTempture*1.8)+32;
        self.myTemptureBlock(_maxTempture,_minTempture,YES);
    }
}





-(void)setFrame:(CGRect)frame
{
    CGRect tempframe = frame;
    tempframe.origin.y = frame.origin.y;
    tempframe.origin.x = frame.origin.x;
    tempframe.size.width = frame.size.width;
    tempframe.size.height = frame.size.height;
    frame = tempframe;
    [super setFrame:frame];
}
@end
