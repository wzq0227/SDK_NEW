//
//  DevicePickerTableViewCell.h
//  QQI
//
//  Created by goscam_sz on 16/8/1.
//  Copyright © 2016年 yuanx. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^intblock)(int);
typedef void (^floatblock)(float);
@interface DevicePickerTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIPickerView *myPickView;
@property (nonatomic,copy) intblock pickintblock;
@property (nonatomic,copy) floatblock pickfloatblock;
@property (nonatomic,assign) int  count;
@property (nonatomic,assign) int  row;
@property (nonatomic,assign) BOOL ismax;
-(void)DataRefreshPickView:(BOOL)isFahrenheit withcount:(int)count;

@property (weak, nonatomic) IBOutlet UILabel *tittlelabel;


@end
