//
//  PushVideoViewController.m
//  ULife3.5
//
//  Created by goscam_sz on 2017/7/5.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "PushVideoViewController.h"
#import "DeviceManagement.h"
#import "PlayVideoViewController.h"
#import "MainNavigationController.h"
#import <RESideMenu.h>
#import "DeviceListViewController.h"
#import "PersonalCenterViewController.h"
#import "VideoImageManager.h"
#import "PushMessageModel.h"
#import "PushMessageManagement.h"
#import "APNSManager.h"
#import "MediaManager.h"


@interface PushVideoViewController ()<RESideMenuDelegate>

@property (nonatomic,strong) PlayVideoViewController *playVideoVC;

@property (nonatomic,copy) NSString * playid;

@property (nonatomic, strong)  NSString *deviceName;

@end

@implementation PushVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setUI];
    
}

- (void)setUI
{
    
    self.view.backgroundColor = UIColorFromRGBA(140, 140, 140, 1.0f);
    UIView * view = [[UIView alloc]initWithFrame:CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,20)];
    view.backgroundColor=[UIColor whiteColor];
    [self.view addSubview:view];
    [self.sureBtn  setImage:[UIImage imageNamed:@"btn_camera_normal"] forState:UIControlStateNormal];
    [self.sureBtn  setImage:[UIImage imageNamed:@"btn_camera_pressed"] forState:UIControlStateHighlighted];
    
    [self.chanceBtn setImage:[UIImage imageNamed:@"btn_delete_normal"] forState:UIControlStateNormal];
    [self.chanceBtn setImage:[UIImage imageNamed:@"btn_delete_pressed"] forState:UIControlStateHighlighted];
   
    
    if ([self.pushModel isKindOfClass:[PushMessageModel class]]) {
        if (self.pushModel.apnsMsgType == APNSMsgMove) {
            //移动侦测
            self.timeLabel.text=[NSString stringWithFormat:@"%@\n%@\n%@%@",DPLocalizedString(@"Object movement sensing event"),[self getCurrentdateString],DPLocalizedString(@"PUSH_From"),self.deviceName];
        }
        else if (self.pushModel.apnsMsgType == APNSMsgPir){
            //pir
            self.timeLabel.text=[NSString stringWithFormat:@"%@\n%@\n%@%@",DPLocalizedString(@"Object movement sensing event"),[self getCurrentdateString],DPLocalizedString(@"PUSH_From"),self.deviceName];
        }
        else if (self.pushModel.apnsMsgType == APNSMsgTemperatureUpperLimit || self.pushModel.apnsMsgType == APNSMsgTemperatureLowerLimit){
            //温度报警
            self.timeLabel.text=[NSString stringWithFormat:@"%@\n%@\n%@%@",DPLocalizedString(@"Temperature alarm event"),[self getCurrentdateString],DPLocalizedString(@"PUSH_From"),self.deviceName];
        }
        else if (self.pushModel.apnsMsgType == APNSMsgVoice){
            //声音报警
            self.timeLabel.text=[NSString stringWithFormat:@"%@\n%@\n%@%@",DPLocalizedString(@"alarm_type_voice_motion"),[self getCurrentdateString],DPLocalizedString(@"PUSH_From"),self.deviceName];
        }
        else if (self.pushModel.apnsMsgType == APNSMsgLowBattery){
            //声音报警
            self.timeLabel.text=[NSString stringWithFormat:@"%@\n%@\n%@%@",DPLocalizedString(@"alarm_type_low_battery"),[self getCurrentdateString],DPLocalizedString(@"PUSH_From"),self.deviceName];
        }
        else if (self.pushModel.apnsMsgType == APNSMsgBellRing){
            //声音报警
            self.timeLabel.text=[NSString stringWithFormat:@"%@\n%@\n%@%@",DPLocalizedString(@"alarm_type_bell_ring"),[self getCurrentdateString],DPLocalizedString(@"PUSH_From"),self.deviceName];
        }
        
//        /var/mobile/Containers/Data/Application/64D8381A-292E-4084-83C1-A00625803DBE/Documents/GosDeviceNVR/A99E6100Y9XA2K91KBC5CLYM111A/Cover/Cover_1.jpg
        UIImage *preViewImg = [[MediaManager shareManager] coverWithDevId:[self.md.DeviceId substringFromIndex:8]
                                                                 fileName:nil
                                                               deviceType:self.md.DeviceType
                                                                 position:GosDeviceNVR == self.md.DeviceType ? PositionTopLeft : PositionMain];
//        UIImage *preViewImg = [[VideoImageManager manager] getImageWithDeviceID:self.md.DeviceId];
        if (preViewImg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.pushImageView.image=preViewImg;
            });
            
        }
        else
        { dispatch_async(dispatch_get_main_queue(), ^{
            self.pushImageView.image= [UIImage imageNamed:@"defaultCovert.jpg"];
        });
    }
    }
    
    //置空Model
