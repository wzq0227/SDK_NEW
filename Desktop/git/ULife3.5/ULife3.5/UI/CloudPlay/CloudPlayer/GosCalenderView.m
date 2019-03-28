//
//  GosCalenderView.m
//  dddd
//
//  Created by zz on 2018/12/25.
//  Copyright © 2018年 zz. All rights reserved.
//

#import "GosCalenderView.h"

#pragma mark - UICollectionViewCell
@interface KHCalenderCollectionViewCell : UICollectionViewCell
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic) NSDictionary *dic;
@property (nonatomic, assign) BOOL hasVideo;
@end

@interface KHCalenderCollectionViewCell () {
    CAShapeLayer *selectShapeLayer;
    UIView *containerView;
}
@end
@implementation KHCalenderCollectionViewCell
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        containerView.hidden = YES;
        [self.contentView addSubview:containerView];
        
        CGFloat selectShaperLayerWidth = self.frame.size.width > self.frame.size.height ? self.frame.size.width : self.frame.size.height;
        selectShapeLayer = [CAShapeLayer layer];
        UIBezierPath *selectPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.frame.size.width * 0.5, self.frame.size.height * 0.5) radius:selectShaperLayerWidth * 0.3 startAngle:0 endAngle:2 * M_PI clockwise:YES];
        selectShapeLayer.path = selectPath.CGPath;
        selectShapeLayer.fillColor = UIColorFromRGB(0x1fbcd2).CGColor;
        selectShapeLayer.strokeColor = [UIColor clearColor].CGColor;
        [containerView.layer addSublayer:selectShapeLayer];
        
        self.textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.textColor = [UIColor blackColor];
        self.contentView.backgroundColor = [UIColor whiteColor];
        [self.contentView addSubview:self.textLabel];
    }
    return self;
}

- (void)setDic:(NSDictionary *)dic {
    _dic = dic;
    
    BOOL hasVideo = [dic[@"HasVideo"] boolValue];
    self.userInteractionEnabled = hasVideo;
    
    containerView.hidden = ![dic[@"Selected"] boolValue];
    self.textLabel.text = [NSString stringWithFormat:@"%d", [dic[@"Title"] intValue]];
    self.textLabel.textColor = hasVideo ? [UIColor blackColor] : [[UIColor grayColor] colorWithAlphaComponent:0.3];
}

@end

#pragma mark - UICollectionViewLayout
@interface GosCalenderViewLayout : UICollectionViewLayout
@property (nonatomic) NSDate *currentDate;
@end
@interface GosCalenderViewLayout () {
    NSMutableArray *arrayM;
    NSInteger index;
}
@end
@implementation GosCalenderViewLayout
- (instancetype)init {
    self = [super init];
    if (!self)
        return nil;
    
    arrayM = [@[] mutableCopy];
    
    return self;
}

- (void)prepareLayout {
    [super prepareLayout];
    
    index = [self getStartIndexInYear:self.currentDate];
    
    [arrayM removeAllObjects];
    for (int i = 0; i < [self.collectionView numberOfItemsInSection:0]; i++) {
        UICollectionViewLayoutAttributes *attr = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
        [arrayM addObject:attr];
    }
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    return arrayM;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat w = self.collectionView.bounds.size.width / 7;
    CGFloat h = self.collectionView.bounds.size.height / 6;
    CGFloat startX = index * w;
    
    CGFloat x;
    CGFloat y;
    if(indexPath.item < 7 - index) {
        x = indexPath.item % 7 * w + startX;
        y = 0;
    }else {
        x = (indexPath.item + index) % 7 * w;
        y = (indexPath.item + index) / 7 * h;
    }
    UICollectionViewLayoutAttributes *attr = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    CGRect rect = CGRectMake(x, y, w, h);
    attr.frame = rect;
    return attr;
}

