//
//  LightDurationOnOffTimeSettingVC.m
//  ULife3.5
//
//  Created by zhuochuncai on 7/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "LightDurationOnOffTimeSettingVC.h"

@interface LightDurationOnOffTimeSettingVC ()<UIPickerViewDataSource,UIPickerViewDelegate>
@property(nonatomic,strong)SelectTimeBlock selectBlock;
@end

@implementation LightDurationOnOffTimeSettingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self configPickerView];
    [self configUI];
}

- (void)configUI{
    
    self.title = DPLocalizedString(@"LightDuration_Setting");
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    UIButton *doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    doneBtn.frame     = CGRectMake(0, 0, 60, 40);
    [doneBtn setTitle:DPLocalizedString(@"Setting_Done") forState:0];
    [doneBtn addTarget:self action:@selector(doneBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:doneBtn];
}

- (void)doneBtnClicked:(id)sender{
    int h = [_onOffTimePickerView selectedRowInComponent:0];
    int m = [_onOffTimePickerView selectedRowInComponent:1];
    if (_selectBlock) {
        _selectBlock(h,m);
    }
}

- (void)selectTimeCallback:(SelectTimeBlock)block{
    _selectBlock = block;
}

- (void)countdownPickerViewValueChanged:(id)sender{
    
}

- (void)configPickerView{

    _onOffTimePickerView.hidden = NO;
    
    _onOffTimePickerView.delegate = self;
    _onOffTimePickerView.dataSource = self;
    
    if (_min> -1 && _min< 60 && _hour > -1 && _hour <24) {
        [_onOffTimePickerView selectRow:_hour inComponent:0 animated:NO];
        [_onOffTimePickerView selectRow:_min inComponent:1 animated:NO];
    }
}


// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 2;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return component==0 ? 24 :60;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
 
    return [NSString stringWithFormat:@"%02d %@", row,(component==0?@"H":@"Min")];//
}


- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    UILabel* pickerLabel = (UILabel*)view;
    if (!pickerLabel){
        pickerLabel = [[UILabel alloc] init];
        pickerLabel.adjustsFontSizeToFitWidth = YES;
        [pickerLabel setTextAlignment:NSTextAlignmentCenter];
        [pickerLabel setBackgroundColor:[UIColor clearColor]];
        [pickerLabel setFont:[UIFont boldSystemFontOfSize:17]];
    }
    // Fill the label text here
    pickerLabel.text=[self pickerView:pickerView titleForRow:row forComponent:component];
    return pickerLabel;
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
