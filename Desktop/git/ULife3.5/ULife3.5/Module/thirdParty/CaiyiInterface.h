//
//  CaiyiInterface.h
//  QQI
//
//  Created by goscam on 16/7/15.
//  Copyright © 2016年 yuanx. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^BlockSuccess)(BOOL state,NSString *error);
typedef void(^BlockQueryList)(BOOL state,NSArray *listArray,NSString *error);
@interface CaiyiInterface : NSObject
+(CaiyiInterface *)sharedInstance;
//跳转接口
-(void)addSecretKey:(NSString *)secretKey;
-(BOOL)getSecretKeyState;

//新增摄像头请求
-(void)AddCamera:(NSString *)UID and:(NSString *)deviceName andBlock:(BlockSuccess)result;
//3.1.3 查询家庭摄像头列表请求
-(void)queryCamera:(BlockQueryList)result;
//摄像头使用鉴权请求
-(void)authCamera:(NSString *)UID andBlock:(BlockSuccess)result;
// 删除摄像头请求
-(void)deleteCamera:(NSString *)UID andBlock:(BlockSuccess)result;
//3.1.6 修改摄像头名称请求
-(void)editCamera:(NSString *)UID and:(NSString *)deviceName andBlock:(BlockSuccess)result;
@end