- (NSInteger)getStartIndexInYear:(NSDate *)date {
    NSArray *weekArray = @[@0, @1, @2, @3, @4, @5, @6];
    NSCalendar *calender = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
    comps.day = 1;
    
    NSDate *tmp = [calender dateFromComponents:comps];
    NSInteger dayOfweek = [calender component:NSCalendarUnitWeekday fromDate:tmp];
    return [[weekArray objectAtIndex:dayOfweek - 1] integerValue];
}
@end

#pragma mark - GosCalenderView
@interface GosCalenderView () <UICollectionViewDataSource, UICollectionViewDelegate> {
    GosCalenderViewLayout *layout;
    UICollectionView *collectionView;
    NSDate *currentDate;
    NSMutableArray *source;
    
    UIView *topView;
    UILabel *dateLabel;
    
    NSDate *selectedDate;
}
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic) NSArray<NSDate *> *hasVideoArray;
@property (nonatomic, copy) GosCalenderSelect blk;
@end
@implementation GosCalenderView

+ (void)showCalendarViewWithAttachFrame:(CGRect)attachFrame
                           selectedDate:(NSDate *)selectedDate
                          hasVideoArray:(NSArray<NSDate *> *)hasVideoArray
                         selectCallback:(GosCalenderSelect)callback {
    GosCalenderView *view = [[GosCalenderView alloc] initWithAttachFrame:attachFrame
                                                            selectedDate:selectedDate
                                                           hasVideoArray:hasVideoArray
                                                          selectCallback:callback];
    
    [[UIApplication sharedApplication].keyWindow addSubview:view];
}

- (void)dismiss {
    
    [self removeFromSuperview];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint point = [[touches anyObject] locationInView:self];
    UIView *hitView = [self hitTest:point withEvent:event];
    
    if (hitView != _contentView) {
        // content以外的地方就离开
        if (self.blk) {
            self.blk(nil);
        }
        [self dismiss];
    }
}

- (instancetype)initWithAttachFrame:(CGRect)attachFrame
                       selectedDate:(NSDate *)selectedDate
                      hasVideoArray:(NSArray<NSDate *> *)hasVideoArray
                     selectCallback:(GosCalenderSelect)callback {
    
    if (self = [super initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)]) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.4];
        
        currentDate = selectedDate?:[NSDate date];
        selectedDate = selectedDate;
        
        // 只用attachFrame的y轴坐标
        [self buildView:CGRectMake(0, CGRectGetMinY(attachFrame), SCREEN_WIDTH, SCREEN_HEIGHT*0.45)];
        [self buildDataSource:currentDate];
        
        self.blk = callback;
        self.hasVideoArray = hasVideoArray;
    }
    return self;
}

- (void)setHasVideoArray:(NSArray<NSDate *> *)hasVideoArray {
    _hasVideoArray = hasVideoArray;
    
    [self reloadData];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return source.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dic = source[indexPath.row];
    
    KHCalenderCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"GosCalenderViewCell" forIndexPath:indexPath];
    if (cell == nil)
        cell = [[KHCalenderCollectionViewCell alloc] init];

    NSDate *tmp = dic[@"Date"];
    if ([self hasVideo:tmp]) {
        NSMutableDictionary *dicM = [dic mutableCopy];
        dicM[@"HasVideo"] = @(YES);
        dic = [dicM copy];
    }
    
    cell.dic = dic;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    KHCalenderCollectionViewCell *cell = (KHCalenderCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if (!cell.userInteractionEnabled)
        return;
    
    NSMutableArray *arrayM = [@[] mutableCopy];
    [source enumerateObjectsUsingBlock:^(NSDictionary *dic, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableDictionary *tmp = [dic mutableCopy];
        
        if (idx == indexPath.row)
            tmp[@"Selected"] = @(YES);
        else
            tmp[@"Selected"] = @(NO);
        
        dic = [tmp copy];
        [arrayM addObject:dic];
    }];
    source = [arrayM copy];
    
    [collectionView reloadData];
    
    if (self.blk)
        self.blk([source[indexPath.row] objectForKey:@"Date"]);
    
    [self dismiss];
}

