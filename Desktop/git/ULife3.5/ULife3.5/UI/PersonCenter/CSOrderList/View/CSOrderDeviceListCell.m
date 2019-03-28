//
//  CSOrderDeviceListCell.m
//  ULife3.5
//
//  Created by Goscam on 2018/4/20.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "CSOrderDeviceListCell.h"

//边框间距
static const double CellMargin = 10;

//视图间距
static const double ViewSpacingInX = 8;

static const double ViewSpacingInY = 6;

@interface CSOrderDeviceListCell()
{
}

@property (strong, nonatomic)  UIView *screenShotImgViewCover;

@property (strong, nonatomic)  UIImageView *latestScreenShotImgView;

@property (strong, nonatomic)  UILabel * deviceNameLabel;

@property (strong, nonatomic)  UILabel * packageTypeLabel;

@property (strong, nonatomic)  UILabel * validTimeLabel;


@end

@implementation CSOrderDeviceListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.hidden = YES;
        self.detailTextLabel.hidden = YES;
//        self.separatorInset = UIEdgeInsetsZero;
//        self.layoutMargins = UIEdgeInsetsZero;
//        self.preservesSuperviewLayoutMargins = NO;
        
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        [self addSubViews];
        [self makeConstraints];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

//MARK: - View
- (void)addSubViews{
    
    [self addSubview: self.latestScreenShotImgView];
    [self addSubview: self.screenShotImgViewCover];
    [self addSubview: self.deviceNameLabel];
    [self addSubview: self.packageTypeLabel];
    [self addSubview: self.validTimeLabel];
}

- (void)makeConstraints{
    
    [self.latestScreenShotImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self).offset(CellMargin);
        make.top.equalTo(self).offset(CellMargin);
        make.width.mas_equalTo(110*SCREEN_WIDTH_RATIO);
        make.centerY.equalTo(self);
    }];
    
    [self.screenShotImgViewCover mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.latestScreenShotImgView);
    }];
    
    [self.deviceNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.latestScreenShotImgView.mas_trailing).offset(ViewSpacingInX);
        make.top.equalTo(self.latestScreenShotImgView);
        make.trailing.equalTo(self).offset(0);
    }];
    
    [self.packageTypeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.deviceNameLabel);
        make.top.equalTo(self.deviceNameLabel.mas_bottom).offset(ViewSpacingInY);
        make.trailing.equalTo(self.deviceNameLabel);
    }];
    
    [self.validTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.deviceNameLabel);
        make.top.equalTo(self.packageTypeLabel.mas_bottom).offset(ViewSpacingInY/2);
        make.trailing.equalTo(self.deviceNameLabel);
    }];
}

- (void)setCellModel:(CSOrderDeviceListCellModel *)cellModel{
    
    _cellModel = cellModel;
    
    NSRange tempRange = [cellModel.devName rangeOfString:MLocalizedString(CSOrder_Unbind_Removed) ];
    if (tempRange.length > 0 ) {
        NSMutableAttributedString *devNameStr = [[NSMutableAttributedString alloc] initWithString:cellModel.devName];
        [devNameStr addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:tempRange];
        self.deviceNameLabel.attributedText = devNameStr;
    }else{
        self.deviceNameLabel.text =  cellModel.devName;
    }
    self.screenShotImgViewCover.hidden = !(tempRange.length>0);
    
    self.packageTypeLabel.text =  cellModel.packageType;
    self.validTimeLabel.text =  cellModel.validTime;
    
    UIImage *tempImage = [UIImage imageWithContentsOfFile: cellModel.imagePath];
    if (!tempImage) {
        tempImage = [UIImage imageNamed:@"defaultCovert.jpg"];
    }
    
    self.latestScreenShotImgView.image = tempImage;
    
    [self setNeedsDisplay];
    [self layoutIfNeeded];
}

//MARK: - getters
- (UILabel*)deviceNameLabel{
    if (!_deviceNameLabel) {
        _deviceNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
    }
    return _deviceNameLabel;
}

- (UILabel*)validTimeLabel{
    if (!_validTimeLabel) {
        _validTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
        _validTimeLabel.font = [UIFont systemFontOfSize:13];
        _validTimeLabel.textColor = [UIColor lightGrayColor];
        _validTimeLabel.numberOfLines = 0;
    }
    return _validTimeLabel;
}

- (UILabel*)packageTypeLabel{
    if (!_packageTypeLabel) {
        _packageTypeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
        _packageTypeLabel.font = [UIFont systemFontOfSize:15];
        _packageTypeLabel.textColor = [UIColor grayColor];
    }
    return _packageTypeLabel;
}

- (UIImageView*)latestScreenShotImgView{
    if (!_latestScreenShotImgView) {
        _latestScreenShotImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
    }
    return _latestScreenShotImgView;
}

- (UIView*)screenShotImgViewCover{
    if (!_screenShotImgViewCover) {
        _screenShotImgViewCover = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        _screenShotImgViewCover.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
        _screenShotImgViewCover.hidden = YES;
    }
    return _screenShotImgViewCover;
}
@end
