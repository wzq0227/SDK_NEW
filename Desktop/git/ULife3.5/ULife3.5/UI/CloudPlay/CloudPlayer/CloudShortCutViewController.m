//
//  CloudShortCutViewController.m
//  ULife3.5
//
//  Created by AnDong on 2017/10/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "CloudShortCutViewController.h"
#import "UIColor+YYAdd.h"

static NSString *const ConvertMP4Notification = @"ConvertMP4Notification";
@interface CloudShortCutViewController ()<UIPickerViewDelegate,UIPickerViewDataSource,UITextFieldDelegate>

@property (nonatomic,strong)UIButton *rightNavButton;

@property (nonatomic,strong)UILabel *topLabel;

@property (nonatomic,strong)UIView *nameView;

@property (nonatomic,strong)UILabel *titleLabel;

@property (nonatomic,strong)UIView *timeView;

@property (nonatomic,strong)UILabel *startLable;

@property (nonatomic,strong)UILabel *stopLabel;

@property (nonatomic,strong)UIView *lineView;

@property (nonatomic,strong)UITextField *titleTf;

@property (nonatomic,strong)UITextField *startTf;

@property (nonatomic,strong)UITextField *endTf;

@property (nonatomic,strong)UIView *pickCoverView;

@property (nonatomic,strong)UIPickerView *pickView;

@property (nonatomic,strong)NSMutableArray *timeArray;

@property (nonatomic,strong)NSMutableArray *minArray;

@property (nonatomic,strong)NSMutableArray *totalSecondsArray;

@property (nonatomic,strong)UILabel *minLabel;

@property (nonatomic,strong)UILabel *secondLabel;

//是否已经被延迟pop了
@property (nonatomic,assign)BOOL isNavBack;



@end

@implementation CloudShortCutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //设置数组
    for (int i = 0; i <= self.mins; i++) {
        NSString *minStr = [NSString stringWithFormat:@"%d",i];
        [self.minArray addObject:minStr];
    }
    
    for (int i = 0; i <= self.seconds; i++) {
        NSString *minStr = [NSString stringWithFormat:@"%d",i];
        [self.timeArray addObject:minStr];
    }
    
    
    
    
    [self setupUI];
    self.view.backgroundColor = [UIColor colorWithRed:234/255.0f green:234/255.0f blue:234/255.0f alpha:1.0f];
    [self configNavItem];
    
    //添加裁剪完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSuccess:) name:ConvertMP4Notification object:nil];
}


- (void)captureSuccess:(NSNotification *)notify{
    //限制下 三秒才响应一次
    NSDictionary *dict = notify.userInfo;
    NSNumber *number = dict[@"result"];
    if (number.intValue == 1) {
        //成功
        [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"PlayVideo_CS_Cut_Succeeded") ];
        [SVProgressHUD dismissWithDelay:1.5];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.isNavBack) {
                return;
            }
            //加这个处理是防止回调两次出现的bug
            self.isNavBack = YES;
            [self.navigationController popViewControllerAnimated:YES];
        });
    }
    else{
        //失败
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"PlayVideo_CS_Cut_Failed")];
        [SVProgressHUD dismissWithDelay:1.5];
    }
}


-(void)configNavItem
{
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    infoButton.frame = CGRectMake(0.0, 0.0, 75, 40);
    infoButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    //    infoButton.titleLabel.textAlignment = NSTextAlignmentRight;
    [infoButton setTitle:DPLocalizedString(@"Setting_Done")
                forState:UIControlStateNormal];
    [infoButton setTitleColor:[UIColor whiteColor]
                     forState:UIControlStateNormal];
    [infoButton addTarget:self
                   action:@selector(finishShortCut)
         forControlEvents:UIControlEventTouchUpInside];
    infoButton.exclusiveTouch = YES;
    UIBarButtonItem *infotemporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
    infotemporaryBarButtonItem.style = UIBarButtonItemStylePlain;
    self.rightNavButton = infoButton;
    self.navigationItem.rightBarButtonItem = infotemporaryBarButtonItem;
}