- (NSInteger)howManyDaysInYear:(NSDate *)date {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
    int month = (int)components.month;
    int year = (int)components.year;
    
    if((month == 1) || (month == 3) || (month == 5) || (month == 7) || (month == 8) || (month == 10) || (month == 12))
        return 31 ;
    
    if((month == 4) || (month == 6) || (month == 9) || (month == 11))
        return 30;
    
    if((year % 4 == 1) || (year % 4 == 2) || (year % 4 == 3))
        return 28;
    
    if(year % 400 == 0)
        return 29;
    
    if(year % 100 == 0)
        return 28;
    
    return 29;
}

- (void)buildView:(CGRect)frame {
    
    self.contentView = [[UIView alloc] initWithFrame:frame];
    self.contentView.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.contentView];
    
    CGFloat topViewH = frame.size.height*0.15;
    topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, topViewH)];
    [self.contentView addSubview:topView];
    
//    NSString *todayBtnStr = @"Today";
//    CGSize todayBtnSize = [todayBtnStr boundingRectWithSize:CGSizeMake(MAXFLOAT, frame.size.height * 0.8) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14.0]} context:nil].size;
//    UIButton *todayBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, todayBtnSize.width + 20, topViewH)];
//    [todayBtn setTitle:todayBtnStr forState:UIControlStateNormal];
//    [todayBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
//    todayBtn.titleLabel.font = [UIFont systemFontOfSize:14.0];
//    [todayBtn addTarget:self action:@selector(backTodayBtnDidClick) forControlEvents:UIControlEventTouchUpInside];
//    [topView addSubview:todayBtn];
    
//    UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(frame.size.width - 40, 0, 30, topViewH)];
//    [backBtn setImage:[UIImage imageNamed:@"c90Back"] forState:UIControlStateNormal];
//    [backBtn setImage:[UIImage imageNamed:@"c90BackClick"] forState:UIControlStateHighlighted];
//    [backBtn addTarget:self action:@selector(backBtnDidClick) forControlEvents:UIControlEventTouchUpInside];
//    backBtn.imageView.contentMode = UIViewContentModeScaleAspectFill;
//    [topView addSubview:backBtn];
    
    dateLabel = [[UILabel alloc] init];
    dateLabel.font = [UIFont systemFontOfSize:14.0];
    dateLabel.textColor = [UIColor blackColor];
    dateLabel.textAlignment = NSTextAlignmentCenter;
    dateLabel.text = [self getStringFromeDate:currentDate];
    CGSize dateLabelS = [dateLabel.text boundingRectWithSize:CGSizeMake(MAXFLOAT, frame.size.height) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14.0]} context:nil].size;
    dateLabelS.width += 50;
    dateLabel.frame = CGRectMake((frame.size.width - dateLabelS.width) * 0.5, 0, dateLabelS.width , topView.bounds.size.height);
    [topView addSubview:dateLabel];
    
    UIButton *leftBtn = [[UIButton alloc] initWithFrame:CGRectMake((frame.size.width - dateLabelS.width) * 0.5 - 0.1 * frame.size.width, 0, 0.1 * frame.size.width, topView.frame.size.height)];
    [leftBtn setImage:[UIImage imageNamed:@"dateShowLeft"] forState:UIControlStateNormal];
    [leftBtn setImage:[UIImage imageNamed:@"dateShowLeftClick"] forState:UIControlStateHighlighted];
    [leftBtn addTarget:self action:@selector(leftBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:leftBtn];
    
    UIButton *rightBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(dateLabel.frame), 0, 0.1 * frame.size.width, topView.frame.size.height)];
    [rightBtn setImage:[UIImage imageNamed:@"dateShowRight"] forState:UIControlStateNormal];
    [rightBtn setImage:[UIImage imageNamed:@"dateShowRightClick"] forState:UIControlStateHighlighted];
    [rightBtn addTarget:self.superview action:@selector(rightBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:rightBtn];
    
    float labelWidth = frame.size.width / 7;
    float labelHeight = 0.1 * frame.size.height;
    for (int i = 0; i < 7; i++) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(i * labelWidth, CGRectGetMaxY(topView.frame)+1, labelWidth, labelHeight)];
        label.font = [UIFont systemFontOfSize:14.0];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor blackColor];
        label.text = [self getLabelName:i];
        [self.contentView addSubview:label];
    }
    
    CGFloat collectionViewH = frame.size.height-topViewH-labelHeight;
    layout = [[GosCalenderViewLayout alloc] init];
    layout.currentDate = currentDate;
    collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(frame.origin.x, CGRectGetMaxY(topView.frame)+labelHeight+1, frame.size.width, collectionViewH) collectionViewLayout:layout];
    [collectionView registerClass:[KHCalenderCollectionViewCell class] forCellWithReuseIdentifier:@"GosCalenderViewCell"];
    collectionView.backgroundColor = [UIColor whiteColor];;
    collectionView.dataSource = self;
    collectionView.delegate = self;
    [self.contentView addSubview:collectionView];
}

