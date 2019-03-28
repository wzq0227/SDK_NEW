//
//  RecordDateListTableViewCell.m
//  goscamapp
//
//  Created by shenyuanluo on 2017/4/28.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "RecordDateListTableViewCell.h"


@interface RecordDateListTableViewCell ()

/**
 *  图片缩略图 imageView
 */
@property (weak, nonatomic) IBOutlet UIImageView *recordDateImageView;

/**
 *  录像日期 Label
 */
@property (weak, nonatomic) IBOutlet UILabel *recordDateLabel;

@end


@implementation RecordDateListTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}


#pragma mark -- 数据源处理
- (void)setRecordDateTableViewCellData:(RecordDateTableViewCellModel *)recordDateTableViewCellData
{
    if (!recordDateTableViewCellData)
    {
        return ;
    }
    _recordDateTableViewCellData   = recordDateTableViewCellData;
    self.recordDateImageView.image = [UIImage imageNamed:@"Record_FolderIcon.png"];
    self.recordDateLabel.text      = recordDateTableViewCellData.recordDateStr;
}

@end
