//
//  CameraInfoManager.h
//  QQI
//
//  Created by goscam on 16/3/15.
//  Copyright © 2016年 yuanx. All rights reserved.
//

#import <Foundation/Foundation.h>


//unsigned int total_size;	//总容量
//unsigned int used_size;		//已用容量
//unsigned int free_size;		//未用容量

@interface CameraInfoManager : NSObject<NSCopying,NSMutableCopying,NSCoding>
@property(nonatomic,copy)NSString *device_id;
@property(nonatomic,copy)NSString *macaddr;
@property(nonatomic,copy)NSString *soft_ver;
@property(nonatomic,copy)NSString *firm_ver;
@property(nonatomic,copy)NSString *model_num;
@property(nonatomic,copy)NSString *Wifi;
@property(nonatomic,copy)NSString *deviceName;
@property(nonatomic,assign)int video_mirror_mode;     //镜像 & 翻转模式 (0:none,1:horizontal,2:vertical,3:horizonta+vertical)
@property(nonatomic,assign)int manual_record_switch;  //手动录像开关   (关: 0,  开: 1)
@property(nonatomic,assign)int motion_detect_sensitivity;    //移动侦测等级   (关: 0,  低: 30  中: 60  高: 100)
@property(nonatomic,assign)int pir_detect_switch;     //红外侦测开关	   (关: 0,  开: 1)
@property(nonatomic,assign)int video_quality;         //码流质量       (高清: 0, 流畅: 1)
@property(nonatomic,assign)int total_size;
@property(nonatomic,assign)int used_size;
@property(nonatomic,assign)int free_size;
@end
