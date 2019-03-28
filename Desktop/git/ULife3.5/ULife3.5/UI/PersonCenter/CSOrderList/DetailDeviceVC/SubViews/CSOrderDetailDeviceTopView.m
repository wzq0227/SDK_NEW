//
//  CSOrderDetailDeviceTopView.m
//  ULife3.5
//
//  Created by Goscam on 2018/4/23.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "CSOrderDetailDeviceTopView.h"

@interface CSOrderDetailDeviceTopView()

@property (strong, nonatomic)  UILabel *renewOrTransferLabel;

@property (strong, nonatomic)  UIButton *renewOrTransferBtn;

@property (strong, nonatomic)  UILabel *playbackLabel;

@property (strong, nonatomic)  UIButton *playbackBtn;

@property (strong, nonatomic)  UIView *playbackBtnCover;

@property (strong, nonatomic)  UIImageView *playbackImgView;

@property (strong, nonatomic)  UIView *separatorLineInX;

@property (strong, nonatomic)  UIView *separatorLineInY;

@property (strong, nonatomic)  CSActionCallback csActionCallback;

@end



@implementation CSOrderDetailDeviceTopView

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}



- (void)commonInit{
    
    [self configUI];
}

- (void)configUI{
    
    self.backgroundColor = [UIColor whiteColor];
    
    [self addSubViews];
    
    [self makeCosntraints];
}

- (void)setCsOrderModel:(CSOrderDeviceListCellModel *)csOrderModel{
    _csOrderModel = csOrderModel;
    [self setImagePath:csOrderModel.imagePath];
    [self resetBtnAndLabel];
}

- (void)setImagePath:(NSString*)imgPath {
    
    UIImage *tempImage = [UIImage imageWithContentsOfFile:imgPath];
    if (!tempImage) {
        tempImage = [UIImage imageNamed:@"defaultCovert.jpg"];
    }
    
    [self.playbackBtn setImage:tempImage forState:0];
}

- (void)resetBtnAndLabel{
    BOOL enablePlayback = _csOrderModel.orderStatus == CSOrderStatusInUse|| _csOrderModel.orderStatus == CSOrderStatusUnbind;
    self.playbackBtn.userInteractionEnabled = enablePlayback;
    self.playbackBtnCover.hidden = enablePlayback;
    
    [self.renewOrTransferBtn setImage:[UIImage imageNamed:_csOrderModel.orderStatus==CSOrderStatusUnbind?@"CSOrder_Icon_Transfer":@"CSOrder_Icon_Renew"] forState:0];
    
    if (_csOrderModel.orderStatus == CSOrderStatusUnpurchased ) {
        self.renewOrTransferLabel.text = MLocalizedString(Setting_CSOrder_Order);
    }else{
        self.renewOrTransferLabel.text = DPLocalizedString(_csOrderModel.orderStatus==CSOrderStatusUnbind?@"CSOrder_TransferBtn_Title":@"PackageRenew");
    }
}


- (void)makeCosntraints{
    
    [self.separatorLineInX mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).mas_offset(20);
        make.center.equalTo(self);
        make.width.mas_equalTo(1);
    }];
    
    [self.playbackBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).mas_offset(41);
        make.leading.equalTo(self).mas_offset(35);
        make.trailing.equalTo(self.separatorLineInX).mas_offset(-35);
        make.centerY.equalTo(self);
    }];
    
    [self.playbackBtnCover mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.playbackBtn);
    }];
    
    [self.playbackImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.playbackBtn);
        make.width.height.mas_equalTo(28);
    }];
    
    [self.playbackLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.playbackBtn);
        make.top.equalTo(self.playbackBtn.mas_bottom).mas_offset(10);
        make.width.mas_equalTo(100);
    }];
    
    [self.renewOrTransferBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.leading.equalTo(self.separatorLineInX).mas_offset(50*SCREEN_WIDTH_RATIO);
        make.trailing.equalTo(self).mas_offset(-50*SCREEN_WIDTH_RATIO);
        make.width.mas_equalTo(80);
        make.height.mas_equalTo(56);
    }];
    
    [self.renewOrTransferLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.renewOrTransferBtn);
        make.top.equalTo(self.renewOrTransferBtn.mas_bottom).mas_offset(18);
        make.width.mas_equalTo(180);
    }];
    
    [self.separatorLineInY mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_offset(1);
        make.bottom.leading.trailing.equalTo(self);
    }];
}