- (void)setupUI{
    [self.view addSubview:self.topLabel];
    [self.view addSubview:self.nameView];
    [self.nameView addSubview:self.titleLabel];
    [self.nameView addSubview:self.titleTf];
    [self.view addSubview:self.timeView];
    [self.timeView addSubview:self.startLable];
    [self.timeView addSubview:self.stopLabel];
    [self.timeView addSubview:self.startTf];
    [self.timeView addSubview:self.endTf];
    [self.timeView addSubview:self.lineView];
    
    
    // 初始化pickerView
    UIView *pickCoverView = [[UIView alloc]initWithFrame:CGRectMake(0, 245, self.view.bounds.size.width, 200)];
    pickCoverView.backgroundColor = [UIColor whiteColor];
    self.pickCoverView = pickCoverView;
    self.pickCoverView.hidden = YES;
    [self.view addSubview:pickCoverView];
    
    self.pickView = [[UIPickerView alloc]initWithFrame:CGRectMake(0,20,kScreen_Width, 180)];
    [self.pickCoverView addSubview:self.pickView];
    //指定数据源和委托
    self.pickView.delegate = self;
    self.pickView.dataSource = self;
    
    [self.pickView selectRow:self.seconds inComponent:1 animated:NO];

    [self.pickCoverView addSubview:self.minLabel];
    [self.pickCoverView addSubview:self.secondLabel];
}

- (void)finishShortCut{
    
    int time = [self getToTalTime];
    if (time == 0) {
        return;
    }
    //完成剪切
   [SVProgressHUD showWithStatus:DPLocalizedString(@"loading")];
    [self.cloudPlayVC convertMP4WithStartValue:self.currentShortCutTime totalValue:time fileName:self.titleTf.text];
}

- (int)getToTalTime{
    NSString *timeStr = self.endTf.text;
    NSString *minStr = [timeStr substringWithRange:NSMakeRange(0, 2)];
    NSString *secondStr = [timeStr substringWithRange:NSMakeRange(3, 2)];
    int totalTime = minStr.intValue * 60 + secondStr.intValue;
    return totalTime;
}

- (void)tfChange{
    NSLog(@"TFChange");
}

//nadate转nsstring
- (NSString *)getDateStringWithDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *dateTime = [formatter stringFromDate:date];
    return dateTime;
}



- (NSString *)getTimeTextWithValue:(NSUInteger)TimeValue{
    NSString *timeText;
    int hrs = (int)TimeValue / 3600;
    int totolSecond = (int)TimeValue % 3600;
    int min = (int)totolSecond / 60;
    int second = (int)totolSecond % 60;
    timeText = [NSString stringWithFormat:@"%02d-%02d-%02d",hrs,min,second];
    return timeText;
}

- (NSString *)getStartTimeTextWithValue:(NSUInteger)TimeValue{
    NSString *timeText;
    int hrs = (int)TimeValue / 3600;
    int totolSecond = (int)TimeValue % 3600;
    int min = (int)totolSecond / 60;
    int second = (int)totolSecond % 60;
    timeText = [NSString stringWithFormat:@"%02d:%02d:%02d",hrs,min,second];
    return timeText;
}

- (NSString *)getStartDateStringWithDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy/MM/dd"];
    NSString *dateTime = [formatter stringFromDate:date];
    return dateTime;
}


#pragma mark UIPickerView Delegate Method 代理方法

//指定每行如何展示数据（此处和tableview类似）
-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (component == 0) {
        return self.minArray[row];
    }
    
    NSInteger componentRow=[self.pickView selectedRowInComponent:0];
    if (componentRow == self.minArray.count -1) {
        return self.timeArray[row];
    }
    return self.totalSecondsArray[row];
}


