//
//  RecordImgTableViewCell.m
//  goscamapp
//
//  Created by shenyuanluo on 2017/4/28.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "RecordImgTableViewCell.h"
#import <Masonry.h>
#import "EnlargeClickButton.h"

#define KB_SIZE 1024

#define MB_SIZE 1048576     // 1024 * 1024

#define GB_SIZE 1073741842  // 1024 * 1024 * 1024

@interface RecordImgTableViewCell ()

/**
 *  图片日期 Label
 */
@property (strong, nonatomic)UILabel *dateLabel;

/**
 *  图片文件名 Label
 */
@property (strong, nonatomic)UILabel *fileNameLabel;

/**
 *  图片文件大小 Label
 */
@property (strong, nonatomic)UILabel *fileSizeLabel;

/**
 *  图片缩略图 imageView
 */
@property (strong, nonatomic)UIImageView *typeImageView;

/**
 *  图片下载状态 imageView
 */
@property (strong, nonatomic)UIImageView *statusImageView;

/**
 *  编辑模式选择 imageBtn
 */
@property (strong, nonatomic)EnlargeClickButton *selectImgBtn;


@end


@implementation RecordImgTableViewCell


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupUI];
        [self updateNormalConstraints];
    }
    return self;
}


#pragma mark - setUI

- (void)setupUI{
    [self.contentView addSubview:self.dateLabel];
    [self.contentView addSubview:self.fileNameLabel];
    [self.contentView addSubview:self.fileSizeLabel];
    [self.contentView addSubview:self.typeImageView];
    [self.contentView addSubview:self.selectImgBtn];
    [self.contentView addSubview:self.statusImageView];
}



#pragma mark - update Constaints

- (void)updateNormalConstraints{
    self.selectImgBtn.hidden = YES;
    
    [self.selectImgBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(15);
        make.width.height.equalTo(@20);
        make.top.equalTo(self.contentView).offset(24);
    }];
    
    [self.dateLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(8 + 10);
        make.top.equalTo(self.contentView).offset(10);
        make.right.equalTo(self.contentView).offset(-45);
        make.height.equalTo(@8);
    }];
    
    [self.typeImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(10);
        make.top.equalTo(self.contentView).offset(5 + 18);
        make.width.height.equalTo(@39);
    }];
    
    [self.fileNameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(25);
        make.left.equalTo(self.typeImageView.mas_right);
        make.right.equalTo(self.contentView).offset(-45);
        make.height.equalTo(@18);
    }];
    
    [self.fileSizeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@8);
        make.top.equalTo(self.contentView).offset(48);
        make.left.equalTo(self.typeImageView.mas_right);
        make.right.equalTo(self.contentView).offset(-45);
    }];
    
    [self.statusImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@25);
        make.centerY.equalTo(self.contentView);
        make.right.equalTo(self.contentView).offset(-18);
    }];
}


- (void)updateEditStyleConstraints{
    self.selectImgBtn.hidden = NO;
    
    [self.selectImgBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(15);
        make.width.height.equalTo(@20);
        make.top.equalTo(self.contentView).offset(24);
    }];
    
    [self.dateLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(8 + 51);
        make.top.equalTo(self.contentView).offset(10);
        make.right.equalTo(self.contentView).offset(-45);
        make.height.equalTo(@8);
    }];
    
    [self.typeImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(51);
        make.top.equalTo(self.contentView).offset(5 + 18);
        make.width.height.equalTo(@39);
    }];
    
    [self.fileNameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@18);
        make.top.equalTo(self.contentView).offset(25);
        make.left.equalTo(self.typeImageView.mas_right);
        make.right.equalTo(self.contentView).offset(-45);
    }];
    
    [self.fileSizeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@8);
        make.top.equalTo(self.contentView).offset(48);
        make.left.equalTo(self.fileNameLabel);
        make.right.equalTo(self.fileNameLabel);
    }];
    
    [self.statusImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@25);
        make.centerY.equalTo(self.contentView);
        make.right.equalTo(self.contentView).offset(-18);
    }];
}

#pragma mark - Event Handle

- (void)selectClick:(UIButton *)selectBtn{
    self.selectImgBtn.selected = !self.selectImgBtn.selected;

    if (self.selectImgBtn.selected) {
        //选中
        [self setSelectBtnStatus:YES];
        if (self.selectBlock) {
            self.selectBlock(YES, self);
        }
        if (self.localVideoModel) {
            self.localVideoModel.isSelect = YES;
        }
        if (self.recordImgTableViewCellData) {
            self.recordImgTableViewCellData.isSelect = YES;
        }
        if (self.myStateBlock) {
            self.myStateBlock(YES);
        }
     
    }
    else{
        //未选中
        [self setSelectBtnStatus:NO];
        if (self.selectBlock) {
            self.selectBlock(NO, self);
        }
        if (self.localVideoModel) {
            self.localVideoModel.isSelect = NO;
        }
        if (self.recordImgTableViewCellData) {
            self.recordImgTableViewCellData.isSelect = NO;
        }
        if (self.myStateBlock) {
            self.myStateBlock(NO);
        }

    }
}

