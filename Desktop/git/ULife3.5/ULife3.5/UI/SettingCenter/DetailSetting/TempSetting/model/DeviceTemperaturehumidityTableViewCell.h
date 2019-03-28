//
//  DeviceTemperaturehumidityTableViewCell.h
//  QQI
//
//  Created by goscam_sz on 16/7/29.
//  Copyright © 2016年 yuanx. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void (^Block)(BOOL);
typedef void (^TemptureBlock)(float max,float min,BOOL);

@interface DeviceTemperaturehumidityTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *chooseBtn;

@property(nonatomic ,copy) Block isHuaShiblock;
@property(nonatomic ,copy) TemptureBlock myTemptureBlock;
@property(nonatomic, assign) float maxTempture;
@property(nonatomic, assign) float minTempture;

@property (weak, nonatomic) IBOutlet UILabel *temperaturelabel;
-(BOOL)DataRefresh:(NSUInteger)nmuber AndState:(BOOL)isHuaShi AndMaxtempture:(float)Maxtemptur AndMintempture:(float)Mintempture;

@end