//选中时回调的委托方法
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (component == 0) {
        [self.pickView selectRow:0 inComponent:1 animated:NO];
        [self.pickView reloadComponent:1];
        NSString *timeStr = self.minArray[row];
        NSString *tureStr = [NSString stringWithFormat:@"%02d",timeStr.intValue];
        self.endTf.text = [self.endTf.text stringByReplacingCharactersInRange:NSMakeRange(0, 2) withString:tureStr];
    }
    else{
        NSString *timeStr;
        NSInteger componentRow=[self.pickView selectedRowInComponent:0];
        if (componentRow == self.minArray.count -1) {
            timeStr = self.timeArray[row];
        }
        else{
            timeStr = self.totalSecondsArray[row];
        }
        NSString *tureStr = [NSString stringWithFormat:@"%02d",timeStr.intValue];
        self.endTf.text = [self.endTf.text stringByReplacingCharactersInRange:NSMakeRange(3, 2) withString:tureStr];
        [UIView animateWithDuration:0.2 animations:^{
            self.pickCoverView.hidden = YES;
        }];
    }
   
    
}

//指定pickerview有几个表盘
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (component == 0) {
        return self.minArray.count;
    }
    else{
        NSInteger componentRow=[self.pickView selectedRowInComponent:0];
        if (componentRow == self.minArray.count -1) {
            return self.timeArray.count;
        }
        return self.totalSecondsArray.count;
    }
}



#pragma mark - UITextField

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    self.pickCoverView.hidden = NO;
    return NO;
}

#pragma mark - Getter

- (UILabel *)topLabel{
    if (!_topLabel) {
        
        CGSize maxSize = CGSizeMake(200, 1000);
        NSString *labelStr = DPLocalizedString(@"PlayVideo_CS_Cut_Tip");
        
        CGSize labelSize = [labelStr sizeForFont:[UIFont systemFontOfSize:14.0f] size:maxSize mode:NSLineBreakByWordWrapping];
        
        _topLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, 5, kScreen_Width- 40, labelSize.height)];
        _topLabel.textColor = [UIColor blackColor];
        _topLabel.numberOfLines = 0;
        _topLabel.text = labelStr;
        _topLabel.font = [UIFont systemFontOfSize:14.0f];
    }
    return _topLabel;
}

- (UIView *)nameView{
    if (!_nameView) {
        _nameView = [[UIView alloc]initWithFrame:CGRectMake(0, self.topLabel.height+15, kScreen_Width, 40)];
        _nameView.backgroundColor = [UIColor whiteColor];
    }
    return _nameView;
}

- (UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, 0, 80, 40)];
        _titleLabel.textColor = [UIColor blackColor];
        _titleLabel.text = DPLocalizedString(@"PlayVideo_CS_Cut_TitleName");
        _titleLabel.font = [UIFont systemFontOfSize:14.0f];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}

-(UITextField *)titleTf{
    if (!_titleTf) {
        _titleTf = [[UITextField alloc]initWithFrame:CGRectMake(100, 0, kScreen_Width - 90, 40)];
        _titleTf.textAlignment = NSTextAlignmentLeft;
        _titleTf.font = [UIFont systemFontOfSize:14.0f];
        _titleTf.text = [NSString stringWithFormat:@"%@-%@",[self getDateStringWithDate:self.currentSelectDate],[self getTimeTextWithValue:self.currentShortCutTime]];
    }
    return _titleTf;
}

- (UIView *)timeView{
    if (!_timeView) {
        _timeView = [[UIView alloc]initWithFrame:CGRectMake(0, self.nameView.origin.y +self.nameView.height+15, kScreen_Width, 80)];
        _timeView.backgroundColor = [UIColor whiteColor];
    }
    return _timeView;
}

- (UIView *)lineView{
    if (!_lineView) {
        _lineView = [[UIView alloc]initWithFrame:CGRectMake(0, 40, kScreen_Width, 0.5)];
        _lineView.backgroundColor = [UIColor colorWithRed:206/255.0f green:206/255.0f blue:206/255.0f alpha:1.0f];
    }
    return _lineView;
}


