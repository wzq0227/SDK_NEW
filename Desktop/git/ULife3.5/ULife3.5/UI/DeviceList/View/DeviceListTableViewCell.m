//
//  DeviceListTableViewCell.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/2.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "DeviceListTableViewCell.h"
#import "VideoImageManager.h"
#import "MediaManager.h"
#import "Masonry.h"

@interface DeviceListTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *covertImageView;              // IPC 封面
@property (weak, nonatomic) IBOutlet UIView *disOnLineView;              // 设备未连接半透明层
@property (weak, nonatomic) IBOutlet UIView *nvrCovertView;                     // NVR 层
@property (weak, nonatomic) IBOutlet UIImageView *topLeftImageView;             // NVR 左上角 封面
@property (weak, nonatomic) IBOutlet UIImageView *topRightImageView;            // NVR 右上角 封面
@property (weak, nonatomic) IBOutlet UIImageView *bottomLeftImageView;          // NVR 左下角 封面
@property (weak, nonatomic) IBOutlet UIImageView *bottomRightImageView;         // NVR 右下角 封面
@property (weak, nonatomic) IBOutlet UILabel *devNameLabel;                     // 设备昵称
@property (weak, nonatomic) IBOutlet UILabel *devIdLabel;                       // 设备 ID


@property (weak, nonatomic) IBOutlet UIView *panoramaCovertBgView;

@property (strong, nonatomic)  UIImageView *panoramaCovertView;         // 360 封面
@property (strong, nonatomic)  UILabel *panoramaDeviceNameLabel;         // 360 设备名


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *devNameLeadingConstraint;

@end


@implementation DeviceListTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}


#pragma mark -- 数据源处理
- (void)setDevListTableViewCellData:(DeviceDataModel *)devListTableViewCellData
{
    if (!devListTableViewCellData)
    {
        return;
    }
    ;
    
    
    if (devListTableViewCellData.DeviceOwner == GosDeviceShare) {
        self.devNameLabel.text = [NSString stringWithFormat:@"%@ %@",devListTableViewCellData.DeviceName,DPLocalizedString(@"DeviceName_ShareSuffix")];
    }
    else{
        self.devNameLabel.text = devListTableViewCellData.DeviceName;
    }
    
    if (20 == devListTableViewCellData.DeviceId.length)
    {
        self.devIdLabel.text = devListTableViewCellData.DeviceId;
    }
    else if (28 == devListTableViewCellData.DeviceId.length)
    {
        self.devIdLabel.text = [devListTableViewCellData.DeviceId substringFromIndex:8];
    }
    else
    {
        self.devIdLabel.text = devListTableViewCellData.DeviceId;
    }
    self.devIdLabel.text = @""; //不显示ID
    [self setOnlineView:devListTableViewCellData.Status];
    [self setCovertImageWithData:devListTableViewCellData];
    
}

- (UIButton *)settingBtn{
    if (!_settingBtn) {
        _settingBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        [_settingBtn setImage:[UIImage imageNamed:@"PlayBlackSetting"] forState:0];//"Setting_DeviceInfo"
    }
    return _settingBtn;
}

#pragma mark -- 设置是否在线
- (void)setOnlineView:(GosDeviceStatus)status
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            return ;
        }
        switch (status)
        {
            case GosDeviceStatusOffLine:    // 不在线
            {
                self.disOnLineView.hidden = NO;
            }
                break;
                
            case GosDeviceStatusOnLine:     // 在线
            {
                self.disOnLineView.hidden = YES;
            }
                break;
                
            case GosDeviceStatusSleep:      // 睡眠
            {
                self.disOnLineView.hidden = YES;
            }
                break;
                
            default:
            {
                self.disOnLineView.hidden = NO;
            }
                break;
        }
    });
}


