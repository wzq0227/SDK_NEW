//
//  DeviceTemperatureTableViewCell.m
//  QQI
//
//  Created by goscam_sz on 16/7/29.
//  Copyright © 2016年 yuanx. All rights reserved.
//

#import "DeviceTemperatureTableViewCell.h"
#import "NetAPISet.h"
@interface DeviceTemperatureTableViewCell()

@property(nonatomic ,assign)BOOL MaxSwitchstate;

@property(nonatomic ,assign)BOOL MinSwitchstate;
@property(nonatomic, strong)NetAPISet* network;
@end



@implementation DeviceTemperatureTableViewCell





- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.isMax=YES;
    self.isMin=YES;
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
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





-(void)DataRefresh:(NSUInteger)nmuber AndisHuaShi:(BOOL)isHuaShi AndTemptureCount:(float)maxTempture withMinTempture:(float)minTempture AndChoose:(BOOL)isChooseMax AndChoose:(BOOL)isChooseMin AndIsEditor:(BOOL)isEditor
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.maxTemture=maxTempture;
    self.minTemture=minTempture;
    if (!isEditor) {
        
        if (nmuber==0) {
            self.SWControl.tag=201;
            self.SWControl.on=isChooseMax;
            self.temperatureText.text = DPLocalizedString(@"upperLimitTemperature");
            if (!isHuaShi) {
                [self.temperatureBtn setTitle:[NSString stringWithFormat:@"%d°",(int)self.maxTemture] forState:UIControlStateNormal];
            }
            else{
                [self.temperatureBtn setTitle:[NSString stringWithFormat:@"%dF",(int)self.maxTemture] forState:UIControlStateNormal];
            }
        }
        else{
            self.SWControl.tag=202;
            self.SWControl.on=isChooseMin;
            self.temperatureText.text = DPLocalizedString(@"lowerLimitTemperature");
            if (!isHuaShi) {
                [self.temperatureBtn setTitle:[NSString stringWithFormat:@"%d°",(int)self.minTemture] forState:UIControlStateNormal];
            }
            else{
                [self.temperatureBtn setTitle:[NSString stringWithFormat:@"%dF",(int)self.minTemture] forState:UIControlStateNormal];
            }
        }
    }
    else{
        if (nmuber==0) {
            
            self.temperatureText.text = DPLocalizedString(@"upperLimitTemperature");
            
            [self.chooseBtn addTarget:self action:@selector(Maxischoose) forControlEvents:UIControlEventTouchUpInside];
            if (!isHuaShi) {
                [self.temperatureBtn setTitle:[NSString stringWithFormat:@"%3.0f°",self.maxTemture] forState:UIControlStateNormal];
            }
            else{
                [self.temperatureBtn setTitle:[NSString stringWithFormat:@"%3.0fF",self.maxTemture] forState:UIControlStateNormal];
            }
        }
        else{
            
            
            self.temperatureText.text = DPLocalizedString(@"lowerLimitTemperature");
            [self.chooseBtn addTarget:self action:@selector(Minischoose) forControlEvents:UIControlEventTouchUpInside];
            if (!isHuaShi) {
                [self.temperatureBtn setTitle:[NSString stringWithFormat:@"%3.0f°",self.minTemture] forState:UIControlStateNormal];
            }
            else{
                [self.temperatureBtn setTitle:[NSString stringWithFormat:@"%3.0fF",self.minTemture] forState:UIControlStateNormal];
            }
        }
    }
}


-(UISwitch *)SWControl
{
    if (_SWControl == nil) {
        CGRect rect=CGRectMake(SCREEN_WIDTH-90, 10, 80, 35);
        _SWControl =[[UISwitch alloc]initWithFrame:rect];
        
        [_SWControl addTarget:self action:@selector(rotateChange:) forControlEvents:UIControlEventValueChanged];
    }
    return _SWControl;
}



-(void)rotateChange:(UISwitch *)UISwitch
{
    if (UISwitch.tag==201) {
        
        self.isChooseMaxSwithch(UISwitch.isOn);
    }
    else if (UISwitch.tag==202){
       
        self.isChooseMaxSwithch(UISwitch.isOn);
    }
    
}


-(void)sendsettemputureData:(int)count;
{
    __weak  DeviceTemperatureTableViewCell* weakSelf = self;

    if (!_network) {
        _network = [NetAPISet sharedInstance];
    }
    
    [_network setTemperatureData:cmdModel_SET_TEMPERATUREDATA  andalarm_enale:count andtemperature_type:0 andmax_alarm_value:self.count andmin_alarm_value:self.temptureCount andUID:self._uidstr andBlock:^(int result, int state, int cmd) {
        if (state==0) {
              NSLog(@"温度报警设置成功");
        }
    
    }];
}



-(void)Minischoose
{
    [self.chooseBtn  setImage:[UIImage imageNamed:@"Setting_Temp_Selected"] forState:UIControlStateNormal];
    self.MaxBlock(NO);
}



-(void)Maxischoose
{
    [self.chooseBtn  setImage:[UIImage imageNamed:@"Setting_Temp_Selected"] forState:UIControlStateNormal];
    self.MaxBlock(YES);
}











@end
