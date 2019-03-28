//
//  SmartClass.h
//  iBaby
//
//  Created by goscam_sz on 15/8/11.
//  Copyright (c) 2015年 yuanx. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface SmartClass : NSObject
-(void)setWifiInfo:(NSArray *)infoArray;
-(NSString * )createCheckCode;
-(NSString *)createInfoStrWith:(NSString *)myCheckCode;
-(void)StartConnectionWith:(NSString *)InfoStr;
-(int)StopSmartConnection;
@end
