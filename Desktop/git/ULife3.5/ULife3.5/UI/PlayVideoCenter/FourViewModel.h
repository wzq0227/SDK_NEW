//
//  FourViewModel.h
//  QQI
//
//  Created by goscam on 16/4/25.
//  Copyright © 2016年 yuanx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GDVideoPlayer.h"
@interface FourViewModel : NSObject
@property(nonatomic,assign)int position;
@property(nonatomic,copy)NSString *UID;
@property(nonatomic,assign)BOOL state;
@property(nonatomic,strong)GDVideoPlayer *player;
@end

@interface FourViewManager : NSObject
+ (FourViewManager *)sharedInstance;
-(void)addFourViewDevice:(NSString *)UID andPosition:(int)position;
-(void)removeFourViewDevice:(NSString *)UID;
-(FourViewModel *)getFourViewDevice:(NSString *)UID;
-(NSMutableArray *)getListFourViewDevice;

@end