/**
 ☑️按钮是否响应点击事件
 
 @param enabled YES 表示响应 NO 不响应
 */
- (void)setSelectBtnEnabled:(BOOL)enabled{
    self.selectImgBtn.userInteractionEnabled = enabled;
}



#pragma mark -- 数据源处理
- (void)setRecordImgTableViewCellData:(RecordImgTableViewCellModel *)recordImgTableViewCellData
{
    if (!recordImgTableViewCellData)
    {
        return ;
    }
    _recordImgTableViewCellData   = recordImgTableViewCellData;
    self.dateLabel.text           = recordImgTableViewCellData.recordImgDateStr;
    self.fileNameLabel.text       = recordImgTableViewCellData.recordImgFileNameStr;
    self.fileSizeLabel.text       = recordImgTableViewCellData.recordImgFileSizeStr;
    self.typeImageView.image      = [UIImage imageNamed:@"Record_ImageIcon@2x.png"];
    [self setDownloadStatusImage:recordImgTableViewCellData.isDownload];
    [self setSelectBtnStatus:recordImgTableViewCellData.isSelect];
    
    NSString *  string = [self.fileNameLabel.text substringFromIndex:15];//截取掉下标7之后的字符串
    string = [string substringToIndex:2];
    NSLog(@"截取的值为：%@",string);
    if ([string isEqualToString:@"bd"] ||[string isEqualToString:@"cd"]|| [string isEqualToString:@"dd"]||[string isEqualToString:@"ed"]) {
        self.typeImageView.image      = [UIImage imageNamed:@"btn-Infrared detection-disabled"];
    }
    else if([string isEqualToString:@"be"] ||[string isEqualToString:@"ce"]|| [string isEqualToString:@"de"]||[string isEqualToString:@"ee"]){
        self.typeImageView.image      = [UIImage imageNamed:@"btn-Sound detection-disabled"];
    }
    else if([string isEqualToString:@"bc"] ||[string isEqualToString:@"cc"]|| [string isEqualToString:@"dc"]||[string isEqualToString:@"ec"]){
        self.typeImageView.image      = [UIImage imageNamed:@"btn-Infrared detection-disabled"];
    }
    else if([string isEqualToString:@"bb"] ||[string isEqualToString:@"cb"]|| [string isEqualToString:@"db"]||[string isEqualToString:@"eb"]){
        self.typeImageView.image      = [UIImage imageNamed:@"btn-Motion detection-disabled"];
    }
    else if([string isEqualToString:@"ea"]){
        self.typeImageView.image      = [UIImage imageNamed:@"Setting_Alexa"];
    }
    else if([string isEqualToString:@"ca"]){
        self.typeImageView.image      = [UIImage imageNamed:@"Setting_ManualRecord"];
    }
    else if([string isEqualToString:@"ba"]){
        self.typeImageView.image      = [UIImage imageNamed:@"Setting_ManualRecord"];
    }
}


- (void)setLocalVideoModel:(LocalVideoModel *)localVideoModel
{
    if (!localVideoModel) {
        return;
    }
    _localVideoModel   = localVideoModel;
    self.dateLabel.text           = [NSString stringWithFormat:@"%@ %@",localVideoModel.recordVideoDateStr,localVideoModel.recordVideoTimeStr];
    self.fileNameLabel.text       = localVideoModel.recordVideoFileNameStr;
    self.fileSizeLabel.text       = localVideoModel.recordVideoFileSizeStr;
    self.typeImageView.image      = [UIImage imageNamed:@"Record_ImageIcon@2x.png"];
    [self setDownloadStatusImage:YES];
    [self setSelectBtnStatus:localVideoModel.isSelect];
    
    
}


