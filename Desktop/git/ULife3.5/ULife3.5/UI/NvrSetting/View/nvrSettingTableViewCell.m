//
//  nvrSettingTableViewCell.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/23.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "nvrSettingTableViewCell.h"

@interface nvrSettingTableViewCell ()

/** 设置类型 ImageView */
@property (weak, nonatomic) IBOutlet UIImageView *setTypeImageView;

/** 设置内容  Label */
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;

/** 新版本提示 View */
@property (weak, nonatomic) IBOutlet UIView *updateVersionView;

@end

@implementation nvrSettingTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}


- (void)setNvrSettingCellData:(NvrSettingDataModel *)nvrSettingCellData
{
    if (!nvrSettingCellData)
    {
        NSLog(@"对象不存在，无法配置 NVR setting Cell ！");
        return;
    }
    self.contentLabel.text = nvrSettingCellData.cellContent;
    [self configImageWithStyle:nvrSettingCellData.cellStyle];
}


#pragma mark -- 设置 cell 图标
- (void)configImageWithStyle:(NvrSettingCellStyle)cellStyle
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法设置 NVR setting cell image ！");
            return ;
        }
        switch (cellStyle)
        {
            case NvrSettingCellDevInfo:     // 设备信息
            {
                strongSelf.setTypeImageView.image = [UIImage imageNamed:@"NvrSetting"];
            }
                break;
            
            case NvrSettingCellShareQr:     // 二维码分享
            {
                strongSelf.setTypeImageView.image = [UIImage imageNamed:@"NvrShare"];
            }
                break;
                
            default:
                break;
        }
    });
}


- (void)showNewVersionView
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法设置 NVR setting cell image ！");
            return ;
        }
        if (NvrSettingCellDevInfo == self.nvrSettingCellData.cellStyle)
        {
            strongSelf.updateVersionView.hidden = NO;
        }
    });
}

@end
