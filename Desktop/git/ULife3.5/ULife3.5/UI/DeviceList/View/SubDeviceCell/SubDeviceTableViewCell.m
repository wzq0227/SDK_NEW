//
//  SubDeviceTableViewCell.m
//  ULife3.5
//
//  Created by Goscam on 2018/3/16.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "SubDeviceTableViewCell.h"
#import "MediaManager.h"

@interface SubDeviceTableViewCell()
{
    
}
@property (strong, nonatomic)  SubDevCellClickActionBlock clickBlock;
@end

@implementation SubDeviceTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    [self configUI];
}

- (void)configUI{
    
    self.playTipBtn.userInteractionEnabled = NO;
    self.disOnLineView.userInteractionEnabled = NO;
    self.covertImageView.userInteractionEnabled = YES;
    [self.covertImageView addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapGesAction:)] ];
    //100-104
    
    self.msgCenterBtn.tag = 101;
    self.cloudPlaybackBtn.tag = 102;
    self.tfCardPlaybackBtn.tag = 103;
    self.settingBtn.tag = 104;
    
    [self.msgCenterBtn setTitle:@"" forState:0];
    [self.cloudPlaybackBtn setTitle:@"" forState:0];
    [self.tfCardPlaybackBtn setTitle:@"" forState:0];
    [self.settingBtn setTitle:@"" forState:0];
    
    
    [self.msgCenterBtn setBackgroundImage:[UIImage imageNamed:@"DevList_SubDevice_Msg"] forState:0];
    [self.cloudPlaybackBtn setBackgroundImage:[UIImage imageNamed:@"DevList_SubDevice_CloudPlayback"] forState:0];
    [self.tfCardPlaybackBtn setBackgroundImage:[UIImage imageNamed:@"DevList_SubDevice_TFPlayback"] forState:0];
    [self.settingBtn setBackgroundImage:[UIImage imageNamed:@"DevList_SubDevice_Settings"] forState:0];
    
    [self.msgCenterBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.cloudPlaybackBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.tfCardPlaybackBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.settingBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    
}

#pragma mark - 点击按钮和cell回调事件
- (void)subDeviceClickCallback:(SubDevCellClickActionBlock)clickCallback{
    self.clickBlock = clickCallback;
}

- (void)tapGesAction:(id)sender{
    if (self.clickBlock) {
        self.clickBlock(SubDevCellActionPlayLiveStream,0);
    }
}

- (void)clickAction:(id)sender{
    UIView *view = (UIView*)sender;
    SubDevCellAction action = view.tag-100;
    if (self.clickBlock) {
        self.clickBlock(action,0);
    }
}

#pragma mark - Model
- (void)setDevListTableViewCellData:(DeviceDataModel *)devListTableViewCellData
{
    if (!devListTableViewCellData){
        return;
    }
    
    if (devListTableViewCellData.DeviceOwner == GosDeviceShare) {
        self.devNameLabel.text = [NSString stringWithFormat:@"%@ %@",devListTableViewCellData.DeviceName,DPLocalizedString(@"DeviceName_ShareSuffix")];
    }
    else{
        self.devNameLabel.text = devListTableViewCellData.DeviceName;
    }
    
    [self setOnlineView:devListTableViewCellData.Status];
    [self setCovertImageWithData:devListTableViewCellData];
}

- (void)setCovertImageWithData:(DeviceDataModel *)cellData
{
    __weak typeof(self)weakSelf = self;

    dispatch_async(dispatch_get_main_queue(), ^{
        
        weakSelf.covertImageView.hidden = NO;
        UIImage *coverImage = [[MediaManager shareManager] coverWithDevId:[cellData.DeviceId substringFromIndex:8]
                                                                 fileName:nil
                                                               deviceType:cellData.DeviceType
                                                                 position:PositionMain];
        [weakSelf setIpcCovertImage:coverImage];
    });
}

- (void)setIpcCovertImage:(UIImage *)covertImage
{
    if (covertImage)
    {
        self.covertImageView.image = covertImage;
    }
    else
    {
        self.covertImageView.image = [UIImage imageNamed:@"defaultCovert.jpg"];
    }
}

- (void)setOnlineView:(GosDeviceStatus)status
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!weakSelf){
            return ;
        }
        self.disOnLineView.hidden = (status==GosDeviceStatusOnLine||status==GosDeviceStatusSleep);
    });
}

@end