- (NSString *)getLabelName:(int)number {
    NSString *labelName = @"";
    switch (number) {
        case 0:
            labelName = @"Sun";
            break;
        case 1:
            labelName = @"Mon";
            break;
        case 2:
            labelName = @"Tues";
            break;
        case 3:
            labelName = @"Wed";
            break;
        case 4:
            labelName = @"Thur";
            break;
        case 5:
            labelName = @"Fri";
            break;
        case 6:
            labelName = @"Sat";
            break;
    }
    return labelName;
}

- (NSString *)getStringFromeDate:(NSDate *)date {
    if (!date)
        return nil;
    
    NSDateComponents *comp = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:date];
    return [NSString stringWithFormat:@"%ld - %02ld", comp.year, comp.month];
}

- (void)leftBtnClick {
    NSDateComponents *comp = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:currentDate];
    NSInteger year = comp.year;
    NSInteger month = comp.month;
    
    if (month-- < 1) {
        month = 12;
        year -= 1;
    }
    
    comp.year = year;
    comp.month = month;
    
    NSDate *newDate = [[NSCalendar currentCalendar] dateFromComponents:comp];
    currentDate = newDate;
    
    [self reloadData];
}
/// 判断传参时间是否大于当前日子时间——基于年月
- (BOOL)isDateGreaterNowMonthWithDate:(NSDate *)date {
    NSDateComponents *compNow = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:[NSDate date]];
    NSDateComponents *compDate = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:currentDate];
    
    return (compDate.year > compNow.year) || (compNow.year == compDate.year && compDate.month >= compNow.month);
}

- (void)rightBtnClick {
    NSDateComponents *comp = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:currentDate];
    
    NSInteger year = comp.year;
    NSInteger month = comp.month;
    
    if (month++ > 12) {
        month = 1;
        year += 1;
    }
    
    comp.year = year;
    comp.month = month;
    
    NSDate *newDate = [[NSCalendar currentCalendar] dateFromComponents:comp];
    // 如果新的时间大于当前时间，就不刷新
    if ([self isDateGreaterNowMonthWithDate:newDate]) return ;
    
    currentDate = newDate;
    
    [self reloadData];
}

- (void)reloadData {
    dateLabel.text = [self getStringFromeDate:currentDate];
    layout.currentDate = currentDate;
    [self buildDataSource:currentDate];
    [collectionView reloadData];
}

- (BOOL)hasVideo:(NSDate *)date {
    for (int i = 0; i < self.hasVideoArray.count; ++i) {
        NSDate *tmp = self.hasVideoArray[i];
        if ([date compare:tmp] == kCFCompareEqualTo)
            return YES;
    }
    
    return NO;
}

