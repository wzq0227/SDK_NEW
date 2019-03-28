//
//  FourViewModel.m
//  QQI
//
//  Created by goscam on 16/4/25.
//  Copyright © 2016年 yuanx. All rights reserved.
//

#import "FourViewModel.h"

#import "DevicePlayManager.h"

@implementation FourViewModel
@end

@interface FourViewManager()
@property(nonatomic,strong)NSMutableArray *listArray;
@property(nonatomic,strong)GDVideoPlayer *onePlayer;
@property(nonatomic,strong)GDVideoPlayer *twoPlayer;
@property(nonatomic,strong)GDVideoPlayer *threePlayer;
@property(nonatomic,strong)GDVideoPlayer *fourPlayer;
@end
@implementation FourViewManager

-(NSMutableArray *)listArray
{
    if (_listArray == nil) {
        _listArray = [[NSMutableArray alloc]init];
    }
    return _listArray;
}

+ (FourViewManager *)sharedInstance
{
    static dispatch_once_t onceToken;
    static FourViewManager *sSharedInstance;
    dispatch_once(&onceToken, ^{
        sSharedInstance = [[FourViewManager alloc] init];
    });
    return sSharedInstance;
}

-(instancetype)init
{
    if (self = [super init]) {
//        DevicePlayManager *Manager = [DevicePlayManager sharedInstance];
//        NSArray *list = [Manager getDeviceList];
//        if ([list count] > 0) {
//            for (int i = 0; i < [list count]; i++) {
//                DevicePlayModel *Playmodel = list[i];
//                if (Playmodel) {
//                    FourViewModel *model = [[FourViewModel alloc]init];
//                    model.UID = Playmodel.UID;
//                    if (model.position == 0) {
//                         self.onePlayer = [[GDVideoPlayer alloc]init];
//                        model.player = self.onePlayer;
//                    }
//                    else if(model.position == 1){
//                        self.twoPlayer = [[GDVideoPlayer alloc]init];
//                        model.player = self.twoPlayer;
//                    }
//                    else if(model.position == 2){
//                        self.threePlayer = [[GDVideoPlayer alloc]init];
//                        model.player = self.threePlayer;
//                    }
//                    else if(model.position == 3){
//                        self.fourPlayer = [[GDVideoPlayer alloc]init];
//                        model.player = self.fourPlayer;
//                    }
//                    model.state = YES;
//                    [self.listArray addObject:model];
//                }
//            }
//        }
    }
    return self;
}

-(void)addFourViewDevice:(NSString *)UID andPosition:(int)position
{
//    if (UID != nil) {
//        BOOL Flag = NO;
//        for (int i = 0; i < [self.listArray count]; i++) {
//            FourViewModel *model = self.listArray[i];
//            if ([model.UID isEqualToString:model.UID]) {
//                Flag = YES;
//                break;
//            }
//        }
//        
//        if (!Flag) {
//            @synchronized(self.listArray){
//                DevicePlayManager *Manager = [DevicePlayManager sharedInstance];
//                NSArray *list = [Manager getDeviceList];
//               
//                FourViewModel *model = [[FourViewModel alloc]init];
//                model.UID = UID;
//                model.state = YES;
//                model.position = position;
//                if (model.position == 0) {
//                    self.onePlayer = [[GDVideoPlayer alloc]init];
//                    model.player = self.onePlayer;
//                }
//                else if(model.position == 1){
//                    self.twoPlayer = [[GDVideoPlayer alloc]init];
//                    model.player = self.twoPlayer;
//                }
//                else if(model.position == 2){
//                    self.threePlayer = [[GDVideoPlayer alloc]init];
//                    model.player = self.threePlayer;
//                }
//                else if(model.position == 3){
//                    self.fourPlayer = [[GDVideoPlayer alloc]init];
//                    model.player = self.fourPlayer;
//                }
//                [self.listArray addObject:model];
//            }
//        }
//    }
}

-(void)removeFourViewDevice:(NSString *)UID
{
    if (UID != nil) {
        @synchronized(self.listArray) {
            for (int i = 0; i < [self.listArray count]; i++) {
                FourViewModel *model = self.listArray[i];
                if ([model.UID isEqualToString:model.UID]) {
                    if (model.position == 0) {
                        [_onePlayer stopPlay];
                        _onePlayer = nil;
                    }
                    else if(model.position == 1){
                        [_twoPlayer stopPlay];
                        _twoPlayer = nil;
                    }
                    else if(model.position == 2){
                        [_threePlayer stopPlay];
                        _threePlayer = nil;
                    }
                    else if(model.position == 3){
                        [_fourPlayer stopPlay];
                        _fourPlayer = nil;
                    }
                    [self.listArray removeObject:model];
                    DevicePlayManager *manager = [[DevicePlayManager alloc]init];
//                    [manager removeDevicePlayModel:UID];
                    break;
                }
            }
        }
    }
}

-(FourViewModel *)getFourViewDevice:(NSString *)UID
{
    FourViewModel *ViewModel  = nil;
    if (UID != nil) {
        @synchronized(self.listArray) {
            for (int i = 0; i < [self.listArray count]; i++) {
                FourViewModel *model = self.listArray[i];
                if ([model.UID isEqualToString:model.UID]) {
                    ViewModel = model;
                    break;
                }
            }
        }
    }
    return ViewModel;
}

-(NSMutableArray *)getListFourViewDevice
{
    return self.listArray;
}
@end