#pragma mark -- 设置封面
- (void)setCovertImageWithData:(DeviceDataModel *)cellData
{
    __weak typeof(self)weakSelf = self;
    self.devNameLeadingConstraint.constant = 6;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法设备封面！");
            return ;
        }
        switch (cellData.DeviceType)
        {
            case GosDeviceIPC:      // 普通 IPC
            {
                if (NO == strongSelf.nvrCovertView.hidden)
                {
                    strongSelf.nvrCovertView.hidden = YES;
            	}
                strongSelf.covertImageView.hidden = NO;
                self.panoramaCovertBgView.hidden = YES;
                UIImage *coverImage = [[MediaManager shareManager] coverWithDevId:[cellData.DeviceId substringFromIndex:8]
                                                                         fileName:nil
                                                                       deviceType:cellData.DeviceType
                                                                         position:PositionMain];
                [strongSelf setIpcCovertImage:coverImage];
//                [strongSelf setIpcCovertImage:[[VideoImageManager manager] getImageWithDeviceID:cellData.DeviceId]];
            }
                break;
            
            case GosDeviceNVR:      // NVR 
            {
                if (YES == strongSelf.nvrCovertView.hidden)
                {
                    strongSelf.nvrCovertView.hidden = NO;
                }
                strongSelf.covertImageView.hidden = YES;
                self.panoramaCovertBgView.hidden = YES;

                UIImage *covertl = [[MediaManager shareManager] coverWithDevId:[cellData.DeviceId substringFromIndex:8]
                                                                      fileName:nil
                                                                    deviceType:cellData.DeviceType
                                                                      position:PositionTopLeft];
                UIImage *coverlr = [[MediaManager shareManager] coverWithDevId:[cellData.DeviceId substringFromIndex:8]
                                                                      fileName:nil
                                                                    deviceType:cellData.DeviceType
                                                                      position:PositionTopRight];
                UIImage *coverbl = [[MediaManager shareManager] coverWithDevId:[cellData.DeviceId substringFromIndex:8]
                                                                      fileName:nil
                                                                    deviceType:cellData.DeviceType
                                                                      position:PositionBottomLeft];
                UIImage *coverbr = [[MediaManager shareManager] coverWithDevId:[cellData.DeviceId substringFromIndex:8]
                                                                      fileName:nil
                                                                    deviceType:cellData.DeviceType
                                                                      position:PositionBottomRight];
                [strongSelf setNvrTopLeftCovertImage:covertl];
                [strongSelf setNvrTopRightCovertImage:coverlr];
                [strongSelf setNvrBottomLeftCovertImage:coverbl];
                [strongSelf setNvrBottomRightCovertImage:coverbr];
        	}
                break;
            case GosDevice360:      // VR360
            {
                
                strongSelf.nvrCovertView.hidden = YES;
                strongSelf.covertImageView.hidden = YES;
                strongSelf.panoramaCovertBgView.hidden = NO;

                UIImage *coverImage = [[MediaManager shareManager] coverWithDevId:[cellData.DeviceId substringFromIndex:8]
                                                                         fileName:nil
                                                                       deviceType:cellData.DeviceType
                                                                         position:PositionMain];
                
                if (strongSelf.panoramaDeviceNameLabel) {
                    NSLog(@"panoramaDeviceNameLabel");
                }

                //得到800*800的正方形图片
                CGRect tempRect = CGRectMake(coverImage.size.width/2-150, coverImage.size.height/2-150, 300, 300);
                UIImage *clipRectImage = [CommonlyUsedFounctions clipToRectImageFromImage:coverImage inRect:tempRect];
                
                //裁剪圆角
                CGRect roundTmpRect = CGRectMake(0, 0, 300, 300);
                strongSelf.panoramaCovertView.image = [CommonlyUsedFounctions clipToRoundImageWithRect:roundTmpRect image:clipRectImage];

                strongSelf.devNameLeadingConstraint.constant = 6;
//                self.devNameLabel.frame = CGRectMake(16, labelFrame.origin.y, labelFrame.size.width, labelFrame.size.height);
                break;
            }

            default:
                break;
        }
    });
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

-(UIImageView*)panoramaCovertView{
    if (!_panoramaCovertView) {
        _panoramaCovertView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 150, 250)];
        [self.panoramaCovertBgView addSubview:_panoramaCovertView];
        [_panoramaCovertView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.panoramaCovertBgView).offset(17); //20
            make.top.equalTo(self.panoramaCovertBgView).offset(17);
            make.bottom.equalTo(self.panoramaCovertBgView).offset(-17);
            make.width.equalTo(_panoramaCovertView.mas_height);
        }];
    }
    return _panoramaCovertView;
}

-(UILabel*)panoramaDeviceNameLabel{
    if (!_panoramaDeviceNameLabel) {
        _panoramaDeviceNameLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 180, 20)];
        _panoramaDeviceNameLabel.textAlignment = NSTextAlignmentRight;
        _panoramaDeviceNameLabel.font = [UIFont fontWithName:@"ArialMT" size:25];
        _panoramaDeviceNameLabel.text = DPLocalizedString(@"VR-1080P");
        [self.panoramaCovertBgView addSubview:_panoramaDeviceNameLabel];
        [_panoramaDeviceNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.panoramaCovertBgView).offset(-10);
            make.bottom.equalTo(self.panoramaCovertBgView).offset(-15);
            make.width.mas_equalTo(180);
        }];
    }
    return _panoramaDeviceNameLabel;
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


- (void)setNvrTopLeftCovertImage:(UIImage *)covertImage
{
    if (covertImage)
    {
        self.topLeftImageView.image = covertImage;
    }
    else
    {
        self.topLeftImageView.image = [UIImage imageNamed:@"defaultCovert.jpg"];
    }
}


- (void)setNvrTopRightCovertImage:(UIImage *)covertImage
{
    if (covertImage)
    {
        self.topRightImageView.image = covertImage;
    }
    else
    {
        self.topRightImageView.image = [UIImage imageNamed:@"defaultCovert.jpg"];
    }
}


- (void)setNvrBottomLeftCovertImage:(UIImage *)covertImage
{
    if (covertImage)
    {
        self.bottomLeftImageView.image = covertImage;
    }
    else
    {
        self.bottomLeftImageView.image = [UIImage imageNamed:@"defaultCovert.jpg"];
    }
}


- (void)setNvrBottomRightCovertImage:(UIImage *)covertImage
{
    if (covertImage)
    {
        self.bottomRightImageView.image = covertImage;
    }
    else
    {
        self.bottomRightImageView.image = [UIImage imageNamed:@"defaultCovert.jpg"];
    }
}




@end