//    [APNSManager shareManager].pushDeviceModel = nil;
  
//    
//    NSMutableArray *deviceArray = [DeviceManagement sharedInstance].deviceListArray;
//    
//    for (DeviceDataModel *model in deviceArray) {
//        if ([[model.DeviceId substringFromIndex:8] isEqualToString:_devid]) {
//            _playVideoVC = [[PlayVideoViewController alloc] init];
//            if (_playVideoVC)
//            {
//                _playVideoVC.deviceModel = model;
//                NSMutableArray * arr = [[PushMessageManagement sharedInstance]pushMessageArray];
//                for (PushMessageModel *md  in arr) {
//                    if ([md.deviceId isEqualToString:model.DeviceId]) {
//                        
//                        if (md.apnsMsgType == APNSMsgMove) {
//                            self.timeLabel.text=[NSString stringWithFormat:@"%@\n%@\n来自%@",DPLocalizedString(@"Object movement sensing event"),[self getCurrentdateString],model.DeviceName];
//                        }
//                        else if (md.apnsMsgType == APNSMsgTemperatureUpperLimit || md.apnsMsgType ==APNSMsgTemperatureLowerLimit){
//            
//                            self.timeLabel.text=[NSString stringWithFormat:@"%@\n%@\n来自%@",DPLocalizedString(@"Temperature alarm event"),[self getCurrentdateString],model.DeviceName];
//                        
//                        }
//                    }
//                }
//                
//                UIImage *preViewImg = [[VideoImageManager manager] getImageWithDeviceID:model.DeviceId];
//             
//                if (preViewImg) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        
//                        self.pushImageView.image=preViewImg;
//                    });
//                    
//                }
//                else
//                { dispatch_async(dispatch_get_main_queue(), ^{
//                    self.pushImageView.image= [UIImage imageNamed:@"defaultCovert.jpg"];
//                });
//                    
//                }
//            }
//        }
//    }
}
- (NSString *)getCurrentdateString{
    
    
    if ([self.pushModel.pushTime isKindOfClass:[NSString class]]) {
        return self.pushModel.pushTime;
    }
    
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"YYYY-MM-dd hh:mm:ss"];
    NSString *DateTime = [formatter stringFromDate:date];
    return DateTime;
}


- (UIImage *)clipWithImageRect:(CGRect)imageRect clipRect:(CGRect)clipRect clipImage:(UIImage *)clipImage;

{
    // 开启位图上下文
    
    UIGraphicsBeginImageContextWithOptions(imageRect.size, NO,0);
    
    // 设置裁剪区域
    
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:clipRect];
    
    [path addClip];
    
    // 绘制图片
    
    [clipImage drawInRect:clipRect];
    
    // 获取当前图片
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    // 关闭上下文
    
    UIGraphicsEndImageContext();
    
    return image;
    
}

- (NSString*)deviceName{
    if (!_deviceName) {
        _deviceName = _pushModel.deviceName.length > 0 ? _pushModel.deviceName : _md.DeviceName;
    }
    return _deviceName;
}

- (void)pushNotificationHandle:(NSNotification *)notify{
    
    NSString * devid = notify.object;
    if (!devid||devid.length==0) {
        return;
    }
    _playid = notify.object;
    NSLog(@"=====================");
}


- (IBAction)chance:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (IBAction)next:(id)sender {
    
    self.playbock(self.md.DeviceId);
    [self dismissViewControllerAnimated:YES completion:^{

    }];
}

@end