- (void)addSubViews{
    

    [self addSubview:self.playbackBtn];
    [self addSubview:self.renewOrTransferBtn];

    [self addSubview:self.playbackLabel];
    [self addSubview:self.playbackImgView];
    [self addSubview:self.playbackBtnCover];
    
    [self addSubview:self.renewOrTransferLabel];
    
    [self addSubview:self.separatorLineInX];
    [self addSubview:self.separatorLineInY];

}

//MARK:- Actions
- (void)clickCallback:(CSActionCallback)aCallbackBlcok{
    _csActionCallback = aCallbackBlcok;
}

- (void)renewOrTransferBtnClicked:(id)sender{
    !_csActionCallback?:_csActionCallback( CSAction_RenewOrTransfer);
}

- (void)playbackBtnClicked:(id)sender{
    !_csActionCallback?:_csActionCallback(CSAction_Playback);
}


//MARK: - getters
- (UILabel*)playbackLabel{
    if (!_playbackLabel) {
        _playbackLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
        _playbackLabel.textAlignment = NSTextAlignmentCenter;
        _playbackLabel.font = [UIFont systemFontOfSize:15];
        _playbackLabel.text = DPLocalizedString(@"VR360_playback");
    }
    return _playbackLabel;
}


- (UILabel*)renewOrTransferLabel{
    if (!_renewOrTransferLabel) {
        _renewOrTransferLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
        _renewOrTransferLabel.textAlignment = NSTextAlignmentCenter;
        _renewOrTransferLabel.font = [UIFont systemFontOfSize:15];
        _renewOrTransferLabel.text = DPLocalizedString(@"PackageRenew");
    }
    return _renewOrTransferLabel;
}


- (UIButton*)renewOrTransferBtn{
    if (!_renewOrTransferBtn) {
        _renewOrTransferBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
        [_renewOrTransferBtn setImage:[UIImage imageNamed:@"CSOrder_Icon_Renew"] forState:UIControlStateNormal];//CSOrder_Icon_Transfer
        [_renewOrTransferBtn addTarget:self action:@selector(renewOrTransferBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _renewOrTransferBtn;
}


- (UIButton*)playbackBtn{
    if (!_playbackBtn) {
        _playbackBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
        [_playbackBtn addTarget:self action:@selector(playbackBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playbackBtn;
}

//
- (UIImageView*)playbackImgView{
    if (!_playbackImgView) {
        _playbackImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        _playbackImgView.image = [UIImage imageNamed:@"CSOrder_Icon_Playback"];
    }
    return _playbackImgView;
}


- (UIView*)playbackBtnCover{
    if (!_playbackBtnCover) {
        _playbackBtnCover = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        _playbackBtnCover.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
        _playbackBtnCover.hidden = YES;
    }
    return _playbackBtnCover;
}

- (UIView*)separatorLineInX{
    if (!_separatorLineInX) {
        _separatorLineInX = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, 320)];
        _separatorLineInX.backgroundColor = [UIColor lightGrayColor];
        _separatorLineInX.alpha = 0.5;
    }
    return _separatorLineInX;
}

- (UIView*)separatorLineInY{
    if (!_separatorLineInY) {
        _separatorLineInY = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320,2)];
        _separatorLineInY.backgroundColor = [UIColor lightGrayColor];
        _separatorLineInY.alpha = 0.5;
    }
    return _separatorLineInY;
}


@end
