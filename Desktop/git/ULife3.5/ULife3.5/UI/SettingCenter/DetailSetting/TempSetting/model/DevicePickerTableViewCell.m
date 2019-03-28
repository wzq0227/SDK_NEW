//
//  DevicePickerTableViewCell.m
//  QQI
//
//  Created by goscam_sz on 16/8/1.
//  Copyright © 2016年 yuanx. All rights reserved.
//

#import "DevicePickerTableViewCell.h"

@interface DevicePickerTableViewCell()<UIPickerViewDataSource,UIPickerViewDelegate>

@property(nonatomic,strong) NSMutableArray * data;
@property(nonatomic,strong) NSMutableArray * blockdata;
@property(nonatomic,assign) BOOL  isint;
@property(nonatomic,assign) BOOL  isonce;

@end


@implementation DevicePickerTableViewCell



- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
    }
    return self;
}


-(void)DataRefreshPickView:(BOOL)isFahrenheit withcount:(int)count
{
  
    _isonce=YES;
    
   
    if (_ismax) {
   
        if (!isFahrenheit) {
            self.data=[[NSMutableArray alloc]init];
            self.blockdata=[[NSMutableArray alloc]init];
            _isint=YES;
            for (int i= count; i<=50; i++) {
                NSString * str=[NSString stringWithFormat:@"%02d°C",i];
                NSString * blockstr=[NSString stringWithFormat:@"%d",i];
                [self.data addObject:str];
                [self.blockdata addObject:blockstr];
            }
        }
        else{
            self.data=[[NSMutableArray alloc]init];
            self.blockdata=[[NSMutableArray alloc]init];
            _isint=NO;
            for (int i= count; i<=50; i++) {
                NSString * str=[NSString stringWithFormat:@"%.1f°F",i*1.8+32];
                NSString * blockstr=[NSString stringWithFormat:@"%d",i];
                [self.data addObject:str];
                [self.blockdata addObject:blockstr];
            }
        }
        
    }
    else{
       
        
        if (!isFahrenheit) {
            self.data=[[NSMutableArray alloc]init];
            self.blockdata=[[NSMutableArray alloc]init];
            _isint=YES;
            for (int i= -10; i<=count; i++) {
                NSString * str=[NSString stringWithFormat:@"%d°C",i];
                NSString * blockstr=[NSString stringWithFormat:@"%d",i];
                [self.data addObject:str];
                [self.blockdata addObject:blockstr];
            }
            NSLog(@"%lu",(unsigned long)self.data.count);
        }
        else{
            self.data=[[NSMutableArray alloc]init];
            self.blockdata=[[NSMutableArray alloc]init];
            _isint=NO;
            for (int i= -10; i<= count; i++) {
                NSString * str=[NSString stringWithFormat:@"%.1f°F",i*1.8+32];
                NSString * blockstr=[NSString stringWithFormat:@"%d",i];
                [self.data addObject:str];
                [self.blockdata addObject:blockstr];
            }
        }
    }
//    [self.myPickView selectRow:self.row inComponent:0 animated:NO];
 
}



- (void)awakeFromNib {
    // Initialization cod
    
    
}


-(void)layoutSubviews
{
    [super layoutSubviews];
    
    
    self.myPickView.showsSelectionIndicator=YES;
    self.myPickView.dataSource = self;
    self.myPickView.delegate = self;
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    if (self.row>=0) {
        [self.myPickView selectRow:self.row inComponent:0 animated:NO];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *label =[[UILabel alloc] initWithFrame:CGRectMake(0, 0.0f, SCREEN_WIDTH,28)];
    [label setText:[self.data objectAtIndex:row]];
    
    label.backgroundColor = [UIColor clearColor];
    [label setTextAlignment: NSTextAlignmentCenter];
    return label;
}

// pickerView 列数
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// pickerView 每列个数
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    return self.data.count;
}

// 每列宽度
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return 180;
}

// 返回选中的行
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    
//    self.count=(int)row;
//    NSLog(@"%d",self.count);
    NSLog(@"didSelectRow______________________________:%d",[self.blockdata[row] intValue]);
    self.pickintblock([self.blockdata[row] intValue]);

}


//返回当前行的内容,此处是将数组中数值添加到滚动的那个显示栏上
-(NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return self.data[row];

}




@end
