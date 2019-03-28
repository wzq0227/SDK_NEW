//
//  IpcFourViewDevListTableViewCell.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/9/21.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "IpcFourViewDevListTableViewCell.h"


@interface IpcFourViewDevListTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *devNameLabel;

@end


@implementation IpcFourViewDevListTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self configBackgroundColor:DEV_LIST_CELL_BG_COLOR];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}


- (void)setDevListCellData:(DeviceDataModel *)devListCellData
{
    _devListCellData       = devListCellData;
    self.devNameLabel.text = devListCellData.DeviceName;
//    if (GosDeviceStatusOnLine == devListCellData.Status)
    {
        [self configLabelColor:[UIColor whiteColor]];
    }
//    else
//    {
//        [self configLabelColor:[UIColor lightGrayColor]];
//    }
}


- (void)configLabelColor:(UIColor *)color
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        strongSelf.devNameLabel.textColor = color;
    });
}


- (void)configBackgroundColor:(UIColor *)color
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        strongSelf.backgroundColor = color;
    });
}

@end
