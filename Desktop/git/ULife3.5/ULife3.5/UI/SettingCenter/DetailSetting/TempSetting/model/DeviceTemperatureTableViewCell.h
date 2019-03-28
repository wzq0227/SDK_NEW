//
//  DeviceTemperatureTableViewCell.h
//  QQI
//
//  Created by goscam_sz on 16/7/29.
//  Copyright © 2016年 yuanx. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^Block)(BOOL);

@interface DeviceTemperatureTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *temperatureBtn;
@property (weak, nonatomic) IBOutlet UILabel *temperatureText;
@property (assign,nonatomic)BOOL frameSetting;
@property (nonatomic,assign)BOOL  isMax;
@property (nonatomic,assign)BOOL  isMin;
@property (strong,nonatomic)UISwitch *SWControl;
@property (weak, nonatomic) IBOutlet UIButton *chooseBtn;
@property (nonatomic,assign)int count;
@property (nonatomic,assign)int temptureCount;
@property (nonatomic,assign)float maxTemture;
@property (nonatomic,assign)float minTemture;
@property (nonatomic,assign)NSString *_uidstr;
@property (nonatomic,copy)  Block  MaxBlock;
@property (nonatomic,copy)  Block  isChooseMaxSwithch;
@property (nonatomic,assign)BOOL  istemptureType;
@property (nonatomic,assign)BOOL  maxisOn;
@property (nonatomic,assign)BOOL  minisOn;


-(void)DataRefresh:(NSUInteger)nmuber AndisHuaShi:(BOOL)isHuaShi AndTemptureCount:(float)maxTempture withMinTempture:(float)minTempture AndChoose:(BOOL)isChooseMax AndChoose:(BOOL)isChooseMin AndIsEditor:(BOOL)isEditor;

@end