- (void)setMediaFileCellData:(MediaFileModel *)mediaFileCellData
{
    if (!mediaFileCellData)
    {
        return;
    }
    _mediaFileCellData       = mediaFileCellData;
    self.dateLabel.text      = [NSString stringWithFormat:@"%@ %@", mediaFileCellData.createDate, mediaFileCellData.createTime];
    self.fileNameLabel.text  = mediaFileCellData.fileName;
    
    NSString *sizeStr = nil;
    if (KB_SIZE > mediaFileCellData.fileSize)
    {
        sizeStr = [NSString stringWithFormat:@"%lluB", mediaFileCellData.fileSize];
    }
    else if (KB_SIZE < mediaFileCellData.fileSize
             && MB_SIZE > mediaFileCellData.fileSize)
    {
        float countKB = mediaFileCellData.fileSize / 1024.0f;
        sizeStr = [NSString stringWithFormat:@"%.02fKB", countKB];
    }
    else if (MB_SIZE < mediaFileCellData.fileSize
             && GB_SIZE > mediaFileCellData.fileSize)
    {
        float countMB = mediaFileCellData.fileSize / (1024.0f * 1024.0f);
        sizeStr = [NSString stringWithFormat:@"%.02fMB", countMB];
    }
    else if (GB_SIZE < mediaFileCellData.fileSize)
    {
        float countGB = mediaFileCellData.fileSize / (1024.0f * 1024.0f * 1024.0f);
        sizeStr = [NSString stringWithFormat:@"%.02fGB", countGB];
    }
    
    self.fileSizeLabel.text  = sizeStr;
    self.typeImageView.image = [UIImage imageNamed:@"Record_ImageIcon@2x.png"];
    [self setDownloadStatusImage:YES];
    [self setSelectBtnStatus:mediaFileCellData.isSelected];
}


- (void)setSelectBtnStatus:(BOOL)isSelect{
    if (isSelect) {
        //选中
        [self.selectImgBtn setBackgroundImage:[UIImage imageNamed:@"deleteBtnHeighLight"] forState:UIControlStateNormal];
        self.selectImgBtn.selected = YES;
    }
    else{
        //未选中
        [self.selectImgBtn setBackgroundImage:[UIImage imageNamed:@"deleteBtnNormal"] forState:UIControlStateNormal];
        self.selectImgBtn.selected = NO;
    }
}
#pragma mark - 编辑模式处理
- (void)setIsEditStyle:(BOOL)isEditStyle{
    _isEditStyle = isEditStyle;
    if (_isEditStyle) {
        [self updateEditStyleConstraints];
    }
    else{
        [self updateNormalConstraints];
    }
    self.statusImageView.hidden=_isEditStyle;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark -- 设置下载状态图片
- (void)setDownloadStatusImage:(BOOL)isDownload
{
    if (NO == isDownload)    // 未下载
    {
        self.statusImageView.image = [UIImage imageNamed:@"Record_DownloadIcon.png"];
    }
    else    // 已下载
    {
        self.statusImageView.image = [UIImage imageNamed:@"Record_PlayIcon.png"];
    }
}

- (void)setStatusImgViewHidden:(BOOL)isHidden{
    self.statusImageView.hidden = isHidden;
}

#pragma mark - getter

/**
 *  图片日期 Label
 */
- (UILabel *)dateLabel{
    if (!_dateLabel) {
        _dateLabel = [[UILabel alloc]init];
        _dateLabel.textColor = [UIColor blackColor];
        _dateLabel.textAlignment = NSTextAlignmentLeft;
        _dateLabel.font = [UIFont systemFontOfSize:11.0f];
    }
    return _dateLabel;
}



/**
 *  图片文件名 Label
 */
- (UILabel *)fileNameLabel{
    if (!_fileNameLabel) {
        _fileNameLabel = [[UILabel alloc]init];
        _fileNameLabel.textColor = [UIColor blackColor];
        _fileNameLabel.textAlignment = NSTextAlignmentLeft;
        _fileNameLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    return _fileNameLabel;
}

/**
 *  图片文件大小 Label
 */
- (UILabel *)fileSizeLabel{
    if (!_fileSizeLabel) {
        _fileSizeLabel = [[UILabel alloc]init];
        _fileSizeLabel.textColor = [UIColor blackColor];
        _fileSizeLabel.textAlignment = NSTextAlignmentLeft;
        _fileSizeLabel.font = [UIFont systemFontOfSize:11.0f];
    }
    return _fileSizeLabel;
}

/**
 *  图片缩略图 imageView
 */
- (UIImageView *)typeImageView{
    if (!_typeImageView) {
        _typeImageView = [[UIImageView alloc]init];
        _typeImageView.image = [UIImage imageNamed:@"Record_ImageIcon@2x.png"];
    }
    return _typeImageView;
}

/**
 *  图片下载状态 imageView
 */
- (UIImageView *)statusImageView{
    if (!_statusImageView) {
        _statusImageView = [[UIImageView alloc]init];
        _statusImageView.image = [UIImage imageNamed:@"Record_DownloadIcon.png"];
    }
    return _statusImageView;
}

/**
 *  编辑模式选择 imageBtn
 */
- (EnlargeClickButton *)selectImgBtn{
    if (!_selectImgBtn) {
        _selectImgBtn = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
        [_selectImgBtn setBackgroundImage:[UIImage imageNamed:@"Record_FileUnselected"] forState:UIControlStateNormal];
        _selectImgBtn.hidden = YES;
        [_selectImgBtn addTarget:self action:@selector(selectClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _selectImgBtn;
}

@end
