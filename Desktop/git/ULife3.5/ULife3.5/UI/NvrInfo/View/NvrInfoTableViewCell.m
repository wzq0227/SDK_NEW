//
//  NvrInfoTableViewCell.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/24.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "NvrInfoTableViewCell.h"

@interface NvrInfoTableViewCell ()

/** 信息类型 Label */
@property (weak, nonatomic) IBOutlet UILabel *infoKeyLabel;

/** 信息值 Label */
@property (weak, nonatomic) IBOutlet UILabel *infoValueLabel;

/** 更新提示 View */
@property (weak, nonatomic) IBOutlet UIView *updateVersionTipsView;

@end

@implementation NvrInfoTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}


- (void)setInfoCellData:(NvrInfoCellDataModel *)infoCellData
{
    if (!infoCellData)
    {
        return;
    }
    self.infoKeyLabel.text   = infoCellData.infoKeyStr;
    self.infoValueLabel.text = infoCellData.infoValueStr;
}


#pragma mark -- 显示 新版本提示 View
- (void)showUpdateVersionView
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法设置 NVR setting cell image ！");
            return ;
        }
        if (NvrInfoCellSysFirmware == self.infoCellData.cellStyle
            || NvrInfoCellAppFirmware == self.infoCellData.cellStyle)
        {
            strongSelf.updateVersionTipsView.hidden = NO;
        }
    });
}

@end