- (void)buildDataSource:(NSDate *)date {
    source = [@[] mutableCopy];
    
    for (int i = 0; i < [self howManyDaysInYear:date]; ++i) {
        NSDateComponents *comp = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
        
//        BOOL isSelected = comp.day == (i+1) ? YES : NO;
        comp.day = i+1;
        NSDate *tmpDate = [[NSCalendar currentCalendar] dateFromComponents:comp];
        BOOL isSelected = selectedDate?[[NSCalendar currentCalendar] isDate:tmpDate inSameDayAsDate:selectedDate]:NO;
        
        NSDictionary *dic = @{@"Date" : tmpDate,
                              @"Selected" : @(isSelected),
                              @"Title" : [NSString stringWithFormat:@"%d", i+1],
                              @"HasVideo" : @(NO)
                              };
        [source addObject:dic];
    }
}
@end


@interface GosCalenderExternalView ()
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation GosCalenderExternalView
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.calendarButton];
        _enableControl = YES;
        CGFloat cW = frame.size.width/2.0;
        CGFloat cX = (frame.size.width - cW)/2.0;
        self.calendarButton.frame = CGRectMake(cX, 0, cW, frame.size.height);
        self.calendarButton.imageEdgeInsets = UIEdgeInsetsMake(0, -40, 0, 0);
        CGFloat leftW = (frame.size.width - _calendarButton.width) / 2.0;
        UIButton *leftBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, leftW, frame.size.height)];
//        UIButton *leftBtn = [[UIButton alloc] initWithFrame:CGRectMake((frame.size.width - _calendarButton.width) * 0.5 - 0.1 * frame.size.width, 0, 0.1 * frame.size.width, frame.size.height)];
        [leftBtn setImage:[UIImage imageNamed:@"dateShowLeft"] forState:UIControlStateNormal];
        [leftBtn setImage:[UIImage imageNamed:@"dateShowLeftClick"] forState:UIControlStateHighlighted];
        [leftBtn addTarget:self action:@selector(leftBtnClick) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:leftBtn];
        
        UIButton *rightBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.calendarButton.frame), 0, leftW, frame.size.height)];
//        UIButton *rightBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.calendarButton.frame), 0, 0.1 * frame.size.width, frame.size.height)];
        [rightBtn setImage:[UIImage imageNamed:@"dateShowRight"] forState:UIControlStateNormal];
        [rightBtn setImage:[UIImage imageNamed:@"dateShowRightClick"] forState:UIControlStateHighlighted];
        [rightBtn addTarget:self.superview action:@selector(rightBtnClick) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:rightBtn];
        
        self.currentDate = [NSDate date];
    }
    return self;
}

- (void)leftBtnClick {
    if (!self.isEnableControl) return ;
    
    self.currentDate = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:-1 toDate:_currentDate options:NSCalendarSearchBackwards];
    // 回调
    self.blk(_currentDate);
}

- (void)rightBtnClick {
    if (!self.isEnableControl) return ;
    
    NSDate *newDate = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:1 toDate:_currentDate options:NSCalendarSearchBackwards];
    // 如果超过当前日子就进行下一步
    if ([self isDateGreaterNowadayWithDate:newDate]) return ;
    
    self.currentDate = newDate;
    // 回调
    self.blk(_currentDate);
}

/// 判断传参时间是否大于当前日子时间——基于日
- (BOOL)isDateGreaterNowadayWithDate:(NSDate *)date {
    return [[NSCalendar currentCalendar] isDateInTomorrow:date];
}

- (void)setCurrentDate:(NSDate *)currentDate {
    _currentDate = currentDate;
    
    [self.calendarButton setTitle:[self.dateFormatter stringFromDate:currentDate] forState:UIControlStateNormal];
}

- (UIButton *)calendarButton {
    if (!_calendarButton) {
        _calendarButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_calendarButton setImage:[UIImage imageNamed:@"icon_calendar_big"] forState:UIControlStateNormal];
        
        [_calendarButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    return _calendarButton;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd"];
    }
    return _dateFormatter;
}
- (void)dealloc {
    NSLog(@"-----------GosCalenderExternalView-----------");
}
@end