- (UILabel *)startLable{
    if (!_startLable) {
        _startLable = [[UILabel alloc]initWithFrame:CGRectMake(20, 0, 80, 40)];
        _startLable.textColor = [UIColor lightGrayColor];
        _startLable.text = DPLocalizedString(@"PlayVideo_CS_Cut_StartTime");
        _startLable.font = [UIFont systemFontOfSize:14.0f];
        _startLable.textAlignment = NSTextAlignmentLeft;
    }
    return _startLable;
}

- (UILabel *)stopLabel{
    if (!_stopLabel) {
        _stopLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, 40, 80, 40)];
        _stopLabel.textColor = [UIColor blackColor];
        _stopLabel.text = DPLocalizedString(@"PlayVideo_CS_Cut_Duration"); ;
        _stopLabel.font = [UIFont systemFontOfSize:14.0f];
        _stopLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _stopLabel;
}

-(UITextField *)startTf{
    if (!_startTf) {
        _startTf = [[UITextField alloc]initWithFrame:CGRectMake(100, 0, kScreen_Width - 100 -30, 40)];
        _startTf.textAlignment = NSTextAlignmentRight;
        _startTf.textColor = [UIColor lightGrayColor];
        _startTf.font = [UIFont systemFontOfSize:14.0f];
        _startTf.userInteractionEnabled = NO;
        _startTf.text = [NSString stringWithFormat:@"%@ %@",[self getStartTimeTextWithValue:self.currentShortCutTime],[self getStartDateStringWithDate:self.currentSelectDate]];
    }
    return _startTf;
}

-(UITextField *)endTf{
    if (!_endTf) {
        _endTf = [[UITextField alloc]initWithFrame:CGRectMake(100, 40, kScreen_Width - 100 -30, 40)];
        _endTf.textAlignment = NSTextAlignmentRight;
        _endTf.font = [UIFont systemFontOfSize:14.0f];
        _endTf.textColor = [UIColor blackColor];
        if (self.seconds>0) {
            _endTf.text = [NSString stringWithFormat:@"%02d:%02d",self.mins,self.seconds];
        }else{
            _endTf.text = @"00:00";
        }
        _endTf.delegate = self;
    }
    return _endTf;
}

- (UILabel *)minLabel{
    if (!_minLabel) {
        _minLabel = [[UILabel alloc]initWithFrame:CGRectMake((kScreen_Width/2 - 20)/2, 0, 50, 20)];
        _minLabel.textColor = [UIColor blackColor];
        _minLabel.text = DPLocalizedString(@"PlayVideo_CS_Cut_Min") ;
        _minLabel.font = [UIFont systemFontOfSize:17.0f];
        _minLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _minLabel;
}

- (UILabel *)secondLabel{
    if (!_secondLabel) {
        _secondLabel = [[UILabel alloc]initWithFrame:CGRectMake(kScreen_Width/2.0f + (kScreen_Width/2 -60)/2, 0, 50, 20)];
        _secondLabel.textColor = [UIColor blackColor];
        _secondLabel.text = DPLocalizedString(@"PlayVideo_CS_Cut_Sec") ;
        _secondLabel.font = [UIFont systemFontOfSize:17.0f];
        _secondLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _secondLabel;
}

- (NSMutableArray *)timeArray{
    if(!_timeArray){
        _timeArray = [NSMutableArray array];
    }
    return _timeArray;
}

- (NSMutableArray *)minArray{
    if(!_minArray){
        _minArray = [NSMutableArray array];
    }
    return _minArray;
}


- (NSMutableArray *)totalSecondsArray{
    if(!_totalSecondsArray){
        _totalSecondsArray = [NSMutableArray array];
        for (int i = 0; i < 60; i++) {
            NSString *minStr = [NSString stringWithFormat:@"%d",i];
            [self.totalSecondsArray addObject:minStr];
        }
    }
    return _totalSecondsArray;
}




@end
