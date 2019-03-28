//
//  RecordDateInfoTableViewCell.m
//  goscamapp
//
//  Created by shenyuanluo on 2017/4/28.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "RecordDateInfoTableViewCell.h"


@interface RecordDateInfoTableViewCell ()

/**
 *  图片缩略图 imageView
 */
@property (weak, nonatomic) IBOutlet UIImageView *recordDateInfoImageView;

/**
 *  录像日期内容 Label
 */
@property (weak, nonatomic) IBOutlet UILabel *recordDateInfoLabel;

@end


@implementation RecordDateInfoTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}


#pragma mark -- 数据源处理
- (void)setRecordDateInfoTableViewCellData:(RecordDateInfoTableViewCellModel *)recordDateInfoTableViewCellData
{
    if (!recordDateInfoTableViewCellData)
    {
        return ;
    }
    _recordDateInfoTableViewCellData   = recordDateInfoTableViewCellData;
    self.recordDateInfoImageView.image = [UIImage imageNamed:@"Record_FolderIcon.png"];
    self.recordDateInfoLabel.text      = recordDateInfoTableViewCellData.recordDateInfoStr;
}


@end
