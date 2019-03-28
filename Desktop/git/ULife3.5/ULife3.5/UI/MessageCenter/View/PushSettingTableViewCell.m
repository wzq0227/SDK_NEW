//
//  PushSettingTableViewCell.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/12.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "PushSettingTableViewCell.h"
#import "DeviceDataModel.h"
#import "DevPushManagement.h"
#import "DeviceManagement.h"

@interface PushSettingTableViewCell ()
{
    DeviceDataModel *_deviceDataModel;
}

@property (weak, nonatomic) IBOutlet UILabel *devNameLabel;
@property (weak, nonatomic) IBOutlet UISwitch *pushStateSwitch;
@property (nonatomic, assign) BOOL isOpenPush;                      // 是否打开推送
@property (nonatomic,strong) NSString * devid;
@property (nonatomic,assign) int ispush;

@end

@implementation PushSettingTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}


- (void)setPushSettingCellData:(DeviceDataModel *)pushSettingCellData
{
    if (!pushSettingCellData)
    {
        return;
    }
    _deviceDataModel = pushSettingCellData;
    self.devNameLabel.text = _deviceDataModel.DeviceName;
    _isOpenPush = [[DevPushManagement shareDevPushManager] isOpenPushWithDeviceId:_deviceDataModel.DeviceId];
    [self configSwithState:_isOpenPush];
}


#pragma mark -- 开启/关闭 推送
- (IBAction)devAPNSSwitchAction:(id)sender
{
    NSLog(@"开启/关闭 推送操作");
    [SVProgressHUD showWithStatus:@"loading..."];
    __weak typeof(self)weakSelf = self;
    if (self.ispush == 0)
    {
        [[DevPushManagement shareDevPushManager] openPushWithDeviceId:_devid
                                                          resultBlock:^(BOOL isSuccess)
        {
            [SVProgressHUD dismiss];
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                NSLog(@"对象丢失，不更推送新开关状态！");
                return ;
            }
            if (NO == isSuccess)
            {
                strongSelf->_isOpenPush = NO;
                NSLog(@"开启推送失败！");
                 self.ispush = 0;
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"OpenPushFailure")];
            }
            else
            {
                strongSelf->_isOpenPush = YES;
                NSLog(@"开启推送成功！");
                 self.ispush =1;
            }
            [strongSelf configSwithState:strongSelf->_isOpenPush];
        }];
    }
    else
    {
        [[DevPushManagement shareDevPushManager] closePushWithDeviceId:_devid
                                                           resultBlock:^(BOOL isSuccess)
        {
            [SVProgressHUD dismiss];
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf)
            {
                NSLog(@"对象丢失，不更推送新开关状态！");
                return ;
            }
            if (NO == isSuccess)
            {
                strongSelf->_isOpenPush = YES;
                NSLog(@"关闭推送失败！");
                 self.ispush =1;
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ClosePushFailure")];
            }
            else
            {
                strongSelf->_isOpenPush = NO;
                NSLog(@"关闭推送成功！");
                 self.ispush = 0;
            }
            [strongSelf configSwithState:strongSelf->_isOpenPush];
        }];
    }
}


- (void)freshenWith:(PushDevSetingStateModel *)md
{
    NSMutableArray * arr = [[DeviceManagement sharedInstance] deviceListArray];
    for (DeviceDataModel * model in arr) {
        if ([md.DeviceId isEqualToString:model.DeviceId] ) {
            self.devNameLabel.text = model.DeviceName;
            self.pushStateSwitch.on = md.Status;
            self.devid = md.DeviceId;
            self.ispush = md.Status;
            NSLog(@"==========%d",md.Status);
        }
    }
}

#pragma mark -- 设置推送开关状态
- (void)configSwithState:(BOOL)isOpen
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法设置消息类型图标");
            return ;
        }
        if (NO == isOpen)                   // 关闭
        {
            strongSelf.pushStateSwitch.on = NO;
        }
        else                                // 打开
        {
            strongSelf.pushStateSwitch.on = YES;
        }
    });
}

@end
